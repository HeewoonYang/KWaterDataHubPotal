-- ============================================================================
-- DataHub Portal - 논리모델 한글 COMMENT (Part 1)
-- 1. 사용자·권한 / 2. 카탈로그·메타 / 3. 온톨로지
-- 001_schema.sql 실행 후 적용
-- ============================================================================
SET search_path TO dh, public;

-- ============================================================================
-- 1. 사용자·권한 (User & Auth)
-- ============================================================================

-- 1-1. division (본부)
COMMENT ON TABLE  dh.division IS '본부/권역 조직';
COMMENT ON COLUMN dh.division.division_id   IS '본부 일련번호 (PK)';
COMMENT ON COLUMN dh.division.division_name IS '본부명 (예: 경영관리본부, 수자원관리본부)';
COMMENT ON COLUMN dh.division.division_code IS '본부 코드 (고유)';
COMMENT ON COLUMN dh.division.sort_order    IS '정렬 순서';
COMMENT ON COLUMN dh.division.created_at    IS '등록일시';
COMMENT ON COLUMN dh.division.updated_at    IS '수정일시';

-- 1-2. department (부서)
COMMENT ON TABLE  dh.department IS '부서/팀';
COMMENT ON COLUMN dh.department.dept_id     IS '부서 일련번호 (PK)';
COMMENT ON COLUMN dh.department.division_id IS '소속 본부 ID (FK→division)';
COMMENT ON COLUMN dh.department.dept_name   IS '부서명 (예: 수자원관리팀, 데이터분석팀)';
COMMENT ON COLUMN dh.department.dept_code   IS '부서 코드 (고유)';
COMMENT ON COLUMN dh.department.headcount   IS '소속 인원수';
COMMENT ON COLUMN dh.department.sort_order  IS '정렬 순서';
COMMENT ON COLUMN dh.department.created_at  IS '등록일시';
COMMENT ON COLUMN dh.department.updated_at  IS '수정일시';

-- 1-3. role (역할)
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

-- 1-4. user_account (사용자)
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

-- 1-5. menu (메뉴)
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

-- 1-6. role_menu_perm (역할별 메뉴 권한)
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
-- 2. 카탈로그·메타데이터 (Catalog & Metadata)
-- ============================================================================

-- 2-1. domain (비즈니스 도메인)
COMMENT ON TABLE  dh.domain IS '비즈니스 도메인 (수자원/수질/에너지/인프라/고객)';
COMMENT ON COLUMN dh.domain.domain_id   IS '도메인 일련번호 (PK)';
COMMENT ON COLUMN dh.domain.domain_code IS '도메인 코드 (water/quality/energy/infra/customer)';
COMMENT ON COLUMN dh.domain.domain_name IS '도메인 한글명 (수자원, 수질, 에너지 등)';
COMMENT ON COLUMN dh.domain.description IS '도메인 설명';
COMMENT ON COLUMN dh.domain.color       IS 'UI 표시 색상 (HEX, 예: #1890ff)';
COMMENT ON COLUMN dh.domain.icon        IS '아이콘 (이모지)';
COMMENT ON COLUMN dh.domain.sort_order  IS '정렬 순서';
COMMENT ON COLUMN dh.domain.created_at  IS '등록일시';

-- 2-2. source_system (원천시스템)
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

-- 2-3. dataset (데이터셋)
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

-- 2-4. dataset_column (데이터셋 컬럼)
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

-- 2-5. tag (태그)
COMMENT ON TABLE  dh.tag IS '태그 (데이터셋 분류·검색용 키워드)';
COMMENT ON COLUMN dh.tag.tag_id     IS '태그 일련번호 (PK)';
COMMENT ON COLUMN dh.tag.tag_name   IS '태그명';
COMMENT ON COLUMN dh.tag.tag_type   IS '태그 유형 (keyword/domain/business/security)';
COMMENT ON COLUMN dh.tag.created_at IS '등록일시';

-- 2-6. dataset_tag (데이터셋-태그 관계)
COMMENT ON TABLE  dh.dataset_tag IS '데이터셋-태그 N:M 매핑';
COMMENT ON COLUMN dh.dataset_tag.dataset_id IS '데이터셋 ID (PK, FK→dataset)';
COMMENT ON COLUMN dh.dataset_tag.tag_id     IS '태그 ID (PK, FK→tag)';

-- 2-7. bookmark (즐겨찾기)
COMMENT ON TABLE  dh.bookmark IS '사용자 즐겨찾기/보관함';
COMMENT ON COLUMN dh.bookmark.bookmark_id IS '즐겨찾기 일련번호 (PK)';
COMMENT ON COLUMN dh.bookmark.user_id     IS '사용자 ID (FK→user_account)';
COMMENT ON COLUMN dh.bookmark.dataset_id  IS '데이터셋 ID (FK→dataset)';
COMMENT ON COLUMN dh.bookmark.created_at  IS '등록일시';

-- 2-8. glossary_term (표준용어)
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

-- 2-9. glossary_history (용어 변경이력)
COMMENT ON TABLE  dh.glossary_history IS '표준용어 변경이력';
COMMENT ON COLUMN dh.glossary_history.history_id  IS '이력 일련번호 (PK)';
COMMENT ON COLUMN dh.glossary_history.term_id     IS '용어 ID (FK→glossary_term)';
COMMENT ON COLUMN dh.glossary_history.change_desc IS '변경 내용 설명';
COMMENT ON COLUMN dh.glossary_history.changed_by  IS '변경자 ID (FK→user_account)';
COMMENT ON COLUMN dh.glossary_history.prev_status IS '변경 전 상태';
COMMENT ON COLUMN dh.glossary_history.new_status  IS '변경 후 상태';
COMMENT ON COLUMN dh.glossary_history.changed_at  IS '변경일시';

-- 2-10. code_group (공통코드 그룹)
COMMENT ON TABLE  dh.code_group IS '공통코드 그룹';
COMMENT ON COLUMN dh.code_group.group_id    IS '그룹 일련번호 (PK)';
COMMENT ON COLUMN dh.code_group.group_code  IS '그룹 코드 (예: CD_REGION, CD_DATA_TYPE)';
COMMENT ON COLUMN dh.code_group.group_name  IS '그룹명';
COMMENT ON COLUMN dh.code_group.description IS '그룹 설명';
COMMENT ON COLUMN dh.code_group.owner_name  IS '관리 담당자명';
COMMENT ON COLUMN dh.code_group.status      IS '상태';
COMMENT ON COLUMN dh.code_group.created_at  IS '등록일시';
COMMENT ON COLUMN dh.code_group.updated_at  IS '수정일시';

-- 2-11. code (공통코드)
COMMENT ON TABLE  dh.code IS '공통코드 값';
COMMENT ON COLUMN dh.code.code_id     IS '코드 일련번호 (PK)';
COMMENT ON COLUMN dh.code.group_id    IS '코드그룹 ID (FK→code_group)';
COMMENT ON COLUMN dh.code.code_value  IS '코드 값 (예: RGN_HQ, RGN_SEL)';
COMMENT ON COLUMN dh.code.code_name   IS '코드명 (예: 본사, 수도권)';
COMMENT ON COLUMN dh.code.description IS '코드 설명';
COMMENT ON COLUMN dh.code.sort_order  IS '정렬 순서';
COMMENT ON COLUMN dh.code.status      IS '상태';
COMMENT ON COLUMN dh.code.created_at  IS '등록일시';

-- 2-12. data_model (데이터모델)
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

-- 2-13. model_entity (모델 엔티티)
COMMENT ON TABLE  dh.model_entity IS '데이터모델 엔티티(테이블)';
COMMENT ON COLUMN dh.model_entity.entity_id      IS '엔티티 일련번호 (PK)';
COMMENT ON COLUMN dh.model_entity.model_id       IS '모델 ID (FK→data_model)';
COMMENT ON COLUMN dh.model_entity.entity_name    IS '엔티티 물리명';
COMMENT ON COLUMN dh.model_entity.entity_name_ko IS '엔티티 한글명';
COMMENT ON COLUMN dh.model_entity.description    IS '엔티티 설명';
COMMENT ON COLUMN dh.model_entity.sort_order     IS '정렬 순서';

-- 2-14. model_attribute (모델 속성)
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

-- 3-1. onto_class (온톨로지 클래스)
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

-- 3-2. onto_data_property (데이터 속성)
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

-- 3-3. onto_relationship (관계 속성)
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
