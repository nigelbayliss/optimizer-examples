@@cost_bad
--
-- The Note section indicates invalidations
-- We've manipulated to cost to cause a plan performance
-- regression. Real-time SPM will detect the plan change
-- and reinstate the old plan.
--
alter session set tracefile_identifier='FSPM';
alter session set events 'trace[sql_plan_management]';
@@q

select p.TRACEFILE
from v$session s,v$process p
where s.paddr=p.addr
and s.username is not null;
