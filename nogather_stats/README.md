Demo to debunk the idea that if you don't gather statistics, plans will not change.

The script is designed to run in SQL Plus

Log into an Oraccle use account has privs to create tables and execute "demo.sql"

An example output is given: "demo.lst". Observe that the plan for
the SQL statement changes, but statistics were not gathered.

The plan change occurs because the value of bind2 has changed to
retrieve new data from the database, but the statistics for the 
table (and its columns) do not reflect the fact that this value exists
in the database. This results in a cardinaality misestimate because the
optimizer believes that no rows have V2 = 10000

You might need to adjust the script in some cases because the
choice of plan is sensitive to your database environment.

### DISCLAIMER

*  These scripts are provided for educational purposes only.
*  They are NOT supported by Oracle World Wide Technical Support.
*  The scripts have been tested and they appear to work as intended.
*  You should always run scripts on a test instance.

### WARNING

*  These scripts drop and create tables. For use on test databases.
