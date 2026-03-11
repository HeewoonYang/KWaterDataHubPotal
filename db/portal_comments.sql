/*
 * ============================================================================
 *  K-water DataHub Portal — 테이블/컬럼 COMMENT 정의
 * ============================================================================
 *  portal_schema.sql의 모든 68개 테이블 · 전체 컬럼에 대한 한글 코멘트
 *  작성일: 2026-03-11
 * ============================================================================
 */

-- ============================================================================
-- 1. 사용자·조직·권한
-- ============================================================================

-- division
COMMENT ON TABLE  division IS '본부/권역 조직 (경영관리본부, 한강권역본부 등)';
COMMENT ON COLUMN division.division_id   IS '본부 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN division.division_code IS '조직코드 (예: DIV_HQ, DIV_HAN)';
COMMENT ON COLUMN division.division_name IS '조직명 (한글)';
COMMENT ON COLUMN division.sort_order    IS '정렬 순서';
COMMENT ON COLUMN division.is_active     IS '활성 여부';
COMMENT ON COLUMN division.created_at    IS '등록일시';
COMMENT ON COLUMN division.created_by    IS '등록자 ID (user_account.user_id)';
COMMENT ON COLUMN division.updated_at    IS '수정일시';
COMMENT ON COLUMN division.updated_by    IS '수정자 ID (user_account.user_id)';

-- department
COMMENT ON TABLE  department IS '부서/팀 조직';
COMMENT ON COLUMN department.dept_id     IS '부서 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN department.division_id IS '소속 본부 FK → division';
COMMENT ON COLUMN department.dept_code   IS '부서코드 (유니크)';
COMMENT ON COLUMN department.dept_name   IS '부서명 (한글)';
COMMENT ON COLUMN department.headcount   IS '정원 수';
COMMENT ON COLUMN department.sort_order  IS '정렬 순서';
COMMENT ON COLUMN department.is_active   IS '활성 여부';
COMMENT ON COLUMN department.created_at  IS '등록일시';
COMMENT ON COLUMN department.created_by  IS '등록자 ID';
COMMENT ON COLUMN department.updated_at  IS '수정일시';
COMMENT ON COLUMN department.updated_by  IS '수정자 ID';

-- role
COMMENT ON TABLE  role IS '역할 정의 (RBAC)';
COMMENT ON COLUMN role.role_id        IS '역할 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN role.role_code      IS '역할코드 (STAFF_USER, ADM_SUPER 등)';
COMMENT ON COLUMN role.role_name      IS '역할명 (한글)';
COMMENT ON COLUMN role.role_group     IS '역할 그룹: 수공직원/협력직원/데이터엔지니어/관리자';
COMMENT ON COLUMN role.role_level     IS '역할 수준 (0=게스트 ~ 6=슈퍼관리자)';
COMMENT ON COLUMN role.data_clearance IS '데이터 열람등급 (1=공개 ~ 4=기밀)';
COMMENT ON COLUMN role.description    IS '역할 설명';
COMMENT ON COLUMN role.is_active      IS '활성 여부';
COMMENT ON COLUMN role.created_at     IS '등록일시';
COMMENT ON COLUMN role.created_by     IS '등록자 ID';
COMMENT ON COLUMN role.updated_at     IS '수정일시';
COMMENT ON COLUMN role.updated_by     IS '수정자 ID';

-- user_account
COMMENT ON TABLE  user_account IS '사용자 계정';
COMMENT ON COLUMN user_account.user_id       IS '사용자 고유 ID (PK, UUID)';
COMMENT ON COLUMN user_account.login_id      IS '로그인 ID (유니크)';
COMMENT ON COLUMN user_account.user_name     IS '사용자명 (한글)';
COMMENT ON COLUMN user_account.email         IS '이메일 주소';
COMMENT ON COLUMN user_account.phone         IS '전화번호';
COMMENT ON COLUMN user_account.dept_id       IS '소속 부서 FK → department';
COMMENT ON COLUMN user_account.role_id       IS '역할 FK → role';
COMMENT ON COLUMN user_account.login_type    IS '로그인 유형: sso/partner/engineer/admin';
COMMENT ON COLUMN user_account.status        IS '계정 상태: active/inactive/pending/locked/deprecated';
COMMENT ON COLUMN user_account.last_login_at IS '최종 로그인 일시';
COMMENT ON COLUMN user_account.password_hash IS '비밀번호 해시 (SSO 사용자는 NULL)';
COMMENT ON COLUMN user_account.profile_image IS '프로필 이미지 URL';
COMMENT ON COLUMN user_account.created_at    IS '등록일시';
COMMENT ON COLUMN user_account.created_by    IS '등록자 ID';
COMMENT ON COLUMN user_account.updated_at    IS '수정일시';
COMMENT ON COLUMN user_account.updated_by    IS '수정자 ID';

-- menu
COMMENT ON TABLE  menu IS '메뉴/화면 정의 (사이드바 IA)';
COMMENT ON COLUMN menu.menu_id     IS '메뉴 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN menu.menu_code   IS '메뉴코드 (유니크)';
COMMENT ON COLUMN menu.menu_name   IS '메뉴명 (한글)';
COMMENT ON COLUMN menu.parent_code IS '상위 메뉴코드 FK → menu (자기참조)';
COMMENT ON COLUMN menu.section     IS '상위 섹션: dashboard/catalog/collect/distribute/meta/community/system';
COMMENT ON COLUMN menu.screen_id   IS 'HTML screen div ID (navigate 함수 대상)';
COMMENT ON COLUMN menu.icon        IS '아이콘 클래스명';
COMMENT ON COLUMN menu.sort_order  IS '정렬 순서';
COMMENT ON COLUMN menu.is_active   IS '활성 여부';
COMMENT ON COLUMN menu.created_at  IS '등록일시';
COMMENT ON COLUMN menu.created_by  IS '등록자 ID';
COMMENT ON COLUMN menu.updated_at  IS '수정일시';
COMMENT ON COLUMN menu.updated_by  IS '수정자 ID';

-- role_menu_perm
COMMENT ON TABLE  role_menu_perm IS '역할별 메뉴 권한 매트릭스 (RBAC)';
COMMENT ON COLUMN role_menu_perm.role_id      IS '역할 FK → role';
COMMENT ON COLUMN role_menu_perm.menu_id      IS '메뉴 FK → menu';
COMMENT ON COLUMN role_menu_perm.can_read     IS '조회 권한';
COMMENT ON COLUMN role_menu_perm.can_create   IS '등록 권한';
COMMENT ON COLUMN role_menu_perm.can_update   IS '수정 권한';
COMMENT ON COLUMN role_menu_perm.can_delete   IS '삭제 권한';
COMMENT ON COLUMN role_menu_perm.can_approve  IS '승인 권한';
COMMENT ON COLUMN role_menu_perm.can_download IS '다운로드 권한';
COMMENT ON COLUMN role_menu_perm.created_at   IS '등록일시';
COMMENT ON COLUMN role_menu_perm.created_by   IS '등록자 ID';
COMMENT ON COLUMN role_menu_perm.updated_at   IS '수정일시';
COMMENT ON COLUMN role_menu_perm.updated_by   IS '수정자 ID';

-- login_history
COMMENT ON TABLE  login_history IS '사용자 로그인/로그아웃 이력';
COMMENT ON COLUMN login_history.history_id  IS '이력 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN login_history.user_id     IS '사용자 FK → user_account';
COMMENT ON COLUMN login_history.login_type  IS '로그인 유형: sso/partner/engineer/admin';
COMMENT ON COLUMN login_history.login_ip    IS '접속 IP 주소';
COMMENT ON COLUMN login_history.user_agent  IS '브라우저 User-Agent';
COMMENT ON COLUMN login_history.login_at    IS '로그인 일시';
COMMENT ON COLUMN login_history.logout_at   IS '로그아웃 일시';
COMMENT ON COLUMN login_history.is_success  IS '로그인 성공 여부';
COMMENT ON COLUMN login_history.fail_reason IS '로그인 실패 사유';
COMMENT ON COLUMN login_history.created_at  IS '등록일시';
COMMENT ON COLUMN login_history.created_by  IS '등록자 ID';
COMMENT ON COLUMN login_history.updated_at  IS '수정일시';
COMMENT ON COLUMN login_history.updated_by  IS '수정자 ID';


-- ============================================================================
-- 2. 카탈로그·메타데이터
-- ============================================================================

-- domain
COMMENT ON TABLE  domain IS '비즈니스 도메인 (수자원/수질/에너지/인프라/고객 등)';
COMMENT ON COLUMN domain.domain_id   IS '도메인 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN domain.domain_code IS '도메인코드 (WATER, QUALITY 등)';
COMMENT ON COLUMN domain.domain_name IS '도메인명 (한글)';
COMMENT ON COLUMN domain.description IS '도메인 설명';
COMMENT ON COLUMN domain.color       IS 'HEX 색상코드 (#3B82F6)';
COMMENT ON COLUMN domain.icon        IS '아이콘명 (droplet, flask 등)';
COMMENT ON COLUMN domain.sort_order  IS '정렬 순서';
COMMENT ON COLUMN domain.is_active   IS '활성 여부';
COMMENT ON COLUMN domain.created_at  IS '등록일시';
COMMENT ON COLUMN domain.created_by  IS '등록자 ID';
COMMENT ON COLUMN domain.updated_at  IS '수정일시';
COMMENT ON COLUMN domain.updated_by  IS '수정자 ID';

-- source_system
COMMENT ON TABLE  source_system IS '원천시스템 (RWIS, SAP, SCADA, WIS 등)';
COMMENT ON COLUMN source_system.system_id       IS '시스템 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN source_system.system_code     IS '시스템코드 (유니크)';
COMMENT ON COLUMN source_system.system_name     IS '시스템명 (한글)';
COMMENT ON COLUMN source_system.system_name_en  IS '시스템명 (영문)';
COMMENT ON COLUMN source_system.description     IS '시스템 설명';
COMMENT ON COLUMN source_system.dbms_type       IS 'DBMS 유형: PostgreSQL/Oracle/MySQL/MSSQL/SAP_HANA';
COMMENT ON COLUMN source_system.protocol        IS '접속 프로토콜: JDBC/REST/SOAP/FTP/MQTT/OPC-UA';
COMMENT ON COLUMN source_system.network_zone    IS '네트워크 구간: internal/dmz/external/cloud';
COMMENT ON COLUMN source_system.connection_info IS '접속정보 JSON (호스트/포트/DB명 등, 암호화 저장)';
COMMENT ON COLUMN source_system.owner_dept_id   IS '담당 부서 FK → department';
COMMENT ON COLUMN source_system.status          IS '시스템 상태';
COMMENT ON COLUMN source_system.created_at      IS '등록일시';
COMMENT ON COLUMN source_system.created_by      IS '등록자 ID';
COMMENT ON COLUMN source_system.updated_at      IS '수정일시';
COMMENT ON COLUMN source_system.updated_by      IS '수정자 ID';

-- dataset
COMMENT ON TABLE  dataset IS '데이터셋/카탈로그 (통합 검색 대상)';
COMMENT ON COLUMN dataset.dataset_id       IS '데이터셋 고유 ID (PK, UUID)';
COMMENT ON COLUMN dataset.dataset_code     IS '데이터셋코드 (유니크)';
COMMENT ON COLUMN dataset.table_name       IS '원천 테이블명';
COMMENT ON COLUMN dataset.dataset_name     IS '데이터셋명 (한글)';
COMMENT ON COLUMN dataset.description      IS '데이터셋 설명';
COMMENT ON COLUMN dataset.domain_id        IS '비즈니스 도메인 FK → domain';
COMMENT ON COLUMN dataset.system_id        IS '원천시스템 FK → source_system';
COMMENT ON COLUMN dataset.asset_type       IS '자산 유형: table/api/file/view/stream';
COMMENT ON COLUMN dataset.security_level   IS '보안등급: public/internal/restricted/confidential';
COMMENT ON COLUMN dataset.quality_score    IS '품질점수 (0.00 ~ 100.00)';
COMMENT ON COLUMN dataset.row_count        IS '총 행 수';
COMMENT ON COLUMN dataset.column_count     IS '총 컬럼 수';
COMMENT ON COLUMN dataset.size_bytes       IS '데이터 크기 (바이트)';
COMMENT ON COLUMN dataset.owner_dept_id    IS '소유 부서 FK → department';
COMMENT ON COLUMN dataset.steward_user_id  IS '데이터 스튜어드 FK → user_account';
COMMENT ON COLUMN dataset.status           IS '데이터셋 상태';
COMMENT ON COLUMN dataset.last_profiled_at IS '최종 프로파일링 일시';
COMMENT ON COLUMN dataset.created_at       IS '등록일시';
COMMENT ON COLUMN dataset.created_by       IS '등록자 ID';
COMMENT ON COLUMN dataset.updated_at       IS '수정일시';
COMMENT ON COLUMN dataset.updated_by       IS '수정자 ID';

-- dataset_column
COMMENT ON TABLE  dataset_column IS '데이터셋 컬럼 스키마 및 프로파일링 정보';
COMMENT ON COLUMN dataset_column.column_id      IS '컬럼 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN dataset_column.dataset_id     IS '데이터셋 FK → dataset';
COMMENT ON COLUMN dataset_column.column_name    IS '컬럼명 (영문)';
COMMENT ON COLUMN dataset_column.column_name_ko IS '컬럼명 (한글)';
COMMENT ON COLUMN dataset_column.data_type      IS '데이터 타입 (VARCHAR, INT 등)';
COMMENT ON COLUMN dataset_column.data_length    IS '데이터 길이';
COMMENT ON COLUMN dataset_column.is_pk          IS 'PK 여부';
COMMENT ON COLUMN dataset_column.is_fk          IS 'FK 여부';
COMMENT ON COLUMN dataset_column.is_nullable    IS 'NULL 허용 여부';
COMMENT ON COLUMN dataset_column.default_value  IS '기본값';
COMMENT ON COLUMN dataset_column.std_term_id    IS '표준용어 FK → glossary_term';
COMMENT ON COLUMN dataset_column.description    IS '컬럼 설명';
COMMENT ON COLUMN dataset_column.null_rate      IS 'NULL 비율 (%) - 프로파일링 결과';
COMMENT ON COLUMN dataset_column.unique_rate    IS '유일값 비율 (%) - 프로파일링 결과';
COMMENT ON COLUMN dataset_column.min_value      IS '최솟값 - 프로파일링 결과';
COMMENT ON COLUMN dataset_column.max_value      IS '최댓값 - 프로파일링 결과';
COMMENT ON COLUMN dataset_column.sample_values  IS '샘플 값 배열';
COMMENT ON COLUMN dataset_column.sort_order     IS '정렬 순서';
COMMENT ON COLUMN dataset_column.created_at     IS '등록일시';
COMMENT ON COLUMN dataset_column.created_by     IS '등록자 ID';
COMMENT ON COLUMN dataset_column.updated_at     IS '수정일시';
COMMENT ON COLUMN dataset_column.updated_by     IS '수정자 ID';

-- tag
COMMENT ON TABLE  tag IS '태그 (데이터셋 분류/검색용)';
COMMENT ON COLUMN tag.tag_id     IS '태그 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN tag.tag_name   IS '태그명';
COMMENT ON COLUMN tag.tag_type   IS '태그 유형: keyword/domain/business/security';
COMMENT ON COLUMN tag.color      IS 'HEX 색상코드';
COMMENT ON COLUMN tag.created_at IS '등록일시';
COMMENT ON COLUMN tag.created_by IS '등록자 ID';
COMMENT ON COLUMN tag.updated_at IS '수정일시';
COMMENT ON COLUMN tag.updated_by IS '수정자 ID';

-- dataset_tag
COMMENT ON TABLE  dataset_tag IS '데이터셋-태그 N:M 매핑';
COMMENT ON COLUMN dataset_tag.dataset_id  IS '데이터셋 FK → dataset';
COMMENT ON COLUMN dataset_tag.tag_id      IS '태그 FK → tag';
COMMENT ON COLUMN dataset_tag.created_at  IS '등록일시';
COMMENT ON COLUMN dataset_tag.created_by  IS '등록자 ID';
COMMENT ON COLUMN dataset_tag.updated_at  IS '수정일시';
COMMENT ON COLUMN dataset_tag.updated_by  IS '수정자 ID';

-- bookmark
COMMENT ON TABLE  bookmark IS '사용자 즐겨찾기/보관함';
COMMENT ON COLUMN bookmark.bookmark_id IS '북마크 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN bookmark.user_id     IS '사용자 FK → user_account';
COMMENT ON COLUMN bookmark.dataset_id  IS '데이터셋 FK → dataset';
COMMENT ON COLUMN bookmark.memo        IS '메모';
COMMENT ON COLUMN bookmark.created_at  IS '등록일시';
COMMENT ON COLUMN bookmark.created_by  IS '등록자 ID';
COMMENT ON COLUMN bookmark.updated_at  IS '수정일시';
COMMENT ON COLUMN bookmark.updated_by  IS '수정자 ID';

-- glossary_term
COMMENT ON TABLE  glossary_term IS '표준용어사전';
COMMENT ON COLUMN glossary_term.term_id         IS '용어 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN glossary_term.term_name       IS '표준용어명 (한글)';
COMMENT ON COLUMN glossary_term.term_name_en    IS '표준용어명 (영문)';
COMMENT ON COLUMN glossary_term.domain_id       IS '비즈니스 도메인 FK → domain';
COMMENT ON COLUMN glossary_term.data_type       IS '데이터 타입';
COMMENT ON COLUMN glossary_term.data_length     IS '데이터 길이';
COMMENT ON COLUMN glossary_term.unit            IS '단위 (m, ㎥/s, mg/L 등)';
COMMENT ON COLUMN glossary_term.valid_range_min IS '유효 범위 최솟값';
COMMENT ON COLUMN glossary_term.valid_range_max IS '유효 범위 최댓값';
COMMENT ON COLUMN glossary_term.definition      IS '용어 정의';
COMMENT ON COLUMN glossary_term.example         IS '예시값';
COMMENT ON COLUMN glossary_term.synonym         IS '유의어/동의어';
COMMENT ON COLUMN glossary_term.status          IS '승인 상태: pending/approved/rejected/revision_needed/cancelled';
COMMENT ON COLUMN glossary_term.approved_by     IS '승인자 FK → user_account';
COMMENT ON COLUMN glossary_term.approved_at     IS '승인 일시';
COMMENT ON COLUMN glossary_term.created_at      IS '등록일시';
COMMENT ON COLUMN glossary_term.created_by      IS '등록자 ID';
COMMENT ON COLUMN glossary_term.updated_at      IS '수정일시';
COMMENT ON COLUMN glossary_term.updated_by      IS '수정자 ID';

-- glossary_history
COMMENT ON TABLE  glossary_history IS '표준용어 변경이력 추적';
COMMENT ON COLUMN glossary_history.history_id  IS '이력 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN glossary_history.term_id     IS '용어 FK → glossary_term';
COMMENT ON COLUMN glossary_history.change_desc IS '변경 설명';
COMMENT ON COLUMN glossary_history.changed_by  IS '변경자 FK → user_account';
COMMENT ON COLUMN glossary_history.prev_status IS '변경 전 승인 상태';
COMMENT ON COLUMN glossary_history.new_status  IS '변경 후 승인 상태';
COMMENT ON COLUMN glossary_history.prev_value  IS '변경 전 값 (JSON)';
COMMENT ON COLUMN glossary_history.new_value   IS '변경 후 값 (JSON)';
COMMENT ON COLUMN glossary_history.created_at  IS '등록일시';
COMMENT ON COLUMN glossary_history.created_by  IS '등록자 ID';
COMMENT ON COLUMN glossary_history.updated_at  IS '수정일시';
COMMENT ON COLUMN glossary_history.updated_by  IS '수정자 ID';

-- code_group
COMMENT ON TABLE  code_group IS '공통코드 그룹 (CD_REGION, CD_STATUS 등)';
COMMENT ON COLUMN code_group.group_id    IS '코드그룹 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN code_group.group_code  IS '코드그룹코드 (유니크)';
COMMENT ON COLUMN code_group.group_name  IS '코드그룹명 (한글)';
COMMENT ON COLUMN code_group.description IS '코드그룹 설명';
COMMENT ON COLUMN code_group.is_active   IS '활성 여부';
COMMENT ON COLUMN code_group.created_at  IS '등록일시';
COMMENT ON COLUMN code_group.created_by  IS '등록자 ID';
COMMENT ON COLUMN code_group.updated_at  IS '수정일시';
COMMENT ON COLUMN code_group.updated_by  IS '수정자 ID';

-- code
COMMENT ON TABLE  code IS '공통코드 값';
COMMENT ON COLUMN code.code_id     IS '코드 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN code.group_id    IS '코드그룹 FK → code_group';
COMMENT ON COLUMN code.code_value  IS '코드값';
COMMENT ON COLUMN code.code_name   IS '코드명 (한글)';
COMMENT ON COLUMN code.description IS '코드 설명';
COMMENT ON COLUMN code.sort_order  IS '정렬 순서';
COMMENT ON COLUMN code.is_active   IS '활성 여부';
COMMENT ON COLUMN code.created_at  IS '등록일시';
COMMENT ON COLUMN code.created_by  IS '등록자 ID';
COMMENT ON COLUMN code.updated_at  IS '수정일시';
COMMENT ON COLUMN code.updated_by  IS '수정자 ID';

-- data_model
COMMENT ON TABLE  data_model IS '논리/물리 데이터모델';
COMMENT ON COLUMN data_model.model_id          IS '모델 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN data_model.model_name        IS '모델명';
COMMENT ON COLUMN data_model.model_type        IS '모델 유형: logical/physical';
COMMENT ON COLUMN data_model.domain_id         IS '비즈니스 도메인 FK → domain';
COMMENT ON COLUMN data_model.version           IS '버전';
COMMENT ON COLUMN data_model.description       IS '모델 설명';
COMMENT ON COLUMN data_model.table_count       IS '테이블 수';
COMMENT ON COLUMN data_model.naming_compliance IS '명명규칙 준수율 (%)';
COMMENT ON COLUMN data_model.type_consistency  IS '타입 일관성 (%)';
COMMENT ON COLUMN data_model.ref_integrity     IS '참조무결성 (%)';
COMMENT ON COLUMN data_model.status            IS '모델 상태';
COMMENT ON COLUMN data_model.owner_user_id     IS '소유자 FK → user_account';
COMMENT ON COLUMN data_model.created_at        IS '등록일시';
COMMENT ON COLUMN data_model.created_by        IS '등록자 ID';
COMMENT ON COLUMN data_model.updated_at        IS '수정일시';
COMMENT ON COLUMN data_model.updated_by        IS '수정자 ID';

-- model_entity
COMMENT ON TABLE  model_entity IS '데이터모델 엔티티 (테이블/뷰)';
COMMENT ON COLUMN model_entity.entity_id      IS '엔티티 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN model_entity.model_id       IS '데이터모델 FK → data_model';
COMMENT ON COLUMN model_entity.entity_name    IS '엔티티명 (영문)';
COMMENT ON COLUMN model_entity.entity_name_ko IS '엔티티명 (한글)';
COMMENT ON COLUMN model_entity.entity_type    IS '엔티티 유형: table/view/mview';
COMMENT ON COLUMN model_entity.description    IS '엔티티 설명';
COMMENT ON COLUMN model_entity.sort_order     IS '정렬 순서';
COMMENT ON COLUMN model_entity.created_at     IS '등록일시';
COMMENT ON COLUMN model_entity.created_by     IS '등록자 ID';
COMMENT ON COLUMN model_entity.updated_at     IS '수정일시';
COMMENT ON COLUMN model_entity.updated_by     IS '수정자 ID';

-- model_attribute
COMMENT ON TABLE  model_attribute IS '데이터모델 속성 (컬럼)';
COMMENT ON COLUMN model_attribute.attribute_id IS '속성 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN model_attribute.entity_id    IS '엔티티 FK → model_entity';
COMMENT ON COLUMN model_attribute.attr_name    IS '속성명 (영문)';
COMMENT ON COLUMN model_attribute.attr_name_ko IS '속성명 (한글)';
COMMENT ON COLUMN model_attribute.data_type    IS '데이터 타입';
COMMENT ON COLUMN model_attribute.data_length  IS '데이터 길이';
COMMENT ON COLUMN model_attribute.is_pk        IS 'PK 여부';
COMMENT ON COLUMN model_attribute.is_fk        IS 'FK 여부';
COMMENT ON COLUMN model_attribute.is_nullable  IS 'NULL 허용 여부';
COMMENT ON COLUMN model_attribute.fk_ref_entity IS 'FK 참조 엔티티명';
COMMENT ON COLUMN model_attribute.fk_ref_attr   IS 'FK 참조 속성명';
COMMENT ON COLUMN model_attribute.description  IS '속성 설명';
COMMENT ON COLUMN model_attribute.sort_order   IS '정렬 순서';
COMMENT ON COLUMN model_attribute.created_at   IS '등록일시';
COMMENT ON COLUMN model_attribute.created_by   IS '등록자 ID';
COMMENT ON COLUMN model_attribute.updated_at   IS '수정일시';
COMMENT ON COLUMN model_attribute.updated_by   IS '수정자 ID';


-- ============================================================================
-- 3. 수집 관리
-- ============================================================================

-- pipeline
COMMENT ON TABLE  pipeline IS '수집 파이프라인 (ETL/CDC/API/Streaming)';
COMMENT ON COLUMN pipeline.pipeline_id    IS '파이프라인 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN pipeline.pipeline_name  IS '파이프라인명';
COMMENT ON COLUMN pipeline.pipeline_code  IS '파이프라인코드 (유니크)';
COMMENT ON COLUMN pipeline.system_id      IS '원천시스템 FK → source_system';
COMMENT ON COLUMN pipeline.collect_method IS '수집방식: cdc/batch/api/file/streaming/migration';
COMMENT ON COLUMN pipeline.schedule       IS 'cron 표현식 (0 */6 * * * = 6시간 간격)';
COMMENT ON COLUMN pipeline.source_table   IS '원천 테이블/경로';
COMMENT ON COLUMN pipeline.target_storage IS '적재 대상 (스키마.테이블 또는 스토리지 경로)';
COMMENT ON COLUMN pipeline.throughput     IS '예상 처리량 (건/시간)';
COMMENT ON COLUMN pipeline.description    IS '파이프라인 설명';
COMMENT ON COLUMN pipeline.owner_user_id  IS '담당자 FK → user_account';
COMMENT ON COLUMN pipeline.owner_dept_id  IS '담당 부서 FK → department';
COMMENT ON COLUMN pipeline.status         IS '파이프라인 상태';
COMMENT ON COLUMN pipeline.created_at     IS '등록일시';
COMMENT ON COLUMN pipeline.created_by     IS '등록자 ID';
COMMENT ON COLUMN pipeline.updated_at     IS '수정일시';
COMMENT ON COLUMN pipeline.updated_by     IS '수정자 ID';

-- pipeline_execution
COMMENT ON TABLE  pipeline_execution IS '파이프라인 실행 이력';
COMMENT ON COLUMN pipeline_execution.execution_id    IS '실행 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN pipeline_execution.pipeline_id     IS '파이프라인 FK → pipeline';
COMMENT ON COLUMN pipeline_execution.started_at      IS '실행 시작 일시';
COMMENT ON COLUMN pipeline_execution.finished_at     IS '실행 종료 일시';
COMMENT ON COLUMN pipeline_execution.duration_sec    IS '소요 시간 (초)';
COMMENT ON COLUMN pipeline_execution.records_read    IS '읽은 레코드 수';
COMMENT ON COLUMN pipeline_execution.records_written IS '적재한 레코드 수';
COMMENT ON COLUMN pipeline_execution.records_error   IS '오류 레코드 수';
COMMENT ON COLUMN pipeline_execution.success_rate    IS '성공률 (%)';
COMMENT ON COLUMN pipeline_execution.status          IS '실행 상태: running/success/failed/cancelled';
COMMENT ON COLUMN pipeline_execution.error_message   IS '오류 메시지';
COMMENT ON COLUMN pipeline_execution.error_detail    IS '상세 오류 정보 (JSON, 스택트레이스 등)';
COMMENT ON COLUMN pipeline_execution.created_at      IS '등록일시';
COMMENT ON COLUMN pipeline_execution.created_by      IS '등록자 ID';
COMMENT ON COLUMN pipeline_execution.updated_at      IS '수정일시';
COMMENT ON COLUMN pipeline_execution.updated_by      IS '수정자 ID';

-- pipeline_column_mapping
COMMENT ON TABLE  pipeline_column_mapping IS '파이프라인 컬럼 매핑 및 변환 규칙';
COMMENT ON COLUMN pipeline_column_mapping.mapping_id     IS '매핑 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN pipeline_column_mapping.pipeline_id    IS '파이프라인 FK → pipeline';
COMMENT ON COLUMN pipeline_column_mapping.source_column  IS '원천 컬럼명';
COMMENT ON COLUMN pipeline_column_mapping.target_column  IS '적재 대상 컬럼명';
COMMENT ON COLUMN pipeline_column_mapping.source_type    IS '원천 데이터 타입';
COMMENT ON COLUMN pipeline_column_mapping.target_type    IS '적재 대상 데이터 타입';
COMMENT ON COLUMN pipeline_column_mapping.transform_rule IS '변환식 (TRIM, TO_DATE, CASE 등)';
COMMENT ON COLUMN pipeline_column_mapping.is_required    IS '필수 여부';
COMMENT ON COLUMN pipeline_column_mapping.sort_order     IS '정렬 순서';
COMMENT ON COLUMN pipeline_column_mapping.created_at     IS '등록일시';
COMMENT ON COLUMN pipeline_column_mapping.created_by     IS '등록자 ID';
COMMENT ON COLUMN pipeline_column_mapping.updated_at     IS '수정일시';
COMMENT ON COLUMN pipeline_column_mapping.updated_by     IS '수정자 ID';

-- cdc_connector
COMMENT ON TABLE  cdc_connector IS 'CDC 커넥터 (실시간 변경 데이터 캡처)';
COMMENT ON COLUMN cdc_connector.connector_id   IS '커넥터 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN cdc_connector.system_id      IS '원천시스템 FK → source_system';
COMMENT ON COLUMN cdc_connector.connector_name IS '커넥터명';
COMMENT ON COLUMN cdc_connector.connector_type IS '커넥터 유형: debezium/oracle_goldengate/sap_slt';
COMMENT ON COLUMN cdc_connector.dbms_type      IS 'DBMS 유형';
COMMENT ON COLUMN cdc_connector.table_count    IS '수집 대상 테이블 수';
COMMENT ON COLUMN cdc_connector.events_per_min IS '분당 이벤트 처리량';
COMMENT ON COLUMN cdc_connector.lag_seconds    IS '지연 시간 (초)';
COMMENT ON COLUMN cdc_connector.config         IS '커넥터 설정 (JSON)';
COMMENT ON COLUMN cdc_connector.status         IS '커넥터 상태';
COMMENT ON COLUMN cdc_connector.created_at     IS '등록일시';
COMMENT ON COLUMN cdc_connector.created_by     IS '등록자 ID';
COMMENT ON COLUMN cdc_connector.updated_at     IS '수정일시';
COMMENT ON COLUMN cdc_connector.updated_by     IS '수정자 ID';

-- kafka_topic
COMMENT ON TABLE  kafka_topic IS 'Kafka 스트리밍 토픽';
COMMENT ON COLUMN kafka_topic.topic_id        IS '토픽 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN kafka_topic.topic_name      IS '토픽명 (유니크)';
COMMENT ON COLUMN kafka_topic.cluster_name    IS '클러스터명';
COMMENT ON COLUMN kafka_topic.partition_count IS '파티션 수';
COMMENT ON COLUMN kafka_topic.replication     IS '복제 계수';
COMMENT ON COLUMN kafka_topic.retention_hours IS '보관 기간 (시간, 기본 7일=168)';
COMMENT ON COLUMN kafka_topic.msg_per_sec     IS '초당 메시지 처리량';
COMMENT ON COLUMN kafka_topic.consumer_groups IS '컨슈머 그룹 목록 (배열)';
COMMENT ON COLUMN kafka_topic.status          IS '토픽 상태';
COMMENT ON COLUMN kafka_topic.created_at      IS '등록일시';
COMMENT ON COLUMN kafka_topic.created_by      IS '등록자 ID';
COMMENT ON COLUMN kafka_topic.updated_at      IS '수정일시';
COMMENT ON COLUMN kafka_topic.updated_by      IS '수정자 ID';

-- external_integration
COMMENT ON TABLE  external_integration IS '외부 시스템 연계 인터페이스';
COMMENT ON COLUMN external_integration.integration_id   IS '연계 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN external_integration.integration_name IS '연계명';
COMMENT ON COLUMN external_integration.integration_type IS '연계 유형: api/file/mq/socket';
COMMENT ON COLUMN external_integration.source_system    IS '원천시스템명';
COMMENT ON COLUMN external_integration.target_system    IS '대상시스템명';
COMMENT ON COLUMN external_integration.protocol         IS '통신 프로토콜';
COMMENT ON COLUMN external_integration.endpoint_url     IS '엔드포인트 URL';
COMMENT ON COLUMN external_integration.frequency        IS '연계 주기';
COMMENT ON COLUMN external_integration.last_success_at  IS '최종 성공 일시';
COMMENT ON COLUMN external_integration.last_fail_at     IS '최종 실패 일시';
COMMENT ON COLUMN external_integration.status           IS '연계 상태';
COMMENT ON COLUMN external_integration.created_at       IS '등록일시';
COMMENT ON COLUMN external_integration.created_by       IS '등록자 ID';
COMMENT ON COLUMN external_integration.updated_at       IS '수정일시';
COMMENT ON COLUMN external_integration.updated_by       IS '수정자 ID';

-- dbt_model
COMMENT ON TABLE  dbt_model IS 'dbt 데이터 변환/정제 모델';
COMMENT ON COLUMN dbt_model.dbt_model_id    IS 'dbt 모델 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN dbt_model.model_name      IS '모델명';
COMMENT ON COLUMN dbt_model.model_path      IS '모델 파일 경로';
COMMENT ON COLUMN dbt_model.materialization IS '구체화 방식: table/view/incremental/ephemeral';
COMMENT ON COLUMN dbt_model.source_tables   IS '소스 테이블 목록 (배열)';
COMMENT ON COLUMN dbt_model.target_table    IS '대상 테이블명';
COMMENT ON COLUMN dbt_model.description     IS '모델 설명';
COMMENT ON COLUMN dbt_model.tags            IS '태그 목록 (배열)';
COMMENT ON COLUMN dbt_model.last_run_at     IS '최종 실행 일시';
COMMENT ON COLUMN dbt_model.last_run_status IS '최종 실행 상태';
COMMENT ON COLUMN dbt_model.run_duration_sec IS '최종 실행 소요시간 (초)';
COMMENT ON COLUMN dbt_model.owner_user_id   IS '담당자 FK → user_account';
COMMENT ON COLUMN dbt_model.status          IS '모델 상태';
COMMENT ON COLUMN dbt_model.created_at      IS '등록일시';
COMMENT ON COLUMN dbt_model.created_by      IS '등록자 ID';
COMMENT ON COLUMN dbt_model.updated_at      IS '수정일시';
COMMENT ON COLUMN dbt_model.updated_by      IS '수정자 ID';

-- server_inventory
COMMENT ON TABLE  server_inventory IS '서버 인프라 자산 목록';
COMMENT ON COLUMN server_inventory.server_id   IS '서버 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN server_inventory.server_name IS '서버명';
COMMENT ON COLUMN server_inventory.server_type IS '서버 유형: web/was/db/cache/storage/k8s-node';
COMMENT ON COLUMN server_inventory.ip_address  IS 'IP 주소';
COMMENT ON COLUMN server_inventory.os_type     IS 'OS 유형';
COMMENT ON COLUMN server_inventory.cpu_cores   IS 'CPU 코어 수';
COMMENT ON COLUMN server_inventory.memory_gb   IS '메모리 (GB)';
COMMENT ON COLUMN server_inventory.disk_gb     IS '디스크 (GB)';
COMMENT ON COLUMN server_inventory.environment IS '환경: production/staging/development';
COMMENT ON COLUMN server_inventory.datacenter  IS '데이터센터 위치';
COMMENT ON COLUMN server_inventory.status      IS '서버 상태';
COMMENT ON COLUMN server_inventory.created_at  IS '등록일시';
COMMENT ON COLUMN server_inventory.created_by  IS '등록자 ID';
COMMENT ON COLUMN server_inventory.updated_at  IS '수정일시';
COMMENT ON COLUMN server_inventory.updated_by  IS '수정자 ID';


-- ============================================================================
-- 4. 유통·활용
-- ============================================================================

-- data_product
COMMENT ON TABLE  data_product IS 'Data Product (API/다운로드/스트리밍 데이터 패키지)';
COMMENT ON COLUMN data_product.product_id      IS 'Product 고유 ID (PK, UUID)';
COMMENT ON COLUMN data_product.product_code    IS 'Product 코드 (유니크)';
COMMENT ON COLUMN data_product.product_name    IS 'Product명';
COMMENT ON COLUMN data_product.description     IS 'Product 설명';
COMMENT ON COLUMN data_product.product_type    IS 'Product 유형: api/download/streaming/dashboard';
COMMENT ON COLUMN data_product.domain_id       IS '비즈니스 도메인 FK → domain';
COMMENT ON COLUMN data_product.security_level  IS '보안등급';
COMMENT ON COLUMN data_product.version         IS '버전';
COMMENT ON COLUMN data_product.endpoint_url    IS 'API 엔드포인트 URL';
COMMENT ON COLUMN data_product.rate_limit      IS '분당 최대 API 호출 수';
COMMENT ON COLUMN data_product.total_calls     IS '누적 총 호출 수';
COMMENT ON COLUMN data_product.avg_response_ms IS '평균 응답시간 (ms)';
COMMENT ON COLUMN data_product.sla_uptime      IS 'SLA 가용률 (%)';
COMMENT ON COLUMN data_product.owner_dept_id   IS '소유 부서 FK → department';
COMMENT ON COLUMN data_product.owner_user_id   IS '소유자 FK → user_account';
COMMENT ON COLUMN data_product.status          IS 'Product 상태';
COMMENT ON COLUMN data_product.published_at    IS '게시 일시';
COMMENT ON COLUMN data_product.created_at      IS '등록일시';
COMMENT ON COLUMN data_product.created_by      IS '등록자 ID';
COMMENT ON COLUMN data_product.updated_at      IS '수정일시';
COMMENT ON COLUMN data_product.updated_by      IS '수정자 ID';

-- product_source
COMMENT ON TABLE  product_source IS 'Data Product 소스 데이터셋 매핑';
COMMENT ON COLUMN product_source.source_id   IS '소스매핑 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN product_source.product_id  IS 'Product FK → data_product';
COMMENT ON COLUMN product_source.dataset_id  IS '데이터셋 FK → dataset';
COMMENT ON COLUMN product_source.join_type   IS '조인 유형: primary/lookup/aggregation';
COMMENT ON COLUMN product_source.join_key    IS '조인 키';
COMMENT ON COLUMN product_source.description IS '매핑 설명';
COMMENT ON COLUMN product_source.sort_order  IS '정렬 순서';
COMMENT ON COLUMN product_source.created_at  IS '등록일시';
COMMENT ON COLUMN product_source.created_by  IS '등록자 ID';
COMMENT ON COLUMN product_source.updated_at  IS '수정일시';
COMMENT ON COLUMN product_source.updated_by  IS '수정자 ID';

-- product_field
COMMENT ON TABLE  product_field IS 'Data Product 응답 필드 정의';
COMMENT ON COLUMN product_field.field_id      IS '필드 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN product_field.product_id    IS 'Product FK → data_product';
COMMENT ON COLUMN product_field.field_name    IS '필드명 (영문)';
COMMENT ON COLUMN product_field.field_name_ko IS '필드명 (한글)';
COMMENT ON COLUMN product_field.field_type    IS '필드 데이터 타입';
COMMENT ON COLUMN product_field.is_required   IS '필수 여부';
COMMENT ON COLUMN product_field.is_filterable IS '필터링 가능 여부';
COMMENT ON COLUMN product_field.description   IS '필드 설명';
COMMENT ON COLUMN product_field.sample_value  IS '샘플값';
COMMENT ON COLUMN product_field.sort_order    IS '정렬 순서';
COMMENT ON COLUMN product_field.created_at    IS '등록일시';
COMMENT ON COLUMN product_field.created_by    IS '등록자 ID';
COMMENT ON COLUMN product_field.updated_at    IS '수정일시';
COMMENT ON COLUMN product_field.updated_by    IS '수정자 ID';

-- api_key
COMMENT ON TABLE  api_key IS 'API 키 발급 및 관리';
COMMENT ON COLUMN api_key.key_id       IS 'API 키 고유 ID (PK, UUID)';
COMMENT ON COLUMN api_key.user_id      IS '발급 사용자 FK → user_account';
COMMENT ON COLUMN api_key.product_id   IS 'Data Product FK → data_product';
COMMENT ON COLUMN api_key.api_key_hash IS 'API 키의 SHA-256 해시 (원문 저장 금지)';
COMMENT ON COLUMN api_key.key_prefix   IS '키 앞 8자 (식별용)';
COMMENT ON COLUMN api_key.description  IS 'API 키 설명';
COMMENT ON COLUMN api_key.is_active    IS '활성 여부';
COMMENT ON COLUMN api_key.expires_at   IS '만료 일시';
COMMENT ON COLUMN api_key.last_used_at IS '최종 사용 일시';
COMMENT ON COLUMN api_key.total_calls  IS '누적 호출 수';
COMMENT ON COLUMN api_key.created_at   IS '등록일시';
COMMENT ON COLUMN api_key.created_by   IS '등록자 ID';
COMMENT ON COLUMN api_key.updated_at   IS '수정일시';
COMMENT ON COLUMN api_key.updated_by   IS '수정자 ID';

-- deidentify_policy
COMMENT ON TABLE  deidentify_policy IS '비식별화/가명처리 정책';
COMMENT ON COLUMN deidentify_policy.policy_id    IS '정책 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN deidentify_policy.policy_name  IS '정책명';
COMMENT ON COLUMN deidentify_policy.description  IS '정책 설명';
COMMENT ON COLUMN deidentify_policy.target_level IS '적용 대상 보안등급';
COMMENT ON COLUMN deidentify_policy.rule_count   IS '규칙 수';
COMMENT ON COLUMN deidentify_policy.is_active    IS '활성 여부';
COMMENT ON COLUMN deidentify_policy.approved_by  IS '승인자 FK → user_account';
COMMENT ON COLUMN deidentify_policy.created_at   IS '등록일시';
COMMENT ON COLUMN deidentify_policy.created_by   IS '등록자 ID';
COMMENT ON COLUMN deidentify_policy.updated_at   IS '수정일시';
COMMENT ON COLUMN deidentify_policy.updated_by   IS '수정자 ID';

-- deidentify_rule
COMMENT ON TABLE  deidentify_rule IS '비식별화 규칙 (마스킹/가명/삭제 등)';
COMMENT ON COLUMN deidentify_rule.rule_id        IS '규칙 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN deidentify_rule.policy_id      IS '정책 FK → deidentify_policy';
COMMENT ON COLUMN deidentify_rule.column_pattern IS '대상 컬럼 패턴 (정규식 또는 컬럼명)';
COMMENT ON COLUMN deidentify_rule.rule_type      IS '규칙 유형: masking/pseudonym/aggregation/suppression/rounding/encryption';
COMMENT ON COLUMN deidentify_rule.rule_config    IS '규칙 설정 JSON (예: {"pattern":"***-****","keep_first":3})';
COMMENT ON COLUMN deidentify_rule.priority       IS '우선순위';
COMMENT ON COLUMN deidentify_rule.description    IS '규칙 설명';
COMMENT ON COLUMN deidentify_rule.created_at     IS '등록일시';
COMMENT ON COLUMN deidentify_rule.created_by     IS '등록자 ID';
COMMENT ON COLUMN deidentify_rule.updated_at     IS '수정일시';
COMMENT ON COLUMN deidentify_rule.updated_by     IS '수정자 ID';

-- data_request
COMMENT ON TABLE  data_request IS '데이터 활용 신청/승인 워크플로우';
COMMENT ON COLUMN data_request.request_id      IS '신청 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN data_request.request_code    IS '신청번호 (유니크)';
COMMENT ON COLUMN data_request.user_id         IS '신청자 FK → user_account';
COMMENT ON COLUMN data_request.dataset_id      IS '대상 데이터셋 FK → dataset';
COMMENT ON COLUMN data_request.product_id      IS '대상 Product FK → data_product';
COMMENT ON COLUMN data_request.request_type    IS '신청 유형: download/api_access/share/export';
COMMENT ON COLUMN data_request.purpose         IS '활용 목적';
COMMENT ON COLUMN data_request.is_urgent       IS '긴급 여부';
COMMENT ON COLUMN data_request.approval_status IS '승인 상태';
COMMENT ON COLUMN data_request.approver_id     IS '승인자 FK → user_account';
COMMENT ON COLUMN data_request.approved_at     IS '승인 일시';
COMMENT ON COLUMN data_request.expire_at       IS '접근 권한 만료일';
COMMENT ON COLUMN data_request.created_at      IS '등록일시';
COMMENT ON COLUMN data_request.created_by      IS '등록자 ID';
COMMENT ON COLUMN data_request.updated_at      IS '수정일시';
COMMENT ON COLUMN data_request.updated_by      IS '수정자 ID';

-- request_attachment
COMMENT ON TABLE  request_attachment IS '데이터 신청 첨부파일';
COMMENT ON COLUMN request_attachment.attachment_id IS '첨부 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN request_attachment.request_id    IS '신청 FK → data_request';
COMMENT ON COLUMN request_attachment.file_name     IS '파일명';
COMMENT ON COLUMN request_attachment.file_path     IS '파일 저장 경로';
COMMENT ON COLUMN request_attachment.file_size     IS '파일 크기 (바이트)';
COMMENT ON COLUMN request_attachment.mime_type     IS 'MIME 타입';
COMMENT ON COLUMN request_attachment.created_at    IS '등록일시';
COMMENT ON COLUMN request_attachment.created_by    IS '등록자 ID';
COMMENT ON COLUMN request_attachment.updated_at    IS '수정일시';
COMMENT ON COLUMN request_attachment.updated_by    IS '수정자 ID';

-- request_timeline
COMMENT ON TABLE  request_timeline IS '신청 처리이력 추적 (워크플로우 타임라인)';
COMMENT ON COLUMN request_timeline.timeline_id   IS '타임라인 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN request_timeline.request_id    IS '신청 FK → data_request';
COMMENT ON COLUMN request_timeline.action_type   IS '작업 유형: submit/review/approve/reject/revise/cancel';
COMMENT ON COLUMN request_timeline.status        IS '처리 후 승인 상태';
COMMENT ON COLUMN request_timeline.actor_user_id IS '처리자 FK → user_account';
COMMENT ON COLUMN request_timeline.comment       IS '처리 의견';
COMMENT ON COLUMN request_timeline.action_date   IS '처리 일시';
COMMENT ON COLUMN request_timeline.created_at    IS '등록일시';
COMMENT ON COLUMN request_timeline.created_by    IS '등록자 ID';
COMMENT ON COLUMN request_timeline.updated_at    IS '수정일시';
COMMENT ON COLUMN request_timeline.updated_by    IS '수정자 ID';

-- chart_content
COMMENT ON TABLE  chart_content IS '시각화 차트 콘텐츠';
COMMENT ON COLUMN chart_content.chart_id      IS '차트 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN chart_content.chart_name    IS '차트명';
COMMENT ON COLUMN chart_content.chart_type    IS '차트 유형: bar/line/pie/scatter/heatmap/map/sankey';
COMMENT ON COLUMN chart_content.description   IS '차트 설명';
COMMENT ON COLUMN chart_content.config        IS '차트 설정 (JSON, 축/범례/색상 등)';
COMMENT ON COLUMN chart_content.data_source   IS '데이터 소스 (쿼리 또는 API URL)';
COMMENT ON COLUMN chart_content.thumbnail_url IS '썸네일 이미지 URL';
COMMENT ON COLUMN chart_content.domain_id     IS '비즈니스 도메인 FK → domain';
COMMENT ON COLUMN chart_content.owner_user_id IS '소유자 FK → user_account';
COMMENT ON COLUMN chart_content.is_public     IS '공개 여부';
COMMENT ON COLUMN chart_content.view_count    IS '조회 수';
COMMENT ON COLUMN chart_content.status        IS '차트 상태';
COMMENT ON COLUMN chart_content.created_at    IS '등록일시';
COMMENT ON COLUMN chart_content.created_by    IS '등록자 ID';
COMMENT ON COLUMN chart_content.updated_at    IS '수정일시';
COMMENT ON COLUMN chart_content.updated_by    IS '수정자 ID';

-- external_provision
COMMENT ON TABLE  external_provision IS '외부 기관 데이터 제공 현황';
COMMENT ON COLUMN external_provision.provision_id   IS '제공 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN external_provision.provision_name IS '제공명';
COMMENT ON COLUMN external_provision.target_org     IS '대상 기관명';
COMMENT ON COLUMN external_provision.dataset_id     IS '데이터셋 FK → dataset';
COMMENT ON COLUMN external_provision.product_id     IS 'Product FK → data_product';
COMMENT ON COLUMN external_provision.provision_type IS '제공 유형: api/file/db_link/portal';
COMMENT ON COLUMN external_provision.frequency      IS '제공 주기: daily/weekly/monthly/on_demand';
COMMENT ON COLUMN external_provision.record_count   IS '제공 레코드 수';
COMMENT ON COLUMN external_provision.last_provided  IS '최종 제공 일시';
COMMENT ON COLUMN external_provision.contract_start IS '계약 시작일';
COMMENT ON COLUMN external_provision.contract_end   IS '계약 종료일';
COMMENT ON COLUMN external_provision.status         IS '제공 상태';
COMMENT ON COLUMN external_provision.created_at     IS '등록일시';
COMMENT ON COLUMN external_provision.created_by     IS '등록자 ID';
COMMENT ON COLUMN external_provision.updated_at     IS '수정일시';
COMMENT ON COLUMN external_provision.updated_by     IS '수정자 ID';


-- ============================================================================
-- 5. 데이터 품질
-- ============================================================================

-- dq_rule
COMMENT ON TABLE  dq_rule IS '데이터 품질 검증 규칙';
COMMENT ON COLUMN dq_rule.rule_id     IS '규칙 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN dq_rule.rule_name   IS '규칙명';
COMMENT ON COLUMN dq_rule.rule_code   IS '규칙코드 (유니크)';
COMMENT ON COLUMN dq_rule.rule_type   IS '품질 차원: completeness/accuracy/consistency/timeliness/validity/uniqueness';
COMMENT ON COLUMN dq_rule.dataset_id  IS '대상 데이터셋 FK → dataset';
COMMENT ON COLUMN dq_rule.column_name IS '대상 컬럼명';
COMMENT ON COLUMN dq_rule.expression  IS '검증식 (SQL WHERE 조건 등)';
COMMENT ON COLUMN dq_rule.threshold   IS '품질 임계값 (%), 이하 시 경고/오류';
COMMENT ON COLUMN dq_rule.severity    IS '심각도: info/warning/critical';
COMMENT ON COLUMN dq_rule.description IS '규칙 설명';
COMMENT ON COLUMN dq_rule.is_active   IS '활성 여부';
COMMENT ON COLUMN dq_rule.created_at  IS '등록일시';
COMMENT ON COLUMN dq_rule.created_by  IS '등록자 ID';
COMMENT ON COLUMN dq_rule.updated_at  IS '수정일시';
COMMENT ON COLUMN dq_rule.updated_by  IS '수정자 ID';

-- dq_execution
COMMENT ON TABLE  dq_execution IS '데이터 품질 검증 실행 결과';
COMMENT ON COLUMN dq_execution.execution_id      IS '실행 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN dq_execution.rule_id           IS '품질규칙 FK → dq_rule';
COMMENT ON COLUMN dq_execution.dataset_id        IS '데이터셋 FK → dataset';
COMMENT ON COLUMN dq_execution.execution_date    IS '실행 일자';
COMMENT ON COLUMN dq_execution.total_rows        IS '전체 행 수';
COMMENT ON COLUMN dq_execution.passed_rows       IS '합격 행 수';
COMMENT ON COLUMN dq_execution.failed_rows       IS '불합격 행 수';
COMMENT ON COLUMN dq_execution.score             IS '합격률 (%)';
COMMENT ON COLUMN dq_execution.result            IS '결과: pass/fail/error/skip';
COMMENT ON COLUMN dq_execution.error_message     IS '오류 메시지';
COMMENT ON COLUMN dq_execution.execution_time_ms IS '실행 소요시간 (ms)';
COMMENT ON COLUMN dq_execution.created_at        IS '등록일시';
COMMENT ON COLUMN dq_execution.created_by        IS '등록자 ID';
COMMENT ON COLUMN dq_execution.updated_at        IS '수정일시';
COMMENT ON COLUMN dq_execution.updated_by        IS '수정자 ID';

-- domain_quality_score
COMMENT ON TABLE  domain_quality_score IS '도메인별 일별 품질 점수 집계';
COMMENT ON COLUMN domain_quality_score.score_id      IS '점수 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN domain_quality_score.domain_id     IS '도메인 FK → domain';
COMMENT ON COLUMN domain_quality_score.score_date    IS '집계 일자';
COMMENT ON COLUMN domain_quality_score.completeness  IS '완전성 점수 (%)';
COMMENT ON COLUMN domain_quality_score.accuracy      IS '정확성 점수 (%)';
COMMENT ON COLUMN domain_quality_score.consistency   IS '일관성 점수 (%)';
COMMENT ON COLUMN domain_quality_score.timeliness    IS '적시성 점수 (%)';
COMMENT ON COLUMN domain_quality_score.validity      IS '유효성 점수 (%)';
COMMENT ON COLUMN domain_quality_score.uniqueness    IS '유일성 점수 (%)';
COMMENT ON COLUMN domain_quality_score.overall_score IS '종합 점수 (%)';
COMMENT ON COLUMN domain_quality_score.dataset_count IS '대상 데이터셋 수';
COMMENT ON COLUMN domain_quality_score.rule_count    IS '적용 규칙 수';
COMMENT ON COLUMN domain_quality_score.created_at    IS '등록일시';
COMMENT ON COLUMN domain_quality_score.created_by    IS '등록자 ID';
COMMENT ON COLUMN domain_quality_score.updated_at    IS '수정일시';
COMMENT ON COLUMN domain_quality_score.updated_by    IS '수정자 ID';

-- quality_issue
COMMENT ON TABLE  quality_issue IS '데이터 품질 이슈 관리';
COMMENT ON COLUMN quality_issue.issue_id      IS '이슈 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN quality_issue.dataset_id    IS '데이터셋 FK → dataset';
COMMENT ON COLUMN quality_issue.rule_id       IS '품질규칙 FK → dq_rule';
COMMENT ON COLUMN quality_issue.issue_type    IS '이슈 유형: missing_data/outlier/format_error/duplicate/referential';
COMMENT ON COLUMN quality_issue.severity      IS '심각도: info/warning/critical';
COMMENT ON COLUMN quality_issue.column_name   IS '대상 컬럼명';
COMMENT ON COLUMN quality_issue.affected_rows IS '영향 행 수';
COMMENT ON COLUMN quality_issue.description   IS '이슈 설명';
COMMENT ON COLUMN quality_issue.resolution    IS '해결 방안/결과';
COMMENT ON COLUMN quality_issue.status        IS '이슈 상태: open/investigating/resolved/ignored';
COMMENT ON COLUMN quality_issue.assigned_to   IS '담당자 FK → user_account';
COMMENT ON COLUMN quality_issue.resolved_at   IS '해결 일시';
COMMENT ON COLUMN quality_issue.created_at    IS '등록일시';
COMMENT ON COLUMN quality_issue.created_by    IS '등록자 ID';
COMMENT ON COLUMN quality_issue.updated_at    IS '수정일시';
COMMENT ON COLUMN quality_issue.updated_by    IS '수정자 ID';


-- ============================================================================
-- 6. 온톨로지
-- ============================================================================

-- onto_class
COMMENT ON TABLE  onto_class IS '온톨로지 클래스 (지식그래프 노드 유형)';
COMMENT ON COLUMN onto_class.class_id        IS '클래스 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN onto_class.class_name_ko   IS '클래스명 (한글)';
COMMENT ON COLUMN onto_class.class_name_en   IS '클래스명 (영문)';
COMMENT ON COLUMN onto_class.class_uri       IS 'URI (예: kw:Dam, kw:WaterTreatmentPlant)';
COMMENT ON COLUMN onto_class.parent_class_id IS '상위 클래스 FK → onto_class (자기참조)';
COMMENT ON COLUMN onto_class.description     IS '클래스 설명';
COMMENT ON COLUMN onto_class.instance_count  IS '인스턴스 수';
COMMENT ON COLUMN onto_class.icon            IS '아이콘명';
COMMENT ON COLUMN onto_class.color           IS 'HEX 색상코드';
COMMENT ON COLUMN onto_class.sort_order      IS '정렬 순서';
COMMENT ON COLUMN onto_class.created_at      IS '등록일시';
COMMENT ON COLUMN onto_class.created_by      IS '등록자 ID';
COMMENT ON COLUMN onto_class.updated_at      IS '수정일시';
COMMENT ON COLUMN onto_class.updated_by      IS '수정자 ID';

-- onto_data_property
COMMENT ON TABLE  onto_data_property IS '온톨로지 데이터 속성 (클래스의 필드)';
COMMENT ON COLUMN onto_data_property.property_id   IS '속성 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN onto_data_property.class_id      IS '소속 클래스 FK → onto_class';
COMMENT ON COLUMN onto_data_property.property_name IS '속성명';
COMMENT ON COLUMN onto_data_property.property_uri  IS '속성 URI';
COMMENT ON COLUMN onto_data_property.data_type     IS '데이터 타입 (xsd:string, xsd:decimal 등)';
COMMENT ON COLUMN onto_data_property.cardinality   IS '카디널리티: 1/0..1/0..*/1..*';
COMMENT ON COLUMN onto_data_property.unit          IS '단위';
COMMENT ON COLUMN onto_data_property.std_term_id   IS '표준용어 FK → glossary_term';
COMMENT ON COLUMN onto_data_property.description   IS '속성 설명';
COMMENT ON COLUMN onto_data_property.sort_order    IS '정렬 순서';
COMMENT ON COLUMN onto_data_property.created_at    IS '등록일시';
COMMENT ON COLUMN onto_data_property.created_by    IS '등록자 ID';
COMMENT ON COLUMN onto_data_property.updated_at    IS '수정일시';
COMMENT ON COLUMN onto_data_property.updated_by    IS '수정자 ID';

-- onto_relationship
COMMENT ON TABLE  onto_relationship IS '온톨로지 클래스 간 관계 (지식그래프 엣지)';
COMMENT ON COLUMN onto_relationship.rel_id          IS '관계 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN onto_relationship.source_class_id IS '출발 클래스 FK → onto_class';
COMMENT ON COLUMN onto_relationship.target_class_id IS '도착 클래스 FK → onto_class';
COMMENT ON COLUMN onto_relationship.rel_name_ko     IS '관계명 (한글)';
COMMENT ON COLUMN onto_relationship.rel_name_en     IS '관계명 (영문)';
COMMENT ON COLUMN onto_relationship.rel_uri         IS '관계 URI';
COMMENT ON COLUMN onto_relationship.cardinality     IS '카디널리티';
COMMENT ON COLUMN onto_relationship.direction       IS '방향: output/input/bidirectional';
COMMENT ON COLUMN onto_relationship.description     IS '관계 설명';
COMMENT ON COLUMN onto_relationship.sort_order      IS '정렬 순서';
COMMENT ON COLUMN onto_relationship.created_at      IS '등록일시';
COMMENT ON COLUMN onto_relationship.created_by      IS '등록자 ID';
COMMENT ON COLUMN onto_relationship.updated_at      IS '수정일시';
COMMENT ON COLUMN onto_relationship.updated_by      IS '수정자 ID';


-- ============================================================================
-- 7. 모니터링
-- ============================================================================

-- region
COMMENT ON TABLE  region IS '유역/지사 (한강, 낙동강, 금강, 영산강·섬진강 등)';
COMMENT ON COLUMN region.region_id   IS '유역 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN region.region_code IS '유역코드 (유니크)';
COMMENT ON COLUMN region.region_name IS '유역명 (한글)';
COMMENT ON COLUMN region.sort_order  IS '정렬 순서';
COMMENT ON COLUMN region.created_at  IS '등록일시';
COMMENT ON COLUMN region.created_by  IS '등록자 ID';
COMMENT ON COLUMN region.updated_at  IS '수정일시';
COMMENT ON COLUMN region.updated_by  IS '수정자 ID';

-- office
COMMENT ON TABLE  office IS '사무소/관리단';
COMMENT ON COLUMN office.office_id   IS '사무소 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN office.region_id   IS '유역 FK → region';
COMMENT ON COLUMN office.office_code IS '사무소코드 (유니크)';
COMMENT ON COLUMN office.office_name IS '사무소명 (한글)';
COMMENT ON COLUMN office.address     IS '주소';
COMMENT ON COLUMN office.sort_order  IS '정렬 순서';
COMMENT ON COLUMN office.created_at  IS '등록일시';
COMMENT ON COLUMN office.created_by  IS '등록자 ID';
COMMENT ON COLUMN office.updated_at  IS '수정일시';
COMMENT ON COLUMN office.updated_by  IS '수정자 ID';

-- site
COMMENT ON TABLE  site IS '사업장/현장 (댐, 정수장, 하수처리장 등)';
COMMENT ON COLUMN site.site_id    IS '사업장 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN site.office_id  IS '사무소 FK → office';
COMMENT ON COLUMN site.site_code  IS '사업장코드 (유니크)';
COMMENT ON COLUMN site.site_name  IS '사업장명 (한글)';
COMMENT ON COLUMN site.site_type  IS '시설 유형: dam/reservoir/water_plant/sewage_plant/weir';
COMMENT ON COLUMN site.latitude   IS '위도';
COMMENT ON COLUMN site.longitude  IS '경도';
COMMENT ON COLUMN site.address    IS '주소';
COMMENT ON COLUMN site.capacity   IS '시설 용량 (댐 저수량, 정수장 처리량 등)';
COMMENT ON COLUMN site.status     IS '사업장 상태';
COMMENT ON COLUMN site.created_at IS '등록일시';
COMMENT ON COLUMN site.created_by IS '등록자 ID';
COMMENT ON COLUMN site.updated_at IS '수정일시';
COMMENT ON COLUMN site.updated_by IS '수정자 ID';

-- sensor_tag
COMMENT ON TABLE  sensor_tag IS '센서 태그 메타데이터 (실측값은 원천시스템에 저장)';
COMMENT ON COLUMN sensor_tag.tag_id       IS '센서태그 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN sensor_tag.site_id      IS '사업장 FK → site';
COMMENT ON COLUMN sensor_tag.sensor_code  IS '센서코드 (유니크)';
COMMENT ON COLUMN sensor_tag.sensor_name  IS '센서명';
COMMENT ON COLUMN sensor_tag.sensor_type  IS '센서 유형: water_level/flow/quality/temperature/pressure';
COMMENT ON COLUMN sensor_tag.unit         IS '측정 단위 (m, ㎥/s, mg/L, ℃, kPa)';
COMMENT ON COLUMN sensor_tag.min_range    IS '측정 범위 최솟값';
COMMENT ON COLUMN sensor_tag.max_range    IS '측정 범위 최댓값';
COMMENT ON COLUMN sensor_tag.install_date IS '설치일';
COMMENT ON COLUMN sensor_tag.last_reading IS '최신 측정값 캐시 (실시간 조회용)';
COMMENT ON COLUMN sensor_tag.last_read_at IS '최신 측정 시각';
COMMENT ON COLUMN sensor_tag.status       IS '센서 상태';
COMMENT ON COLUMN sensor_tag.created_at   IS '등록일시';
COMMENT ON COLUMN sensor_tag.created_by   IS '등록자 ID';
COMMENT ON COLUMN sensor_tag.updated_at   IS '수정일시';
COMMENT ON COLUMN sensor_tag.updated_by   IS '수정자 ID';

-- asset_database
COMMENT ON TABLE  asset_database IS '자산DB 현황 (시설물 자산 유형별 집계)';
COMMENT ON COLUMN asset_database.asset_db_id   IS '자산DB 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN asset_database.asset_type    IS '자산 유형: dam/reservoir/pipeline/pump/valve/instrument';
COMMENT ON COLUMN asset_database.asset_name    IS '자산명';
COMMENT ON COLUMN asset_database.total_count   IS '전체 수량';
COMMENT ON COLUMN asset_database.active_count  IS '가동 수량';
COMMENT ON COLUMN asset_database.source_system IS '원천시스템명';
COMMENT ON COLUMN asset_database.last_sync_at  IS '최종 동기화 일시';
COMMENT ON COLUMN asset_database.description   IS '자산 설명';
COMMENT ON COLUMN asset_database.created_at    IS '등록일시';
COMMENT ON COLUMN asset_database.created_by    IS '등록자 ID';
COMMENT ON COLUMN asset_database.updated_at    IS '수정일시';
COMMENT ON COLUMN asset_database.updated_by    IS '수정자 ID';


-- ============================================================================
-- 8. 커뮤니티·소통
-- ============================================================================

-- board_post
COMMENT ON TABLE  board_post IS '게시판 (공지사항/내부/외부)';
COMMENT ON COLUMN board_post.post_id       IS '게시글 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN board_post.user_id       IS '작성자 FK → user_account';
COMMENT ON COLUMN board_post.title         IS '제목';
COMMENT ON COLUMN board_post.content       IS '본문 내용';
COMMENT ON COLUMN board_post.post_type     IS '게시판 유형: notice/internal/external';
COMMENT ON COLUMN board_post.is_pinned     IS '상단 고정 여부';
COMMENT ON COLUMN board_post.view_count    IS '조회 수';
COMMENT ON COLUMN board_post.like_count    IS '좋아요 수';
COMMENT ON COLUMN board_post.comment_count IS '댓글 수';
COMMENT ON COLUMN board_post.status        IS '게시글 상태';
COMMENT ON COLUMN board_post.created_at    IS '등록일시';
COMMENT ON COLUMN board_post.created_by    IS '등록자 ID';
COMMENT ON COLUMN board_post.updated_at    IS '수정일시';
COMMENT ON COLUMN board_post.updated_by    IS '수정자 ID';

-- board_comment
COMMENT ON TABLE  board_comment IS '게시판 댓글 (대댓글 지원)';
COMMENT ON COLUMN board_comment.comment_id   IS '댓글 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN board_comment.post_id      IS '게시글 FK → board_post';
COMMENT ON COLUMN board_comment.user_id      IS '작성자 FK → user_account';
COMMENT ON COLUMN board_comment.parent_id    IS '상위 댓글 FK → board_comment (대댓글)';
COMMENT ON COLUMN board_comment.comment_text IS '댓글 내용';
COMMENT ON COLUMN board_comment.status       IS '댓글 상태';
COMMENT ON COLUMN board_comment.created_at   IS '등록일시';
COMMENT ON COLUMN board_comment.created_by   IS '등록자 ID';
COMMENT ON COLUMN board_comment.updated_at   IS '수정일시';
COMMENT ON COLUMN board_comment.updated_by   IS '수정자 ID';

-- resource_archive
COMMENT ON TABLE  resource_archive IS '자료실 (매뉴얼, 템플릿, 보고서 등)';
COMMENT ON COLUMN resource_archive.resource_id    IS '자료 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN resource_archive.user_id        IS '등록자 FK → user_account';
COMMENT ON COLUMN resource_archive.resource_name  IS '자료명';
COMMENT ON COLUMN resource_archive.description    IS '자료 설명';
COMMENT ON COLUMN resource_archive.file_name      IS '파일명';
COMMENT ON COLUMN resource_archive.file_path      IS '파일 저장 경로';
COMMENT ON COLUMN resource_archive.file_size      IS '파일 크기 (바이트)';
COMMENT ON COLUMN resource_archive.mime_type      IS 'MIME 타입';
COMMENT ON COLUMN resource_archive.category       IS '카테고리: manual/template/report/guide/regulation';
COMMENT ON COLUMN resource_archive.download_count IS '다운로드 수';
COMMENT ON COLUMN resource_archive.status         IS '자료 상태';
COMMENT ON COLUMN resource_archive.created_at     IS '등록일시';
COMMENT ON COLUMN resource_archive.created_by     IS '등록자 ID';
COMMENT ON COLUMN resource_archive.updated_at     IS '수정일시';
COMMENT ON COLUMN resource_archive.updated_by     IS '수정자 ID';


-- ============================================================================
-- 9. 시스템관리
-- ============================================================================

-- security_policy
COMMENT ON TABLE  security_policy IS '보안 정책 (접근제어, 암호화, 감사 등)';
COMMENT ON COLUMN security_policy.policy_id      IS '정책 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN security_policy.policy_name    IS '정책명';
COMMENT ON COLUMN security_policy.policy_type    IS '정책 유형: access_control/encryption/audit/password/network';
COMMENT ON COLUMN security_policy.description    IS '정책 설명';
COMMENT ON COLUMN security_policy.rule_config    IS '정책 규칙 (JSON)';
COMMENT ON COLUMN security_policy.target_level   IS '적용 대상 보안등급';
COMMENT ON COLUMN security_policy.is_active      IS '활성 여부';
COMMENT ON COLUMN security_policy.effective_from IS '시행 시작일';
COMMENT ON COLUMN security_policy.effective_to   IS '시행 종료일';
COMMENT ON COLUMN security_policy.created_at     IS '등록일시';
COMMENT ON COLUMN security_policy.created_by     IS '등록자 ID';
COMMENT ON COLUMN security_policy.updated_at     IS '수정일시';
COMMENT ON COLUMN security_policy.updated_by     IS '수정자 ID';

-- system_interface
COMMENT ON TABLE  system_interface IS '시스템 인터페이스 정의 및 모니터링';
COMMENT ON COLUMN system_interface.interface_id     IS '인터페이스 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN system_interface.interface_code   IS '인터페이스코드 (유니크)';
COMMENT ON COLUMN system_interface.interface_name   IS '인터페이스명';
COMMENT ON COLUMN system_interface.source_system_id IS '송신시스템 FK → source_system';
COMMENT ON COLUMN system_interface.target_system_id IS '수신시스템 FK → source_system';
COMMENT ON COLUMN system_interface.interface_type   IS '인터페이스 유형: api/db_link/file/mq/mcp';
COMMENT ON COLUMN system_interface.protocol         IS '통신 프로토콜';
COMMENT ON COLUMN system_interface.frequency        IS '연계 주기: realtime/hourly/daily/weekly/monthly/on_demand';
COMMENT ON COLUMN system_interface.direction        IS '방향: inbound/outbound/bidirectional';
COMMENT ON COLUMN system_interface.last_success_at  IS '최종 성공 일시';
COMMENT ON COLUMN system_interface.last_fail_at     IS '최종 실패 일시';
COMMENT ON COLUMN system_interface.success_rate     IS '성공률 (%)';
COMMENT ON COLUMN system_interface.avg_response_ms  IS '평균 응답시간 (ms)';
COMMENT ON COLUMN system_interface.status           IS '인터페이스 상태';
COMMENT ON COLUMN system_interface.created_at       IS '등록일시';
COMMENT ON COLUMN system_interface.created_by       IS '등록자 ID';
COMMENT ON COLUMN system_interface.updated_at       IS '수정일시';
COMMENT ON COLUMN system_interface.updated_by       IS '수정자 ID';

-- audit_log
COMMENT ON TABLE  audit_log IS '감사 로그 (모든 사용자 작업 추적)';
COMMENT ON COLUMN audit_log.log_id        IS '로그 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN audit_log.user_id       IS '사용자 FK → user_account';
COMMENT ON COLUMN audit_log.user_name     IS '사용자명 (비정규화)';
COMMENT ON COLUMN audit_log.action_type   IS '작업 유형: login/logout/create/read/update/delete/download/approve/export';
COMMENT ON COLUMN audit_log.target_table  IS '대상 테이블명';
COMMENT ON COLUMN audit_log.target_id     IS '대상 레코드 ID';
COMMENT ON COLUMN audit_log.action_detail IS '작업 상세 내용';
COMMENT ON COLUMN audit_log.ip_address    IS '접속 IP 주소';
COMMENT ON COLUMN audit_log.user_agent    IS '브라우저 User-Agent';
COMMENT ON COLUMN audit_log.result        IS '결과: success/fail/denied';
COMMENT ON COLUMN audit_log.created_at    IS '등록일시';
COMMENT ON COLUMN audit_log.created_by    IS '등록자 ID';
COMMENT ON COLUMN audit_log.updated_at    IS '수정일시';
COMMENT ON COLUMN audit_log.updated_by    IS '수정자 ID';

-- notification
COMMENT ON TABLE  notification IS '사용자 알림';
COMMENT ON COLUMN notification.noti_id    IS '알림 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN notification.user_id    IS '수신자 FK → user_account';
COMMENT ON COLUMN notification.noti_type  IS '알림 유형: system/approval/quality/security/pipeline';
COMMENT ON COLUMN notification.title      IS '알림 제목';
COMMENT ON COLUMN notification.message    IS '알림 내용';
COMMENT ON COLUMN notification.link_url   IS '관련 화면 링크';
COMMENT ON COLUMN notification.is_read    IS '읽음 여부';
COMMENT ON COLUMN notification.read_at    IS '읽은 일시';
COMMENT ON COLUMN notification.created_at IS '등록일시';
COMMENT ON COLUMN notification.created_by IS '등록자 ID';
COMMENT ON COLUMN notification.updated_at IS '수정일시';
COMMENT ON COLUMN notification.updated_by IS '수정자 ID';

-- widget_template
COMMENT ON TABLE  widget_template IS '대시보드 위젯 템플릿';
COMMENT ON COLUMN widget_template.widget_id     IS '위젯 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN widget_template.widget_code   IS '위젯코드 (유니크)';
COMMENT ON COLUMN widget_template.widget_name   IS '위젯명';
COMMENT ON COLUMN widget_template.widget_type   IS '위젯 유형: kpi/chart/table/map/timeline/calendar';
COMMENT ON COLUMN widget_template.description   IS '위젯 설명';
COMMENT ON COLUMN widget_template.config_json   IS '기본 설정 (JSON, 차트유형/데이터소스 등)';
COMMENT ON COLUMN widget_template.thumbnail_url IS '썸네일 이미지 URL';
COMMENT ON COLUMN widget_template.min_width     IS '최소 너비 (그리드 단위)';
COMMENT ON COLUMN widget_template.min_height    IS '최소 높이 (그리드 단위)';
COMMENT ON COLUMN widget_template.max_width     IS '최대 너비 (그리드 단위)';
COMMENT ON COLUMN widget_template.max_height    IS '최대 높이 (그리드 단위)';
COMMENT ON COLUMN widget_template.category      IS '카테고리: dashboard/quality/collect/distribute/system';
COMMENT ON COLUMN widget_template.is_active     IS '활성 여부';
COMMENT ON COLUMN widget_template.created_at    IS '등록일시';
COMMENT ON COLUMN widget_template.created_by    IS '등록자 ID';
COMMENT ON COLUMN widget_template.updated_at    IS '수정일시';
COMMENT ON COLUMN widget_template.updated_by    IS '수정자 ID';

-- user_widget_layout
COMMENT ON TABLE  user_widget_layout IS '사용자별 위젯 배치 (개인화 대시보드)';
COMMENT ON COLUMN user_widget_layout.layout_id       IS '배치 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN user_widget_layout.user_id         IS '사용자 FK → user_account';
COMMENT ON COLUMN user_widget_layout.widget_id       IS '위젯 FK → widget_template';
COMMENT ON COLUMN user_widget_layout.position_x      IS 'X 위치 (그리드)';
COMMENT ON COLUMN user_widget_layout.position_y      IS 'Y 위치 (그리드)';
COMMENT ON COLUMN user_widget_layout.width           IS '너비 (그리드 단위)';
COMMENT ON COLUMN user_widget_layout.height          IS '높이 (그리드 단위)';
COMMENT ON COLUMN user_widget_layout.config_override IS '사용자 개인 설정 오버라이드 (JSON)';
COMMENT ON COLUMN user_widget_layout.is_visible      IS '표시 여부';
COMMENT ON COLUMN user_widget_layout.sort_order      IS '정렬 순서';
COMMENT ON COLUMN user_widget_layout.created_at      IS '등록일시';
COMMENT ON COLUMN user_widget_layout.created_by      IS '등록자 ID';
COMMENT ON COLUMN user_widget_layout.updated_at      IS '수정일시';
COMMENT ON COLUMN user_widget_layout.updated_by      IS '수정자 ID';

-- lineage_node
COMMENT ON TABLE  lineage_node IS '데이터 리니지 노드 (계보 추적 대상)';
COMMENT ON COLUMN lineage_node.node_id     IS '노드 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN lineage_node.node_type   IS '노드 유형: dataset/table/column/pipeline/system/product';
COMMENT ON COLUMN lineage_node.object_id   IS '대상 객체 ID (UUID 또는 코드)';
COMMENT ON COLUMN lineage_node.object_name IS '대상 객체명';
COMMENT ON COLUMN lineage_node.description IS '노드 설명';
COMMENT ON COLUMN lineage_node.metadata    IS '추가 메타 정보 (JSON)';
COMMENT ON COLUMN lineage_node.created_at  IS '등록일시';
COMMENT ON COLUMN lineage_node.created_by  IS '등록자 ID';
COMMENT ON COLUMN lineage_node.updated_at  IS '수정일시';
COMMENT ON COLUMN lineage_node.updated_by  IS '수정자 ID';

-- lineage_edge
COMMENT ON TABLE  lineage_edge IS '데이터 리니지 엣지 (계보 흐름)';
COMMENT ON COLUMN lineage_edge.edge_id        IS '엣지 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN lineage_edge.source_node_id IS '출발 노드 FK → lineage_node';
COMMENT ON COLUMN lineage_edge.target_node_id IS '도착 노드 FK → lineage_node';
COMMENT ON COLUMN lineage_edge.edge_type      IS '엣지 유형: transform/derive/copy/aggregate/filter';
COMMENT ON COLUMN lineage_edge.transformation IS '변환 설명';
COMMENT ON COLUMN lineage_edge.pipeline_id    IS '파이프라인 FK → pipeline';
COMMENT ON COLUMN lineage_edge.created_at     IS '등록일시';
COMMENT ON COLUMN lineage_edge.created_by     IS '등록자 ID';
COMMENT ON COLUMN lineage_edge.updated_at     IS '수정일시';
COMMENT ON COLUMN lineage_edge.updated_by     IS '수정자 ID';

-- ai_chat_session
COMMENT ON TABLE  ai_chat_session IS 'AI/LLM 대화 세션';
COMMENT ON COLUMN ai_chat_session.session_id    IS '세션 고유 ID (PK, UUID)';
COMMENT ON COLUMN ai_chat_session.user_id       IS '사용자 FK → user_account';
COMMENT ON COLUMN ai_chat_session.session_title IS '세션 제목';
COMMENT ON COLUMN ai_chat_session.model_name    IS '사용 모델명';
COMMENT ON COLUMN ai_chat_session.message_count IS '메시지 수';
COMMENT ON COLUMN ai_chat_session.is_archived   IS '보관 여부';
COMMENT ON COLUMN ai_chat_session.created_at    IS '등록일시';
COMMENT ON COLUMN ai_chat_session.created_by    IS '등록자 ID';
COMMENT ON COLUMN ai_chat_session.updated_at    IS '수정일시';
COMMENT ON COLUMN ai_chat_session.updated_by    IS '수정자 ID';

-- ai_chat_message
COMMENT ON TABLE  ai_chat_message IS 'AI 대화 메시지 (질문/응답)';
COMMENT ON COLUMN ai_chat_message.message_id   IS '메시지 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN ai_chat_message.session_id   IS '세션 FK → ai_chat_session';
COMMENT ON COLUMN ai_chat_message.role         IS '발화자: user/assistant/system';
COMMENT ON COLUMN ai_chat_message.message_text IS '메시지 내용';
COMMENT ON COLUMN ai_chat_message.tokens_used  IS '사용 토큰 수';
COMMENT ON COLUMN ai_chat_message.response_ms  IS '응답 소요시간 (ms)';
COMMENT ON COLUMN ai_chat_message.metadata     IS '참조 데이터셋/검색 컨텍스트 등 (JSON)';
COMMENT ON COLUMN ai_chat_message.created_at   IS '등록일시';
COMMENT ON COLUMN ai_chat_message.created_by   IS '등록자 ID';
COMMENT ON COLUMN ai_chat_message.updated_at   IS '수정일시';
COMMENT ON COLUMN ai_chat_message.updated_by   IS '수정자 ID';

-- daily_dist_stats
COMMENT ON TABLE  daily_dist_stats IS '일별 Data Product 유통 통계';
COMMENT ON COLUMN daily_dist_stats.stat_id         IS '통계 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN daily_dist_stats.stat_date       IS '통계 일자';
COMMENT ON COLUMN daily_dist_stats.product_id      IS 'Product FK → data_product';
COMMENT ON COLUMN daily_dist_stats.total_calls     IS '총 호출 수';
COMMENT ON COLUMN daily_dist_stats.success_calls   IS '성공 호출 수';
COMMENT ON COLUMN daily_dist_stats.fail_calls      IS '실패 호출 수';
COMMENT ON COLUMN daily_dist_stats.avg_response_ms IS '평균 응답시간 (ms)';
COMMENT ON COLUMN daily_dist_stats.unique_users    IS '고유 사용자 수';
COMMENT ON COLUMN daily_dist_stats.data_volume_mb  IS '데이터 전송량 (MB)';
COMMENT ON COLUMN daily_dist_stats.created_at      IS '등록일시';
COMMENT ON COLUMN daily_dist_stats.created_by      IS '등록자 ID';
COMMENT ON COLUMN daily_dist_stats.updated_at      IS '수정일시';
COMMENT ON COLUMN daily_dist_stats.updated_by      IS '수정자 ID';

-- dept_usage_stats
COMMENT ON TABLE  dept_usage_stats IS '부서별 일별 활용 통계';
COMMENT ON COLUMN dept_usage_stats.stat_id        IS '통계 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN dept_usage_stats.stat_date      IS '통계 일자';
COMMENT ON COLUMN dept_usage_stats.dept_id        IS '부서 FK → department';
COMMENT ON COLUMN dept_usage_stats.dataset_count  IS '활용 데이터셋 수';
COMMENT ON COLUMN dept_usage_stats.api_calls      IS 'API 호출 수';
COMMENT ON COLUMN dept_usage_stats.download_count IS '다운로드 수';
COMMENT ON COLUMN dept_usage_stats.search_count   IS '검색 수';
COMMENT ON COLUMN dept_usage_stats.active_users   IS '활성 사용자 수';
COMMENT ON COLUMN dept_usage_stats.created_at     IS '등록일시';
COMMENT ON COLUMN dept_usage_stats.created_by     IS '등록자 ID';
COMMENT ON COLUMN dept_usage_stats.updated_at     IS '수정일시';
COMMENT ON COLUMN dept_usage_stats.updated_by     IS '수정자 ID';

-- erp_sync_history
COMMENT ON TABLE  erp_sync_history IS 'ERP(SAP HR) 동기화 이력 (조직/사용자 정보)';
COMMENT ON COLUMN erp_sync_history.sync_id        IS '동기화 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN erp_sync_history.sync_type      IS '동기화 유형: user/department/division';
COMMENT ON COLUMN erp_sync_history.sync_direction IS '동기화 방향: inbound(ERP→포탈)/outbound';
COMMENT ON COLUMN erp_sync_history.total_records  IS '전체 레코드 수';
COMMENT ON COLUMN erp_sync_history.created_count  IS '신규 생성 수';
COMMENT ON COLUMN erp_sync_history.updated_count  IS '수정 수';
COMMENT ON COLUMN erp_sync_history.skipped_count  IS '건너뜀 수';
COMMENT ON COLUMN erp_sync_history.error_count    IS '오류 수';
COMMENT ON COLUMN erp_sync_history.started_at     IS '시작 일시';
COMMENT ON COLUMN erp_sync_history.finished_at    IS '종료 일시';
COMMENT ON COLUMN erp_sync_history.status         IS '동기화 상태: running/success/failed/cancelled';
COMMENT ON COLUMN erp_sync_history.error_detail   IS '오류 상세 내용';
COMMENT ON COLUMN erp_sync_history.created_at     IS '등록일시';
COMMENT ON COLUMN erp_sync_history.created_by     IS '등록자 ID';
COMMENT ON COLUMN erp_sync_history.updated_at     IS '수정일시';
COMMENT ON COLUMN erp_sync_history.updated_by     IS '수정자 ID';

-- ============================================================================
-- 끝
-- ============================================================================
