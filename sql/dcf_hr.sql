SELECT 
      Decode(HR.record_type_code,
        'WS',nvl(HR.CLASS_YEAR,'   '),
        'AL',nvl(HR.CLASS_YEAR,'   '),
        'ST',nvl(HR.CLASS_YEAR,'   '),
        '    ')                      as CLASS_YEAR,
      HR.DISPLAY_NAME                as DISPLAY_NAME,
      HR.SORT_NAME                  as SORT_NAME,
       to_char (nvl(hr.number_of_years_giving,0) + 1) as years_of_giving,
      Decode(HR.RECORD_STATUS_CODE,
        'D','Y',
        'Z','Y',
        'N')                      as DECEASED_IND,
      Decode(HR.RECORD_TYPE_CODE,
        'WS','Y',
        'N')                      as WIDOW_IND,
      Decode(HR.AFFIL_STATUS_CODE,
        'A','Y',
        'N')                      as ADOPTED_IND,
      nvl((select distinct 'Y'
        from    advance.committee com
        where    com.id_number = hr.id_number
              and com.committee_code in ('ALFV','ALFC','RGC','PAR')
              and com.committee_status_code = 'C'
              union
              select distinct 'Y'
        from    advance.committee com
        where    com.id_number = hr.id_number
              and com.committee_code in ('CLAS')
              and com.committee_role_code = 'BC'
              and com.committee_status_code = 'C'
              ),'N')    as DCFVOL_IND,
case when bts.gift_club_id_number is not null then 'Y' else 'N' end  as BTS_IND,
     case when HR.class_year = '2016' then 'Y' when
       ripley.gift_club_id_number is not null then 'Y' else 'N' end as ripley_ind,
    case when ld.id_number is not null and ld.mail_list_status_code = 'CUR' then 'N'
       when gc_override.id_number is not null then 'Y'
      when members.id_number is not null then 'Y'
      when ld.id_number is not null then 'Y' else 'N' end as a1769_ind,
      Decode(nvl(cp.cash_participation,' '),
        ' ',' ',
        decode(HR.record_type_code,
          'WS',to_char(nvl(CP.CASH_PARTICIPATION,' '))||' %',
          'AL',to_char(nvl(CP.CASH_PARTICIPATION,' '))||' %',
          'ST',to_char(nvl(CP.CASH_PARTICIPATION,' '))||' %',
          '     ')
      )                          as CLASS_PARTICIPATION,
      aeo.get_dcf_current_fy            as DCF_year
FROM    (Select partic_table.class_year as YOG, 
                to_char(round(100*partic_table.num_donors/partic_table.base,1)) as CASH_PARTICIPATION
        From  (SELECT af.class_year ,
                   COUNT(DISTINCT ent.id_number)  as base,
                     (select count(*)
                      from   aeo.EDW_AD_DW_SOURCE_AGG dcf, 
                             advance.entity        e
                      where  dcf.dir_dcf_af_cash_particip_cy = 'Y'  
                             and dcf.id_number = e.id_number
                             and e.record_type_code = 'AL'
                             and e.record_status_code in ('A','R')
                             and e.pref_school_code = 'DC'
                             and af.class_year = e.pref_class_year
                             and not exists 
                                 (select 'x' from affiliation a
                                 where e.id_number = a.id_number
                                       and a.affil_code = 'DC'
                                       and a.record_type_code = 'AL'
                                       and a.affil_status_code = 'A') ) as num_donors  
                FROM affiliation af, entity ent, address
              WHERE af.record_type_code = 'AL'
                 AND af.affil_code = 'DC' 
                 AND af.affil_status_code NOT IN ('A', 'U') 
                 AND ent.id_number = af.id_number
                 AND ent.record_status_code IN ('A', 'R') 
                 AND address.id_number = af.id_number 
                 AND address.addr_pref_ind = 'Y'
                 AND address.addr_status_code = 'A'
              GROUP BY af.class_year )partic_table)   CP,
              (select g.gift_club_id_number 
                      from gift_clubs g
                      where g.gift_club_code = 'HRP'
                      and g.gift_club_status = 'A') ripley,
              (select agg.id_number, mm.mail_list_status_code
              from aeo.edw_ad_dw_source_agg agg, mailing_list mm
              where agg.DCF_AF_1769_SOC_ELIG_FLAG = 'Y'
              and mm.id_number(+) = agg.id_number
              and mm.mail_list_code(+) = '1769X') ld,
              (select distinct t.gift_club_id_number
from gift_clubs t, aeo.gift_clubs_pubname p
where t.gift_club_code = p.gift_club_code
and t.gift_club_sequence = p.gift_club_sequence
and t.gift_club_id_number = p.gift_club_id_number
and t.gift_club_code = 'BTS'
and t.gift_club_status = 'A'
and t.gift_club_type in ('MBR','PMB')
and UPPER(p.published_name)  NOT LIKE '%ANONY%')  bts,
              (select views.id_number
              from aeo.edw_ad_dw_source_agg views
              where views.DCF_AF_1769_SOC_ELIG_FLAG ='Y') members,
                            (select gc.gift_club_id_number id_number,
gc.gift_club_code  from gift_clubs gc
where gc.gift_club_code = '176'
and gc.gift_club_start_date between '20170701' and '20180630'
and gc.gift_club_status = 'A') gc_override,
            (Select  affiliation.id_number,                              
                    affiliation.record_type_code                  as RECORD_TYPE_CODE,
                    nvl(Affiliation.class_year,' ')                  as CLASS_YEAR,
                    ENTITY.PREF_MAIL_NAME                  as DISPLAY_NAME,
                    ENTITY.PREF_NAME_SORT                  as SORT_NAME,
                    dcf.Dcf_Af_Tot_Yrs_Gvng    as Number_of_years_giving ,
                    ENTITY.RECORD_STATUS_CODE              as RECORD_STATUS_CODE,                          
                    AFFILIATION.AFFIL_STATUS_CODE            as AFFIL_STATUS_CODE,
                    aeo.get_dcf_current_fy                    as DCF_year
              From    AEO.EDW_AD_DW_SOURCE_AGG dcf,
                    advance.entity          ENTITY,
                    advance.AFFILIATION      AFFILIATION
              Where  ENTITY.id_number = AFFILIATION.id_number (+)
                    and Entity.person_or_org = 'P'
                    and AFFILIATION.affil_code (+) = 'DC'
                    and AFFILIATION.affil_primary_ind (+) = 'Y'
                    and dcf.id_number = Entity.id_number
                    and ( dcf.DIR_DCF_AF_GFT_CUR_YR + dcf.dir_dcf_af_pldg_pymt_cur_yr >0 or
                       dcf.dir_dcf_af_cash_particip_cy = 'Y')
                    and not exists
                          (select  'Y' as Flag1
                          from    ADVANCE.MAILING_LIST
                          where    ADVANCE.MAILING_LIST.id_number = ENTITY.id_number
                                and ADVANCE.MAILING_LIST.MAIL_LIST_CODE = 'HREXC'
                                and ADVANCE.MAILING_LIST.MAIL_LIST_STATUS_CODE = 'CUR') 
                    and ENTITY.Record_status_code <> 'Y'
              Union
              Select  affiliation.id_number, 
                    affiliation.record_type_code                  as RECORD_TYPE_CODE,
                    NVL(Affiliation.class_year,' ')                as CLASS_YEAR,
                    ENTITY.PREF_MAIL_NAME                  as DISPLAY_NAME,
                    ENTITY.PREF_NAME_SORT                  as SORT_NAME,
                    dcf.Dcf_Af_Tot_Yrs_Gvng    as Number_of_years_giving ,
                    ENTITY.RECORD_STATUS_CODE              as RECORD_STATUS_CODE,                          
                    AFFILIATION.AFFIL_STATUS_CODE            as AFFIL_STATUS_CODE,
                    aeo.get_dcf_current_fy                    as DCF_year
              From    AEO.EDW_AD_DW_SOURCE_AGG dcf,
                    advance.entity          ENTITY,
                    advance.AFFILIATION      AFFILIATION
              Where    ENTITY.id_number = AFFILIATION.id_number (+)
                    AND AFFILIATION.affil_code (+) = 'DC'
                    AND AFFILIATION.affil_primary_ind (+) = 'Y'
                    AND dcf.id_number (+) = Entity.id_number
                    AND EXISTS
                        (select  * 
                        from    ADVANCE.MAILING_LIST
                        where    ADVANCE.MAILING_LIST.id_number = ENTITY.id_number
                              and ADVANCE.MAILING_LIST.MAIL_LIST_CODE = 'HRINC'
                              and ADVANCE.MAILING_LIST.MAIL_LIST_STATUS_CODE = 'CUR')
                    AND  NOT EXISTS
                         (select  * 
                         from    ADVANCE.MAILING_LIST
                         where  ADVANCE.MAILING_LIST.id_number = ENTITY.id_number
                              and ADVANCE.MAILING_LIST.MAIL_LIST_CODE = 'HREXC'
                              and ADVANCE.MAILING_LIST.MAIL_LIST_STATUS_CODE= 'CUR')
                    AND  ENTITY.RECORD_STATUS_CODE <>'Y') HR
WHERE  HR.class_year = CP.YOG(+)
and ripley.gift_club_id_number(+) = hr.id_number
and ld.id_number(+) = hr.id_number
and hr.id_number = members.id_number(+)
and gc_override.id_number(+) = hr.id_number
and bts.gift_club_id_number(+) = hr.id_number
UNION
SELECT     
        Anon.CLASS_YEAR              as CLASS_YEAR,
        ' Anonymous ('||Anon.AnonCnt||')'    as DISPLAY_NAME,
        ' Anonymous'                as SORT_NAME,
        ' '                        as YEARS_OF_GIVING,
        'N'                        as DECEASED_IND,
        'N'                        as WIDOW_IND,
        'N'                        as ADOPTED_IND,
        'N'                        as DCFVOL_IND,
        'N'                        as BTS_IND,
        'N'                        as ripley_ind,
          'N' lead_soc_ind,
        Decode(nvl(cp.cash_participation,' '),
            ' ','     ',
            to_char(nvl(CP.CASH_PARTICIPATION,' '))||' %'  )  as CLASS_PARTICIPATION,
        Anon.DCF_Year                as DCF_year
FROM    (Select partic_table.class_year as YOG, 
                to_char(round(100*partic_table.num_donors/partic_table.base,1)) as CASH_PARTICIPATION
        From  (SELECT af.class_year ,
                   COUNT(DISTINCT ent.id_number)  as base,
                     (select count(*)
                      from   aeo.EDW_AD_DW_SOURCE_AGG dcf, 
                             advance.entity        e
                      where  dcf.dir_dcf_af_cash_particip_cy = 'Y'  
                             and dcf.id_number = e.id_number
                             and e.record_type_code = 'AL'
                             and e.record_status_code in ('A','R')
                             and e.pref_school_code = 'DC'
                             and af.class_year = e.pref_class_year
                             and not exists 
                                 (select 'x' from affiliation a
                                 where e.id_number = a.id_number
                                       and a.affil_code = 'DC'
                                       and a.record_type_code = 'AL'
                                       and a.affil_status_code = 'A') ) as num_donors  
                FROM affiliation af, entity ent, address
              WHERE af.record_type_code = 'AL'
                 AND af.affil_code = 'DC' 
                 AND af.affil_status_code NOT IN ('A', 'U') 
                 AND ent.id_number = af.id_number
                 AND ent.record_status_code IN ('A', 'R') 
                 AND address.id_number = af.id_number 
                 AND address.addr_pref_ind = 'Y'
                 AND address.addr_status_code = 'A'
              GROUP BY af.class_year )partic_table)   CP,
      (Select  anonymous.class_year,
            anonymous.dcf_year,
            count(distinct anonymous.id_number)    as AnonCnt
      From (select    affiliation.id_number,      
                nvl(Affiliation.class_year,' ')          as CLASS_YEAR,
                aeo.get_dcf_current_fy            as DCF_year
          from    AEO.EDW_AD_DW_SOURCE_AGG dcf,
                advance.entity        ENTITY,
                advance.AFFILIATION    AFFILIATION
          where    ENTITY.id_number = AFFILIATION.id_number (+)
                and Entity.person_or_org = 'P'
                and AFFILIATION.affil_code (+) = 'DC'
                and AFFILIATION.affil_primary_ind (+) = 'Y'
                and ENTITY.RECORD_STATUS_CODE = 'Y'
                and dcf.id_number = Entity.id_number
                and ( dcf.DIR_DCF_AF_GFT_CUR_YR + dcf.dir_dcf_af_pldg_pymt_cur_yr >0 
                    or dcf.dir_dcf_af_cash_particip_cy = 'Y' )
                and Not exists
                    (select  'Y' as Flag1
                    from    ADVANCE.MAILING_LIST
                    where    ADVANCE.MAILING_LIST.id_number = ENTITY.id_number
                          and ADVANCE.MAILING_LIST.MAIL_LIST_CODE = 'HREXC'
                          and ADVANCE.MAILING_LIST.MAIL_LIST_STATUS_CODE= 'CUR') 
                and AFFILIATION.RECORD_TYPE_CODE in ('WS','ST','AL')
          union
          select    affiliation.id_number,        
                ' '                        as CLASS_YEAR,
                aeo.get_dcf_current_fy          as DCF_year
          from    AEO.EDW_AD_DW_SOURCE_AGG dcf,
                advance.entity        ENTITY,
                advance.AFFILIATION    AFFILIATION
          where      ENTITY.id_number = AFFILIATION.id_number (+)
                and Entity.person_or_org = 'P'
                and AFFILIATION.affil_code (+) = 'DC'
                and AFFILIATION.affil_primary_ind (+) = 'Y'
                and ENTITY.RECORD_STATUS_CODE = 'Y'
                and dcf.id_number = Entity.id_number
                and ( dcf.DIR_DCF_AF_GFT_CUR_YR + dcf.dir_dcf_af_pldg_pymt_cur_yr >0 
                   or dcf.dir_dcf_af_cash_particip_cy = 'Y')
                and entity.pref_class_year <= aeo.get_dcf_current_fy
                and Not exists
                    (select  'Y' as Flag1
                    from    ADVANCE.MAILING_LIST
                    where    ADVANCE.MAILING_LIST.id_number = ENTITY.id_number
                          and ADVANCE.MAILING_LIST.MAIL_LIST_CODE = 'HREXC'
                          and ADVANCE.MAILING_LIST.MAIL_LIST_STATUS_CODE= 'CUR') 
                and AFFILIATION.RECORD_TYPE_CODE <>'WS'
                and AFFILIATION.RECORD_TYPE_CODE <>'ST'
                and AFFILIATION.RECORD_TYPE_CODE <>'AL'
          union
          select    affiliation.id_number,      
                nvl(Affiliation.class_year,' ')        as CLASS_YEAR,
                aeo.get_dcf_current_fy          as DCF_year
          from    AEO.EDW_AD_DW_SOURCE_AGG dcf,
                advance.entity        ENTITY,
                advance.AFFILIATION    AFFILIATION
          where    ENTITY.id_number = AFFILIATION.id_number (+)
                and Entity.person_or_org = 'P'
                and AFFILIATION.affil_code (+) = 'DC'
                and AFFILIATION.affil_primary_ind (+) = 'Y'
                and dcf.id_number = Entity.id_number
                and ( dcf.DIR_DCF_AF_GFT_CUR_YR + dcf.dir_dcf_af_pldg_pymt_cur_yr >0 
                    or dcf.dir_dcf_af_cash_particip_cy = 'Y' )
                and exists
                    (select  'Y' as Flag1
                    from    ADVANCE.MAILING_LIST
                    where    ADVANCE.MAILING_LIST.id_number = ENTITY.id_number
                          and ADVANCE.MAILING_LIST.MAIL_LIST_CODE = 'HREXC'
                          and ADVANCE.MAILING_LIST.MAIL_LIST_STATUS_CODE= 'CUR') 
                and AFFILIATION.RECORD_TYPE_CODE in ('WS','ST','AL')
                and entity.pref_class_year <= aeo.get_dcf_current_fy
          union
          select    affiliation.id_number,        
                ' '                        as CLASS_YEAR,
                aeo.get_dcf_current_fy          as DCF_year
          from    AEO.EDW_AD_DW_SOURCE_AGG dcf,
                advance.entity        ENTITY,
                advance.AFFILIATION    AFFILIATION
          where     ENTITY.id_number = AFFILIATION.id_number (+)
                and Entity.person_or_org = 'P'
                and AFFILIATION.affil_code (+) = 'DC'
                and AFFILIATION.affil_primary_ind (+) = 'Y'
                and dcf.id_number = Entity.id_number
                and ( dcf.DIR_DCF_AF_GFT_CUR_YR + dcf.dir_dcf_af_pldg_pymt_cur_yr >0 
                    or dcf.dir_dcf_dcf_cash_particip_cy= 'Y' )
                and exists
                    (select  'Y' as Flag1
                    from    ADVANCE.MAILING_LIST
                    where    ADVANCE.MAILING_LIST.id_number = ENTITY.id_number
                          and ADVANCE.MAILING_LIST.MAIL_LIST_CODE = 'HREXC'
                          and ADVANCE.MAILING_LIST.MAIL_LIST_STATUS_CODE= 'CUR') 
                and AFFILIATION.RECORD_TYPE_CODE <>'WS'
                and AFFILIATION.RECORD_TYPE_CODE <>'ST'
                and AFFILIATION.RECORD_TYPE_CODE <>'AL'
          union
          select    affiliation.id_number,            
                nvl(Affiliation.class_year,' ')        as CLASS_YEAR,
                aeo.get_dcf_current_fy          as DCF_year
          from    AEO.EDW_AD_DW_SOURCE_AGG,
                          advance.entity        ENTITY,
                advance.AFFILIATION    AFFILIATION
          where    ENTITY.id_number = AFFILIATION.id_number (+)
                AND AFFILIATION.affil_code (+) = 'DC'
                AND AFFILIATION.affil_primary_ind (+) = 'Y'
                AND AEO.EDW_AD_DW_SOURCE_AGG.id_number (+) = Entity.id_number
                AND EXISTS
                    (select  * 
                    from    ADVANCE.MAILING_LIST
                    where    ADVANCE.MAILING_LIST.id_number = ENTITY.id_number
                          and ADVANCE.MAILING_LIST.MAIL_LIST_CODE = 'HRINC'
                          and ADVANCE.MAILING_LIST.MAIL_LIST_STATUS_CODE = 'CUR')
                AND   NOT EXISTS
                    (select  * 
                    from    ADVANCE.MAILING_LIST
                    where    ADVANCE.MAILING_LIST.id_number = ENTITY.id_number
                          and ADVANCE.MAILING_LIST.MAIL_LIST_CODE = 'HREXC'
                          and ADVANCE.MAILING_LIST.MAIL_LIST_STATUS_CODE= 'CUR')
                AND ENTITY.RECORD_STATUS_CODE ='Y'
                and AFFILIATION.RECORD_TYPE_CODE in ('WS','AL','ST')
          union
          select    affiliation.id_number,            
                ' '                        as CLASS_YEAR,
                aeo.get_dcf_current_fy          as DCF_year
          from    AEO.EDW_AD_DW_SOURCE_AGG,
                advance.entity        ENTITY,
                advance.AFFILIATION    AFFILIATION
          where    ENTITY.id_number = AFFILIATION.id_number (+)
                AND AFFILIATION.affil_code (+) = 'DC'
                AND AFFILIATION.affil_primary_ind (+) = 'Y'
                AND AEO.EDW_AD_DW_SOURCE_AGG.id_number   (+) = Entity.id_number
                AND EXISTS
                    (select  * 
                    from    ADVANCE.MAILING_LIST
                    where    ADVANCE.MAILING_LIST.id_number = ENTITY.id_number
                          and ADVANCE.MAILING_LIST.MAIL_LIST_CODE = 'HRINC'
                          and ADVANCE.MAILING_LIST.MAIL_LIST_STATUS_CODE = 'CUR')
                AND   NOT EXISTS
                    (select  * 
                    from    ADVANCE.MAILING_LIST
                    where    ADVANCE.MAILING_LIST.id_number = ENTITY.id_number
                          and ADVANCE.MAILING_LIST.MAIL_LIST_CODE = 'HREXC'
                          and ADVANCE.MAILING_LIST.MAIL_LIST_STATUS_CODE= 'CUR')
                AND ENTITY.RECORD_STATUS_CODE ='Y'
                and AFFILIATION.RECORD_TYPE_CODE <> 'WS'
                and AFFILIATION.RECORD_TYPE_CODE <> 'AL'
                and AFFILIATION.RECORd_TYPE_CODE <> 'ST'  ) Anonymous
      Group by  anonymous.class_year,
            anonymous.dcf_year) anon
WHERE  Anon.class_year = CP.yog (+)
ORDER BY   1,3
