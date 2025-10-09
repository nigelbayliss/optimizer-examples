--
-- Count the number of SQL performance regressions prevented 
-- by real-time SQL plan management SINCE the most recent upgrade.
-- If the database has not been upgraded, it reports "for all time".
--
-- The upgrade history is deduced from DBA_PDB_HISTORY
--

with ver_aux as
(
  select      p.signature,
              p.accepted,
              pfspm.status comp_res,
              pfspm.ref_phv,
              pfspm.test_phv,
              pfspm.ver
   from dba_sql_plan_baselines p,
         XMLTABLE(
              '/notes'
              passing xmltype(p.notes)
              columns
                  fg_spm          XMLType   path 'fg_spm') pf,
          XMLTABLE(
              '/fg_spm'
              passing pf.fg_spm
              columns
                  ref_phv         NUMBER         path 'ref_phv',
                  test_phv        NUMBER         path 'test_phv',
                  ver             VARCHAR2(8)    path 'ver',
                  status          VARCHAR2(8)    path 'status') (+) pfspm
   where notes is not null 
   and   foreground_last_verified > (select trunc(dy) 
                                     from (select db_version,min(op_timestamp) dy 
                                           from   dba_pdb_history 
                                           group by db_version order by db_version desc) 
                                     where rownum = 1)
   and   notes like '%<test_phv>%' )
 select nvl(count(*),0) regressions_prevented
 from ver_aux o
 where ver = 'normal'
   and comp_res = 'worse'
   and accepted = 'NO'
   and not exists
           (select 1 from ver_aux v
                   where ver = 'reverse'
                     and comp_res in ('similar', 'worse')
                     and v.signature = o.signature
                     and o.test_phv = v.ref_phv)
 ;
