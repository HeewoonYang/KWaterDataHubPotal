-- ============================================================================
-- 시스템 설정용 공통코드 Seed 데이터
-- 포탈 UI 드롭다운에서 동적으로 로드하여 사용
-- ============================================================================

-- 기존 시스템 코드 삭제 (재실행 가능하도록)
DELETE FROM meta.std_code WHERE group_id IN (
    SELECT group_id FROM meta.std_code_group WHERE code_id LIKE 'SYS_%'
);
DELETE FROM meta.std_code_group WHERE code_id LIKE 'SYS_%';

-- ============================================================================
-- 1. SYS_COLLECT_METHOD — 수집방식
-- ============================================================================
INSERT INTO meta.std_code_group (system_prefix, system_name, logical_name, physical_name, code_id, code_desc, code_type, status)
VALUES ('SYS', '시스템공통', '수집방식', 'COLLECT_METHOD_CD', 'SYS_COLLECT_METHOD', '데이터 수집 방식 코드', '시스템', 'active');

INSERT INTO meta.std_code (group_id, code_value, code_name, sort_order, description, status)
SELECT g.group_id, v.code_value, v.code_name, v.sort_order, v.description, 'active'
FROM meta.std_code_group g,
(VALUES
    ('cdc',       '실시간 (CDC)',    1, 'Change Data Capture 방식 실시간 수집'),
    ('batch',     '배치 (ETL)',      2, '정기 배치 추출-변환-적재'),
    ('api',       'API 호출',        3, 'REST API 기반 수집'),
    ('file',      '파일 수집',       4, '파일 업로드/다운로드 수집'),
    ('streaming', '스트리밍',        5, '스트리밍 실시간 수집'),
    ('migration', '마이그레이션',    6, '일회성 데이터 이관')
) AS v(code_value, code_name, sort_order, description)
WHERE g.code_id = 'SYS_COLLECT_METHOD';

-- ============================================================================
-- 2. SYS_SECURITY_LEVEL — 보안등급
-- ============================================================================
INSERT INTO meta.std_code_group (system_prefix, system_name, logical_name, physical_name, code_id, code_desc, code_type, status)
VALUES ('SYS', '시스템공통', '보안등급', 'SECURITY_LEVEL_CD', 'SYS_SECURITY_LEVEL', '데이터 보안 등급 코드', '시스템', 'active');

INSERT INTO meta.std_code (group_id, code_value, code_name, sort_order, description, status)
SELECT g.group_id, v.code_value, v.code_name, v.sort_order, v.description, 'active'
FROM meta.std_code_group g,
(VALUES
    ('public',       '공개',       1, '외부 공개 가능 데이터'),
    ('internal',     '내부일반',   2, '사내 일반 접근 가능 데이터'),
    ('restricted',   '내부중요',   3, '접근 제한 필요 데이터'),
    ('confidential', '기밀',       4, '최고 보안 등급 데이터')
) AS v(code_value, code_name, sort_order, description)
WHERE g.code_id = 'SYS_SECURITY_LEVEL';

-- ============================================================================
-- 3. SYS_DATA_ASSET_TYPE — 데이터 자산 유형
-- ============================================================================
INSERT INTO meta.std_code_group (system_prefix, system_name, logical_name, physical_name, code_id, code_desc, code_type, status)
VALUES ('SYS', '시스템공통', '데이터자산유형', 'DATA_ASSET_TYPE_CD', 'SYS_DATA_ASSET_TYPE', '데이터 자산 유형 코드', '시스템', 'active');

INSERT INTO meta.std_code (group_id, code_value, code_name, sort_order, description, status)
SELECT g.group_id, v.code_value, v.code_name, v.sort_order, v.description, 'active'
FROM meta.std_code_group g,
(VALUES
    ('table',  '테이블',    1, 'RDB 테이블'),
    ('api',    'API',       2, 'API 엔드포인트'),
    ('file',   '파일',      3, '파일 데이터'),
    ('view',   '뷰/모델',   4, '뷰 또는 데이터 모델'),
    ('stream', '스트림',    5, '실시간 스트림 데이터')
) AS v(code_value, code_name, sort_order, description)
WHERE g.code_id = 'SYS_DATA_ASSET_TYPE';

-- ============================================================================
-- 4. SYS_DATA_TYPE — 데이터 타입 (컬럼 데이터타입)
-- ============================================================================
INSERT INTO meta.std_code_group (system_prefix, system_name, logical_name, physical_name, code_id, code_desc, code_type, status)
VALUES ('SYS', '시스템공통', '데이터타입', 'DATA_TYPE_CD', 'SYS_DATA_TYPE', '컬럼 데이터 타입 코드', '시스템', 'active');

INSERT INTO meta.std_code (group_id, code_value, code_name, sort_order, description, status)
SELECT g.group_id, v.code_value, v.code_name, v.sort_order, v.description, 'active'
FROM meta.std_code_group g,
(VALUES
    ('NUMBER',    'NUMBER',    1, '숫자형'),
    ('VARCHAR',   'VARCHAR',   2, '가변 문자열'),
    ('CHAR',      'CHAR',      3, '고정 문자열'),
    ('DATE',      'DATE',      4, '날짜'),
    ('TIMESTAMP', 'TIMESTAMP', 5, '날짜+시간'),
    ('CLOB',      'CLOB',      6, '대용량 텍스트'),
    ('BLOB',      'BLOB',      7, '바이너리 대용량'),
    ('INTEGER',   'INTEGER',   8, '정수형'),
    ('DECIMAL',   'DECIMAL',   9, '소수형'),
    ('BOOLEAN',   'BOOLEAN',  10, '논리형')
) AS v(code_value, code_name, sort_order, description)
WHERE g.code_id = 'SYS_DATA_TYPE';

-- ============================================================================
-- 5. SYS_UNIT — 단위
-- ============================================================================
INSERT INTO meta.std_code_group (system_prefix, system_name, logical_name, physical_name, code_id, code_desc, code_type, status)
VALUES ('SYS', '시스템공통', '단위', 'UNIT_CD', 'SYS_UNIT', '데이터 측정 단위 코드', '시스템', 'active');

INSERT INTO meta.std_code (group_id, code_value, code_name, sort_order, description, status)
SELECT g.group_id, v.code_value, v.code_name, v.sort_order, v.description, 'active'
FROM meta.std_code_group g,
(VALUES
    ('m',     'm (미터)',      1, '길이 단위'),
    ('m3/s',  'm³/s (유량)',   2, '유량 단위'),
    ('mg/L',  'mg/L (농도)',   3, '농도 단위'),
    ('NTU',   'NTU (탁도)',    4, '탁도 단위'),
    ('MWh',   'MWh (전력)',    5, '전력량 단위'),
    ('degC',  '℃ (온도)',      6, '온도 단위'),
    ('none',  '- (무단위)',    7, '단위 없음'),
    ('km',    'km (킬로미터)', 8, '거리 단위'),
    ('ton',   'ton (톤)',      9, '무게 단위'),
    ('ppm',   'ppm',          10, '농도 단위 (백만분율)'),
    ('pH',    'pH',           11, '수소이온농도'),
    ('percent', '% (퍼센트)', 12, '비율')
) AS v(code_value, code_name, sort_order, description)
WHERE g.code_id = 'SYS_UNIT';

-- ============================================================================
-- 6. SYS_RESPONSE_FORMAT — 응답 포맷
-- ============================================================================
INSERT INTO meta.std_code_group (system_prefix, system_name, logical_name, physical_name, code_id, code_desc, code_type, status)
VALUES ('SYS', '시스템공통', '응답포맷', 'RESPONSE_FORMAT_CD', 'SYS_RESPONSE_FORMAT', 'API 응답 데이터 포맷 코드', '시스템', 'active');

INSERT INTO meta.std_code (group_id, code_value, code_name, sort_order, description, status)
SELECT g.group_id, v.code_value, v.code_name, v.sort_order, v.description, 'active'
FROM meta.std_code_group g,
(VALUES
    ('json',     'JSON',      1, 'JavaScript Object Notation'),
    ('csv',      'CSV',       2, 'Comma Separated Values'),
    ('json_csv', 'JSON/CSV',  3, 'JSON 및 CSV 모두 지원'),
    ('parquet',  'Parquet',   4, 'Apache Parquet 컬럼 포맷'),
    ('excel',    '엑셀',      5, 'Excel 스프레드시트'),
    ('xml',      'XML',       6, 'Extensible Markup Language')
) AS v(code_value, code_name, sort_order, description)
WHERE g.code_id = 'SYS_RESPONSE_FORMAT';

-- ============================================================================
-- 7. SYS_API_TYPE — API 유형
-- ============================================================================
INSERT INTO meta.std_code_group (system_prefix, system_name, logical_name, physical_name, code_id, code_desc, code_type, status)
VALUES ('SYS', '시스템공통', 'API유형', 'API_TYPE_CD', 'SYS_API_TYPE', 'API 프로토콜 유형 코드', '시스템', 'active');

INSERT INTO meta.std_code (group_id, code_value, code_name, sort_order, description, status)
SELECT g.group_id, v.code_value, v.code_name, v.sort_order, v.description, 'active'
FROM meta.std_code_group g,
(VALUES
    ('rest',    'REST API',    1, 'RESTful API'),
    ('graphql', 'GraphQL',     2, 'GraphQL API'),
    ('kafka',   'Kafka Topic', 3, 'Apache Kafka 스트림'),
    ('grpc',    'gRPC',        4, 'gRPC 프로토콜')
) AS v(code_value, code_name, sort_order, description)
WHERE g.code_id = 'SYS_API_TYPE';

-- ============================================================================
-- 8. SYS_AUTH_METHOD — 인증 방식
-- ============================================================================
INSERT INTO meta.std_code_group (system_prefix, system_name, logical_name, physical_name, code_id, code_desc, code_type, status)
VALUES ('SYS', '시스템공통', '인증방식', 'AUTH_METHOD_CD', 'SYS_AUTH_METHOD', 'API 인증 방식 코드', '시스템', 'active');

INSERT INTO meta.std_code (group_id, code_value, code_name, sort_order, description, status)
SELECT g.group_id, v.code_value, v.code_name, v.sort_order, v.description, 'active'
FROM meta.std_code_group g,
(VALUES
    ('api_key', 'API Key',           1, 'API 키 인증'),
    ('oauth2',  'OAuth 2.0',         2, 'OAuth 2.0 인증'),
    ('jwt',     'JWT',               3, 'JSON Web Token 인증'),
    ('none',    '인증 없음 (공개)',   4, '인증 불필요')
) AS v(code_value, code_name, sort_order, description)
WHERE g.code_id = 'SYS_AUTH_METHOD';

-- ============================================================================
-- 확인 쿼리
-- ============================================================================
SELECT g.code_id, g.logical_name, COUNT(c.code_id) AS code_count
FROM meta.std_code_group g
LEFT JOIN meta.std_code c ON c.group_id = g.group_id AND c.status = 'active'
WHERE g.code_id LIKE 'SYS_%'
GROUP BY g.code_id, g.logical_name
ORDER BY g.code_id;
