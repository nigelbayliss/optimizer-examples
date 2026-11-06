-- Oracle: run as the user whose objects you want to drop.
-- SQL*Plus / SQLcl: @drop_schema_objects.sql
-- SQL Developer: Run Script (F5).
-- Set c_preview to FALSE to execute the displayed DROP statements.
-- DDL commits implicitly; completed drops cannot be rolled back.
-- CASCADE CONSTRAINTS can remove referencing foreign keys in other schemas.
-- Tables use the normal recycle-bin behavior (no PURGE).

SET SERVEROUTPUT ON SIZE UNLIMITED

DECLARE
    c_preview CONSTANT BOOLEAN := TRUE;
    l_owner   VARCHAR2(128) := SYS_CONTEXT('USERENV', 'CURRENT_USER');
    l_count   PLS_INTEGER := 0;

    FUNCTION quoted(p_name VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN '"' || REPLACE(p_name, '"', '""') || '"';
    END;

    PROCEDURE run_ddl(p_sql VARCHAR2) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(p_sql || ';');
        IF NOT c_preview THEN
            EXECUTE IMMEDIATE p_sql;
        END IF;
        l_count := l_count + 1;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('FAILED: ' || SQLERRM);
            RAISE; -- Stop; preceding successful drops are already committed.
    END;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Schema: ' || quoted(l_owner));
    IF c_preview THEN
        DBMS_OUTPUT.PUT_LINE('PREVIEW ONLY. Set c_preview to FALSE to execute.');
    END IF;

    -- Logs are dropped using their master table names, not MLOG$_ names.
    FOR r IN (SELECT master FROM user_mview_logs ORDER BY master) LOOP
        run_ddl('DROP MATERIALIZED VIEW LOG ON ' ||
                quoted(l_owner) || '.' || quoted(r.master));
    END LOOP;

    FOR r IN (SELECT mview_name FROM user_mviews ORDER BY mview_name) LOOP
--        run_ddl('DROP MATERIALIZED VIEW ' ||
--                quoted(l_owner) || '.' || quoted(r.mview_name));
        run_ddl('EXEC DBMS_AUTO_MV.DROP_AUTO_MVS(user, ''' || r.mview_name || ''', TRUE)');
    END LOOP;

    -- Query after dropping MVs, so any retained prebuilt tables are included.
    -- In preview mode, exclude storage that an earlier DROP removes itself.
    -- Nested storage, secondary tables and IOT overflow/mapping tables are
    -- removed with their owning tables rather than dropped individually.
    FOR r IN (
        SELECT t.table_name
        FROM user_tables t
        WHERE t.nested = 'NO'
          AND t.secondary = 'N'
          AND (t.iot_type IS NULL OR t.iot_type = 'IOT')
          AND table_name like 'AMV_DEMO%'
          AND NOT EXISTS (
              SELECT 1 FROM user_recyclebin b
              WHERE b.object_name = t.table_name
          )
          AND NOT EXISTS (
              SELECT 1 FROM user_mviews m
              WHERE m.container_name = t.table_name
                AND m.build_mode <> 'PREBUILT'
          )
          AND NOT EXISTS (
              SELECT 1 FROM user_mview_logs l
              WHERE l.log_table = t.table_name
          )
        ORDER BY t.table_name
    ) LOOP
        run_ddl('DROP TABLE ' || quoted(l_owner) || '.' ||
                quoted(r.table_name) || ' CASCADE CONSTRAINTS');
    END LOOP;

    IF c_preview THEN
        DBMS_OUTPUT.PUT_LINE('Statements previewed: ' || l_count);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Statements executed: ' || l_count);
    END IF;
END;
/

