/*
 * seed_04_community_system.sql — 커뮤니티·소통 + 시스템관리 도메인
 * 의존성: seed_01, seed_02, seed_03 선행
 */

-- ============================================================================
-- 1. 게시판 (board_post)
-- ============================================================================
INSERT INTO board_post (usr_id, tit, cntnt, post_ty, is_pinnd, view_co, like_co, cm_co) VALUES
    ('a0000001-0000-0000-0000-000000000001', 'DataHub Portal 오픈 안내',          'K-water DataHub Portal이 정식 오픈되었습니다. 데이터 카탈로그 검색, API 발급, 품질 모니터링 등의 기능을 이용하실 수 있습니다.', 'notice',   TRUE,  520, 35, 8),
    ('a0000001-0000-0000-0000-000000000001', '2026년 1분기 데이터 품질 보고서',   '전사 데이터 품질 점수가 전 분기 대비 3.2% 향상되었습니다. 상세 내용은 첨부 보고서를 참고해 주세요.',                             'notice',   TRUE,  380, 22, 5),
    ('a0000001-0000-0000-0000-000000000013', '표준 용어사전 업데이트 안내',        '수자원 도메인 표준 용어 15건이 신규 등록되었습니다. 메타데이터 → 표준사전관리에서 확인 가능합니다.',                              'notice',   FALSE, 210, 12, 3),
    ('a0000001-0000-0000-0000-000000000010', '댐 수위 데이터 활용 사례 공유',     '소양강댐 수위 데이터를 활용한 홍수 예측 모델 개발 사례를 공유합니다.',                                                         'internal', FALSE, 156, 18, 6),
    ('a0000001-0000-0000-0000-000000000012', '수질TMS 데이터 보정 방법 안내',     'TMS 센서 교정 시 발생하는 이상값 보정 프로세스를 안내합니다.',                                                                   'internal', FALSE, 98,  8,  2),
    ('a0000001-0000-0000-0000-000000000030', 'CDC 파이프라인 모니터링 가이드',    '실시간 CDC 파이프라인의 지연(lag) 모니터링 방법과 장애 대응 절차를 공유합니다.',                                                 'internal', FALSE, 75,  5,  1),
    ('a0000001-0000-0000-0000-000000000021', '외부 API 연동 시 주의사항',         '데이터 상품 API를 외부 시스템과 연동할 때의 인증 방식과 호출 제한에 대해 정리했습니다.',                                         'external', FALSE, 45,  3,  0);

-- ============================================================================
-- 2. 게시판 댓글 (board_cm)
-- ============================================================================
INSERT INTO board_cm (post_id, usr_id, parent_id, cm_text) VALUES
    (1, 'a0000001-0000-0000-0000-000000000010', NULL, '포탈 오픈 축하합니다! 카탈로그 검색 기능이 매우 편리하네요.'),
    (1, 'a0000001-0000-0000-0000-000000000014', NULL, '데이터 신청 프로세스가 간소화되어 좋습니다.'),
    (1, 'a0000001-0000-0000-0000-000000000001', 1,    '감사합니다. 추가 개선사항이 있으면 말씀해 주세요.'),
    (4, 'a0000001-0000-0000-0000-000000000011', NULL, '좋은 사례 공유 감사합니다. 저도 유입량 데이터로 비슷한 분석을 해보겠습니다.'),
    (4, 'a0000001-0000-0000-0000-000000000012', NULL, '예측 모델의 정확도가 어느 정도인지 궁금합니다.'),
    (4, 'a0000001-0000-0000-0000-000000000010', 5,    '현재 RMSE 기준 약 0.3m 수준입니다. 추가 데이터 확보 시 개선 예정입니다.'),
    (5, 'a0000001-0000-0000-0000-000000000014', NULL, '보정 프로세스 문서화 감사합니다. 참고하겠습니다.');

-- ============================================================================
-- 3. 자료실 (resrce_archv)
-- ============================================================================
INSERT INTO resrce_archv (usr_id, resrce_nm, dc, file_nm, file_path, file_size, mime_ty, ctgry, dwld_co) VALUES
    ('a0000001-0000-0000-0000-000000000013', 'DataHub 사용자 가이드 v2.0',        '포탈 전체 기능 사용 가이드',                  'DataHub_UserGuide_v2.0.pdf',    '/docs/guides/',     15728640,  'application/pdf',  '가이드',  230),
    ('a0000001-0000-0000-0000-000000000001', '데이터 품질 관리 정책서',            '전사 데이터 품질 관리 정책 및 프로세스 문서', 'DQ_Policy_2026.pdf',            '/docs/policies/',   8388608,   'application/pdf',  '정책',    180),
    ('a0000001-0000-0000-0000-000000000012', '표준 용어사전 엑셀 양식',            '표준 용어 등록 시 사용하는 엑셀 양식',        'StdTerm_Template.xlsx',         '/docs/templates/',  524288,    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', '양식', 95),
    ('a0000001-0000-0000-0000-000000000030', 'CDC 파이프라인 운영 매뉴얼',         'Debezium CDC 커넥터 설치·운영 매뉴얼',       'CDC_Operation_Manual.pdf',      '/docs/manuals/',    6291456,   'application/pdf',  '매뉴얼', 62),
    ('a0000001-0000-0000-0000-000000000002', '데이터 보안 관리 지침',              '데이터 보안등급 분류 및 접근통제 지침',       'DataSecurity_Guideline.pdf',    '/docs/security/',   4194304,   'application/pdf',  '정책',    145);

-- ============================================================================
-- 4. 보안 정책 (scrty_polcy)
-- ============================================================================
INSERT INTO scrty_polcy (polcy_nm, polcy_ty, dc, trget_lvl, is_actv, eftv_from, eftv_to) VALUES
    ('기밀 데이터 접근 통제',     'access_control',   '기밀 등급 데이터는 보안관리자 승인 후 접근 가능',       'confidential', TRUE, '2026-01-01', '2026-12-31'),
    ('내부중요 데이터 외부반출 제한','data_export',    '내부중요 등급 이상 데이터 외부 반출 시 비식별화 필수',  'restricted',   TRUE, '2026-01-01', '2026-12-31'),
    ('API 키 만료 정책',          'api_security',     'API 키는 최대 1년, 외부 사용자는 90일 유효',            'public',       TRUE, '2026-01-01', NULL);

-- ============================================================================
-- 5. 시스템 인터페이스 (sys_intrfc)
-- ============================================================================
INSERT INTO sys_intrfc (intrfc_cd, intrfc_nm, src_sys_id, trget_sys_id, intrfc_ty, prtcl, freq, drct, last_succes_at, succes_rt, avg_rspns_ms, stat) VALUES
    ('IF_SCADA_DAM',   'SCADA 댐 수위 연계',  2, NULL, 'realtime', 'TCP',   '실시간', 'inbound',  now()-interval '5 minutes',  99.95, 120,  'active'),
    ('IF_TMS_WQ',      'TMS 수질 연계',       3, NULL, 'batch',    'HTTP',  '1시간',  'inbound',  now()-interval '1 hour',     99.80, 450,  'active'),
    ('IF_SAP_FIN',     'SAP 재무 연계',       1, NULL, 'batch',    'RFC',   '일별',   'inbound',  now()-interval '22 hours',   99.50, 3200, 'active'),
    ('IF_KMA_WEATHER', '기상청 API 연계',     6, NULL, 'api',      'REST',  '6시간',  'inbound',  now()-interval '6 hours',    98.50, 850,  'active');

-- ============================================================================
-- 6. 감사 로그 (audit_log)
-- ============================================================================
INSERT INTO audit_log (usr_id, usr_nm, actn_ty, trget_table, trget_id, actn_dtl, ip_addr, rst) VALUES
    ('a0000001-0000-0000-0000-000000000001', '김관리',   'LOGIN',     NULL,            NULL,                 '관리자 로그인',                     '10.1.1.100', 'success'),
    ('a0000001-0000-0000-0000-000000000010', '홍길동',   'READ',      'dset',          'd0000001-0000-0000-0000-000000000001', '댐 수위 데이터셋 조회',     '10.1.2.50',  'success'),
    ('a0000001-0000-0000-0000-000000000010', '홍길동',   'DOWNLOAD',  'dset',          'd0000001-0000-0000-0000-000000000001', '댐 수위 데이터 다운로드',   '10.1.2.50',  'success'),
    ('a0000001-0000-0000-0000-000000000012', '이민호',   'CREATE',    'glsry_term',    '1',                  '표준용어 [수위] 등록',              '10.1.3.10',  'success'),
    ('a0000001-0000-0000-0000-000000000012', '이민호',   'APPROVE',   'glsry_term',    '1',                  '표준용어 [수위] 승인',              '10.1.3.10',  'success'),
    ('a0000001-0000-0000-0000-000000000021', '이개발',   'API_CALL',  'data_product',  'b0000001-0000-0000-0000-000000000001', '댐 현황 API 호출',   '192.168.1.51','success'),
    ('a0000001-0000-0000-0000-000000000020', '김협력',   'READ',      'dset',          'd0000001-0000-0000-0000-000000000006', '수력발전 데이터 열람 시도', '192.168.1.50','denied'),
    ('a0000001-0000-0000-0000-000000000002', '이보안',   'UPDATE',    'scrty_polcy',   '1',                  '기밀데이터 접근통제 정책 수정',     '10.1.1.101', 'success'),
    ('a0000001-0000-0000-0000-000000000030', '정파이프', 'CREATE',    'ppln',          '1',                  '댐수위 실시간 수집 파이프라인 생성','10.1.5.1',   'success'),
    ('a0000001-0000-0000-0000-000000000031', '한이티엘', 'UPDATE',    'ppln_exec',     '3',                  '수질TMS 배치 수집 실행',            '10.1.5.2',   'success');

-- ============================================================================
-- 7. 알림 (ntcn)
-- ============================================================================
INSERT INTO ntcn (usr_id, ntcn_ty, tit, msg, link_url, is_read) VALUES
    ('a0000001-0000-0000-0000-000000000010', 'system',   'DataHub Portal 오픈',           '포탈이 정식 오픈되었습니다. 지금 바로 이용해 보세요.',                    '/dashboard',          TRUE),
    ('a0000001-0000-0000-0000-000000000010', 'approval', '데이터 신청 승인 완료',         'REQ-2026-001 (고객 사용량 다운로드) 신청이 승인되었습니다.',              '/dist-request',       TRUE),
    ('a0000001-0000-0000-0000-000000000014', 'quality',  '관로자산 품질 이슈 발생',       '관로자산 데이터 관경(pipe_dia) NULL 15,000건 발견. 확인 부탁드립니다.',   '/quality-issues',     FALSE),
    ('a0000001-0000-0000-0000-000000000030', 'pipeline', '파이프라인 실행 중',            'PL_DAM_WATER 파이프라인이 현재 실행 중입니다.',                          '/collect-pipeline',   FALSE),
    ('a0000001-0000-0000-0000-000000000020', 'security', '데이터 반출 요청 반려',         'REQ-2026-004 (발전량 데이터 외부반출) 요청이 보안등급 미달로 반려되었습니다.', '/dist-request',  TRUE),
    ('a0000001-0000-0000-0000-000000000012', 'approval', '표준용어 승인 요청',            '표준용어 [사용량] 승인 요청이 도착했습니다.',                            '/meta-std-dict',      FALSE),
    ('a0000001-0000-0000-0000-000000000001', 'system',   '시스템 점검 예정 안내',         '3/20(토) 02:00~06:00 시스템 점검이 예정되어 있습니다.',                  '/dashboard',          FALSE),
    ('a0000001-0000-0000-0000-000000000011', 'quality',  '수질 데이터 품질 점수 하락',    '수질 도메인 적시성 점수가 85.2%로 하락했습니다. 확인이 필요합니다.',      '/quality-dashboard',  FALSE);

-- ============================================================================
-- 8. 위젯 템플릿 (widg_tmplat)
-- ============================================================================
INSERT INTO widg_tmplat (widg_cd, widg_nm, widg_ty, dc, min_width, min_hg, max_width, max_hg, ctgry, is_actv) VALUES
    ('WDG_DAM_STATUS',   '댐 저수율 현황',      'chart',    '전국 다목적댐 저수율 막대 차트',     2, 1, 4, 2, '수자원',    TRUE),
    ('WDG_WQ_REALTIME',  '수질 실시간 추이',    'chart',    '주요 측정소 수질 시계열 라인 차트',   2, 1, 4, 3, '수질',      TRUE),
    ('WDG_DQ_SCORE',     '품질 점수 요약',      'kpi',      '도메인별 데이터 품질 종합 점수',      1, 1, 2, 1, '품질',      TRUE),
    ('WDG_PIPELINE_STAT','파이프라인 현황',     'stat',     '수집 파이프라인 상태 요약',           1, 1, 2, 1, '수집',      TRUE),
    ('WDG_RECENT_ALERT', '최근 알림',           'list',     '최근 시스템 알림 목록',               2, 1, 4, 2, '시스템',    TRUE),
    ('WDG_CATALOG_STAT', '카탈로그 현황',       'kpi',      '데이터셋·API·파일 자산 수 요약',     1, 1, 2, 1, '카탈로그',  TRUE);

-- ============================================================================
-- 9. 사용자 위젯 레이아웃 (usr_widg_layout)
-- ============================================================================
INSERT INTO usr_widg_layout (usr_id, widg_id, positn_x, positn_y, width, hg, sort_ord) VALUES
    ('a0000001-0000-0000-0000-000000000001', 1, 0, 0, 2, 1, 1),
    ('a0000001-0000-0000-0000-000000000001', 3, 2, 0, 1, 1, 2),
    ('a0000001-0000-0000-0000-000000000001', 4, 3, 0, 1, 1, 3),
    ('a0000001-0000-0000-0000-000000000001', 5, 0, 1, 2, 1, 4),
    ('a0000001-0000-0000-0000-000000000010', 1, 0, 0, 2, 1, 1),
    ('a0000001-0000-0000-0000-000000000010', 2, 2, 0, 2, 1, 2),
    ('a0000001-0000-0000-0000-000000000010', 6, 0, 1, 1, 1, 3);

-- ============================================================================
-- 10. 리니지 (lnage_node + lnage_edge)
-- ============================================================================
INSERT INTO lnage_node (node_ty, obj_id, obj_nm, dc) VALUES
    ('system',   'SYS_SCADA',         'SCADA 시스템',          '댐·보 실시간 감시 시스템'),
    ('system',   'SYS_TMS',           '수질TMS 시스템',        '실시간 수질 자동측정 시스템'),
    ('pipeline', 'PL_DAM_WATER',      '댐수위 실시간 수집',    'SCADA→DataHub CDC 파이프라인'),
    ('pipeline', 'PL_WQ_TMS',         '수질TMS 배치 수집',     'TMS→DataHub 배치 파이프라인'),
    ('dataset',  'DS_DAM_WATER_LVL',  '댐 수위 측정 데이터',   'raw.dam_water_level'),
    ('dataset',  'DS_WQ_TMS_REALTIME','수질TMS 실시간 데이터', 'vw_wq_tms_realtime'),
    ('product',  'PRD_DAM_STATUS',    '댐 현황 종합 API',      '/api/v2/dam/status'),
    ('product',  'PRD_WQ_REALTIME',   '수질 실시간 API',       '/api/v1/waterquality/realtime');

INSERT INTO lnage_edge (src_node_id, trget_node_id, edge_ty, trsfmn, ppln_id) VALUES
    (1, 3, 'extract',   'CDC change capture',    1),
    (3, 5, 'transform', 'schema mapping + type cast', 1),
    (2, 4, 'extract',   'batch query',           2),
    (4, 6, 'transform', 'cleansing + aggregation', 2),
    (5, 7, 'publish',   'API endpoint serving',  NULL),
    (6, 8, 'publish',   'API endpoint serving',  NULL);

-- ============================================================================
-- 11. AI 대화 (ai_chat_sesn + ai_chat_msg)
-- ============================================================================
INSERT INTO ai_chat_sesn (sesn_id, usr_id, sesn_tit, model_nm, msg_co) VALUES
    ('e0000001-0000-0000-0000-000000000001', 'a0000001-0000-0000-0000-000000000010', '소양강댐 수위 트렌드 분석', 'gpt-4o', 4),
    ('e0000001-0000-0000-0000-000000000002', 'a0000001-0000-0000-0000-000000000012', '수질 데이터 품질 규칙 추천', 'gpt-4o', 6);

INSERT INTO ai_chat_msg (sesn_id, role, msg_text, tkns_used, rspns_ms) VALUES
    ('e0000001-0000-0000-0000-000000000001', 'user',      '최근 1개월 소양강댐 수위 트렌드를 분석해 주세요.',      25,   0),
    ('e0000001-0000-0000-0000-000000000001', 'assistant', '소양강댐의 최근 1개월 수위 데이터를 분석한 결과, 평균 수위는 193.2m이며 하강 추세입니다.', 150, 2500),
    ('e0000001-0000-0000-0000-000000000001', 'user',      '저수율은 어떤가요?',                                    12,   0),
    ('e0000001-0000-0000-0000-000000000001', 'assistant', '현재 저수율은 약 85.3%로 평년 대비 약간 낮은 수준입니다.', 80, 1800),
    ('e0000001-0000-0000-0000-000000000002', 'user',      '수질TMS 데이터에 적용할 품질 규칙을 추천해 주세요.',     30,   0),
    ('e0000001-0000-0000-0000-000000000002', 'assistant', 'pH: 0~14 범위 검사, DO: 양수 검사, BOD/COD: 이상치 탐지 규칙을 추천합니다.', 200, 3200);

-- ============================================================================
-- 12. 일별 유통 통계 (daly_dist_stats)
-- ============================================================================
INSERT INTO daly_dist_stats (stat_dt, product_id, tot_calls, succes_calls, fail_calls, avg_rspns_ms, unique_usrs, data_vlm_mb) VALUES
    (CURRENT_DATE,     'b0000001-0000-0000-0000-000000000001', 1250, 1245, 5,  135, 28, 450.50),
    (CURRENT_DATE - 1, 'b0000001-0000-0000-0000-000000000001', 1180, 1175, 5,  142, 25, 420.30),
    (CURRENT_DATE - 2, 'b0000001-0000-0000-0000-000000000001', 980,  978,  2,  128, 22, 380.10),
    (CURRENT_DATE,     'b0000001-0000-0000-0000-000000000002', 850,  845,  5,  210, 15, 320.80),
    (CURRENT_DATE - 1, 'b0000001-0000-0000-0000-000000000002', 790,  788,  2,  225, 13, 295.50),
    (CURRENT_DATE,     'b0000001-0000-0000-0000-000000000004', 320,  320,  0,  180, 8,  150.20);

-- ============================================================================
-- 13. 부서별 활용 통계 (dept_usg_stats)
-- ============================================================================
INSERT INTO dept_usg_stats (stat_dt, dept_id, dset_co, api_calls, dwld_co, search_co, actv_usrs) VALUES
    (CURRENT_DATE, 1,  8,   450, 12, 85,  15),
    (CURRENT_DATE, 4,  5,   280, 8,  62,  12),
    (CURRENT_DATE, 10, 12,  1200, 25, 150, 18),
    (CURRENT_DATE, 11, 15,  2500, 5,  45,  8),
    (CURRENT_DATE, 6,  3,   180, 3,  28,  6);

-- ============================================================================
-- 14. ERP 동기화 이력 (erp_sync_hist)
-- ============================================================================
INSERT INTO erp_sync_hist (sync_ty, sync_drct, tot_rcrds, crtd_co, updtd_co, skipd_co, err_co, strtd_at, fnshed_at, stat) VALUES
    ('organization', 'inbound', 350,   5,   12,  333, 0, now()-interval '22 hours', now()-interval '22 hours'+interval '45 seconds', 'success'),
    ('employee',     'inbound', 1200,  15,  45,  1140, 0, now()-interval '22 hours'+interval '50 seconds', now()-interval '22 hours'+interval '180 seconds', 'success'),
    ('finance',      'inbound', 45000, 2500, 800, 41500, 200, now()-interval '22 hours'+interval '200 seconds', now()-interval '22 hours'+interval '500 seconds', 'success');

-- ============================================================================
-- 15. dbt 모델 (dbt_model)
-- ============================================================================
INSERT INTO dbt_model (model_nm, model_path, mtrlzn, src_tbls, trget_table, dc, last_run_at, last_run_stat, run_dur_secnd, owner_usr_id, stat) VALUES
    ('stg_dam_water_level', 'models/staging/stg_dam_water_level.sql', 'view',  ARRAY['raw.dam_water_level'], 'staging.stg_dam_water_level', '댐수위 스테이징 뷰',       now()-interval '3 hours', 'success', 8,   'a0000001-0000-0000-0000-000000000031', 'active'),
    ('stg_wq_tms',          'models/staging/stg_wq_tms.sql',          'view',  ARRAY['raw.wq_tms_data'],     'staging.stg_wq_tms',          '수질TMS 스테이징 뷰',      now()-interval '3 hours', 'success', 12,  'a0000001-0000-0000-0000-000000000031', 'active'),
    ('mart_dam_daily',      'models/mart/mart_dam_daily.sql',         'table', ARRAY['staging.stg_dam_water_level','staging.stg_dam_inflow'], 'mart.dam_daily', '댐 일별 집계 마트',  now()-interval '2 hours', 'success', 45, 'a0000001-0000-0000-0000-000000000031', 'active'),
    ('mart_wq_station',     'models/mart/mart_wq_station.sql',        'table', ARRAY['staging.stg_wq_tms'],  'mart.wq_station_daily',       '수질측정소 일별 마트', now()-interval '2 hours', 'success', 60,  'a0000001-0000-0000-0000-000000000031', 'active');

-- ============================================================================
-- 16. 서버 인벤토리 (server_invntry)
-- ============================================================================
INSERT INTO server_invntry (server_nm, server_ty, ip_addr, os_ty, cpu_cores, mory_gb, disk_gb, envrn, dtcntr, stat) VALUES
    ('kw-datahub-db01',  'database',    '10.1.10.11', 'Ubuntu 22.04', 32, 128, 2000, 'production',  '대전 IDC', 'active'),
    ('kw-datahub-db02',  'database',    '10.1.10.12', 'Ubuntu 22.04', 32, 128, 2000, 'production',  '대전 IDC', 'active'),
    ('kw-datahub-app01', 'application', '10.1.10.21', 'Ubuntu 22.04', 16, 64,  500,  'production',  '대전 IDC', 'active'),
    ('kw-datahub-app02', 'application', '10.1.10.22', 'Ubuntu 22.04', 16, 64,  500,  'production',  '대전 IDC', 'active'),
    ('kw-kafka-01',      'streaming',   '10.1.10.31', 'Ubuntu 22.04', 16, 64,  1000, 'production',  '대전 IDC', 'active'),
    ('kw-kafka-02',      'streaming',   '10.1.10.32', 'Ubuntu 22.04', 16, 64,  1000, 'production',  '대전 IDC', 'active'),
    ('kw-dev-01',        'application', '10.1.20.11', 'Ubuntu 22.04', 8,  32,  500,  'development', '서울 IDC', 'active');

-- ============================================================================
-- 17. 첨부파일 (rqst_atch)
-- ============================================================================
INSERT INTO rqst_atch (rqst_id, file_nm, file_path, file_size, mime_ty) VALUES
    (1, '활용계획서_고객사용량.pdf', '/attachments/requests/REQ-2026-001/', 2097152, 'application/pdf'),
    (3, '관로자산_분석계획.docx',    '/attachments/requests/REQ-2026-003/', 1048576, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
