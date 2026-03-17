/*
 * seed_03_distribute_quality_monitor.sql — 유통·활용 + 품질 + 온톨로지 + 모니터링
 * 의존성: seed_01, seed_02 선행
 */

-- ============================================================================
-- 1. 데이터 상품 (data_product)
-- ============================================================================
INSERT INTO data_product (product_id, product_cd, product_nm, dc, product_ty, domn_id, scrty_lvl, ver, endpt_url, rt_limit, sla_uptm, owner_dept_id, owner_usr_id, stat, pblshd_at) VALUES
    ('b0000001-0000-0000-0000-000000000001', 'PRD_DAM_STATUS',   '댐 현황 종합 API',       '전국 다목적댐 수위·저수율·유입량 종합 조회 API',        'api',  1, 'public',     '2.0', '/api/v2/dam/status',        5000, 99.9, 1,  'a0000001-0000-0000-0000-000000000013', 'active', now()-interval '90 days'),
    ('b0000001-0000-0000-0000-000000000002', 'PRD_WQ_REALTIME',  '수질 실시간 모니터링 API','TMS 실시간 수질 데이터 조회 API',                       'api',  2, 'internal',   '1.5', '/api/v1/waterquality/realtime', 3000, 99.5, 4,  'a0000001-0000-0000-0000-000000000013', 'active', now()-interval '60 days'),
    ('b0000001-0000-0000-0000-000000000003', 'PRD_HYDRO_REPORT', '수력발전 실적 리포트',    '월별 발전소별 발전량·가동률 리포트 데이터',              'file', 3, 'restricted', '1.0', NULL,                            1000, 99.0, 6,  'a0000001-0000-0000-0000-000000000013', 'active', now()-interval '30 days'),
    ('b0000001-0000-0000-0000-000000000004', 'PRD_WEATHER_MERGE','기상·수위 융합 데이터',   '기상청 데이터와 댐 수위 데이터 융합 분석용 데이터셋',   'api',  1, 'public',     '1.0', '/api/v1/weather-dam/merged',    2000, 99.5, 10, 'a0000001-0000-0000-0000-000000000012', 'active', now()-interval '15 days');

-- ============================================================================
-- 2. 상품-원천 연결 (product_src)
-- ============================================================================
INSERT INTO product_src (product_id, dset_id, join_ty, dc, sort_ord) VALUES
    ('b0000001-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001', 'inner', '댐 수위 데이터',     1),
    ('b0000001-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000002', 'left',  '댐 유입량 데이터',   2),
    ('b0000001-0000-0000-0000-000000000002', 'd0000001-0000-0000-0000-000000000004', 'inner', '수질TMS 실시간',     1),
    ('b0000001-0000-0000-0000-000000000003', 'd0000001-0000-0000-0000-000000000006', 'inner', '수력발전량',         1),
    ('b0000001-0000-0000-0000-000000000004', 'd0000001-0000-0000-0000-000000000011', 'inner', '기상 API',           1),
    ('b0000001-0000-0000-0000-000000000004', 'd0000001-0000-0000-0000-000000000001', 'left',  '댐 수위 데이터',     2);

-- ============================================================================
-- 3. 상품 필드 (product_field) — 대표 1건
-- ============================================================================
INSERT INTO product_field (product_id, field_nm, field_nm_ko, field_ty, is_reqrd, is_fltrbl, dc, smple_val, sort_ord) VALUES
    ('b0000001-0000-0000-0000-000000000001', 'dam_cd',      '댐코드',   'STRING',  TRUE,  TRUE,  '댐 식별 코드',       'SOYANGDAM',  1),
    ('b0000001-0000-0000-0000-000000000001', 'dam_nm',      '댐명',     'STRING',  FALSE, TRUE,  '댐 명칭',            '소양강댐',   2),
    ('b0000001-0000-0000-0000-000000000001', 'water_lvl',   '수위',     'FLOAT',   FALSE, FALSE, '현재 수위(EL.m)',    '193.52',     3),
    ('b0000001-0000-0000-0000-000000000001', 'storage_rt',  '저수율',   'FLOAT',   FALSE, TRUE,  '저수율(%)',          '85.3',       4),
    ('b0000001-0000-0000-0000-000000000001', 'msrmt_dt',    '측정일시', 'DATETIME',FALSE, TRUE,  '측정 일시',          '2026-03-14T09:00:00', 5);

-- ============================================================================
-- 4. API 키 (api_key)
-- ============================================================================
INSERT INTO api_key (key_id, usr_id, product_id, api_key_hash, key_prfx, dc, is_actv, expirs_at, tot_calls) VALUES
    ('c0000001-0000-0000-0000-000000000001', 'a0000001-0000-0000-0000-000000000010', 'b0000001-0000-0000-0000-000000000001', encode(digest('apikey_hong_dam_2026','sha256'),'hex'), 'kw_dam_', '댐 현황 API 조회용', TRUE,  now()+interval '365 days', 15230),
    ('c0000001-0000-0000-0000-000000000002', 'a0000001-0000-0000-0000-000000000014', 'b0000001-0000-0000-0000-000000000002', encode(digest('apikey_choi_wq_2026','sha256'),'hex'),  'kw_wq_',  '수질 API 모니터링용', TRUE,  now()+interval '180 days', 8450),
    ('c0000001-0000-0000-0000-000000000003', 'a0000001-0000-0000-0000-000000000021', 'b0000001-0000-0000-0000-000000000001', encode(digest('apikey_partner_dam','sha256'),'hex'),   'kw_ext_', '외부개발자 댐API',   TRUE,  now()+interval '90 days',  320);

-- ============================================================================
-- 5. 비식별화 정책·규칙 (didntf_polcy + didntf_rule)
-- ============================================================================
INSERT INTO didntf_polcy (polcy_nm, dc, trget_lvl, rule_co, is_actv, aprvd_by) VALUES
    ('고객정보 비식별화 정책', '고객 개인정보 포함 데이터 비식별 처리 정책', 'confidential', 4, TRUE, 'a0000001-0000-0000-0000-000000000002'),
    ('내부중요 데이터 마스킹',  '내부중요 등급 데이터 외부 제공 시 마스킹',   'restricted',   2, TRUE, 'a0000001-0000-0000-0000-000000000002');

INSERT INTO didntf_rule (polcy_id, col_pttrn, rule_ty, rule_cnfg, priort, dc) VALUES
    (1, '*phone*',    'masking',    '{"mask_char":"*","visible_last":4}',  1, '전화번호 뒷 4자리만 노출'),
    (1, '*email*',    'masking',    '{"mask_char":"*","visible_first":2}', 2, '이메일 앞 2자리만 노출'),
    (1, '*addr*',     'suppression','{"level":"city"}',                    3, '주소 시/군 단위까지만 노출'),
    (1, '*resident*', 'encryption', '{"algorithm":"AES-256"}',             4, '주민번호 AES 암호화'),
    (2, '*account*',  'pseudonym',  '{"prefix":"ACC_","length":8}',        1, '계좌번호 가명처리'),
    (2, '*salary*',   'rounding',   '{"unit":1000000}',                    2, '급여 백만원 단위 반올림');

-- ============================================================================
-- 6. 데이터 신청 (data_rqst + rqst_tmln)
-- ============================================================================
INSERT INTO data_rqst (rqst_cd, usr_id, dset_id, product_id, rqst_ty, purps, is_urgnt, aprvl_stat, apprvr_id, aprvd_at) VALUES
    ('REQ-2026-001', 'a0000001-0000-0000-0000-000000000010', 'd0000001-0000-0000-0000-000000000010', NULL,                                       'download', '고객 사용량 패턴 분석 연구', FALSE, 'approved', 'a0000001-0000-0000-0000-000000000012', now()-interval '5 days'),
    ('REQ-2026-002', 'a0000001-0000-0000-0000-000000000021', NULL,                                    'b0000001-0000-0000-0000-000000000001', 'api',      '외부 연구기관 댐 데이터 활용', FALSE, 'approved', 'a0000001-0000-0000-0000-000000000013', now()-interval '3 days'),
    ('REQ-2026-003', 'a0000001-0000-0000-0000-000000000014', 'd0000001-0000-0000-0000-000000000008', NULL,                                       'download', '관로 자산 현황 분석',         TRUE,  'pending',  NULL, NULL),
    ('REQ-2026-004', 'a0000001-0000-0000-0000-000000000020', 'd0000001-0000-0000-0000-000000000006', NULL,                                       'export',   '발전량 데이터 외부 제공',     FALSE, 'rejected', 'a0000001-0000-0000-0000-000000000002', now()-interval '1 day');

INSERT INTO rqst_tmln (rqst_id, actn_ty, stat, actr_usr_id, cm) VALUES
    (1, 'submit',  'pending',  'a0000001-0000-0000-0000-000000000010', '고객사용량 다운로드 신청'),
    (1, 'approve', 'approved', 'a0000001-0000-0000-0000-000000000012', '비식별 처리 후 다운로드 승인'),
    (2, 'submit',  'pending',  'a0000001-0000-0000-0000-000000000021', '댐 API 접근 신청'),
    (2, 'approve', 'approved', 'a0000001-0000-0000-0000-000000000013', '읽기 전용 API 키 발급 승인'),
    (3, 'submit',  'pending',  'a0000001-0000-0000-0000-000000000014', '관로자산 다운로드 긴급 신청'),
    (4, 'submit',  'pending',  'a0000001-0000-0000-0000-000000000020', '발전량 외부반출 신청'),
    (4, 'reject',  'rejected', 'a0000001-0000-0000-0000-000000000002', '보안등급 미달로 반려');

-- ============================================================================
-- 7. 차트 콘텐츠 (chart_cntnt)
-- ============================================================================
INSERT INTO chart_cntnt (chart_nm, chart_ty, dc, data_src, domn_id, owner_usr_id, is_public, view_co) VALUES
    ('전국 댐 저수율 현황',    'bar',     '전국 다목적댐 저수율 막대 차트',       '/api/v2/dam/status',                1, 'a0000001-0000-0000-0000-000000000012', TRUE,  450),
    ('수질TMS 실시간 추이',    'line',    '주요 측정소 pH·DO·BOD 시계열 차트',   '/api/v1/waterquality/realtime',     2, 'a0000001-0000-0000-0000-000000000012', TRUE,  380),
    ('발전량 월별 추이',       'line',    '발전소별 월간 발전량 추이 차트',       '/api/v1/hydro/monthly',            3, 'a0000001-0000-0000-0000-000000000013', FALSE, 120),
    ('데이터 품질 도메인별',   'pie',     '도메인별 품질 점수 원형 차트',         '/api/v1/quality/domain-scores',    NULL,'a0000001-0000-0000-0000-000000000013', TRUE,  290);

-- ============================================================================
-- 8. 외부 제공 (extn_prvsn)
-- ============================================================================
INSERT INTO extn_prvsn (prvsn_nm, trget_org, dset_id, product_id, prvsn_ty, freq, rcrd_co, last_prvdd, cntrct_strt, cntrct_end, stat) VALUES
    ('한국수자원학회 수위데이터 제공', '한국수자원학회', 'd0000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000001', 'api',  '실시간', 0,      now()-interval '1 hour',  '2026-01-01', '2026-12-31', 'active'),
    ('환경부 수질데이터 연간 제공',   '환경부',         'd0000001-0000-0000-0000-000000000005', NULL,                                    'file', '월별',   450000, now()-interval '30 days', '2026-01-01', '2026-12-31', 'active');

-- ============================================================================
-- 9. DQ 규칙 (dq_rule)
-- ============================================================================
INSERT INTO dq_rule (rule_nm, rule_cd, rule_ty, dset_id, col_nm, expr, thrhld, svrt, dc, is_actv) VALUES
    ('댐수위 NULL 검사',         'DQ_DAM_NULL',     'completeness', 'd0000001-0000-0000-0000-000000000001', 'water_lvl',  'water_lvl IS NOT NULL', 99.00, 'critical', '수위 값 NULL 불가',       TRUE),
    ('댐수위 범위 검사',         'DQ_DAM_RANGE',    'validity',     'd0000001-0000-0000-0000-000000000001', 'water_lvl',  'water_lvl BETWEEN 0 AND 200', 98.00, 'warning', '수위 0~200m 범위',     TRUE),
    ('수질 pH 범위 검사',        'DQ_WQ_PH',        'validity',     'd0000001-0000-0000-0000-000000000004', 'ph',         'ph BETWEEN 0 AND 14',  99.00, 'critical', 'pH 0~14 범위',            TRUE),
    ('수질 DO 양수 검사',        'DQ_WQ_DO',        'validity',     'd0000001-0000-0000-0000-000000000004', 'do_val',     'do_val >= 0',          98.00, 'warning',  'DO 음수 불가',            TRUE),
    ('발전량 정확성 검사',       'DQ_HYDRO_ACC',    'accuracy',     'd0000001-0000-0000-0000-000000000006', NULL,          'gen_kwh <= max_capacity * 24', 95.00, 'warning', '발전량 최대용량 초과 검사', TRUE),
    ('고객사용량 유일성 검사',   'DQ_CUST_UNIQUE',  'uniqueness',   'd0000001-0000-0000-0000-000000000010', NULL,          'COUNT(DISTINCT customer_id, month) = COUNT(*)', 100.00, 'critical', '고객-월 중복 불가', TRUE),
    ('관로자산 완전성 검사',     'DQ_PIPE_COMPL',   'completeness', 'd0000001-0000-0000-0000-000000000008', 'pipe_dia',   'pipe_dia IS NOT NULL', 95.00, 'warning',  '관경 필수',               TRUE),
    ('하천유량 적시성 검사',     'DQ_RIVER_TIMELY', 'timeliness',   'd0000001-0000-0000-0000-000000000003', NULL,          'msrmt_dt >= now() - interval ''2 hours''', 90.00, 'warning', '2시간 이내 데이터', TRUE);

-- ============================================================================
-- 10. DQ 실행이력 (dq_exec)
-- ============================================================================
INSERT INTO dq_exec (rule_id, dset_id, exec_dt, tot_rows, passd_rows, faild_rows, score, rst, exec_tm_ms) VALUES
    (1, 'd0000001-0000-0000-0000-000000000001', CURRENT_DATE,     5840000, 5838500, 1500,   99.97, 'pass', 4500),
    (1, 'd0000001-0000-0000-0000-000000000001', CURRENT_DATE - 1, 5800000, 5798200, 1800,   99.97, 'pass', 4200),
    (2, 'd0000001-0000-0000-0000-000000000001', CURRENT_DATE,     5840000, 5835000, 5000,   99.91, 'pass', 3800),
    (3, 'd0000001-0000-0000-0000-000000000004', CURRENT_DATE,     12000000,11998000,2000,   99.98, 'pass', 8500),
    (4, 'd0000001-0000-0000-0000-000000000004', CURRENT_DATE,     12000000,11995000,5000,   99.96, 'pass', 7200),
    (5, 'd0000001-0000-0000-0000-000000000006', CURRENT_DATE,     1800000, 1795000, 5000,   99.72, 'pass', 5500),
    (6, 'd0000001-0000-0000-0000-000000000010', CURRENT_DATE,     8500000, 8500000, 0,      100.00,'pass', 12000),
    (7, 'd0000001-0000-0000-0000-000000000008', CURRENT_DATE,     250000,  235000,  15000,  94.00, 'fail', 2800),
    (8, 'd0000001-0000-0000-0000-000000000003', CURRENT_DATE,     3200000, 3000000, 200000, 93.75, 'fail', 6000);

-- ============================================================================
-- 11. 도메인별 품질 점수 (domn_qlity_score)
-- ============================================================================
INSERT INTO domn_qlity_score (domn_id, score_dt, cmpltn, accrcy, cnstnc, tmlns, valid, uqe, ovrall_score, dset_co, rule_co) VALUES
    (1, CURRENT_DATE,     95.2, 92.8, 94.1, 88.5, 96.3, 99.8, 94.5, 4, 3),
    (1, CURRENT_DATE - 7, 94.8, 92.5, 93.8, 87.9, 96.0, 99.7, 94.1, 4, 3),
    (2, CURRENT_DATE,     92.1, 90.5, 91.3, 85.2, 94.8, 99.5, 92.2, 2, 2),
    (3, CURRENT_DATE,     96.5, 94.2, 95.0, 92.1, 97.1, 100.0,95.8, 2, 1),
    (4, CURRENT_DATE,     85.3, 82.1, 88.4, 78.9, 90.2, 98.5, 87.2, 2, 1),
    (5, CURRENT_DATE,     93.8, 91.5, 92.0, 89.3, 95.5, 100.0,93.7, 1, 1),
    (6, CURRENT_DATE,     97.0, 95.5, 96.2, 94.0, 98.0, 99.9, 96.8, 1, 0);

-- ============================================================================
-- 12. 품질 이슈 (qlity_issue)
-- ============================================================================
INSERT INTO qlity_issue (dset_id, rule_id, issue_ty, svrt, col_nm, afctd_rows, dc, stat, asgnd_to) VALUES
    ('d0000001-0000-0000-0000-000000000008', 7, 'completeness', 'warning',  'pipe_dia', 15000, '관로자산 관경 데이터 15,000건 NULL 발견. 2020년 이전 데이터 보정 필요', 'open',          'a0000001-0000-0000-0000-000000000013'),
    ('d0000001-0000-0000-0000-000000000003', 8, 'timeliness',   'warning',  NULL,        200000,'하천유량 데이터 2시간 초과 지연 20만건. WIMS 연계 지연 원인 조사 필요',  'investigating', 'a0000001-0000-0000-0000-000000000030'),
    ('d0000001-0000-0000-0000-000000000004', NULL, 'consistency','critical', 'station_cd', 500,  '수질TMS 측정소코드 일부 변경으로 코드 불일치 500건 발생',               'resolved',      'a0000001-0000-0000-0000-000000000012');

-- ============================================================================
-- 13. 온톨로지 (onto_class + onto_data_prprty + onto_rel)
-- ============================================================================
INSERT INTO onto_class (class_nm_ko, class_nm_en, class_uri, dc, instn_co, icon, color, sort_ord) VALUES
    ('수자원시설물', 'WaterFacility',  'kwater:WaterFacility',  '댐·보·취수장 등 수자원 시설물',           3, 'building',   '#3B82F6', 1),
    ('댐',          'Dam',             'kwater:Dam',             '다목적댐, 용수전용댐 등',                15, 'droplet',    '#3B82F6', 2),
    ('하천',        'River',           'kwater:River',           '국가하천, 지방하천',                     120,'git-branch', '#10B981', 3),
    ('수질측정소',  'WQStation',       'kwater:WQStation',       '자동/수동 수질 측정 지점',               85, 'map-pin',    '#10B981', 4),
    ('발전소',      'PowerPlant',      'kwater:PowerPlant',      '수력/태양광 발전 시설',                  12, 'zap',        '#F59E0B', 5),
    ('관측소',      'ObservStation',   'kwater:ObservStation',   '수위/유량/강우 관측 지점',               200,'radio',      '#6366F1', 6);

INSERT INTO onto_data_prprty (class_id, prprty_nm, prprty_uri, data_ty, crdnlt, unit, dc, sort_ord) VALUES
    (2, 'water_level',  'kwater:waterLevel',  'float',  '1',   'm',     '현재 수위(EL.m)',       1),
    (2, 'storage_rate', 'kwater:storageRate', 'float',  '1',   '%',     '저수율',                2),
    (2, 'max_storage',  'kwater:maxStorage',  'float',  '1',   '만m3', '총저수용량',             3),
    (4, 'ph_value',     'kwater:phValue',     'float',  '1',   'pH',    '수소이온농도',          1),
    (4, 'do_value',     'kwater:doValue',     'float',  '1',   'mg/L',  '용존산소',              2),
    (5, 'gen_capacity', 'kwater:genCapacity', 'float',  '1',   'MW',    '발전 용량',             1),
    (5, 'gen_amount',   'kwater:genAmount',   'float',  '0..*','MWh',   '발전량',                2);

INSERT INTO onto_rel (src_class_id, trget_class_id, rel_nm_ko, rel_nm_en, rel_uri, crdnlt, drct, dc, sort_ord) VALUES
    (2, 3, '위치한 하천',      'locatedIn',     'kwater:locatedIn',     '1',    'output', '댐이 위치한 하천',           1),
    (2, 6, '관측소 보유',      'hasStation',    'kwater:hasStation',    '0..*', 'output', '댐 관련 관측소',             2),
    (3, 4, '수질측정소 보유',  'hasWQStation',  'kwater:hasWQStation',  '0..*', 'output', '하천의 수질측정소',          3),
    (1, 2, '하위 시설물(댐)',  'hasFacility',   'kwater:hasFacility',   '0..*', 'output', '수자원시설물 → 댐',          4),
    (1, 5, '하위 시설물(발전)','hasPowerPlant', 'kwater:hasPowerPlant', '0..*', 'output', '수자원시설물 → 발전소',      5);

-- ============================================================================
-- 14. 모니터링 — 지역·사업소·사이트·센서
-- ============================================================================
INSERT INTO regn (regn_cd, regn_nm, sort_ord) VALUES
    ('RGN_HAN',      '한강유역',          1),
    ('RGN_NAKDONG',  '낙동강유역',        2),
    ('RGN_GEUM',     '금강유역',          3),
    ('RGN_YEONGSAN', '영산강·섬진강유역', 4);

INSERT INTO office (regn_id, office_cd, office_nm, addr, sort_ord) VALUES
    (1, 'OFC_CHUNCHEON',  '춘천권관리단',   '강원도 춘천시',     1),
    (1, 'OFC_PALDANG',    '팔당권관리단',   '경기도 하남시',     2),
    (2, 'OFC_ANDONG',     '안동권관리단',   '경북 안동시',       3),
    (3, 'OFC_DAEJEON',    '대전권관리단',   '대전광역시',        4),
    (4, 'OFC_JANGSEONG',  '장성권관리단',   '전남 장성군',       5);

INSERT INTO site (office_id, site_cd, site_nm, site_ty, la, lngt, cpcty, stat) VALUES
    (1, 'SITE_SOYANG',   '소양강댐',     '다목적댐',  37.9450000, 127.8180000, 2900.00, 'active'),
    (1, 'SITE_CHUNCHEON','춘천댐',       '다목적댐',  37.8780000, 127.7280000, 150.00,  'active'),
    (2, 'SITE_PALDANG',  '팔당댐',       '다목적댐',  37.5210000, 127.2810000, 244.00,  'active'),
    (3, 'SITE_ANDONG',   '안동댐',       '다목적댐',  36.5680000, 128.8150000, 1248.00, 'active'),
    (4, 'SITE_DAECHEONG','대청댐',       '다목적댐',  36.4770000, 127.4820000, 1490.00, 'active'),
    (1, 'SITE_WQ_SOYG',  '소양강수질측정소','수질측정소',37.9420000, 127.8150000, NULL,  'active'),
    (2, 'SITE_WQ_PALDG', '팔당수질측정소',  '수질측정소',37.5200000, 127.2800000, NULL,  'active');

INSERT INTO sensor_tag (site_id, sensor_cd, sensor_nm, sensor_ty, unit, min_rng, max_rng, instl_dt, last_readng, last_read_at, stat) VALUES
    (1, 'SNS_SOYANG_WL',  '소양강댐 수위계',   '수위계',   'm',    100.0000, 200.0000, '2015-03-01', 193.5200, now()-interval '5 minutes', 'active'),
    (1, 'SNS_SOYANG_RF',  '소양강댐 강우계',   '강우계',   'mm',   0.0000,   500.0000, '2015-03-01', 0.0000,   now()-interval '5 minutes', 'active'),
    (3, 'SNS_PALDANG_WL', '팔당댐 수위계',     '수위계',   'm',    20.0000,  30.0000,  '2010-01-01', 25.4800,  now()-interval '10 minutes','active'),
    (5, 'SNS_DAECHEONG_WL','대청댐 수위계',    '수위계',   'm',    50.0000,  80.0000,  '2012-06-01', 72.3100,  now()-interval '5 minutes', 'active'),
    (6, 'SNS_WQ_SOYANG_PH','소양강 pH 센서',   'pH센서',   'pH',   0.0000,   14.0000,  '2018-01-01', 7.2000,   now()-interval '15 minutes','active'),
    (6, 'SNS_WQ_SOYANG_DO','소양강 DO 센서',   'DO센서',   'mg/L', 0.0000,   20.0000,  '2018-01-01', 8.5000,   now()-interval '15 minutes','active'),
    (7, 'SNS_WQ_PALDG_PH', '팔당 pH 센서',    'pH센서',   'pH',   0.0000,   14.0000,  '2016-06-01', 7.5000,   now()-interval '20 minutes','active');

-- ============================================================================
-- 15. 자산 DB 현황 (asset_db)
-- ============================================================================
INSERT INTO asset_db (asset_ty, asset_nm, tot_co, actv_co, src_sys, last_sync_at, dc) VALUES
    ('테이블',     '운영 DB 테이블',    2450,  2100, 'PostgreSQL',  now()-interval '1 hour',  '전체 운영 테이블'),
    ('API 엔드포인트','등록 API',        128,   95,   'API Gateway', now()-interval '30 minutes','게이트웨이 등록 API'),
    ('파일 데이터셋', '파일 자산',       350,   280,  'HDFS/S3',     now()-interval '2 hours',   '하둡/S3 파일 데이터'),
    ('Kafka 토픽',    'Kafka 토픽',      45,    38,   'Kafka',       now()-interval '10 minutes','Kafka 클러스터 토픽'),
    ('dbt 모델',      'dbt 변환 모델',   85,    72,   'dbt Cloud',   now()-interval '3 hours',   'dbt 프로젝트 모델');
