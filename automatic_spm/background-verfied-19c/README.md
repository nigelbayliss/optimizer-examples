# Demonstration of Automatic SPM with Background Verification

This demonstration is intended for Oracle Database 19c BaseDB and on-premises Enterprise Edition

The demo manipulates optimizer statistics (histograms) to induce an SQL performance regression. Automatic SQL plan management will then kick in and repair the regression.

Execute tests in a user account granted DBA privilege (but not SYS or SYSTEM).

A spool file (example.lst) is provided so you can see the expected results of the test.

## Scenario

- An existing query (Q1) performs well
- Drop histograms on a table to induce a poor SQL execution plan
- The execution plan for Q1 is now poor - this is a performance regression
- Automatic SQL plan management kicks and reinstates the good plan, resolving the performance regression
- Two SQL plan baselines are created, the one for the good plan is accepted

To run the scenario, log into a DBA account and run the script "example.sql"

WARNING! To make the test re-runnable, the AWR repository is purged for 5 days back
         so that the test query is removed. See "pawr.sql".

DISCLAIMER:
- These scripts are provided for educational purposes only.
- They are NOT supported by Oracle World Wide Technical Support.
- The scripts have been tested and they appear to work as intended.
- You should always run scripts on a test instance.
