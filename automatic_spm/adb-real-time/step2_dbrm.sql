@@dbrm_on

@@plan_bad
--
-- The Note section indicates invalidations
-- We've manipulated the plan with hints to cause a performance
-- regression. Real-time SPM will detect the plan change
-- and reinstate the old plan.
--
@@q
--
-- The SQL plan baseline is used
--
@@q
--
-- We'll force a hard parse and double-check we have the SQL plan baseline
--
@@flush
@@q
@@diag

@@dbrm_off
