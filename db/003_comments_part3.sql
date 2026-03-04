-- ============================================================================
-- DataHub Portal - 논리모델 한글 COMMENT (Part 3)
-- 6. 데이터 품질 / 7. 모니터링 / 8. 커뮤니티 / 9. 시스템관리 / 10. 통계
-- 001_schema.sql 실행 후 적용
-- ============================================================================
SET search_path TO dh, public;

-- ============================================================================
-- 6. 데이터 품질 (Data Quality)
-- ============================================================================

-- 6-1. dq_rule (DQ 규칙)
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

-- 6-2. dq_execution (DQ 실행 결과)
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

-- 6-3. domain_quality_score (도메인 품질점수)
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

-- 6-4. quality_issue (품질 이슈)
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
-- 7. 모니터링 (Monitoring)
-- ============================================================================

-- 7-1. region (유역/지사)
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

-- 7-2. office (사무소)
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

-- 7-3. site (사업장)
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

-- 7-4. sensor_tag (계측 태그)
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

-- 7-5. asset_database (자산DB)
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

-- 8-1. board_post (게시판)
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

-- 8-2. board_comment (댓글)
COMMENT ON TABLE  dh.board_comment IS '게시판 댓글';
COMMENT ON COLUMN dh.board_comment.comment_id        IS '댓글 일련번호 (PK)';
COMMENT ON COLUMN dh.board_comment.post_id           IS '게시글 ID (FK→board_post)';
COMMENT ON COLUMN dh.board_comment.parent_comment_id IS '상위 댓글 ID (대댓글, 자기참조 FK)';
COMMENT ON COLUMN dh.board_comment.content           IS '댓글 내용';
COMMENT ON COLUMN dh.board_comment.author_id         IS '작성자 ID (FK→user_account)';
COMMENT ON COLUMN dh.board_comment.created_at        IS '등록일시';

-- 8-3. resource_archive (자료실)
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
-- 9. 시스템관리 (System Administration)
-- ============================================================================

-- 9-1. security_policy (보안정책)
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

-- 9-2. system_interface (연계 인터페이스)
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

-- 9-3. audit_log (감사 로그)
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

-- 9-4. notification (알림)
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

-- 9-5. widget_template (위젯 템플릿)
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

-- 9-6. user_widget_layout (사용자 위젯 배치)
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

-- 9-7. lineage_node (리니지 노드)
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

-- 9-8. lineage_edge (리니지 엣지)
COMMENT ON TABLE  dh.lineage_edge IS '데이터 리니지 노드간 연결';
COMMENT ON COLUMN dh.lineage_edge.edge_id        IS '엣지 일련번호 (PK)';
COMMENT ON COLUMN dh.lineage_edge.source_node_id IS '출발 노드 ID (FK→lineage_node)';
COMMENT ON COLUMN dh.lineage_edge.target_node_id IS '도착 노드 ID (FK→lineage_node)';
COMMENT ON COLUMN dh.lineage_edge.edge_type      IS '연결 유형 (data_flow/trigger/reference)';
COMMENT ON COLUMN dh.lineage_edge.description    IS '연결 설명';
COMMENT ON COLUMN dh.lineage_edge.created_at     IS '등록일시';

-- 9-9. ai_chat_session (AI 대화 세션)
COMMENT ON TABLE  dh.ai_chat_session IS 'AI 검색·질의응답 대화 세션';
COMMENT ON COLUMN dh.ai_chat_session.session_id IS '세션 UUID (PK)';
COMMENT ON COLUMN dh.ai_chat_session.user_id    IS '사용자 ID (FK→user_account)';
COMMENT ON COLUMN dh.ai_chat_session.title      IS '대화 제목';
COMMENT ON COLUMN dh.ai_chat_session.created_at IS '생성일시';
COMMENT ON COLUMN dh.ai_chat_session.updated_at IS '수정일시';

-- 9-10. ai_chat_message (AI 대화 메시지)
COMMENT ON TABLE  dh.ai_chat_message IS 'AI 대화 메시지';
COMMENT ON COLUMN dh.ai_chat_message.message_id  IS '메시지 일련번호 (PK)';
COMMENT ON COLUMN dh.ai_chat_message.session_id  IS '세션 ID (FK→ai_chat_session)';
COMMENT ON COLUMN dh.ai_chat_message.role        IS '발화자 (user/assistant)';
COMMENT ON COLUMN dh.ai_chat_message.content     IS '메시지 내용';
COMMENT ON COLUMN dh.ai_chat_message.source_refs IS '참조 데이터셋/테이블 정보 (JSON)';
COMMENT ON COLUMN dh.ai_chat_message.created_at  IS '발화일시';


-- ============================================================================
-- 10. 유통 통계 (Distribution Statistics)
-- ============================================================================

-- 10-1. daily_dist_stats (일별 유통 통계)
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

-- 10-2. dept_usage_stats (부서별 활용 통계)
COMMENT ON TABLE  dh.dept_usage_stats IS '부서별 월간 활용 통계';
COMMENT ON COLUMN dh.dept_usage_stats.stat_id       IS '통계 일련번호 (PK)';
COMMENT ON COLUMN dh.dept_usage_stats.stat_month    IS '통계 기준월 (매월 1일)';
COMMENT ON COLUMN dh.dept_usage_stats.dept_id       IS '부서 ID (FK→department)';
COMMENT ON COLUMN dh.dept_usage_stats.api_calls     IS 'API 호출 건수';
COMMENT ON COLUMN dh.dept_usage_stats.downloads     IS '다운로드 건수';
COMMENT ON COLUMN dh.dept_usage_stats.data_requests IS '데이터 신청 건수';
COMMENT ON COLUMN dh.dept_usage_stats.created_at    IS '등록일시';
