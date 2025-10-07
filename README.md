# Almacenamiento de Imágenes en PostgreSQL

Este proyecto fue hecho para probar cómo guardar y recuperar imágenes directamente en una base de datos PostgreSQL usando el tipo de dato `BYTEA`.

## Grupo de Proyecto

-Daniel Ross - 30.142.372
-Sebastián Vera - 30.124.802
-Samuel Palacios - 29.631.417
-Santiago de Andrade - 31.065.103
-Andrés Valdivieso - 31.045.690


## ¿Qué hace este proyecto?

Básicamente armamos un sistema para:
- Insertar imágenes en la base de datos guardándolas como datos binarios
- Recuperar esas imágenes usando su ID
- Mantener información importante como el nombre original, tipo MIME y un checksum para verificar la integridad

Este proyecto tiene **dos implementaciones** para realizar las mismas operaciones:
1. **Implementación en Python** (`photo_demo.py`): Script CLI para insertar y recuperar imágenes desde la terminal
2. **Implementación en PostgreSQL** (`photo_procedures.sql`): Procedimientos almacenados para hacer las operaciones directamente en la base de datos

## Estructura del proyecto

```
.
├── create.sql            # Script SQL para crear la tabla y los índices
├── photo_demo.py         # Script de Python para insertar/recuperar imágenes
├── photo_procedures.sql  # Procedimientos almacenados en PostgreSQL
└── .env                  # Variables de entorno (no incluido, hay que crearlo)
```

## Configuración de la base de datos

Primero creamos una tabla `photo` que tiene estos campos:
- **id**: UUID generado automáticamente
- **filename**: nombre original del archivo
- **mime_type**: tipo de imagen (jpeg, png, etc.)
- **bytes**: la imagen guardada como BYTEA
- **size_bytes**: tamaño del archivo en bytes
- **created_at**: timestamp de cuándo se subió
- **checksum**: hash SHA-256 de la imagen (se genera automáticamente)

Para crear la tabla solo hay que correr:
```bash
psql -U tu_usuario -d nombre_db -f create.sql
```

## Configuración del entorno

Hay que crear un archivo `.env` en la raíz del proyecto con estos datos:
```
PGHOST=localhost
PGPORT=5432
PGDATABASE=nombre_de_tu_base
PGUSER=tu_usuario
PGPASSWORD=tu_contraseña
```

## Instalación de dependencias

Instalamos las librerías necesarias:
```bash
pip install psycopg2-binary python-dotenv
```

> **Nota:** Si te da error con `psycopg2`, mejor usa `psycopg2-binary` que ya viene compilado.

## Cómo usar el proyecto

### Opción 1: Usando el script de Python

El script `photo_demo.py` tiene dos comandos principales:

#### Insertar una imagen
```bash
python3 photo_demo.py insert ruta/a/tu/imagen.jpg
```

Esto guarda la imagen en la base de datos y te muestra el ID generado junto con otra info útil.

#### Recuperar una imagen
```bash
python3 photo_demo.py fetch --id <UUID-de-la-imagen>
```

Por defecto guarda el archivo con el nombre original pero con el sufijo `-retrieved`. También puedes especificar dónde guardarlo:
```bash
python3 photo_demo.py fetch --id <UUID> --out mi_imagen_recuperada.jpg
```

### Opción 2: Usando procedimientos de PostgreSQL

Primero hay que cargar los procedimientos en la base de datos:
```bash
psql -U tu_usuario -d nombre_db -f photo_procedures.sql
```

#### Insertar una imagen desde psql
```sql
-- Cargar la imagen en una variable
\set content `base64 < ruta/a/tu/imagen.jpg`

-- Insertar la imagen
CALL insert_photo('imagen.jpg', 'image/jpeg', decode(:'content', 'base64'));
```

#### Recuperar una imagen desde psql
```sql
-- Ver información de la imagen
SELECT * FROM fetch_photo('uuid-de-la-imagen');

-- Guardar la imagen en un archivo
\o imagen_recuperada.jpg
SELECT bytes FROM fetch_photo('uuid-de-la-imagen');
\o
```

#### Listar todas las imágenes
```sql
SELECT * FROM list_photos();
```

## Cómo funciona por dentro

### Inserción
1. Lee el archivo completo como bytes
2. Detecta el tipo MIME basándose en la extensión
3. Inserta todo en la base de datos usando `psycopg2.Binary()` para manejar correctamente los datos binarios
4. El checksum se genera automáticamente en la base de datos

### Recuperación
1. Busca la imagen por su UUID
2. Extrae los bytes y la metadata
3. Guarda los bytes en un archivo nuevo

## Ventajas y desventajas de este enfoque

### Ventajas
- Todo está en un solo lugar (base de datos)
- Transacciones ACID para las imágenes
- Backups automáticos con el resto de la base de datos
- El checksum nos ayuda a verificar que no se corrompa la imagen
- **Doble implementación**: Flexibilidad para usar Python o PostgreSQL según la necesidad

### Desventajas
- Puede hacer que la base de datos crezca mucho
- No es tan rápido como servir archivos estáticos desde disco
- Usa más recursos del servidor de base de datos

## Comparación entre implementaciones

| Característica | Python (`photo_demo.py`) | PostgreSQL (`photo_procedures.sql`) |
|----------------|--------------------------|-------------------------------------|
| **Facilidad de uso** | Más fácil, CLI amigable | Requiere conocimiento de SQL |
| **Manejo de archivos** | Automático desde filesystem | Manual con base64 |
| **Detección MIME** | Automática en Python | Manual al insertar |
| **Portabilidad** | Requiere Python instalado | Solo necesita acceso a PostgreSQL |
| **Casos de uso** | Scripts, automatización | Triggers, lógica dentro de la DB |

## Notas adicionales

- El script usa context managers para asegurar que las conexiones se cierren correctamente
- Los índices ayudan a buscar por fecha y checksum más rápido
- La extensión `uuid-ossp` se necesita para generar los UUIDs automáticamente

---

**Hecho con Python y PostgreSQL** 🐍🐘
