# Secure View Merging

The optimizer_secure_view_merging parameter is depricated in Oracle Database 23ai.

The scripts here demonstrates how you can use the MERGE VIEW privilege instead.

NOTE! The script drops users U1 and U2 - always use a test database.

You must edit "example.sql" to change the container name to match your PDB.

Ths script assumes you can log into SYS using "connect / as SYSDBA". Edit the script if necessary.

# Disclaimer

   <br/>-- These scripts are provided for educational purposes only.
   <br/>-- They are NOT supported by Oracle World Wide Technical Support.
   <br/>-- The scripts have been tested and they appear to work as intended.
   <br/>-- You should always run scripts on a test instance.


