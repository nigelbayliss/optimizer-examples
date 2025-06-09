set pagesize 1000
set tab off
set linesize 160
column plan_table_output format a150

select *
from table(dbms_xplan.display_sql_plan_baseline(sql_handle=>'SQL_2044b318726d1c30'))
/