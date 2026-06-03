# Introduction

How to detect the potential need for column groups (and create them automatically).

There are two approaches demonstrated here:

1. Parse a test query while column usage seeding is enabled and create column groups
2. Create column groups from a SQL tuning set

# Demos

There are four demos:
<pre>
    SQL> -- Use column usage tracking to identify useful column groups
    SQL> -- for a SQL statement in the cursor cache (identified using a SQL ID)
    SQL> -- The utility script that does most of the work is "cg_from_sqlid.sql"
    SQL> @run_test1
    SQL> -- Use column usage tracking to identify useful column groups
    SQL> -- for SQL statements in a SQL tuning set (identified using the SQLSET name)
    SQL> -- The utility script that does most of the work is "cg_from_sts.sql"
    SQL> @run_test3
</pre>

# Stand-alone scripts

-  "gather_ext.sql" is provided to demonstrate how to gather stats on extended statistics if stats have never been gathered.
-  "cg_from_sqlid.sql" creates column groups for a SQL statement in the cursor cache
-  "cg_from_sts.sql" create column groups for SQL statements in a SQL tuning set
-  "cg_from_plan.sql" create column groups for a SQL statement parsed with EXPLAIN PLAN (you must enable seeding before the explain plan)

# Experimental script
-  "corr_from_table.sql" will sample colums to see if they have correlated values. There are a number of caveats - see script for details.
For example:
<pre>
SQL> Check myuser.mytable, sampling 100% of rows, and create the column groups immediately
SQL> @corr_from_table myuser mytable 100 Y
</pre>

# Notes

There used to be more example scripts, but I've removed them for now. They were useful, but not mathematically sound. I will return to them at a later date to see if I can resolve this issue.

# Disclaimer

   <br/>-- These scripts are provided for educational purposes only.
   <br/>-- They are NOT supported by Oracle World Wide Technical Support.
   <br/>-- The scripts have been tested and they appear to work as intended.
   <br/>-- You should always run scripts on a test instance.


