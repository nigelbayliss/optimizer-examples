--
-- Remove the elapsed time limit
--
BEGIN
   CS_RESOURCE_MANAGER.UPDATE_PLAN_DIRECTIVE(
      consumer_group => 'LOW', 
      elapsed_time_limit => NULL);
END;
/

