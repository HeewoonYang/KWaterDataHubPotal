-- ============================================================================
-- DataHub Portal - PostgreSQL Database Schema
-- K-water (한국수자원공사) 데이터허브 통합 포털
-- Generated: 2026-03-03
-- ============================================================================
-- 도메인 구분:
--   1. 사용자·권한 (User & Auth)
--   2. 카탈로그·메타 (Catalog & Metadata)
--   3. 수집·정제 (Collection & Transformation)
--   4. 유통·활용 (Distribution & Utilization)
--   5. 모니터링 (Monitoring)
--   6. 커뮤니티 (Community)
--   7. 시스템관리 (System Administration)
-- ============================================================================

-- 스키마 생성
CREATE SCHEMA IF NOT EXISTS dh;
SET search_path TO dh, public;

-- 확장 모듈
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 0. 공통 ENUM 타입
-- ============================================================================

CREATE TYPE dh.data_security_level AS ENUM ('public','internal','restricted','confidential');
  -- public=공개(3등급), internal=내부일반(2등급), restricted=내부중요(1등급), confidential=기밀

CREATE TYPE dh.entity_status AS ENUM ('active','inactive','pending','locked','deprecated');

CREATE TYPE dh.approval_status AS ENUM ('pending','approved','rejected','revision_needed','cancelled');

CREATE TYPE dh.collect_method AS ENUM ('cdc','batch','api','file','streaming','migration');

CREATE TYPE dh.data_asset_type AS ENUM ('table','api','file','view','stream');


-- ============================================================================
-- 1. 사용자·권한 (User & Auth)
-- ============================================================================

-- 1-1. 본부 (Headquarters / Division)
CREATE TABLE dh.division (
    division_id     SERIAL PRIMARY KEY,
    division_name   VARCHAR(100) NOT NULL,
    division_code   VARCHAR(20)  NOT NULL UNIQUE,
    sort_order      INT DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.division IS '본부/권역 조직 (경영관리본부, 수자원관리본부 등)';

-- 1-2. 부서 (Department)
CREATE TABLE dh.department (
    dept_id         SERIAL PRIMARY KEY,
    division_id     INT REFERENCES dh.division(division_id),
    dept_name       VARCHAR(100) NOT NULL,
    dept_code       VARCHAR(20)  NOT NULL UNIQUE,
    headcount       INT DEFAULT 0,
    sort_order      INT DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.department IS '부서/팀 (수자원관리팀, 데이터분석팀 등)';

-- 1-3. 역할 (Role)
CREATE TABLE dh.role (
    role_id         SERIAL PRIMARY KEY,
    role_code       VARCHAR(30)  NOT NULL UNIQUE,   -- e.g. super, sysadmin, steward, kwater
    role_name       VARCHAR(100) NOT NULL,           -- 한글명
    role_level      SMALLINT NOT NULL DEFAULT 5,     -- 0=슈퍼관리자 ~ 6=외부사용자
    data_clearance  dh.data_security_level NOT NULL DEFAULT 'public',
    session_timeout_min INT DEFAULT 30,
    ip_range        VARCHAR(50),
    mfa_required    BOOLEAN DEFAULT FALSE,
    auto_lock_after INT DEFAULT 5,                   -- 실패 횟수
    pw_change_days  INT DEFAULT 90,
    description     TEXT,
    status          dh.entity_status DEFAULT 'active',
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.role IS '역할 정의 (RBAC 기반: 슈퍼관리자, 시스템관리자, 데이터스튜어드, 수공직원, 협력직원 등)';

-- 1-4. 사용자 (User)
CREATE TABLE dh.user_account (
    user_id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    login_id        VARCHAR(50)  NOT NULL UNIQUE,
    user_name       VARCHAR(100) NOT NULL,
    email           VARCHAR(200),
    phone           VARCHAR(20),
    dept_id         INT REFERENCES dh.department(dept_id),
    role_id         INT REFERENCES dh.role(role_id),
    login_type      VARCHAR(20)  NOT NULL DEFAULT 'sso',  -- sso, partner, engineer, admin
    status          dh.entity_status DEFAULT 'active',
    last_login_at   TIMESTAMPTZ,
    login_fail_count INT DEFAULT 0,
    pw_hash         TEXT,                              -- SSO 사용자는 NULL
    pw_changed_at   TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.user_account IS '사용자 계정 (SSO/협력직원/엔지니어/관리자)';
CREATE INDEX idx_user_dept   ON dh.user_account(dept_id);
CREATE INDEX idx_user_role   ON dh.user_account(role_id);
CREATE INDEX idx_user_status ON dh.user_account(status);

-- 1-5. 메뉴 (Screen/Menu)
CREATE TABLE dh.menu (
    menu_id         SERIAL PRIMARY KEY,
    menu_code       VARCHAR(50)  NOT NULL UNIQUE,    -- e.g. home, cat-search, col-pipeline
    menu_name       VARCHAR(100) NOT NULL,
    parent_code     VARCHAR(50),                     -- 상위 메뉴 코드
    section         VARCHAR(50),                     -- 통합대시보드, 카탈로그, 수집, 유통, 메타, 커뮤니티, 시스템
    icon            VARCHAR(10),
    sort_order      INT DEFAULT 0,
    description     TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.menu IS '메뉴/화면 정의 (사이드바 IA 구조)';

-- 1-6. 역할별 메뉴 권한 (Role-Menu Permission)
CREATE TABLE dh.role_menu_perm (
    role_id         INT NOT NULL REFERENCES dh.role(role_id),
    menu_id         INT NOT NULL REFERENCES dh.menu(menu_id),
    can_read        BOOLEAN DEFAULT TRUE,
    can_create      BOOLEAN DEFAULT FALSE,
    can_update      BOOLEAN DEFAULT FALSE,
    can_delete      BOOLEAN DEFAULT FALSE,
    can_approve     BOOLEAN DEFAULT FALSE,
    can_download    BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (role_id, menu_id)
);

COMMENT ON TABLE dh.role_menu_perm IS '역할별 메뉴 접근 권한 매트릭스 (RBAC)';


-- ============================================================================
-- 2. 카탈로그·메타 (Catalog & Metadata)
-- ============================================================================

-- 2-1. 도메인 (Business Domain)
CREATE TABLE dh.domain (
    domain_id       SERIAL PRIMARY KEY,
    domain_code     VARCHAR(20)  NOT NULL UNIQUE,    -- water, quality, energy, infra, customer
    domain_name     VARCHAR(100) NOT NULL,           -- 수자원, 수질, 에너지, 인프라, 고객
    description     TEXT,
    color           VARCHAR(7),                      -- hex color
    icon            VARCHAR(10),
    sort_order      INT DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.domain IS '비즈니스 도메인 (수자원/수질/에너지/인프라/고객)';

-- 2-2. 원천시스템 (Source System)
CREATE TABLE dh.source_system (
    system_id       SERIAL PRIMARY KEY,
    system_code     VARCHAR(30)  NOT NULL UNIQUE,    -- RWIS, SAP, HDAPS, SCADA, KMA_API 등
    system_name     VARCHAR(100) NOT NULL,
    system_type     VARCHAR(30),                     -- 내부시스템, 외부기관
    dbms_type       VARCHAR(30),                     -- SAP HANA, Oracle, PostgreSQL, 티베로
    protocol        VARCHAR(30),                     -- REST/HTTPS, SFTP/SSH, TCP/Custom, JDBC
    network_zone    VARCHAR(10),                     -- FA, OA, DMZ, IoT
    connection_info JSONB,                           -- 접속정보 (암호화 권장)
    status          dh.entity_status DEFAULT 'active',
    description     TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.source_system IS '원천/연계 시스템 (RWIS, SAP, SCADA, 기상청API 등)';

-- 2-3. 데이터셋 (Dataset / Data Asset)
CREATE TABLE dh.dataset (
    dataset_id      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_code    VARCHAR(30)  NOT NULL UNIQUE,    -- e.g. ds-001
    table_name      VARCHAR(100) NOT NULL,           -- e.g. TB_WATER_LEVEL
    dataset_name    VARCHAR(200) NOT NULL,           -- 한글명 e.g. 수위관측 데이터
    description     TEXT,
    domain_id       INT REFERENCES dh.domain(domain_id),
    system_id       INT REFERENCES dh.source_system(system_id),
    asset_type      dh.data_asset_type NOT NULL DEFAULT 'table',
    collect_method  dh.collect_method,
    security_level  dh.data_security_level NOT NULL DEFAULT 'public',
    quality_score   NUMERIC(5,2),                    -- 0.00 ~ 100.00
    row_count       BIGINT DEFAULT 0,
    column_count    INT DEFAULT 0,
    storage_size_mb NUMERIC(12,2),
    update_cycle    VARCHAR(30),                     -- 실시간, 1분, 5분, 1시간, 일배치 등
    last_collected  TIMESTAMPTZ,
    owner_dept_id   INT REFERENCES dh.department(dept_id),
    steward_user_id UUID REFERENCES dh.user_account(user_id),
    is_certified    BOOLEAN DEFAULT FALSE,
    is_popular      BOOLEAN DEFAULT FALSE,
    view_count      INT DEFAULT 0,
    download_count  INT DEFAULT 0,
    bookmark_count  INT DEFAULT 0,
    status          dh.entity_status DEFAULT 'active',
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.dataset IS '데이터 자산/데이터셋 카탈로그 (통합 검색 대상)';
CREATE INDEX idx_dataset_domain   ON dh.dataset(domain_id);
CREATE INDEX idx_dataset_system   ON dh.dataset(system_id);
CREATE INDEX idx_dataset_security ON dh.dataset(security_level);
CREATE INDEX idx_dataset_quality  ON dh.dataset(quality_score);

-- 2-4. 데이터셋 컬럼 (Dataset Column / Schema)
CREATE TABLE dh.dataset_column (
    column_id       SERIAL PRIMARY KEY,
    dataset_id      UUID NOT NULL REFERENCES dh.dataset(dataset_id) ON DELETE CASCADE,
    column_name     VARCHAR(100) NOT NULL,           -- 물리명
    column_name_ko  VARCHAR(200),                    -- 한글명
    data_type       VARCHAR(30)  NOT NULL,           -- STRING, FLOAT, INT, TIMESTAMP, ENUM 등
    is_pk           BOOLEAN DEFAULT FALSE,
    is_fk           BOOLEAN DEFAULT FALSE,
    is_not_null     BOOLEAN DEFAULT FALSE,
    std_term_id     INT,                             -- 표준용어 참조
    description     TEXT,
    sort_order      INT DEFAULT 0,
    null_rate       NUMERIC(5,2),                    -- 프로파일링: NULL 비율
    unique_rate     NUMERIC(5,2),                    -- 프로파일링: 유니크 비율
    min_value       VARCHAR(100),
    max_value       VARCHAR(100),
    avg_value       VARCHAR(100),
    sample_values   TEXT[],                          -- 샘플 값 배열
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.dataset_column IS '데이터셋 컬럼 스키마 및 프로파일링 정보';
CREATE INDEX idx_dscol_dataset ON dh.dataset_column(dataset_id);

-- 2-5. 태그 (Tag)
CREATE TABLE dh.tag (
    tag_id          SERIAL PRIMARY KEY,
    tag_name        VARCHAR(50) NOT NULL UNIQUE,
    tag_type        VARCHAR(20) DEFAULT 'keyword',   -- keyword, domain, business, security
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 2-6. 데이터셋-태그 관계 (Dataset ↔ Tag)
CREATE TABLE dh.dataset_tag (
    dataset_id      UUID NOT NULL REFERENCES dh.dataset(dataset_id) ON DELETE CASCADE,
    tag_id          INT  NOT NULL REFERENCES dh.tag(tag_id) ON DELETE CASCADE,
    PRIMARY KEY (dataset_id, tag_id)
);

-- 2-7. 즐겨찾기/보관함 (User Bookmark)
CREATE TABLE dh.bookmark (
    bookmark_id     SERIAL PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES dh.user_account(user_id),
    dataset_id      UUID NOT NULL REFERENCES dh.dataset(dataset_id),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, dataset_id)
);

COMMENT ON TABLE dh.bookmark IS '사용자 즐겨찾기/보관함';

-- 2-8. 표준용어 (Standard Glossary Term)
CREATE TABLE dh.glossary_term (
    term_id         SERIAL PRIMARY KEY,
    term_name       VARCHAR(200) NOT NULL,           -- 한글 표준용어명
    term_name_en    VARCHAR(200),                    -- 영문명 (CamelCase)
    abbreviation    VARCHAR(10),                     -- 약어
    domain_id       INT REFERENCES dh.domain(domain_id),
    data_type       VARCHAR(30),                     -- NUMBER, VARCHAR, DATE, TIMESTAMP 등
    length_precision VARCHAR(20),                    -- e.g. "10,2"
    unit            VARCHAR(20),                     -- m, m3/s, mg/L, NTU, MWh, 도 등
    valid_range_min NUMERIC,
    valid_range_max NUMERIC,
    definition      TEXT NOT NULL,
    synonyms        TEXT,                            -- 쉼표 구분 유사어
    used_systems    TEXT,                            -- 사용 시스템 목록
    owner_name      VARCHAR(100),
    status          dh.approval_status DEFAULT 'pending',
    created_by      UUID REFERENCES dh.user_account(user_id),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.glossary_term IS '표준용어사전 (표준 컬럼명, 타입, 단위 등)';
CREATE INDEX idx_glossary_domain ON dh.glossary_term(domain_id);
CREATE INDEX idx_glossary_status ON dh.glossary_term(status);

-- 2-9. 용어 변경이력 (Glossary Change History)
CREATE TABLE dh.glossary_history (
    history_id      SERIAL PRIMARY KEY,
    term_id         INT NOT NULL REFERENCES dh.glossary_term(term_id),
    change_desc     TEXT NOT NULL,
    changed_by      UUID REFERENCES dh.user_account(user_id),
    prev_status     dh.approval_status,
    new_status      dh.approval_status,
    changed_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 2-10. 공통코드 그룹 (Code Group)
CREATE TABLE dh.code_group (
    group_id        SERIAL PRIMARY KEY,
    group_code      VARCHAR(30)  NOT NULL UNIQUE,    -- e.g. CD_REGION
    group_name      VARCHAR(100) NOT NULL,
    description     TEXT,
    owner_name      VARCHAR(100),
    status          dh.entity_status DEFAULT 'active',
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.code_group IS '공통코드 그룹 (CD_REGION, CD_DATA_TYPE 등)';

-- 2-11. 공통코드 (Code)
CREATE TABLE dh.code (
    code_id         SERIAL PRIMARY KEY,
    group_id        INT NOT NULL REFERENCES dh.code_group(group_id) ON DELETE CASCADE,
    code_value      VARCHAR(50)  NOT NULL,
    code_name       VARCHAR(100) NOT NULL,
    description     TEXT,
    sort_order      INT DEFAULT 0,
    status          dh.entity_status DEFAULT 'active',
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (group_id, code_value)
);

COMMENT ON TABLE dh.code IS '공통코드 값 (RGN_HQ=본사, RGN_SEL=수도권 등)';

-- 2-12. 데이터모델 (Logical/Physical Model)
CREATE TABLE dh.data_model (
    model_id        SERIAL PRIMARY KEY,
    model_name      VARCHAR(200) NOT NULL,
    model_type      VARCHAR(20)  NOT NULL,           -- logical, physical
    domain_id       INT REFERENCES dh.domain(domain_id),
    table_count     INT DEFAULT 0,
    column_count    INT DEFAULT 0,
    version         VARCHAR(20) DEFAULT '1.0',
    naming_compliance   NUMERIC(5,2),                -- 명명규칙 준수율
    type_consistency    NUMERIC(5,2),                -- 타입 일관성
    ref_integrity       NUMERIC(5,2),                -- 참조무결성
    index_coverage      NUMERIC(5,2),                -- 인덱스 커버리지
    status          dh.approval_status DEFAULT 'pending',
    owner_user_id   UUID REFERENCES dh.user_account(user_id),
    description     TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.data_model IS '데이터 모델 (논리모델/물리모델)';

-- 2-13. 데이터모델 테이블 (Model Entity)
CREATE TABLE dh.model_entity (
    entity_id       SERIAL PRIMARY KEY,
    model_id        INT NOT NULL REFERENCES dh.data_model(model_id) ON DELETE CASCADE,
    entity_name     VARCHAR(100) NOT NULL,           -- 테이블/엔티티명
    entity_name_ko  VARCHAR(200),
    description     TEXT,
    sort_order      INT DEFAULT 0
);

-- 2-14. 데이터모델 컬럼 (Model Attribute)
CREATE TABLE dh.model_attribute (
    attribute_id    SERIAL PRIMARY KEY,
    entity_id       INT NOT NULL REFERENCES dh.model_entity(entity_id) ON DELETE CASCADE,
    attr_name       VARCHAR(100) NOT NULL,
    attr_name_ko    VARCHAR(200),
    data_type       VARCHAR(50)  NOT NULL,           -- INT, VARCHAR(50), DECIMAL(12,2) 등
    is_pk           BOOLEAN DEFAULT FALSE,
    is_fk           BOOLEAN DEFAULT FALSE,
    fk_ref_entity   VARCHAR(100),                    -- FK 참조 대상 엔티티
    fk_ref_attr     VARCHAR(100),                    -- FK 참조 대상 속성
    is_not_null     BOOLEAN DEFAULT FALSE,
    sort_order      INT DEFAULT 0
);


-- ============================================================================
-- 3. 온톨로지 (Ontology / Knowledge Graph)
-- ============================================================================

-- 3-1. 온톨로지 클래스 (Ontology Class)
CREATE TABLE dh.onto_class (
    class_id        SERIAL PRIMARY KEY,
    class_name_ko   VARCHAR(100) NOT NULL,           -- 한글명 (댐, 정수장 등)
    class_name_en   VARCHAR(100) NOT NULL,           -- 영문명 (Dam, WaterTreatmentPlant)
    class_uri       VARCHAR(200) NOT NULL UNIQUE,    -- kw:Dam
    parent_class_id INT REFERENCES dh.onto_class(class_id),
    instance_count  BIGINT DEFAULT 0,
    description     TEXT,
    status          dh.entity_status DEFAULT 'active',
    created_by      UUID REFERENCES dh.user_account(user_id),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.onto_class IS '온톨로지 클래스 (kw:Thing 트리 구조)';

-- 3-2. 온톨로지 데이터 속성 (Data Property)
CREATE TABLE dh.onto_data_property (
    property_id     SERIAL PRIMARY KEY,
    class_id        INT NOT NULL REFERENCES dh.onto_class(class_id) ON DELETE CASCADE,
    property_name   VARCHAR(100) NOT NULL,
    property_uri    VARCHAR(200) NOT NULL,
    data_type       VARCHAR(30)  NOT NULL,           -- xsd:string, xsd:float 등
    cardinality     VARCHAR(10) DEFAULT '0..1',      -- 0..1, 1..1, 0..*, 1..*
    std_term_id     INT REFERENCES dh.glossary_term(term_id),
    description     TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 3-3. 온톨로지 관계 속성 (Object Property / Relationship)
CREATE TABLE dh.onto_relationship (
    rel_id          SERIAL PRIMARY KEY,
    source_class_id INT NOT NULL REFERENCES dh.onto_class(class_id),
    target_class_id INT NOT NULL REFERENCES dh.onto_class(class_id),
    rel_name_ko     VARCHAR(100) NOT NULL,
    rel_uri         VARCHAR(200) NOT NULL,
    inverse_uri     VARCHAR(200),
    cardinality     VARCHAR(10) DEFAULT '0..*',
    direction       VARCHAR(10) DEFAULT 'output',    -- output(→), input(←)
    description     TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.onto_relationship IS '온톨로지 클래스간 관계 (hasDownstreamIntake 등)';


-- ============================================================================
-- 4. 수집·정제 (Collection & Transformation)
-- ============================================================================

-- 4-1. 파이프라인 (Pipeline)
CREATE TABLE dh.pipeline (
    pipeline_id     SERIAL PRIMARY KEY,
    pipeline_name   VARCHAR(200) NOT NULL,
    system_id       INT REFERENCES dh.source_system(system_id),
    collect_method  dh.collect_method NOT NULL,
    schedule        VARCHAR(100),                    -- cron 표현식 또는 '상시'
    target_storage  VARCHAR(200),                    -- 타겟 저장소
    target_tables   TEXT[],                          -- 대상 테이블 목록
    throughput      VARCHAR(50),                     -- e.g. '48.2K/일', '12K/분'
    owner_user_id   UUID REFERENCES dh.user_account(user_id),
    description     TEXT,
    status          VARCHAR(20) DEFAULT 'normal',    -- normal, delayed, error, stopped
    last_run_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.pipeline IS '수집 파이프라인 (ETL/CDC/API/Streaming)';

-- 4-2. 파이프라인 실행이력 (Pipeline Execution Log)
CREATE TABLE dh.pipeline_execution (
    execution_id    BIGSERIAL PRIMARY KEY,
    pipeline_id     INT NOT NULL REFERENCES dh.pipeline(pipeline_id),
    started_at      TIMESTAMPTZ NOT NULL,
    finished_at     TIMESTAMPTZ,
    duration_sec    NUMERIC(10,2),
    records_count   BIGINT DEFAULT 0,
    success_rate    NUMERIC(5,2),
    status          VARCHAR(20) NOT NULL,            -- success, warning, failed
    error_message   TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_pipeline_exec ON dh.pipeline_execution(pipeline_id, started_at DESC);

-- 4-3. 컬럼 매핑 (Pipeline Column Mapping)
CREATE TABLE dh.pipeline_column_mapping (
    mapping_id      SERIAL PRIMARY KEY,
    pipeline_id     INT NOT NULL REFERENCES dh.pipeline(pipeline_id) ON DELETE CASCADE,
    source_column   VARCHAR(100) NOT NULL,
    target_column   VARCHAR(100) NOT NULL,
    transform_rule  TEXT,                            -- trim + uppercase, ISO8601→TIMESTAMP 등
    is_required     BOOLEAN DEFAULT FALSE,
    sort_order      INT DEFAULT 0
);

-- 4-4. CDC 연계현황 (CDC Synchronization)
CREATE TABLE dh.cdc_connector (
    connector_id    SERIAL PRIMARY KEY,
    system_id       INT REFERENCES dh.source_system(system_id),
    connector_name  VARCHAR(100) NOT NULL,           -- e.g. cdc-sap-asset
    dbms_type       VARCHAR(30),                     -- SAP HANA, ORACLE, 티베로
    table_count     INT DEFAULT 0,
    schema_count    INT DEFAULT 0,
    events_per_min  INT DEFAULT 0,
    lag_seconds     NUMERIC(6,2) DEFAULT 0,
    today_count     BIGINT DEFAULT 0,
    status          VARCHAR(20) DEFAULT 'normal',    -- normal, delayed, error
    last_sync_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.cdc_connector IS 'CDC 커넥터 현황 (Debezium, Oracle GoldenGate)';

-- 4-5. Kafka 토픽 (Kafka Topic)
CREATE TABLE dh.kafka_topic (
    topic_id        SERIAL PRIMARY KEY,
    topic_name      VARCHAR(200) NOT NULL UNIQUE,
    partitions      INT NOT NULL DEFAULT 1,
    replication     INT NOT NULL DEFAULT 3,
    in_rate         NUMERIC(10,1),                   -- messages/sec
    out_rate        NUMERIC(10,1),
    lag             BIGINT DEFAULT 0,
    retention       VARCHAR(30),                     -- e.g. '7d', '30d'
    status          VARCHAR(20) DEFAULT 'normal',    -- normal, warning, inactive
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.kafka_topic IS 'Kafka 토픽 관리 (스트리밍 데이터)';

-- 4-6. 외부연계 (External Integration)
CREATE TABLE dh.external_integration (
    integration_id  SERIAL PRIMARY KEY,
    system_name     VARCHAR(200) NOT NULL,
    organization    VARCHAR(100),                    -- 연계기관
    method          VARCHAR(30),                     -- REST API, SFTP, DB Link, 양방향전송
    protocol        VARCHAR(30),                     -- REST/HTTPS, SFTP/SSH, TCP/Custom
    cycle           VARCHAR(30),                     -- 1시간, 3시간, 6시간, 실시간
    response_time_ms INT,
    today_count     BIGINT DEFAULT 0,
    success_rate    NUMERIC(5,2),
    status          VARCHAR(20) DEFAULT 'normal',
    last_sync_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.external_integration IS '외부기관 연계 (기상청, 환경부 등)';

-- 4-7. dbt 모델 (dbt Transformation Model)
CREATE TABLE dh.dbt_model (
    dbt_model_id    SERIAL PRIMARY KEY,
    model_name      VARCHAR(200) NOT NULL,
    layer           VARCHAR(30)  NOT NULL,           -- staging, intermediate, mart
    source_name     VARCHAR(200),                    -- 소스 참조
    transform_rule  TEXT,                            -- 정제·변환 규칙
    execution_time_sec NUMERIC(8,2),
    status          VARCHAR(20) DEFAULT 'success',   -- success, warning, failed
    error_message   TEXT,
    last_run_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.dbt_model IS 'dbt 변환 모델 (staging → intermediate → mart)';

-- 4-8. 서버 인프라 (Server Inventory)
CREATE TABLE dh.server_inventory (
    server_id       SERIAL PRIMARY KEY,
    server_name     VARCHAR(100) NOT NULL,
    layer           VARCHAR(50),                     -- 수집계, 분석계, 온톨로지, 연계, 서비스, 카프카
    server_type     VARCHAR(10),                     -- VM, PM, GM(GPU)
    instance_count  INT DEFAULT 1,
    cpu_spec        VARCHAR(100),
    memory_spec     VARCHAR(100),
    disk_spec       VARCHAR(200),
    gpu_spec        VARCHAR(100),
    status          VARCHAR(20) DEFAULT 'normal',    -- normal, maintenance, stopped
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);


-- ============================================================================
-- 5. 유통·활용 (Distribution & Utilization)
-- ============================================================================

-- 5-1. Data Product (데이터 상품)
CREATE TABLE dh.data_product (
    product_id      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_name    VARCHAR(200) NOT NULL,
    domain_id       INT REFERENCES dh.domain(domain_id),
    format          VARCHAR(20),                     -- JSON, CSV, Parquet, Excel
    security_level  dh.data_security_level NOT NULL DEFAULT 'public',
    dist_status     VARCHAR(20) DEFAULT 'preparing', -- active, preparing, restricted, paused, deprecated
    api_type        VARCHAR(30),                     -- REST API, GraphQL, Kafka, gRPC, MCP, NGSI-LD
    refresh_cycle   VARCHAR(30),                     -- 실시간, 5분, 30분, 1시간, 일배치, 수동
    endpoint_path   VARCHAR(500),
    auth_method     VARCHAR(30),                     -- Bearer Token, API Key, OAuth 2.0, JWT
    rate_limit      VARCHAR(30),                     -- e.g. '100 req/min'
    daily_calls     BIGINT DEFAULT 0,
    monthly_calls   BIGINT DEFAULT 0,
    active_users    INT DEFAULT 0,
    avg_latency_ms  INT,
    uptime_pct      NUMERIC(5,2),
    source_datasets UUID[],                          -- 소스 데이터셋 ID 배열
    access_scope    VARCHAR(30) DEFAULT 'all',       -- all, dept_limited, approval_required, internal
    allowed_depts   TEXT,
    log_policy      JSONB,                           -- {queryLog:true, downloadLog:true, statsLog:true}
    owner_user_id   UUID REFERENCES dh.user_account(user_id),
    description     TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.data_product IS '유통 Data Product (API/파일/스트림)';
CREATE INDEX idx_product_domain ON dh.data_product(domain_id);
CREATE INDEX idx_product_status ON dh.data_product(dist_status);

-- 5-2. Data Product 소스 데이터 (Product Source)
CREATE TABLE dh.product_source (
    source_id       SERIAL PRIMARY KEY,
    product_id      UUID NOT NULL REFERENCES dh.data_product(product_id) ON DELETE CASCADE,
    source_type     VARCHAR(20),                     -- Kafka, DB, API, File
    source_ref      VARCHAR(200),                    -- topic name / table name
    schema_type     VARCHAR(30),                     -- AVRO, PostgreSQL, JSON
    description     TEXT
);

-- 5-3. Data Product 응답 필드 (Product Response Field)
CREATE TABLE dh.product_field (
    field_id        SERIAL PRIMARY KEY,
    product_id      UUID NOT NULL REFERENCES dh.data_product(product_id) ON DELETE CASCADE,
    field_name      VARCHAR(100) NOT NULL,
    data_type       VARCHAR(30)  NOT NULL,
    is_required     BOOLEAN DEFAULT FALSE,
    description     TEXT,
    sort_order      INT DEFAULT 0
);

-- 5-4. API Key 발급 (API Key Management)
CREATE TABLE dh.api_key (
    key_id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id      UUID NOT NULL REFERENCES dh.data_product(product_id),
    user_id         UUID NOT NULL REFERENCES dh.user_account(user_id),
    api_key         VARCHAR(100) NOT NULL UNIQUE,
    api_secret_hash TEXT NOT NULL,                   -- 해싱된 시크릿
    permission      VARCHAR(10) DEFAULT 'READ',      -- READ, WRITE, ADMIN
    rate_limit      INT,                             -- req/min
    issued_at       TIMESTAMPTZ DEFAULT NOW(),
    expires_at      TIMESTAMPTZ,
    is_active       BOOLEAN DEFAULT TRUE
);

COMMENT ON TABLE dh.api_key IS 'API Key 발급 및 관리';

-- 5-5. 비식별화 정책 (De-identification Policy)
CREATE TABLE dh.deidentify_policy (
    policy_id       VARCHAR(20)  PRIMARY KEY,        -- e.g. DI-POL-001
    policy_name     VARCHAR(200) NOT NULL,
    technique       VARCHAR(30)  NOT NULL,           -- masking, sha256, aes256, generalization, pseudonym, k_anonymity
    apply_level     dh.data_security_level,
    target_table    VARCHAR(100),
    processed_count BIGINT DEFAULT 0,
    success_rate    NUMERIC(5,2),
    owner_user_id   UUID REFERENCES dh.user_account(user_id),
    status          VARCHAR(20) DEFAULT 'active',    -- active, paused, disabled
    description     TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.deidentify_policy IS '비식별화/가명처리 정책';

-- 5-6. 비식별화 규칙 (De-identification Rule - field-level)
CREATE TABLE dh.deidentify_rule (
    rule_id         SERIAL PRIMARY KEY,
    policy_id       VARCHAR(20) NOT NULL REFERENCES dh.deidentify_policy(policy_id) ON DELETE CASCADE,
    target_field    VARCHAR(100) NOT NULL,
    field_type      VARCHAR(30),                     -- VARCHAR(50), VARCHAR(20), VARCHAR(200) 등
    masking_pattern TEXT NOT NULL,                    -- 부분마스킹, 중간마스킹, 일반화 등
    example_before  VARCHAR(200),
    example_after   VARCHAR(200),
    sort_order      INT DEFAULT 0
);

-- 5-7. 데이터 신청·승인 (Data Request & Approval)
CREATE TABLE dh.data_request (
    request_id      VARCHAR(20) PRIMARY KEY,          -- e.g. WF-089, AP-056, REQ-042
    request_type    VARCHAR(30) NOT NULL,             -- usage, permission, quality_report, meta_edit, api, download, kafka
    title           VARCHAR(300) NOT NULL,
    description     TEXT,
    target_dataset_id UUID REFERENCES dh.dataset(dataset_id),
    target_data_name VARCHAR(200),
    security_level  dh.data_security_level,
    priority        VARCHAR(10) DEFAULT 'normal',     -- normal, high, low
    usage_type      VARCHAR(30),                      -- 분석리포트, 시스템연계, AI/ML, 연구학술, 업무자동화
    delivery_method VARCHAR(30),                      -- API, file_download, db_readonly, streaming, sandbox
    usage_start_dt  DATE,
    usage_end_dt    DATE,
    requester_id    UUID NOT NULL REFERENCES dh.user_account(user_id),
    handler_id      UUID REFERENCES dh.user_account(user_id),
    current_step    SMALLINT DEFAULT 1,               -- 1~6단계
    status          dh.approval_status DEFAULT 'pending',
    reject_reason   TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.data_request IS '데이터 활용 신청/승인 (6단계 워크플로우)';
CREATE INDEX idx_request_requester ON dh.data_request(requester_id);
CREATE INDEX idx_request_status    ON dh.data_request(status);
CREATE INDEX idx_request_type      ON dh.data_request(request_type);

-- 5-8. 신청 첨부파일 (Request Attachment)
CREATE TABLE dh.request_attachment (
    attachment_id   SERIAL PRIMARY KEY,
    request_id      VARCHAR(20) NOT NULL REFERENCES dh.data_request(request_id) ON DELETE CASCADE,
    file_name       VARCHAR(300) NOT NULL,
    file_type       VARCHAR(20),                     -- PDF, DOCX, XLSX, HWP
    file_size_bytes BIGINT,
    file_path       TEXT NOT NULL,
    uploaded_at     TIMESTAMPTZ DEFAULT NOW()
);

-- 5-9. 신청 처리이력 (Request Timeline)
CREATE TABLE dh.request_timeline (
    timeline_id     SERIAL PRIMARY KEY,
    request_id      VARCHAR(20) NOT NULL REFERENCES dh.data_request(request_id) ON DELETE CASCADE,
    step            SMALLINT NOT NULL,                -- 1~6
    step_name       VARCHAR(50) NOT NULL,
    action_desc     TEXT,
    actor_id        UUID REFERENCES dh.user_account(user_id),
    actor_name      VARCHAR(100),
    status          VARCHAR(30),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 5-10. 시각화 차트 콘텐츠 (Chart Content)
CREATE TABLE dh.chart_content (
    chart_id        VARCHAR(20) PRIMARY KEY,          -- e.g. CHT-001
    chart_name      VARCHAR(200) NOT NULL,
    domain_id       INT REFERENCES dh.domain(domain_id),
    chart_type      VARCHAR(30),                      -- line, bar, area, pie, gauge, heatmap, donut, table
    data_level      dh.data_security_level DEFAULT 'public',
    visibility      VARCHAR(30) DEFAULT 'public',     -- public, internal, confidential
    description     TEXT,
    config_json     JSONB,                            -- 차트 설정 JSON
    author_id       UUID REFERENCES dh.user_account(user_id),
    like_count      INT DEFAULT 0,
    is_recommended  BOOLEAN DEFAULT FALSE,
    is_popular      BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.chart_content IS '시각화 차트 콘텐츠 관리';

-- 5-11. 외부 시스템 데이터 제공 (External Data Provision / Digital Twin)
CREATE TABLE dh.external_provision (
    provision_id    SERIAL PRIMARY KEY,
    target_name     VARCHAR(200) NOT NULL,            -- e.g. 정수장 디지털트윈
    provided_data   TEXT,                             -- 제공 데이터 항목
    api_method      VARCHAR(30),                      -- REST, Kafka, REST+Kafka
    daily_calls     BIGINT DEFAULT 0,
    sla_pct         NUMERIC(5,2),
    status          VARCHAR(20) DEFAULT 'normal',
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);


-- ============================================================================
-- 6. 데이터 품질 (Data Quality)
-- ============================================================================

-- 6-1. DQ 규칙 (Data Quality Rule)
CREATE TABLE dh.dq_rule (
    rule_id         SERIAL PRIMARY KEY,
    rule_name       VARCHAR(200) NOT NULL,
    dataset_id      UUID REFERENCES dh.dataset(dataset_id),
    dimension       VARCHAR(20) NOT NULL,             -- completeness, validity, consistency, timeliness, uniqueness
    rule_expression TEXT,                              -- SQL 또는 규칙 표현식
    threshold       NUMERIC(5,2),                     -- 임계값 (%)
    severity        VARCHAR(10) DEFAULT 'medium',     -- critical, high, medium, low
    is_active       BOOLEAN DEFAULT TRUE,
    created_by      UUID REFERENCES dh.user_account(user_id),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.dq_rule IS 'DQ 검증 규칙 (완전성/유효성/정합성/적시성/유일성)';

-- 6-2. DQ 실행 결과 (DQ Execution Result)
CREATE TABLE dh.dq_execution (
    execution_id    BIGSERIAL PRIMARY KEY,
    rule_id         INT NOT NULL REFERENCES dh.dq_rule(rule_id),
    dataset_id      UUID REFERENCES dh.dataset(dataset_id),
    executed_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    total_rows      BIGINT,
    passed_rows     BIGINT,
    failed_rows     BIGINT,
    pass_rate       NUMERIC(5,2),
    status          VARCHAR(20) NOT NULL,             -- passed, warning, failed
    violation_detail JSONB,                           -- 위반 상세 정보
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_dq_exec_rule    ON dh.dq_execution(rule_id, executed_at DESC);
CREATE INDEX idx_dq_exec_dataset ON dh.dq_execution(dataset_id);

-- 6-3. 도메인별 품질 점수 (Domain Quality Score)
CREATE TABLE dh.domain_quality_score (
    score_id        SERIAL PRIMARY KEY,
    domain_id       INT NOT NULL REFERENCES dh.domain(domain_id),
    score_date      DATE NOT NULL,
    completeness    NUMERIC(5,2),
    validity        NUMERIC(5,2),
    consistency     NUMERIC(5,2),
    timeliness      NUMERIC(5,2),
    accuracy        NUMERIC(5,2),
    uniqueness      NUMERIC(5,2),
    overall_dqi     NUMERIC(5,2),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (domain_id, score_date)
);

COMMENT ON TABLE dh.domain_quality_score IS '도메인별 6대 품질지표 일별 점수';

-- 6-4. 품질 이슈 (Quality Issue)
CREATE TABLE dh.quality_issue (
    issue_id        SERIAL PRIMARY KEY,
    dataset_id      UUID REFERENCES dh.dataset(dataset_id),
    dimension       VARCHAR(20) NOT NULL,
    error_type      TEXT NOT NULL,                    -- 중복 레코드, FK 참조 무결성 위반 등
    violation_count INT,
    sla_status      VARCHAR(20),                     -- on_track, delayed, resolved
    assignee_id     UUID REFERENCES dh.user_account(user_id),
    occurred_at     TIMESTAMPTZ DEFAULT NOW(),
    resolved_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);


-- ============================================================================
-- 7. 모니터링 (Monitoring - 계측/자산DB)
-- ============================================================================

-- 7-1. 유역/지사 (Region / Basin Branch)
CREATE TABLE dh.region (
    region_id       SERIAL PRIMARY KEY,
    region_name     VARCHAR(100) NOT NULL,
    region_code     VARCHAR(20)  NOT NULL UNIQUE,
    office_count    INT DEFAULT 0,
    site_count      INT DEFAULT 0,
    tag_count       INT DEFAULT 0,
    collect_rate    NUMERIC(5,2),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.region IS '유역/지사 (충청지역지사, 한강권역본부 등)';

-- 7-2. 사무소 (Office)
CREATE TABLE dh.office (
    office_id       SERIAL PRIMARY KEY,
    region_id       INT NOT NULL REFERENCES dh.region(region_id),
    office_name     VARCHAR(100) NOT NULL,
    site_count      INT DEFAULT 0,
    tag_count       INT DEFAULT 0,
    total_records   BIGINT DEFAULT 0,
    data_start_dt   DATE,
    data_end_dt     DATE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.office IS '사무소/관리단 (과천관리단 등)';

-- 7-3. 사업장 (Site)
CREATE TABLE dh.site (
    site_id         SERIAL PRIMARY KEY,
    office_id       INT NOT NULL REFERENCES dh.office(office_id),
    site_name       VARCHAR(100) NOT NULL,
    site_code       VARCHAR(30),
    site_type       VARCHAR(30),                     -- 정수장, 가압장, 댐, 보 등
    tag_count       INT DEFAULT 0,
    collect_tags    INT DEFAULT 0,
    uncollect_tags  INT DEFAULT 0,
    collect_rate    NUMERIC(5,2),
    data_count      BIGINT DEFAULT 0,
    status          VARCHAR(20) DEFAULT 'normal',
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.site IS '사업장 (정수장, 가압장, 관측소 등)';

-- 7-4. 계측 태그 (Sensor Tag)
CREATE TABLE dh.sensor_tag (
    tag_id          SERIAL PRIMARY KEY,
    site_id         INT NOT NULL REFERENCES dh.site(site_id),
    tag_name        VARCHAR(100) NOT NULL,
    tag_code        VARCHAR(50),
    tag_type        VARCHAR(30),                     -- 수위, 유량, 수질, 압력, 온도 등
    category        VARCHAR(50),
    supplier        VARCHAR(100),
    unit            VARCHAR(20),
    section         VARCHAR(50),
    description     TEXT,
    is_collecting   BOOLEAN DEFAULT TRUE,
    data_count      BIGINT DEFAULT 0,
    validity_rate   NUMERIC(5,2),
    status          VARCHAR(20) DEFAULT 'normal',    -- normal, warning, error
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.sensor_tag IS '계측 센서 태그 (SCADA/IoT 계측점)';
CREATE INDEX idx_tag_site ON dh.sensor_tag(site_id);

-- 7-5. 자산DB (Asset Database)
CREATE TABLE dh.asset_database (
    asset_db_id     SERIAL PRIMARY KEY,
    db_name         VARCHAR(100) NOT NULL,
    db_system       VARCHAR(50),                     -- SAP ECC, SAP PM, Oracle 19c 등
    cdc_method      VARCHAR(50),                     -- CDC(Debezium), Oracle GoldenGate, REST API
    table_count     INT DEFAULT 0,
    endpoint_count  INT DEFAULT 0,                   -- API 엔드포인트 수
    daily_collect   BIGINT DEFAULT 0,
    cdc_lag_sec     NUMERIC(6,2),
    cdc_sync_pct    NUMERIC(5,2),
    storage_used_tb NUMERIC(6,2),
    storage_alloc_tb NUMERIC(6,2),
    status          VARCHAR(20) DEFAULT 'normal',    -- normal, delayed, error
    last_sync_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.asset_database IS '자산DB 모니터링 (자산DB, 시설DB, 수질DB 등)';


-- ============================================================================
-- 8. 커뮤니티 (Community)
-- ============================================================================

-- 8-1. 게시판 (Board Post) - 공지/내부/외부 통합
CREATE TABLE dh.board_post (
    post_id         SERIAL PRIMARY KEY,
    board_type      VARCHAR(20) NOT NULL,            -- notice, internal, external
    category        VARCHAR(50),                     -- 시스템안내, 데이터정책, 기술Q&A, API문의 등
    title           VARCHAR(300) NOT NULL,
    content         TEXT,
    author_id       UUID NOT NULL REFERENCES dh.user_account(user_id),
    author_org      VARCHAR(100),                    -- 외부게시판: 소속기관
    is_pinned       BOOLEAN DEFAULT FALSE,
    is_urgent       BOOLEAN DEFAULT FALSE,
    view_count      INT DEFAULT 0,
    comment_count   INT DEFAULT 0,
    status          VARCHAR(20) DEFAULT 'active',    -- active, answered, closed, deleted
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.board_post IS '게시판 (공지사항/내부게시판/외부게시판)';
CREATE INDEX idx_post_board  ON dh.board_post(board_type, created_at DESC);
CREATE INDEX idx_post_author ON dh.board_post(author_id);

-- 8-2. 게시판 댓글 (Board Comment)
CREATE TABLE dh.board_comment (
    comment_id      SERIAL PRIMARY KEY,
    post_id         INT NOT NULL REFERENCES dh.board_post(post_id) ON DELETE CASCADE,
    parent_comment_id INT REFERENCES dh.board_comment(comment_id),
    content         TEXT NOT NULL,
    author_id       UUID NOT NULL REFERENCES dh.user_account(user_id),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 8-3. 자료실 (Resource Archive)
CREATE TABLE dh.resource_archive (
    resource_id     SERIAL PRIMARY KEY,
    category        VARCHAR(50),                     -- 가이드매뉴얼, 교육자료, 정책규정, 양식서식, 기술문서
    title           VARCHAR(300) NOT NULL,
    description     TEXT,
    file_name       VARCHAR(300) NOT NULL,
    file_type       VARCHAR(20),                     -- PDF, XLSX, HWP, DOCX, PPTX
    file_size_bytes BIGINT,
    file_path       TEXT NOT NULL,
    author_id       UUID NOT NULL REFERENCES dh.user_account(user_id),
    download_count  INT DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.resource_archive IS '자료실 (가이드, 교육자료, 양식 등)';


-- ============================================================================
-- 9. 시스템 관리 (System Administration)
-- ============================================================================

-- 9-1. 보안정책 (Security Policy)
CREATE TABLE dh.security_policy (
    policy_id       SERIAL PRIMARY KEY,
    policy_name     VARCHAR(200) NOT NULL,
    data_level      dh.data_security_level NOT NULL,
    asset_type      dh.data_asset_type,
    rule_expression TEXT,                            -- 정책 규칙
    is_active       BOOLEAN DEFAULT TRUE,
    created_by      UUID REFERENCES dh.user_account(user_id),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.security_policy IS '데이터등급 보안정책 규칙';

-- 9-2. 연계 인터페이스 (System Interface)
CREATE TABLE dh.system_interface (
    interface_id    SERIAL PRIMARY KEY,
    interface_name  VARCHAR(200) NOT NULL,
    system_id       INT REFERENCES dh.source_system(system_id),
    direction       VARCHAR(10),                     -- inbound, outbound, bidirectional
    protocol        VARCHAR(30),
    endpoint_url    VARCHAR(500),
    avg_response_ms INT,
    success_rate    NUMERIC(5,2),
    daily_calls     BIGINT DEFAULT 0,
    error_rate      NUMERIC(5,2),
    status          VARCHAR(20) DEFAULT 'normal',
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.system_interface IS '연계 인터페이스 모니터링';

-- 9-3. 감사 로그 (Audit Log)
CREATE TABLE dh.audit_log (
    log_id          BIGSERIAL PRIMARY KEY,
    user_id         UUID REFERENCES dh.user_account(user_id),
    user_name       VARCHAR(100),
    action_type     VARCHAR(30) NOT NULL,            -- data, collect, distribute, access, system, permission, batch
    action_detail   TEXT,
    target_entity   VARCHAR(100),                    -- 대상 테이블/화면/API
    target_id       VARCHAR(100),
    ip_address      VARCHAR(45),
    risk_level      VARCHAR(10) DEFAULT 'low',       -- high, medium, low
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.audit_log IS '접속통계 및 감사로그 (전 활동 기록)';
CREATE INDEX idx_audit_user    ON dh.audit_log(user_id, created_at DESC);
CREATE INDEX idx_audit_action  ON dh.audit_log(action_type);
CREATE INDEX idx_audit_created ON dh.audit_log(created_at DESC);

-- 9-4. 알림 (Notification)
CREATE TABLE dh.notification (
    noti_id         BIGSERIAL PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES dh.user_account(user_id),
    noti_type       VARCHAR(30) NOT NULL,            -- approval, quality, pipeline, system, request
    title           VARCHAR(200) NOT NULL,
    message         TEXT,
    icon            VARCHAR(10),
    is_read         BOOLEAN DEFAULT FALSE,
    related_entity  VARCHAR(50),                     -- 관련 엔티티 타입
    related_id      VARCHAR(50),                     -- 관련 엔티티 ID
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.notification IS '사용자 알림 (승인요청, 품질이슈, 파이프라인 등)';
CREATE INDEX idx_noti_user ON dh.notification(user_id, is_read, created_at DESC);

-- 9-5. 위젯 템플릿 (Widget Template)
CREATE TABLE dh.widget_template (
    widget_id       VARCHAR(30) PRIMARY KEY,          -- e.g. w-kpi-quality
    widget_name     VARCHAR(100) NOT NULL,
    icon            VARCHAR(10),
    category        VARCHAR(20) NOT NULL,             -- kpi, card, list, chart
    description     TEXT,
    color           VARCHAR(7),
    data_level      dh.data_security_level DEFAULT 'public',
    allowed_roles   TEXT[],                           -- 접근 가능 역할 배열
    config_json     JSONB,                            -- 위젯 설정
    svg_template    TEXT,                             -- SVG 시각화 템플릿
    created_by      UUID REFERENCES dh.user_account(user_id),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.widget_template IS '대시보드 위젯 템플릿 라이브러리';

-- 9-6. 사용자 대시보드 위젯 설정 (User Widget Layout)
CREATE TABLE dh.user_widget_layout (
    layout_id       SERIAL PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES dh.user_account(user_id),
    widget_id       VARCHAR(30) NOT NULL REFERENCES dh.widget_template(widget_id),
    position_x      INT DEFAULT 0,
    position_y      INT DEFAULT 0,
    width           INT DEFAULT 1,
    height          INT DEFAULT 1,
    is_visible      BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, widget_id)
);

-- 9-7. 데이터 리니지 (Data Lineage)
CREATE TABLE dh.lineage_node (
    node_id         VARCHAR(30) PRIMARY KEY,          -- e.g. node-src-1
    node_name       VARCHAR(200) NOT NULL,
    stage           VARCHAR(20) NOT NULL,             -- source, ingestion, transformation, serving
    node_type       VARCHAR(30),                      -- FA, EXT, APP, SQL, VIZ, API
    system_ref      VARCHAR(100),                     -- 참조 시스템명
    status          VARCHAR(20) DEFAULT 'normal',
    throughput      VARCHAR(50),
    records_in      BIGINT,
    records_out     BIGINT,
    latency_sec     NUMERIC(8,2),
    quality_score   NUMERIC(5,2),
    description     TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dh.lineage_node IS '데이터 리니지 노드 (SOURCE→INGESTION→TRANSFORM→SERVING)';

-- 9-8. 리니지 엣지 (Lineage Edge)
CREATE TABLE dh.lineage_edge (
    edge_id         SERIAL PRIMARY KEY,
    source_node_id  VARCHAR(30) NOT NULL REFERENCES dh.lineage_node(node_id),
    target_node_id  VARCHAR(30) NOT NULL REFERENCES dh.lineage_node(node_id),
    edge_type       VARCHAR(20) DEFAULT 'data_flow',  -- data_flow, trigger, reference
    description     TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (source_node_id, target_node_id)
);

-- 9-9. AI 대화이력 (AI Chat History)
CREATE TABLE dh.ai_chat_session (
    session_id      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES dh.user_account(user_id),
    title           VARCHAR(200),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE dh.ai_chat_message (
    message_id      BIGSERIAL PRIMARY KEY,
    session_id      UUID NOT NULL REFERENCES dh.ai_chat_session(session_id) ON DELETE CASCADE,
    role            VARCHAR(10) NOT NULL,             -- user, assistant
    content         TEXT NOT NULL,
    source_refs     JSONB,                            -- 참조 데이터셋/테이블 정보
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_chat_session ON dh.ai_chat_message(session_id, created_at);


-- ============================================================================
-- 10. 유통 통계 집계 (Distribution Statistics - 시계열)
-- ============================================================================

-- 10-1. 일별 유통 통계 (Daily Distribution Stats)
CREATE TABLE dh.daily_dist_stats (
    stat_id         BIGSERIAL PRIMARY KEY,
    stat_date       DATE NOT NULL,
    product_id      UUID REFERENCES dh.data_product(product_id),
    api_calls       BIGINT DEFAULT 0,
    downloads       INT DEFAULT 0,
    active_users    INT DEFAULT 0,
    avg_latency_ms  INT,
    error_count     INT DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (stat_date, product_id)
);

-- 10-2. 부서별 활용 통계 (Dept Usage Stats)
CREATE TABLE dh.dept_usage_stats (
    stat_id         BIGSERIAL PRIMARY KEY,
    stat_month      DATE NOT NULL,                   -- 월 기준 (매월 1일)
    dept_id         INT NOT NULL REFERENCES dh.department(dept_id),
    api_calls       BIGINT DEFAULT 0,
    downloads       INT DEFAULT 0,
    data_requests   INT DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (stat_month, dept_id)
);


-- ============================================================================
-- updated_at 자동 갱신 트리거
-- ============================================================================

CREATE OR REPLACE FUNCTION dh.update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- updated_at 컬럼이 있는 주요 테이블에 트리거 적용
DO $$
DECLARE
    t TEXT;
BEGIN
    FOR t IN
        SELECT table_name FROM information_schema.columns
        WHERE table_schema = 'dh' AND column_name = 'updated_at'
    LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_%s_updated
             BEFORE UPDATE ON dh.%I
             FOR EACH ROW EXECUTE FUNCTION dh.update_timestamp()',
            t, t
        );
    END LOOP;
END;
$$;
