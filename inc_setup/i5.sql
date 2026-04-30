set echo off
prompt ========================================
prompt Make a single partition stale to check
prompt we continue to use synopses successfully
prompt ========================================
set echo on
delete from sales_data partition (p2020);
exec dbms_stats.flush_database_monitoring_info;
set echo off
prompt ========================================
prompt Check stale
prompt ========================================
select table_name,partition_name,stale_stats,num_rows,to_char(last_analyzed,'YYYY-MM-DD HH24:MI:SS') last_gathered
from   user_tab_statistics
where  table_name = 'SALES_DATA'
order  by partition_name;

prompt ========================================
prompt Sleep for a few seconds because we want
prompt to see a clear difference in LAST_GATHERED
prompt times
prompt ========================================
set echo on
exec dbms_lock.sleep(10);
set echo off

prompt ========================================
prompt Note the short time to process this step
prompt indicating that we are not scanning all
prompt rows in the table.
prompt ========================================
set timing on
set echo on
exec dbms_stats.gather_table_stats(user,'sales_data',options=>'gather auto')
set echo off
set timing off

prompt ========================================
prompt GLOBAL stats have been updated using synopses
prompt (compare NUM_ROWS with above)
prompt ========================================
select table_name,partition_name,stale_stats,num_rows,to_char(last_analyzed,'YYYY-MM-DD HH24:MI:SS') last_gathered
from   user_tab_statistics
where  table_name = 'SALES_DATA'
order  by partition_name;
