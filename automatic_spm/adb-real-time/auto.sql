--
-- Enable real-time SPM
--
exec dbms_spm.configure('AUTO_SPM_EVOLVE_TASK', 'AUTO')
