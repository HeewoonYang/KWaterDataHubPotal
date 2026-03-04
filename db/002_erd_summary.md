# DataHub Portal - PostgreSQL DB 모델링 요약

## 스키마: `dh` (DataHub)

---

## 테이블 목록 (총 56개)

### 1. 사용자·권한 (6 tables)
| # | 테이블 | 설명 | PK |
|---|--------|------|-----|
| 1 | `division` | 본부/권역 (경영관리본부 등) | division_id |
| 2 | `department` | 부서/팀 | dept_id |
| 3 | `role` | 역할 정의 (RBAC) | role_id |
| 4 | `user_account` | 사용자 계정 | user_id (UUID) |
| 5 | `menu` | 메뉴/화면 정의 | menu_id |
| 6 | `role_menu_perm` | 역할-메뉴 권한 매트릭스 | (role_id, menu_id) |

### 2. 카탈로그·메타데이터 (14 tables)
| # | 테이블 | 설명 | PK |
|---|--------|------|-----|
| 7 | `domain` | 비즈니스 도메인 (수자원 등) | domain_id |
| 8 | `source_system` | 원천시스템 (RWIS, SAP 등) | system_id |
| 9 | `dataset` | 데이터 자산/카탈로그 | dataset_id (UUID) |
| 10 | `dataset_column` | 데이터셋 컬럼 스키마 | column_id |
| 11 | `tag` | 태그 | tag_id |
| 12 | `dataset_tag` | 데이터셋-태그 N:M | (dataset_id, tag_id) |
| 13 | `bookmark` | 사용자 즐겨찾기 | bookmark_id |
| 14 | `glossary_term` | 표준용어사전 | term_id |
| 15 | `glossary_history` | 용어 변경이력 | history_id |
| 16 | `code_group` | 공통코드 그룹 | group_id |
| 17 | `code` | 공통코드 값 | code_id |
| 18 | `data_model` | 논리/물리 데이터모델 | model_id |
| 19 | `model_entity` | 모델 엔티티(테이블) | entity_id |
| 20 | `model_attribute` | 모델 속성(컬럼) | attribute_id |

### 3. 온톨로지 (3 tables)
| # | 테이블 | 설명 | PK |
|---|--------|------|-----|
| 21 | `onto_class` | 온톨로지 클래스 (kw:Dam 등) | class_id |
| 22 | `onto_data_property` | 데이터 속성 | property_id |
| 23 | `onto_relationship` | 클래스간 관계 | rel_id |

### 4. 수집·정제 (8 tables)
| # | 테이블 | 설명 | PK |
|---|--------|------|-----|
| 24 | `pipeline` | 수집 파이프라인 | pipeline_id |
| 25 | `pipeline_execution` | 파이프라인 실행이력 | execution_id |
| 26 | `pipeline_column_mapping` | 컬럼 매핑 | mapping_id |
| 27 | `cdc_connector` | CDC 커넥터 | connector_id |
| 28 | `kafka_topic` | Kafka 토픽 | topic_id |
| 29 | `external_integration` | 외부연계 | integration_id |
| 30 | `dbt_model` | dbt 변환 모델 | dbt_model_id |
| 31 | `server_inventory` | 서버 인프라 | server_id |

### 5. 유통·활용 (11 tables)
| # | 테이블 | 설명 | PK |
|---|--------|------|-----|
| 32 | `data_product` | Data Product | product_id (UUID) |
| 33 | `product_source` | Product 소스 데이터 | source_id |
| 34 | `product_field` | Product 응답 필드 | field_id |
| 35 | `api_key` | API Key 발급 | key_id (UUID) |
| 36 | `deidentify_policy` | 비식별화 정책 | policy_id |
| 37 | `deidentify_rule` | 비식별화 규칙 | rule_id |
| 38 | `data_request` | 데이터 신청/승인 | request_id |
| 39 | `request_attachment` | 신청 첨부파일 | attachment_id |
| 40 | `request_timeline` | 신청 처리이력 | timeline_id |
| 41 | `chart_content` | 시각화 차트 | chart_id |
| 42 | `external_provision` | 외부 데이터 제공 | provision_id |

### 6. 데이터 품질 (4 tables)
| # | 테이블 | 설명 | PK |
|---|--------|------|-----|
| 43 | `dq_rule` | DQ 검증 규칙 | rule_id |
| 44 | `dq_execution` | DQ 실행 결과 | execution_id |
| 45 | `domain_quality_score` | 도메인 품질 점수 | score_id |
| 46 | `quality_issue` | 품질 이슈 | issue_id |

### 7. 모니터링 (5 tables)
| # | 테이블 | 설명 | PK |
|---|--------|------|-----|
| 47 | `region` | 유역/지사 | region_id |
| 48 | `office` | 사무소/관리단 | office_id |
| 49 | `site` | 사업장 | site_id |
| 50 | `sensor_tag` | 계측 센서 태그 | tag_id |
| 51 | `asset_database` | 자산DB 현황 | asset_db_id |

### 8. 커뮤니티 (3 tables)
| # | 테이블 | 설명 | PK |
|---|--------|------|-----|
| 52 | `board_post` | 게시판 (공지/내부/외부) | post_id |
| 53 | `board_comment` | 게시판 댓글 | comment_id |
| 54 | `resource_archive` | 자료실 | resource_id |

### 9. 시스템관리 (12 tables)
| # | 테이블 | 설명 | PK |
|---|--------|------|-----|
| 55 | `security_policy` | 보안정책 | policy_id |
| 56 | `system_interface` | 연계 인터페이스 | interface_id |
| 57 | `audit_log` | 감사로그 | log_id |
| 58 | `notification` | 알림 | noti_id |
| 59 | `widget_template` | 위젯 템플릿 | widget_id |
| 60 | `user_widget_layout` | 사용자 위젯 배치 | layout_id |
| 61 | `lineage_node` | 리니지 노드 | node_id |
| 62 | `lineage_edge` | 리니지 엣지 | edge_id |
| 63 | `ai_chat_session` | AI 대화 세션 | session_id (UUID) |
| 64 | `ai_chat_message` | AI 대화 메시지 | message_id |
| 65 | `daily_dist_stats` | 일별 유통 통계 | stat_id |
| 66 | `dept_usage_stats` | 부서별 활용 통계 | stat_id |

---

## 핵심 엔티티 관계 (ERD)

```
                        ┌──────────┐
                        │ division │
                        └────┬─────┘
                             │ 1:N
                        ┌────┴──────┐
                        │ department│
                        └────┬──────┘
                             │ 1:N
                    ┌────────┴────────┐
                    │  user_account   │
                    └──┬──────┬───────┘
                       │      │
          ┌────────────┤      ├──────────────┐
          │            │      │              │
     ┌────┴────┐  ┌────┴────┐ │        ┌─────┴──────┐
     │  role   │  │bookmark │ │        │notification│
     └────┬────┘  └─────────┘ │        └────────────┘
          │                   │
     ┌────┴──────────┐   ┌───┴────────────┐
     │role_menu_perm │   │  data_request   │
     └────┬──────────┘   └───┬────────────┘
          │                  │ 1:N
     ┌────┴────┐        ┌───┴───────────┐
     │  menu   │        │request_timeline│
     └─────────┘        └───────────────┘

     ┌────────┐  1:N  ┌──────────┐  N:M  ┌─────┐
     │ domain ├───────┤ dataset  ├───────┤ tag │
     └───┬────┘       └──┬───┬───┘       └─────┘
         │               │   │
         │          ┌────┴┐  └───────────────┐
         │          │col  │           ┌──────┴──────┐
         │          └─────┘           │data_product │
         │                            └──────┬──────┘
    ┌────┴──────────┐                        │
    │source_system  │                   ┌────┴────┐
    └──┬──────┬─────┘                   │ api_key │
       │      │                         └─────────┘
  ┌────┴───┐ ┌┴───────────┐
  │pipeline│ │cdc_connector│
  └────┬───┘ └────────────┘
       │1:N
  ┌────┴──────────────┐
  │pipeline_execution │
  └───────────────────┘

     ┌────────┐  1:N  ┌────────┐  1:N  ┌──────┐  1:N  ┌───────────┐
     │ region ├───────┤ office ├───────┤ site ├───────┤sensor_tag │
     └────────┘       └────────┘       └──────┘       └───────────┘
```

---

## ENUM 타입 정리

| ENUM | 값 | UI 표현 |
|------|-----|---------|
| `data_security_level` | public, internal, restricted, confidential | 공개/내부일반/내부중요/기밀 |
| `entity_status` | active, inactive, pending, locked, deprecated | 활성/비활성/대기/잠김/폐기 |
| `approval_status` | pending, approved, rejected, revision_needed, cancelled | 대기/승인/반려/보완요청/취소 |
| `collect_method` | cdc, batch, api, file, streaming, migration | 실시간CDC/배치ETL/API/파일/스트리밍/마이그레이션 |
| `data_asset_type` | table, api, file, view, stream | 테이블/API/파일/뷰/스트림 |

---

## 화면 → 테이블 매핑

| 화면 (Screen) | 주요 테이블 |
|--------------|-------------|
| 로그인 | user_account, role |
| 개인대시보드 | widget_template, user_widget_layout |
| 데이터 워크플로우 | data_request, request_timeline |
| 데이터 품질현황 | dq_rule, dq_execution, domain_quality_score, quality_issue |
| AI 검색 | ai_chat_session, ai_chat_message, dataset |
| 시각화 갤러리 | chart_content |
| 계측DB 모니터링 | region, office, site, sensor_tag |
| 자산DB 모니터링 | asset_database |
| 통합데이터 검색 | dataset, dataset_column, tag, dataset_tag, bookmark |
| 지식그래프 | onto_class, onto_relationship |
| 데이터 리니지 | lineage_node, lineage_edge |
| 내 보관함 | bookmark, dataset |
| 데이터 요청 | data_request, request_attachment, request_timeline |
| 파이프라인 관리 | pipeline, pipeline_execution, pipeline_column_mapping |
| 수집현황 모니터링 | pipeline, source_system |
| CDC 연계현황 | cdc_connector, source_system |
| Kafka 스트리밍 | kafka_topic |
| 외부연계 | external_integration |
| 아키텍처 구조도 | server_inventory |
| 정제·변환 (dbt) | dbt_model |
| Data Product 관리 | data_product, product_source, product_field |
| 비식별화 관리 | deidentify_policy, deidentify_rule |
| 데이터 신청·승인 | data_request, request_timeline |
| 유통 API 관리 | data_product, api_key |
| 유통통계 | daily_dist_stats, dept_usage_stats |
| 외부시스템 제공 | external_provision |
| 차트 콘텐츠 | chart_content |
| 표준용어 | glossary_term, glossary_history |
| 분류체계·태그 | code_group, code, tag |
| 데이터모델관리 | data_model, model_entity, model_attribute |
| DQ 검증 | dq_rule, dq_execution |
| 온톨로지 관리 | onto_class, onto_data_property, onto_relationship |
| 공지사항 | board_post (type=notice) |
| 내부게시판 | board_post (type=internal), board_comment |
| 외부게시판 | board_post (type=external), board_comment |
| 자료실 | resource_archive |
| 사용자관리 | user_account, department, division |
| 권한·역할관리 | role, role_menu_perm, menu |
| 보안정책 | security_policy |
| 인터페이스 모니터링 | system_interface |
| 감사로그 | audit_log |
| 위젯 템플릿 | widget_template |
