SELECT 
    dds.dd_session_id
  , ddd.dd_session_data_id
  , prs.name_full_formatted AS Session_held_by
  , (CAST ((FROM_TZ (CAST (dds.session_dt_tm  AS TIMESTAMP), '+00:00') AT TIME ZONE 'US/Eastern') AS DATE)) AS session_dt_tm
  , ddd.long_blob_id
  , ddd.session_data_key
  , note_type.display AS Note_Type
  , ce.event_title_text
  , ce.event_id
  , result_status.display AS Note_Status
  , pra.name_full_formatted AS author
  , (CAST ((FROM_TZ (CAST (ce.performed_dt_tm   AS TIMESTAMP), '+00:00') AT TIME ZONE 'US/Eastern') AS DATE)) AS  Performed_On
  , ea.alias AS CSN 
  , p.name_full_formatted AS Patient
  , pa.alias AS MRN
FROM
    dd_session dds
    inner join dd_contribution ddc on ddc.dd_contribution_id = dds.parent_entity_id
    inner join dd_session_data ddd on ddd.dd_session_id = dds.dd_session_id
    inner join prsnl prs on prs.person_id = dds.session_user_id
    inner join clinical_event ce on ce.parent_event_id = ddc.mdoc_event_id
           /* and ce.valid_until_dt_tm > sysdate  -- Need to cast as EST, damn it! */
           and (CAST ((FROM_TZ (CAST (ce.valid_until_dt_tm   AS TIMESTAMP), '+00:00') AT TIME ZONE 'US/Eastern') AS DATE)) > sysdate
    inner join code_value note_type on note_type.code_value = ce.event_cd
           and note_type.code_set = 72
    inner join code_value result_status on result_status.code_value = ce.result_status_cd
           and result_status.code_set = 8
    inner join code_value event_class on event_class.code_value = ce.event_class_cd
           and event_class.cdf_meaning = 'MDOC'
           and event_class.code_set = 53
    inner join prsnl pra on pra.person_id = ce.performed_prsnl_id
    inner join person p on p.person_id = ce.person_id
    inner join person_alias pa on pa.person_id = p.person_id
           and pa.active_ind = 1
           /* and pa.end_effective_dt_tm > sysdate -- Need to cast as EST, damn it! */
           and (CAST ((FROM_TZ (CAST (pa.end_effective_dt_tm  AS TIMESTAMP), '+00:00') AT TIME ZONE 'US/Eastern') AS DATE)) > sysdate
    inner join code_value alias_type  on alias_type.code_value = pa.person_alias_type_cd
           and alias_type.cdf_meaning ='MRN'
           and alias_type.code_set = 4
    inner join code_value alias_pool on alias_pool.code_value = pa.alias_pool_cd
           and alias_pool.display = 'CHB_MRN'
           and alias_pool.code_set = 263
    inner join encntr_alias ea on ea.encntr_id = ce.encntr_id
	       /* and ea.end_effective_dt_tm > sysdate  --  Need to cast as EST, damn it! */
	       and (CAST ((FROM_TZ (CAST (ea.end_effective_dt_tm   AS TIMESTAMP), '+00:00') AT TIME ZONE 'US/Eastern') AS DATE)) > sysdate
	       and ea.active_ind = 1
    inner join code_value encntr_alias_type on encntr_alias_type.code_value = ea.encntr_alias_type_cd
           and encntr_alias_type.display = 'FIN NBR'
           and encntr_alias_type.code_set = 319
where dds.parent_entity_name = 'DD_CONTRIBUTION'
  and dds.session_dt_tm > sysdate - 30 
  and dds.session_user_id =  5273996.00
ORDER BY dds.session_dt_tm desc,ddd.dd_session_data_id