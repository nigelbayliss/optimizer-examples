alter session set optimizer_capture_sql_quarantine = true;
alter session set optimizer_use_sql_quarantine = true;

-- this example assumes that you are connected using the LOW service. If you have picked
-- for example TPURGENT, then pls. adjust the consumer group you are setting the resource limit
-- accordingly.
BEGIN
   CS_RESOURCE_MANAGER.UPDATE_PLAN_DIRECTIVE(
      consumer_group => 'LOW',
      io_megabytes_limit => null,
      elapsed_time_limit => 5);
END;
/

