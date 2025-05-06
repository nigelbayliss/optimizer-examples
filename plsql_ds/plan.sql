set pagesize 1000
set tab off
set linesize 250
set trims on
column PLAN_TABLE_OUTPUT format a200

select *
from table(dbms_xplan.display_cursor(format=>'typical +allstats last'));
