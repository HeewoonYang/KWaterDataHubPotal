/*
 * ============================================================================
 *  메타데이터 표준사전 DB — 테이블/컬럼 COMMENT 일괄 추가
 * ============================================================================
 *  DBeaver에서 이 파일을 열고 전체 실행 (Ctrl+Shift+Enter)하면 됩니다.
 *  이미 COMMENT가 있는 경우 덮어씁니다 (안전).
 * ============================================================================
 */







-- ============================================================================
-- 1. std_word (표준 단어사전)
-- ============================================================================
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

-- ============================================================================
-- 2. std_domain_group (표준 도메인그룹)
-- ============================================================================
COMMENT ON TABLE  meta.std_domain_group IS '표준 도메인그룹 — 11개 데이터 도메인 분류';
COMMENT ON COLUMN meta.std_domain_group.group_id IS '도메인그룹 고유 ID';
COMMENT ON COLUMN meta.std_domain_group.group_name IS '도메인그룹명 (수량/번호/금액/텍스트/비율/기타/날짜/주소/명/분류/차례)';
COMMENT ON COLUMN meta.std_domain_group.description IS '도메인그룹 설명';
COMMENT ON COLUMN meta.std_domain_group.sort_order IS '정렬 순서';
COMMENT ON COLUMN meta.std_domain_group.is_active IS '활성 여부';
COMMENT ON COLUMN meta.std_domain_group.created_at IS '생성일시';
COMMENT ON COLUMN meta.std_domain_group.updated_at IS '수정일시';

-- ============================================================================
-- 3. std_domain (표준 도메인사전)
-- ============================================================================
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

-- ============================================================================
-- 4. std_term (표준 용어사전)
-- ============================================================================
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

-- ============================================================================
-- 5. std_code_group (표준 코드그룹)
-- ============================================================================
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

-- ============================================================================
-- 6. std_code (표준 코드사전)
-- ============================================================================
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

-- ============================================================================
-- 7. std_change_history (표준사전 변경이력)
-- ============================================================================
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

-- ============================================================================
-- 8. 뷰 COMMENT
-- ============================================================================
COMMENT ON VIEW meta.v_dict_summary IS '전체 사전 건수 통계 뷰';
COMMENT ON VIEW meta.v_domain_group_stats IS '도메인그룹별 도메인/용어 건수 분포';
COMMENT ON VIEW meta.v_code_group_stats IS '시스템 접두어별 코드그룹/코드 건수 분포';

