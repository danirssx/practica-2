import argparse
import mimetypes
import os
import sys
from dataclasses import dataclass
from pathlib import Path
import psycopg2
import psycopg2.extras
from dotenv import load_dotenv


@dataclass
class DBConfig:
    host: str
    port: int
    dbname: str
    user: str
    password: str


def get_db_config() -> DBConfig:
    load_dotenv()
    host = os.getenv("PGHOST", "localhost")
    port = int(os.getenv("PGPORT", "5432"))
    dbname = os.getenv("PGDATABASE", "photos_db")
    user = os.getenv("PGUSER", "app_user")
    password = os.getenv("PGPASSWORD", "")
    return DBConfig(host, port, dbname, user, password)


def get_conn(cfg: DBConfig):
    dsn = f"host={cfg.host} port={cfg.port} dbname={cfg.dbname} user={cfg.user} password={cfg.password}"
    return psycopg2.connect(dsn)


def guess_mime(path: Path) -> str:
    mt, _ = mimetypes.guess_type(str(path))
    return mt or "application/octet-stream"


def insert_image(cfg: DBConfig, file_path: Path):
    if not file_path.exists() or not file_path.is_file():
        print(f"Error: File does not exist: {file_path}", file=sys.stderr)
        sys.exit(1)

    data = file_path.read_bytes()
    mt = guess_mime(file_path)

    with get_conn(cfg) as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """
                INSERT INTO photo (filename, mime_type, bytes, size_bytes)
                VALUES (%s, %s, %s, %s)
                RETURNING id, filename, mime_type, size_bytes, created_at
                """,
                (file_path.name, mt, psycopg2.Binary(data), len(data)),
            )
            row = cur.fetchone()

    print(f"✅ Image inserted successfully:")
    print(f"   ID: {row['id']}")
    print(f"   Filename: {row['filename']}")
    print(f"   Size: {row['size_bytes']} bytes")
    print(f"   Type: {row['mime_type']}")
    print(f"   Created: {row['created_at']}")


def fetch_image(cfg: DBConfig, id_: str, out: Path | None):
    with get_conn(cfg) as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT filename, mime_type, bytes FROM photo WHERE id = %s", (id_,)
            )
            row = cur.fetchone()
            if not row:
                print(f"Error: No image found with id: {id_}", file=sys.stderr)
                sys.exit(1)
            filename, mime_type, blob = row

    if out is None:
        stem = Path(filename).stem
        ext = Path(filename).suffix
        out = Path(f"{stem}-retrieved{ext}")

    Path(out).write_bytes(blob)
    print(f"✅ Imagen retribuida:")
    print(f"   Guardada en: {out}")
    print(f"   Tipo: {mime_type}")


def main():
    parser = argparse.ArgumentParser(
        description="Guardada la imagen en la base de datos"
    )
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_ins = sub.add_parser("insert", help="Inserta una imagen en la base de datos")
    p_ins.add_argument("file", type=Path, help="Path to image file")

    p_fetch = sub.add_parser("fetch", help="Retribuir imagen por ID")
    p_fetch.add_argument("--id", required=True, help="Image UUID")
    p_fetch.add_argument("--out", type=Path, help="Output file path")

    args = parser.parse_args()
    cfg = get_db_config()

    if args.cmd == "insert":
        insert_image(cfg, args.file)
    elif args.cmd == "fetch":
        fetch_image(cfg, args.id, args.out)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
