/*
 * seed_01_core.sql — 핵심 기초 데이터 (사용자·조직·권한 + 메뉴 + 코드)
 * 의존성: role(이미 INSERT됨), domn(이미 INSERT됨), cd_grp(이미 INSERT됨)
 */

-- ============================================================================
-- 1. 본부 (divs)
-- ============================================================================
INSERT INTO divs (divs_cd, divs_nm, sort_ord) VALUES
    ('DIV_WATER',   '수자원본부',     1),
    ('DIV_QUALITY', '수질환경본부',   2),
    ('DIV_ENERGY',  '에너지본부',     3),
    ('DIV_INFRA',   '인프라관리본부', 4),
    ('DIV_DIGITAL', '디지털혁신본부', 5),
    ('DIV_MGMT',    '경영관리본부',   6);

-- ============================================================================
-- 2. 부서 (dept)
-- ============================================================================
INSERT INTO dept (divs_id, dept_cd, dept_nm, hdcnt, sort_ord) VALUES
    (1, 'DEPT_DAM',       '댐관리처',       45, 1),
    (1, 'DEPT_RIVER',     '하천관리처',     32, 2),
    (1, 'DEPT_FLOOD',     '홍수관리처',     28, 3),
    (2, 'DEPT_WQ_MGMT',   '수질관리처',     35, 1),
    (2, 'DEPT_WQ_ANLYS',  '수질분석처',     22, 2),
    (3, 'DEPT_HYDRO',     '수력발전처',     18, 1),
    (3, 'DEPT_SOLAR',     '신재생에너지처', 15, 2),
    (4, 'DEPT_PIPE',      '관로관리처',     40, 1),
    (4, 'DEPT_FACILITY',  '시설관리처',     38, 2),
    (5, 'DEPT_DATA',      '데이터관리처',   25, 1),
    (5, 'DEPT_PLATFORM',  '플랫폼운영처',  20, 2),
    (5, 'DEPT_AI',        'AI혁신처',       12, 3),
    (6, 'DEPT_HR',        '인사처',         30, 1),
    (6, 'DEPT_FINANCE',   '재무처',         22, 2);

-- ============================================================================
-- 3. 사용자 (usr_acnt) — role_id 참조: 이미 INSERT된 role 사용
-- ============================================================================
INSERT INTO usr_acnt (usr_id, login_id, usr_nm, email, phone, dept_id, role_id, login_ty, stat) VALUES
    ('a0000001-0000-0000-0000-000000000001', 'admin',       '김관리',   'admin@kwater.or.kr',      '010-1111-0001', 10, 9,  'admin',    'active'),
    ('a0000001-0000-0000-0000-000000000002', 'sec_admin',   '이보안',   'security@kwater.or.kr',   '010-1111-0002', 10, 10, 'admin',    'active'),
    ('a0000001-0000-0000-0000-000000000003', 'super_admin', '박최고',   'super@kwater.or.kr',      '010-1111-0003', 10, 11, 'admin',    'active'),
    ('a0000001-0000-0000-0000-000000000010', 'hong.gildong','홍길동',   'gdhong@kwater.or.kr',     '010-2222-0001',  1,  1, 'sso',      'active'),
    ('a0000001-0000-0000-0000-000000000011', 'kim.suji',    '김수지',   'sjkim@kwater.or.kr',      '010-2222-0002',  1,  2, 'sso',      'active'),
    ('a0000001-0000-0000-0000-000000000012', 'lee.minho',   '이민호',   'mhlee@kwater.or.kr',      '010-2222-0003',  4,  3, 'sso',      'active'),
    ('a0000001-0000-0000-0000-000000000013', 'park.jiyeon', '박지연',   'jypark@kwater.or.kr',     '010-2222-0004', 10,  3, 'sso',      'active'),
    ('a0000001-0000-0000-0000-000000000014', 'choi.dongsu', '최동수',   'dschoi@kwater.or.kr',     '010-2222-0005',  5,  1, 'sso',      'active'),
    ('a0000001-0000-0000-0000-000000000020', 'partner01',   '김협력',   'partner01@partner.co.kr', '010-3333-0001', NULL, 4, 'partner',  'active'),
    ('a0000001-0000-0000-0000-000000000021', 'dev.external','이개발',   'dev@partner.co.kr',       '010-3333-0002', NULL, 5, 'partner',  'active'),
    ('a0000001-0000-0000-0000-000000000030', 'eng.pipeline','정파이프', 'pipeline@kwater.or.kr',   '010-4444-0001', 11,  6, 'engineer', 'active'),
    ('a0000001-0000-0000-0000-000000000031', 'eng.etl',     '한이티엘', 'etl@kwater.or.kr',        '010-4444-0002', 11,  7, 'engineer', 'active'),
    ('a0000001-0000-0000-0000-000000000032', 'eng.dba',     '윤디비에이','dba@kwater.or.kr',       '010-4444-0003', 11,  8, 'engineer', 'active');

-- ============================================================================
-- 4. 메뉴 (menu) — parent_cd 참조
-- ============================================================================
INSERT INTO menu (menu_cd, menu_nm, parent_cd, sctn, scrin_id, icon, sort_ord) VALUES
    -- 대시보드
    ('dashboard',       '대시보드',       NULL,            'main',     'dashboard',         'grid',          1),
    -- 데이터 카탈로그
    ('catalog',         '데이터 카탈로그', NULL,           'main',     NULL,                'database',      2),
    ('cat-search',      '카탈로그 검색',   'catalog',      'main',     'cat-search',        'search',        1),
    ('cat-detail',      '데이터셋 상세',   'catalog',      'main',     'cat-detail',        'file-text',     2),
    ('cat-glossary',    '용어사전',        'catalog',      'main',     'cat-glossary',      'book',          3),
    -- 메타데이터
    ('metadata',        '메타데이터',      NULL,           'main',     NULL,                'layers',        3),
    ('meta-std-dict',   '표준사전관리',    'metadata',     'main',     'meta-std-dict',     'book-open',     1),
    ('meta-model',      '데이터모델',      'metadata',     'main',     'meta-model',        'box',           2),
    -- 수집 관리
    ('collect',         '수집 관리',       NULL,           'main',     NULL,                'download-cloud', 4),
    ('collect-pipeline','파이프라인',       'collect',      'main',     'collect-pipeline',  'git-branch',    1),
    ('collect-source',  '원천시스템',       'collect',      'main',     'collect-source',    'server',        2),
    ('collect-cdc',     'CDC 모니터링',    'collect',      'main',     'collect-cdc',       'activity',      3),
    ('collect-kafka',   'Kafka 토픽',      'collect',      'main',     'collect-kafka',     'radio',         4),
    -- 데이터 유통
    ('distribute',      '데이터 유통',     NULL,           'main',     NULL,                'share-2',       5),
    ('dist-product',    '데이터 상품',     'distribute',   'main',     'dist-product',      'package',       1),
    ('dist-request',    '데이터 신청',     'distribute',   'main',     'dist-request',      'file-plus',     2),
    ('dist-deidentify', '비식별화',        'distribute',   'main',     'dist-deidentify',   'shield',        3),
    -- 품질 관리
    ('quality',         '품질 관리',       NULL,           'main',     NULL,                'check-circle',  6),
    ('quality-dashboard','품질 대시보드',  'quality',      'main',     'quality-dashboard', 'bar-chart',     1),
    ('quality-rules',   '품질 규칙',       'quality',      'main',     'quality-rules',     'list',          2),
    ('quality-issues',  '품질 이슈',       'quality',      'main',     'quality-issues',    'alert-triangle',3),
    -- 시스템 관리
    ('system',          '시스템 관리',     NULL,           'main',     NULL,                'settings',      7),
    ('sys-user',        '사용자 관리',     'system',       'main',     'sys-user',          'users',         1),
    ('sys-role',        '역할 관리',       'system',       'main',     'sys-role',          'shield',        2),
    ('sys-audit',       '감사 로그',       'system',       'main',     'sys-audit',         'file-text',     3),
    ('sys-monitor',     '시스템 모니터링', 'system',       'main',     'sys-monitor',       'monitor',       4),
    -- 커뮤니티
    ('community',       '커뮤니티',        NULL,           'main',     NULL,                'message-square', 8),
    ('comm-board',      '게시판',          'community',    'main',     'comm-board',        'clipboard',     1),
    ('comm-resource',   '자료실',          'community',    'main',     'comm-resource',     'archive',       2);

-- ============================================================================
-- 5. 역할-메뉴 권한 (role_menu_perm) — 주요 역할별 권한 매핑
-- ============================================================================
INSERT INTO role_menu_perm (role_id, menu_id, can_read, can_crt, can_updt, can_del, can_aprv, can_dwld)
SELECT r.role_id, m.menu_id,
    TRUE,  -- can_read
    CASE WHEN r.role_lvl >= 2 THEN TRUE ELSE FALSE END,  -- can_crt
    CASE WHEN r.role_lvl >= 2 THEN TRUE ELSE FALSE END,  -- can_updt
    CASE WHEN r.role_lvl >= 3 THEN TRUE ELSE FALSE END,  -- can_del
    CASE WHEN r.role_lvl >= 3 THEN TRUE ELSE FALSE END,  -- can_aprv
    CASE WHEN r.role_lvl >= 1 THEN TRUE ELSE FALSE END   -- can_dwld
FROM role r
CROSS JOIN menu m
WHERE r.role_cd IN ('STAFF_USER','STAFF_DEPT_MGR','STAFF_STEWARD','ADM_SYSTEM','ADM_SUPER')
  AND m.parent_cd IS NOT NULL;

-- 협력직원: 카탈로그+커뮤니티만 읽기
INSERT INTO role_menu_perm (role_id, menu_id, can_read, can_dwld)
SELECT r.role_id, m.menu_id, TRUE, FALSE
FROM role r, menu m
WHERE r.role_cd IN ('PARTNER_VIEW','PARTNER_DEV')
  AND m.menu_cd IN ('cat-search','cat-detail','cat-glossary','comm-board','comm-resource');

-- 엔지니어: 수집+모니터링 전체 권한
INSERT INTO role_menu_perm (role_id, menu_id, can_read, can_crt, can_updt, can_del, can_aprv, can_dwld)
SELECT r.role_id, m.menu_id, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE
FROM role r, menu m
WHERE r.role_cd IN ('ENG_PIPELINE','ENG_ETL','ENG_DBA')
  AND m.menu_cd IN ('collect-pipeline','collect-source','collect-cdc','collect-kafka','sys-monitor');

-- ============================================================================
-- 6. 코드 상세 (cd) — cd_grp 9건에 대한 코드값
-- ============================================================================
INSERT INTO cd (grp_id, cd_val, cd_nm, sort_ord) VALUES
    -- CD_REGION (grp_id=1)
    (1, 'HAN',       '한강유역',       1),
    (1, 'NAKDONG',    '낙동강유역',     2),
    (1, 'GEUM',       '금강유역',       3),
    (1, 'YEONGSAN',   '영산강·섬진강유역', 4),
    -- CD_SECURITY_LEVEL (grp_id=2)
    (2, 'PUBLIC',      '공개',          1),
    (2, 'INTERNAL',    '내부일반',      2),
    (2, 'RESTRICTED',  '내부중요',      3),
    (2, 'CONFIDENTIAL','기밀',          4),
    -- CD_ASSET_TYPE (grp_id=3)
    (3, 'TABLE',  '테이블',   1),
    (3, 'API',    'API',       2),
    (3, 'FILE',   '파일',      3),
    (3, 'VIEW',   '뷰',        4),
    (3, 'STREAM', '스트림',    5),
    -- CD_COLLECT_METHOD (grp_id=4)
    (4, 'CDC',        'CDC(실시간)',         1),
    (4, 'BATCH',      '배치(ETL)',           2),
    (4, 'API',        'API호출',             3),
    (4, 'FILE',       '파일수집',            4),
    (4, 'STREAMING',  '스트리밍',            5),
    (4, 'MIGRATION',  '마이그레이션',        6),
    -- CD_DBMS_TYPE (grp_id=5)
    (5, 'POSTGRESQL', 'PostgreSQL',  1),
    (5, 'ORACLE',     'Oracle',      2),
    (5, 'MYSQL',      'MySQL',       3),
    (5, 'MSSQL',      'MS SQL',      4),
    (5, 'SAP_HANA',   'SAP HANA',    5),
    -- CD_DQ_DIMENSION (grp_id=6)
    (6, 'COMPLETENESS', '완전성',    1),
    (6, 'ACCURACY',     '정확성',    2),
    (6, 'CONSISTENCY',  '일관성',    3),
    (6, 'TIMELINESS',   '적시성',    4),
    (6, 'VALIDITY',     '유효성',    5),
    (6, 'UNIQUENESS',   '유일성',    6),
    -- CD_CHART_TYPE (grp_id=7)
    (7, 'BAR',     '막대',       1),
    (7, 'LINE',    '꺾은선',     2),
    (7, 'PIE',     '원형',       3),
    (7, 'SCATTER', '산점도',     4),
    (7, 'HEATMAP', '히트맵',     5),
    (7, 'MAP',     '지도',       6),
    -- CD_BOARD_TYPE (grp_id=8)
    (8, 'NOTICE',   '공지사항',   1),
    (8, 'INTERNAL', '내부게시판', 2),
    (8, 'EXTERNAL', '외부게시판', 3),
    -- CD_REQUEST_TYPE (grp_id=9)
    (9, 'DOWNLOAD', '다운로드',   1),
    (9, 'API',      'API접근',    2),
    (9, 'SHARE',    '공유',       3),
    (9, 'EXPORT',   '반출',       4);

-- ============================================================================
-- 7. 로그인 이력 (login_hist) — 최근 로그인 기록
-- ============================================================================
INSERT INTO login_hist (usr_id, login_ty, login_ip, login_at, is_succes) VALUES
    ('a0000001-0000-0000-0000-000000000001', 'admin',    '10.1.1.100', now() - interval '1 hour', TRUE),
    ('a0000001-0000-0000-0000-000000000010', 'sso',      '10.1.2.50',  now() - interval '2 hours', TRUE),
    ('a0000001-0000-0000-0000-000000000011', 'sso',      '10.1.2.51',  now() - interval '3 hours', TRUE),
    ('a0000001-0000-0000-0000-000000000012', 'sso',      '10.1.3.10',  now() - interval '30 minutes', TRUE),
    ('a0000001-0000-0000-0000-000000000020', 'partner',  '192.168.1.50', now() - interval '5 hours', TRUE),
    ('a0000001-0000-0000-0000-000000000030', 'engineer', '10.1.5.1',   now() - interval '45 minutes', TRUE),
    ('a0000001-0000-0000-0000-000000000021', 'partner',  '192.168.1.51', now() - interval '1 day', FALSE);
