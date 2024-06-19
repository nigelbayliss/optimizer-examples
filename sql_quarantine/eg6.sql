--
-- If the SQL statement has a different plan, it will complete
-- because SQL quarantine relates to execution plans, not SQL statements in isolation
-- Create an index, but disable the DBRM time limit since it will take more that 5 seconds
--
BEGIN
   CS_RESOURCE_MANAGER.UPDATE_PLAN_DIRECTIVE(
      consumer_group => 'LOW',
      io_megabytes_limit => null,
      elapsed_time_limit => null);
END;
/
create index fact1i on fact1(ln(a));
BEGIN
   CS_RESOURCE_MANAGER.UPDATE_PLAN_DIRECTIVE(
      consumer_group => 'LOW',
      io_megabytes_limit => null,
      elapsed_time_limit => 5);
END;
/
@@q
@@plan
