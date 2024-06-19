alter session set optimizer_capture_sql_quarantine = true;
alter session set optimizer_use_sql_quarantine = true;

BEGIN
   CS_RESOURCE_MANAGER.UPDATE_PLAN_DIRECTIVE(
      consumer_group => 'LOW',
      io_megabytes_limit => null,
      elapsed_time_limit => 5);
END;
/

