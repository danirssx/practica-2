-- Esquema mínimo para fotos en BYTEA
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS photo (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  filename    TEXT NOT NULL,
  mime_type   TEXT NOT NULL,                  -- ej: image/jpeg, image/png
  bytes       BYTEA NOT NULL,                 -- la foto como binario
  size_bytes  INTEGER NOT NULL,               -- redundante pero útil para validar
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  checksum    TEXT GENERATED ALWAYS AS (encode(digest(bytes, 'sha256'), 'hex')) STORED
);

-- Índices útiles
CREATE INDEX IF NOT EXISTS idx_photo_created_at ON photo(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_photo_checksum ON photo(checksum);
