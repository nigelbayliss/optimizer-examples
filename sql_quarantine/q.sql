--
-- We want to see raw query performance without the result cache
--
alter session set result_cache_mode = 'manual';

set timing on
select max(ln(a)) from fact1; 
set timing off

