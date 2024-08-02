--
-- Enable auto SPM
--
@on
--
-- Reset test - it can be restarted from here
--
@reset
prompt Warning! About to purge 5 days of AWR data to ensure
prompt the test query is not present (in case the test is executed more than once)
pause p...
@pawr
--
prompt These queries should return no rows if the test is successfully reset
--
@base
@asts
@awr
prompt Here we check that AWR and Auto SQL Tuning Set do not contain the test query
prompt and there should be no SQL plan baseline for the test query
pause p...
--
prompt Create schema - histograms ensure plan is good
--
@tab
--
prompt This is the test query - the HASH JOIN is best,
prompt and will be chosen as long as histograms are present
--
@q1
@wait_asts
--
-- Now we should see the test query
--
@asts
prompt Here we check to make sure we have captured our test query
prompt The automatic SQL tuning set records the good HASH JOIN plan
pause p...
--
prompt Now that the SQL statement (q1) is seen in SQL tuning set (above)
prompt we will now induce a bad NESTED LOOP plan by dropping the histograms
--
@droph
--
prompt Execute the query again using the bad nested loops plan, and ensure it's captured in AWR
--
@q1
--
prompt Wait for the bad plan to be captured in the Auto SQL Tuning Set
--
@wait_asts
--
prompt Auto SPM will look for SQL statements showing up in AWR, so we'll make sure it's there
--
@snap
@q1_loop 10
@snap
@awr
@asts
--
prompt Now waiting for auto SPM to kick in and fix our regression
--
@wait_spm
--
-- The test query has a SQL plan baseline reinstating the good plan
--
@q1
--
@base
