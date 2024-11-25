# Demonstration of Real-time SPM

This demonstration is intended for use in Oracle Autonomous Database 23ai (Transaction Processing)

The demo will work in Oracle Autonmous Database 19c, too, but see "tab.sql" for the minor edit you will need.

Execute these tests in the ADMIN account.

Spool files (*.lst) are provided so you can see the expected results of the tests.

## Example

Scenario:

- An existing query performs well. 
- There is a plan change and the new plan performs poorly compared with the previous (old) plan. 
- A SQL plan baseline for the old plan is accepted to fix the SQL performance regression.

The script "step2_dbrm.sql" demonstrates how you can use database resource manager (DBRM) to terminate a runaway query automatically. If the terminated query has poorer performance than a previous good plan, real-time SPM will reinstate the old plan, preventing the runaway plan from being used again. In addition, you can enable SQL quarantine if you want to prevent a bad plan from running repeatedly in cases where a previous good plan is not available (i.e. in cases that cannot be repaied by real-time SPM).

The script "step2_nodbrm.sql" demonstrates a plan 'repair' without using DBRM to terminate the query.

To run the example: 

* Log into the ADMIN account and run step1.sql. 
* Wait 15mins 
* Run step2_dbrm.sql to demonstrate a query that's terminated with database resource mangager or step2_nodbrm.sql to allow the long-running query to complete.

## Why are there hints in the test query?

The test query includes a hint: /*+ USE_NL(t1) LEADING(t2 t1) */

This hint induces a bad plan. The testcase disables and enables the hint by setting __optimizer\_ignore\_hints__ from TRUE to FALSE, thus flipping the plan from good to bad (inducing a performance regression). Arguably, the most obvious way to induce a bad plan is to manipulate optimizer statistics, but this is difficult to pull off in practice because real-time SPM includes some sanity checks, and won't reinstate an old plan if the cost has changed significantly.

DISCLAIMER:
- These scripts are provided for educational purposes only.
- They are NOT supported by Oracle World Wide Technical Support.
- The scripts have been tested and they appear to work as intended.
- You should always run scripts on a test instance.
