# Demonstration of Dynamic Statistics with PL/SQL

See the [blog post](https://blogs.oracle.com/optimizer/post/plsql-ds) for more information.

This demonstration is intended for Oracle Database 23ai Autonomous Database.

Spool file (example.lst) is provided so you can see the expected results of the tests.

To run the tests, execute "example.sql" in SQL Plus or similar database client. Use a DBA account such as ADMIN.

There are pause commands in the script that will output "p...". Press carriage return to continue.

WARNING: The script will drop a table called T1 as well as TYPEs and a PL/SQL package.

DISCLAIMER:
- These scripts are provided for educational purposes only.
- They are NOT supported by Oracle World Wide Technical Support.
- The scripts have been tested and they appear to work as intended.
- You should always run scripts on a test instance.
