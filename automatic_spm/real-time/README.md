# Demonstration of Real-time SPM

This demonstration is intended for Oracle Database 23ai BaseDB and on-premises Enterprise Edition (when available)
Note: Real-time SPM is not available in Oracle Database 23ai FREE

The demo relies on manipulating a database parameter to cause a SQL performance regression, and therefore 
will not work in Oracle Autonomous Database.

Execute tests in a user account granted DBA priviledge (but not SYS or SYSTEM). 

Spool files (*.lst) are provided so you can see the expected results of the tests.

## Important

Before running this demo, ensure that you have not enabled SQL plan management auto capture. This is a separate capability, independent of real-time SPM. This means that the database parameter *optimizer_capture_sql_plan_baselines* must be FALSE and *optimizer_use_sql_plan_baselines* must be TRUE.

## Example 1

Scenario:

- An existing query performs poorly. 
- There is a plan change and the new plan performs better. 
- The SQL plan baseline for the new plan is accepted.

To run example 1, log into a DBA account and run step1.sql and then run step2.sql

## Example 2

Scenario:

- An existing query performs well. 
- There is a plan change and the new plan performs poorly compared with the previous (old) plan. 
- The SQL plan baseline for the old plan is accepted to fix the SQL performance regression.
- A reverse verification step is performed to confirm the reistated old plan definitely out-performs the new (poor) plan.

To run example 2, log into a DBA account and run step3.sql and then run step4.sql

## Reverse Verification (Example 2)

In step3, you will see an initial good plan using indexes. We'll call that the OLD plan.

In step4, the optimizer chooses a NEW (poor) plan with hash join and full table scans. Real-time SPM corrects this and accepts the OLD plan. You can see this in step4.lst, where the plan is marked:

```
Note
-----
   - SQL plan baseline SQL_PLAN_20j5m31t6u71h5ef7a68d used for this statement
```

You can see the good and bad plans if you run planb.sql (see planb.lst). Plan name SQL_PLAN_20j5m31t6u71h5ef7a68d is the OLD good plan and SQL_PLAN_20j5m31t6u71h8059011b is the NEW bad plan. The former is marked "Accepted: YES".  

At the end of step4, you will see the two SQL plan baselines listed.

```
PLAN_NAME                                FOREGROUND_LAST_VERIFIED      RESULT   VERIFY_T
---------------------------------------- ----------------------------- -------- --------
SQL_PLAN_20j5m31t6u71h8059011b           06-JUN-25 03.01.06.000000 PM  worse    normal
SQL_PLAN_20j5m31t6u71h5ef7a68d           06-JUN-25 03.01.08.000000 PM  better   reverse
```

Plan SQL_PLAN_20j5m31t6u71h8059011b is the NEW (poor) plan, and real-time SPM marks the performance test result "worse" (because the new plan is worse than the old plan). At the next hard parse, the optimizer chooses the NEW (bad) plan again, but instead, real-time SPM ensures that OLD plan is run again. There reverse verification step checks that the performance of the OLD plan really is better than the NEW plan. In this case, it is, so the OLD plan remains accepted and the new plan remains not accepted. Finally, the OLD plan SQL_PLAN_20j5m31t6u71h5ef7a68d is marked better.

DISCLAIMER:
- These scripts are provided for educational purposes only.
- They are NOT supported by Oracle World Wide Technical Support.
- The scripts have been tested and they appear to work as intended.
- You should always run scripts on a test instance.
