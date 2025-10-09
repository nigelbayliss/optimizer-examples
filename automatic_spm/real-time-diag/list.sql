--
-- List real-time SPM events
--
column plan_name format a40
column signature format 999999999999999999999999
column foreground_last_verified format a40
set linesize 200
set trims on
set tab off
break on signature
--
-- 'worse' means that the TEST plan performed worse than the reference plan it was compared to
-- 'better' means that the TEST plan performed better than the reference plan it was compared to
-- 'similar' means that the TEST plan performance was similar to the reference plan it was compared to
--
-- 'normal' means a plan change was seen and it was verified against a plan in the autmatic SQL tuning set (ASTS)
-- 'reverse' means a reverse verification check was made to ensure the plan previously chosen from ASTS out-performs the previously-rejected new plan
--
-- The plan hash values given for the test plan and reference plan are PHV2s 
-- For more on PHV2s, see https://blogs.oracle.com/optimizer/post/spm-cheat-sheet-part-1
--
-- Here is some example output. It is typically what you will see if a new plan performs worse than an old plan:
--   The new (test) plan with PHV2=1439196373 was compared to a previous (reference) plan in ASTS with PHV2=2340339719
--   The new plan performed worse and was not accepted (ACCEPTED=NO). 
--   The old plan (2340339719) was accepted and added to the SQL plan baseline to restore performance (see plan name SQL_PLAN_9mmnzp9rptjrr8b7ec007)
--   When the SQL statement was hard parsed again, the CBO still chose the 'bad' plan PHV2=1439196373, which caused a reverse verify to kick in
--   The plan that was accepted earlier (2340339719) performed better than the plan chosen by the CBO (1439196373), so the original decision to accept SQL_PLAN_9mmnzp9rptjrr8b7ec007 remained
--
--   The FOREGROUND_LAST_VERIFIED column indicates when each event occured: very quickly in this case, but sometimes is will take a while
--   for a reverse verification to kick in if there is a long wait for a new hard parse.
-- 
/*
                SIGNATURE PLAN_NAME                                ACC FOREGROUND_LAST_VERIFIED                 RESULT   VERIFY_T TEST_PLAN_PHV2 REFERENCE_PLAN_PHV2
------------------------- ---------------------------------------- --- ---------------------------------------- -------- -------- -------------- -------------------
     11082971287366977271 SQL_PLAN_9mmnzp9rptjrr55c864d5           NO  09-OCT-25 12.49.13.000000 PM             worse    normal       1439196373          2340339719
                          SQL_PLAN_9mmnzp9rptjrr8b7ec007           YES 09-OCT-25 12.49.13.000000 PM             better   reverse      2340339719          1439196373
*/
select p.signature,
       p.plan_name, 
       p.accepted, 
       p.foreground_last_verified, 
       pfspm.status result, 
       pfspm.ver verify_type,
       pfspm.test_phv test_plan_phv2,
       pfspm.ref_phv reference_plan_phv2
from dba_sql_plan_baselines p,
    XMLTABLE(
         '/notes'
         passing xmltype(p.notes)
         columns
             plan_id         NUMBER    path 'plan_id',
             flags           NUMBER    path 'flags',
             fg_spm          XMLType   path 'fg_spm') pf,
     XMLTABLE(
         '/fg_spm'
         passing pf.fg_spm
         columns
             ref_phv         NUMBER         path 'ref_phv',
             test_phv        NUMBER         path 'test_phv',
             ver             VARCHAR2(8)    path 'ver',
             status          VARCHAR2(8)    path 'status') (+) pfspm
where notes like '%<test_phv>%' 
order by p.signature, p.accepted, p.plan_name
;
