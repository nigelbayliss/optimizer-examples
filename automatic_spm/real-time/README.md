# Demonstration of Real-time SPM

NOTE! This demo is currently non-functional. I will repair the demo and include a message to that effect here when it's done.

This demonstration is intended for Oracle Database 23ai BaseDB and on-premises Enterprise Edition (when available)
Note: Real-time SPM is not available in Oracle Database 23ai FREE

The demo relies on manipulating a database parameter to cause a SQL performance regression, and therefore 
will not work in Oracle Autonomous Database.

Execute tests in a user account granted DBA priviledge (but not SYS or SYSTEM). 

Spool files (*.lst) are provided so you can see the expected results of the tests.

## Example 1

Scenario:

- An existing query performs poorly. 
- There is a plan change and the new plan performs better. 
- The SQL plan baseline for the new plan is accepted.

To run example 1, log into a DBA account and run step1.sql followed by step2.sql

## Example 2

Scenario:

- An existing query performs well. 
- There is a plan change and the new plan performs poorly compared wit the previous (old) plan. 
- The SQL plan baseline for the old plan is accepted to fix the SQL performance regression.
- A reverse verification step is performed to confirm the reistated old plan definitely out-performs the new (poor) plan.

To run example 2, log into a DBA account and run step3.sql followed by step4.sql

DISCLAIMER:
- These scripts are provided for educational purposes only.
- They are NOT supported by Oracle World Wide Technical Support.
- The scripts have been tested and they appear to work as intended.
- You should always run scripts on a test instance.
