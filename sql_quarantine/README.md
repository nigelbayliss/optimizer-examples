# SQL Quarantine

These scripts are for use in Autonomous Database and demonstrate SQL quarantine

Use a DBA account, firstly run "example1.sql" and wait for SQL quarantine to kick in. In generally takes a few minutes for the SQL statement to be quarantined.

Next, run "example2.sql." This script should run in its entirety to clean up database resource manager (which otherwise imposes a 5 second time limit on SQL statements)

Spooled output is included - see example1.lst and example2.lst

DISCLAIMER:
   <br/>-- These scripts are provided for educational purposes only.
   <br/>-- They are NOT supported by Oracle World Wide Technical Support.
   <br/>-- The scripts have been tested and they appear to work as intended.
   <br/>-- You should always run scripts on a test instance.

