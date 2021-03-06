/*****************************************************
프로그램명  : ITF_ORDER_4.sql
작성자      : Won Jong Bok
수정자      :
최초 작성일 : 2020-12-03
수정일      :
소스 테이블(기본) :MMMEDORT(약처방),  MNBLOODT(수혈기록), MMTRTORT(처치/재료/수술료/마취료처방)
                   MMEXMORT(검사), MMREHORT(치료처방)  -> 이 테이블은 ods_daily.mmorderv  view형태의 테이블에 모여 있음 아래 sql 참고
소스 테이블(참조) : MNWADACT(병동실시내역), MNOUTACT(외래실시내역)
프로그램 설명 : 처방관련 (처치, 약, 재료) 데이터 적재
cnt:
*****************************************************/
DROP TABLE if exists itfcdmpv532_daily.itf_order_4;;

CREATE  TABLE itfcdmpv532_daily.itf_order_4 AS
 SELECT A.patno
            , A.patfg                AS visit_gb
            , A.ordcode              AS order_cd
            , A.ordseqno::VARCHAR  AS order_seq
            , NULL                   AS order_sub_cd
            , NULL                   AS start_dt
            , A.orddate              AS order_dt
            , A.meddate              AS medical_dt
            , null               	AS operation_dt
            , null		             AS act_dt  
            , null             AS anesthesia_dt
            , A.meddept              AS medical_dept
            , 'N'                   AS self_drug_yn
            , null      AS operation_seq
            , 'N'                    AS tot_order_yn
            , NULL                   AS tot_order_qty
            , NULL                   AS order_day
            , 1                      AS order_qty1
            , NULL                   AS order_qty2
            , NULL 					 AS order_cnt
            , A.orddr                AS order_dr
            , NULL                   AS procedure_provider
            , NULL                   AS device_provider
            , A.chadr                AS charge_dr
            , NULL                 AS operation_dr
            , NULL              AS anesthesia_dr
            , NULL                   AS act_dr
            , NULL                   AS act_provider
            , NULL                   AS medical_dr
            , A.ordclstyp            AS order_class_gb
            , A.dcyn                 AS dc_yn1
            , NULL                   AS dc_yn2
            , dcordseq::VARCHAR    AS dc_order_seq
            , A.mkfg                 AS order_gb
            , 'Y'                    AS act_yn--CASE WHEN (B.ordclsfg IN ('F1','D1','C2','C3') OR C.ordclstyp ='D1') AND COALESCE(nullif(B.ACTFG, ''), nullif(C.ACTYN, ''), 'Y') = 'Y' THEN 'Y' ELSE 'N' END AS act_yn
            , A.PRNACTYN             AS prn_order_yn
            , 'N'                    AS prn_act_yn
            , 'N'                    AS pre_order_yn
            , 'N'                    AS pre_order_act_yn
            , C.methodcd             AS method_cd
            , NULL                   AS verbatim_end_date
            , NULL                   AS stop_dt
            , NULL                   AS stop_cause
            , A.remark
            , NULL                   AS drug_unit
            , NULL                   AS refill_cnt
            , NULL                   AS lot_number
            , 'N'                    AS discharge_drug_yn
            , NULL                   AS modality_cd
            , NULL                   AS unique_no
            , NULL                   AS cancel_dt
            , NULL                   AS cancel_yn
            ,  '처치'::varchar(50) reference_gb
            , a.edittime::timestamp  lastupdate_dt
            , a.wardno               AS ward_cd
 FROM ods_daily.MMREHORT  A
 LEFT JOIN ods_daily.MNWADACT B ON A.PATNO = B.PATNO AND A.meddate = B.admtime AND A.ORDDATE = B.ORDDATE AND A.ORDSEQNO = B.ORDSEQNO AND
                               A.ORDCODE = B.ORDCODE AND A.PATFG IN ('E', 'I', 'D') AND B.rejttime IS NULL
 LEFT JOIN ods_daily.mnoutact C ON A.PATNO = C.PATNO AND A.meddept = C.meddept AND A.ORDDATE = C.ORDDATE AND A.ORDSEQNO = C.ORDSEQNO AND
                               A.ORDCODE = C.ORDCODE AND A.PATFG IN ('G','H','M','O') AND C.rejttime is null
 WHERE  A.ordclstyp = 'F1';
/*
 *SQL Error [23505]: ERROR: duplicate key value violates unique constraint "pg_type_typname_nsp_index"
  Detail: Key (typname, typnamespace)=(itf_order_4, 16396) already exists.
 */


 -----------------------------check cnt
insert into ods_daily.etl_task_check(task_grp_id, task_id, table_name, cnt)
select (SELECT last_value FROM etl_task_check_grp_id), 'itf_order_4' , 'itf_order_4', count(*) as cnt
from itfcdmpv532_daily.itf_order_4 ;
