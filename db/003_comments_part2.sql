-- ============================================================================
-- DataHub Portal - 논리모델 한글 COMMENT (Part 2)
-- 4. 수집·정제 / 5. 유통·활용
-- 001_schema.sql 실행 후 적용
-- ============================================================================
SET search_path TO dh, public;

-- ============================================================================
-- 4. 수집·정제 (Collection & Transformation)
-- ============================================================================

-- 4-1. pipeline (파이프라인)
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

-- 4-2. pipeline_execution (파이프라인 실행이력)
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

-- 4-3. pipeline_column_mapping (컬럼 매핑)
COMMENT ON TABLE  dh.pipeline_column_mapping IS '파이프라인 소스-타겟 컬럼 매핑';
COMMENT ON COLUMN dh.pipeline_column_mapping.mapping_id     IS '매핑 일련번호 (PK)';
COMMENT ON COLUMN dh.pipeline_column_mapping.pipeline_id    IS '파이프라인 ID (FK→pipeline)';
COMMENT ON COLUMN dh.pipeline_column_mapping.source_column  IS '소스 컬럼명';
COMMENT ON COLUMN dh.pipeline_column_mapping.target_column  IS '타겟 컬럼명';
COMMENT ON COLUMN dh.pipeline_column_mapping.transform_rule IS '변환 규칙 (예: trim+uppercase, ISO8601→TIMESTAMP)';
COMMENT ON COLUMN dh.pipeline_column_mapping.is_required    IS '필수 매핑 여부';
COMMENT ON COLUMN dh.pipeline_column_mapping.sort_order     IS '정렬 순서';

-- 4-4. cdc_connector (CDC 커넥터)
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

-- 4-5. kafka_topic (Kafka 토픽)
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

-- 4-6. external_integration (외부연계)
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

-- 4-7. dbt_model (dbt 변환 모델)
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

-- 4-8. server_inventory (서버 인프라)
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

-- 5-1. data_product (Data Product)
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

-- 5-2. product_source (Product 소스 데이터)
COMMENT ON TABLE  dh.product_source IS 'Data Product 소스 데이터';
COMMENT ON COLUMN dh.product_source.source_id   IS '소스 일련번호 (PK)';
COMMENT ON COLUMN dh.product_source.product_id  IS '상품 ID (FK→data_product)';
COMMENT ON COLUMN dh.product_source.source_type IS '소스 유형 (Kafka/DB/API/File)';
COMMENT ON COLUMN dh.product_source.source_ref  IS '소스 참조 (토픽명/테이블명)';
COMMENT ON COLUMN dh.product_source.schema_type IS '스키마 유형 (AVRO/PostgreSQL/JSON)';
COMMENT ON COLUMN dh.product_source.description IS '소스 설명';

-- 5-3. product_field (Product 응답 필드)
COMMENT ON TABLE  dh.product_field IS 'Data Product 응답 필드 정의';
COMMENT ON COLUMN dh.product_field.field_id    IS '필드 일련번호 (PK)';
COMMENT ON COLUMN dh.product_field.product_id  IS '상품 ID (FK→data_product)';
COMMENT ON COLUMN dh.product_field.field_name  IS '필드명';
COMMENT ON COLUMN dh.product_field.data_type   IS '데이터타입';
COMMENT ON COLUMN dh.product_field.is_required IS '필수 필드 여부';
COMMENT ON COLUMN dh.product_field.description IS '필드 설명';
COMMENT ON COLUMN dh.product_field.sort_order  IS '정렬 순서';

-- 5-4. api_key (API Key)
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

-- 5-5. deidentify_policy (비식별화 정책)
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

-- 5-6. deidentify_rule (비식별화 규칙)
COMMENT ON TABLE  dh.deidentify_rule IS '비식별화 필드별 규칙';
COMMENT ON COLUMN dh.deidentify_rule.rule_id         IS '규칙 일련번호 (PK)';
COMMENT ON COLUMN dh.deidentify_rule.policy_id       IS '정책 ID (FK→deidentify_policy)';
COMMENT ON COLUMN dh.deidentify_rule.target_field    IS '대상 필드명';
COMMENT ON COLUMN dh.deidentify_rule.field_type      IS '필드 데이터타입';
COMMENT ON COLUMN dh.deidentify_rule.masking_pattern IS '마스킹 패턴 (부분마스킹/중간마스킹/일반화 등)';
COMMENT ON COLUMN dh.deidentify_rule.example_before  IS '적용 전 예시';
COMMENT ON COLUMN dh.deidentify_rule.example_after   IS '적용 후 예시';
COMMENT ON COLUMN dh.deidentify_rule.sort_order      IS '정렬 순서';

-- 5-7. data_request (데이터 신청·승인)
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

-- 5-8. request_attachment (신청 첨부파일)
COMMENT ON TABLE  dh.request_attachment IS '데이터 신청 첨부파일';
COMMENT ON COLUMN dh.request_attachment.attachment_id  IS '첨부파일 일련번호 (PK)';
COMMENT ON COLUMN dh.request_attachment.request_id     IS '신청번호 (FK→data_request)';
COMMENT ON COLUMN dh.request_attachment.file_name      IS '파일명';
COMMENT ON COLUMN dh.request_attachment.file_type      IS '파일 유형 (PDF/DOCX/XLSX/HWP)';
COMMENT ON COLUMN dh.request_attachment.file_size_bytes IS '파일 크기 (bytes)';
COMMENT ON COLUMN dh.request_attachment.file_path      IS '파일 저장 경로';
COMMENT ON COLUMN dh.request_attachment.uploaded_at    IS '업로드 일시';

-- 5-9. request_timeline (신청 처리이력)
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

-- 5-10. chart_content (시각화 차트)
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

-- 5-11. external_provision (외부 데이터 제공)
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
