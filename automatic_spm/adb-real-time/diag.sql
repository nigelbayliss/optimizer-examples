column plan_name format a40
--
-- 'worse' means that a plan that's just been executed is worse than a plan in ASTS
-- 'better' means that a plan that's just been executed is better than a plan in ASTS
-- 'normal' means a plan changed has been spotted and is being verified against a plan in ASTS
-- 'reverse' means a reverse verification check is being made to ensure the plan previously chosen from ASTS out-performs the previously-rejected new plan
--
select p.plan_name, p.foreground_last_verified, pfspm.status result, pfspm.ver verify_type
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
             ver             VARCHAR2(8)    path 'ver',
             status          VARCHAR2(8)    path 'status') pfspm
where notes is not null
and sql_text like 'select /* SPM_TEST_QUERY_Q1%'
order by p.foreground_last_verified
;

