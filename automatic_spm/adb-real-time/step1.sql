--
-- Example:
--    Initial (old) plan is good
--    A new plan is chosen by the optimizer, but this plan is worse than the old plan
--    Real-time SPM reinstates good (old) plan
--    When SQL statement is hard parsed, optimizer chooses poor new plan again
--    Reverse-verify kicks in a confirms that old plan was better
--  Run this script followed by step4.sql
--
-- Reset test - clear out SQL plan baselines and the auto SQL tuning set
--
@@reset
--
-- Create tables
--
@@tab
--
-- Enable real-time SPM
--
@@auto
--
-- Execute the query, manipulating the cost to yield a good plan
--
@@plan_good
@@q
@@q
--
-- Wait now for SQL statement to appear in SYS_AUTO_STS
--
@@wait_asts
@@asts
