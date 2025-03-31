-- 1. Create 'table_to_delete' with 10 million rows
CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1, (10^7)::int) x;

-- 2. Check space consumption before any modifications (575MB)
SELECT *, pg_size_pretty(total_bytes) AS total,
            pg_size_pretty(index_bytes) AS INDEX,
            pg_size_pretty(toast_bytes) AS toast,
            pg_size_pretty(table_bytes) AS TABLE
FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
       FROM (SELECT c.oid, nspname AS table_schema,
                          relname AS TABLE_NAME,
                          c.reltuples AS row_estimate,
                          pg_total_relation_size(c.oid) AS total_bytes,
                          pg_indexes_size(c.oid) AS index_bytes,
                          pg_total_relation_size(reltoastrelid) AS toast_bytes
             FROM pg_class c
             LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
             WHERE relkind = 'r'
           ) a
    ) a
WHERE table_name LIKE '%table_to_delete%';

-- 3. DELETE operation (remove 1/3 of rows) (4s)
DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string', '')::int % 3 = 0;

-- 3b. Check space consumption after DELETE (575MB)
SELECT *, pg_size_pretty(total_bytes) AS total,
            pg_size_pretty(index_bytes) AS INDEX,
            pg_size_pretty(toast_bytes) AS toast,
            pg_size_pretty(table_bytes) AS TABLE
FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
       FROM (SELECT c.oid, nspname AS table_schema,
                          relname AS TABLE_NAME,
                          c.reltuples AS row_estimate,
                          pg_total_relation_size(c.oid) AS total_bytes,
                          pg_indexes_size(c.oid) AS index_bytes,
                          pg_total_relation_size(reltoastrelid) AS toast_bytes
             FROM pg_class c
             LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
             WHERE relkind = 'r'
           ) a
    ) a
WHERE table_name LIKE '%table_to_delete%';

-- 3c. Perform VACUUM FULL (4.8s)
VACUUM FULL VERBOSE table_to_delete;

-- 3d. Check space consumption after VACUUM FULL (383MB  - less for ~190MB)
SELECT *, pg_size_pretty(total_bytes) AS total,
            pg_size_pretty(index_bytes) AS INDEX,
            pg_size_pretty(toast_bytes) AS toast,
            pg_size_pretty(table_bytes) AS TABLE
FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
       FROM (SELECT c.oid, nspname AS table_schema,
                          relname AS TABLE_NAME,
                          c.reltuples AS row_estimate,
                          pg_total_relation_size(c.oid) AS total_bytes,
                          pg_indexes_size(c.oid) AS index_bytes,
                          pg_total_relation_size(reltoastrelid) AS toast_bytes
             FROM pg_class c
             LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
             WHERE relkind = 'r'
           ) a
    ) a
WHERE table_name LIKE '%table_to_delete%';

-- 3e. Recreate table (13s)
DROP TABLE table_to_delete;
CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1, (10^7)::int) x;

-- 4. Perform TRUNCATE (0.52s)
TRUNCATE table_to_delete;

-- 4b. Check space consumption after TRUNCATE (0 bytes)
SELECT *, pg_size_pretty(total_bytes) AS total,
            pg_size_pretty(index_bytes) AS INDEX,
            pg_size_pretty(toast_bytes) AS toast,
            pg_size_pretty(table_bytes) AS TABLE
FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
       FROM (SELECT c.oid, nspname AS table_schema,
                          relname AS TABLE_NAME,
                          c.reltuples AS row_estimate,
                          pg_total_relation_size(c.oid) AS total_bytes,
                          pg_indexes_size(c.oid) AS index_bytes,
                          pg_total_relation_size(reltoastrelid) AS toast_bytes
             FROM pg_class c
             LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
             WHERE relkind = 'r'
           ) a
    ) a
WHERE table_name LIKE '%table_to_delete%';

--5
-- So table takes 575MB space:
--1.Delete option took 4 seconds to perform, but space occupied was the same!
--2.VACCUUM FULL VERBOSE took 4.8 seconds to perform and decreese table space by 192MB to 383MB.
--3.TRUNCATE was the longest to perform -13 seconds, but it free all the space as 0 bytes
-- All these function has their own advantages of use.