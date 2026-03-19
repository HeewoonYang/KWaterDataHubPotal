/*
 * ============================================================================
 *  K-water DataHub Portal — 메타데이터 표준사전 DB 스키마 (PostgreSQL 15+)
 * ============================================================================
 *  대상: K-water 데이터 표준사전 (단어/도메인/용어/코드)
 *  범위: 표준 단어사전, 도메인사전, 용어사전, 코드사전, 변경이력
 *  스키마: meta (기존 public 스키마와 분리)
 *  작성일: 2026-03-11
 *  공통 감사컬럼: created_at, updated_at
 * ============================================================================
 */

-- ============================================================================
-- 0. 스키마 생성
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS meta;

-- ============================================================================
-- 1. 표준 단어사전 (std_word)
-- ============================================================================
-- 원본: 표준 데이터 조회_K-water데이터표준_단어사전.xlsx (6,291건)
-- 컬럼: 논리명, 물리명, 물리의미, 속성분류어, 동의어, 설명

CREATE TABLE meta.std_word (
    word_id         SERIAL        PRIMARY KEY,
    logical_name    VARCHAR(200)  NOT NULL,              -- 논리명 (한글)
    physical_name   VARCHAR(100)  NOT NULL,              -- 물리명 (SNAKE_CASE 약어)
    physical_desc   VARCHAR(500),                        -- 물리의미 (영문 설명)
    is_class_word   BOOLEAN       DEFAULT FALSE,         -- 속성분류어 여부 (Y→true, N→false)
    synonym         VARCHAR(500),                        -- 동의어
    description     TEXT,                                -- 설명
    status          VARCHAR(20)   DEFAULT 'active'
                    CHECK (status IN ('active','inactive','deprecated')),
    created_at      TIMESTAMPTZ   DEFAULT now(),
    updated_at      TIMESTAMPTZ   DEFAULT now(),
    UNIQUE (logical_name),
    UNIQUE (physical_name)
);

COMMENT ON TABLE  meta.std_word IS '표준 단어사전 — K-water 데이터 표준 단어 정의';
COMMENT ON COLUMN meta.std_word.word_id IS '단어 고유 ID';
COMMENT ON COLUMN meta.std_word.logical_name IS '논리명 (한글 단어명)';
COMMENT ON COLUMN meta.std_word.physical_name IS '물리명 (영문 약어, SNAKE_CASE)';
COMMENT ON COLUMN meta.std_word.physical_desc IS '물리의미 (영문 설명)';
COMMENT ON COLUMN meta.std_word.is_class_word IS '속성분류어 여부 (true=분류어, false=비분류어)';
COMMENT ON COLUMN meta.std_word.synonym IS '동의어';
COMMENT ON COLUMN meta.std_word.description IS '상세 설명';
COMMENT ON COLUMN meta.std_word.status IS '상태 (active/inactive/deprecated)';
COMMENT ON COLUMN meta.std_word.created_at IS '생성일시';
COMMENT ON COLUMN meta.std_word.updated_at IS '수정일시';

-- 인덱스
CREATE INDEX idx_std_word_logical     ON meta.std_word(logical_name);
CREATE INDEX idx_std_word_physical    ON meta.std_word(physical_name);
CREATE INDEX idx_std_word_class       ON meta.std_word(is_class_word) WHERE is_class_word = TRUE;
CREATE INDEX idx_std_word_status      ON meta.std_word(status);
CREATE INDEX idx_std_word_search_gin  ON meta.std_word USING gin(
    to_tsvector('simple', logical_name || ' ' || COALESCE(physical_name, '') || ' ' || COALESCE(physical_desc, '') || ' ' || COALESCE(description, ''))
);


-- ============================================================================
-- 2. 표준 도메인그룹 (std_domain_group)
-- ============================================================================
-- 도메인사전에서 추출한 11개 도메인그룹 (수량, 번호, 금액, 텍스트 등)

CREATE TABLE meta.std_domain_group (
    group_id        SERIAL        PRIMARY KEY,
    group_name      VARCHAR(50)   NOT NULL UNIQUE,       -- 도메인그룹명 (수량, 번호, 금액 등)
    description     TEXT,                                -- 설명
    sort_order      INT           DEFAULT 0,             -- 정렬 순서
    is_active       BOOLEAN       DEFAULT TRUE,          -- 활성 여부
    created_at      TIMESTAMPTZ   DEFAULT now(),
    updated_at      TIMESTAMPTZ   DEFAULT now()
);

COMMENT ON TABLE  meta.std_domain_group IS '표준 도메인그룹 — 11개 데이터 도메인 분류';
COMMENT ON COLUMN meta.std_domain_group.group_id IS '도메인그룹 고유 ID';
COMMENT ON COLUMN meta.std_domain_group.group_name IS '도메인그룹명 (수량/번호/금액/텍스트/비율/기타/날짜/주소/명/분류/차례)';
COMMENT ON COLUMN meta.std_domain_group.description IS '도메인그룹 설명';
COMMENT ON COLUMN meta.std_domain_group.sort_order IS '정렬 순서';
COMMENT ON COLUMN meta.std_domain_group.is_active IS '활성 여부';
COMMENT ON COLUMN meta.std_domain_group.created_at IS '생성일시';
COMMENT ON COLUMN meta.std_domain_group.updated_at IS '수정일시';

-- 초기 데이터 (11개 도메인그룹)
INSERT INTO meta.std_domain_group (group_name, sort_order) VALUES
    ('수량',   1),
    ('번호',   2),
    ('금액',   3),
    ('텍스트', 4),
    ('비율',   5),
    ('기타',   6),
    ('날짜',   7),
    ('주소',   8),
    ('명',     9),
    ('분류',  10),
    ('차례',  11);


-- ============================================================================
-- 3. 표준 도메인사전 (std_domain)
-- ============================================================================
-- 원본: 표준 데이터 조회_K-water데이터표준_도메인사전.xlsx (614건)
-- 컬럼: 도메인그룹명, 도메인명, 도메인논리명, 데이터유형, 길이, 소수점,
--       개인정보여부, 암호화여부, 스크램블, 설명

CREATE TABLE meta.std_domain (
    domain_id           SERIAL        PRIMARY KEY,
    group_id            INT           NOT NULL REFERENCES meta.std_domain_group(group_id),
    domain_name         VARCHAR(200)  NOT NULL,           -- 도메인명
    domain_logical_name VARCHAR(200)  NOT NULL,           -- 도메인논리명 (예: 1인당1일급수량DEC)
    data_type           VARCHAR(30)   NOT NULL,           -- 데이터유형 (NUMERIC, VARCHAR, CHAR 등)
    data_length         INT,                              -- 길이
    data_scale          INT,                              -- 소수점 자리수
    is_personal_info    BOOLEAN       DEFAULT FALSE,      -- 개인정보 여부
    is_encrypted        BOOLEAN       DEFAULT FALSE,      -- 암호화 여부
    scramble_type       VARCHAR(50),                      -- 스크램블 유형
    description         TEXT,                             -- 설명
    status              VARCHAR(20)   DEFAULT 'active'
                        CHECK (status IN ('active','inactive','deprecated')),
    created_at          TIMESTAMPTZ   DEFAULT now(),
    updated_at          TIMESTAMPTZ   DEFAULT now(),
    UNIQUE (domain_logical_name)
);

COMMENT ON TABLE  meta.std_domain IS '표준 도메인사전 — 데이터 도메인 표준 정의';
COMMENT ON COLUMN meta.std_domain.domain_id IS '도메인 고유 ID';
COMMENT ON COLUMN meta.std_domain.group_id IS '도메인그룹 ID (FK → std_domain_group)';
COMMENT ON COLUMN meta.std_domain.domain_name IS '도메인명';
COMMENT ON COLUMN meta.std_domain.domain_logical_name IS '도메인논리명 (도메인명+데이터유형약어+크기, 예: BOD측정값DEC14,4)';
COMMENT ON COLUMN meta.std_domain.data_type IS '데이터유형 (NUMERIC/VARCHAR/CHAR/DATE/TIMESTAMP/BLOB/CLOB/GEOMETRY)';
COMMENT ON COLUMN meta.std_domain.data_length IS '데이터 길이';
COMMENT ON COLUMN meta.std_domain.data_scale IS '소수점 자리수';
COMMENT ON COLUMN meta.std_domain.is_personal_info IS '개인정보 포함 여부';
COMMENT ON COLUMN meta.std_domain.is_encrypted IS '암호화 대상 여부';
COMMENT ON COLUMN meta.std_domain.scramble_type IS '스크램블(마스킹/익명화) 유형';
COMMENT ON COLUMN meta.std_domain.description IS '도메인 설명';
COMMENT ON COLUMN meta.std_domain.status IS '상태 (active/inactive/deprecated)';
COMMENT ON COLUMN meta.std_domain.created_at IS '생성일시';
COMMENT ON COLUMN meta.std_domain.updated_at IS '수정일시';

-- 인덱스
CREATE INDEX idx_std_domain_group        ON meta.std_domain(group_id);
CREATE INDEX idx_std_domain_type         ON meta.std_domain(data_type);
CREATE INDEX idx_std_domain_personal     ON meta.std_domain(is_personal_info) WHERE is_personal_info = TRUE;
CREATE INDEX idx_std_domain_status       ON meta.std_domain(status);
CREATE INDEX idx_std_domain_search_gin   ON meta.std_domain USING gin(
    to_tsvector('simple', domain_name || ' ' || domain_logical_name || ' ' || COALESCE(description, ''))
);


-- ============================================================================
-- 4. 표준 용어사전 (std_term)
-- ============================================================================
-- 원본: 표준 데이터 조회_K-water데이터표준_용어사전.xlsx (41,359건)
-- 컬럼: 논리명, 물리명, 영문의미, 도메인논리명, 도메인논리약어, 도메인그룹,
--       데이터유형, 길이, 소수점, 개인정보여부, 암호화여부, 스크램블, 설명

CREATE TABLE meta.std_term (
    term_id             SERIAL        PRIMARY KEY,
    logical_name        VARCHAR(300)  NOT NULL,           -- 논리명 (한글)
    physical_name       VARCHAR(200)  NOT NULL,           -- 물리명 (SNAKE_CASE 컬럼명)
    english_name        VARCHAR(500),                     -- 영문의미
    domain_logical_name VARCHAR(200),                     -- 도메인논리명 (검색/매핑키)
    domain_id           INT           REFERENCES meta.std_domain(domain_id),
    domain_abbr         VARCHAR(100),                     -- 도메인 논리 약어
    domain_group_id     INT           REFERENCES meta.std_domain_group(group_id),
    data_type           VARCHAR(30),                      -- 데이터유형
    data_length         INT,                              -- 길이
    data_scale          INT,                              -- 소수점
    is_personal_info    BOOLEAN       DEFAULT FALSE,      -- 개인정보 여부
    is_encrypted        BOOLEAN       DEFAULT FALSE,      -- 암호화 여부
    scramble_type       VARCHAR(50),                      -- 스크램블 유형
    description         TEXT,                             -- 설명
    status              VARCHAR(20)   DEFAULT 'active'
                        CHECK (status IN ('active','inactive','deprecated')),
    created_at          TIMESTAMPTZ   DEFAULT now(),
    updated_at          TIMESTAMPTZ   DEFAULT now(),
    UNIQUE (physical_name)
);

COMMENT ON TABLE  meta.std_term IS '표준 용어사전 — 테이블 컬럼 표준 용어 정의 (41,359건)';
COMMENT ON COLUMN meta.std_term.term_id IS '용어 고유 ID';
COMMENT ON COLUMN meta.std_term.logical_name IS '논리명 (한글 컬럼명)';
COMMENT ON COLUMN meta.std_term.physical_name IS '물리명 (SNAKE_CASE 컬럼명, 예: YR10AG_ACMSLT_QY)';
COMMENT ON COLUMN meta.std_term.english_name IS '영문의미 (예: TEN YEARS AGO ACTUAL RESULT QUANTITY)';
COMMENT ON COLUMN meta.std_term.domain_logical_name IS '도메인논리명 (도메인사전 연결키)';
COMMENT ON COLUMN meta.std_term.domain_id IS '도메인 ID (FK → std_domain)';
COMMENT ON COLUMN meta.std_term.domain_abbr IS '도메인 논리 약어 (예: 량, 코드, 명)';
COMMENT ON COLUMN meta.std_term.domain_group_id IS '도메인그룹 ID (FK → std_domain_group)';
COMMENT ON COLUMN meta.std_term.data_type IS '데이터유형';
COMMENT ON COLUMN meta.std_term.data_length IS '데이터 길이';
COMMENT ON COLUMN meta.std_term.data_scale IS '소수점 자리수';
COMMENT ON COLUMN meta.std_term.is_personal_info IS '개인정보 포함 여부';
COMMENT ON COLUMN meta.std_term.is_encrypted IS '암호화 대상 여부';
COMMENT ON COLUMN meta.std_term.scramble_type IS '스크램블(마스킹/익명화) 유형';
COMMENT ON COLUMN meta.std_term.description IS '용어 설명';
COMMENT ON COLUMN meta.std_term.status IS '상태 (active/inactive/deprecated)';
COMMENT ON COLUMN meta.std_term.created_at IS '생성일시';
COMMENT ON COLUMN meta.std_term.updated_at IS '수정일시';

-- 인덱스
CREATE INDEX idx_std_term_logical        ON meta.std_term(logical_name);
CREATE INDEX idx_std_term_physical       ON meta.std_term(physical_name);
CREATE INDEX idx_std_term_domain         ON meta.std_term(domain_id);
CREATE INDEX idx_std_term_domain_grp     ON meta.std_term(domain_group_id);
CREATE INDEX idx_std_term_data_type      ON meta.std_term(data_type);
CREATE INDEX idx_std_term_personal       ON meta.std_term(is_personal_info) WHERE is_personal_info = TRUE;
CREATE INDEX idx_std_term_status         ON meta.std_term(status);
CREATE INDEX idx_std_term_search_gin     ON meta.std_term USING gin(
    to_tsvector('simple', logical_name || ' ' || physical_name || ' ' || COALESCE(english_name, '') || ' ' || COALESCE(description, ''))
);


-- ============================================================================
-- 5. 표준 코드그룹 (std_code_group)
-- ============================================================================
-- 원본: 코드사전 엑셀의 코드그룹 레벨 (42개 업무시스템 x 코드별)
-- 한 행: 코드그룹(ADT), 논리명, 물리명, 코드설명, 코드구분, 길이, 코드ID

CREATE TABLE meta.std_code_group (
    group_id          SERIAL        PRIMARY KEY,
    system_prefix     VARCHAR(30)   NOT NULL,             -- 시스템 접두어 (ADT, AMS, SCM 등)
    system_name       VARCHAR(100),                       -- 시스템명 (감사, 수도시설자산관리 등)
    logical_name      VARCHAR(200)  NOT NULL,             -- 논리명 (감사결재상태코드 등)
    physical_name     VARCHAR(200)  NOT NULL,             -- 물리명 (AUDIT_SANCTN_STAT_CD 등)
    code_desc         TEXT,                               -- 코드 설명
    code_type         VARCHAR(30),                        -- 코드구분 (공통코드 등)
    data_length       INT,                                -- 길이
    code_id           VARCHAR(50)   NOT NULL UNIQUE,      -- 코드ID (ADT_0059 등)
    status            VARCHAR(20)   DEFAULT 'active'
                      CHECK (status IN ('active','inactive','deprecated')),
    created_at        TIMESTAMPTZ   DEFAULT now(),
    updated_at        TIMESTAMPTZ   DEFAULT now()
);

COMMENT ON TABLE  meta.std_code_group IS '표준 코드그룹 — 업무시스템별 공통코드 그룹 정의';
COMMENT ON COLUMN meta.std_code_group.group_id IS '코드그룹 고유 ID';
COMMENT ON COLUMN meta.std_code_group.system_prefix IS '시스템 접두어 (ADT/AMS/BST/SCM 등 42개)';
COMMENT ON COLUMN meta.std_code_group.system_name IS '시스템명 (감사/수도시설자산관리/K-Best 등)';
COMMENT ON COLUMN meta.std_code_group.logical_name IS '논리명 (한글 코드그룹명)';
COMMENT ON COLUMN meta.std_code_group.physical_name IS '물리명 (영문 컬럼명)';
COMMENT ON COLUMN meta.std_code_group.code_desc IS '코드 설명';
COMMENT ON COLUMN meta.std_code_group.code_type IS '코드구분 (공통코드 등)';
COMMENT ON COLUMN meta.std_code_group.data_length IS '데이터 길이';
COMMENT ON COLUMN meta.std_code_group.code_id IS '코드 고유 식별자 (ADT_0059 등)';
COMMENT ON COLUMN meta.std_code_group.status IS '상태 (active/inactive/deprecated)';
COMMENT ON COLUMN meta.std_code_group.created_at IS '생성일시';
COMMENT ON COLUMN meta.std_code_group.updated_at IS '수정일시';

-- 인덱스
CREATE INDEX idx_std_code_group_prefix    ON meta.std_code_group(system_prefix);
CREATE INDEX idx_std_code_group_physical  ON meta.std_code_group(physical_name);
CREATE INDEX idx_std_code_group_status    ON meta.std_code_group(status);
CREATE INDEX idx_std_code_group_search_gin ON meta.std_code_group USING gin(
    to_tsvector('simple', logical_name || ' ' || physical_name || ' ' || COALESCE(system_name, '') || ' ' || COALESCE(code_desc, ''))
);


-- ============================================================================
-- 6. 표준 코드사전 (std_code)
-- ============================================================================
-- 원본: 표준 데이터 조회_K-water데이터표준_코드사전.xlsx (139,258건, 2시트)
-- 코드값 레벨: 코드값, 코드값명, 정렬순서, 부모코드, 설명, 적용일자

CREATE TABLE meta.std_code (
    code_id           SERIAL        PRIMARY KEY,
    group_id          INT           NOT NULL REFERENCES meta.std_code_group(group_id) ON DELETE CASCADE,
    code_value        VARCHAR(100)  NOT NULL,              -- 코드값 (0, 256, 512 등)
    code_name         VARCHAR(500)  NOT NULL,              -- 코드값명 (기안전, 승인, 반려 등)
    sort_order        INT           DEFAULT 0,             -- 정렬 순서
    parent_code_name  VARCHAR(200),                        -- 부모코드명
    parent_code_value VARCHAR(100),                        -- 부모코드값
    parent_id         INT           REFERENCES meta.std_code(code_id), -- 자기참조 FK (계층 코드)
    description       TEXT,                                -- 설명
    effective_from    DATE,                                -- 적용시작일자
    effective_to      DATE,                                -- 적용종료일자
    status            VARCHAR(20)   DEFAULT 'active'
                      CHECK (status IN ('active','inactive','deprecated')),
    created_at        TIMESTAMPTZ   DEFAULT now(),
    updated_at        TIMESTAMPTZ   DEFAULT now(),
    UNIQUE (group_id, code_value)
);

COMMENT ON TABLE  meta.std_code IS '표준 코드사전 — 공통코드 값 정의 (139,258건)';
COMMENT ON COLUMN meta.std_code.code_id IS '코드 고유 ID';
COMMENT ON COLUMN meta.std_code.group_id IS '코드그룹 ID (FK → std_code_group)';
COMMENT ON COLUMN meta.std_code.code_value IS '코드값 (예: 0, 1, 256, 512)';
COMMENT ON COLUMN meta.std_code.code_name IS '코드값명 (예: 기안전, 진행, 승인, 반려)';
COMMENT ON COLUMN meta.std_code.sort_order IS '정렬 순서';
COMMENT ON COLUMN meta.std_code.parent_code_name IS '부모 코드명';
COMMENT ON COLUMN meta.std_code.parent_code_value IS '부모 코드값';
COMMENT ON COLUMN meta.std_code.parent_id IS '부모 코드 참조 (계층형 코드 구조)';
COMMENT ON COLUMN meta.std_code.description IS '코드 설명';
COMMENT ON COLUMN meta.std_code.effective_from IS '코드 적용 시작일자';
COMMENT ON COLUMN meta.std_code.effective_to IS '코드 적용 종료일자';
COMMENT ON COLUMN meta.std_code.status IS '상태 (active/inactive/deprecated)';
COMMENT ON COLUMN meta.std_code.created_at IS '생성일시';
COMMENT ON COLUMN meta.std_code.updated_at IS '수정일시';

-- 인덱스
CREATE INDEX idx_std_code_group          ON meta.std_code(group_id);
CREATE INDEX idx_std_code_value          ON meta.std_code(code_value);
CREATE INDEX idx_std_code_parent         ON meta.std_code(parent_id);
CREATE INDEX idx_std_code_effective      ON meta.std_code(effective_from, effective_to);
CREATE INDEX idx_std_code_status         ON meta.std_code(status);
CREATE INDEX idx_std_code_search_gin     ON meta.std_code USING gin(
    to_tsvector('simple', code_name || ' ' || code_value || ' ' || COALESCE(description, ''))
);


-- ============================================================================
-- 7. 변경이력 (std_change_history)
-- ============================================================================
-- 4개 사전 공통 변경이력 추적 테이블

CREATE TABLE meta.std_change_history (
    history_id      BIGSERIAL     PRIMARY KEY,
    dict_type       VARCHAR(20)   NOT NULL                -- 사전 종류
                    CHECK (dict_type IN ('word','domain_group','domain','term','code_group','code')),
    record_id       INT           NOT NULL,               -- 대상 레코드 PK
    action          VARCHAR(10)   NOT NULL                -- 변경 유형
                    CHECK (action IN ('create','update','delete','import')),
    change_desc     TEXT,                                 -- 변경 설명
    prev_value      JSONB,                                -- 변경 전 값
    new_value       JSONB,                                -- 변경 후 값
    changed_by      VARCHAR(100),                         -- 변경자
    changed_at      TIMESTAMPTZ   DEFAULT now()
);

COMMENT ON TABLE  meta.std_change_history IS '표준사전 변경이력 — 모든 사전 공통 변경 추적';
COMMENT ON COLUMN meta.std_change_history.history_id IS '이력 고유 ID';
COMMENT ON COLUMN meta.std_change_history.dict_type IS '사전 종류 (word/domain_group/domain/term/code_group/code)';
COMMENT ON COLUMN meta.std_change_history.record_id IS '대상 레코드 PK';
COMMENT ON COLUMN meta.std_change_history.action IS '변경 유형 (create/update/delete/import)';
COMMENT ON COLUMN meta.std_change_history.change_desc IS '변경 설명';
COMMENT ON COLUMN meta.std_change_history.prev_value IS '변경 전 값 (JSONB)';
COMMENT ON COLUMN meta.std_change_history.new_value IS '변경 후 값 (JSONB)';
COMMENT ON COLUMN meta.std_change_history.changed_by IS '변경자';
COMMENT ON COLUMN meta.std_change_history.changed_at IS '변경일시';

-- 인덱스
CREATE INDEX idx_change_history_type     ON meta.std_change_history(dict_type, record_id);
CREATE INDEX idx_change_history_date     ON meta.std_change_history(changed_at DESC);
CREATE INDEX idx_change_history_action   ON meta.std_change_history(action);


-- ============================================================================
-- 8. 업데이트 타임스탬프 자동 갱신 트리거
-- ============================================================================

CREATE OR REPLACE FUNCTION meta.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 각 테이블에 updated_at 자동 갱신 트리거 설정
CREATE TRIGGER trg_std_word_updated
    BEFORE UPDATE ON meta.std_word
    FOR EACH ROW EXECUTE FUNCTION meta.update_updated_at();

CREATE TRIGGER trg_std_domain_group_updated
    BEFORE UPDATE ON meta.std_domain_group
    FOR EACH ROW EXECUTE FUNCTION meta.update_updated_at();

CREATE TRIGGER trg_std_domain_updated
    BEFORE UPDATE ON meta.std_domain
    FOR EACH ROW EXECUTE FUNCTION meta.update_updated_at();

CREATE TRIGGER trg_std_term_updated
    BEFORE UPDATE ON meta.std_term
    FOR EACH ROW EXECUTE FUNCTION meta.update_updated_at();

CREATE TRIGGER trg_std_code_group_updated
    BEFORE UPDATE ON meta.std_code_group
    FOR EACH ROW EXECUTE FUNCTION meta.update_updated_at();

CREATE TRIGGER trg_std_code_updated
    BEFORE UPDATE ON meta.std_code
    FOR EACH ROW EXECUTE FUNCTION meta.update_updated_at();


-- ============================================================================
-- 9. 통계용 뷰
-- ============================================================================

-- 사전별 건수 통계 뷰
CREATE OR REPLACE VIEW meta.v_dict_summary AS
SELECT
    '단어사전' AS dict_name, 'word' AS dict_type,
    COUNT(*) AS total_count,
    COUNT(*) FILTER (WHERE status = 'active') AS active_count
FROM meta.std_word
UNION ALL
SELECT
    '도메인그룹', 'domain_group',
    COUNT(*),
    COUNT(*) FILTER (WHERE is_active = TRUE)
FROM meta.std_domain_group
UNION ALL
SELECT
    '도메인사전', 'domain',
    COUNT(*),
    COUNT(*) FILTER (WHERE status = 'active')
FROM meta.std_domain
UNION ALL
SELECT
    '용어사전', 'term',
    COUNT(*),
    COUNT(*) FILTER (WHERE status = 'active')
FROM meta.std_term
UNION ALL
SELECT
    '코드그룹', 'code_group',
    COUNT(*),
    COUNT(*) FILTER (WHERE status = 'active')
FROM meta.std_code_group
UNION ALL
SELECT
    '코드사전', 'code',
    COUNT(*),
    COUNT(*) FILTER (WHERE status = 'active')
FROM meta.std_code;

COMMENT ON VIEW meta.v_dict_summary IS '전체 사전 건수 통계 뷰';

-- 도메인그룹별 도메인/용어 분포 뷰
CREATE OR REPLACE VIEW meta.v_domain_group_stats AS
SELECT
    dg.group_id,
    dg.group_name,
    dg.sort_order,
    COUNT(DISTINCT d.domain_id)  AS domain_count,
    COUNT(DISTINCT t.term_id)    AS term_count
FROM meta.std_domain_group dg
LEFT JOIN meta.std_domain d ON d.group_id = dg.group_id AND d.status = 'active'
LEFT JOIN meta.std_term t   ON t.domain_group_id = dg.group_id AND t.status = 'active'
GROUP BY dg.group_id, dg.group_name, dg.sort_order
ORDER BY dg.sort_order;

COMMENT ON VIEW meta.v_domain_group_stats IS '도메인그룹별 도메인/용어 건수 분포';

-- 코드그룹별 시스템 접두어 분포 뷰
CREATE OR REPLACE VIEW meta.v_code_group_stats AS
SELECT
    cg.system_prefix,
    cg.system_name,
    COUNT(DISTINCT cg.group_id) AS group_count,
    COUNT(c.code_id)            AS code_count
FROM meta.std_code_group cg
LEFT JOIN meta.std_code c ON c.group_id = cg.group_id AND c.status = 'active'
WHERE cg.status = 'active'
GROUP BY cg.system_prefix, cg.system_name
ORDER BY cg.system_prefix;

COMMENT ON VIEW meta.v_code_group_stats IS '시스템 접두어별 코드그룹/코드 건수 분포';
