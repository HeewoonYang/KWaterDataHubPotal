/*
 * ============================================================================
 *  K-water DataHub Portal — 포탈 운영 DB 스키마 (PostgreSQL 15+)
 * ============================================================================
 *  대상: 포탈 자체 운영 데이터 (연계·수집된 원천 데이터 제외)
 *  범위: 사용자/권한, 카탈로그/메타, 수집관리, 유통/활용, 품질,
 *        온톨로지, 모니터링, 커뮤니티, 시스템관리, 대시보드
 *  작성일: 2026-03-11
 *  공통 감사컬럼: 모든 테이블에 created_at, created_by, updated_at, updated_by 포함
 * ============================================================================
 */

-- ============================================================================
-- 0. 확장 모듈 & ENUM 타입
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TYPE data_security_level AS ENUM ('public','internal','restricted','confidential');
CREATE TYPE entity_status AS ENUM ('active','inactive','pending','locked','deprecated');
CREATE TYPE approval_status AS ENUM ('pending','approved','rejected','revision_needed','cancelled');
CREATE TYPE collect_method AS ENUM ('cdc','batch','api','file','streaming','migration');
CREATE TYPE data_asset_type AS ENUM ('table','api','file','view','stream');
CREATE TYPE login_type AS ENUM ('sso','partner','engineer','admin');
CREATE TYPE noti_type AS ENUM ('system','approval','quality','security','pipeline');
CREATE TYPE deidentify_rule_type AS ENUM ('masking','pseudonym','aggregation','suppression','rounding','encryption');


-- ============================================================================
-- 1. 사용자·조직·권한 도메인
-- ============================================================================

CREATE TABLE division (
    division_id   SERIAL       PRIMARY KEY,
    division_code VARCHAR(20)  NOT NULL UNIQUE,
    division_name VARCHAR(100) NOT NULL,
    sort_order    INT          DEFAULT 0,
    is_active     BOOLEAN      DEFAULT TRUE,
    created_at    TIMESTAMPTZ  DEFAULT now(),
    created_by    UUID,
    updated_at    TIMESTAMPTZ  DEFAULT now(),
    updated_by    UUID
);

CREATE TABLE department (
    dept_id       SERIAL       PRIMARY KEY,
    division_id   INT          NOT NULL REFERENCES division(division_id),
    dept_code     VARCHAR(20)  NOT NULL UNIQUE,
    dept_name     VARCHAR(100) NOT NULL,
    headcount     INT          DEFAULT 0,
    sort_order    INT          DEFAULT 0,
    is_active     BOOLEAN      DEFAULT TRUE,
    created_at    TIMESTAMPTZ  DEFAULT now(),
    created_by    UUID,
    updated_at    TIMESTAMPTZ  DEFAULT now(),
    updated_by    UUID
);

CREATE TABLE role (
    role_id        SERIAL        PRIMARY KEY,
    role_code      VARCHAR(30)   NOT NULL UNIQUE,
    role_name      VARCHAR(100)  NOT NULL,
    role_group     VARCHAR(50)   NOT NULL,
    role_level     SMALLINT      DEFAULT 0 CHECK (role_level BETWEEN 0 AND 6),
    data_clearance SMALLINT      DEFAULT 1 CHECK (data_clearance BETWEEN 1 AND 4),
    description    TEXT,
    is_active      BOOLEAN       DEFAULT TRUE,
    created_at     TIMESTAMPTZ   DEFAULT now(),
    created_by     UUID,
    updated_at     TIMESTAMPTZ   DEFAULT now(),
    updated_by     UUID
);

CREATE TABLE user_account (
    user_id        UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
    login_id       VARCHAR(50)   NOT NULL UNIQUE,
    user_name      VARCHAR(50)   NOT NULL,
    email          VARCHAR(120),
    phone          VARCHAR(20),
    dept_id        INT           REFERENCES department(dept_id),
    role_id        INT           NOT NULL REFERENCES role(role_id),
    login_type     login_type    NOT NULL DEFAULT 'sso',
    status         entity_status NOT NULL DEFAULT 'active',
    last_login_at  TIMESTAMPTZ,
    password_hash  VARCHAR(256),
    profile_image  VARCHAR(500),
    created_at     TIMESTAMPTZ   DEFAULT now(),
    created_by     UUID,
    updated_at     TIMESTAMPTZ   DEFAULT now(),
    updated_by     UUID
);

CREATE TABLE menu (
    menu_id      SERIAL       PRIMARY KEY,
    menu_code    VARCHAR(30)  NOT NULL UNIQUE,
    menu_name    VARCHAR(100) NOT NULL,
    parent_code  VARCHAR(30)  REFERENCES menu(menu_code),
    section      VARCHAR(30)  NOT NULL,
    screen_id    VARCHAR(50),
    icon         VARCHAR(50),
    sort_order   INT          DEFAULT 0,
    is_active    BOOLEAN      DEFAULT TRUE,
    created_at   TIMESTAMPTZ  DEFAULT now(),
    created_by   UUID,
    updated_at   TIMESTAMPTZ  DEFAULT now(),
    updated_by   UUID
);

CREATE TABLE role_menu_perm (
    role_id       INT     NOT NULL REFERENCES role(role_id) ON DELETE CASCADE,
    menu_id       INT     NOT NULL REFERENCES menu(menu_id) ON DELETE CASCADE,
    can_read      BOOLEAN DEFAULT TRUE,
    can_create    BOOLEAN DEFAULT FALSE,
    can_update    BOOLEAN DEFAULT FALSE,
    can_delete    BOOLEAN DEFAULT FALSE,
    can_approve   BOOLEAN DEFAULT FALSE,
    can_download  BOOLEAN DEFAULT FALSE,
    created_at    TIMESTAMPTZ DEFAULT now(),
    created_by    UUID,
    updated_at    TIMESTAMPTZ DEFAULT now(),
    updated_by    UUID,
    PRIMARY KEY (role_id, menu_id)
);

CREATE TABLE login_history (
    history_id   BIGSERIAL    PRIMARY KEY,
    user_id      UUID         NOT NULL REFERENCES user_account(user_id),
    login_type   login_type   NOT NULL,
    login_ip     INET,
    user_agent   VARCHAR(500),
    login_at     TIMESTAMPTZ  DEFAULT now(),
    logout_at    TIMESTAMPTZ,
    is_success   BOOLEAN      DEFAULT TRUE,
    fail_reason  VARCHAR(200),
    created_at   TIMESTAMPTZ  DEFAULT now(),
    created_by   UUID,
    updated_at   TIMESTAMPTZ  DEFAULT now(),
    updated_by   UUID
);


-- ============================================================================
-- 2. 카탈로그·메타데이터 도메인
-- ============================================================================

CREATE TABLE domain (
    domain_id   SERIAL       PRIMARY KEY,
    domain_code VARCHAR(20)  NOT NULL UNIQUE,
    domain_name VARCHAR(100) NOT NULL,
    description TEXT,
    color       VARCHAR(7),
    icon        VARCHAR(50),
    sort_order  INT          DEFAULT 0,
    is_active   BOOLEAN      DEFAULT TRUE,
    created_at  TIMESTAMPTZ  DEFAULT now(),
    created_by  UUID,
    updated_at  TIMESTAMPTZ  DEFAULT now(),
    updated_by  UUID
);

CREATE TABLE source_system (
    system_id       SERIAL        PRIMARY KEY,
    system_code     VARCHAR(30)   NOT NULL UNIQUE,
    system_name     VARCHAR(100)  NOT NULL,
    system_name_en  VARCHAR(100),
    description     TEXT,
    dbms_type       VARCHAR(30),
    protocol        VARCHAR(30),
    network_zone    VARCHAR(20),
    connection_info JSONB,
    owner_dept_id   INT           REFERENCES department(dept_id),
    status          entity_status DEFAULT 'active',
    created_at      TIMESTAMPTZ   DEFAULT now(),
    created_by      UUID,
    updated_at      TIMESTAMPTZ   DEFAULT now(),
    updated_by      UUID
);

CREATE TABLE dataset (
    dataset_id       UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_code     VARCHAR(50)     NOT NULL UNIQUE,
    table_name       VARCHAR(128),
    dataset_name     VARCHAR(200)    NOT NULL,
    description      TEXT,
    domain_id        INT             REFERENCES domain(domain_id),
    system_id        INT             REFERENCES source_system(system_id),
    asset_type       data_asset_type DEFAULT 'table',
    security_level   data_security_level DEFAULT 'internal',
    quality_score    NUMERIC(5,2)    DEFAULT 0 CHECK (quality_score BETWEEN 0 AND 100),
    row_count        BIGINT          DEFAULT 0,
    column_count     INT             DEFAULT 0,
    size_bytes       BIGINT          DEFAULT 0,
    owner_dept_id    INT             REFERENCES department(dept_id),
    steward_user_id  UUID            REFERENCES user_account(user_id),
    status           entity_status   DEFAULT 'active',
    last_profiled_at TIMESTAMPTZ,
    created_at       TIMESTAMPTZ     DEFAULT now(),
    created_by       UUID,
    updated_at       TIMESTAMPTZ     DEFAULT now(),
    updated_by       UUID
);

CREATE TABLE dataset_column (
    column_id       SERIAL        PRIMARY KEY,
    dataset_id      UUID          NOT NULL REFERENCES dataset(dataset_id) ON DELETE CASCADE,
    column_name     VARCHAR(128)  NOT NULL,
    column_name_ko  VARCHAR(128),
    data_type       VARCHAR(50)   NOT NULL,
    data_length     INT,
    is_pk           BOOLEAN       DEFAULT FALSE,
    is_fk           BOOLEAN       DEFAULT FALSE,
    is_nullable     BOOLEAN       DEFAULT TRUE,
    default_value   VARCHAR(200),
    std_term_id     INT,
    description     TEXT,
    null_rate       NUMERIC(5,2),
    unique_rate     NUMERIC(5,2),
    min_value       VARCHAR(200),
    max_value       VARCHAR(200),
    sample_values   TEXT[],
    sort_order      INT           DEFAULT 0,
    created_at      TIMESTAMPTZ   DEFAULT now(),
    created_by      UUID,
    updated_at      TIMESTAMPTZ   DEFAULT now(),
    updated_by      UUID,
    UNIQUE (dataset_id, column_name)
);

CREATE TABLE tag (
    tag_id     SERIAL       PRIMARY KEY,
    tag_name   VARCHAR(50)  NOT NULL UNIQUE,
    tag_type   VARCHAR(20)  DEFAULT 'keyword',
    color      VARCHAR(7),
    created_at TIMESTAMPTZ  DEFAULT now(),
    created_by UUID,
    updated_at TIMESTAMPTZ  DEFAULT now(),
    updated_by UUID
);

CREATE TABLE dataset_tag (
    dataset_id UUID NOT NULL REFERENCES dataset(dataset_id) ON DELETE CASCADE,
    tag_id     INT  NOT NULL REFERENCES tag(tag_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID,
    updated_at TIMESTAMPTZ DEFAULT now(),
    updated_by UUID,
    PRIMARY KEY (dataset_id, tag_id)
);

CREATE TABLE bookmark (
    bookmark_id SERIAL      PRIMARY KEY,
    user_id     UUID        NOT NULL REFERENCES user_account(user_id) ON DELETE CASCADE,
    dataset_id  UUID        NOT NULL REFERENCES dataset(dataset_id) ON DELETE CASCADE,
    memo        VARCHAR(200),
    created_at  TIMESTAMPTZ DEFAULT now(),
    created_by  UUID,
    updated_at  TIMESTAMPTZ DEFAULT now(),
    updated_by  UUID,
    UNIQUE (user_id, dataset_id)
);

CREATE TABLE glossary_term (
    term_id         SERIAL        PRIMARY KEY,
    term_name       VARCHAR(100)  NOT NULL,
    term_name_en    VARCHAR(100),
    domain_id       INT           REFERENCES domain(domain_id),
    data_type       VARCHAR(30),
    data_length     INT,
    unit            VARCHAR(30),
    valid_range_min VARCHAR(50),
    valid_range_max VARCHAR(50),
    definition      TEXT          NOT NULL,
    example         VARCHAR(200),
    synonym         VARCHAR(200),
    status          approval_status DEFAULT 'pending',
    approved_by     UUID          REFERENCES user_account(user_id),
    approved_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ   DEFAULT now(),
    created_by      UUID          REFERENCES user_account(user_id),
    updated_at      TIMESTAMPTZ   DEFAULT now(),
    updated_by      UUID
);

CREATE TABLE glossary_history (
    history_id  SERIAL          PRIMARY KEY,
    term_id     INT             NOT NULL REFERENCES glossary_term(term_id) ON DELETE CASCADE,
    change_desc TEXT            NOT NULL,
    changed_by  UUID            REFERENCES user_account(user_id),
    prev_status approval_status,
    new_status  approval_status,
    prev_value  JSONB,
    new_value   JSONB,
    created_at  TIMESTAMPTZ     DEFAULT now(),
    created_by  UUID,
    updated_at  TIMESTAMPTZ     DEFAULT now(),
    updated_by  UUID
);

CREATE TABLE code_group (
    group_id    SERIAL       PRIMARY KEY,
    group_code  VARCHAR(30)  NOT NULL UNIQUE,
    group_name  VARCHAR(100) NOT NULL,
    description TEXT,
    is_active   BOOLEAN      DEFAULT TRUE,
    created_at  TIMESTAMPTZ  DEFAULT now(),
    created_by  UUID,
    updated_at  TIMESTAMPTZ  DEFAULT now(),
    updated_by  UUID
);

CREATE TABLE code (
    code_id     SERIAL       PRIMARY KEY,
    group_id    INT          NOT NULL REFERENCES code_group(group_id) ON DELETE CASCADE,
    code_value  VARCHAR(30)  NOT NULL,
    code_name   VARCHAR(100) NOT NULL,
    description VARCHAR(200),
    sort_order  INT          DEFAULT 0,
    is_active   BOOLEAN      DEFAULT TRUE,
    created_at  TIMESTAMPTZ  DEFAULT now(),
    created_by  UUID,
    updated_at  TIMESTAMPTZ  DEFAULT now(),
    updated_by  UUID,
    UNIQUE (group_id, code_value)
);

CREATE TABLE data_model (
    model_id          SERIAL        PRIMARY KEY,
    model_name        VARCHAR(200)  NOT NULL,
    model_type        VARCHAR(20)   NOT NULL CHECK (model_type IN ('logical','physical')),
    domain_id         INT           REFERENCES domain(domain_id),
    version           VARCHAR(20)   DEFAULT '1.0',
    description       TEXT,
    table_count       INT           DEFAULT 0,
    naming_compliance NUMERIC(5,2)  DEFAULT 0,
    type_consistency  NUMERIC(5,2)  DEFAULT 0,
    ref_integrity     NUMERIC(5,2)  DEFAULT 0,
    status            entity_status DEFAULT 'active',
    owner_user_id     UUID          REFERENCES user_account(user_id),
    created_at        TIMESTAMPTZ   DEFAULT now(),
    created_by        UUID,
    updated_at        TIMESTAMPTZ   DEFAULT now(),
    updated_by        UUID
);

CREATE TABLE model_entity (
    entity_id      SERIAL        PRIMARY KEY,
    model_id       INT           NOT NULL REFERENCES data_model(model_id) ON DELETE CASCADE,
    entity_name    VARCHAR(128)  NOT NULL,
    entity_name_ko VARCHAR(128),
    entity_type    VARCHAR(20)   DEFAULT 'table',
    description    TEXT,
    sort_order     INT           DEFAULT 0,
    created_at     TIMESTAMPTZ   DEFAULT now(),
    created_by     UUID,
    updated_at     TIMESTAMPTZ   DEFAULT now(),
    updated_by     UUID,
    UNIQUE (model_id, entity_name)
);

CREATE TABLE model_attribute (
    attribute_id  SERIAL       PRIMARY KEY,
    entity_id     INT          NOT NULL REFERENCES model_entity(entity_id) ON DELETE CASCADE,
    attr_name     VARCHAR(128) NOT NULL,
    attr_name_ko  VARCHAR(128),
    data_type     VARCHAR(50)  NOT NULL,
    data_length   INT,
    is_pk         BOOLEAN      DEFAULT FALSE,
    is_fk         BOOLEAN      DEFAULT FALSE,
    is_nullable   BOOLEAN      DEFAULT TRUE,
    fk_ref_entity VARCHAR(128),
    fk_ref_attr   VARCHAR(128),
    description   TEXT,
    sort_order    INT          DEFAULT 0,
    created_at    TIMESTAMPTZ  DEFAULT now(),
    created_by    UUID,
    updated_at    TIMESTAMPTZ  DEFAULT now(),
    updated_by    UUID,
    UNIQUE (entity_id, attr_name)
);


-- ============================================================================
-- 3. 수집 관리 도메인
-- ============================================================================

CREATE TABLE pipeline (
    pipeline_id    SERIAL         PRIMARY KEY,
    pipeline_name  VARCHAR(200)   NOT NULL,
    pipeline_code  VARCHAR(50)    UNIQUE,
    system_id      INT            REFERENCES source_system(system_id),
    collect_method collect_method NOT NULL DEFAULT 'batch',
    schedule       VARCHAR(50),
    source_table   VARCHAR(200),
    target_storage VARCHAR(200),
    throughput     VARCHAR(50),
    description    TEXT,
    owner_user_id  UUID           REFERENCES user_account(user_id),
    owner_dept_id  INT            REFERENCES department(dept_id),
    status         entity_status  DEFAULT 'active',
    created_at     TIMESTAMPTZ    DEFAULT now(),
    created_by     UUID,
    updated_at     TIMESTAMPTZ    DEFAULT now(),
    updated_by     UUID
);

CREATE TABLE pipeline_execution (
    execution_id    BIGSERIAL   PRIMARY KEY,
    pipeline_id     INT         NOT NULL REFERENCES pipeline(pipeline_id) ON DELETE CASCADE,
    started_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    finished_at     TIMESTAMPTZ,
    duration_sec    INT,
    records_read    BIGINT      DEFAULT 0,
    records_written BIGINT      DEFAULT 0,
    records_error   BIGINT      DEFAULT 0,
    success_rate    NUMERIC(5,2),
    status          VARCHAR(20) DEFAULT 'running' CHECK (status IN ('running','success','failed','cancelled')),
    error_message   TEXT,
    error_detail    JSONB,
    created_at      TIMESTAMPTZ DEFAULT now(),
    created_by      UUID,
    updated_at      TIMESTAMPTZ DEFAULT now(),
    updated_by      UUID
);

CREATE TABLE pipeline_column_mapping (
    mapping_id     SERIAL       PRIMARY KEY,
    pipeline_id    INT          NOT NULL REFERENCES pipeline(pipeline_id) ON DELETE CASCADE,
    source_column  VARCHAR(128) NOT NULL,
    target_column  VARCHAR(128) NOT NULL,
    source_type    VARCHAR(50),
    target_type    VARCHAR(50),
    transform_rule VARCHAR(500),
    is_required    BOOLEAN      DEFAULT FALSE,
    sort_order     INT          DEFAULT 0,
    created_at     TIMESTAMPTZ  DEFAULT now(),
    created_by     UUID,
    updated_at     TIMESTAMPTZ  DEFAULT now(),
    updated_by     UUID,
    UNIQUE (pipeline_id, source_column)
);

CREATE TABLE cdc_connector (
    connector_id   SERIAL        PRIMARY KEY,
    system_id      INT           NOT NULL REFERENCES source_system(system_id),
    connector_name VARCHAR(100)  NOT NULL,
    connector_type VARCHAR(30),
    dbms_type      VARCHAR(30),
    table_count    INT           DEFAULT 0,
    events_per_min BIGINT        DEFAULT 0,
    lag_seconds    INT           DEFAULT 0,
    config         JSONB,
    status         entity_status DEFAULT 'active',
    created_at     TIMESTAMPTZ   DEFAULT now(),
    created_by     UUID,
    updated_at     TIMESTAMPTZ   DEFAULT now(),
    updated_by     UUID
);

CREATE TABLE kafka_topic (
    topic_id        SERIAL        PRIMARY KEY,
    topic_name      VARCHAR(200)  NOT NULL UNIQUE,
    cluster_name    VARCHAR(100),
    partition_count INT           DEFAULT 3,
    replication     INT           DEFAULT 2,
    retention_hours INT           DEFAULT 168,
    msg_per_sec     BIGINT        DEFAULT 0,
    consumer_groups TEXT[],
    status          entity_status DEFAULT 'active',
    created_at      TIMESTAMPTZ   DEFAULT now(),
    created_by      UUID,
    updated_at      TIMESTAMPTZ   DEFAULT now(),
    updated_by      UUID
);

CREATE TABLE external_integration (
    integration_id   SERIAL        PRIMARY KEY,
    integration_name VARCHAR(200)  NOT NULL,
    integration_type VARCHAR(30),
    source_system    VARCHAR(100),
    target_system    VARCHAR(100),
    protocol         VARCHAR(30),
    endpoint_url     VARCHAR(500),
    frequency        VARCHAR(50),
    last_success_at  TIMESTAMPTZ,
    last_fail_at     TIMESTAMPTZ,
    status           entity_status DEFAULT 'active',
    created_at       TIMESTAMPTZ   DEFAULT now(),
    created_by       UUID,
    updated_at       TIMESTAMPTZ   DEFAULT now(),
    updated_by       UUID
);

CREATE TABLE dbt_model (
    dbt_model_id    SERIAL        PRIMARY KEY,
    model_name      VARCHAR(200)  NOT NULL,
    model_path      VARCHAR(500),
    materialization VARCHAR(30)   DEFAULT 'table',
    source_tables   TEXT[],
    target_table    VARCHAR(200),
    description     TEXT,
    tags            TEXT[],
    last_run_at     TIMESTAMPTZ,
    last_run_status VARCHAR(20),
    run_duration_sec INT,
    owner_user_id   UUID          REFERENCES user_account(user_id),
    status          entity_status DEFAULT 'active',
    created_at      TIMESTAMPTZ   DEFAULT now(),
    created_by      UUID,
    updated_at      TIMESTAMPTZ   DEFAULT now(),
    updated_by      UUID
);

CREATE TABLE server_inventory (
    server_id   SERIAL        PRIMARY KEY,
    server_name VARCHAR(100)  NOT NULL,
    server_type VARCHAR(30),
    ip_address  INET,
    os_type     VARCHAR(50),
    cpu_cores   INT,
    memory_gb   INT,
    disk_gb     INT,
    environment VARCHAR(20),
    datacenter  VARCHAR(50),
    status      entity_status DEFAULT 'active',
    created_at  TIMESTAMPTZ   DEFAULT now(),
    created_by  UUID,
    updated_at  TIMESTAMPTZ   DEFAULT now(),
    updated_by  UUID
);


-- ============================================================================
-- 4. 유통·활용 도메인
-- ============================================================================

CREATE TABLE data_product (
    product_id      UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_code    VARCHAR(50)   NOT NULL UNIQUE,
    product_name    VARCHAR(200)  NOT NULL,
    description     TEXT,
    product_type    VARCHAR(30)   DEFAULT 'api',
    domain_id       INT           REFERENCES domain(domain_id),
    security_level  data_security_level DEFAULT 'internal',
    version         VARCHAR(20)   DEFAULT '1.0',
    endpoint_url    VARCHAR(500),
    rate_limit      INT           DEFAULT 1000,
    total_calls     BIGINT        DEFAULT 0,
    avg_response_ms INT           DEFAULT 0,
    sla_uptime      NUMERIC(5,2)  DEFAULT 99.9,
    owner_dept_id   INT           REFERENCES department(dept_id),
    owner_user_id   UUID          REFERENCES user_account(user_id),
    status          entity_status DEFAULT 'active',
    published_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ   DEFAULT now(),
    created_by      UUID,
    updated_at      TIMESTAMPTZ   DEFAULT now(),
    updated_by      UUID
);

CREATE TABLE product_source (
    source_id   SERIAL      PRIMARY KEY,
    product_id  UUID        NOT NULL REFERENCES data_product(product_id) ON DELETE CASCADE,
    dataset_id  UUID        NOT NULL REFERENCES dataset(dataset_id),
    join_type   VARCHAR(20),
    join_key    VARCHAR(200),
    description VARCHAR(200),
    sort_order  INT         DEFAULT 0,
    created_at  TIMESTAMPTZ DEFAULT now(),
    created_by  UUID,
    updated_at  TIMESTAMPTZ DEFAULT now(),
    updated_by  UUID,
    UNIQUE (product_id, dataset_id)
);

CREATE TABLE product_field (
    field_id      SERIAL        PRIMARY KEY,
    product_id    UUID          NOT NULL REFERENCES data_product(product_id) ON DELETE CASCADE,
    field_name    VARCHAR(128)  NOT NULL,
    field_name_ko VARCHAR(128),
    field_type    VARCHAR(50)   NOT NULL,
    is_required   BOOLEAN       DEFAULT FALSE,
    is_filterable BOOLEAN       DEFAULT FALSE,
    description   VARCHAR(200),
    sample_value  VARCHAR(200),
    sort_order    INT           DEFAULT 0,
    created_at    TIMESTAMPTZ   DEFAULT now(),
    created_by    UUID,
    updated_at    TIMESTAMPTZ   DEFAULT now(),
    updated_by    UUID,
    UNIQUE (product_id, field_name)
);

CREATE TABLE api_key (
    key_id       UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id      UUID          NOT NULL REFERENCES user_account(user_id),
    product_id   UUID          REFERENCES data_product(product_id),
    api_key_hash VARCHAR(256)  NOT NULL,
    key_prefix   VARCHAR(10),
    description  VARCHAR(200),
    is_active    BOOLEAN       DEFAULT TRUE,
    expires_at   TIMESTAMPTZ,
    last_used_at TIMESTAMPTZ,
    total_calls  BIGINT        DEFAULT 0,
    created_at   TIMESTAMPTZ   DEFAULT now(),
    created_by   UUID,
    updated_at   TIMESTAMPTZ   DEFAULT now(),
    updated_by   UUID
);

CREATE TABLE deidentify_policy (
    policy_id    SERIAL             PRIMARY KEY,
    policy_name  VARCHAR(200)       NOT NULL,
    description  TEXT,
    target_level data_security_level,
    rule_count   INT                DEFAULT 0,
    is_active    BOOLEAN            DEFAULT TRUE,
    approved_by  UUID               REFERENCES user_account(user_id),
    created_at   TIMESTAMPTZ        DEFAULT now(),
    created_by   UUID               REFERENCES user_account(user_id),
    updated_at   TIMESTAMPTZ        DEFAULT now(),
    updated_by   UUID
);

CREATE TABLE deidentify_rule (
    rule_id        SERIAL               PRIMARY KEY,
    policy_id      INT                  NOT NULL REFERENCES deidentify_policy(policy_id) ON DELETE CASCADE,
    column_pattern VARCHAR(200)         NOT NULL,
    rule_type      deidentify_rule_type NOT NULL,
    rule_config    JSONB,
    priority       INT                  DEFAULT 0,
    description    VARCHAR(200),
    created_at     TIMESTAMPTZ          DEFAULT now(),
    created_by     UUID,
    updated_at     TIMESTAMPTZ          DEFAULT now(),
    updated_by     UUID
);

CREATE TABLE data_request (
    request_id      SERIAL          PRIMARY KEY,
    request_code    VARCHAR(30)     NOT NULL UNIQUE,
    user_id         UUID            NOT NULL REFERENCES user_account(user_id),
    dataset_id      UUID            REFERENCES dataset(dataset_id),
    product_id      UUID            REFERENCES data_product(product_id),
    request_type    VARCHAR(30)     NOT NULL,
    purpose         TEXT,
    is_urgent       BOOLEAN         DEFAULT FALSE,
    approval_status approval_status DEFAULT 'pending',
    approver_id     UUID            REFERENCES user_account(user_id),
    approved_at     TIMESTAMPTZ,
    expire_at       TIMESTAMPTZ,
    created_at      TIMESTAMPTZ     DEFAULT now(),
    created_by      UUID,
    updated_at      TIMESTAMPTZ     DEFAULT now(),
    updated_by      UUID
);

CREATE TABLE request_attachment (
    attachment_id SERIAL        PRIMARY KEY,
    request_id    INT           NOT NULL REFERENCES data_request(request_id) ON DELETE CASCADE,
    file_name     VARCHAR(200)  NOT NULL,
    file_path     VARCHAR(500)  NOT NULL,
    file_size     BIGINT        DEFAULT 0,
    mime_type     VARCHAR(100),
    created_at    TIMESTAMPTZ   DEFAULT now(),
    created_by    UUID,
    updated_at    TIMESTAMPTZ   DEFAULT now(),
    updated_by    UUID
);

CREATE TABLE request_timeline (
    timeline_id   SERIAL          PRIMARY KEY,
    request_id    INT             NOT NULL REFERENCES data_request(request_id) ON DELETE CASCADE,
    action_type   VARCHAR(30)     NOT NULL,
    status        approval_status NOT NULL,
    actor_user_id UUID            REFERENCES user_account(user_id),
    comment       TEXT,
    action_date   TIMESTAMPTZ     DEFAULT now(),
    created_at    TIMESTAMPTZ     DEFAULT now(),
    created_by    UUID,
    updated_at    TIMESTAMPTZ     DEFAULT now(),
    updated_by    UUID
);

CREATE TABLE chart_content (
    chart_id      SERIAL        PRIMARY KEY,
    chart_name    VARCHAR(200)  NOT NULL,
    chart_type    VARCHAR(30),
    description   TEXT,
    config        JSONB,
    data_source   VARCHAR(500),
    thumbnail_url VARCHAR(500),
    domain_id     INT           REFERENCES domain(domain_id),
    owner_user_id UUID          REFERENCES user_account(user_id),
    is_public     BOOLEAN       DEFAULT FALSE,
    view_count    INT           DEFAULT 0,
    status        entity_status DEFAULT 'active',
    created_at    TIMESTAMPTZ   DEFAULT now(),
    created_by    UUID,
    updated_at    TIMESTAMPTZ   DEFAULT now(),
    updated_by    UUID
);

CREATE TABLE external_provision (
    provision_id   SERIAL        PRIMARY KEY,
    provision_name VARCHAR(200)  NOT NULL,
    target_org     VARCHAR(200)  NOT NULL,
    dataset_id     UUID          REFERENCES dataset(dataset_id),
    product_id     UUID          REFERENCES data_product(product_id),
    provision_type VARCHAR(30),
    frequency      VARCHAR(30),
    record_count   BIGINT        DEFAULT 0,
    last_provided  TIMESTAMPTZ,
    contract_start DATE,
    contract_end   DATE,
    status         entity_status DEFAULT 'active',
    created_at     TIMESTAMPTZ   DEFAULT now(),
    created_by     UUID,
    updated_at     TIMESTAMPTZ   DEFAULT now(),
    updated_by     UUID
);


-- ============================================================================
-- 5. 데이터 품질 도메인
-- ============================================================================

CREATE TABLE dq_rule (
    rule_id     SERIAL        PRIMARY KEY,
    rule_name   VARCHAR(200)  NOT NULL,
    rule_code   VARCHAR(50)   UNIQUE,
    rule_type   VARCHAR(30)   NOT NULL,
    dataset_id  UUID          REFERENCES dataset(dataset_id),
    column_name VARCHAR(128),
    expression  TEXT,
    threshold   NUMERIC(5,2)  DEFAULT 95.00,
    severity    VARCHAR(10)   DEFAULT 'warning',
    description TEXT,
    is_active   BOOLEAN       DEFAULT TRUE,
    created_at  TIMESTAMPTZ   DEFAULT now(),
    created_by  UUID          REFERENCES user_account(user_id),
    updated_at  TIMESTAMPTZ   DEFAULT now(),
    updated_by  UUID
);

CREATE TABLE dq_execution (
    execution_id      BIGSERIAL   PRIMARY KEY,
    rule_id           INT         NOT NULL REFERENCES dq_rule(rule_id) ON DELETE CASCADE,
    dataset_id        UUID        NOT NULL REFERENCES dataset(dataset_id),
    execution_date    DATE        NOT NULL DEFAULT CURRENT_DATE,
    total_rows        BIGINT      DEFAULT 0,
    passed_rows       BIGINT      DEFAULT 0,
    failed_rows       BIGINT      DEFAULT 0,
    score             NUMERIC(5,2),
    result            VARCHAR(10) NOT NULL CHECK (result IN ('pass','fail','error','skip')),
    error_message     TEXT,
    execution_time_ms INT,
    created_at        TIMESTAMPTZ DEFAULT now(),
    created_by        UUID,
    updated_at        TIMESTAMPTZ DEFAULT now(),
    updated_by        UUID
);

CREATE TABLE domain_quality_score (
    score_id      SERIAL       PRIMARY KEY,
    domain_id     INT          NOT NULL REFERENCES domain(domain_id),
    score_date    DATE         NOT NULL DEFAULT CURRENT_DATE,
    completeness  NUMERIC(5,2) DEFAULT 0,
    accuracy      NUMERIC(5,2) DEFAULT 0,
    consistency   NUMERIC(5,2) DEFAULT 0,
    timeliness    NUMERIC(5,2) DEFAULT 0,
    validity      NUMERIC(5,2) DEFAULT 0,
    uniqueness    NUMERIC(5,2) DEFAULT 0,
    overall_score NUMERIC(5,2) DEFAULT 0,
    dataset_count INT          DEFAULT 0,
    rule_count    INT          DEFAULT 0,
    created_at    TIMESTAMPTZ  DEFAULT now(),
    created_by    UUID,
    updated_at    TIMESTAMPTZ  DEFAULT now(),
    updated_by    UUID,
    UNIQUE (domain_id, score_date)
);

CREATE TABLE quality_issue (
    issue_id      SERIAL      PRIMARY KEY,
    dataset_id    UUID        NOT NULL REFERENCES dataset(dataset_id),
    rule_id       INT         REFERENCES dq_rule(rule_id),
    issue_type    VARCHAR(30) NOT NULL,
    severity      VARCHAR(10) DEFAULT 'warning',
    column_name   VARCHAR(128),
    affected_rows BIGINT      DEFAULT 0,
    description   TEXT        NOT NULL,
    resolution    TEXT,
    status        VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open','investigating','resolved','ignored')),
    assigned_to   UUID        REFERENCES user_account(user_id),
    resolved_at   TIMESTAMPTZ,
    created_at    TIMESTAMPTZ DEFAULT now(),
    created_by    UUID,
    updated_at    TIMESTAMPTZ DEFAULT now(),
    updated_by    UUID
);


-- ============================================================================
-- 6. 온톨로지 도메인
-- ============================================================================

CREATE TABLE onto_class (
    class_id        SERIAL        PRIMARY KEY,
    class_name_ko   VARCHAR(100)  NOT NULL,
    class_name_en   VARCHAR(100),
    class_uri       VARCHAR(200)  NOT NULL UNIQUE,
    parent_class_id INT           REFERENCES onto_class(class_id),
    description     TEXT,
    instance_count  INT           DEFAULT 0,
    icon            VARCHAR(50),
    color           VARCHAR(7),
    sort_order      INT           DEFAULT 0,
    created_at      TIMESTAMPTZ   DEFAULT now(),
    created_by      UUID,
    updated_at      TIMESTAMPTZ   DEFAULT now(),
    updated_by      UUID
);

CREATE TABLE onto_data_property (
    property_id   SERIAL        PRIMARY KEY,
    class_id      INT           NOT NULL REFERENCES onto_class(class_id) ON DELETE CASCADE,
    property_name VARCHAR(100)  NOT NULL,
    property_uri  VARCHAR(200),
    data_type     VARCHAR(50)   NOT NULL,
    cardinality   VARCHAR(10)   DEFAULT '1',
    unit          VARCHAR(30),
    std_term_id   INT           REFERENCES glossary_term(term_id),
    description   TEXT,
    sort_order    INT           DEFAULT 0,
    created_at    TIMESTAMPTZ   DEFAULT now(),
    created_by    UUID,
    updated_at    TIMESTAMPTZ   DEFAULT now(),
    updated_by    UUID,
    UNIQUE (class_id, property_name)
);

CREATE TABLE onto_relationship (
    rel_id          SERIAL        PRIMARY KEY,
    source_class_id INT           NOT NULL REFERENCES onto_class(class_id) ON DELETE CASCADE,
    target_class_id INT           NOT NULL REFERENCES onto_class(class_id) ON DELETE CASCADE,
    rel_name_ko     VARCHAR(100)  NOT NULL,
    rel_name_en     VARCHAR(100),
    rel_uri         VARCHAR(200),
    cardinality     VARCHAR(10)   DEFAULT '0..*',
    direction       VARCHAR(10)   DEFAULT 'output' CHECK (direction IN ('output','input','bidirectional')),
    description     TEXT,
    sort_order      INT           DEFAULT 0,
    created_at      TIMESTAMPTZ   DEFAULT now(),
    created_by      UUID,
    updated_at      TIMESTAMPTZ   DEFAULT now(),
    updated_by      UUID,
    UNIQUE (source_class_id, target_class_id, rel_uri)
);


-- ============================================================================
-- 7. 모니터링 도메인
-- ============================================================================

CREATE TABLE region (
    region_id   SERIAL       PRIMARY KEY,
    region_code VARCHAR(20)  NOT NULL UNIQUE,
    region_name VARCHAR(100) NOT NULL,
    sort_order  INT          DEFAULT 0,
    created_at  TIMESTAMPTZ  DEFAULT now(),
    created_by  UUID,
    updated_at  TIMESTAMPTZ  DEFAULT now(),
    updated_by  UUID
);

CREATE TABLE office (
    office_id   SERIAL       PRIMARY KEY,
    region_id   INT          NOT NULL REFERENCES region(region_id),
    office_code VARCHAR(20)  NOT NULL UNIQUE,
    office_name VARCHAR(100) NOT NULL,
    address     VARCHAR(300),
    sort_order  INT          DEFAULT 0,
    created_at  TIMESTAMPTZ  DEFAULT now(),
    created_by  UUID,
    updated_at  TIMESTAMPTZ  DEFAULT now(),
    updated_by  UUID
);

CREATE TABLE site (
    site_id   SERIAL         PRIMARY KEY,
    office_id INT            NOT NULL REFERENCES office(office_id),
    site_code VARCHAR(20)    NOT NULL UNIQUE,
    site_name VARCHAR(100)   NOT NULL,
    site_type VARCHAR(30),
    latitude  NUMERIC(10,7),
    longitude NUMERIC(10,7),
    address   VARCHAR(300),
    capacity  NUMERIC(15,2),
    status    entity_status  DEFAULT 'active',
    created_at TIMESTAMPTZ   DEFAULT now(),
    created_by UUID,
    updated_at TIMESTAMPTZ   DEFAULT now(),
    updated_by UUID
);

CREATE TABLE sensor_tag (
    tag_id       SERIAL        PRIMARY KEY,
    site_id      INT           NOT NULL REFERENCES site(site_id),
    sensor_code  VARCHAR(50)   NOT NULL UNIQUE,
    sensor_name  VARCHAR(100)  NOT NULL,
    sensor_type  VARCHAR(30),
    unit         VARCHAR(20),
    min_range    NUMERIC(12,4),
    max_range    NUMERIC(12,4),
    install_date DATE,
    last_reading NUMERIC(12,4),
    last_read_at TIMESTAMPTZ,
    status       entity_status DEFAULT 'active',
    created_at   TIMESTAMPTZ   DEFAULT now(),
    created_by   UUID,
    updated_at   TIMESTAMPTZ   DEFAULT now(),
    updated_by   UUID
);

CREATE TABLE asset_database (
    asset_db_id   SERIAL      PRIMARY KEY,
    asset_type    VARCHAR(50) NOT NULL,
    asset_name    VARCHAR(200),
    total_count   INT         DEFAULT 0,
    active_count  INT         DEFAULT 0,
    source_system VARCHAR(100),
    last_sync_at  TIMESTAMPTZ,
    description   TEXT,
    created_at    TIMESTAMPTZ DEFAULT now(),
    created_by    UUID,
    updated_at    TIMESTAMPTZ DEFAULT now(),
    updated_by    UUID
);


-- ============================================================================
-- 8. 커뮤니티·소통 도메인
-- ============================================================================

CREATE TABLE board_post (
    post_id       SERIAL        PRIMARY KEY,
    user_id       UUID          NOT NULL REFERENCES user_account(user_id),
    title         VARCHAR(300)  NOT NULL,
    content       TEXT          NOT NULL,
    post_type     VARCHAR(20)   NOT NULL CHECK (post_type IN ('notice','internal','external')),
    is_pinned     BOOLEAN       DEFAULT FALSE,
    view_count    INT           DEFAULT 0,
    like_count    INT           DEFAULT 0,
    comment_count INT           DEFAULT 0,
    status        entity_status DEFAULT 'active',
    created_at    TIMESTAMPTZ   DEFAULT now(),
    created_by    UUID,
    updated_at    TIMESTAMPTZ   DEFAULT now(),
    updated_by    UUID
);

CREATE TABLE board_comment (
    comment_id   SERIAL        PRIMARY KEY,
    post_id      INT           NOT NULL REFERENCES board_post(post_id) ON DELETE CASCADE,
    user_id      UUID          NOT NULL REFERENCES user_account(user_id),
    parent_id    INT           REFERENCES board_comment(comment_id),
    comment_text TEXT          NOT NULL,
    status       entity_status DEFAULT 'active',
    created_at   TIMESTAMPTZ   DEFAULT now(),
    created_by   UUID,
    updated_at   TIMESTAMPTZ   DEFAULT now(),
    updated_by   UUID
);

CREATE TABLE resource_archive (
    resource_id    SERIAL        PRIMARY KEY,
    user_id        UUID          NOT NULL REFERENCES user_account(user_id),
    resource_name  VARCHAR(300)  NOT NULL,
    description    TEXT,
    file_name      VARCHAR(200)  NOT NULL,
    file_path      VARCHAR(500)  NOT NULL,
    file_size      BIGINT        DEFAULT 0,
    mime_type      VARCHAR(100),
    category       VARCHAR(30),
    download_count INT           DEFAULT 0,
    status         entity_status DEFAULT 'active',
    created_at     TIMESTAMPTZ   DEFAULT now(),
    created_by     UUID,
    updated_at     TIMESTAMPTZ   DEFAULT now(),
    updated_by     UUID
);


-- ============================================================================
-- 9. 시스템 관리 도메인
-- ============================================================================

CREATE TABLE security_policy (
    policy_id      SERIAL             PRIMARY KEY,
    policy_name    VARCHAR(200)       NOT NULL,
    policy_type    VARCHAR(30)        NOT NULL,
    description    TEXT,
    rule_config    JSONB,
    target_level   data_security_level,
    is_active      BOOLEAN            DEFAULT TRUE,
    effective_from DATE,
    effective_to   DATE,
    created_at     TIMESTAMPTZ        DEFAULT now(),
    created_by     UUID               REFERENCES user_account(user_id),
    updated_at     TIMESTAMPTZ        DEFAULT now(),
    updated_by     UUID
);

CREATE TABLE system_interface (
    interface_id     SERIAL        PRIMARY KEY,
    interface_code   VARCHAR(30)   NOT NULL UNIQUE,
    interface_name   VARCHAR(200)  NOT NULL,
    source_system_id INT           REFERENCES source_system(system_id),
    target_system_id INT           REFERENCES source_system(system_id),
    interface_type   VARCHAR(30),
    protocol         VARCHAR(30),
    frequency        VARCHAR(30),
    direction        VARCHAR(10)   DEFAULT 'inbound' CHECK (direction IN ('inbound','outbound','bidirectional')),
    last_success_at  TIMESTAMPTZ,
    last_fail_at     TIMESTAMPTZ,
    success_rate     NUMERIC(5,2)  DEFAULT 100.00,
    avg_response_ms  INT           DEFAULT 0,
    status           entity_status DEFAULT 'active',
    created_at       TIMESTAMPTZ   DEFAULT now(),
    created_by       UUID,
    updated_at       TIMESTAMPTZ   DEFAULT now(),
    updated_by       UUID
);

CREATE TABLE audit_log (
    log_id        BIGSERIAL   PRIMARY KEY,
    user_id       UUID        REFERENCES user_account(user_id),
    user_name     VARCHAR(50),
    action_type   VARCHAR(30) NOT NULL,
    target_table  VARCHAR(100),
    target_id     VARCHAR(100),
    action_detail TEXT,
    ip_address    INET,
    user_agent    VARCHAR(500),
    result        VARCHAR(10) DEFAULT 'success' CHECK (result IN ('success','fail','denied')),
    created_at    TIMESTAMPTZ DEFAULT now(),
    created_by    UUID,
    updated_at    TIMESTAMPTZ DEFAULT now(),
    updated_by    UUID
);

CREATE TABLE notification (
    noti_id    BIGSERIAL    PRIMARY KEY,
    user_id    UUID         NOT NULL REFERENCES user_account(user_id),
    noti_type  noti_type    NOT NULL DEFAULT 'system',
    title      VARCHAR(200) NOT NULL,
    message    TEXT         NOT NULL,
    link_url   VARCHAR(500),
    is_read    BOOLEAN      DEFAULT FALSE,
    read_at    TIMESTAMPTZ,
    created_at TIMESTAMPTZ  DEFAULT now(),
    created_by UUID,
    updated_at TIMESTAMPTZ  DEFAULT now(),
    updated_by UUID
);

CREATE TABLE widget_template (
    widget_id     SERIAL       PRIMARY KEY,
    widget_code   VARCHAR(30)  NOT NULL UNIQUE,
    widget_name   VARCHAR(100) NOT NULL,
    widget_type   VARCHAR(30)  NOT NULL,
    description   TEXT,
    config_json   JSONB,
    thumbnail_url VARCHAR(500),
    min_width     INT          DEFAULT 1,
    min_height    INT          DEFAULT 1,
    max_width     INT          DEFAULT 4,
    max_height    INT          DEFAULT 4,
    category      VARCHAR(30),
    is_active     BOOLEAN      DEFAULT TRUE,
    created_at    TIMESTAMPTZ  DEFAULT now(),
    created_by    UUID,
    updated_at    TIMESTAMPTZ  DEFAULT now(),
    updated_by    UUID
);

CREATE TABLE user_widget_layout (
    layout_id       SERIAL      PRIMARY KEY,
    user_id         UUID        NOT NULL REFERENCES user_account(user_id) ON DELETE CASCADE,
    widget_id       INT         NOT NULL REFERENCES widget_template(widget_id),
    position_x      INT         DEFAULT 0,
    position_y      INT         DEFAULT 0,
    width           INT         DEFAULT 1,
    height          INT         DEFAULT 1,
    config_override JSONB,
    is_visible      BOOLEAN     DEFAULT TRUE,
    sort_order      INT         DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT now(),
    created_by      UUID,
    updated_at      TIMESTAMPTZ DEFAULT now(),
    updated_by      UUID,
    UNIQUE (user_id, widget_id)
);

CREATE TABLE lineage_node (
    node_id     SERIAL       PRIMARY KEY,
    node_type   VARCHAR(20)  NOT NULL CHECK (node_type IN ('dataset','table','column','pipeline','system','product')),
    object_id   VARCHAR(100) NOT NULL,
    object_name VARCHAR(200) NOT NULL,
    description VARCHAR(300),
    metadata    JSONB,
    created_at  TIMESTAMPTZ  DEFAULT now(),
    created_by  UUID,
    updated_at  TIMESTAMPTZ  DEFAULT now(),
    updated_by  UUID,
    UNIQUE (node_type, object_id)
);

CREATE TABLE lineage_edge (
    edge_id        SERIAL      PRIMARY KEY,
    source_node_id INT         NOT NULL REFERENCES lineage_node(node_id) ON DELETE CASCADE,
    target_node_id INT         NOT NULL REFERENCES lineage_node(node_id) ON DELETE CASCADE,
    edge_type      VARCHAR(20) DEFAULT 'transform',
    transformation TEXT,
    pipeline_id    INT         REFERENCES pipeline(pipeline_id),
    created_at     TIMESTAMPTZ DEFAULT now(),
    created_by     UUID,
    updated_at     TIMESTAMPTZ DEFAULT now(),
    updated_by     UUID,
    UNIQUE (source_node_id, target_node_id, edge_type)
);

CREATE TABLE ai_chat_session (
    session_id    UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id       UUID         NOT NULL REFERENCES user_account(user_id),
    session_title VARCHAR(200),
    model_name    VARCHAR(50),
    message_count INT          DEFAULT 0,
    is_archived   BOOLEAN      DEFAULT FALSE,
    created_at    TIMESTAMPTZ  DEFAULT now(),
    created_by    UUID,
    updated_at    TIMESTAMPTZ  DEFAULT now(),
    updated_by    UUID
);

CREATE TABLE ai_chat_message (
    message_id   BIGSERIAL   PRIMARY KEY,
    session_id   UUID        NOT NULL REFERENCES ai_chat_session(session_id) ON DELETE CASCADE,
    role         VARCHAR(10) NOT NULL CHECK (role IN ('user','assistant','system')),
    message_text TEXT        NOT NULL,
    tokens_used  INT         DEFAULT 0,
    response_ms  INT         DEFAULT 0,
    metadata     JSONB,
    created_at   TIMESTAMPTZ DEFAULT now(),
    created_by   UUID,
    updated_at   TIMESTAMPTZ DEFAULT now(),
    updated_by   UUID
);

CREATE TABLE daily_dist_stats (
    stat_id         SERIAL       PRIMARY KEY,
    stat_date       DATE         NOT NULL DEFAULT CURRENT_DATE,
    product_id      UUID         REFERENCES data_product(product_id),
    total_calls     BIGINT       DEFAULT 0,
    success_calls   BIGINT       DEFAULT 0,
    fail_calls      BIGINT       DEFAULT 0,
    avg_response_ms INT          DEFAULT 0,
    unique_users    INT          DEFAULT 0,
    data_volume_mb  NUMERIC(12,2) DEFAULT 0,
    created_at      TIMESTAMPTZ  DEFAULT now(),
    created_by      UUID,
    updated_at      TIMESTAMPTZ  DEFAULT now(),
    updated_by      UUID,
    UNIQUE (stat_date, product_id)
);

CREATE TABLE dept_usage_stats (
    stat_id        SERIAL      PRIMARY KEY,
    stat_date      DATE        NOT NULL DEFAULT CURRENT_DATE,
    dept_id        INT         NOT NULL REFERENCES department(dept_id),
    dataset_count  INT         DEFAULT 0,
    api_calls      BIGINT      DEFAULT 0,
    download_count INT         DEFAULT 0,
    search_count   INT         DEFAULT 0,
    active_users   INT         DEFAULT 0,
    created_at     TIMESTAMPTZ DEFAULT now(),
    created_by     UUID,
    updated_at     TIMESTAMPTZ DEFAULT now(),
    updated_by     UUID,
    UNIQUE (stat_date, dept_id)
);

CREATE TABLE erp_sync_history (
    sync_id        SERIAL      PRIMARY KEY,
    sync_type      VARCHAR(30) NOT NULL,
    sync_direction VARCHAR(10) DEFAULT 'inbound',
    total_records  INT         DEFAULT 0,
    created_count  INT         DEFAULT 0,
    updated_count  INT         DEFAULT 0,
    skipped_count  INT         DEFAULT 0,
    error_count    INT         DEFAULT 0,
    started_at     TIMESTAMPTZ DEFAULT now(),
    finished_at    TIMESTAMPTZ,
    status         VARCHAR(20) DEFAULT 'running' CHECK (status IN ('running','success','failed','cancelled')),
    error_detail   TEXT,
    created_at     TIMESTAMPTZ DEFAULT now(),
    created_by     UUID,
    updated_at     TIMESTAMPTZ DEFAULT now(),
    updated_by     UUID
);


-- ============================================================================
-- 10. 인덱스
-- ============================================================================

CREATE INDEX idx_user_account_dept      ON user_account(dept_id);
CREATE INDEX idx_user_account_role      ON user_account(role_id);
CREATE INDEX idx_user_account_status    ON user_account(status);
CREATE INDEX idx_user_account_login     ON user_account(login_id);
CREATE INDEX idx_login_history_user     ON login_history(user_id, login_at DESC);
CREATE INDEX idx_dataset_domain         ON dataset(domain_id);
CREATE INDEX idx_dataset_system         ON dataset(system_id);
CREATE INDEX idx_dataset_security       ON dataset(security_level);
CREATE INDEX idx_dataset_status         ON dataset(status);
CREATE INDEX idx_dataset_owner_dept     ON dataset(owner_dept_id);
CREATE INDEX idx_dataset_name_gin       ON dataset USING gin(to_tsvector('simple', dataset_name));
CREATE INDEX idx_dataset_column_dataset ON dataset_column(dataset_id);
CREATE INDEX idx_dataset_tag_tag        ON dataset_tag(tag_id);
CREATE INDEX idx_bookmark_user          ON bookmark(user_id);
CREATE INDEX idx_glossary_term_domain   ON glossary_term(domain_id);
CREATE INDEX idx_glossary_term_status   ON glossary_term(status);
CREATE INDEX idx_pipeline_system        ON pipeline(system_id);
CREATE INDEX idx_pipeline_status        ON pipeline(status);
CREATE INDEX idx_pipeline_exec_pipe     ON pipeline_execution(pipeline_id, started_at DESC);
CREATE INDEX idx_pipeline_exec_status   ON pipeline_execution(status);
CREATE INDEX idx_data_product_domain    ON data_product(domain_id);
CREATE INDEX idx_data_product_status    ON data_product(status);
CREATE INDEX idx_api_key_user           ON api_key(user_id);
CREATE INDEX idx_api_key_product        ON api_key(product_id);
CREATE INDEX idx_data_request_user      ON data_request(user_id);
CREATE INDEX idx_data_request_status    ON data_request(approval_status);
CREATE INDEX idx_data_request_dataset   ON data_request(dataset_id);
CREATE INDEX idx_request_timeline_req   ON request_timeline(request_id, action_date DESC);
CREATE INDEX idx_dq_rule_dataset        ON dq_rule(dataset_id);
CREATE INDEX idx_dq_execution_rule      ON dq_execution(rule_id, execution_date DESC);
CREATE INDEX idx_dq_execution_dataset   ON dq_execution(dataset_id, execution_date DESC);
CREATE INDEX idx_quality_issue_dataset  ON quality_issue(dataset_id);
CREATE INDEX idx_quality_issue_status   ON quality_issue(status);
CREATE INDEX idx_domain_quality_date    ON domain_quality_score(score_date DESC);
CREATE INDEX idx_office_region          ON office(region_id);
CREATE INDEX idx_site_office            ON site(office_id);
CREATE INDEX idx_sensor_tag_site        ON sensor_tag(site_id);
CREATE INDEX idx_board_post_type        ON board_post(post_type, created_at DESC);
CREATE INDEX idx_board_post_user        ON board_post(user_id);
CREATE INDEX idx_board_comment_post     ON board_comment(post_id);
CREATE INDEX idx_audit_log_user         ON audit_log(user_id, created_at DESC);
CREATE INDEX idx_audit_log_action       ON audit_log(action_type, created_at DESC);
CREATE INDEX idx_audit_log_date         ON audit_log(created_at DESC);
CREATE INDEX idx_notification_user      ON notification(user_id, is_read, created_at DESC);
CREATE INDEX idx_lineage_edge_source    ON lineage_edge(source_node_id);
CREATE INDEX idx_lineage_edge_target    ON lineage_edge(target_node_id);
CREATE INDEX idx_ai_chat_session_user   ON ai_chat_session(user_id, created_at DESC);
CREATE INDEX idx_ai_chat_message_sess   ON ai_chat_message(session_id, created_at);
CREATE INDEX idx_daily_dist_stats_date  ON daily_dist_stats(stat_date DESC);
CREATE INDEX idx_dept_usage_stats_date  ON dept_usage_stats(stat_date DESC);


-- ============================================================================
-- 11. updated_at 자동 갱신 트리거
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOR tbl IN
        SELECT table_name FROM information_schema.columns
        WHERE table_schema = 'public' AND column_name = 'updated_at'
    LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_%s_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp()',
            tbl, tbl
        );
    END LOOP;
END;
$$;


-- ============================================================================
-- 12. 초기 데이터
-- ============================================================================

INSERT INTO role (role_code, role_name, role_group, role_level, data_clearance) VALUES
    ('STAFF_USER',     '일반사용자',         '수공직원',        1, 2),
    ('STAFF_DEPT_MGR', '부서관리자',         '수공직원',        2, 3),
    ('STAFF_STEWARD',  '데이터스튜어드',     '수공직원',        3, 4),
    ('PARTNER_VIEW',   '데이터조회',         '협력직원',        1, 1),
    ('PARTNER_DEV',    '외부개발자',         '협력직원',        1, 1),
    ('ENG_PIPELINE',   '파이프라인관리자',   '데이터엔지니어',  3, 4),
    ('ENG_ETL',        'ETL운영자',          '데이터엔지니어',  3, 4),
    ('ENG_DBA',        'DBA',                '데이터엔지니어',  3, 4),
    ('ADM_SYSTEM',     '시스템관리자',       '관리자',          5, 4),
    ('ADM_SECURITY',   '보안관리자',         '관리자',          5, 4),
    ('ADM_SUPER',      '슈퍼관리자',         '관리자',          6, 4);

INSERT INTO domain (domain_code, domain_name, color, icon) VALUES
    ('WATER',    '수자원',   '#3B82F6', 'droplet'),
    ('QUALITY',  '수질',     '#10B981', 'flask'),
    ('ENERGY',   '에너지',   '#F59E0B', 'zap'),
    ('INFRA',    '인프라',   '#8B5CF6', 'building'),
    ('CUSTOMER', '고객',     '#EF4444', 'users'),
    ('SAFETY',   '안전',     '#6366F1', 'shield'),
    ('FINANCE',  '경영관리', '#EC4899', 'briefcase');

INSERT INTO code_group (group_code, group_name, description) VALUES
    ('CD_REGION',         '유역코드',       '한강/낙동강/금강/영산강·섬진강 등'),
    ('CD_SECURITY_LEVEL', '보안등급',       '공개/내부일반/내부중요/기밀'),
    ('CD_ASSET_TYPE',     '데이터자산유형', '테이블/API/파일/뷰/스트림'),
    ('CD_COLLECT_METHOD', '수집방식',       'CDC/배치/API/파일/스트리밍/마이그레이션'),
    ('CD_DBMS_TYPE',      'DBMS유형',       'PostgreSQL/Oracle/MySQL/MSSQL/SAP_HANA'),
    ('CD_DQ_DIMENSION',   '품질차원',       '완전성/정확성/일관성/적시성/유효성/유일성'),
    ('CD_CHART_TYPE',     '차트유형',       'bar/line/pie/scatter/heatmap/map'),
    ('CD_BOARD_TYPE',     '게시판유형',     '공지사항/내부/외부'),
    ('CD_REQUEST_TYPE',   '신청유형',       '다운로드/API접근/공유/반출');
