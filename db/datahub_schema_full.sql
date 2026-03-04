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

COMMENT ON TABLE  dh.division IS '본부/권역 조직';
COMMENT ON COLUMN dh.division.division_id   IS '본부 일련번호 (PK)';
COMMENT ON COLUMN dh.division.division_name IS '본부명 (예: 경영관리본부, 수자원관리본부)';
COMMENT ON COLUMN dh.division.division_code IS '본부 코드 (고유)';
COMMENT ON COLUMN dh.division.sort_order    IS '정렬 순서';
COMMENT ON COLUMN dh.division.created_at    IS '등록일시';
COMMENT ON COLUMN dh.division.updated_at    IS '수정일시';

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

COMMENT ON TABLE  dh.department IS '부서/팀';
COMMENT ON COLUMN dh.department.dept_id     IS '부서 일련번호 (PK)';
COMMENT ON COLUMN dh.department.division_id IS '소속 본부 ID (FK→division)';
COMMENT ON COLUMN dh.department.dept_name   IS '부서명 (예: 수자원관리팀, 데이터분석팀)';
COMMENT ON COLUMN dh.department.dept_code   IS '부서 코드 (고유)';
COMMENT ON COLUMN dh.department.headcount   IS '소속 인원수';
COMMENT ON COLUMN dh.department.sort_order  IS '정렬 순서';
COMMENT ON COLUMN dh.department.created_at  IS '등록일시';
COMMENT ON COLUMN dh.department.updated_at  IS '수정일시';

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

COMMENT ON TABLE  dh.role IS '역할 정의 (RBAC)';
COMMENT ON COLUMN dh.role.role_id            IS '역할 일련번호 (PK)';
COMMENT ON COLUMN dh.role.role_code          IS '역할 코드 (예: super, sysadmin, steward, kwater)';
COMMENT ON COLUMN dh.role.role_name          IS '역할 한글명 (예: 슈퍼관리자, 데이터스튜어드)';
COMMENT ON COLUMN dh.role.role_level         IS '역할 수준 (0=슈퍼관리자 ~ 6=외부사용자)';
COMMENT ON COLUMN dh.role.data_clearance     IS '데이터 보안등급 접근허용 (public/internal/restricted/confidential)';
COMMENT ON COLUMN dh.role.session_timeout_min IS '세션 타임아웃 (분)';
COMMENT ON COLUMN dh.role.ip_range           IS '허용 IP 대역 (예: 10.0.0.0/8)';
COMMENT ON COLUMN dh.role.mfa_required       IS '다중인증(MFA) 필수 여부';
COMMENT ON COLUMN dh.role.auto_lock_after    IS '자동잠금 로그인 실패 횟수';
COMMENT ON COLUMN dh.role.pw_change_days     IS '비밀번호 변경 주기 (일)';
COMMENT ON COLUMN dh.role.description        IS '역할 설명';
COMMENT ON COLUMN dh.role.status             IS '상태 (active/inactive/pending/locked/deprecated)';
COMMENT ON COLUMN dh.role.created_at         IS '등록일시';
COMMENT ON COLUMN dh.role.updated_at         IS '수정일시';

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

COMMENT ON TABLE  dh.user_account IS '사용자 계정';
COMMENT ON COLUMN dh.user_account.user_id          IS '사용자 UUID (PK)';
COMMENT ON COLUMN dh.user_account.login_id         IS '로그인 ID (사번 또는 아이디)';
COMMENT ON COLUMN dh.user_account.user_name        IS '사용자명';
COMMENT ON COLUMN dh.user_account.email            IS '이메일 주소';
COMMENT ON COLUMN dh.user_account.phone            IS '휴대폰 번호';
COMMENT ON COLUMN dh.user_account.dept_id          IS '소속 부서 ID (FK→department)';
COMMENT ON COLUMN dh.user_account.role_id          IS '역할 ID (FK→role)';
COMMENT ON COLUMN dh.user_account.login_type       IS '로그인 유형 (sso/partner/engineer/admin)';
COMMENT ON COLUMN dh.user_account.status           IS '계정 상태 (active/inactive/pending/locked/deprecated)';
COMMENT ON COLUMN dh.user_account.last_login_at    IS '최종 로그인 일시';
COMMENT ON COLUMN dh.user_account.login_fail_count IS '로그인 연속 실패 횟수';
COMMENT ON COLUMN dh.user_account.pw_hash          IS '비밀번호 해시 (SSO 사용자는 NULL)';
COMMENT ON COLUMN dh.user_account.pw_changed_at    IS '비밀번호 최종 변경일시';
COMMENT ON COLUMN dh.user_account.created_at       IS '등록일시';
COMMENT ON COLUMN dh.user_account.updated_at       IS '수정일시';

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

COMMENT ON TABLE  dh.menu IS '메뉴/화면 정의 (사이드바 IA 구조)';
COMMENT ON COLUMN dh.menu.menu_id     IS '메뉴 일련번호 (PK)';
COMMENT ON COLUMN dh.menu.menu_code   IS '메뉴 코드 (예: home, cat-search, col-pipeline)';
COMMENT ON COLUMN dh.menu.menu_name   IS '메뉴 한글명';
COMMENT ON COLUMN dh.menu.parent_code IS '상위 메뉴 코드';
COMMENT ON COLUMN dh.menu.section     IS '섹션 구분 (통합대시보드/카탈로그/수집/유통/메타/커뮤니티/시스템)';
COMMENT ON COLUMN dh.menu.icon        IS '아이콘 (이모지)';
COMMENT ON COLUMN dh.menu.sort_order  IS '정렬 순서';
COMMENT ON COLUMN dh.menu.description IS '메뉴 설명';
COMMENT ON COLUMN dh.menu.created_at  IS '등록일시';

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

COMMENT ON TABLE  dh.role_menu_perm IS '역할별 메뉴 접근 권한 매트릭스 (RBAC)';
COMMENT ON COLUMN dh.role_menu_perm.role_id      IS '역할 ID (PK, FK→role)';
COMMENT ON COLUMN dh.role_menu_perm.menu_id      IS '메뉴 ID (PK, FK→menu)';
COMMENT ON COLUMN dh.role_menu_perm.can_read     IS '조회 권한';
COMMENT ON COLUMN dh.role_menu_perm.can_create   IS '등록 권한';
COMMENT ON COLUMN dh.role_menu_perm.can_update   IS '수정 권한';
COMMENT ON COLUMN dh.role_menu_perm.can_delete   IS '삭제 권한';
COMMENT ON COLUMN dh.role_menu_perm.can_approve  IS '승인 권한';
COMMENT ON COLUMN dh.role_menu_perm.can_download IS '다운로드 권한';

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

COMMENT ON TABLE  dh.domain IS '비즈니스 도메인 (수자원/수질/에너지/인프라/고객)';
COMMENT ON COLUMN dh.domain.domain_id   IS '도메인 일련번호 (PK)';
COMMENT ON COLUMN dh.domain.domain_code IS '도메인 코드 (water/quality/energy/infra/customer)';
COMMENT ON COLUMN dh.domain.domain_name IS '도메인 한글명 (수자원, 수질, 에너지 등)';
COMMENT ON COLUMN dh.domain.description IS '도메인 설명';
COMMENT ON COLUMN dh.domain.color       IS 'UI 표시 색상 (HEX, 예: #1890ff)';
COMMENT ON COLUMN dh.domain.icon        IS '아이콘 (이모지)';
COMMENT ON COLUMN dh.domain.sort_order  IS '정렬 순서';
COMMENT ON COLUMN dh.domain.created_at  IS '등록일시';

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

COMMENT ON TABLE  dh.source_system IS '원천/연계 시스템';
COMMENT ON COLUMN dh.source_system.system_id       IS '시스템 일련번호 (PK)';
COMMENT ON COLUMN dh.source_system.system_code     IS '시스템 코드 (RWIS, SAP, SCADA, KMA_API 등)';
COMMENT ON COLUMN dh.source_system.system_name     IS '시스템 한글명';
COMMENT ON COLUMN dh.source_system.system_type     IS '시스템 유형 (내부시스템/외부기관)';
COMMENT ON COLUMN dh.source_system.dbms_type       IS 'DBMS 유형 (SAP HANA/Oracle/PostgreSQL/티베로)';
COMMENT ON COLUMN dh.source_system.protocol        IS '통신 프로토콜 (REST/HTTPS, SFTP/SSH, TCP/Custom, JDBC)';
COMMENT ON COLUMN dh.source_system.network_zone    IS '네트워크 영역 (FA/OA/DMZ/IoT)';
COMMENT ON COLUMN dh.source_system.connection_info IS '접속정보 (JSON, 암호화 권장)';
COMMENT ON COLUMN dh.source_system.status          IS '시스템 상태';
COMMENT ON COLUMN dh.source_system.description     IS '시스템 설명';
COMMENT ON COLUMN dh.source_system.created_at      IS '등록일시';
COMMENT ON COLUMN dh.source_system.updated_at      IS '수정일시';

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

COMMENT ON TABLE  dh.dataset IS '데이터 자산/카탈로그 (통합 검색 대상)';
COMMENT ON COLUMN dh.dataset.dataset_id      IS '데이터셋 UUID (PK)';
COMMENT ON COLUMN dh.dataset.dataset_code    IS '데이터셋 코드 (예: ds-001)';
COMMENT ON COLUMN dh.dataset.table_name      IS '물리 테이블명 (예: TB_WATER_LEVEL)';
COMMENT ON COLUMN dh.dataset.dataset_name    IS '데이터셋 한글명 (예: 수위관측 데이터)';
COMMENT ON COLUMN dh.dataset.description     IS '데이터셋 설명';
COMMENT ON COLUMN dh.dataset.domain_id       IS '비즈니스 도메인 ID (FK→domain)';
COMMENT ON COLUMN dh.dataset.system_id       IS '원천시스템 ID (FK→source_system)';
COMMENT ON COLUMN dh.dataset.asset_type      IS '자산 유형 (table/api/file/view/stream)';
COMMENT ON COLUMN dh.dataset.collect_method  IS '수집 방식 (cdc/batch/api/file/streaming/migration)';
COMMENT ON COLUMN dh.dataset.security_level  IS '보안등급 (public/internal/restricted/confidential)';
COMMENT ON COLUMN dh.dataset.quality_score   IS '품질점수 (0.00~100.00)';
COMMENT ON COLUMN dh.dataset.row_count       IS '총 레코드 건수';
COMMENT ON COLUMN dh.dataset.column_count    IS '컬럼 수';
COMMENT ON COLUMN dh.dataset.storage_size_mb IS '저장 용량 (MB)';
COMMENT ON COLUMN dh.dataset.update_cycle    IS '갱신 주기 (실시간/1분/5분/1시간/일배치 등)';
COMMENT ON COLUMN dh.dataset.last_collected  IS '최종 수집 일시';
COMMENT ON COLUMN dh.dataset.owner_dept_id   IS '소유 부서 ID (FK→department)';
COMMENT ON COLUMN dh.dataset.steward_user_id IS '데이터 스튜어드 사용자 ID (FK→user_account)';
COMMENT ON COLUMN dh.dataset.is_certified    IS '인증 데이터셋 여부 (품질검증 통과)';
COMMENT ON COLUMN dh.dataset.is_popular      IS '인기 데이터셋 여부';
COMMENT ON COLUMN dh.dataset.view_count      IS '조회수';
COMMENT ON COLUMN dh.dataset.download_count  IS '다운로드 횟수';
COMMENT ON COLUMN dh.dataset.bookmark_count  IS '즐겨찾기 수';
COMMENT ON COLUMN dh.dataset.status          IS '데이터셋 상태 (active/inactive/pending/locked/deprecated)';
COMMENT ON COLUMN dh.dataset.created_at      IS '등록일시';
COMMENT ON COLUMN dh.dataset.updated_at      IS '수정일시';

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

COMMENT ON TABLE  dh.dataset_column IS '데이터셋 컬럼 스키마 및 프로파일링 정보';
COMMENT ON COLUMN dh.dataset_column.column_id      IS '컬럼 일련번호 (PK)';
COMMENT ON COLUMN dh.dataset_column.dataset_id     IS '데이터셋 ID (FK→dataset)';
COMMENT ON COLUMN dh.dataset_column.column_name    IS '컬럼 물리명 (영문)';
COMMENT ON COLUMN dh.dataset_column.column_name_ko IS '컬럼 한글명';
COMMENT ON COLUMN dh.dataset_column.data_type      IS '데이터 타입 (STRING/FLOAT/INT/TIMESTAMP/ENUM 등)';
COMMENT ON COLUMN dh.dataset_column.is_pk          IS 'PK 여부';
COMMENT ON COLUMN dh.dataset_column.is_fk          IS 'FK 여부';
COMMENT ON COLUMN dh.dataset_column.is_not_null    IS 'NOT NULL 제약 여부';
COMMENT ON COLUMN dh.dataset_column.std_term_id    IS '표준용어 ID (FK→glossary_term)';
COMMENT ON COLUMN dh.dataset_column.description    IS '컬럼 설명';
COMMENT ON COLUMN dh.dataset_column.sort_order     IS '정렬 순서';
COMMENT ON COLUMN dh.dataset_column.null_rate      IS 'NULL 비율 (%, 프로파일링)';
COMMENT ON COLUMN dh.dataset_column.unique_rate    IS '유니크 비율 (%, 프로파일링)';
COMMENT ON COLUMN dh.dataset_column.min_value      IS '최솟값 (프로파일링)';
COMMENT ON COLUMN dh.dataset_column.max_value      IS '최댓값 (프로파일링)';
COMMENT ON COLUMN dh.dataset_column.avg_value      IS '평균값 (프로파일링)';
COMMENT ON COLUMN dh.dataset_column.sample_values  IS '샘플 값 배열 (프로파일링)';
COMMENT ON COLUMN dh.dataset_column.created_at     IS '등록일시';
COMMENT ON COLUMN dh.dataset_column.updated_at     IS '수정일시';

CREATE INDEX idx_dscol_dataset ON dh.dataset_column(dataset_id);

-- 2-5. 태그 (Tag)
CREATE TABLE dh.tag (
    tag_id          SERIAL PRIMARY KEY,
    tag_name        VARCHAR(50) NOT NULL UNIQUE,
    tag_type        VARCHAR(20) DEFAULT 'keyword',   -- keyword, domain, business, security
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE  dh.tag IS '태그 (데이터셋 분류·검색용 키워드)';
COMMENT ON COLUMN dh.tag.tag_id     IS '태그 일련번호 (PK)';
COMMENT ON COLUMN dh.tag.tag_name   IS '태그명';
COMMENT ON COLUMN dh.tag.tag_type   IS '태그 유형 (keyword/domain/business/security)';
COMMENT ON COLUMN dh.tag.created_at IS '등록일시';

-- 2-6. 데이터셋-태그 관계 (Dataset ↔ Tag)
CREATE TABLE dh.dataset_tag (
    dataset_id      UUID NOT NULL REFERENCES dh.dataset(dataset_id) ON DELETE CASCADE,
    tag_id          INT  NOT NULL REFERENCES dh.tag(tag_id) ON DELETE CASCADE,
    PRIMARY KEY (dataset_id, tag_id)
);

COMMENT ON TABLE  dh.dataset_tag IS '데이터셋-태그 N:M 매핑';
COMMENT ON COLUMN dh.dataset_tag.dataset_id IS '데이터셋 ID (PK, FK→dataset)';
COMMENT ON COLUMN dh.dataset_tag.tag_id     IS '태그 ID (PK, FK→tag)';

-- 2-7. 즐겨찾기/보관함 (User Bookmark)
CREATE TABLE dh.bookmark (
    bookmark_id     SERIAL PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES dh.user_account(user_id),
    dataset_id      UUID NOT NULL REFERENCES dh.dataset(dataset_id),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, dataset_id)
);

COMMENT ON TABLE  dh.bookmark IS '사용자 즐겨찾기/보관함';
COMMENT ON COLUMN dh.bookmark.bookmark_id IS '즐겨찾기 일련번호 (PK)';
COMMENT ON COLUMN dh.bookmark.user_id     IS '사용자 ID (FK→user_account)';
COMMENT ON COLUMN dh.bookmark.dataset_id  IS '데이터셋 ID (FK→dataset)';
COMMENT ON COLUMN dh.bookmark.created_at  IS '등록일시';

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

COMMENT ON TABLE  dh.glossary_term IS '표준용어사전';
COMMENT ON COLUMN dh.glossary_term.term_id          IS '용어 일련번호 (PK)';
COMMENT ON COLUMN dh.glossary_term.term_name        IS '한글 표준용어명';
COMMENT ON COLUMN dh.glossary_term.term_name_en     IS '영문명 (CamelCase)';
COMMENT ON COLUMN dh.glossary_term.abbreviation     IS '약어';
COMMENT ON COLUMN dh.glossary_term.domain_id        IS '도메인 ID (FK→domain)';
COMMENT ON COLUMN dh.glossary_term.data_type        IS '표준 데이터타입 (NUMBER/VARCHAR/DATE/TIMESTAMP 등)';
COMMENT ON COLUMN dh.glossary_term.length_precision IS '길이/정밀도 (예: 10,2)';
COMMENT ON COLUMN dh.glossary_term.unit             IS '측정 단위 (m, m3/s, mg/L, NTU, MWh 등)';
COMMENT ON COLUMN dh.glossary_term.valid_range_min  IS '유효 범위 최솟값';
COMMENT ON COLUMN dh.glossary_term.valid_range_max  IS '유효 범위 최댓값';
COMMENT ON COLUMN dh.glossary_term.definition       IS '용어 정의';
COMMENT ON COLUMN dh.glossary_term.synonyms         IS '유사어 (쉼표 구분)';
COMMENT ON COLUMN dh.glossary_term.used_systems     IS '사용 시스템 목록';
COMMENT ON COLUMN dh.glossary_term.owner_name       IS '관리 담당자명';
COMMENT ON COLUMN dh.glossary_term.status           IS '승인 상태 (pending/approved/rejected/revision_needed/cancelled)';
COMMENT ON COLUMN dh.glossary_term.created_by       IS '등록자 ID (FK→user_account)';
COMMENT ON COLUMN dh.glossary_term.created_at       IS '등록일시';
COMMENT ON COLUMN dh.glossary_term.updated_at       IS '수정일시';

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

COMMENT ON TABLE  dh.glossary_history IS '표준용어 변경이력';
COMMENT ON COLUMN dh.glossary_history.history_id  IS '이력 일련번호 (PK)';
COMMENT ON COLUMN dh.glossary_history.term_id     IS '용어 ID (FK→glossary_term)';
COMMENT ON COLUMN dh.glossary_history.change_desc IS '변경 내용 설명';
COMMENT ON COLUMN dh.glossary_history.changed_by  IS '변경자 ID (FK→user_account)';
COMMENT ON COLUMN dh.glossary_history.prev_status IS '변경 전 상태';
COMMENT ON COLUMN dh.glossary_history.new_status  IS '변경 후 상태';
COMMENT ON COLUMN dh.glossary_history.changed_at  IS '변경일시';

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

COMMENT ON TABLE  dh.code_group IS '공통코드 그룹';
COMMENT ON COLUMN dh.code_group.group_id    IS '그룹 일련번호 (PK)';
COMMENT ON COLUMN dh.code_group.group_code  IS '그룹 코드 (예: CD_REGION, CD_DATA_TYPE)';
COMMENT ON COLUMN dh.code_group.group_name  IS '그룹명';
COMMENT ON COLUMN dh.code_group.description IS '그룹 설명';
COMMENT ON COLUMN dh.code_group.owner_name  IS '관리 담당자명';
COMMENT ON COLUMN dh.code_group.status      IS '상태';
COMMENT ON COLUMN dh.code_group.created_at  IS '등록일시';
COMMENT ON COLUMN dh.code_group.updated_at  IS '수정일시';

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

COMMENT ON TABLE  dh.code IS '공통코드 값';
COMMENT ON COLUMN dh.code.code_id     IS '코드 일련번호 (PK)';
COMMENT ON COLUMN dh.code.group_id    IS '코드그룹 ID (FK→code_group)';
COMMENT ON COLUMN dh.code.code_value  IS '코드 값 (예: RGN_HQ, RGN_SEL)';
COMMENT ON COLUMN dh.code.code_name   IS '코드명 (예: 본사, 수도권)';
COMMENT ON COLUMN dh.code.description IS '코드 설명';
COMMENT ON COLUMN dh.code.sort_order  IS '정렬 순서';
COMMENT ON COLUMN dh.code.status      IS '상태';
COMMENT ON COLUMN dh.code.created_at  IS '등록일시';

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

COMMENT ON TABLE  dh.data_model IS '데이터 모델 (논리모델/물리모델)';
COMMENT ON COLUMN dh.data_model.model_id           IS '모델 일련번호 (PK)';
COMMENT ON COLUMN dh.data_model.model_name         IS '모델명';
COMMENT ON COLUMN dh.data_model.model_type         IS '모델 유형 (logical/physical)';
COMMENT ON COLUMN dh.data_model.domain_id          IS '도메인 ID (FK→domain)';
COMMENT ON COLUMN dh.data_model.table_count        IS '테이블 수';
COMMENT ON COLUMN dh.data_model.column_count       IS '컬럼 수';
COMMENT ON COLUMN dh.data_model.version            IS '모델 버전';
COMMENT ON COLUMN dh.data_model.naming_compliance  IS '명명규칙 준수율 (%)';
COMMENT ON COLUMN dh.data_model.type_consistency   IS '타입 일관성 (%)';
COMMENT ON COLUMN dh.data_model.ref_integrity      IS '참조무결성 점수 (%)';
COMMENT ON COLUMN dh.data_model.index_coverage     IS '인덱스 커버리지 (%)';
COMMENT ON COLUMN dh.data_model.status             IS '승인 상태';
COMMENT ON COLUMN dh.data_model.owner_user_id      IS '모델 관리자 ID (FK→user_account)';
COMMENT ON COLUMN dh.data_model.description        IS '모델 설명';
COMMENT ON COLUMN dh.data_model.created_at         IS '등록일시';
COMMENT ON COLUMN dh.data_model.updated_at         IS '수정일시';

-- 2-13. 데이터모델 테이블 (Model Entity)
CREATE TABLE dh.model_entity (
    entity_id       SERIAL PRIMARY KEY,
    model_id        INT NOT NULL REFERENCES dh.data_model(model_id) ON DELETE CASCADE,
    entity_name     VARCHAR(100) NOT NULL,           -- 테이블/엔티티명
    entity_name_ko  VARCHAR(200),
    description     TEXT,
    sort_order      INT DEFAULT 0
);

COMMENT ON TABLE  dh.model_entity IS '데이터모델 엔티티(테이블)';
COMMENT ON COLUMN dh.model_entity.entity_id      IS '엔티티 일련번호 (PK)';
COMMENT ON COLUMN dh.model_entity.model_id       IS '모델 ID (FK→data_model)';
COMMENT ON COLUMN dh.model_entity.entity_name    IS '엔티티 물리명';
COMMENT ON COLUMN dh.model_entity.entity_name_ko IS '엔티티 한글명';
COMMENT ON COLUMN dh.model_entity.description    IS '엔티티 설명';
COMMENT ON COLUMN dh.model_entity.sort_order     IS '정렬 순서';

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

COMMENT ON TABLE  dh.model_attribute IS '데이터모델 속성(컬럼)';
COMMENT ON COLUMN dh.model_attribute.attribute_id IS '속성 일련번호 (PK)';
COMMENT ON COLUMN dh.model_attribute.entity_id    IS '엔티티 ID (FK→model_entity)';
COMMENT ON COLUMN dh.model_attribute.attr_name    IS '속성 물리명';
COMMENT ON COLUMN dh.model_attribute.attr_name_ko IS '속성 한글명';
COMMENT ON COLUMN dh.model_attribute.data_type    IS '데이터타입 (INT, VARCHAR(50), DECIMAL(12,2) 등)';
COMMENT ON COLUMN dh.model_attribute.is_pk        IS 'PK 여부';
COMMENT ON COLUMN dh.model_attribute.is_fk        IS 'FK 여부';
COMMENT ON COLUMN dh.model_attribute.fk_ref_entity IS 'FK 참조 대상 엔티티명';
COMMENT ON COLUMN dh.model_attribute.fk_ref_attr   IS 'FK 참조 대상 속성명';
COMMENT ON COLUMN dh.model_attribute.is_not_null   IS 'NOT NULL 제약 여부';
COMMENT ON COLUMN dh.model_attribute.sort_order    IS '정렬 순서';

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

COMMENT ON TABLE  dh.onto_class IS '온톨로지 클래스 (kw:Thing 트리 구조)';
COMMENT ON COLUMN dh.onto_class.class_id        IS '클래스 일련번호 (PK)';
COMMENT ON COLUMN dh.onto_class.class_name_ko   IS '클래스 한글명 (예: 댐, 정수장)';
COMMENT ON COLUMN dh.onto_class.class_name_en   IS '클래스 영문명 (예: Dam, WaterTreatmentPlant)';
COMMENT ON COLUMN dh.onto_class.class_uri       IS '클래스 URI (예: kw:Dam)';
COMMENT ON COLUMN dh.onto_class.parent_class_id IS '상위 클래스 ID (자기참조 FK)';
COMMENT ON COLUMN dh.onto_class.instance_count  IS '인스턴스(개체) 수';
COMMENT ON COLUMN dh.onto_class.description     IS '클래스 설명';
COMMENT ON COLUMN dh.onto_class.status          IS '상태';
COMMENT ON COLUMN dh.onto_class.created_by      IS '등록자 ID (FK→user_account)';
COMMENT ON COLUMN dh.onto_class.created_at      IS '등록일시';
COMMENT ON COLUMN dh.onto_class.updated_at      IS '수정일시';

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

COMMENT ON TABLE  dh.onto_data_property IS '온톨로지 데이터 속성 (DataProperty)';
COMMENT ON COLUMN dh.onto_data_property.property_id   IS '속성 일련번호 (PK)';
COMMENT ON COLUMN dh.onto_data_property.class_id      IS '소속 클래스 ID (FK→onto_class)';
COMMENT ON COLUMN dh.onto_data_property.property_name IS '속성명';
COMMENT ON COLUMN dh.onto_data_property.property_uri  IS '속성 URI';
COMMENT ON COLUMN dh.onto_data_property.data_type     IS 'XSD 데이터타입 (xsd:string/xsd:float 등)';
COMMENT ON COLUMN dh.onto_data_property.cardinality   IS '카디널리티 (0..1, 1..1, 0..*, 1..*)';
COMMENT ON COLUMN dh.onto_data_property.std_term_id   IS '표준용어 ID (FK→glossary_term)';
COMMENT ON COLUMN dh.onto_data_property.description   IS '속성 설명';
COMMENT ON COLUMN dh.onto_data_property.created_at    IS '등록일시';

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

COMMENT ON TABLE  dh.onto_relationship IS '온톨로지 클래스간 관계 (ObjectProperty)';
COMMENT ON COLUMN dh.onto_relationship.rel_id          IS '관계 일련번호 (PK)';
COMMENT ON COLUMN dh.onto_relationship.source_class_id IS '출발 클래스 ID (FK→onto_class)';
COMMENT ON COLUMN dh.onto_relationship.target_class_id IS '도착 클래스 ID (FK→onto_class)';
COMMENT ON COLUMN dh.onto_relationship.rel_name_ko     IS '관계 한글명';
COMMENT ON COLUMN dh.onto_relationship.rel_uri         IS '관계 URI (예: kw:hasDownstreamIntake)';
COMMENT ON COLUMN dh.onto_relationship.inverse_uri     IS '역관계 URI';
COMMENT ON COLUMN dh.onto_relationship.cardinality     IS '카디널리티';
COMMENT ON COLUMN dh.onto_relationship.direction       IS '방향 (output→, input←)';
COMMENT ON COLUMN dh.onto_relationship.description     IS '관계 설명';
COMMENT ON COLUMN dh.onto_relationship.created_at      IS '등록일시';

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

COMMENT ON TABLE  dh.pipeline IS '수집 파이프라인 (ETL/CDC/API/Streaming)';
COMMENT ON COLUMN dh.pipeline.pipeline_id   IS '파이프라인 일련번호 (PK)';
COMMENT ON COLUMN dh.pipeline.pipeline_name IS '파이프라인명';
COMMENT ON COLUMN dh.pipeline.system_id     IS '원천시스템 ID (FK→source_system)';
COMMENT ON COLUMN dh.pipeline.collect_method IS '수집 방식 (cdc/batch/api/file/streaming/migration)';
COMMENT ON COLUMN dh.pipeline.schedule      IS '실행 스케줄 (cron 표현식 또는 상시)';
COMMENT ON COLUMN dh.pipeline.target_storage IS '타겟 저장소 (예: PostgreSQL, HDFS)';
COMMENT ON COLUMN dh.pipeline.target_tables IS '대상 테이블 목록 (배열)';
COMMENT ON COLUMN dh.pipeline.throughput    IS '처리량 (예: 48.2K/일, 12K/분)';
COMMENT ON COLUMN dh.pipeline.owner_user_id IS '파이프라인 관리자 ID (FK→user_account)';
COMMENT ON COLUMN dh.pipeline.description   IS '파이프라인 설명';
COMMENT ON COLUMN dh.pipeline.status        IS '상태 (normal/delayed/error/stopped)';
COMMENT ON COLUMN dh.pipeline.last_run_at   IS '최종 실행 일시';
COMMENT ON COLUMN dh.pipeline.created_at    IS '등록일시';
COMMENT ON COLUMN dh.pipeline.updated_at    IS '수정일시';

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

COMMENT ON TABLE  dh.pipeline_execution IS '파이프라인 실행이력';
COMMENT ON COLUMN dh.pipeline_execution.execution_id  IS '실행 일련번호 (PK)';
COMMENT ON COLUMN dh.pipeline_execution.pipeline_id   IS '파이프라인 ID (FK→pipeline)';
COMMENT ON COLUMN dh.pipeline_execution.started_at    IS '실행 시작 일시';
COMMENT ON COLUMN dh.pipeline_execution.finished_at   IS '실행 완료 일시';
COMMENT ON COLUMN dh.pipeline_execution.duration_sec  IS '소요 시간 (초)';
COMMENT ON COLUMN dh.pipeline_execution.records_count IS '처리 건수';
COMMENT ON COLUMN dh.pipeline_execution.success_rate  IS '성공률 (%)';
COMMENT ON COLUMN dh.pipeline_execution.status        IS '결과 상태 (success/warning/failed)';
COMMENT ON COLUMN dh.pipeline_execution.error_message IS '오류 메시지';
COMMENT ON COLUMN dh.pipeline_execution.created_at    IS '등록일시';

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

COMMENT ON TABLE  dh.pipeline_column_mapping IS '파이프라인 소스-타겟 컬럼 매핑';
COMMENT ON COLUMN dh.pipeline_column_mapping.mapping_id     IS '매핑 일련번호 (PK)';
COMMENT ON COLUMN dh.pipeline_column_mapping.pipeline_id    IS '파이프라인 ID (FK→pipeline)';
COMMENT ON COLUMN dh.pipeline_column_mapping.source_column  IS '소스 컬럼명';
COMMENT ON COLUMN dh.pipeline_column_mapping.target_column  IS '타겟 컬럼명';
COMMENT ON COLUMN dh.pipeline_column_mapping.transform_rule IS '변환 규칙 (예: trim+uppercase, ISO8601→TIMESTAMP)';
COMMENT ON COLUMN dh.pipeline_column_mapping.is_required    IS '필수 매핑 여부';
COMMENT ON COLUMN dh.pipeline_column_mapping.sort_order     IS '정렬 순서';

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

COMMENT ON TABLE  dh.cdc_connector IS 'CDC 커넥터 현황 (Debezium, Oracle GoldenGate)';
COMMENT ON COLUMN dh.cdc_connector.connector_id   IS '커넥터 일련번호 (PK)';
COMMENT ON COLUMN dh.cdc_connector.system_id       IS '원천시스템 ID (FK→source_system)';
COMMENT ON COLUMN dh.cdc_connector.connector_name  IS '커넥터명 (예: cdc-sap-asset)';
COMMENT ON COLUMN dh.cdc_connector.dbms_type       IS 'DBMS 유형 (SAP HANA/ORACLE/티베로)';
COMMENT ON COLUMN dh.cdc_connector.table_count     IS '연계 테이블 수';
COMMENT ON COLUMN dh.cdc_connector.schema_count    IS '연계 스키마 수';
COMMENT ON COLUMN dh.cdc_connector.events_per_min  IS '분당 이벤트 수';
COMMENT ON COLUMN dh.cdc_connector.lag_seconds     IS '동기화 지연 시간 (초)';
COMMENT ON COLUMN dh.cdc_connector.today_count     IS '금일 처리 건수';
COMMENT ON COLUMN dh.cdc_connector.status          IS '상태 (normal/delayed/error)';
COMMENT ON COLUMN dh.cdc_connector.last_sync_at    IS '최종 동기화 일시';
COMMENT ON COLUMN dh.cdc_connector.created_at      IS '등록일시';
COMMENT ON COLUMN dh.cdc_connector.updated_at      IS '수정일시';

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

COMMENT ON TABLE  dh.kafka_topic IS 'Kafka 토픽 관리 (스트리밍 데이터)';
COMMENT ON COLUMN dh.kafka_topic.topic_id    IS '토픽 일련번호 (PK)';
COMMENT ON COLUMN dh.kafka_topic.topic_name  IS '토픽명';
COMMENT ON COLUMN dh.kafka_topic.partitions  IS '파티션 수';
COMMENT ON COLUMN dh.kafka_topic.replication IS '복제 팩터';
COMMENT ON COLUMN dh.kafka_topic.in_rate     IS '인입률 (messages/sec)';
COMMENT ON COLUMN dh.kafka_topic.out_rate    IS '소비율 (messages/sec)';
COMMENT ON COLUMN dh.kafka_topic.lag         IS '컨슈머 지연 (메시지 수)';
COMMENT ON COLUMN dh.kafka_topic.retention   IS '보존 기간 (예: 7d, 30d)';
COMMENT ON COLUMN dh.kafka_topic.status      IS '상태 (normal/warning/inactive)';
COMMENT ON COLUMN dh.kafka_topic.created_at  IS '등록일시';
COMMENT ON COLUMN dh.kafka_topic.updated_at  IS '수정일시';

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

COMMENT ON TABLE  dh.external_integration IS '외부기관 연계 (기상청, 환경부, 홍수통제소 등)';
COMMENT ON COLUMN dh.external_integration.integration_id  IS '연계 일련번호 (PK)';
COMMENT ON COLUMN dh.external_integration.system_name     IS '연계 시스템명';
COMMENT ON COLUMN dh.external_integration.organization    IS '연계 기관명';
COMMENT ON COLUMN dh.external_integration.method          IS '연계 방식 (REST API/SFTP/DB Link/양방향전송)';
COMMENT ON COLUMN dh.external_integration.protocol        IS '통신 프로토콜 (REST/HTTPS, SFTP/SSH, TCP/Custom)';
COMMENT ON COLUMN dh.external_integration.cycle           IS '연계 주기 (1시간/3시간/6시간/실시간)';
COMMENT ON COLUMN dh.external_integration.response_time_ms IS '평균 응답시간 (ms)';
COMMENT ON COLUMN dh.external_integration.today_count     IS '금일 처리 건수';
COMMENT ON COLUMN dh.external_integration.success_rate    IS '성공률 (%)';
COMMENT ON COLUMN dh.external_integration.status          IS '상태';
COMMENT ON COLUMN dh.external_integration.last_sync_at    IS '최종 연계 일시';
COMMENT ON COLUMN dh.external_integration.created_at      IS '등록일시';
COMMENT ON COLUMN dh.external_integration.updated_at      IS '수정일시';

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

COMMENT ON TABLE  dh.dbt_model IS 'dbt 변환 모델 (staging→intermediate→mart)';
COMMENT ON COLUMN dh.dbt_model.dbt_model_id       IS 'dbt 모델 일련번호 (PK)';
COMMENT ON COLUMN dh.dbt_model.model_name         IS '모델명';
COMMENT ON COLUMN dh.dbt_model.layer              IS '레이어 (staging/intermediate/mart)';
COMMENT ON COLUMN dh.dbt_model.source_name        IS '소스 참조명';
COMMENT ON COLUMN dh.dbt_model.transform_rule     IS '정제·변환 규칙';
COMMENT ON COLUMN dh.dbt_model.execution_time_sec IS '실행 소요시간 (초)';
COMMENT ON COLUMN dh.dbt_model.status             IS '상태 (success/warning/failed)';
COMMENT ON COLUMN dh.dbt_model.error_message      IS '오류 메시지';
COMMENT ON COLUMN dh.dbt_model.last_run_at        IS '최종 실행 일시';
COMMENT ON COLUMN dh.dbt_model.created_at         IS '등록일시';
COMMENT ON COLUMN dh.dbt_model.updated_at         IS '수정일시';

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

COMMENT ON TABLE  dh.server_inventory IS '서버 인프라 자원 목록';
COMMENT ON COLUMN dh.server_inventory.server_id      IS '서버 일련번호 (PK)';
COMMENT ON COLUMN dh.server_inventory.server_name    IS '서버명';
COMMENT ON COLUMN dh.server_inventory.layer          IS '계층 구분 (수집계/분석계/온톨로지/연계/서비스/카프카)';
COMMENT ON COLUMN dh.server_inventory.server_type    IS '서버 유형 (VM/PM/GM-GPU)';
COMMENT ON COLUMN dh.server_inventory.instance_count IS '인스턴스 수';
COMMENT ON COLUMN dh.server_inventory.cpu_spec       IS 'CPU 사양';
COMMENT ON COLUMN dh.server_inventory.memory_spec    IS '메모리 사양';
COMMENT ON COLUMN dh.server_inventory.disk_spec      IS '디스크 사양';
COMMENT ON COLUMN dh.server_inventory.gpu_spec       IS 'GPU 사양';
COMMENT ON COLUMN dh.server_inventory.status         IS '상태 (normal/maintenance/stopped)';
COMMENT ON COLUMN dh.server_inventory.created_at     IS '등록일시';
COMMENT ON COLUMN dh.server_inventory.updated_at     IS '수정일시';

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

COMMENT ON TABLE  dh.data_product IS '유통 Data Product (API/파일/스트림)';
COMMENT ON COLUMN dh.data_product.product_id     IS '상품 UUID (PK)';
COMMENT ON COLUMN dh.data_product.product_name   IS '상품명';
COMMENT ON COLUMN dh.data_product.domain_id      IS '도메인 ID (FK→domain)';
COMMENT ON COLUMN dh.data_product.format         IS '데이터 포맷 (JSON/CSV/Parquet/Excel)';
COMMENT ON COLUMN dh.data_product.security_level IS '보안등급';
COMMENT ON COLUMN dh.data_product.dist_status    IS '유통 상태 (active/preparing/restricted/paused/deprecated)';
COMMENT ON COLUMN dh.data_product.api_type       IS 'API 유형 (REST API/GraphQL/Kafka/gRPC/MCP/NGSI-LD)';
COMMENT ON COLUMN dh.data_product.refresh_cycle  IS '갱신 주기 (실시간/5분/30분/1시간/일배치/수동)';
COMMENT ON COLUMN dh.data_product.endpoint_path  IS 'API 엔드포인트 경로';
COMMENT ON COLUMN dh.data_product.auth_method    IS '인증 방식 (Bearer Token/API Key/OAuth 2.0/JWT)';
COMMENT ON COLUMN dh.data_product.rate_limit     IS '호출 제한 (예: 100 req/min)';
COMMENT ON COLUMN dh.data_product.daily_calls    IS '일 호출 건수';
COMMENT ON COLUMN dh.data_product.monthly_calls  IS '월 호출 건수';
COMMENT ON COLUMN dh.data_product.active_users   IS '활성 사용자 수';
COMMENT ON COLUMN dh.data_product.avg_latency_ms IS '평균 응답 지연 (ms)';
COMMENT ON COLUMN dh.data_product.uptime_pct     IS '가용률 (%)';
COMMENT ON COLUMN dh.data_product.source_datasets IS '소스 데이터셋 ID 배열';
COMMENT ON COLUMN dh.data_product.access_scope   IS '접근 범위 (all/dept_limited/approval_required/internal)';
COMMENT ON COLUMN dh.data_product.allowed_depts  IS '허용 부서 목록';
COMMENT ON COLUMN dh.data_product.log_policy     IS '로그 정책 (JSON: queryLog, downloadLog, statsLog)';
COMMENT ON COLUMN dh.data_product.owner_user_id  IS '관리자 ID (FK→user_account)';
COMMENT ON COLUMN dh.data_product.description    IS '상품 설명';
COMMENT ON COLUMN dh.data_product.created_at     IS '등록일시';
COMMENT ON COLUMN dh.data_product.updated_at     IS '수정일시';

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

COMMENT ON TABLE  dh.product_source IS 'Data Product 소스 데이터';
COMMENT ON COLUMN dh.product_source.source_id   IS '소스 일련번호 (PK)';
COMMENT ON COLUMN dh.product_source.product_id  IS '상품 ID (FK→data_product)';
COMMENT ON COLUMN dh.product_source.source_type IS '소스 유형 (Kafka/DB/API/File)';
COMMENT ON COLUMN dh.product_source.source_ref  IS '소스 참조 (토픽명/테이블명)';
COMMENT ON COLUMN dh.product_source.schema_type IS '스키마 유형 (AVRO/PostgreSQL/JSON)';
COMMENT ON COLUMN dh.product_source.description IS '소스 설명';

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

COMMENT ON TABLE  dh.product_field IS 'Data Product 응답 필드 정의';
COMMENT ON COLUMN dh.product_field.field_id    IS '필드 일련번호 (PK)';
COMMENT ON COLUMN dh.product_field.product_id  IS '상품 ID (FK→data_product)';
COMMENT ON COLUMN dh.product_field.field_name  IS '필드명';
COMMENT ON COLUMN dh.product_field.data_type   IS '데이터타입';
COMMENT ON COLUMN dh.product_field.is_required IS '필수 필드 여부';
COMMENT ON COLUMN dh.product_field.description IS '필드 설명';
COMMENT ON COLUMN dh.product_field.sort_order  IS '정렬 순서';

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

COMMENT ON TABLE  dh.api_key IS 'API Key 발급 및 관리';
COMMENT ON COLUMN dh.api_key.key_id          IS 'Key UUID (PK)';
COMMENT ON COLUMN dh.api_key.product_id      IS '상품 ID (FK→data_product)';
COMMENT ON COLUMN dh.api_key.user_id         IS '발급 사용자 ID (FK→user_account)';
COMMENT ON COLUMN dh.api_key.api_key         IS 'API Key 값 (고유)';
COMMENT ON COLUMN dh.api_key.api_secret_hash IS 'API Secret 해시값';
COMMENT ON COLUMN dh.api_key.permission      IS '권한 (READ/WRITE/ADMIN)';
COMMENT ON COLUMN dh.api_key.rate_limit      IS '호출 제한 (req/min)';
COMMENT ON COLUMN dh.api_key.issued_at       IS '발급일시';
COMMENT ON COLUMN dh.api_key.expires_at      IS '만료일시';
COMMENT ON COLUMN dh.api_key.is_active       IS '활성 여부';

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

COMMENT ON TABLE  dh.deidentify_policy IS '비식별화/가명처리 정책';
COMMENT ON COLUMN dh.deidentify_policy.policy_id       IS '정책 코드 (PK, 예: DI-POL-001)';
COMMENT ON COLUMN dh.deidentify_policy.policy_name     IS '정책명';
COMMENT ON COLUMN dh.deidentify_policy.technique       IS '비식별 기법 (masking/sha256/aes256/generalization/pseudonym/k_anonymity)';
COMMENT ON COLUMN dh.deidentify_policy.apply_level     IS '적용 보안등급';
COMMENT ON COLUMN dh.deidentify_policy.target_table    IS '대상 테이블명';
COMMENT ON COLUMN dh.deidentify_policy.processed_count IS '처리 완료 건수';
COMMENT ON COLUMN dh.deidentify_policy.success_rate    IS '처리 성공률 (%)';
COMMENT ON COLUMN dh.deidentify_policy.owner_user_id   IS '관리자 ID (FK→user_account)';
COMMENT ON COLUMN dh.deidentify_policy.status          IS '상태 (active/paused/disabled)';
COMMENT ON COLUMN dh.deidentify_policy.description     IS '정책 설명';
COMMENT ON COLUMN dh.deidentify_policy.created_at      IS '등록일시';
COMMENT ON COLUMN dh.deidentify_policy.updated_at      IS '수정일시';

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

COMMENT ON TABLE  dh.deidentify_rule IS '비식별화 필드별 규칙';
COMMENT ON COLUMN dh.deidentify_rule.rule_id         IS '규칙 일련번호 (PK)';
COMMENT ON COLUMN dh.deidentify_rule.policy_id       IS '정책 ID (FK→deidentify_policy)';
COMMENT ON COLUMN dh.deidentify_rule.target_field    IS '대상 필드명';
COMMENT ON COLUMN dh.deidentify_rule.field_type      IS '필드 데이터타입';
COMMENT ON COLUMN dh.deidentify_rule.masking_pattern IS '마스킹 패턴 (부분마스킹/중간마스킹/일반화 등)';
COMMENT ON COLUMN dh.deidentify_rule.example_before  IS '적용 전 예시';
COMMENT ON COLUMN dh.deidentify_rule.example_after   IS '적용 후 예시';
COMMENT ON COLUMN dh.deidentify_rule.sort_order      IS '정렬 순서';

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

COMMENT ON TABLE  dh.data_request IS '데이터 활용 신청/승인 (6단계 워크플로우)';
COMMENT ON COLUMN dh.data_request.request_id        IS '신청번호 (PK, 예: WF-089, AP-056)';
COMMENT ON COLUMN dh.data_request.request_type      IS '신청 유형 (usage/permission/quality_report/meta_edit/api/download/kafka)';
COMMENT ON COLUMN dh.data_request.title             IS '신청 제목';
COMMENT ON COLUMN dh.data_request.description       IS '신청 상세 설명';
COMMENT ON COLUMN dh.data_request.target_dataset_id IS '대상 데이터셋 ID (FK→dataset)';
COMMENT ON COLUMN dh.data_request.target_data_name  IS '대상 데이터명';
COMMENT ON COLUMN dh.data_request.security_level    IS '데이터 보안등급';
COMMENT ON COLUMN dh.data_request.priority          IS '우선순위 (normal/high/low)';
COMMENT ON COLUMN dh.data_request.usage_type        IS '활용 목적 (분석리포트/시스템연계/AI·ML/연구학술/업무자동화)';
COMMENT ON COLUMN dh.data_request.delivery_method   IS '제공 방식 (API/file_download/db_readonly/streaming/sandbox)';
COMMENT ON COLUMN dh.data_request.usage_start_dt    IS '활용 시작일';
COMMENT ON COLUMN dh.data_request.usage_end_dt      IS '활용 종료일';
COMMENT ON COLUMN dh.data_request.requester_id      IS '신청자 ID (FK→user_account)';
COMMENT ON COLUMN dh.data_request.handler_id        IS '처리자 ID (FK→user_account)';
COMMENT ON COLUMN dh.data_request.current_step      IS '현재 단계 (1~6)';
COMMENT ON COLUMN dh.data_request.status            IS '승인 상태 (pending/approved/rejected/revision_needed/cancelled)';
COMMENT ON COLUMN dh.data_request.reject_reason     IS '반려 사유';
COMMENT ON COLUMN dh.data_request.created_at        IS '신청일시';
COMMENT ON COLUMN dh.data_request.updated_at        IS '수정일시';

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

COMMENT ON TABLE  dh.request_attachment IS '데이터 신청 첨부파일';
COMMENT ON COLUMN dh.request_attachment.attachment_id  IS '첨부파일 일련번호 (PK)';
COMMENT ON COLUMN dh.request_attachment.request_id     IS '신청번호 (FK→data_request)';
COMMENT ON COLUMN dh.request_attachment.file_name      IS '파일명';
COMMENT ON COLUMN dh.request_attachment.file_type      IS '파일 유형 (PDF/DOCX/XLSX/HWP)';
COMMENT ON COLUMN dh.request_attachment.file_size_bytes IS '파일 크기 (bytes)';
COMMENT ON COLUMN dh.request_attachment.file_path      IS '파일 저장 경로';
COMMENT ON COLUMN dh.request_attachment.uploaded_at    IS '업로드 일시';

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

COMMENT ON TABLE  dh.request_timeline IS '데이터 신청 처리이력 (단계별 타임라인)';
COMMENT ON COLUMN dh.request_timeline.timeline_id IS '이력 일련번호 (PK)';
COMMENT ON COLUMN dh.request_timeline.request_id  IS '신청번호 (FK→data_request)';
COMMENT ON COLUMN dh.request_timeline.step        IS '처리 단계 (1~6)';
COMMENT ON COLUMN dh.request_timeline.step_name   IS '단계명 (예: 신청접수, 데이터스튜어드검토, 보안팀심사)';
COMMENT ON COLUMN dh.request_timeline.action_desc IS '처리 내용';
COMMENT ON COLUMN dh.request_timeline.actor_id    IS '처리자 ID (FK→user_account)';
COMMENT ON COLUMN dh.request_timeline.actor_name  IS '처리자명';
COMMENT ON COLUMN dh.request_timeline.status      IS '처리 결과';
COMMENT ON COLUMN dh.request_timeline.created_at  IS '처리일시';

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

COMMENT ON TABLE  dh.chart_content IS '시각화 차트 콘텐츠 관리';
COMMENT ON COLUMN dh.chart_content.chart_id       IS '차트 코드 (PK, 예: CHT-001)';
COMMENT ON COLUMN dh.chart_content.chart_name     IS '차트명';
COMMENT ON COLUMN dh.chart_content.domain_id      IS '도메인 ID (FK→domain)';
COMMENT ON COLUMN dh.chart_content.chart_type     IS '차트 유형 (line/bar/area/pie/gauge/heatmap/donut/table)';
COMMENT ON COLUMN dh.chart_content.data_level     IS '데이터 보안등급';
COMMENT ON COLUMN dh.chart_content.visibility     IS '공개 범위 (public/internal/confidential)';
COMMENT ON COLUMN dh.chart_content.description    IS '차트 설명';
COMMENT ON COLUMN dh.chart_content.config_json    IS '차트 설정 (JSON)';
COMMENT ON COLUMN dh.chart_content.author_id      IS '작성자 ID (FK→user_account)';
COMMENT ON COLUMN dh.chart_content.like_count     IS '좋아요 수';
COMMENT ON COLUMN dh.chart_content.is_recommended IS '추천 콘텐츠 여부';
COMMENT ON COLUMN dh.chart_content.is_popular     IS '인기 콘텐츠 여부';
COMMENT ON COLUMN dh.chart_content.created_at     IS '등록일시';
COMMENT ON COLUMN dh.chart_content.updated_at     IS '수정일시';

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

COMMENT ON TABLE  dh.external_provision IS '외부시스템 데이터 제공 (디지털트윈 등)';
COMMENT ON COLUMN dh.external_provision.provision_id  IS '제공 일련번호 (PK)';
COMMENT ON COLUMN dh.external_provision.target_name   IS '제공 대상 시스템명 (예: 정수장 디지털트윈)';
COMMENT ON COLUMN dh.external_provision.provided_data IS '제공 데이터 항목';
COMMENT ON COLUMN dh.external_provision.api_method    IS 'API 방식 (REST/Kafka/REST+Kafka)';
COMMENT ON COLUMN dh.external_provision.daily_calls   IS '일 호출 건수';
COMMENT ON COLUMN dh.external_provision.sla_pct       IS 'SLA 달성률 (%)';
COMMENT ON COLUMN dh.external_provision.status        IS '상태';
COMMENT ON COLUMN dh.external_provision.created_at    IS '등록일시';
COMMENT ON COLUMN dh.external_provision.updated_at    IS '수정일시';

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

COMMENT ON TABLE  dh.dq_rule IS 'DQ 검증 규칙 (완전성/유효성/정합성/적시성/유일성)';
COMMENT ON COLUMN dh.dq_rule.rule_id         IS '규칙 일련번호 (PK)';
COMMENT ON COLUMN dh.dq_rule.rule_name       IS '규칙명';
COMMENT ON COLUMN dh.dq_rule.dataset_id      IS '대상 데이터셋 ID (FK→dataset)';
COMMENT ON COLUMN dh.dq_rule.dimension       IS '품질 차원 (completeness/validity/consistency/timeliness/uniqueness)';
COMMENT ON COLUMN dh.dq_rule.rule_expression IS '규칙 표현식 (SQL 또는 조건식)';
COMMENT ON COLUMN dh.dq_rule.threshold       IS '임계값 (%)';
COMMENT ON COLUMN dh.dq_rule.severity        IS '심각도 (critical/high/medium/low)';
COMMENT ON COLUMN dh.dq_rule.is_active       IS '활성 여부';
COMMENT ON COLUMN dh.dq_rule.created_by      IS '등록자 ID (FK→user_account)';
COMMENT ON COLUMN dh.dq_rule.created_at      IS '등록일시';
COMMENT ON COLUMN dh.dq_rule.updated_at      IS '수정일시';

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

COMMENT ON TABLE  dh.dq_execution IS 'DQ 검증 실행 결과';
COMMENT ON COLUMN dh.dq_execution.execution_id    IS '실행 일련번호 (PK)';
COMMENT ON COLUMN dh.dq_execution.rule_id         IS '규칙 ID (FK→dq_rule)';
COMMENT ON COLUMN dh.dq_execution.dataset_id      IS '대상 데이터셋 ID (FK→dataset)';
COMMENT ON COLUMN dh.dq_execution.executed_at      IS '검증 실행 일시';
COMMENT ON COLUMN dh.dq_execution.total_rows       IS '전체 행 수';
COMMENT ON COLUMN dh.dq_execution.passed_rows      IS '통과 행 수';
COMMENT ON COLUMN dh.dq_execution.failed_rows      IS '실패 행 수';
COMMENT ON COLUMN dh.dq_execution.pass_rate        IS '통과율 (%)';
COMMENT ON COLUMN dh.dq_execution.status           IS '결과 상태 (passed/warning/failed)';
COMMENT ON COLUMN dh.dq_execution.violation_detail IS '위반 상세 정보 (JSON)';
COMMENT ON COLUMN dh.dq_execution.created_at       IS '등록일시';

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

COMMENT ON TABLE  dh.domain_quality_score IS '도메인별 6대 품질지표 일별 점수';
COMMENT ON COLUMN dh.domain_quality_score.score_id     IS '점수 일련번호 (PK)';
COMMENT ON COLUMN dh.domain_quality_score.domain_id    IS '도메인 ID (FK→domain)';
COMMENT ON COLUMN dh.domain_quality_score.score_date   IS '평가 일자';
COMMENT ON COLUMN dh.domain_quality_score.completeness IS '완전성 점수 (%)';
COMMENT ON COLUMN dh.domain_quality_score.validity     IS '유효성 점수 (%)';
COMMENT ON COLUMN dh.domain_quality_score.consistency  IS '정합성 점수 (%)';
COMMENT ON COLUMN dh.domain_quality_score.timeliness   IS '적시성 점수 (%)';
COMMENT ON COLUMN dh.domain_quality_score.accuracy     IS '정확성 점수 (%)';
COMMENT ON COLUMN dh.domain_quality_score.uniqueness   IS '유일성 점수 (%)';
COMMENT ON COLUMN dh.domain_quality_score.overall_dqi  IS '종합 DQI 점수 (%)';
COMMENT ON COLUMN dh.domain_quality_score.created_at   IS '등록일시';

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

COMMENT ON TABLE  dh.quality_issue IS '데이터 품질 이슈';
COMMENT ON COLUMN dh.quality_issue.issue_id        IS '이슈 일련번호 (PK)';
COMMENT ON COLUMN dh.quality_issue.dataset_id      IS '데이터셋 ID (FK→dataset)';
COMMENT ON COLUMN dh.quality_issue.dimension       IS '품질 차원';
COMMENT ON COLUMN dh.quality_issue.error_type      IS '오류 유형 (중복 레코드, FK 참조 무결성 위반 등)';
COMMENT ON COLUMN dh.quality_issue.violation_count IS '위반 건수';
COMMENT ON COLUMN dh.quality_issue.sla_status      IS 'SLA 상태 (on_track/delayed/resolved)';
COMMENT ON COLUMN dh.quality_issue.assignee_id     IS '담당자 ID (FK→user_account)';
COMMENT ON COLUMN dh.quality_issue.occurred_at     IS '발생 일시';
COMMENT ON COLUMN dh.quality_issue.resolved_at     IS '해결 일시';
COMMENT ON COLUMN dh.quality_issue.created_at      IS '등록일시';

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

COMMENT ON TABLE  dh.region IS '유역/지사 (충청지역지사, 한강권역본부 등)';
COMMENT ON COLUMN dh.region.region_id    IS '유역 일련번호 (PK)';
COMMENT ON COLUMN dh.region.region_name  IS '유역/지사명';
COMMENT ON COLUMN dh.region.region_code  IS '유역 코드 (고유)';
COMMENT ON COLUMN dh.region.office_count IS '소속 사무소 수';
COMMENT ON COLUMN dh.region.site_count   IS '소속 사업장 수';
COMMENT ON COLUMN dh.region.tag_count    IS '소속 태그 수';
COMMENT ON COLUMN dh.region.collect_rate IS '수집률 (%)';
COMMENT ON COLUMN dh.region.created_at   IS '등록일시';
COMMENT ON COLUMN dh.region.updated_at   IS '수정일시';

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

COMMENT ON TABLE  dh.office IS '사무소/관리단';
COMMENT ON COLUMN dh.office.office_id     IS '사무소 일련번호 (PK)';
COMMENT ON COLUMN dh.office.region_id     IS '유역 ID (FK→region)';
COMMENT ON COLUMN dh.office.office_name   IS '사무소명';
COMMENT ON COLUMN dh.office.site_count    IS '소속 사업장 수';
COMMENT ON COLUMN dh.office.tag_count     IS '소속 태그 수';
COMMENT ON COLUMN dh.office.total_records IS '총 데이터 건수';
COMMENT ON COLUMN dh.office.data_start_dt IS '데이터 시작일';
COMMENT ON COLUMN dh.office.data_end_dt   IS '데이터 종료일';
COMMENT ON COLUMN dh.office.created_at    IS '등록일시';
COMMENT ON COLUMN dh.office.updated_at    IS '수정일시';

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

COMMENT ON TABLE  dh.site IS '사업장 (정수장, 가압장, 댐, 관측소 등)';
COMMENT ON COLUMN dh.site.site_id        IS '사업장 일련번호 (PK)';
COMMENT ON COLUMN dh.site.office_id      IS '사무소 ID (FK→office)';
COMMENT ON COLUMN dh.site.site_name      IS '사업장명';
COMMENT ON COLUMN dh.site.site_code      IS '사업장 코드';
COMMENT ON COLUMN dh.site.site_type      IS '사업장 유형 (정수장/가압장/댐/보 등)';
COMMENT ON COLUMN dh.site.tag_count      IS '전체 태그 수';
COMMENT ON COLUMN dh.site.collect_tags   IS '수집 중 태그 수';
COMMENT ON COLUMN dh.site.uncollect_tags IS '미수집 태그 수';
COMMENT ON COLUMN dh.site.collect_rate   IS '수집률 (%)';
COMMENT ON COLUMN dh.site.data_count     IS '데이터 건수';
COMMENT ON COLUMN dh.site.status         IS '상태 (normal/warning/error)';
COMMENT ON COLUMN dh.site.created_at     IS '등록일시';
COMMENT ON COLUMN dh.site.updated_at     IS '수정일시';

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

COMMENT ON TABLE  dh.sensor_tag IS '계측 센서 태그 (SCADA/IoT 계측점)';
COMMENT ON COLUMN dh.sensor_tag.tag_id        IS '태그 일련번호 (PK)';
COMMENT ON COLUMN dh.sensor_tag.site_id       IS '사업장 ID (FK→site)';
COMMENT ON COLUMN dh.sensor_tag.tag_name      IS '태그명';
COMMENT ON COLUMN dh.sensor_tag.tag_code      IS '태그 코드';
COMMENT ON COLUMN dh.sensor_tag.tag_type      IS '태그 유형 (수위/유량/수질/압력/온도 등)';
COMMENT ON COLUMN dh.sensor_tag.category      IS '분류';
COMMENT ON COLUMN dh.sensor_tag.supplier      IS '공급업체';
COMMENT ON COLUMN dh.sensor_tag.unit          IS '측정 단위';
COMMENT ON COLUMN dh.sensor_tag.section       IS '구간/위치';
COMMENT ON COLUMN dh.sensor_tag.description   IS '태그 설명';
COMMENT ON COLUMN dh.sensor_tag.is_collecting IS '수집 중 여부';
COMMENT ON COLUMN dh.sensor_tag.data_count    IS '데이터 건수';
COMMENT ON COLUMN dh.sensor_tag.validity_rate IS '유효율 (%)';
COMMENT ON COLUMN dh.sensor_tag.status        IS '상태 (normal/warning/error)';
COMMENT ON COLUMN dh.sensor_tag.created_at    IS '등록일시';
COMMENT ON COLUMN dh.sensor_tag.updated_at    IS '수정일시';

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

COMMENT ON TABLE  dh.asset_database IS '자산DB 모니터링 (자산DB, 시설DB, 수질DB 등)';
COMMENT ON COLUMN dh.asset_database.asset_db_id     IS '자산DB 일련번호 (PK)';
COMMENT ON COLUMN dh.asset_database.db_name         IS 'DB명';
COMMENT ON COLUMN dh.asset_database.db_system       IS 'DB 시스템 (SAP ECC/SAP PM/Oracle 19c 등)';
COMMENT ON COLUMN dh.asset_database.cdc_method      IS 'CDC 방식 (Debezium/Oracle GoldenGate/REST API)';
COMMENT ON COLUMN dh.asset_database.table_count     IS '테이블 수';
COMMENT ON COLUMN dh.asset_database.endpoint_count  IS 'API 엔드포인트 수';
COMMENT ON COLUMN dh.asset_database.daily_collect   IS '일 수집 건수';
COMMENT ON COLUMN dh.asset_database.cdc_lag_sec     IS 'CDC 지연 시간 (초)';
COMMENT ON COLUMN dh.asset_database.cdc_sync_pct    IS 'CDC 동기화율 (%)';
COMMENT ON COLUMN dh.asset_database.storage_used_tb IS '사용 저장용량 (TB)';
COMMENT ON COLUMN dh.asset_database.storage_alloc_tb IS '할당 저장용량 (TB)';
COMMENT ON COLUMN dh.asset_database.status          IS '상태 (normal/delayed/error)';
COMMENT ON COLUMN dh.asset_database.last_sync_at    IS '최종 동기화 일시';
COMMENT ON COLUMN dh.asset_database.created_at      IS '등록일시';
COMMENT ON COLUMN dh.asset_database.updated_at      IS '수정일시';

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

COMMENT ON TABLE  dh.board_post IS '게시판 (공지사항/내부게시판/외부게시판)';
COMMENT ON COLUMN dh.board_post.post_id       IS '게시글 일련번호 (PK)';
COMMENT ON COLUMN dh.board_post.board_type    IS '게시판 유형 (notice/internal/external)';
COMMENT ON COLUMN dh.board_post.category      IS '카테고리 (시스템안내/데이터정책/기술Q&A/API문의 등)';
COMMENT ON COLUMN dh.board_post.title         IS '제목';
COMMENT ON COLUMN dh.board_post.content       IS '본문 내용';
COMMENT ON COLUMN dh.board_post.author_id     IS '작성자 ID (FK→user_account)';
COMMENT ON COLUMN dh.board_post.author_org    IS '소속 기관 (외부게시판용)';
COMMENT ON COLUMN dh.board_post.is_pinned     IS '상단 고정 여부';
COMMENT ON COLUMN dh.board_post.is_urgent     IS '긴급 공지 여부';
COMMENT ON COLUMN dh.board_post.view_count    IS '조회수';
COMMENT ON COLUMN dh.board_post.comment_count IS '댓글 수';
COMMENT ON COLUMN dh.board_post.status        IS '상태 (active/answered/closed/deleted)';
COMMENT ON COLUMN dh.board_post.created_at    IS '등록일시';
COMMENT ON COLUMN dh.board_post.updated_at    IS '수정일시';

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

COMMENT ON TABLE  dh.board_comment IS '게시판 댓글';
COMMENT ON COLUMN dh.board_comment.comment_id        IS '댓글 일련번호 (PK)';
COMMENT ON COLUMN dh.board_comment.post_id           IS '게시글 ID (FK→board_post)';
COMMENT ON COLUMN dh.board_comment.parent_comment_id IS '상위 댓글 ID (대댓글, 자기참조 FK)';
COMMENT ON COLUMN dh.board_comment.content           IS '댓글 내용';
COMMENT ON COLUMN dh.board_comment.author_id         IS '작성자 ID (FK→user_account)';
COMMENT ON COLUMN dh.board_comment.created_at        IS '등록일시';

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

COMMENT ON TABLE  dh.resource_archive IS '자료실 (가이드, 교육자료, 양식 등)';
COMMENT ON COLUMN dh.resource_archive.resource_id    IS '자료 일련번호 (PK)';
COMMENT ON COLUMN dh.resource_archive.category       IS '카테고리 (가이드매뉴얼/교육자료/정책규정/양식서식/기술문서)';
COMMENT ON COLUMN dh.resource_archive.title          IS '자료명';
COMMENT ON COLUMN dh.resource_archive.description    IS '자료 설명';
COMMENT ON COLUMN dh.resource_archive.file_name      IS '파일명';
COMMENT ON COLUMN dh.resource_archive.file_type      IS '파일 유형 (PDF/XLSX/HWP/DOCX/PPTX)';
COMMENT ON COLUMN dh.resource_archive.file_size_bytes IS '파일 크기 (bytes)';
COMMENT ON COLUMN dh.resource_archive.file_path      IS '파일 저장 경로';
COMMENT ON COLUMN dh.resource_archive.author_id      IS '작성자 ID (FK→user_account)';
COMMENT ON COLUMN dh.resource_archive.download_count IS '다운로드 횟수';
COMMENT ON COLUMN dh.resource_archive.created_at     IS '등록일시';
COMMENT ON COLUMN dh.resource_archive.updated_at     IS '수정일시';

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

COMMENT ON TABLE  dh.security_policy IS '데이터등급 보안정책 규칙';
COMMENT ON COLUMN dh.security_policy.policy_id       IS '정책 일련번호 (PK)';
COMMENT ON COLUMN dh.security_policy.policy_name     IS '정책명';
COMMENT ON COLUMN dh.security_policy.data_level      IS '적용 보안등급';
COMMENT ON COLUMN dh.security_policy.asset_type      IS '적용 자산 유형';
COMMENT ON COLUMN dh.security_policy.rule_expression IS '정책 규칙 표현식';
COMMENT ON COLUMN dh.security_policy.is_active       IS '활성 여부';
COMMENT ON COLUMN dh.security_policy.created_by      IS '등록자 ID (FK→user_account)';
COMMENT ON COLUMN dh.security_policy.created_at      IS '등록일시';
COMMENT ON COLUMN dh.security_policy.updated_at      IS '수정일시';

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

COMMENT ON TABLE  dh.system_interface IS '연계 인터페이스 모니터링';
COMMENT ON COLUMN dh.system_interface.interface_id   IS '인터페이스 일련번호 (PK)';
COMMENT ON COLUMN dh.system_interface.interface_name IS '인터페이스명';
COMMENT ON COLUMN dh.system_interface.system_id      IS '시스템 ID (FK→source_system)';
COMMENT ON COLUMN dh.system_interface.direction      IS '방향 (inbound/outbound/bidirectional)';
COMMENT ON COLUMN dh.system_interface.protocol       IS '통신 프로토콜';
COMMENT ON COLUMN dh.system_interface.endpoint_url   IS '엔드포인트 URL';
COMMENT ON COLUMN dh.system_interface.avg_response_ms IS '평균 응답시간 (ms)';
COMMENT ON COLUMN dh.system_interface.success_rate   IS '성공률 (%)';
COMMENT ON COLUMN dh.system_interface.daily_calls    IS '일 호출 건수';
COMMENT ON COLUMN dh.system_interface.error_rate     IS '오류율 (%)';
COMMENT ON COLUMN dh.system_interface.status         IS '상태';
COMMENT ON COLUMN dh.system_interface.created_at     IS '등록일시';
COMMENT ON COLUMN dh.system_interface.updated_at     IS '수정일시';

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

COMMENT ON TABLE  dh.audit_log IS '접속통계 및 감사로그 (전 활동 기록)';
COMMENT ON COLUMN dh.audit_log.log_id        IS '로그 일련번호 (PK)';
COMMENT ON COLUMN dh.audit_log.user_id       IS '사용자 ID (FK→user_account)';
COMMENT ON COLUMN dh.audit_log.user_name     IS '사용자명 (비정규화)';
COMMENT ON COLUMN dh.audit_log.action_type   IS '활동 유형 (data/collect/distribute/access/system/permission/batch)';
COMMENT ON COLUMN dh.audit_log.action_detail IS '활동 상세 내용';
COMMENT ON COLUMN dh.audit_log.target_entity IS '대상 엔티티 (테이블/화면/API)';
COMMENT ON COLUMN dh.audit_log.target_id     IS '대상 ID';
COMMENT ON COLUMN dh.audit_log.ip_address    IS '접속 IP 주소';
COMMENT ON COLUMN dh.audit_log.risk_level    IS '위험 수준 (high/medium/low)';
COMMENT ON COLUMN dh.audit_log.created_at    IS '발생일시';

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

COMMENT ON TABLE  dh.notification IS '사용자 알림';
COMMENT ON COLUMN dh.notification.noti_id        IS '알림 일련번호 (PK)';
COMMENT ON COLUMN dh.notification.user_id        IS '수신 사용자 ID (FK→user_account)';
COMMENT ON COLUMN dh.notification.noti_type      IS '알림 유형 (approval/quality/pipeline/system/request)';
COMMENT ON COLUMN dh.notification.title          IS '알림 제목';
COMMENT ON COLUMN dh.notification.message        IS '알림 내용';
COMMENT ON COLUMN dh.notification.icon           IS '아이콘 (이모지)';
COMMENT ON COLUMN dh.notification.is_read        IS '읽음 여부';
COMMENT ON COLUMN dh.notification.related_entity IS '관련 엔티티 타입';
COMMENT ON COLUMN dh.notification.related_id     IS '관련 엔티티 ID';
COMMENT ON COLUMN dh.notification.created_at     IS '발생일시';

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

COMMENT ON TABLE  dh.widget_template IS '대시보드 위젯 템플릿 라이브러리';
COMMENT ON COLUMN dh.widget_template.widget_id     IS '위젯 코드 (PK, 예: w-kpi-quality)';
COMMENT ON COLUMN dh.widget_template.widget_name   IS '위젯명';
COMMENT ON COLUMN dh.widget_template.icon          IS '아이콘 (이모지)';
COMMENT ON COLUMN dh.widget_template.category      IS '위젯 카테고리 (kpi/card/list/chart)';
COMMENT ON COLUMN dh.widget_template.description   IS '위젯 설명';
COMMENT ON COLUMN dh.widget_template.color         IS 'UI 표시 색상 (HEX)';
COMMENT ON COLUMN dh.widget_template.data_level    IS '데이터 보안등급';
COMMENT ON COLUMN dh.widget_template.allowed_roles IS '접근 허용 역할 배열';
COMMENT ON COLUMN dh.widget_template.config_json   IS '위젯 설정 (JSON)';
COMMENT ON COLUMN dh.widget_template.svg_template  IS 'SVG 시각화 템플릿';
COMMENT ON COLUMN dh.widget_template.created_by    IS '등록자 ID (FK→user_account)';
COMMENT ON COLUMN dh.widget_template.created_at    IS '등록일시';
COMMENT ON COLUMN dh.widget_template.updated_at    IS '수정일시';

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

COMMENT ON TABLE  dh.user_widget_layout IS '사용자 대시보드 위젯 배치 설정';
COMMENT ON COLUMN dh.user_widget_layout.layout_id  IS '배치 일련번호 (PK)';
COMMENT ON COLUMN dh.user_widget_layout.user_id    IS '사용자 ID (FK→user_account)';
COMMENT ON COLUMN dh.user_widget_layout.widget_id  IS '위젯 ID (FK→widget_template)';
COMMENT ON COLUMN dh.user_widget_layout.position_x IS 'X 위치 (그리드 컬럼)';
COMMENT ON COLUMN dh.user_widget_layout.position_y IS 'Y 위치 (그리드 행)';
COMMENT ON COLUMN dh.user_widget_layout.width      IS '너비 (그리드 단위)';
COMMENT ON COLUMN dh.user_widget_layout.height     IS '높이 (그리드 단위)';
COMMENT ON COLUMN dh.user_widget_layout.is_visible IS '표시 여부';
COMMENT ON COLUMN dh.user_widget_layout.created_at IS '등록일시';

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

COMMENT ON TABLE  dh.lineage_node IS '데이터 리니지 노드 (SOURCE→INGESTION→TRANSFORM→SERVING)';
COMMENT ON COLUMN dh.lineage_node.node_id       IS '노드 코드 (PK, 예: node-src-1)';
COMMENT ON COLUMN dh.lineage_node.node_name     IS '노드명';
COMMENT ON COLUMN dh.lineage_node.stage         IS '리니지 단계 (source/ingestion/transformation/serving)';
COMMENT ON COLUMN dh.lineage_node.node_type     IS '노드 유형 (FA/EXT/APP/SQL/VIZ/API)';
COMMENT ON COLUMN dh.lineage_node.system_ref    IS '참조 시스템명';
COMMENT ON COLUMN dh.lineage_node.status        IS '상태';
COMMENT ON COLUMN dh.lineage_node.throughput    IS '처리량';
COMMENT ON COLUMN dh.lineage_node.records_in    IS '입력 건수';
COMMENT ON COLUMN dh.lineage_node.records_out   IS '출력 건수';
COMMENT ON COLUMN dh.lineage_node.latency_sec   IS '지연시간 (초)';
COMMENT ON COLUMN dh.lineage_node.quality_score IS '품질점수 (%)';
COMMENT ON COLUMN dh.lineage_node.description   IS '노드 설명';
COMMENT ON COLUMN dh.lineage_node.created_at    IS '등록일시';
COMMENT ON COLUMN dh.lineage_node.updated_at    IS '수정일시';

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

COMMENT ON TABLE  dh.lineage_edge IS '데이터 리니지 노드간 연결';
COMMENT ON COLUMN dh.lineage_edge.edge_id        IS '엣지 일련번호 (PK)';
COMMENT ON COLUMN dh.lineage_edge.source_node_id IS '출발 노드 ID (FK→lineage_node)';
COMMENT ON COLUMN dh.lineage_edge.target_node_id IS '도착 노드 ID (FK→lineage_node)';
COMMENT ON COLUMN dh.lineage_edge.edge_type      IS '연결 유형 (data_flow/trigger/reference)';
COMMENT ON COLUMN dh.lineage_edge.description    IS '연결 설명';
COMMENT ON COLUMN dh.lineage_edge.created_at     IS '등록일시';

-- 9-9. AI 대화이력 (AI Chat History)
CREATE TABLE dh.ai_chat_session (
    session_id      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES dh.user_account(user_id),
    title           VARCHAR(200),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE  dh.ai_chat_session IS 'AI 검색·질의응답 대화 세션';
COMMENT ON COLUMN dh.ai_chat_session.session_id IS '세션 UUID (PK)';
COMMENT ON COLUMN dh.ai_chat_session.user_id    IS '사용자 ID (FK→user_account)';
COMMENT ON COLUMN dh.ai_chat_session.title      IS '대화 제목';
COMMENT ON COLUMN dh.ai_chat_session.created_at IS '생성일시';
COMMENT ON COLUMN dh.ai_chat_session.updated_at IS '수정일시';

CREATE TABLE dh.ai_chat_message (
    message_id      BIGSERIAL PRIMARY KEY,
    session_id      UUID NOT NULL REFERENCES dh.ai_chat_session(session_id) ON DELETE CASCADE,
    role            VARCHAR(10) NOT NULL,             -- user, assistant
    content         TEXT NOT NULL,
    source_refs     JSONB,                            -- 참조 데이터셋/테이블 정보
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE  dh.ai_chat_message IS 'AI 대화 메시지';
COMMENT ON COLUMN dh.ai_chat_message.message_id  IS '메시지 일련번호 (PK)';
COMMENT ON COLUMN dh.ai_chat_message.session_id  IS '세션 ID (FK→ai_chat_session)';
COMMENT ON COLUMN dh.ai_chat_message.role        IS '발화자 (user/assistant)';
COMMENT ON COLUMN dh.ai_chat_message.content     IS '메시지 내용';
COMMENT ON COLUMN dh.ai_chat_message.source_refs IS '참조 데이터셋/테이블 정보 (JSON)';
COMMENT ON COLUMN dh.ai_chat_message.created_at  IS '발화일시';

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

COMMENT ON TABLE  dh.daily_dist_stats IS '일별 유통 통계';
COMMENT ON COLUMN dh.daily_dist_stats.stat_id        IS '통계 일련번호 (PK)';
COMMENT ON COLUMN dh.daily_dist_stats.stat_date      IS '통계 기준일';
COMMENT ON COLUMN dh.daily_dist_stats.product_id     IS '상품 ID (FK→data_product)';
COMMENT ON COLUMN dh.daily_dist_stats.api_calls      IS 'API 호출 건수';
COMMENT ON COLUMN dh.daily_dist_stats.downloads      IS '다운로드 건수';
COMMENT ON COLUMN dh.daily_dist_stats.active_users   IS '활성 사용자 수';
COMMENT ON COLUMN dh.daily_dist_stats.avg_latency_ms IS '평균 지연시간 (ms)';
COMMENT ON COLUMN dh.daily_dist_stats.error_count    IS '오류 건수';
COMMENT ON COLUMN dh.daily_dist_stats.created_at     IS '등록일시';

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

COMMENT ON TABLE  dh.dept_usage_stats IS '부서별 월간 활용 통계';
COMMENT ON COLUMN dh.dept_usage_stats.stat_id       IS '통계 일련번호 (PK)';
COMMENT ON COLUMN dh.dept_usage_stats.stat_month    IS '통계 기준월 (매월 1일)';
COMMENT ON COLUMN dh.dept_usage_stats.dept_id       IS '부서 ID (FK→department)';
COMMENT ON COLUMN dh.dept_usage_stats.api_calls     IS 'API 호출 건수';
COMMENT ON COLUMN dh.dept_usage_stats.downloads     IS '다운로드 건수';
COMMENT ON COLUMN dh.dept_usage_stats.data_requests IS '데이터 신청 건수';
COMMENT ON COLUMN dh.dept_usage_stats.created_at    IS '등록일시';

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
