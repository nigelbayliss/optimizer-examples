# Demonstration of Real-time SPM

This demonstration is intended for use in Oracle Database 23ai Autonomous Database (Transaction Processing)

Execute these tests in the ADMIN account.

Spool files (*.lst) are provided so you can see the expected results of the tests.

## Example 1

An existing query performs well. There is a plan change and the new plan performs poorly compared with the previous (old) plan. 
A SQL plan baseline for the old plan is accepted to fix the SQL performance regression.

The script "step2_dbrm.sql" demonstrates how you can use database resource manager (DBRM) to terminate a runaway query automatically. If the terminated query has poorer performance than a previous good plan, real-time SPM will reinstate the old plan, preventing the runaway plan from being used again. In addition, you can enable SQL quarantine if you want to prevent a bad plan from running repeatedly in cases where a previous good plan is not available (i.e. in cases that cannot be repaied by real-time SPM).

The script "step2_nodbrm.sql" demonstrates a plan 'repair' without using DBRM to terminate the query.

To run the example: 

* Log into the ADMIN account and run step1.sql. 
* Wait 15mins 
* Run step2_dbrm.sql to demonstrate a query that's terminated with database resource mangager or step2_nodbrm.sql to allow the long-running query to complete.

DISCLAIMER:
- These scripts are provided for educational purposes only.
- They are NOT supported by Oracle World Wide Technical Support.
- The scripts have been tested and they appear to work as intended.
- You should always run scripts on a test instance.
