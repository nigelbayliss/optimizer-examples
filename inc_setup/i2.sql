set echo off
prompt ========================================
prompt Set up the table for incremental stats
prompt ========================================
set echo on
BEGIN
  DBMS_STATS.SET_TABLE_PREFS(
    ownname => USER, 
    tabname => 'SALES_DATA',
    pname   => 'INCREMENTAL',
    pvalue  => 'TRUE'
  );
END;
/

BEGIN
  DBMS_STATS.SET_TABLE_PREFS(
    ownname => USER, 
    tabname => 'SALES_DATA',
    pname   => 'INCREMENTAL_LEVEL',
    pvalue  => 'PARTITION'
  );
END;
/
set echo off
