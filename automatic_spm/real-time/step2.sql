@@flush
@@cost_good
--
-- The Note section indicates real-time SPM is active
-- This new plan is better than the old plan, and we 
-- want real-time SPM to enforce it
--
@@q
--
-- We'll force a hard parse so that the Note section will be
-- updated and allow us to see the SQL plan baseline explicitly
--
@@flush
@@q
@@diag
