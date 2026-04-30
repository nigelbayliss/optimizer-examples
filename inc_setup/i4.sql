set echo off
prompt ========================================
prompt Checking this again...
prompt
prompt GLOBAL stats have not been gathered
prompt yet because we gathered at the partition-level
prompt only - (look at the LAST_GATHERED dates and
prompt observe that the global-level stats are
prompt older than the stats on the partitions)
prompt ========================================
select table_name,partition_name,stale_stats,to_char(last_analyzed,'YYYY-MM-DD HH24:MI:SS') last_gathered
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
prompt
prompt If the table has indexes, this step will
prompt take longer, but we will still use
prompt synopses to reduce the overall gather time.
prompt 
prompt For the purposes of illustration, and to make
prompt the synopses optimization  more obvious, no indexes
prompt in this test case.
prompt ========================================
set timing on
set echo on
exec dbms_stats.gather_table_stats(user,'sales_data',options=>'gather auto')
set echo off
set timing off

prompt ========================================
prompt GLOBAL stats have been gathered using synopses
prompt (check the LAST_GATHERED time for the global
prompt stats - where partition_name is NULL)
prompt ========================================
select table_name,partition_name,stale_stats,to_char(last_analyzed,'YYYY-MM-DD HH24:MI:SS') last_gathered
from   user_tab_statistics
where  table_name = 'SALES_DATA'
order  by partition_name;
