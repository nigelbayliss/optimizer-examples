--
-- Example:
--    Initial plan is poor
--    New plan is better
-- Run this script followed by step2.sql
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
-- Execute the query, manipulating the cost to yield a poor plan
--
@@cost_bad
@@q
@@q
--
-- Wait now for SQL statement to appear in SYS_AUTO_STS
--
@@wait_asts
@@asts
