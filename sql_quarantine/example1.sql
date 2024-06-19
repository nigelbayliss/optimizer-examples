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
@@q

pause p...

@@q

pause p...

@@q
