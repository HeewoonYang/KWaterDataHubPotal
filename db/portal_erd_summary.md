# K-water DataHub Portal — DB 모델 설계 요약

> 대상: 포탈 자체 운영 데이터 (연계·수집된 원천 데이터 제외)
> DBMS: PostgreSQL 15+
> 작성일: 2026-03-11

---

## 1. 전체 구성

| 구분 | 테이블 수 | ENUM 타입 |
|------|:---------:|:---------:|
| 사용자·조직·권한 | 8 | login_type |
| 카탈로그·메타데이터 | 14 | data_asset_type, data_security_level |
| 수집 관리 | 16 | collect_method |
| 유통·활용 | 11 | deidentify_rule_type |
| 데이터 품질 | 4 | — |
| 온톨로지 | 3 | — |
| 모니터링 | 5 | — |
| 커뮤니티 | 3 | — |
| 시스템관리 | 21 | noti_type |
| K-water 데이터표준 사전 | 5 | — |
| **합계** | **81** | **7 ENUM** |

공통 ENUM: `entity_status`, `approval_status`

---

## 2. 도메인별 테이블 목록

### 2-1. 사용자·조직·권한 (7개)

| # | 테이블 | PK | 핵심 FK/관계 | 설명 |
|---|--------|-----|-------------|------|
| 1 | `divs` | divs_id | — | 본부/권역 |
| 2 | `dept` | dept_id | → divs | 부서/팀 |
| 3 | `role` | role_id | — | 역할 정의 (RBAC) |
| 4 | `usr_acnt` | usr_id (UUID) | → dept, role | 사용자 계정 |
| 5 | `menu` | menu_id | → menu (자기참조) | 메뉴/화면 정의 |
| 6 | `role_menu_perm` | (role_id, menu_id) | → role, menu | 역할별 메뉴 권한 |
| 7 | `login_hist` | hist_id | → usr_acnt | 로그인 이력 |

### 2-2. 카탈로그·메타데이터 (14개)

| # | 테이블 | PK | 핵심 FK/관계 | 설명 |
|---|--------|-----|-------------|------|
| 8 | `domn` | domn_id | — | 비즈니스 도메인 |
| 9 | `src_sys` | sys_id | → dept | 원천시스템 |
| 10 | `dset` | dset_id (UUID) | → domn, system, dept, user | 데이터셋 카탈로그 |
| 11 | `dset_col` | col_id | → dset, glsry_term | 컬럼 스키마+프로파일링 |
| 12 | `tag` | tag_id | — | 태그 |
| 13 | `dset_tag` | (dset_id, tag_id) | → dset, tag | N:M 매핑 |
| 14 | `bmrk` | bmrk_id | → user, dset | 즐겨찾기 |
| 15 | `glsry_term` | term_id | → domn, user | 표준용어사전 |
| 16 | `glsry_hist` | hist_id | → glsry_term, user | 용어 변경이력 |
| 17 | `cd_grp` | group_id | — | 공통코드 그룹 |
| 18 | `cd` | cd_id | → cd_grp | 공통코드 값 |
| 19 | `data_model` | model_id | → domn, user | 논리/물리 모델 |
| 20 | `model_entty` | entty_id | → data_model | 모델 엔티티 |
| 21 | `model_atrb` | atrb_id | → model_entty | 모델 속성 |

### 2-3. 수집 관리 (16개)

| # | 테이블 | PK | 핵심 FK/관계 | 설명 |
|---|--------|-----|-------------|------|
| 22 | `ppln` | ppln_id | → src_sys, user, dept | 수집 파이프라인 |
| 23 | `ppln_exec` | exec_id | → ppln | 실행 이력 |
| 24 | `ppln_col_mapng` | mapng_id | → ppln | 컬럼 매핑·변환 |
| 25 | `cdc_cnctr` | cnctr_id | → src_sys | CDC 커넥터 |
| 26 | `kafka_topc` | topic_id | — | Kafka 토픽 |
| 27 | `extn_intgrn` | intgrn_id | — | 외부 연계 |
| 28 | `dbt_model` | dbt_model_id | → user | dbt 변환 모델 |
| 29 | `server_invntry` | server_id | — | 서버 인프라 자산 |
| 30a | `db_conn` | db_conn_id | → usr_acnt | DB 연결 정보 (요구사항 001) |
| 30b | `db_conn_usr` | db_conn_usr_id | → db_conn | DB 접속 사용자 (요구사항 002) |
| 30c | `tbl_mapng` | tbl_mapng_id | → extn_intgrn, db_conn | 테이블 매핑 (요구사항 004) |
| 30d | `tbl_mapng_hist` | mapng_hist_id | → tbl_mapng | 매핑 변경 이력 (요구사항 004) |
| 30e | `db_view_def` | view_def_id | → db_conn | 뷰 정의 (요구사항 006) |
| 30f | `migr_job` | migr_job_id | → db_conn | 마이그레이션 작업 (요구사항 007) |
| 30g | `migr_exec` | migr_exec_id | → migr_job | 마이그레이션 실행 (요구사항 007+008) |
| 30h | `migr_exec_dtl` | migr_exec_dtl_id | → migr_exec | 마이그레이션 상세 (요구사항 008) |

### 2-4. 유통·활용 (11개)

| # | 테이블 | PK | 핵심 FK/관계 | 설명 |
|---|--------|-----|-------------|------|
| 30 | `data_product` | product_id (UUID) | → domn, dept, user | Data Product |
| 31 | `product_src` | source_id | → product, dset | 소스 매핑 |
| 32 | `product_field` | field_id | → product | 필드 정의 |
| 33 | `api_key` | key_id (UUID) | → user, product | API 키 |
| 34 | `didntf_polcy` | policy_id | → user | 비식별화 정책 |
| 35 | `didntf_rule` | rule_id | → policy | 비식별화 규칙 |
| 36 | `data_rqst` | rqst_id | → user, dset, product | 데이터 신청 |
| 37 | `rqst_atch` | atch_id | → request | 첨부파일 |
| 38 | `rqst_tmln` | tmln_id | → request, user | 처리 타임라인 |
| 39 | `chart_cntnt` | chart_id | → domn, user | 차트 콘텐츠 |
| 40 | `extn_prvsn` | prvsn_id | → dset, product | 외부 제공 현황 |

### 2-5. 데이터 품질 (4개)

| # | 테이블 | PK | 핵심 FK/관계 | 설명 |
|---|--------|-----|-------------|------|
| 41 | `dq_rule` | rule_id | → dset, user | 품질 검증 규칙 |
| 42 | `dq_exec` | exec_id | → rule, dset | 검증 실행 결과 |
| 43 | `domn_qlity_score` | score_id | → domn | 도메인별 품질 점수 |
| 44 | `qlity_issue` | issue_id | → dset, rule, user | 품질 이슈 |

### 2-6. 온톨로지 (3개)

| # | 테이블 | PK | 핵심 FK/관계 | 설명 |
|---|--------|-----|-------------|------|
| 45 | `onto_class` | class_id | → onto_class (자기참조) | 온톨로지 클래스 |
| 46 | `onto_data_prprty` | prprty_id | → class, glsry_term | 데이터 속성 |
| 47 | `onto_rel` | rel_id | → class (source/target) | 클래스 간 관계 |

### 2-7. 모니터링 (5개)

| # | 테이블 | PK | 핵심 FK/관계 | 설명 |
|---|--------|-----|-------------|------|
| 48 | `regn` | regn_id | — | 유역/지사 |
| 49 | `office` | office_id | → regn | 사무소 |
| 50 | `site` | site_id | → office | 사업장/현장 |
| 51 | `sensor_tag` | tag_id | → site | 센서 태그 (메타만) |
| 52 | `asset_db` | asset_db_id | — | 자산DB 현황 |

### 2-8. 커뮤니티 (3개)

| # | 테이블 | PK | 핵심 FK/관계 | 설명 |
|---|--------|-----|-------------|------|
| 53 | `board_post` | post_id | → user | 게시판 글 |
| 54 | `board_cm` | cm_id | → post, user, comment(대댓글) | 댓글 |
| 55 | `resrce_archv` | resrce_id | → user | 자료실 |

### 2-10. K-water 데이터표준 사전 (5개) — 데이터관리포탈 연동

| # | 테이블 | PK | 핵심 FK/관계 | 설명 | 시드 건수 |
|---|--------|-----|-------------|------|:---------:|
| 69 | `std_word` | word_id | — | 표준단어사전 | 6,306 |
| 70 | `std_domn_dict` | std_domn_id | — | 표준도메인사전 | 615 |
| 71 | `std_term` | std_term_id | — | 표준용어사전 | 41,724 |
| 72 | `std_cd_grp` | std_cd_grp_id | — | 표준코드그룹사전 | 3,572 |
| 73 | `std_cd` | std_cd_id | → std_cd_grp | 표준코드사전 | 139,288 |

> 시드 데이터 원본: K-water 데이터관리포탈 표준 데이터 조회 엑셀 4종
> (`seed_std_word.sql`, `seed_std_domn_dict.sql`, `seed_std_term.sql`, `seed_std_cd.sql`)

### 2-9. 시스템관리 (21개)

| # | 테이블 | PK | 핵심 FK/관계 | 설명 |
|---|--------|-----|-------------|------|
| 56 | `scrty_polcy` | policy_id | → user | 보안 정책 |
| 57 | `sys_intrfc` | intrfc_id | → src_sys (×2) | 인터페이스 |
| 58 | `audit_log` | log_id | → user | 감사 로그 |
| 59 | `ntcn` | ntcn_id | → user | 알림 |
| 60 | `widg_tmplat` | widget_id | — | 위젯 템플릿 |
| 61 | `usr_widg_layout` | layout_id | → user, widget | 위젯 배치 |
| 62 | `lnage_node` | node_id | — | 리니지 노드 |
| 63 | `lnage_edge` | edge_id | → node (×2), ppln | 리니지 엣지 |
| 64 | `ai_chat_sesn` | sesn_id (UUID) | → user | AI 대화 세션 |
| 65 | `ai_chat_msg` | msg_id | → session | AI 메시지 |
| 66 | `daly_dist_stats` | stat_id | → product | 일별 유통 통계 |
| 67 | `dept_usg_stats` | stat_id | → dept | 부서별 활용 통계 |
| 68 | `erp_sync_hist` | sync_id | — | ERP 동기화 이력 |
| 69 | `db_rcvry_log` | rcvry_log_id | → asset_db, user (×2) | DB 복구 로그 이력 |
| 70 | `db_rcvry_dtl` | rcvry_dtl_id | → db_rcvry_log | DB 복구 상세 내역 |
| 71 | `db_cnctn_cnfg` | cnctn_cnfg_id | — | 연계 DB 접속 설정 |
| 72 | `bkup_sched` | sched_id | → db_cnctn_cnfg | 백업 복구 스케줄 |
| 73 | `bkup_repl_hist` | repl_id | → bkup_sched, db_cnctn_cnfg | 백업 복제·이관 이력 |
| 74 | `intfc_endpt` | endpt_id | — | 연계 엔드포인트 등록 |
| 75 | `intfc_chk_hist` | chk_id | → intfc_endpt | 연계 점검 이력 |
| 76 | `intfc_log` | log_id | → intfc_endpt | 연계 송수신 로그 |

---

## 3. ERD 관계도

```
┌─────────────────────────────────────────────────────────────────────┐
│                      사용자·조직·권한                                │
│                                                                     │
│  divs ──1:N──▸ dept ──1:N──▸ usr_acnt                 │
│                                            │                        │
│                    role ──────────────────┘ (N:1)                   │
│                      │                                              │
│                      └──N:M──▸ menu  (via role_menu_perm)          │
│                                                                     │
│  usr_acnt ──1:N──▸ login_hist                               │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                    카탈로그·메타데이터                                │
│                                                                     │
│  domn ──1:N──▸ dset ◂──N:1── src_sys                    │
│                    │                                                │
│                    ├──1:N──▸ dset_col ──N:1──▸ glsry_term  │
│                    ├──N:M──▸ tag  (via dset_tag)                │
│                    └──1:N──▸ bmrk                              │
│                                                                     │
│  domn ──1:N──▸ glsry_term ──1:N──▸ glsry_hist           │
│  domn ──1:N──▸ data_model ──1:N──▸ model_entty ──1:N──▸ attr   │
│  cd_grp ──1:N──▸ cd                                          │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                       수집 관리                                     │
│                                                                     │
│  src_sys ──1:N──▸ ppln ──1:N──▸ ppln_exec       │
│                    │        └──1:N──▸ ppln_col_mapng      │
│                    └──1:N──▸ cdc_cnctr                         │
│                                                                     │
│  kafka_topc    extn_intgrn    dbt_model    server_inv    │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                      유통·활용                                      │
│                                                                     │
│  data_product ──1:N──▸ product_src ◂──N:1── dset             │
│       │         └──1:N──▸ product_field                            │
│       └──1:N──▸ api_key                                            │
│                                                                     │
│  didntf_polcy ──1:N──▸ didntf_rule                        │
│                                                                     │
│  data_rqst ──1:N──▸ rqst_atch                          │
│       └────────1:N──▸ rqst_tmln                             │
│                                                                     │
│  chart_cntnt    extn_prvsn                                │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                       품질 관리                                     │
│                                                                     │
│  dq_rule ──1:N──▸ dq_exec                                    │
│  domn ──1:N──▸ domn_qlity_score                              │
│  dset ──1:N──▸ qlity_issue                                    │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                      온톨로지                                       │
│                                                                     │
│  onto_class (자기참조: parent) ──1:N──▸ onto_data_prprty          │
│       └──────────────────N:M──▸ onto_rel                  │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                      모니터링                                       │
│                                                                     │
│  regn ──1:N──▸ office ──1:N──▸ site ──1:N──▸ sensor_tag          │
│  asset_db (독립)                                              │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                     시스템관리                                       │
│                                                                     │
│  audit_log (사용자 작업 추적, 월별 파티셔닝 권장)                    │
│  ntcn (사용자 알림)                                         │
│  widg_tmplat ──1:N──▸ usr_widg_layout                       │
│  lnage_node ◂──N:M──▸ lnage_edge                              │
│  ai_chat_sesn ──1:N──▸ ai_chat_msg                          │
│  daly_dist_stats / dept_usg_stats (통계 집계)                    │
│  erp_sync_hist (ERP 동기화 이력)                                 │
│  sys_intrfc / scrty_polcy                                 │
│  asset_db ──1:N──▸ db_rcvry_log ──1:N──▸ db_rcvry_dtl     │
│              (DB 복구 로그 이력 → 테이블 단위 복구 상세)            │
│  db_cnctn_cnfg ──1:N──▸ bkup_sched ──1:N──▸ bkup_repl_hist│
│  (연계 DB 설정 → 백업 스케줄 → 복제·이관 이력)                     │
│  intfc_endpt ──1:N──▸ intfc_chk_hist                         │
│              ──1:N──▸ intfc_log                              │
│  (연계 엔드포인트 → 점검이력 / 송수신 로그)                        │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│              K-water 데이터표준 사전 (데이터관리포탈 연동)            │
│                                                                     │
│  std_word (6,306건)           표준단어사전                     │
│  std_domn_dict (615건)        표준도메인사전                   │
│  std_term (41,724건)          표준용어사전                     │
│  std_cd_grp ──1:N──▸ std_cd   표준코드사전 (3,572+139,288건)   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 4. 설계 특징

### 4.1 보안·거버넌스
- **데이터 보안등급**: 4단계 (public → internal → restricted → confidential)
- **RBAC 권한**: `role_menu_perm`으로 메뉴 단위 6종 권한 (CRUD + 승인 + 다운로드)
- **비식별화**: `didntf_polcy` → `didntf_rule` (마스킹/가명/삭제 등 6종)
- **감사로그**: `audit_log` (모든 사용자 작업 추적, 월별 파티셔닝 권장)

### 4.2 메타데이터 관리
- **표준용어사전**: `glsry_term` + 변경이력 추적 (`glsry_hist`)
- **K-water 데이터표준**: `std_word`(단어) + `std_domn_dict`(도메인) + `std_term`(용어) + `std_cd_grp`/`std_cd`(코드) — 데이터관리포탈 연동용
- **데이터 프로파일링**: `dset_col`의 null_rt, unique_rt, smple_vals
- **데이터 리니지**: `lnage_node` ↔ `lnage_edge` (계보 추적)
- **온톨로지**: `onto_class` 자기참조 트리 + 속성 + 관계

### 4.3 운영 관리
- **파이프라인 모니터링**: ppln → ppln_exec 이력 (성공률, 소요시간)
- **Data Product**: 데이터셋 기반 API/다운로드 패키지 + API 키 관리
- **신청/승인 워크플로우**: `data_rqst` → `rqst_tmln` (타임라인 추적)
- **ERP 동기화**: `erp_sync_hist` (SAP HR 조직/사용자 동기화)

### 4.4 공통 감사 컬럼
- **모든 73개 테이블**에 다음 4개 감사 컬럼 포함:
  - `crtd_at` (TIMESTAMPTZ) — 등록일시 (DEFAULT now())
  - `crtd_by` (UUID) — 등록자 ID (usr_acnt.usr_id 참조)
  - `updtd_at` (TIMESTAMPTZ) — 수정일시 (DEFAULT now(), 트리거 자동 갱신)
  - `updtd_by` (UUID) — 수정자 ID (usr_acnt.usr_id 참조)
- 전체 테이블/컬럼에 한글 COMMENT 정의 (`portal_comments.sql`)

### 4.6 K-water 데이터표준 사전 (데이터관리포탈 연동)
- **표준단어사전** (`std_word`): 6,306건 — 논리명/물리명/영문풀네임/속성분류어/동의어
- **표준도메인사전** (`std_domn_dict`): 615건 — 도메인그룹/데이터유형/길이/개인정보여부
- **표준용어사전** (`std_term`): 41,724건 — 논리명/물리명/도메인매핑/데이터유형
- **표준코드사전** (`std_cd_grp` + `std_cd`): 3,572그룹 + 139,288코드값
- 기존 `glsry_term`(포탈 자체 용어관리)과 `std_term`(K-water 표준)은 별도 운영하되 참조 연계 가능

### 4.5 성능 고려
- UUID PK: `usr_acnt`, `dset`, `data_product`, `api_key`, `ai_chat_sesn`
- GIN 인덱스: `dset.dset_nm` 전문검색
- 통계 테이블: `daly_dist_stats`, `dept_usg_stats` 일별 집계
- `updtd_at` 자동 갱신 트리거 (모든 해당 테이블)
- `audit_log` 월별 파티셔닝 권장 (연간 ~50GB)

---

## 5. 예상 데이터 규모 (5년 기준)

| 테이블 그룹 | 예상 건수 | 예상 용량 |
|------------|:---------:|:---------:|
| 사용자/권한 | ~50K | ~500MB |
| 메타데이터/카탈로그 | ~100K | ~5GB |
| 수집 실행 이력 | ~2M | ~15GB |
| 신청/승인 | ~200K | ~10GB |
| 감사 로그 | ~50M | ~250GB |
| 품질 검증 결과 | ~5M | ~25GB |
| 통계 집계 | ~500K | ~3GB |
| 커뮤니티/자료실 | ~50K | ~10GB |
| AI 대화 | ~1M | ~5GB |
| **합계** | **~59M** | **~325GB** |

---

## 6. 파일 위치

| 파일 | 설명 |
|------|------|
| `db/portal_schema.sql` | DDL (테이블 + 인덱스 + 트리거 + 초기데이터) |
| `db/portal_comments.sql` | 전체 73개 테이블 · 모든 컬럼 한글 COMMENT |
| `db/portal_erd_summary.md` | 이 문서 (ERD 요약) |
| `db/seed_std_word.sql` | 표준단어사전 시드 (6,306건) |
| `db/seed_std_domn_dict.sql` | 표준도메인사전 시드 (615건) |
| `db/seed_std_term.sql` | 표준용어사전 시드 (41,724건) |
| `db/seed_std_cd.sql` | 표준코드사전 시드 (3,572그룹 + 139,288코드) |
