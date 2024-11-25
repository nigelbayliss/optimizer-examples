--
-- Disable automatic SPM
--
exec dbms_spm.configure('AUTO_SPM_EVOLVE_TASK', 'OFF')
