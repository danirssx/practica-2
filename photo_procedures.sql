CREATE OR REPLACE PROCEDURE insert_photo(
    p_filename VARCHAR,
    p_mime_type VARCHAR,
    p_bytes BYTEA,
    OUT out_id UUID,
    OUT out_filename VARCHAR,
    OUT out_mime_type VARCHAR,
    OUT out_size_bytes INTEGER,
    OUT out_created_at TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO photo (filename, mime_type, bytes, size_bytes)
    VALUES (p_filename, p_mime_type, p_bytes, LENGTH(p_bytes))
    RETURNING id, filename, mime_type, size_bytes, created_at
    INTO out_id, out_filename, out_mime_type, out_size_bytes, out_created_at;

    RAISE NOTICE '✅ Image inserted successfully:';
    RAISE NOTICE '   ID: %', out_id;
    RAISE NOTICE '   Filename: %', out_filename;
    RAISE NOTICE '   Size: % bytes', out_size_bytes;
    RAISE NOTICE '   Type: %', out_mime_type;
    RAISE NOTICE '   Created: %', out_created_at;
END;
$$;

-- Function to fetch an image from the database
-- Usage: SELECT * FROM fetch_photo('uuid-here');
CREATE OR REPLACE FUNCTION fetch_photo(p_id UUID)
RETURNS TABLE (
    filename VARCHAR,
    mime_type VARCHAR,
    bytes BYTEA,
    size_bytes INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT p.filename, p.mime_type, p.bytes, p.size_bytes
    FROM photo p
    WHERE p.id = p_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Error: No image found with id: %', p_id;
    END IF;
END;
$$;

-- Alternative: Procedure version of fetch_photo with OUT parameters
CREATE OR REPLACE PROCEDURE get_photo(
    p_id UUID,
    OUT out_filename VARCHAR,
    OUT out_mime_type VARCHAR,
    OUT out_bytes BYTEA,
    OUT out_size_bytes INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT filename, mime_type, bytes, size_bytes
    INTO out_filename, out_mime_type, out_bytes, out_size_bytes
    FROM photo
    WHERE id = p_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Error: No image found with id: %', p_id;
    END IF;

    RAISE NOTICE '✅ Image retrieved:';
    RAISE NOTICE '   Filename: %', out_filename;
    RAISE NOTICE '   Type: %', out_mime_type;
    RAISE NOTICE '   Size: % bytes', out_size_bytes;
END;
$$;

-- Helper function to list all photos
CREATE OR REPLACE FUNCTION list_photos()
RETURNS TABLE (
    id UUID,
    filename VARCHAR,
    mime_type VARCHAR,
    size_bytes INTEGER,
    created_at TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT p.id, p.filename, p.mime_type, p.size_bytes, p.created_at
    FROM photo p
    ORDER BY p.created_at DESC;
END;
$$;
