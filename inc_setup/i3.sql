set echo off
prompt ========================================
prompt Sleep for a few seconds because we want
prompt to see a clear difference in LAST_GATHERED
prompt times (comparing the partition-level
prompt gather times with the global time)
prompt ========================================
set echo on
exec dbms_lock.sleep(10);
set echo off
prompt ========================================
prompt NOTES is NULL - no synopses
prompt ========================================
select distinct partition_name,notes
from   user_part_col_statistics
where  table_name = 'SALES_DATA'
order  by partition_name;

prompt ========================================
prompt We can gather partition-level statistics
prompt over a period of time if necessary -
prompt creating synopses as we go.
prompt
prompt If statistics are being gathered on
prompt the table during this period of time (e.g. using auto stats),
prompt you might need to adjust how this is done. For example,
prompt you could change the table's GRANULARITY
prompt preference to GLOBAL, allowing
prompt partition-level statistics to be created/updated
prompt using this piecemeal approach without interference.
prompt If you use a acript to gather stats on the 
prompt relevant table, this will need to be changed during
prompt the process.
prompt ========================================

set timing on
set echo on
-- Gather per-partition statistics only
DECLARE
  v_owner   VARCHAR2(128) := USER;          -- or set to your schema name
  v_table   VARCHAR2(128) := 'SALES_DATA';  -- target table
BEGIN
  FOR p IN (
    SELECT partition_name
    FROM   all_tab_partitions
    WHERE  table_owner = v_owner
    AND    table_name  = v_table
    ORDER  BY partition_position
  )
  LOOP
    DBMS_STATS.GATHER_TABLE_STATS(
      ownname          => v_owner,
      tabname          => v_table,
      partname         => p.partition_name,
      estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
      method_opt       => 'FOR ALL COLUMNS SIZE AUTO',
      granularity      => 'PARTITION',   -- do not touch global/table stats
      cascade          => TRUE,          -- include indexes in this partition
      no_invalidate    => DBMS_STATS.AUTO_INVALIDATE
    );
  END LOOP;
END;
/
set echo off
set timing off

prompt ========================================
prompt NOTES is NOT NULL - we now have synopses
prompt ========================================
select distinct partition_name,notes
from   user_part_col_statistics
where  table_name = 'SALES_DATA'
order  by partition_name;


prompt ========================================
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

