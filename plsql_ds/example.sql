column pref_value format a30
column procedure_name format a20
set trims on 
set tab off
--
-- We want plans without the result cache
--
alter session set result_cache_mode = 'MANUAL';

@@tab
@@pack

--
--  Report actual stats for queries
--
alter session set statistics_level='ALL';

prompt TEST 1 =========================================================================================
--
--  Control PL/SQL dynamic sampling with preferences
--
exec dbms_stats.set_global_plsql_prefs('dynamic_stats','OFF')
select dbms_stats.get_plsql_prefs('dynamic_stats') pref_value
from dual;

--
-- With dynamic sampling, our literal example yields good estimates
--
select /* Q1 */ count(*) 
from   t1
where  (a = 20 and  b = 40)
or      a = 10;

@@plan

--
-- Dynamic sampling is enabled, but PL/SQL dynamic samping is disabled
-- The estimates will not be accurate when functions are used like this
--
select /* Q2 */ count(*)
from   t1
where  (a = ds_test.fnum(20) and b = ds_test.fnum2(40))
or     a = 10;

@@plan

--
-- Dynamic sampling is enabled, but PL/SQL dynamic samping is disabled
-- The estimates will not be accurate when functions are used like this
--
select /* Q3 */ count(*) 
from table(ds_test.ftab(1000));

@@plan

pause p...

prompt TEST 2 =========================================================================================
--
-- Go back to default preference settings
--
exec dbms_stats.set_global_plsql_prefs('dynamic_stats',null)
select dbms_stats.get_plsql_prefs('dynamic_stats') pref_value
from dual;

--
-- PL/SQL DS global preference is CHOOSE, and consistent with
-- pre-RU23.8, PL/SQL dynamic sampling will be used for the function
-- Estimate is good
--
select /* Q4 */ count(*)
from   t1
where  (a = ds_test.fnum(20) and b = ds_test.fnum2(40))
or     a = 10;
@@plan

--
-- PL/SQL DS global preference is CHOOSE, and consistent with
-- pre-RU23.8, PL/SQL dynamic sampling will be NOT be used for a
-- table function 
-- Estimate is poor
--
select /* Q5 */ count(*) 
from table(ds_test.ftab(1000));

@@plan

--
-- PL/SQL DS global preference is CHOOSE, however, consistent with
-- pre-RU23.8, PL/SQL dynamic sampling WILL be used for the
-- table function because of the hint
-- Estimate is good
--
select /* Q6 */ /*+ dynamic_sampling(6) */ count(*)
from table(ds_test.ftab(1000));

@@plan

pause p...

prompt TEST 3 =========================================================================================
--
-- Enable dynamic sampling with PL/SQL functions
--
exec dbms_stats.set_global_plsql_prefs('dynamic_stats','ON')
select dbms_stats.get_plsql_prefs('dynamic_stats') pref_value from dual;

--
-- We get dynamic sampling and a good estimate for our PL/SQL functions
-- Estimate is good
--
select /* Q7 */ count(*)
from   t1
where  (a = ds_test.fnum(20) and b = ds_test.fnum2(40))
or     a = 10;
@@plan

--
-- Dynamic sampling for PL/SQL table functions is enabled too
-- Estimate is good
--
select /* Q8 */ count(*) 
from table(ds_test.ftab(1000));

@@plan

--
-- Also PL/SQL pipelined table functions
-- Estimate is good
--
select /* Q9 */ count(*) 
from table(ds_test.fpipe(500));

@@plan

pause p...

prompt TEST 4 =========================================================================================
exec dbms_stats.set_plsql_prefs(user,'ds_test',null,'dynamic_stats','OFF')
select dbms_stats.get_plsql_prefs('dynamic_stats',user,'ds_test','fnum') pref_value from dual;
select dbms_stats.get_plsql_prefs('dynamic_stats',user,'ds_test','fnum2') pref_value from dual;

--
-- This is the main usecase for this new feature
-- PL/SQL DS is enabled, but we want to explicitly prevent particular PL/SQL packages
-- from being called at parse time. In this example, PL/SQL dynamic has been 
-- disabled specifically for the functions used in the query predicates 
-- No PL/SQL DS, and estimate is not accurate
--
select /* Q10 */ count(*)
from   t1
where  (a = ds_test.fnum(20) and b = ds_test.fnum2(40))
or     a = 10;
@@plan

pause p...

prompt TEST 5 =========================================================================================
--
-- Now turn the global preference off
--
exec dbms_stats.set_global_plsql_prefs('dynamic_stats','OFF')
select dbms_stats.get_plsql_prefs('dynamic_stats') pref_value from dual;
--
-- The global preference has set PL/SQL DS OFF, but we can override with a preference set for the package
-- Note that get_plsql_prefs retrieves values for individual functions, not the whole package
-- The estimate is good again
--
exec dbms_stats.set_plsql_prefs(user,'ds_test',null,'dynamic_stats','ON')
select dbms_stats.get_plsql_prefs('dynamic_stats',user,'ds_test','fnum') pref_value from dual;
select dbms_stats.get_plsql_prefs('dynamic_stats',user,'ds_test','fnum2') pref_value from dual;
select procedure_name,
       dynamic_sampling_on, 
       dynamic_sampling_off,
       dynamic_sampling_choose
from   user_procedures
where  procedure_name like 'FNUM%';

select /* Q11 */ count(*)
from   t1
where  (a = ds_test.fnum(20) and b = ds_test.fnum2(40))
or     a = 10;

@@plan
--
-- PL/SQL DS global pref is still OFF, and now delete the function preferences
--
exec dbms_stats.delete_plsql_prefs(user,'ds_test',null,'dynamic_stats')
--
-- No PL/SQL DS because we've deleted the package/function preference and the global pref is OFF
--
select /* Q12 */ count(*)
from   t1
where  (a = ds_test.fnum(20) and b = ds_test.fnum2(40))
or     a = 10;

@@plan

exec dbms_stats.delete_plsql_prefs(user,'ds_test',null,'dynamic_stats')
select procedure_name,
       dynamic_sampling_on,
       dynamic_sampling_off,
       dynamic_sampling_choose
from   user_procedures
where  procedure_name like 'FNUM%';

--
-- Back to default
--
exec dbms_stats.set_global_plsql_prefs('dynamic_stats',null)

@@drop
