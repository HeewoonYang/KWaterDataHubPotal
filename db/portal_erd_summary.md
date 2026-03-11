# K-water DataHub Portal — DB 모델 설계 요약

> 대상: 포탈 자체 운영 데이터 (연계·수집된 원천 데이터 제외)
> DBMS: PostgreSQL 15+
> 작성일: 2026-03-11

---

## 1. 전체 구성

| 구분 | 테이블 수 | ENUM 타입 |
|------|:---------:|:---------:|
| 사용자·조직·권한 | 7 | login_type |
| 카탈로그·메타데이터 | 14 | data_asset_type, data_security_level |
| 수집 관리 | 8 | collect_method |
| 유통·활용 | 11 | deidentify_rule_type |
| 데이터 품질 | 4 | — |
| 온톨로지 | 3 | — |
| 모니터링 | 5 | — |
| 커뮤니티 | 3 | — |
| 시스템관리 | 13 | noti_type |
| **합계** | **68** | **7 ENUM** |

공통 ENUM: `entity_status`, `approval_status`

---

## 2. 도메인별 테이블 목록

### 2-1. 사용자·조직·권한 (7개)

| # | 테이블 | PK | 핵심 FK/관계 | 설명 |
|---|--------|-----|-------------|------|
| 1 | `division` | division_id | — | 본부/권역 |
| 2 | `department` | dept_id | → division | 부서/팀 |
| 3 | `role` | role_id | — | 역할 정의 (RBAC) |
| 4 | `user_account` | user_id (UUID) | → dept, role | 사용자 계정 |
| 5 | `menu` | menu_id | → menu (자기참조) | 메뉴/화면 정의 |
| 6 | `role_menu_perm` | (role_id, menu_id) | → role, menu | 역할별 메뉴 권한 |
| 7 | `login_history` | history_id | → user_account | 로그인 이력 |

### 2-2. 카탈로그·메타데이터 (14개)

| # | 테이블 | PK | 핵심 FK/관계 | 설명 |
|---|--------|-----|-------------|------|
| 8 | `domain` | domain_id | — | 비즈니스 도메인 |
| 9 | `source_system` | system_id | → department | 원천시스템 |
| 10 | `dataset` | dataset_id (UUID) | → domain, system, dept, user | 데이터셋 카탈로그 |
| 11 | `dataset_column` | column_id | → dataset, glossary_term | 컬럼 스키마+프로파일링 |
| 12 | `tag` | tag_id | — | 태그 |
| 13 | `dataset_tag` | (dataset_id, tag_id) | → dataset, tag | N:M 매핑 |
| 14 | `bookmark` | bookmark_id | → user, dataset | 즐겨찾기 |
| 15 | `glossary_term` | term_id | → domain, user | 표준용어사전 |
| 16 | `glossary_history` | history_id | → glossary_term, user | 용어 변경이력 |
| 17 | `code_group` | group_id | — | 공통코드 그룹 |
| 18 | `code` | code_id | → code_group | 공통코드 값 |
| 19 | `data_model` | model_id | → domain, user | 논리/물리 모델 |
| 20 | `model_entity` | entity_id | → data_model | 모델 엔티티 |
| 21 | `model_attribute` | attribute_id | → model_entity | 모델 속성 |

### 2-3. 수집 관리 (8개)

| # | 테이블 | PK | 핵심 FK/관계 | 설명 |
|---|--------|-----|-------------|------|
| 22 | `pipeline` | pipeline_id | → source_system, user, dept | 수집 파이프라인 |
| 23 | `pipeline_execution` | execution_id | → pipeline | 실행 이력 |
| 24 | `pipeline_column_mapping` | mapping_id | → pipeline | 컬럼 매핑·변환 |
| 25 | `cdc_connector` | connector_id | → source_system | CDC 커넥터 |
| 26 | `kafka_topic` | topic_id | — | Kafka 토픽 |
| 27 | `external_integration` | integration_id | — | 외부 연계 |
| 28 | `dbt_model` | dbt_model_id | → user | dbt 변환 모델 |
| 29 | `server_inventory` | server_id | — | 서버 인프라 자산 |

### 2-4. 유통·활용 (11개)

| # | 테이블 | PK | 핵심 FK/관계 | 설명 |
|---|--------|-----|-------------|------|
| 30 | `data_product` | product_id (UUID) | → domain, dept, user | Data Product |
| 31 | `product_source` | source_id | → product, dataset | 소스 매핑 |
| 32 | `product_field` | field_id | → product | 필드 정의 |
| 33 | `api_key` | key_id (UUID) | → user, product | API 키 |
| 34 | `deidentify_policy` | policy_id | → user | 비식별화 정책 |
| 35 | `deidentify_rule` | rule_id | → policy | 비식별화 규칙 |
| 36 | `data_request` | request_id | → user, dataset, product | 데이터 신청 |
| 37 | `request_attachment` | attachment_id | → request | 첨부파일 |
| 38 | `request_timeline` | timeline_id | → request, user | 처리 타임라인 |
| 39 | `chart_content` | chart_id | → domain, user | 차트 콘텐츠 |
| 40 | `external_provision` | provision_id | → dataset, product | 외부 제공 현황 |

### 2-5. 데이터 품질 (4개)

| # | 테이블 | PK | 핵심 FK/관계 | 설명 |
|---|--------|-----|-------------|------|
| 41 | `dq_rule` | rule_id | → dataset, user | 품질 검증 규칙 |
| 42 | `dq_execution` | execution_id | → rule, dataset | 검증 실행 결과 |
| 43 | `domain_quality_score` | score_id | → domain | 도메인별 품질 점수 |
| 44 | `quality_issue` | issue_id | → dataset, rule, user | 품질 이슈 |

### 2-6. 온톨로지 (3개)

| # | 테이블 | PK | 핵심 FK/관계 | 설명 |
|---|--------|-----|-------------|------|
| 45 | `onto_class` | class_id | → onto_class (자기참조) | 온톨로지 클래스 |
| 46 | `onto_data_property` | property_id | → class, glossary_term | 데이터 속성 |
| 47 | `onto_relationship` | rel_id | → class (source/target) | 클래스 간 관계 |

### 2-7. 모니터링 (5개)

| # | 테이블 | PK | 핵심 FK/관계 | 설명 |
|---|--------|-----|-------------|------|
| 48 | `region` | region_id | — | 유역/지사 |
| 49 | `office` | office_id | → region | 사무소 |
| 50 | `site` | site_id | → office | 사업장/현장 |
| 51 | `sensor_tag` | tag_id | → site | 센서 태그 (메타만) |
| 52 | `asset_database` | asset_db_id | — | 자산DB 현황 |

### 2-8. 커뮤니티 (3개)

| # | 테이블 | PK | 핵심 FK/관계 | 설명 |
|---|--------|-----|-------------|------|
| 53 | `board_post` | post_id | → user | 게시판 글 |
| 54 | `board_comment` | comment_id | → post, user, comment(대댓글) | 댓글 |
| 55 | `resource_archive` | resource_id | → user | 자료실 |

### 2-9. 시스템관리 (13개)

| # | 테이블 | PK | 핵심 FK/관계 | 설명 |
|---|--------|-----|-------------|------|
| 56 | `security_policy` | policy_id | → user | 보안 정책 |
| 57 | `system_interface` | interface_id | → source_system (×2) | 인터페이스 |
| 58 | `audit_log` | log_id | → user | 감사 로그 |
| 59 | `notification` | noti_id | → user | 알림 |
| 60 | `widget_template` | widget_id | — | 위젯 템플릿 |
| 61 | `user_widget_layout` | layout_id | → user, widget | 위젯 배치 |
| 62 | `lineage_node` | node_id | — | 리니지 노드 |
| 63 | `lineage_edge` | edge_id | → node (×2), pipeline | 리니지 엣지 |
| 64 | `ai_chat_session` | session_id (UUID) | → user | AI 대화 세션 |
| 65 | `ai_chat_message` | message_id | → session | AI 메시지 |
| 66 | `daily_dist_stats` | stat_id | → product | 일별 유통 통계 |
| 67 | `dept_usage_stats` | stat_id | → department | 부서별 활용 통계 |
| 68 | `erp_sync_history` | sync_id | — | ERP 동기화 이력 |

---

## 3. ERD 관계도

```
┌─────────────────────────────────────────────────────────────────────┐
│                      사용자·조직·권한                                │
│                                                                     │
│  division ──1:N──▸ department ──1:N──▸ user_account                 │
│                                            │                        │
│                    role ──────────────────┘ (N:1)                   │
│                      │                                              │
│                      └──N:M──▸ menu  (via role_menu_perm)          │
│                                                                     │
│  user_account ──1:N──▸ login_history                               │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                    카탈로그·메타데이터                                │
│                                                                     │
│  domain ──1:N──▸ dataset ◂──N:1── source_system                    │
│                    │                                                │
│                    ├──1:N──▸ dataset_column ──N:1──▸ glossary_term  │
│                    ├──N:M──▸ tag  (via dataset_tag)                │
│                    └──1:N──▸ bookmark                              │
│                                                                     │
│  domain ──1:N──▸ glossary_term ──1:N──▸ glossary_history           │
│  domain ──1:N──▸ data_model ──1:N──▸ model_entity ──1:N──▸ attr   │
│  code_group ──1:N──▸ code                                          │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                       수집 관리                                     │
│                                                                     │
│  source_system ──1:N──▸ pipeline ──1:N──▸ pipeline_execution       │
│                    │        └──1:N──▸ pipeline_column_mapping      │
│                    └──1:N──▸ cdc_connector                         │
│                                                                     │
│  kafka_topic    external_integration    dbt_model    server_inv    │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                      유통·활용                                      │
│                                                                     │
│  data_product ──1:N──▸ product_source ◂──N:1── dataset             │
│       │         └──1:N──▸ product_field                            │
│       └──1:N──▸ api_key                                            │
│                                                                     │
│  deidentify_policy ──1:N──▸ deidentify_rule                        │
│                                                                     │
│  data_request ──1:N──▸ request_attachment                          │
│       └────────1:N──▸ request_timeline                             │
│                                                                     │
│  chart_content    external_provision                                │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                       품질 관리                                     │
│                                                                     │
│  dq_rule ──1:N──▸ dq_execution                                    │
│  domain ──1:N──▸ domain_quality_score                              │
│  dataset ──1:N──▸ quality_issue                                    │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                      온톨로지                                       │
│                                                                     │
│  onto_class (자기참조: parent) ──1:N──▸ onto_data_property          │
│       └──────────────────N:M──▸ onto_relationship                  │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                      모니터링                                       │
│                                                                     │
│  region ──1:N──▸ office ──1:N──▸ site ──1:N──▸ sensor_tag          │
│  asset_database (독립)                                              │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                     시스템관리                                       │
│                                                                     │
│  audit_log (사용자 작업 추적, 월별 파티셔닝 권장)                    │
│  notification (사용자 알림)                                         │
│  widget_template ──1:N──▸ user_widget_layout                       │
│  lineage_node ◂──N:M──▸ lineage_edge                              │
│  ai_chat_session ──1:N──▸ ai_chat_message                          │
│  daily_dist_stats / dept_usage_stats (통계 집계)                    │
│  erp_sync_history (ERP 동기화 이력)                                 │
│  system_interface / security_policy                                 │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 4. 설계 특징

### 4.1 보안·거버넌스
- **데이터 보안등급**: 4단계 (public → internal → restricted → confidential)
- **RBAC 권한**: `role_menu_perm`으로 메뉴 단위 6종 권한 (CRUD + 승인 + 다운로드)
- **비식별화**: `deidentify_policy` → `deidentify_rule` (마스킹/가명/삭제 등 6종)
- **감사로그**: `audit_log` (모든 사용자 작업 추적, 월별 파티셔닝 권장)

### 4.2 메타데이터 관리
- **표준용어사전**: `glossary_term` + 변경이력 추적 (`glossary_history`)
- **데이터 프로파일링**: `dataset_column`의 null_rate, unique_rate, sample_values
- **데이터 리니지**: `lineage_node` ↔ `lineage_edge` (계보 추적)
- **온톨로지**: `onto_class` 자기참조 트리 + 속성 + 관계

### 4.3 운영 관리
- **파이프라인 모니터링**: pipeline → execution 이력 (성공률, 소요시간)
- **Data Product**: 데이터셋 기반 API/다운로드 패키지 + API 키 관리
- **신청/승인 워크플로우**: `data_request` → `request_timeline` (타임라인 추적)
- **ERP 동기화**: `erp_sync_history` (SAP HR 조직/사용자 동기화)

### 4.4 공통 감사 컬럼
- **모든 68개 테이블**에 다음 4개 감사 컬럼 포함:
  - `created_at` (TIMESTAMPTZ) — 등록일시 (DEFAULT now())
  - `created_by` (UUID) — 등록자 ID (user_account.user_id 참조)
  - `updated_at` (TIMESTAMPTZ) — 수정일시 (DEFAULT now(), 트리거 자동 갱신)
  - `updated_by` (UUID) — 수정자 ID (user_account.user_id 참조)
- 전체 테이블/컬럼에 한글 COMMENT 정의 (`portal_comments.sql`)

### 4.5 성능 고려
- UUID PK: `user_account`, `dataset`, `data_product`, `api_key`, `ai_chat_session`
- GIN 인덱스: `dataset.dataset_name` 전문검색
- 통계 테이블: `daily_dist_stats`, `dept_usage_stats` 일별 집계
- `updated_at` 자동 갱신 트리거 (모든 해당 테이블)
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
| `db/portal_comments.sql` | 전체 68개 테이블 · 모든 컬럼 한글 COMMENT |
| `db/portal_erd_summary.md` | 이 문서 (ERD 요약) |
