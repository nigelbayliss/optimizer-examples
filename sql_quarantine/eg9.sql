--
-- Clean up the plan directive
--
BEGIN
   CS_RESOURCE_MANAGER.UPDATE_PLAN_DIRECTIVE(
      consumer_group => 'LOW',
      io_megabytes_limit => null,
      elapsed_time_limit => null);
END;
/

