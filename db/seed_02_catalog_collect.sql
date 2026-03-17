/*
 * seed_02_catalog_collect.sql — 카탈로그·메타데이터 + 수집관리 도메인
 * 의존성: seed_01_core.sql 선행
 */

-- ============================================================================
-- 1. 원천시스템 (src_sys)
-- ============================================================================
INSERT INTO src_sys (sys_cd, sys_nm, sys_nm_en, dc, dbms_ty, prtcl, ntwk_zone, owner_dept_id, stat) VALUES
    ('SYS_SAP',    'SAP ERP',        'SAP ERP System',     'K-water 전사 ERP 시스템',           'SAP_HANA',   'RFC',   'internal', 14, 'active'),
    ('SYS_SCADA',  'SCADA',          'SCADA System',       '댐·보 실시간 감시 시스템',           'PostgreSQL', 'TCP',   'dmz',      1,  'active'),
    ('SYS_TMS',    '수질TMS',        'Water Quality TMS',  '실시간 수질 자동측정 시스템',         'Oracle',     'HTTP',  'dmz',      4,  'active'),
    ('SYS_GIS',    '수자원GIS',      'GIS Platform',       '공간정보 플랫폼',                    'PostgreSQL', 'REST',  'internal', 2,  'active'),
    ('SYS_HYDRO',  '수력발전SCADA',  'Hydro Power SCADA',  '수력발전소 발전량·운전 데이터',       'MSSQL',      'OPC',   'internal', 6,  'active'),
    ('SYS_WEATHER','기상청API',      'KMA Open API',       '기상청 공공데이터 API',              NULL,         'REST',  'external', 10, 'active'),
    ('SYS_WIMS',   'WIMS',           'Water Info Mgmt Sys','수자원 정보관리 시스템',              'Oracle',     'JDBC',  'internal', 1,  'active');

-- ============================================================================
-- 2. 데이터셋 (dset) — K-water 핵심 데이터셋
-- ============================================================================
INSERT INTO dset (dset_id, dset_cd, table_nm, dset_nm, dc, domn_id, sys_id, asset_ty, scrty_lvl, qlity_score, row_co, col_co, owner_dept_id, stwrd_usr_id, stat) VALUES
    -- 수자원 도메인
    ('d0000001-0000-0000-0000-000000000001', 'DS_DAM_WATER_LVL', 'tb_dam_water_level',    '댐 수위 측정 데이터',        '전국 다목적댐 시간별 수위 관측 데이터',           1, 2, 'table', 'public',     92.5, 5840000, 12, 1,  'a0000001-0000-0000-0000-000000000012', 'active'),
    ('d0000001-0000-0000-0000-000000000002', 'DS_DAM_INFLOW',    'tb_dam_inflow',         '댐 유입량 데이터',           '다목적댐 일별 유입·방류량 데이터',               1, 2, 'table', 'public',     88.3, 2100000,  8, 1,  'a0000001-0000-0000-0000-000000000012', 'active'),
    ('d0000001-0000-0000-0000-000000000003', 'DS_RIVER_FLOW',    'tb_river_flow',         '하천 유량 관측 데이터',       '주요 하천 수위·유량 관측소 데이터',               1, 7, 'table', 'public',     95.1, 3200000, 10, 2,  'a0000001-0000-0000-0000-000000000012', 'active'),
    -- 수질 도메인
    ('d0000001-0000-0000-0000-000000000004', 'DS_WQ_TMS_REALTIME','vw_wq_tms_realtime',   '수질TMS 실시간 데이터',       '자동측정망 실시간 수질 항목(pH, DO, BOD 등)',     2, 3, 'view',  'internal',   85.7, 12000000, 15, 4,  'a0000001-0000-0000-0000-000000000012', 'active'),
    ('d0000001-0000-0000-0000-000000000005', 'DS_WQ_MANUAL',     'tb_wq_manual_sample',   '수질 수동측정 데이터',        '수동 채수·분석 수질 데이터',                     2, 3, 'table', 'internal',   90.2, 450000,  20, 5,  'a0000001-0000-0000-0000-000000000012', 'active'),
    -- 에너지 도메인
    ('d0000001-0000-0000-0000-000000000006', 'DS_HYDRO_GEN',     'tb_hydro_generation',   '수력발전량 데이터',           '발전소별 시간별 발전량·운전상태',                3, 5, 'table', 'restricted', 93.8, 1800000, 14, 6,  'a0000001-0000-0000-0000-000000000013', 'active'),
    ('d0000001-0000-0000-0000-000000000007', 'DS_SOLAR_GEN',     'tb_solar_generation',   '태양광 발전량 데이터',        '태양광 발전소 일별 발전 실적',                   3, 5, 'table', 'internal',   87.4, 380000,   8, 7,  'a0000001-0000-0000-0000-000000000013', 'active'),
    -- 인프라 도메인
    ('d0000001-0000-0000-0000-000000000008', 'DS_PIPE_ASSET',    'tb_pipe_asset',         '관로 자산 대장',             '상수도 관로 시설물 자산 정보',                   4, 1, 'table', 'restricted', 78.9, 250000,  25, 8,  'a0000001-0000-0000-0000-000000000013', 'active'),
    ('d0000001-0000-0000-0000-000000000009', 'DS_FACILITY',      'tb_facility_master',    '시설물 마스터 데이터',        '정수장·취수장·배수지 등 시설물 대장',            4, 1, 'table', 'internal',   82.1, 15000,   30, 9,  'a0000001-0000-0000-0000-000000000013', 'active'),
    -- 고객 도메인
    ('d0000001-0000-0000-0000-000000000010', 'DS_CUST_USAGE',    'tb_customer_usage',     '고객 사용량 데이터',         '가정·업무용 월별 사용량 데이터',                 5, 1, 'table', 'confidential',91.5, 8500000, 12, 14, 'a0000001-0000-0000-0000-000000000013', 'active'),
    -- API 자산
    ('d0000001-0000-0000-0000-000000000011', 'DS_WEATHER_API',   NULL,                    '기상청 날씨 API',            '기상청 공공데이터 포탈 실시간 날씨 API',          1, 6, 'api',   'public',     97.2, 0,        8, 10, 'a0000001-0000-0000-0000-000000000012', 'active'),
    ('d0000001-0000-0000-0000-000000000012', 'DS_FLOOD_WARN',    'str_flood_warning',     '홍수예보 스트림',            '실시간 홍수 예경보 이벤트 스트림',               6, 2, 'stream','public',     94.0, 0,        6, 3,  'a0000001-0000-0000-0000-000000000012', 'active');

-- ============================================================================
-- 3. 데이터셋 컬럼 (dset_col) — 대표 데이터셋 2~3개의 컬럼 정의
-- ============================================================================
INSERT INTO dset_col (dset_id, col_nm, col_nm_ko, data_ty, data_lt, is_pk, is_nulbl, dc, sort_ord) VALUES
    -- 댐 수위 데이터셋 컬럼
    ('d0000001-0000-0000-0000-000000000001', 'dam_cd',      '댐코드',     'VARCHAR',   10, TRUE,  FALSE, '댐 식별 코드',             1),
    ('d0000001-0000-0000-0000-000000000001', 'msrmt_dt',    '측정일시',   'TIMESTAMP', NULL, TRUE,  FALSE, '수위 측정 일시',           2),
    ('d0000001-0000-0000-0000-000000000001', 'water_lvl',   '수위',       'NUMERIC',   NULL, FALSE, FALSE, '현재 수위(EL.m)',          3),
    ('d0000001-0000-0000-0000-000000000001', 'full_lvl',    '만수위',     'NUMERIC',   NULL, FALSE, TRUE,  '만수위(EL.m)',             4),
    ('d0000001-0000-0000-0000-000000000001', 'low_lvl',     '저수위',     'NUMERIC',   NULL, FALSE, TRUE,  '저수위(EL.m)',             5),
    ('d0000001-0000-0000-0000-000000000001', 'storage_rt',  '저수율',     'NUMERIC',   NULL, FALSE, TRUE,  '저수율(%)',                6),
    ('d0000001-0000-0000-0000-000000000001', 'inflow_qty',  '유입량',     'NUMERIC',   NULL, FALSE, TRUE,  '유입량(m3/s)',             7),
    ('d0000001-0000-0000-0000-000000000001', 'outflow_qty', '방류량',     'NUMERIC',   NULL, FALSE, TRUE,  '방류량(m3/s)',             8),
    -- 수질TMS 실시간 데이터셋 컬럼
    ('d0000001-0000-0000-0000-000000000004', 'station_cd',  '측정소코드', 'VARCHAR',   20,  TRUE,  FALSE, '자동측정망 측정소 코드',    1),
    ('d0000001-0000-0000-0000-000000000004', 'msrmt_dt',    '측정일시',   'TIMESTAMP', NULL, TRUE,  FALSE, '측정 일시',                2),
    ('d0000001-0000-0000-0000-000000000004', 'ph',          'pH',         'NUMERIC',   NULL, FALSE, TRUE,  '수소이온농도',             3),
    ('d0000001-0000-0000-0000-000000000004', 'do_val',      'DO',         'NUMERIC',   NULL, FALSE, TRUE,  '용존산소(mg/L)',           4),
    ('d0000001-0000-0000-0000-000000000004', 'bod',         'BOD',        'NUMERIC',   NULL, FALSE, TRUE,  '생화학적산소요구량(mg/L)', 5),
    ('d0000001-0000-0000-0000-000000000004', 'cod',         'COD',        'NUMERIC',   NULL, FALSE, TRUE,  '화학적산소요구량(mg/L)',   6),
    ('d0000001-0000-0000-0000-000000000004', 'ss',          'SS',         'NUMERIC',   NULL, FALSE, TRUE,  '부유물질(mg/L)',           7),
    ('d0000001-0000-0000-0000-000000000004', 'tn',          'T-N',        'NUMERIC',   NULL, FALSE, TRUE,  '총질소(mg/L)',             8),
    ('d0000001-0000-0000-0000-000000000004', 'tp',          'T-P',        'NUMERIC',   NULL, FALSE, TRUE,  '총인(mg/L)',               9),
    ('d0000001-0000-0000-0000-000000000004', 'turbidity',   '탁도',       'NUMERIC',   NULL, FALSE, TRUE,  '탁도(NTU)',                10);

-- ============================================================================
-- 4. 태그 (tag)
-- ============================================================================
INSERT INTO tag (tag_nm, tag_ty, color) VALUES
    ('수위',       'keyword',  '#3B82F6'),
    ('유량',       'keyword',  '#3B82F6'),
    ('수질',       'keyword',  '#10B981'),
    ('발전량',     'keyword',  '#F59E0B'),
    ('실시간',     'system',   '#EF4444'),
    ('일별집계',   'system',   '#8B5CF6'),
    ('공공데이터', 'system',   '#06B6D4'),
    ('댐',         'keyword',  '#3B82F6'),
    ('하천',       'keyword',  '#3B82F6'),
    ('관로',       'keyword',  '#8B5CF6'),
    ('TMS',        'system',   '#10B981'),
    ('SAP',        'system',   '#F59E0B');

-- ============================================================================
-- 5. 데이터셋-태그 연결 (dset_tag)
-- ============================================================================
INSERT INTO dset_tag (dset_id, tag_id) VALUES
    ('d0000001-0000-0000-0000-000000000001', 1),  -- 댐수위-수위
    ('d0000001-0000-0000-0000-000000000001', 8),  -- 댐수위-댐
    ('d0000001-0000-0000-0000-000000000001', 5),  -- 댐수위-실시간
    ('d0000001-0000-0000-0000-000000000002', 2),  -- 유입량-유량
    ('d0000001-0000-0000-0000-000000000002', 8),  -- 유입량-댐
    ('d0000001-0000-0000-0000-000000000003', 2),  -- 하천유량-유량
    ('d0000001-0000-0000-0000-000000000003', 9),  -- 하천유량-하천
    ('d0000001-0000-0000-0000-000000000004', 3),  -- TMS-수질
    ('d0000001-0000-0000-0000-000000000004', 5),  -- TMS-실시간
    ('d0000001-0000-0000-0000-000000000004', 11), -- TMS-TMS
    ('d0000001-0000-0000-0000-000000000006', 4),  -- 수력발전-발전량
    ('d0000001-0000-0000-0000-000000000008', 10), -- 관로자산-관로
    ('d0000001-0000-0000-0000-000000000011', 7);  -- 기상API-공공데이터

-- ============================================================================
-- 6. 북마크 (bmrk)
-- ============================================================================
INSERT INTO bmrk (usr_id, dset_id, memo) VALUES
    ('a0000001-0000-0000-0000-000000000010', 'd0000001-0000-0000-0000-000000000001', '소양강댐 수위 모니터링용'),
    ('a0000001-0000-0000-0000-000000000010', 'd0000001-0000-0000-0000-000000000004', '수질 현황 확인'),
    ('a0000001-0000-0000-0000-000000000011', 'd0000001-0000-0000-0000-000000000002', '유입량 트렌드 분석');

-- ============================================================================
-- 7. 용어사전 (glsry_term)
-- ============================================================================
INSERT INTO glsry_term (term_nm, term_nm_en, domn_id, data_ty, unit, valid_rng_min, valid_rng_max, dfn, stat, aprvd_by, aprvd_at) VALUES
    ('수위',       'Water Level',   1, 'NUMERIC',  'm',    '0',   '200',   '하천·호소·댐 등의 수면 높이를 기준면으로부터 측정한 값',                          'approved', 'a0000001-0000-0000-0000-000000000012', now() - interval '30 days'),
    ('유량',       'Flow Rate',     1, 'NUMERIC',  'm3/s', '0',   '50000', '단위 시간당 하천의 특정 단면을 통과하는 물의 체적',                               'approved', 'a0000001-0000-0000-0000-000000000012', now() - interval '30 days'),
    ('저수율',     'Storage Rate',  1, 'NUMERIC',  '%',    '0',   '100',   '댐 저수량 대비 현재 저수량의 백분율',                                             'approved', 'a0000001-0000-0000-0000-000000000012', now() - interval '25 days'),
    ('pH',         'pH',            2, 'NUMERIC',  'pH',   '0',   '14',    '수소이온농도 지수, 물의 산성·알칼리성 정도를 나타내는 척도',                        'approved', 'a0000001-0000-0000-0000-000000000012', now() - interval '20 days'),
    ('BOD',        'BOD',           2, 'NUMERIC',  'mg/L', '0',   '500',   '생화학적 산소 요구량. 미생물이 유기물을 분해하는 데 소비하는 산소량',               'approved', 'a0000001-0000-0000-0000-000000000012', now() - interval '20 days'),
    ('탁도',       'Turbidity',     2, 'NUMERIC',  'NTU',  '0',   '4000',  '물의 흐린 정도를 나타내는 지표',                                                  'approved', 'a0000001-0000-0000-0000-000000000012', now() - interval '15 days'),
    ('발전량',     'Generation',    3, 'NUMERIC',  'MWh',  '0',   NULL,    '발전소에서 생산한 전기 에너지의 양',                                              'approved', 'a0000001-0000-0000-0000-000000000013', now() - interval '10 days'),
    ('사용량',     'Usage Amount',  5, 'NUMERIC',  'm3',   '0',   NULL,    '고객이 사용한 수도 사용량',                                                       'pending',  NULL, NULL),
    ('관경',       'Pipe Diameter', 4, 'NUMERIC',  'mm',   '13',  '3000',  '관로의 내경 직경',                                                               'approved', 'a0000001-0000-0000-0000-000000000013', now() - interval '5 days'),
    ('설치연도',   'Install Year',  4, 'INTEGER',  NULL,   '1960','2030',  '시설물이 설치된 연도',                                                            'approved', 'a0000001-0000-0000-0000-000000000013', now() - interval '5 days');

-- ============================================================================
-- 8. 용어사전 이력 (glsry_hist)
-- ============================================================================
INSERT INTO glsry_hist (term_id, chg_desc, chgd_by, prev_stat, new_stat) VALUES
    (1, '초기 등록',                  'a0000001-0000-0000-0000-000000000012', NULL,      'pending'),
    (1, '데이터스튜어드 승인',        'a0000001-0000-0000-0000-000000000012', 'pending', 'approved'),
    (4, '유효범위 0~14로 설정 후 승인','a0000001-0000-0000-0000-000000000012', 'pending', 'approved');

-- ============================================================================
-- 9. 데이터 모델 (data_model + model_entty + model_atrb)
-- ============================================================================
INSERT INTO data_model (model_nm, model_ty, domn_id, ver, dc, table_co, stat, owner_usr_id) VALUES
    ('수자원 관측 논리 모델', 'logical',  1, '2.1', '댐·하천 관측 데이터 논리 모델',     8,  'active', 'a0000001-0000-0000-0000-000000000012'),
    ('수질 분석 물리 모델',  'physical', 2, '1.5', '수질TMS·수동측정 물리 테이블 모델', 12, 'active', 'a0000001-0000-0000-0000-000000000012');

INSERT INTO model_entty (model_id, entty_nm, entty_nm_ko, entty_ty, dc, sort_ord) VALUES
    (1, 'dam_master',     '댐 마스터',     'table', '다목적댐 기본 정보',     1),
    (1, 'dam_water_level','댐 수위',       'table', '댐 수위 관측 데이터',    2),
    (1, 'dam_inflow',     '댐 유입량',     'table', '댐 유입·방류량 데이터',  3),
    (2, 'wq_station',     '수질 측정소',   'table', '자동측정망 측정소 정보', 1),
    (2, 'wq_tms_data',    '수질TMS 데이터','table', 'TMS 실시간 관측 데이터', 2);

INSERT INTO model_atrb (entty_id, atrb_nm, atrb_nm_ko, data_ty, is_pk, dc, sort_ord) VALUES
    (1, 'dam_cd',   '댐코드',   'VARCHAR(10)',  TRUE,  '댐 식별 코드',        1),
    (1, 'dam_nm',   '댐명',     'VARCHAR(50)',  FALSE, '댐 명칭',             2),
    (1, 'river_nm', '하천명',   'VARCHAR(50)',  FALSE, '위치 하천명',         3),
    (2, 'dam_cd',   '댐코드',   'VARCHAR(10)',  TRUE,  '댐 FK',              1),
    (2, 'msrmt_dt', '측정일시', 'TIMESTAMP',    TRUE,  '관측 일시',          2),
    (2, 'water_lvl','수위',     'NUMERIC(8,2)', FALSE, '수위(EL.m)',         3);

-- ============================================================================
-- 10. 파이프라인 (ppln)
-- ============================================================================
INSERT INTO ppln (ppln_nm, ppln_cd, sys_id, colct_mthd, schdul, src_table, trget_stg, dc, owner_usr_id, owner_dept_id, stat) VALUES
    ('댐수위 실시간 수집',       'PL_DAM_WATER',  2, 'cdc',       '*/5 * * * *',  'scada.dam_water_level',     'raw.dam_water_level',     'SCADA 댐수위 CDC 실시간 수집',        'a0000001-0000-0000-0000-000000000030', 11, 'active'),
    ('수질TMS 배치 수집',        'PL_WQ_TMS',     3, 'batch',     '0 */1 * * *',  'tms.wq_realtime',           'raw.wq_tms_data',         '수질TMS 1시간 단위 배치 수집',         'a0000001-0000-0000-0000-000000000031', 11, 'active'),
    ('기상청 API 수집',          'PL_WEATHER',    6, 'api',       '0 0,6,12,18 * * *','openapi.weather','raw.weather_data',        '기상청 공공 API 6시간 단위 수집',      'a0000001-0000-0000-0000-000000000030', 11, 'active'),
    ('SAP 재무 배치',            'PL_SAP_FIN',    1, 'batch',     '0 2 * * *',    'sap.bkpf',                  'raw.sap_finance',         'SAP 재무전표 일배치',                 'a0000001-0000-0000-0000-000000000031', 11, 'active'),
    ('수력발전 CDC 수집',        'PL_HYDRO',      5, 'cdc',       '*/1 * * * *',  'scada.hydro_gen',           'raw.hydro_generation',    '수력발전 SCADA 실시간 수집',           'a0000001-0000-0000-0000-000000000030', 11, 'active'),
    ('관로자산 파일 수집',       'PL_PIPE_FILE',  1, 'file',      '0 3 1 * *',    '/data/pipe_export.csv',     'raw.pipe_asset',          '관로자산 CSV 월배치 수집',             'a0000001-0000-0000-0000-000000000031', 11, 'active'),
    ('WIMS 하천유량 배치',       'PL_RIVER',      7, 'batch',     '0 1 * * *',    'wims.river_flow',           'raw.river_flow',          'WIMS 하천유량 일배치 수집',            'a0000001-0000-0000-0000-000000000031', 11, 'active'),
    ('홍수예보 스트리밍',        'PL_FLOOD',      2, 'streaming', NULL,            'kafka:flood-warning',       'raw.flood_warning',       '홍수예보 Kafka 스트리밍 수집',         'a0000001-0000-0000-0000-000000000030', 11, 'active');

-- ============================================================================
-- 11. 파이프라인 실행이력 (ppln_exec)
-- ============================================================================
INSERT INTO ppln_exec (ppln_id, strtd_at, fnshed_at, dur_secnd, rcrds_read, rcrds_wrtn, rcrds_err, succes_rt, stat) VALUES
    (1, now()-interval '2 hours',    now()-interval '2 hours'+interval '45 seconds',  45, 12500, 12500, 0,    100.00, 'success'),
    (1, now()-interval '1 hour',     now()-interval '1 hour'+interval '38 seconds',   38, 11800, 11800, 0,    100.00, 'success'),
    (2, now()-interval '3 hours',    now()-interval '3 hours'+interval '120 seconds', 120, 85000, 84950, 50,  99.94, 'success'),
    (2, now()-interval '2 hours',    now()-interval '2 hours'+interval '95 seconds',  95,  82000, 82000, 0,   100.00, 'success'),
    (3, now()-interval '6 hours',    now()-interval '6 hours'+interval '15 seconds',  15,  500,   500,   0,   100.00, 'success'),
    (4, now()-interval '22 hours',   now()-interval '22 hours'+interval '300 seconds',300, 45000, 44800, 200, 99.56, 'success'),
    (5, now()-interval '30 minutes', now()-interval '30 minutes'+interval '12 seconds',12, 3200,  3200,  0,   100.00, 'success'),
    (6, now()-interval '15 days',    now()-interval '15 days'+interval '600 seconds', 600, 250000,248000,2000,99.20, 'success'),
    (7, now()-interval '1 day',      now()-interval '1 day'+interval '180 seconds',   180, 96000, 96000, 0,   100.00, 'success'),
    (1, now()-interval '30 minutes', NULL,                                            NULL, 0,     0,     0,   NULL,   'running');

-- ============================================================================
-- 12. CDC 커넥터 (cdc_cnctr)
-- ============================================================================
INSERT INTO cdc_cnctr (sys_id, cnctr_nm, cnctr_ty, dbms_ty, table_co, evnt_per_min, lag_secnd, stat) VALUES
    (2, 'scada-dam-connector',    'debezium', 'PostgreSQL', 5,  2400, 2,  'active'),
    (5, 'hydro-scada-connector',  'debezium', 'MSSQL',      3,  1800, 3,  'active'),
    (3, 'tms-oracle-connector',   'debezium', 'Oracle',      8,  5000, 5,  'active');

-- ============================================================================
-- 13. Kafka 토픽 (kafka_topc)
-- ============================================================================
INSERT INTO kafka_topc (topc_nm, clstr_nm, prtitn_co, rplctn, rtntn_hr, msg_per_sec, stat) VALUES
    ('kwater.scada.dam-water-level',  'kwater-prod', 6, 3, 168, 420,  'active'),
    ('kwater.scada.hydro-generation', 'kwater-prod', 3, 3, 168, 300,  'active'),
    ('kwater.tms.wq-realtime',        'kwater-prod', 8, 3, 336, 850,  'active'),
    ('kwater.flood.warning',          'kwater-prod', 3, 3, 720, 5,    'active'),
    ('kwater.sap.finance-journal',    'kwater-batch', 2, 2, 168, 50,  'active');

-- ============================================================================
-- 14. 외부 연계 (extn_intgrn)
-- ============================================================================
INSERT INTO extn_intgrn (intgrn_nm, intgrn_ty, src_sys, trget_sys, prtcl, endpt_url, freq, last_succes_at, stat) VALUES
    ('기상청 실시간 날씨 연계',  'api_inbound',  '기상청 Open API',  'DataHub',     'REST',  'https://apis.data.go.kr/1360000/VilageFcstInfoService', '6시간', now()-interval '6 hours', 'active'),
    ('환경부 수질데이터 연계',   'api_inbound',  '환경부 Open API',  'DataHub',     'REST',  'https://apis.data.go.kr/B500001/waterQualityService',   '일별',  now()-interval '1 day',   'active'),
    ('SAP ERP 재무 연계',        'db_sync',      'SAP HANA',         'DataHub',     'RFC',   NULL,                                                    '일별',  now()-interval '22 hours','active');

-- ============================================================================
-- 15. 파이프라인 컬럼 매핑 (ppln_col_mapng) — 대표 1건
-- ============================================================================
INSERT INTO ppln_col_mapng (ppln_id, src_col, trget_col, src_ty, trget_ty, trsfm_rule, is_reqrd, sort_ord) VALUES
    (1, 'DAM_CODE',     'dam_cd',     'VARCHAR(10)', 'VARCHAR(10)', NULL,                       TRUE,  1),
    (1, 'MEASURE_TIME', 'msrmt_dt',   'TIMESTAMP',   'TIMESTAMPTZ', 'TO_TIMESTAMP(src, fmt)',   TRUE,  2),
    (1, 'WATER_LEVEL',  'water_lvl',  'NUMBER(8,2)', 'NUMERIC(8,2)', NULL,                      TRUE,  3),
    (1, 'INFLOW',       'inflow_qty', 'NUMBER(10,2)','NUMERIC(10,2)', 'ROUND(src, 2)',           FALSE, 4);
