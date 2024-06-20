set echo on
--
-- We don't want this to affect a test
--
alter session set result_cache_mode = 'manual';
@off
@@tab
@on
show parameter quarantine

--
-- It may take a little time for the
-- quarantine data to be flushed to disk
-- Execute "q.sql" periodically until
-- quarantine kicks in - then run example2.sql
--
-- you will see when quarantine kicks in when the SQL statement is
-- aborted, due to the resource constraint limits. The very moment
-- the statement is aborted, it is marked as quarantined, due to the
-- setting of (A) capturing statements for quarantine and (B) use
-- and enforce quarantined statements

@@q

pause p...

@@q

pause p...

@@q
