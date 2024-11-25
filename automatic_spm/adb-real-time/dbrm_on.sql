--
-- For the sake of this experiment, we'll set the 
-- maximum runtime for a SQL statement to 15 seconds
--
BEGIN
   CS_RESOURCE_MANAGER.UPDATE_PLAN_DIRECTIVE(
      consumer_group => 'LOW', 
      elapsed_time_limit => 15);
END;
/
