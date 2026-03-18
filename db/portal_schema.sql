/*
 * ============================================================================
 *  K-water DataHub Portal — 포탈 운영 DB 스키마 (PostgreSQL 15+)
 * ============================================================================
 *  대상: 포탈 자체 운영 데이터 (연계·수집된 원천 데이터 제외)
 *  범위: 사용자/권한, 카탈로그/메타, 수집관리, 유통/활용, 품질,
 *        온톨로지, 모니터링, 커뮤니티, 시스템관리, 대시보드
 *  작성일: 2026-03-11
 *  공통 감사컬럼: 모든 테이블에 crtd_at, crtd_by, updtd_at, updtd_by 포함
 *  명명규칙: K-water 표준사전 기반 영문약어 (소문자 snake_case)
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

CREATE TABLE divs (
    divs_id   SERIAL       PRIMARY KEY,
    divs_cd VARCHAR(20)  NOT NULL UNIQUE,
    divs_nm VARCHAR(100) NOT NULL,
    sort_ord    INT          DEFAULT 0,
    is_actv     BOOLEAN      DEFAULT TRUE,
    crtd_at    TIMESTAMPTZ  DEFAULT now(),
    crtd_by    UUID,
    updtd_at    TIMESTAMPTZ  DEFAULT now(),
    updtd_by    UUID
);

CREATE TABLE dept (
    dept_id       SERIAL       PRIMARY KEY,
    divs_id   INT          NOT NULL REFERENCES divs(divs_id),
    dept_cd     VARCHAR(20)  NOT NULL UNIQUE,
    dept_nm     VARCHAR(100) NOT NULL,
    hdcnt     INT          DEFAULT 0,
    sort_ord    INT          DEFAULT 0,
    is_actv     BOOLEAN      DEFAULT TRUE,
    crtd_at    TIMESTAMPTZ  DEFAULT now(),
    crtd_by    UUID,
    updtd_at    TIMESTAMPTZ  DEFAULT now(),
    updtd_by    UUID
);

CREATE TABLE role (
    role_id        SERIAL        PRIMARY KEY,
    role_cd      VARCHAR(30)   NOT NULL UNIQUE,
    role_nm      VARCHAR(100)  NOT NULL,
    role_grp     VARCHAR(50)   NOT NULL,
    role_lvl     SMALLINT      DEFAULT 0 CHECK (role_lvl BETWEEN 0 AND 6),
    data_clrnc SMALLINT      DEFAULT 1 CHECK (data_clrnc BETWEEN 1 AND 4),
    dc    TEXT,
    is_actv      BOOLEAN       DEFAULT TRUE,
    crtd_at     TIMESTAMPTZ   DEFAULT now(),
    crtd_by     UUID,
    updtd_at     TIMESTAMPTZ   DEFAULT now(),
    updtd_by     UUID
);

CREATE TABLE usr_acnt (
    usr_id        UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
    login_id       VARCHAR(50)   NOT NULL UNIQUE,
    usr_nm      VARCHAR(50)   NOT NULL,
    email          VARCHAR(120),
    phone          VARCHAR(20),
    dept_id        INT           REFERENCES dept(dept_id),
    role_id        INT           NOT NULL REFERENCES role(role_id),
    login_ty       login_type    NOT NULL DEFAULT 'sso',
    stat         entity_status NOT NULL DEFAULT 'active',
    last_login_at  TIMESTAMPTZ,
    pwd_hash  VARCHAR(256),
    pfile_img  VARCHAR(500),
    crtd_at     TIMESTAMPTZ   DEFAULT now(),
    crtd_by     UUID,
    updtd_at     TIMESTAMPTZ   DEFAULT now(),
    updtd_by     UUID
);

CREATE TABLE menu (
    menu_id      SERIAL       PRIMARY KEY,
    menu_cd    VARCHAR(30)  NOT NULL UNIQUE,
    menu_nm    VARCHAR(100) NOT NULL,
    parent_cd  VARCHAR(30)  REFERENCES menu(menu_cd),
    sctn      VARCHAR(30)  NOT NULL,
    scrin_id    VARCHAR(50),
    icon         VARCHAR(50),
    sort_ord   INT          DEFAULT 0,
    is_actv    BOOLEAN      DEFAULT TRUE,
    crtd_at   TIMESTAMPTZ  DEFAULT now(),
    crtd_by   UUID,
    updtd_at   TIMESTAMPTZ  DEFAULT now(),
    updtd_by   UUID
);

CREATE TABLE role_menu_perm (
    role_id       INT     NOT NULL REFERENCES role(role_id) ON DELETE CASCADE,
    menu_id       INT     NOT NULL REFERENCES menu(menu_id) ON DELETE CASCADE,
    can_read      BOOLEAN DEFAULT TRUE,
    can_crt    BOOLEAN DEFAULT FALSE,
    can_updt    BOOLEAN DEFAULT FALSE,
    can_del    BOOLEAN DEFAULT FALSE,
    can_aprv   BOOLEAN DEFAULT FALSE,
    can_dwld  BOOLEAN DEFAULT FALSE,
    crtd_at    TIMESTAMPTZ DEFAULT now(),
    crtd_by    UUID,
    updtd_at    TIMESTAMPTZ DEFAULT now(),
    updtd_by    UUID,
    PRIMARY KEY (role_id, menu_id)
);

CREATE TABLE login_hist (
    hist_id   BIGSERIAL    PRIMARY KEY,
    usr_id      UUID         NOT NULL REFERENCES usr_acnt(usr_id),
    login_ty     login_type   NOT NULL,
    login_ip     INET,
    usr_agent   VARCHAR(500),
    login_at     TIMESTAMPTZ  DEFAULT now(),
    logout_at    TIMESTAMPTZ,
    is_succes   BOOLEAN      DEFAULT TRUE,
    fail_rsn  VARCHAR(200),
    crtd_at   TIMESTAMPTZ  DEFAULT now(),
    crtd_by   UUID,
    updtd_at   TIMESTAMPTZ  DEFAULT now(),
    updtd_by   UUID
);

CREATE TABLE pwd_reset_hist (
    reset_id      BIGSERIAL    PRIMARY KEY,
    usr_id        UUID         NOT NULL REFERENCES usr_acnt(usr_id),
    reset_ty      VARCHAR(20)  NOT NULL DEFAULT 'email',  -- email / admin / self
    temp_pwd_hash VARCHAR(256),
    req_ip        INET,
    is_used       BOOLEAN      DEFAULT FALSE,
    expires_at    TIMESTAMPTZ  NOT NULL,
    crtd_at       TIMESTAMPTZ  DEFAULT now(),
    crtd_by       UUID,
    updtd_at      TIMESTAMPTZ  DEFAULT now(),
    updtd_by      UUID
);
COMMENT ON TABLE pwd_reset_hist IS '비밀번호 초기화 이력';


-- ============================================================================
-- 2. 카탈로그·메타데이터 도메인
-- ============================================================================

CREATE TABLE domn (
    domn_id   SERIAL       PRIMARY KEY,
    domn_cd VARCHAR(20)  NOT NULL UNIQUE,
    domn_nm VARCHAR(100) NOT NULL,
    dc TEXT,
    color       VARCHAR(7),
    icon        VARCHAR(50),
    sort_ord  INT          DEFAULT 0,
    is_actv   BOOLEAN      DEFAULT TRUE,
    crtd_at  TIMESTAMPTZ  DEFAULT now(),
    crtd_by  UUID,
    updtd_at  TIMESTAMPTZ  DEFAULT now(),
    updtd_by  UUID
);

CREATE TABLE src_sys (
    sys_id       SERIAL        PRIMARY KEY,
    sys_cd     VARCHAR(30)   NOT NULL UNIQUE,
    sys_nm     VARCHAR(100)  NOT NULL,
    sys_nm_en  VARCHAR(100),
    dc     TEXT,
    dbms_ty       VARCHAR(30),
    prtcl        VARCHAR(30),
    ntwk_zone    VARCHAR(20),
    cnctn_info JSONB,
    owner_dept_id   INT           REFERENCES dept(dept_id),
    stat          entity_status DEFAULT 'active',
    crtd_at      TIMESTAMPTZ   DEFAULT now(),
    crtd_by      UUID,
    updtd_at      TIMESTAMPTZ   DEFAULT now(),
    updtd_by      UUID
);

CREATE TABLE dset (
    dset_id       UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    dset_cd     VARCHAR(50)     NOT NULL UNIQUE,
    table_nm       VARCHAR(128),
    dset_nm     VARCHAR(200)    NOT NULL,
    dc      TEXT,
    domn_id        INT             REFERENCES domn(domn_id),
    sys_id        INT             REFERENCES src_sys(sys_id),
    asset_ty       data_asset_type DEFAULT 'table',
    scrty_lvl   data_security_level DEFAULT 'internal',
    qlity_score    NUMERIC(5,2)    DEFAULT 0 CHECK (qlity_score BETWEEN 0 AND 100),
    row_co        BIGINT          DEFAULT 0,
    col_co     INT             DEFAULT 0,
    size_bytes       BIGINT          DEFAULT 0,
    owner_dept_id    INT             REFERENCES dept(dept_id),
    stwrd_usr_id  UUID            REFERENCES usr_acnt(usr_id),
    stat           entity_status   DEFAULT 'active',
    last_prfld_at TIMESTAMPTZ,
    crtd_at       TIMESTAMPTZ     DEFAULT now(),
    crtd_by       UUID,
    updtd_at       TIMESTAMPTZ     DEFAULT now(),
    updtd_by       UUID
);

CREATE TABLE dset_col (
    col_id       SERIAL        PRIMARY KEY,
    dset_id      UUID          NOT NULL REFERENCES dset(dset_id) ON DELETE CASCADE,
    col_nm     VARCHAR(128)  NOT NULL,
    col_nm_ko  VARCHAR(128),
    data_ty       VARCHAR(50)   NOT NULL,
    data_lt     INT,
    is_pk           BOOLEAN       DEFAULT FALSE,
    is_fk           BOOLEAN       DEFAULT FALSE,
    is_nulbl     BOOLEAN       DEFAULT TRUE,
    dflt_val   VARCHAR(200),
    std_term_id     INT,
    dc     TEXT,
    null_rt       NUMERIC(5,2),
    unique_rt     NUMERIC(5,2),
    min_val       VARCHAR(200),
    max_val       VARCHAR(200),
    smple_vals   TEXT[],
    sort_ord      INT           DEFAULT 0,
    crtd_at      TIMESTAMPTZ   DEFAULT now(),
    crtd_by      UUID,
    updtd_at      TIMESTAMPTZ   DEFAULT now(),
    updtd_by      UUID,
    UNIQUE (dset_id, col_nm)
);

CREATE TABLE tag (
    tag_id     SERIAL       PRIMARY KEY,
    tag_nm   VARCHAR(50)  NOT NULL UNIQUE,
    tag_ty   VARCHAR(20)  DEFAULT 'keyword',
    color      VARCHAR(7),
    crtd_at TIMESTAMPTZ  DEFAULT now(),
    crtd_by UUID,
    updtd_at TIMESTAMPTZ  DEFAULT now(),
    updtd_by UUID
);

CREATE TABLE dset_tag (
    dset_id UUID NOT NULL REFERENCES dset(dset_id) ON DELETE CASCADE,
    tag_id     INT  NOT NULL REFERENCES tag(tag_id) ON DELETE CASCADE,
    crtd_at TIMESTAMPTZ DEFAULT now(),
    crtd_by UUID,
    updtd_at TIMESTAMPTZ DEFAULT now(),
    updtd_by UUID,
    PRIMARY KEY (dset_id, tag_id)
);

CREATE TABLE bmrk (
    bmrk_id SERIAL      PRIMARY KEY,
    usr_id     UUID        NOT NULL REFERENCES usr_acnt(usr_id) ON DELETE CASCADE,
    dset_id  UUID        NOT NULL REFERENCES dset(dset_id) ON DELETE CASCADE,
    memo        VARCHAR(200),
    crtd_at  TIMESTAMPTZ DEFAULT now(),
    crtd_by  UUID,
    updtd_at  TIMESTAMPTZ DEFAULT now(),
    updtd_by  UUID,
    UNIQUE (usr_id, dset_id)
);

CREATE TABLE glsry_term (
    term_id         SERIAL        PRIMARY KEY,
    term_nm       VARCHAR(100)  NOT NULL,
    term_nm_en    VARCHAR(100),
    domn_id       INT           REFERENCES domn(domn_id),
    data_ty       VARCHAR(30),
    data_lt     INT,
    unit            VARCHAR(30),
    valid_rng_min VARCHAR(50),
    valid_rng_max VARCHAR(50),
    dfn      TEXT          NOT NULL,
    exmp         VARCHAR(200),
    synm         VARCHAR(200),
    stat          approval_status DEFAULT 'pending',
    aprvd_by     UUID          REFERENCES usr_acnt(usr_id),
    aprvd_at     TIMESTAMPTZ,
    crtd_at      TIMESTAMPTZ   DEFAULT now(),
    crtd_by      UUID          REFERENCES usr_acnt(usr_id),
    updtd_at      TIMESTAMPTZ   DEFAULT now(),
    updtd_by      UUID
);

CREATE TABLE glsry_hist (
    hist_id  SERIAL          PRIMARY KEY,
    term_id     INT             NOT NULL REFERENCES glsry_term(term_id) ON DELETE CASCADE,
    chg_desc TEXT            NOT NULL,
    chgd_by  UUID            REFERENCES usr_acnt(usr_id),
    prev_stat approval_status,
    new_stat  approval_status,
    prev_val  JSONB,
    new_val   JSONB,
    crtd_at  TIMESTAMPTZ     DEFAULT now(),
    crtd_by  UUID,
    updtd_at  TIMESTAMPTZ     DEFAULT now(),
    updtd_by  UUID
);

CREATE TABLE cd_grp (
    grp_id    SERIAL       PRIMARY KEY,
    grp_cd  VARCHAR(30)  NOT NULL UNIQUE,
    grp_nm  VARCHAR(100) NOT NULL,
    dc TEXT,
    is_actv   BOOLEAN      DEFAULT TRUE,
    crtd_at  TIMESTAMPTZ  DEFAULT now(),
    crtd_by  UUID,
    updtd_at  TIMESTAMPTZ  DEFAULT now(),
    updtd_by  UUID
);

CREATE TABLE cd (
    cd_id     SERIAL       PRIMARY KEY,
    grp_id    INT          NOT NULL REFERENCES cd_grp(grp_id) ON DELETE CASCADE,
    cd_val  VARCHAR(30)  NOT NULL,
    cd_nm   VARCHAR(100) NOT NULL,
    dc VARCHAR(200),
    sort_ord  INT          DEFAULT 0,
    is_actv   BOOLEAN      DEFAULT TRUE,
    crtd_at  TIMESTAMPTZ  DEFAULT now(),
    crtd_by  UUID,
    updtd_at  TIMESTAMPTZ  DEFAULT now(),
    updtd_by  UUID,
    UNIQUE (grp_id, cd_val)
);

CREATE TABLE data_model (
    model_id          SERIAL        PRIMARY KEY,
    model_nm        VARCHAR(200)  NOT NULL,
    model_ty        VARCHAR(20)   NOT NULL CHECK (model_ty IN ('logical','physical')),
    domn_id         INT           REFERENCES domn(domn_id),
    ver           VARCHAR(20)   DEFAULT '1.0',
    dc       TEXT,
    table_co       INT           DEFAULT 0,
    namng_cmplnc NUMERIC(5,2)  DEFAULT 0,
    ty_cnstnc  NUMERIC(5,2)  DEFAULT 0,
    ref_intgrty     NUMERIC(5,2)  DEFAULT 0,
    stat            entity_status DEFAULT 'active',
    owner_usr_id     UUID          REFERENCES usr_acnt(usr_id),
    crtd_at        TIMESTAMPTZ   DEFAULT now(),
    crtd_by        UUID,
    updtd_at        TIMESTAMPTZ   DEFAULT now(),
    updtd_by        UUID
);

CREATE TABLE model_entty (
    entty_id      SERIAL        PRIMARY KEY,
    model_id       INT           NOT NULL REFERENCES data_model(model_id) ON DELETE CASCADE,
    entty_nm    VARCHAR(128)  NOT NULL,
    entty_nm_ko VARCHAR(128),
    entty_ty    VARCHAR(20)   DEFAULT 'table',
    dc    TEXT,
    sort_ord     INT           DEFAULT 0,
    crtd_at     TIMESTAMPTZ   DEFAULT now(),
    crtd_by     UUID,
    updtd_at     TIMESTAMPTZ   DEFAULT now(),
    updtd_by     UUID,
    UNIQUE (model_id, entty_nm)
);

CREATE TABLE model_atrb (
    atrb_id  SERIAL       PRIMARY KEY,
    entty_id     INT          NOT NULL REFERENCES model_entty(entty_id) ON DELETE CASCADE,
    atrb_nm     VARCHAR(128) NOT NULL,
    atrb_nm_ko  VARCHAR(128),
    data_ty     VARCHAR(50)  NOT NULL,
    data_lt   INT,
    is_pk         BOOLEAN      DEFAULT FALSE,
    is_fk         BOOLEAN      DEFAULT FALSE,
    is_nulbl   BOOLEAN      DEFAULT TRUE,
    fk_ref_entty VARCHAR(128),
    fk_ref_atrb   VARCHAR(128),
    dc   TEXT,
    sort_ord    INT          DEFAULT 0,
    crtd_at    TIMESTAMPTZ  DEFAULT now(),
    crtd_by    UUID,
    updtd_at    TIMESTAMPTZ  DEFAULT now(),
    updtd_by    UUID,
    UNIQUE (entty_id, atrb_nm)
);


-- ============================================================================
-- 3. 수집 관리 도메인
-- ============================================================================

CREATE TABLE ppln (
    ppln_id    SERIAL         PRIMARY KEY,
    ppln_nm  VARCHAR(200)   NOT NULL,
    ppln_cd  VARCHAR(50)    UNIQUE,
    sys_id      INT            REFERENCES src_sys(sys_id),
    colct_mthd collect_method NOT NULL DEFAULT 'batch',
    schdul       VARCHAR(50),
    src_table   VARCHAR(200),
    trget_stg VARCHAR(200),
    thrput     VARCHAR(50),
    dc    TEXT,
    owner_usr_id  UUID           REFERENCES usr_acnt(usr_id),
    owner_dept_id  INT            REFERENCES dept(dept_id),
    stat         entity_status  DEFAULT 'active',
    crtd_at     TIMESTAMPTZ    DEFAULT now(),
    crtd_by     UUID,
    updtd_at     TIMESTAMPTZ    DEFAULT now(),
    updtd_by     UUID
);

CREATE TABLE ppln_exec (
    exec_id    BIGSERIAL   PRIMARY KEY,
    ppln_id     INT         NOT NULL REFERENCES ppln(ppln_id) ON DELETE CASCADE,
    strtd_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    fnshed_at     TIMESTAMPTZ,
    dur_secnd  INT,
    rcrds_read    BIGINT      DEFAULT 0,
    rcrds_wrtn BIGINT      DEFAULT 0,
    rcrds_err   BIGINT      DEFAULT 0,
    succes_rt    NUMERIC(5,2),
    stat          VARCHAR(20) DEFAULT 'running' CHECK (stat IN ('running','success','failed','cancelled')),
    err_msg   TEXT,
    err_dtl    JSONB,
    crtd_at      TIMESTAMPTZ DEFAULT now(),
    crtd_by      UUID,
    updtd_at      TIMESTAMPTZ DEFAULT now(),
    updtd_by      UUID
);

CREATE TABLE ppln_col_mapng (
    mapng_id     SERIAL       PRIMARY KEY,
    ppln_id    INT          NOT NULL REFERENCES ppln(ppln_id) ON DELETE CASCADE,
    src_col  VARCHAR(128) NOT NULL,
    trget_col  VARCHAR(128) NOT NULL,
    src_ty    VARCHAR(50),
    trget_ty    VARCHAR(50),
    trsfm_rule VARCHAR(500),
    is_reqrd    BOOLEAN      DEFAULT FALSE,
    sort_ord     INT          DEFAULT 0,
    crtd_at     TIMESTAMPTZ  DEFAULT now(),
    crtd_by     UUID,
    updtd_at     TIMESTAMPTZ  DEFAULT now(),
    updtd_by     UUID,
    UNIQUE (ppln_id, src_col)
);

CREATE TABLE cdc_cnctr (
    cnctr_id   SERIAL        PRIMARY KEY,
    sys_id      INT           NOT NULL REFERENCES src_sys(sys_id),
    cnctr_nm VARCHAR(100)  NOT NULL,
    cnctr_ty VARCHAR(30),
    dbms_ty      VARCHAR(30),
    table_co    INT           DEFAULT 0,
    evnt_per_min BIGINT        DEFAULT 0,
    lag_secnd    INT           DEFAULT 0,
    cnfg         JSONB,
    stat         entity_status DEFAULT 'active',
    crtd_at     TIMESTAMPTZ   DEFAULT now(),
    crtd_by     UUID,
    updtd_at     TIMESTAMPTZ   DEFAULT now(),
    updtd_by     UUID
);

CREATE TABLE kafka_topc (
    topc_id        SERIAL        PRIMARY KEY,
    topc_nm      VARCHAR(200)  NOT NULL UNIQUE,
    clstr_nm    VARCHAR(100),
    prtitn_co INT           DEFAULT 3,
    rplctn     INT           DEFAULT 2,
    rtntn_hr INT           DEFAULT 168,
    msg_per_sec     BIGINT        DEFAULT 0,
    cnsmr_grps TEXT[],
    stat          entity_status DEFAULT 'active',
    crtd_at      TIMESTAMPTZ   DEFAULT now(),
    crtd_by      UUID,
    updtd_at      TIMESTAMPTZ   DEFAULT now(),
    updtd_by      UUID
);

CREATE TABLE extn_intgrn (
    intgrn_id   SERIAL        PRIMARY KEY,
    intgrn_nm VARCHAR(200)  NOT NULL,
    intgrn_ty VARCHAR(30),
    src_sys    VARCHAR(100),
    trget_sys    VARCHAR(100),
    prtcl         VARCHAR(30),
    endpt_url     VARCHAR(500),
    freq        VARCHAR(50),
    last_succes_at  TIMESTAMPTZ,
    last_fail_at     TIMESTAMPTZ,
    stat           entity_status DEFAULT 'active',
    crtd_at       TIMESTAMPTZ   DEFAULT now(),
    crtd_by       UUID,
    updtd_at       TIMESTAMPTZ   DEFAULT now(),
    updtd_by       UUID
);

CREATE TABLE dbt_model (
    dbt_model_id    SERIAL        PRIMARY KEY,
    model_nm      VARCHAR(200)  NOT NULL,
    model_path      VARCHAR(500),
    mtrlzn VARCHAR(30)   DEFAULT 'table',
    src_tbls   TEXT[],
    trget_table    VARCHAR(200),
    dc     TEXT,
    tags            TEXT[],
    last_run_at     TIMESTAMPTZ,
    last_run_stat VARCHAR(20),
    run_dur_secnd INT,
    owner_usr_id   UUID          REFERENCES usr_acnt(usr_id),
    stat          entity_status DEFAULT 'active',
    crtd_at      TIMESTAMPTZ   DEFAULT now(),
    crtd_by      UUID,
    updtd_at      TIMESTAMPTZ   DEFAULT now(),
    updtd_by      UUID
);

CREATE TABLE server_invntry (
    server_id   SERIAL        PRIMARY KEY,
    server_nm VARCHAR(100)  NOT NULL,
    server_ty VARCHAR(30),
    ip_addr  INET,
    os_ty     VARCHAR(50),
    cpu_cores   INT,
    mory_gb   INT,
    disk_gb     INT,
    envrn VARCHAR(20),
    dtcntr  VARCHAR(50),
    stat      entity_status DEFAULT 'active',
    crtd_at  TIMESTAMPTZ   DEFAULT now(),
    crtd_by  UUID,
    updtd_at  TIMESTAMPTZ   DEFAULT now(),
    updtd_by  UUID
);


-- ============================================================================
-- 4. 유통·활용 도메인
-- ============================================================================

CREATE TABLE data_product (
    product_id      UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_cd    VARCHAR(50)   NOT NULL UNIQUE,
    product_nm    VARCHAR(200)  NOT NULL,
    dc     TEXT,
    product_ty    VARCHAR(30)   DEFAULT 'api',
    domn_id       INT           REFERENCES domn(domn_id),
    scrty_lvl  data_security_level DEFAULT 'internal',
    ver         VARCHAR(20)   DEFAULT '1.0',
    endpt_url    VARCHAR(500),
    rt_limit      INT           DEFAULT 1000,
    tot_calls     BIGINT        DEFAULT 0,
    avg_rspns_ms INT           DEFAULT 0,
    sla_uptm      NUMERIC(5,2)  DEFAULT 99.9,
    owner_dept_id   INT           REFERENCES dept(dept_id),
    owner_usr_id   UUID          REFERENCES usr_acnt(usr_id),
    stat          entity_status DEFAULT 'active',
    pblshd_at    TIMESTAMPTZ,
    crtd_at      TIMESTAMPTZ   DEFAULT now(),
    crtd_by      UUID,
    updtd_at      TIMESTAMPTZ   DEFAULT now(),
    updtd_by      UUID
);

CREATE TABLE product_src (
    src_id   SERIAL      PRIMARY KEY,
    product_id  UUID        NOT NULL REFERENCES data_product(product_id) ON DELETE CASCADE,
    dset_id  UUID        NOT NULL REFERENCES dset(dset_id),
    join_ty   VARCHAR(20),
    join_key    VARCHAR(200),
    dc VARCHAR(200),
    sort_ord  INT         DEFAULT 0,
    crtd_at  TIMESTAMPTZ DEFAULT now(),
    crtd_by  UUID,
    updtd_at  TIMESTAMPTZ DEFAULT now(),
    updtd_by  UUID,
    UNIQUE (product_id, dset_id)
);

CREATE TABLE product_field (
    field_id      SERIAL        PRIMARY KEY,
    product_id    UUID          NOT NULL REFERENCES data_product(product_id) ON DELETE CASCADE,
    field_nm    VARCHAR(128)  NOT NULL,
    field_nm_ko VARCHAR(128),
    field_ty    VARCHAR(50)   NOT NULL,
    is_reqrd   BOOLEAN       DEFAULT FALSE,
    is_fltrbl BOOLEAN       DEFAULT FALSE,
    dc   VARCHAR(200),
    smple_val  VARCHAR(200),
    sort_ord    INT           DEFAULT 0,
    crtd_at    TIMESTAMPTZ   DEFAULT now(),
    crtd_by    UUID,
    updtd_at    TIMESTAMPTZ   DEFAULT now(),
    updtd_by    UUID,
    UNIQUE (product_id, field_nm)
);

CREATE TABLE api_key (
    key_id       UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
    usr_id      UUID          NOT NULL REFERENCES usr_acnt(usr_id),
    product_id   UUID          REFERENCES data_product(product_id),
    api_key_hash VARCHAR(256)  NOT NULL,
    key_prfx   VARCHAR(10),
    dc  VARCHAR(200),
    is_actv    BOOLEAN       DEFAULT TRUE,
    expirs_at   TIMESTAMPTZ,
    last_used_at TIMESTAMPTZ,
    tot_calls  BIGINT        DEFAULT 0,
    crtd_at   TIMESTAMPTZ   DEFAULT now(),
    crtd_by   UUID,
    updtd_at   TIMESTAMPTZ   DEFAULT now(),
    updtd_by   UUID
);

CREATE TABLE didntf_polcy (
    polcy_id    SERIAL             PRIMARY KEY,
    polcy_nm  VARCHAR(200)       NOT NULL,
    dc  TEXT,
    trget_lvl data_security_level,
    rule_co   INT                DEFAULT 0,
    is_actv    BOOLEAN            DEFAULT TRUE,
    aprvd_by  UUID               REFERENCES usr_acnt(usr_id),
    crtd_at   TIMESTAMPTZ        DEFAULT now(),
    crtd_by   UUID               REFERENCES usr_acnt(usr_id),
    updtd_at   TIMESTAMPTZ        DEFAULT now(),
    updtd_by   UUID
);

CREATE TABLE didntf_rule (
    rule_id        SERIAL               PRIMARY KEY,
    polcy_id      INT                  NOT NULL REFERENCES didntf_polcy(polcy_id) ON DELETE CASCADE,
    col_pttrn VARCHAR(200)         NOT NULL,
    rule_ty      deidentify_rule_type NOT NULL,
    rule_cnfg    JSONB,
    priort     INT                  DEFAULT 0,
    dc    VARCHAR(200),
    crtd_at     TIMESTAMPTZ          DEFAULT now(),
    crtd_by     UUID,
    updtd_at     TIMESTAMPTZ          DEFAULT now(),
    updtd_by     UUID
);

CREATE TABLE data_rqst (
    rqst_id      SERIAL          PRIMARY KEY,
    rqst_cd    VARCHAR(30)     NOT NULL UNIQUE,
    usr_id         UUID            NOT NULL REFERENCES usr_acnt(usr_id),
    dset_id      UUID            REFERENCES dset(dset_id),
    product_id      UUID            REFERENCES data_product(product_id),
    rqst_ty    VARCHAR(30)     NOT NULL,
    purps         TEXT,
    is_urgnt       BOOLEAN         DEFAULT FALSE,
    aprvl_stat approval_status DEFAULT 'pending',
    apprvr_id     UUID            REFERENCES usr_acnt(usr_id),
    aprvd_at     TIMESTAMPTZ,
    expir_at       TIMESTAMPTZ,
    crtd_at      TIMESTAMPTZ     DEFAULT now(),
    crtd_by      UUID,
    updtd_at      TIMESTAMPTZ     DEFAULT now(),
    updtd_by      UUID
);

CREATE TABLE rqst_atch (
    atch_id SERIAL        PRIMARY KEY,
    rqst_id    INT           NOT NULL REFERENCES data_rqst(rqst_id) ON DELETE CASCADE,
    file_nm     VARCHAR(200)  NOT NULL,
    file_path     VARCHAR(500)  NOT NULL,
    file_size     BIGINT        DEFAULT 0,
    mime_ty     VARCHAR(100),
    crtd_at    TIMESTAMPTZ   DEFAULT now(),
    crtd_by    UUID,
    updtd_at    TIMESTAMPTZ   DEFAULT now(),
    updtd_by    UUID
);

CREATE TABLE rqst_tmln (
    tmln_id   SERIAL          PRIMARY KEY,
    rqst_id    INT             NOT NULL REFERENCES data_rqst(rqst_id) ON DELETE CASCADE,
    actn_ty   VARCHAR(30)     NOT NULL,
    stat        approval_status NOT NULL,
    actr_usr_id UUID            REFERENCES usr_acnt(usr_id),
    cm       TEXT,
    actn_dt   TIMESTAMPTZ     DEFAULT now(),
    crtd_at    TIMESTAMPTZ     DEFAULT now(),
    crtd_by    UUID,
    updtd_at    TIMESTAMPTZ     DEFAULT now(),
    updtd_by    UUID
);

CREATE TABLE chart_cntnt (
    chart_id      SERIAL        PRIMARY KEY,
    chart_nm    VARCHAR(200)  NOT NULL,
    chart_ty    VARCHAR(30),
    dc   TEXT,
    cnfg        JSONB,
    data_src   VARCHAR(500),
    thumb_url VARCHAR(500),
    domn_id     INT           REFERENCES domn(domn_id),
    owner_usr_id UUID          REFERENCES usr_acnt(usr_id),
    is_public     BOOLEAN       DEFAULT FALSE,
    view_co    INT           DEFAULT 0,
    stat        entity_status DEFAULT 'active',
    crtd_at    TIMESTAMPTZ   DEFAULT now(),
    crtd_by    UUID,
    updtd_at    TIMESTAMPTZ   DEFAULT now(),
    updtd_by    UUID
);

CREATE TABLE extn_prvsn (
    prvsn_id   SERIAL        PRIMARY KEY,
    prvsn_nm VARCHAR(200)  NOT NULL,
    trget_org     VARCHAR(200)  NOT NULL,
    dset_id     UUID          REFERENCES dset(dset_id),
    product_id     UUID          REFERENCES data_product(product_id),
    prvsn_ty VARCHAR(30),
    freq      VARCHAR(30),
    rcrd_co   BIGINT        DEFAULT 0,
    last_prvdd  TIMESTAMPTZ,
    cntrct_strt DATE,
    cntrct_end   DATE,
    stat         entity_status DEFAULT 'active',
    crtd_at     TIMESTAMPTZ   DEFAULT now(),
    crtd_by     UUID,
    updtd_at     TIMESTAMPTZ   DEFAULT now(),
    updtd_by     UUID
);


-- ============================================================================
-- 5. 데이터 품질 도메인
-- ============================================================================

CREATE TABLE dq_rule (
    rule_id     SERIAL        PRIMARY KEY,
    rule_nm   VARCHAR(200)  NOT NULL,
    rule_cd   VARCHAR(50)   UNIQUE,
    rule_ty   VARCHAR(30)   NOT NULL,
    dset_id  UUID          REFERENCES dset(dset_id),
    col_nm VARCHAR(128),
    expr  TEXT,
    thrhld   NUMERIC(5,2)  DEFAULT 95.00,
    svrt    VARCHAR(10)   DEFAULT 'warning',
    dc TEXT,
    is_actv   BOOLEAN       DEFAULT TRUE,
    crtd_at  TIMESTAMPTZ   DEFAULT now(),
    crtd_by  UUID          REFERENCES usr_acnt(usr_id),
    updtd_at  TIMESTAMPTZ   DEFAULT now(),
    updtd_by  UUID
);

CREATE TABLE dq_exec (
    exec_id      BIGSERIAL   PRIMARY KEY,
    rule_id           INT         NOT NULL REFERENCES dq_rule(rule_id) ON DELETE CASCADE,
    dset_id        UUID        NOT NULL REFERENCES dset(dset_id),
    exec_dt    DATE        NOT NULL DEFAULT CURRENT_DATE,
    tot_rows        BIGINT      DEFAULT 0,
    passd_rows       BIGINT      DEFAULT 0,
    faild_rows       BIGINT      DEFAULT 0,
    score             NUMERIC(5,2),
    rst            VARCHAR(10) NOT NULL CHECK (rst IN ('pass','fail','error','skip')),
    err_msg     TEXT,
    exec_tm_ms INT,
    crtd_at        TIMESTAMPTZ DEFAULT now(),
    crtd_by        UUID,
    updtd_at        TIMESTAMPTZ DEFAULT now(),
    updtd_by        UUID
);

CREATE TABLE domn_qlity_score (
    score_id      SERIAL       PRIMARY KEY,
    domn_id     INT          NOT NULL REFERENCES domn(domn_id),
    score_dt    DATE         NOT NULL DEFAULT CURRENT_DATE,
    cmpltn  NUMERIC(5,2) DEFAULT 0,
    accrcy      NUMERIC(5,2) DEFAULT 0,
    cnstnc   NUMERIC(5,2) DEFAULT 0,
    tmlns    NUMERIC(5,2) DEFAULT 0,
    valid      NUMERIC(5,2) DEFAULT 0,
    uqe      NUMERIC(5,2) DEFAULT 0,
    ovrall_score NUMERIC(5,2) DEFAULT 0,
    dset_co INT          DEFAULT 0,
    rule_co    INT          DEFAULT 0,
    crtd_at    TIMESTAMPTZ  DEFAULT now(),
    crtd_by    UUID,
    updtd_at    TIMESTAMPTZ  DEFAULT now(),
    updtd_by    UUID,
    UNIQUE (domn_id, score_dt)
);

CREATE TABLE qlity_issue (
    issue_id      SERIAL      PRIMARY KEY,
    dset_id    UUID        NOT NULL REFERENCES dset(dset_id),
    rule_id       INT         REFERENCES dq_rule(rule_id),
    issue_ty    VARCHAR(30) NOT NULL,
    svrt      VARCHAR(10) DEFAULT 'warning',
    col_nm   VARCHAR(128),
    afctd_rows BIGINT      DEFAULT 0,
    dc   TEXT        NOT NULL,
    rsln    TEXT,
    stat        VARCHAR(20) DEFAULT 'open' CHECK (stat IN ('open','investigating','resolved','ignored')),
    asgnd_to   UUID        REFERENCES usr_acnt(usr_id),
    rslvd_at   TIMESTAMPTZ,
    crtd_at    TIMESTAMPTZ DEFAULT now(),
    crtd_by    UUID,
    updtd_at    TIMESTAMPTZ DEFAULT now(),
    updtd_by    UUID
);


-- ============================================================================
-- 6. 온톨로지 도메인
-- ============================================================================

CREATE TABLE onto_class (
    class_id        SERIAL        PRIMARY KEY,
    class_nm_ko   VARCHAR(100)  NOT NULL,
    class_nm_en   VARCHAR(100),
    class_uri       VARCHAR(200)  NOT NULL UNIQUE,
    parent_class_id INT           REFERENCES onto_class(class_id),
    dc     TEXT,
    instn_co  INT           DEFAULT 0,
    icon            VARCHAR(50),
    color           VARCHAR(7),
    sort_ord      INT           DEFAULT 0,
    crtd_at      TIMESTAMPTZ   DEFAULT now(),
    crtd_by      UUID,
    updtd_at      TIMESTAMPTZ   DEFAULT now(),
    updtd_by      UUID
);

CREATE TABLE onto_data_prprty (
    prprty_id   SERIAL        PRIMARY KEY,
    class_id      INT           NOT NULL REFERENCES onto_class(class_id) ON DELETE CASCADE,
    prprty_nm VARCHAR(100)  NOT NULL,
    prprty_uri  VARCHAR(200),
    data_ty     VARCHAR(50)   NOT NULL,
    crdnlt   VARCHAR(10)   DEFAULT '1',
    unit          VARCHAR(30),
    std_term_id   INT           REFERENCES glsry_term(term_id),
    dc   TEXT,
    sort_ord    INT           DEFAULT 0,
    crtd_at    TIMESTAMPTZ   DEFAULT now(),
    crtd_by    UUID,
    updtd_at    TIMESTAMPTZ   DEFAULT now(),
    updtd_by    UUID,
    UNIQUE (class_id, prprty_nm)
);

CREATE TABLE onto_rel (
    rel_id          SERIAL        PRIMARY KEY,
    src_class_id INT           NOT NULL REFERENCES onto_class(class_id) ON DELETE CASCADE,
    trget_class_id INT           NOT NULL REFERENCES onto_class(class_id) ON DELETE CASCADE,
    rel_nm_ko     VARCHAR(100)  NOT NULL,
    rel_nm_en     VARCHAR(100),
    rel_uri         VARCHAR(200),
    crdnlt     VARCHAR(10)   DEFAULT '0..*',
    drct       VARCHAR(10)   DEFAULT 'output' CHECK (drct IN ('output','input','bidirectional')),
    dc     TEXT,
    sort_ord      INT           DEFAULT 0,
    crtd_at      TIMESTAMPTZ   DEFAULT now(),
    crtd_by      UUID,
    updtd_at      TIMESTAMPTZ   DEFAULT now(),
    updtd_by      UUID,
    UNIQUE (src_class_id, trget_class_id, rel_uri)
);


-- ============================================================================
-- 7. 모니터링 도메인
-- ============================================================================

CREATE TABLE regn (
    regn_id   SERIAL       PRIMARY KEY,
    regn_cd VARCHAR(20)  NOT NULL UNIQUE,
    regn_nm VARCHAR(100) NOT NULL,
    sort_ord  INT          DEFAULT 0,
    crtd_at  TIMESTAMPTZ  DEFAULT now(),
    crtd_by  UUID,
    updtd_at  TIMESTAMPTZ  DEFAULT now(),
    updtd_by  UUID
);

CREATE TABLE office (
    office_id   SERIAL       PRIMARY KEY,
    regn_id   INT          NOT NULL REFERENCES regn(regn_id),
    office_cd VARCHAR(20)  NOT NULL UNIQUE,
    office_nm VARCHAR(100) NOT NULL,
    addr     VARCHAR(300),
    sort_ord  INT          DEFAULT 0,
    crtd_at  TIMESTAMPTZ  DEFAULT now(),
    crtd_by  UUID,
    updtd_at  TIMESTAMPTZ  DEFAULT now(),
    updtd_by  UUID
);

CREATE TABLE site (
    site_id   SERIAL         PRIMARY KEY,
    office_id INT            NOT NULL REFERENCES office(office_id),
    site_cd VARCHAR(20)    NOT NULL UNIQUE,
    site_nm VARCHAR(100)   NOT NULL,
    site_ty VARCHAR(30),
    la  NUMERIC(10,7),
    lngt NUMERIC(10,7),
    addr   VARCHAR(300),
    cpcty  NUMERIC(15,2),
    stat    entity_status  DEFAULT 'active',
    crtd_at TIMESTAMPTZ   DEFAULT now(),
    crtd_by UUID,
    updtd_at TIMESTAMPTZ   DEFAULT now(),
    updtd_by UUID
);

CREATE TABLE sensor_tag (
    tag_id       SERIAL        PRIMARY KEY,
    site_id      INT           NOT NULL REFERENCES site(site_id),
    sensor_cd  VARCHAR(50)   NOT NULL UNIQUE,
    sensor_nm  VARCHAR(100)  NOT NULL,
    sensor_ty  VARCHAR(30),
    unit         VARCHAR(20),
    min_rng    NUMERIC(12,4),
    max_rng    NUMERIC(12,4),
    instl_dt DATE,
    last_readng NUMERIC(12,4),
    last_read_at TIMESTAMPTZ,
    stat       entity_status DEFAULT 'active',
    crtd_at   TIMESTAMPTZ   DEFAULT now(),
    crtd_by   UUID,
    updtd_at   TIMESTAMPTZ   DEFAULT now(),
    updtd_by   UUID
);

CREATE TABLE asset_db (
    asset_db_id   SERIAL      PRIMARY KEY,
    asset_ty    VARCHAR(50) NOT NULL,
    asset_nm    VARCHAR(200),
    tot_co   INT         DEFAULT 0,
    actv_co  INT         DEFAULT 0,
    src_sys VARCHAR(100),
    last_sync_at  TIMESTAMPTZ,
    dc   TEXT,
    crtd_at    TIMESTAMPTZ DEFAULT now(),
    crtd_by    UUID,
    updtd_at    TIMESTAMPTZ DEFAULT now(),
    updtd_by    UUID
);


-- ============================================================================
-- 8. 커뮤니티·소통 도메인
-- ============================================================================

CREATE TABLE board_post (
    post_id       SERIAL        PRIMARY KEY,
    usr_id       UUID          NOT NULL REFERENCES usr_acnt(usr_id),
    tit         VARCHAR(300)  NOT NULL,
    cntnt       TEXT          NOT NULL,
    post_ty     VARCHAR(20)   NOT NULL CHECK (post_ty IN ('notice','internal','external')),
    is_pinnd     BOOLEAN       DEFAULT FALSE,
    view_co    INT           DEFAULT 0,
    like_co    INT           DEFAULT 0,
    cm_co INT           DEFAULT 0,
    stat        entity_status DEFAULT 'active',
    crtd_at    TIMESTAMPTZ   DEFAULT now(),
    crtd_by    UUID,
    updtd_at    TIMESTAMPTZ   DEFAULT now(),
    updtd_by    UUID
);

CREATE TABLE board_cm (
    cm_id   SERIAL        PRIMARY KEY,
    post_id      INT           NOT NULL REFERENCES board_post(post_id) ON DELETE CASCADE,
    usr_id      UUID          NOT NULL REFERENCES usr_acnt(usr_id),
    parent_id    INT           REFERENCES board_cm(cm_id),
    cm_text TEXT          NOT NULL,
    stat       entity_status DEFAULT 'active',
    crtd_at   TIMESTAMPTZ   DEFAULT now(),
    crtd_by   UUID,
    updtd_at   TIMESTAMPTZ   DEFAULT now(),
    updtd_by   UUID
);

CREATE TABLE resrce_archv (
    resrce_id    SERIAL        PRIMARY KEY,
    usr_id        UUID          NOT NULL REFERENCES usr_acnt(usr_id),
    resrce_nm  VARCHAR(300)  NOT NULL,
    dc    TEXT,
    file_nm      VARCHAR(200)  NOT NULL,
    file_path      VARCHAR(500)  NOT NULL,
    file_size      BIGINT        DEFAULT 0,
    mime_ty      VARCHAR(100),
    ctgry       VARCHAR(30),
    dwld_co INT           DEFAULT 0,
    stat         entity_status DEFAULT 'active',
    crtd_at     TIMESTAMPTZ   DEFAULT now(),
    crtd_by     UUID,
    updtd_at     TIMESTAMPTZ   DEFAULT now(),
    updtd_by     UUID
);


-- ============================================================================
-- 9. 시스템 관리 도메인
-- ============================================================================

CREATE TABLE scrty_polcy (
    polcy_id      SERIAL             PRIMARY KEY,
    polcy_nm    VARCHAR(200)       NOT NULL,
    polcy_ty    VARCHAR(30)        NOT NULL,
    dc    TEXT,
    rule_cnfg    JSONB,
    trget_lvl   data_security_level,
    is_actv      BOOLEAN            DEFAULT TRUE,
    eftv_from DATE,
    eftv_to   DATE,
    crtd_at     TIMESTAMPTZ        DEFAULT now(),
    crtd_by     UUID               REFERENCES usr_acnt(usr_id),
    updtd_at     TIMESTAMPTZ        DEFAULT now(),
    updtd_by     UUID
);

CREATE TABLE sys_intrfc (
    intrfc_id     SERIAL        PRIMARY KEY,
    intrfc_cd   VARCHAR(30)   NOT NULL UNIQUE,
    intrfc_nm   VARCHAR(200)  NOT NULL,
    src_sys_id INT           REFERENCES src_sys(sys_id),
    trget_sys_id INT           REFERENCES src_sys(sys_id),
    intrfc_ty   VARCHAR(30),
    prtcl         VARCHAR(30),
    freq        VARCHAR(30),
    drct        VARCHAR(10)   DEFAULT 'inbound' CHECK (drct IN ('inbound','outbound','bidirectional')),
    last_succes_at  TIMESTAMPTZ,
    last_fail_at     TIMESTAMPTZ,
    succes_rt     NUMERIC(5,2)  DEFAULT 100.00,
    avg_rspns_ms  INT           DEFAULT 0,
    stat           entity_status DEFAULT 'active',
    crtd_at       TIMESTAMPTZ   DEFAULT now(),
    crtd_by       UUID,
    updtd_at       TIMESTAMPTZ   DEFAULT now(),
    updtd_by       UUID
);

CREATE TABLE audit_log (
    log_id        BIGSERIAL   PRIMARY KEY,
    usr_id       UUID        REFERENCES usr_acnt(usr_id),
    usr_nm     VARCHAR(50),
    actn_ty   VARCHAR(30) NOT NULL,
    trget_table  VARCHAR(100),
    trget_id     VARCHAR(100),
    actn_dtl TEXT,
    ip_addr    INET,
    usr_agent    VARCHAR(500),
    rst        VARCHAR(10) DEFAULT 'success' CHECK (rst IN ('success','fail','denied')),
    crtd_at    TIMESTAMPTZ DEFAULT now(),
    crtd_by    UUID,
    updtd_at    TIMESTAMPTZ DEFAULT now(),
    updtd_by    UUID
);

CREATE TABLE ntcn (
    ntcn_id    BIGSERIAL    PRIMARY KEY,
    usr_id     UUID         NOT NULL REFERENCES usr_acnt(usr_id),
    ntcn_ty    noti_type    NOT NULL DEFAULT 'system',
    tit      VARCHAR(200) NOT NULL,
    msg    TEXT         NOT NULL,
    link_url   VARCHAR(500),
    is_read    BOOLEAN      DEFAULT FALSE,
    read_at    TIMESTAMPTZ,
    crtd_at TIMESTAMPTZ  DEFAULT now(),
    crtd_by UUID,
    updtd_at TIMESTAMPTZ  DEFAULT now(),
    updtd_by UUID
);

CREATE TABLE widg_tmplat (
    widg_id     SERIAL       PRIMARY KEY,
    widg_cd   VARCHAR(30)  NOT NULL UNIQUE,
    widg_nm   VARCHAR(100) NOT NULL,
    widg_ty   VARCHAR(30)  NOT NULL,
    dc   TEXT,
    cnfg_json   JSONB,
    thumb_url VARCHAR(500),
    min_width     INT          DEFAULT 1,
    min_hg     INT          DEFAULT 1,
    max_width     INT          DEFAULT 4,
    max_hg     INT          DEFAULT 4,
    ctgry      VARCHAR(30),
    is_actv     BOOLEAN      DEFAULT TRUE,
    crtd_at    TIMESTAMPTZ  DEFAULT now(),
    crtd_by    UUID,
    updtd_at    TIMESTAMPTZ  DEFAULT now(),
    updtd_by    UUID
);

CREATE TABLE usr_widg_layout (
    layout_id       SERIAL      PRIMARY KEY,
    usr_id         UUID        NOT NULL REFERENCES usr_acnt(usr_id) ON DELETE CASCADE,
    widg_id       INT         NOT NULL REFERENCES widg_tmplat(widg_id),
    positn_x      INT         DEFAULT 0,
    positn_y      INT         DEFAULT 0,
    width           INT         DEFAULT 1,
    hg           INT         DEFAULT 1,
    cnfg_ovrd JSONB,
    is_vsbl      BOOLEAN     DEFAULT TRUE,
    sort_ord      INT         DEFAULT 0,
    crtd_at      TIMESTAMPTZ DEFAULT now(),
    crtd_by      UUID,
    updtd_at      TIMESTAMPTZ DEFAULT now(),
    updtd_by      UUID,
    UNIQUE (usr_id, widg_id)
);

CREATE TABLE lnage_node (
    node_id     SERIAL       PRIMARY KEY,
    node_ty   VARCHAR(20)  NOT NULL CHECK (node_ty IN ('dataset','table','column','pipeline','system','product')),
    obj_id   VARCHAR(100) NOT NULL,
    obj_nm VARCHAR(200) NOT NULL,
    dc VARCHAR(300),
    mtdata    JSONB,
    crtd_at  TIMESTAMPTZ  DEFAULT now(),
    crtd_by  UUID,
    updtd_at  TIMESTAMPTZ  DEFAULT now(),
    updtd_by  UUID,
    UNIQUE (node_ty, obj_id)
);

CREATE TABLE lnage_edge (
    edge_id        SERIAL      PRIMARY KEY,
    src_node_id INT         NOT NULL REFERENCES lnage_node(node_id) ON DELETE CASCADE,
    trget_node_id INT         NOT NULL REFERENCES lnage_node(node_id) ON DELETE CASCADE,
    edge_ty      VARCHAR(20) DEFAULT 'transform',
    trsfmn TEXT,
    ppln_id    INT         REFERENCES ppln(ppln_id),
    crtd_at     TIMESTAMPTZ DEFAULT now(),
    crtd_by     UUID,
    updtd_at     TIMESTAMPTZ DEFAULT now(),
    updtd_by     UUID,
    UNIQUE (src_node_id, trget_node_id, edge_ty)
);

CREATE TABLE ai_chat_sesn (
    sesn_id    UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    usr_id       UUID         NOT NULL REFERENCES usr_acnt(usr_id),
    sesn_tit VARCHAR(200),
    model_nm    VARCHAR(50),
    msg_co INT          DEFAULT 0,
    is_archvd   BOOLEAN      DEFAULT FALSE,
    crtd_at    TIMESTAMPTZ  DEFAULT now(),
    crtd_by    UUID,
    updtd_at    TIMESTAMPTZ  DEFAULT now(),
    updtd_by    UUID
);

CREATE TABLE ai_chat_msg (
    msg_id   BIGSERIAL   PRIMARY KEY,
    sesn_id   UUID        NOT NULL REFERENCES ai_chat_sesn(sesn_id) ON DELETE CASCADE,
    role         VARCHAR(10) NOT NULL CHECK (role IN ('user','assistant','system')),
    msg_text TEXT        NOT NULL,
    tkns_used  INT         DEFAULT 0,
    rspns_ms  INT         DEFAULT 0,
    mtdata     JSONB,
    crtd_at   TIMESTAMPTZ DEFAULT now(),
    crtd_by   UUID,
    updtd_at   TIMESTAMPTZ DEFAULT now(),
    updtd_by   UUID
);

CREATE TABLE daly_dist_stats (
    stat_id         SERIAL       PRIMARY KEY,
    stat_dt       DATE         NOT NULL DEFAULT CURRENT_DATE,
    product_id      UUID         REFERENCES data_product(product_id),
    tot_calls     BIGINT       DEFAULT 0,
    succes_calls   BIGINT       DEFAULT 0,
    fail_calls      BIGINT       DEFAULT 0,
    avg_rspns_ms INT          DEFAULT 0,
    unique_usrs    INT          DEFAULT 0,
    data_vlm_mb  NUMERIC(12,2) DEFAULT 0,
    crtd_at      TIMESTAMPTZ  DEFAULT now(),
    crtd_by      UUID,
    updtd_at      TIMESTAMPTZ  DEFAULT now(),
    updtd_by      UUID,
    UNIQUE (stat_dt, product_id)
);

CREATE TABLE dept_usg_stats (
    stat_id        SERIAL      PRIMARY KEY,
    stat_dt      DATE        NOT NULL DEFAULT CURRENT_DATE,
    dept_id        INT         NOT NULL REFERENCES dept(dept_id),
    dset_co  INT         DEFAULT 0,
    api_calls      BIGINT      DEFAULT 0,
    dwld_co INT         DEFAULT 0,
    search_co   INT         DEFAULT 0,
    actv_usrs   INT         DEFAULT 0,
    crtd_at     TIMESTAMPTZ DEFAULT now(),
    crtd_by     UUID,
    updtd_at     TIMESTAMPTZ DEFAULT now(),
    updtd_by     UUID,
    UNIQUE (stat_dt, dept_id)
);

CREATE TABLE erp_sync_hist (
    sync_id        SERIAL      PRIMARY KEY,
    sync_ty      VARCHAR(30) NOT NULL,
    sync_drct VARCHAR(10) DEFAULT 'inbound',
    tot_rcrds  INT         DEFAULT 0,
    crtd_co  INT         DEFAULT 0,
    updtd_co  INT         DEFAULT 0,
    skipd_co  INT         DEFAULT 0,
    err_co    INT         DEFAULT 0,
    strtd_at     TIMESTAMPTZ DEFAULT now(),
    fnshed_at    TIMESTAMPTZ,
    stat         VARCHAR(20) DEFAULT 'running' CHECK (stat IN ('running','success','failed','cancelled')),
    err_dtl   TEXT,
    crtd_at     TIMESTAMPTZ DEFAULT now(),
    crtd_by     UUID,
    updtd_at     TIMESTAMPTZ DEFAULT now(),
    updtd_by     UUID
);


-- ============================================================================
-- 10. 인덱스
-- ============================================================================

CREATE INDEX idx_usr_acnt_dept      ON usr_acnt(dept_id);
CREATE INDEX idx_usr_acnt_role      ON usr_acnt(role_id);
CREATE INDEX idx_usr_acnt_stat    ON usr_acnt(stat);
CREATE INDEX idx_usr_acnt_login     ON usr_acnt(login_id);
CREATE INDEX idx_login_hist_usr     ON login_hist(usr_id, login_at DESC);
CREATE INDEX idx_dset_domn         ON dset(domn_id);
CREATE INDEX idx_dset_sys         ON dset(sys_id);
CREATE INDEX idx_dset_scrty       ON dset(scrty_lvl);
CREATE INDEX idx_dset_stat         ON dset(stat);
CREATE INDEX idx_dset_owner_dept     ON dset(owner_dept_id);
CREATE INDEX idx_dset_nm_gin       ON dset USING gin(to_tsvector('simple', dset_nm));
CREATE INDEX idx_dset_col_dset ON dset_col(dset_id);
CREATE INDEX idx_dset_tag_tag        ON dset_tag(tag_id);
CREATE INDEX idx_bmrk_usr          ON bmrk(usr_id);
CREATE INDEX idx_glsry_term_domn   ON glsry_term(domn_id);
CREATE INDEX idx_glsry_term_stat   ON glsry_term(stat);
CREATE INDEX idx_ppln_sys        ON ppln(sys_id);
CREATE INDEX idx_ppln_stat        ON ppln(stat);
CREATE INDEX idx_ppln_exec_pipe     ON ppln_exec(ppln_id, strtd_at DESC);
CREATE INDEX idx_ppln_exec_stat   ON ppln_exec(stat);
CREATE INDEX idx_data_product_domn    ON data_product(domn_id);
CREATE INDEX idx_data_product_stat    ON data_product(stat);
CREATE INDEX idx_api_key_usr           ON api_key(usr_id);
CREATE INDEX idx_api_key_product        ON api_key(product_id);
CREATE INDEX idx_data_rqst_usr      ON data_rqst(usr_id);
CREATE INDEX idx_data_rqst_stat    ON data_rqst(aprvl_stat);
CREATE INDEX idx_data_rqst_dset   ON data_rqst(dset_id);
CREATE INDEX idx_rqst_tmln_req   ON rqst_tmln(rqst_id, actn_dt DESC);
CREATE INDEX idx_dq_rule_dset        ON dq_rule(dset_id);
CREATE INDEX idx_dq_exec_rule      ON dq_exec(rule_id, exec_dt DESC);
CREATE INDEX idx_dq_exec_dset   ON dq_exec(dset_id, exec_dt DESC);
CREATE INDEX idx_qlity_issue_dset  ON qlity_issue(dset_id);
CREATE INDEX idx_qlity_issue_stat   ON qlity_issue(stat);
CREATE INDEX idx_domn_qlity_dt    ON domn_qlity_score(score_dt DESC);
CREATE INDEX idx_office_regn          ON office(regn_id);
CREATE INDEX idx_site_office            ON site(office_id);
CREATE INDEX idx_sensor_tag_site        ON sensor_tag(site_id);
CREATE INDEX idx_board_post_ty        ON board_post(post_ty, crtd_at DESC);
CREATE INDEX idx_board_post_usr        ON board_post(usr_id);
CREATE INDEX idx_board_cm_post     ON board_cm(post_id);
CREATE INDEX idx_audit_log_usr         ON audit_log(usr_id, crtd_at DESC);
CREATE INDEX idx_audit_log_actn       ON audit_log(actn_ty, crtd_at DESC);
CREATE INDEX idx_audit_log_dt         ON audit_log(crtd_at DESC);
CREATE INDEX idx_ntcn_usr      ON ntcn(usr_id, is_read, crtd_at DESC);
CREATE INDEX idx_lnage_edge_src    ON lnage_edge(src_node_id);
CREATE INDEX idx_lnage_edge_trget    ON lnage_edge(trget_node_id);
CREATE INDEX idx_ai_chat_sesn_usr   ON ai_chat_sesn(usr_id, crtd_at DESC);
CREATE INDEX idx_ai_chat_msg_sess   ON ai_chat_msg(sesn_id, crtd_at);
CREATE INDEX idx_daly_dist_stats_dt  ON daly_dist_stats(stat_dt DESC);
CREATE INDEX idx_dept_usg_stats_dt  ON dept_usg_stats(stat_dt DESC);


-- ============================================================================
-- 11. updated_at 자동 갱신 트리거
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updtd_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOR tbl IN
        SELECT table_name FROM information_schema.columns
        WHERE table_schema = 'public' AND column_name = 'updtd_at'
    LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_%s_updtd_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp()',
            tbl, tbl
        );
    END LOOP;
END;
$$;


-- ============================================================================
-- 11-A. K-water 데이터표준 사전 (데이터관리포탈 연동)
-- ============================================================================
-- 기존 데이터관리포탈에서 관리하는 표준 사전 4종(단어/도메인/용어/코드)을 수용한다.
-- 시드 데이터는 별도 파일로 관리: seed_std_word.sql, seed_std_domn_dict.sql,
--   seed_std_term.sql, seed_std_cd.sql

-- 표준단어사전
CREATE TABLE std_word (
    word_id      SERIAL        PRIMARY KEY,
    lgc_nm       VARCHAR(100)  NOT NULL,               -- 논리명 (한글)
    phys_nm      VARCHAR(50)   NOT NULL,               -- 물리명 (영문약어)
    phys_mean    VARCHAR(200),                          -- 물리의미 (영문풀네임)
    attr_cls     VARCHAR(5)    DEFAULT 'N',             -- 속성분류어 여부 (Y/N)
    synm         VARCHAR(200),                          -- 동의어
    dc           TEXT,                                  -- 설명
    crtd_at      TIMESTAMPTZ   DEFAULT now(),
    crtd_by      UUID,
    updtd_at     TIMESTAMPTZ   DEFAULT now(),
    updtd_by     UUID
);
CREATE UNIQUE INDEX uix_std_word_phys ON std_word (phys_nm);
COMMENT ON TABLE std_word IS '표준단어사전 – K-water 데이터관리포탈 기준';

-- 표준도메인사전
CREATE TABLE std_domn_dict (
    std_domn_id  SERIAL        PRIMARY KEY,
    domn_grp_nm  VARCHAR(100),                          -- 도메인그룹명
    domn_nm      VARCHAR(200)  NOT NULL,                -- 도메인명
    domn_lgc_nm  VARCHAR(200),                          -- 도메인논리명
    data_ty      VARCHAR(30),                           -- 데이터유형 (NUMERIC, VARCHAR 등)
    data_len     NUMERIC,                               -- 길이
    deci_point   NUMERIC,                               -- 소수점
    psnl_info_yn VARCHAR(5),                            -- 개인정보여부
    enc_yn       VARCHAR(5),                            -- 암호화여부
    scrbl        VARCHAR(50),                           -- 스크램블
    dc           TEXT,                                  -- 설명
    crtd_at      TIMESTAMPTZ   DEFAULT now(),
    crtd_by      UUID,
    updtd_at     TIMESTAMPTZ   DEFAULT now(),
    updtd_by     UUID
);
CREATE UNIQUE INDEX uix_std_domn_dict_nm ON std_domn_dict (domn_nm);
COMMENT ON TABLE std_domn_dict IS '표준도메인사전 – K-water 데이터관리포탈 기준';

-- 표준용어사전
CREATE TABLE std_term (
    std_term_id   SERIAL        PRIMARY KEY,
    lgc_nm        VARCHAR(200)  NOT NULL,               -- 논리명 (한글)
    phys_nm       VARCHAR(200)  NOT NULL,               -- 물리명 (영문약어 조합)
    eng_mean      VARCHAR(500),                         -- 영문의미
    domn_lgc_nm   VARCHAR(200),                         -- 도메인논리명
    domn_lgc_abbr VARCHAR(50),                          -- 도메인논리약어
    domn_grp      VARCHAR(100),                         -- 도메인그룹
    data_ty       VARCHAR(30),                          -- 데이터유형
    data_len      NUMERIC,                              -- 길이
    deci_point    NUMERIC,                              -- 소수점
    psnl_info_yn  VARCHAR(5),                           -- 개인정보여부
    enc_yn        VARCHAR(5),                           -- 암호화여부
    scrbl         VARCHAR(50),                          -- 스크램블
    dc            TEXT,                                 -- 설명
    crtd_at       TIMESTAMPTZ   DEFAULT now(),
    crtd_by       UUID,
    updtd_at      TIMESTAMPTZ   DEFAULT now(),
    updtd_by      UUID
);
CREATE UNIQUE INDEX uix_std_term_phys ON std_term (phys_nm);
COMMENT ON TABLE std_term IS '표준용어사전 – K-water 데이터관리포탈 기준';

-- 표준코드그룹사전
CREATE TABLE std_cd_grp (
    std_cd_grp_id SERIAL        PRIMARY KEY,
    sys_grp       VARCHAR(50),                          -- 코드그룹 (시스템구분): ADT(감사), SCM(공통) 등
    lgc_nm        VARCHAR(200)  NOT NULL,               -- 논리명
    phys_nm       VARCHAR(200),                         -- 물리명
    cd_desc       TEXT,                                 -- 코드설명
    cd_cls        VARCHAR(30),                          -- 코드구분
    cd_len        INT,                                  -- 길이
    cd_id         VARCHAR(50)   NOT NULL,               -- 코드ID (원본 키)
    crtd_at       TIMESTAMPTZ   DEFAULT now(),
    crtd_by       UUID,
    updtd_at      TIMESTAMPTZ   DEFAULT now(),
    updtd_by      UUID
);
CREATE UNIQUE INDEX uix_std_cd_grp_cd_id ON std_cd_grp (cd_id);
COMMENT ON TABLE std_cd_grp IS '표준코드그룹사전 – K-water 데이터관리포탈 기준';

-- 표준코드사전
CREATE TABLE std_cd (
    std_cd_id     SERIAL        PRIMARY KEY,
    std_cd_grp_id INT           NOT NULL REFERENCES std_cd_grp(std_cd_grp_id) ON DELETE CASCADE,
    cd_val        VARCHAR(100)  NOT NULL,               -- 코드값
    cd_val_nm     VARCHAR(200),                         -- 코드값명
    sort_ord      INT           DEFAULT 0,              -- 정렬순서
    prnt_cd_nm    VARCHAR(200),                         -- 부모코드명
    prnt_cd_val   VARCHAR(100),                         -- 부모코드값
    dc            TEXT,                                 -- 설명
    aply_bgn_dt   DATE,                                 -- 적용시작일자
    aply_end_dt   DATE,                                 -- 적용종료일자
    crtd_at       TIMESTAMPTZ   DEFAULT now(),
    crtd_by       UUID,
    updtd_at      TIMESTAMPTZ   DEFAULT now(),
    updtd_by      UUID,
    UNIQUE (std_cd_grp_id, cd_val)
);
COMMENT ON TABLE std_cd IS '표준코드사전 – K-water 데이터관리포탈 기준';


-- ============================================================================
-- 11-2. DB 복구 로그 관리
-- ============================================================================

-- DB 복구 로그 이력 (메인)
CREATE TABLE db_rcvry_log (
    rcvry_log_id    BIGSERIAL       PRIMARY KEY,
    asset_db_id     INT             REFERENCES asset_db(asset_db_id),
    rcvry_ty        VARCHAR(30)     NOT NULL CHECK (rcvry_ty IN ('full','incremental','point_in_time','differential')),
    stat            VARCHAR(20)     DEFAULT 'running' CHECK (stat IN ('running','success','failed','cancelled')),
    strtd_at        TIMESTAMPTZ     NOT NULL DEFAULT now(),
    fnshed_at       TIMESTAMPTZ,
    dur_secnd       INT,
    bkup_src        VARCHAR(200),
    bkup_dt         TIMESTAMPTZ,
    tot_rcrds       BIGINT          DEFAULT 0,
    rcvrd_rcrds     BIGINT          DEFAULT 0,
    err_rcrds       BIGINT          DEFAULT 0,
    data_sz_mb      NUMERIC(12,2),
    exec_usr_id     UUID            REFERENCES usr_acnt(usr_id),
    vrfy_stat       VARCHAR(20)     DEFAULT 'pending' CHECK (vrfy_stat IN ('pending','verified','failed')),
    vrfy_at         TIMESTAMPTZ,
    vrfy_by         UUID            REFERENCES usr_acnt(usr_id),
    vrfy_rslt       TEXT,
    err_msg         TEXT,
    err_dtl         JSONB,
    dc              TEXT,
    crtd_at         TIMESTAMPTZ     DEFAULT now(),
    crtd_by         UUID,
    updtd_at        TIMESTAMPTZ     DEFAULT now(),
    updtd_by        UUID
);

CREATE INDEX idx_rcvry_log_asset ON db_rcvry_log (asset_db_id, strtd_at DESC);
CREATE INDEX idx_rcvry_log_stat  ON db_rcvry_log (stat);
CREATE INDEX idx_rcvry_log_vrfy  ON db_rcvry_log (vrfy_stat);
CREATE INDEX idx_rcvry_log_dt    ON db_rcvry_log (strtd_at DESC);

COMMENT ON TABLE db_rcvry_log IS 'DB별 복구 로그 이력, 복구 실행·검증 관리';

-- DB 복구 상세 내역 (테이블 단위)
CREATE TABLE db_rcvry_dtl (
    rcvry_dtl_id    BIGSERIAL       PRIMARY KEY,
    rcvry_log_id    BIGINT          NOT NULL REFERENCES db_rcvry_log(rcvry_log_id) ON DELETE CASCADE,
    trget_table     VARCHAR(200)    NOT NULL,
    tot_rcrds       BIGINT          DEFAULT 0,
    rcvrd_rcrds     BIGINT          DEFAULT 0,
    err_rcrds       BIGINT          DEFAULT 0,
    stat            VARCHAR(20)     DEFAULT 'running' CHECK (stat IN ('running','success','failed','cancelled')),
    strtd_at        TIMESTAMPTZ     DEFAULT now(),
    fnshed_at       TIMESTAMPTZ,
    dur_secnd       INT,
    err_msg         TEXT,
    crtd_at         TIMESTAMPTZ     DEFAULT now(),
    crtd_by         UUID,
    updtd_at        TIMESTAMPTZ     DEFAULT now(),
    updtd_by        UUID
);

CREATE INDEX idx_rcvry_dtl_log ON db_rcvry_dtl (rcvry_log_id);

COMMENT ON TABLE db_rcvry_dtl IS 'DB 복구 상세 내역, 테이블 단위 복구 결과';


-- ============================================================================
-- 11-3. 연계 DB 접속 설정 / 백업 스케줄 / 복제·이관
-- ============================================================================

-- 연계 DB 접속 설정
CREATE TABLE db_cnctn_cnfg (
    cnctn_cnfg_id   SERIAL          PRIMARY KEY,
    cnfg_nm         VARCHAR(200)    NOT NULL,
    dbms_ty         VARCHAR(30)     NOT NULL,
    host_addr       VARCHAR(200)    NOT NULL,
    port_no         INT             NOT NULL,
    db_nm           VARCHAR(100),
    schma_nm        VARCHAR(100),
    usr_nm          VARCHAR(100),
    ntwk_zone       VARCHAR(20)     CHECK (ntwk_zone IN ('FA','OA','DMZ','IoT')),
    scrty_lvl       data_security_level DEFAULT 'internal',
    cnctn_stat      VARCHAR(20)     DEFAULT 'disconnected' CHECK (cnctn_stat IN ('connected','disconnected','error')),
    last_test_at    TIMESTAMPTZ,
    dc              TEXT,
    crtd_at         TIMESTAMPTZ     DEFAULT now(),
    crtd_by         UUID,
    updtd_at        TIMESTAMPTZ     DEFAULT now(),
    updtd_by        UUID
);

CREATE INDEX idx_cnctn_cnfg_dbms ON db_cnctn_cnfg (dbms_ty);
CREATE INDEX idx_cnctn_cnfg_stat ON db_cnctn_cnfg (cnctn_stat);

COMMENT ON TABLE db_cnctn_cnfg IS '연계 DB 접속 설정, DBMS별 접속 정보 관리';

-- 백업 복구 스케줄 설정
CREATE TABLE bkup_sched (
    sched_id        SERIAL          PRIMARY KEY,
    cnctn_cnfg_id   INT             NOT NULL REFERENCES db_cnctn_cnfg(cnctn_cnfg_id),
    sched_nm        VARCHAR(200)    NOT NULL,
    bkup_ty         VARCHAR(30)     NOT NULL CHECK (bkup_ty IN ('full','incremental','differential')),
    cron_expr       VARCHAR(50)     NOT NULL,
    rtntn_days      INT             DEFAULT 30,
    bkup_path       VARCHAR(500),
    is_actv         BOOLEAN         DEFAULT true,
    last_exec_at    TIMESTAMPTZ,
    next_exec_at    TIMESTAMPTZ,
    fail_noti       BOOLEAN         DEFAULT true,
    dc              TEXT,
    crtd_at         TIMESTAMPTZ     DEFAULT now(),
    crtd_by         UUID,
    updtd_at        TIMESTAMPTZ     DEFAULT now(),
    updtd_by        UUID
);

CREATE INDEX idx_bkup_sched_cnfg ON bkup_sched (cnctn_cnfg_id);
CREATE INDEX idx_bkup_sched_actv ON bkup_sched (is_actv);

COMMENT ON TABLE bkup_sched IS '백업 복구 스케줄 설정, 크론 기반 자동 백업 관리';

-- 백업 복제·이관 이력
CREATE TABLE bkup_repl_hist (
    repl_id         BIGSERIAL       PRIMARY KEY,
    sched_id        INT             REFERENCES bkup_sched(sched_id),
    cnctn_cnfg_id   INT             REFERENCES db_cnctn_cnfg(cnctn_cnfg_id),
    repl_ty         VARCHAR(30)     NOT NULL CHECK (repl_ty IN ('full','incremental')),
    repl_drct       VARCHAR(20)     DEFAULT 'inbound' CHECK (repl_drct IN ('inbound','outbound')),
    stat            VARCHAR(20)     DEFAULT 'running' CHECK (stat IN ('running','success','failed','cancelled')),
    strtd_at        TIMESTAMPTZ     NOT NULL DEFAULT now(),
    fnshed_at       TIMESTAMPTZ,
    dur_secnd       INT,
    tot_rcrds       BIGINT          DEFAULT 0,
    replcd_rcrds    BIGINT          DEFAULT 0,
    err_rcrds       BIGINT          DEFAULT 0,
    data_sz_mb      NUMERIC(12,2),
    vrfy_stat       VARCHAR(20)     DEFAULT 'pending' CHECK (vrfy_stat IN ('pending','verified','failed')),
    err_msg         TEXT,
    err_dtl         JSONB,
    crtd_at         TIMESTAMPTZ     DEFAULT now(),
    crtd_by         UUID,
    updtd_at        TIMESTAMPTZ     DEFAULT now(),
    updtd_by        UUID
);

CREATE INDEX idx_repl_hist_sched ON bkup_repl_hist (sched_id, strtd_at DESC);
CREATE INDEX idx_repl_hist_cnfg  ON bkup_repl_hist (cnctn_cnfg_id, strtd_at DESC);
CREATE INDEX idx_repl_hist_stat  ON bkup_repl_hist (stat);

COMMENT ON TABLE bkup_repl_hist IS '백업 복제·이관 이력, 증분/전체 복제 실행 결과';


-- ============================================================================
-- 12. 초기 데이터
-- ============================================================================

INSERT INTO role (role_cd, role_nm, role_grp, role_lvl, data_clrnc) VALUES
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

INSERT INTO domn (domn_cd, domn_nm, color, icon) VALUES
    ('WATER',    '수자원',   '#3B82F6', 'droplet'),
    ('QUALITY',  '수질',     '#10B981', 'flask'),
    ('ENERGY',   '에너지',   '#F59E0B', 'zap'),
    ('INFRA',    '인프라',   '#8B5CF6', 'building'),
    ('CUSTOMER', '고객',     '#EF4444', 'users'),
    ('SAFETY',   '안전',     '#6366F1', 'shield'),
    ('FINANCE',  '경영관리', '#EC4899', 'briefcase');

INSERT INTO cd_grp (grp_cd, grp_nm, dc) VALUES
    ('CD_REGION',         '유역코드',       '한강/낙동강/금강/영산강·섬진강 등'),
    ('CD_SECURITY_LEVEL', '보안등급',       '공개/내부일반/내부중요/기밀'),
    ('CD_ASSET_TYPE',     '데이터자산유형', '테이블/API/파일/뷰/스트림'),
    ('CD_COLLECT_METHOD', '수집방식',       'CDC/배치/API/파일/스트리밍/마이그레이션'),
    ('CD_DBMS_TYPE',      'DBMS유형',       'PostgreSQL/Oracle/MySQL/MSSQL/SAP_HANA'),
    ('CD_DQ_DIMENSION',   '품질차원',       '완전성/정확성/일관성/적시성/유효성/유일성'),
    ('CD_CHART_TYPE',     '차트유형',       'bar/line/pie/scatter/heatmap/map'),
    ('CD_BOARD_TYPE',     '게시판유형',     '공지사항/내부/외부'),
    ('CD_REQUEST_TYPE',   '신청유형',       '다운로드/API접근/공유/반출');
