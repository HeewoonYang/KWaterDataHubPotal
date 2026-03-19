/*
 * ============================================================================
 *  K-water DataHub Portal — public 스키마 테이블/컬럼 COMMENT 일괄 추가
 * ============================================================================
 *  DBeaver에서 이 파일을 열고 전체 실행 (Ctrl+Shift+Enter)하면 됩니다.
 *  이미 COMMENT가 있는 경우 덮어씁니다 (안전).
 *  대상: portal_schema.sql의 모든 public 테이블 (68개 + 표준사전 5개)
 * ============================================================================
 */

-- ============================================================================
-- 1. 사용자·조직·권한 도메인
-- ============================================================================

-- 1-1. divs (본부)
COMMENT ON TABLE divs IS '본부 — K-water 조직 본부 정보';
COMMENT ON COLUMN divs.divs_id IS '본부 고유 ID';
COMMENT ON COLUMN divs.divs_cd IS '본부 코드';
COMMENT ON COLUMN divs.divs_nm IS '본부명';
COMMENT ON COLUMN divs.sort_ord IS '정렬 순서';
COMMENT ON COLUMN divs.is_actv IS '활성 여부';
COMMENT ON COLUMN divs.crtd_at IS '생성일시';
COMMENT ON COLUMN divs.crtd_by IS '생성자 ID';
COMMENT ON COLUMN divs.updtd_at IS '수정일시';
COMMENT ON COLUMN divs.updtd_by IS '수정자 ID';

-- 1-2. dept (부서)
COMMENT ON TABLE dept IS '부서 — K-water 조직 부서 정보';
COMMENT ON COLUMN dept.dept_id IS '부서 고유 ID';
COMMENT ON COLUMN dept.divs_id IS '소속 본부 ID (FK → divs)';
COMMENT ON COLUMN dept.dept_cd IS '부서 코드';
COMMENT ON COLUMN dept.dept_nm IS '부서명';
COMMENT ON COLUMN dept.hdcnt IS '정원 인원수';
COMMENT ON COLUMN dept.sort_ord IS '정렬 순서';
COMMENT ON COLUMN dept.is_actv IS '활성 여부';
COMMENT ON COLUMN dept.crtd_at IS '생성일시';
COMMENT ON COLUMN dept.crtd_by IS '생성자 ID';
COMMENT ON COLUMN dept.updtd_at IS '수정일시';
COMMENT ON COLUMN dept.updtd_by IS '수정자 ID';

-- 1-3. role (역할)
COMMENT ON TABLE role IS '역할 — 사용자 역할 및 권한 등급 정의';
COMMENT ON COLUMN role.role_id IS '역할 고유 ID';
COMMENT ON COLUMN role.role_cd IS '역할 코드';
COMMENT ON COLUMN role.role_nm IS '역할명';
COMMENT ON COLUMN role.role_grp IS '역할 그룹 (수공직원/협력직원/데이터엔지니어/관리자)';
COMMENT ON COLUMN role.role_lvl IS '역할 레벨 (0~6, 높을수록 고권한)';
COMMENT ON COLUMN role.data_clrnc IS '데이터 열람 등급 (1~4, 높을수록 기밀)';
COMMENT ON COLUMN role.dc IS '역할 설명';
COMMENT ON COLUMN role.is_actv IS '활성 여부';
COMMENT ON COLUMN role.crtd_at IS '생성일시';
COMMENT ON COLUMN role.crtd_by IS '생성자 ID';
COMMENT ON COLUMN role.updtd_at IS '수정일시';
COMMENT ON COLUMN role.updtd_by IS '수정자 ID';

-- 1-4. usr_acnt (사용자 계정)
COMMENT ON TABLE usr_acnt IS '사용자 계정 — 포탈 로그인 사용자 정보';
COMMENT ON COLUMN usr_acnt.usr_id IS '사용자 고유 ID (UUID)';
COMMENT ON COLUMN usr_acnt.login_id IS '로그인 ID';
COMMENT ON COLUMN usr_acnt.usr_nm IS '사용자명';
COMMENT ON COLUMN usr_acnt.email IS '이메일';
COMMENT ON COLUMN usr_acnt.phone IS '전화번호';
COMMENT ON COLUMN usr_acnt.dept_id IS '소속 부서 ID (FK → dept)';
COMMENT ON COLUMN usr_acnt.role_id IS '역할 ID (FK → role)';
COMMENT ON COLUMN usr_acnt.login_ty IS '로그인 유형 (sso/partner/engineer/admin)';
COMMENT ON COLUMN usr_acnt.stat IS '계정 상태 (active/inactive/pending/locked/deprecated)';
COMMENT ON COLUMN usr_acnt.last_login_at IS '마지막 로그인 일시';
COMMENT ON COLUMN usr_acnt.pwd_hash IS '비밀번호 해시';
COMMENT ON COLUMN usr_acnt.pfile_img IS '프로필 이미지 경로';
COMMENT ON COLUMN usr_acnt.crtd_at IS '생성일시';
COMMENT ON COLUMN usr_acnt.crtd_by IS '생성자 ID';
COMMENT ON COLUMN usr_acnt.updtd_at IS '수정일시';
COMMENT ON COLUMN usr_acnt.updtd_by IS '수정자 ID';

-- 1-5. menu (메뉴)
COMMENT ON TABLE menu IS '메뉴 — 포탈 사이드바 메뉴 구조';
COMMENT ON COLUMN menu.menu_id IS '메뉴 고유 ID';
COMMENT ON COLUMN menu.menu_cd IS '메뉴 코드';
COMMENT ON COLUMN menu.menu_nm IS '메뉴명';
COMMENT ON COLUMN menu.parent_cd IS '상위 메뉴 코드 (FK → menu.menu_cd)';
COMMENT ON COLUMN menu.sctn IS '메뉴 섹션 (사이드바 그룹)';
COMMENT ON COLUMN menu.scrin_id IS '화면 ID (navigate 대상)';
COMMENT ON COLUMN menu.icon IS '아이콘 클래스';
COMMENT ON COLUMN menu.sort_ord IS '정렬 순서';
COMMENT ON COLUMN menu.is_actv IS '활성 여부';
COMMENT ON COLUMN menu.crtd_at IS '생성일시';
COMMENT ON COLUMN menu.crtd_by IS '생성자 ID';
COMMENT ON COLUMN menu.updtd_at IS '수정일시';
COMMENT ON COLUMN menu.updtd_by IS '수정자 ID';

-- 1-6. role_menu_perm (역할별 메뉴 권한)
COMMENT ON TABLE role_menu_perm IS '역할별 메뉴 권한 — RBAC 메뉴 접근 제어';
COMMENT ON COLUMN role_menu_perm.role_id IS '역할 ID (FK → role)';
COMMENT ON COLUMN role_menu_perm.menu_id IS '메뉴 ID (FK → menu)';
COMMENT ON COLUMN role_menu_perm.can_read IS '조회 권한';
COMMENT ON COLUMN role_menu_perm.can_crt IS '생성 권한';
COMMENT ON COLUMN role_menu_perm.can_updt IS '수정 권한';
COMMENT ON COLUMN role_menu_perm.can_del IS '삭제 권한';
COMMENT ON COLUMN role_menu_perm.can_aprv IS '승인 권한';
COMMENT ON COLUMN role_menu_perm.can_dwld IS '다운로드 권한';
COMMENT ON COLUMN role_menu_perm.crtd_at IS '생성일시';
COMMENT ON COLUMN role_menu_perm.crtd_by IS '생성자 ID';
COMMENT ON COLUMN role_menu_perm.updtd_at IS '수정일시';
COMMENT ON COLUMN role_menu_perm.updtd_by IS '수정자 ID';

-- 1-7. login_hist (로그인 이력)
COMMENT ON TABLE login_hist IS '로그인 이력 — 사용자 로그인/로그아웃 기록';
COMMENT ON COLUMN login_hist.hist_id IS '이력 고유 ID';
COMMENT ON COLUMN login_hist.usr_id IS '사용자 ID (FK → usr_acnt)';
COMMENT ON COLUMN login_hist.login_ty IS '로그인 유형';
COMMENT ON COLUMN login_hist.login_ip IS '로그인 IP 주소';
COMMENT ON COLUMN login_hist.usr_agent IS 'User-Agent 문자열';
COMMENT ON COLUMN login_hist.login_at IS '로그인 일시';
COMMENT ON COLUMN login_hist.logout_at IS '로그아웃 일시';
COMMENT ON COLUMN login_hist.is_succes IS '로그인 성공 여부';
COMMENT ON COLUMN login_hist.fail_rsn IS '실패 사유';
COMMENT ON COLUMN login_hist.crtd_at IS '생성일시';
COMMENT ON COLUMN login_hist.crtd_by IS '생성자 ID';
COMMENT ON COLUMN login_hist.updtd_at IS '수정일시';
COMMENT ON COLUMN login_hist.updtd_by IS '수정자 ID';

-- 1-8. pwd_reset_hist (비밀번호 초기화 이력)
COMMENT ON TABLE pwd_reset_hist IS '비밀번호 초기화 이력';
COMMENT ON COLUMN pwd_reset_hist.reset_id IS '초기화 고유 ID';
COMMENT ON COLUMN pwd_reset_hist.usr_id IS '사용자 ID (FK → usr_acnt)';
COMMENT ON COLUMN pwd_reset_hist.reset_ty IS '초기화 유형 (email/admin/self)';
COMMENT ON COLUMN pwd_reset_hist.temp_pwd_hash IS '임시 비밀번호 해시';
COMMENT ON COLUMN pwd_reset_hist.req_ip IS '요청 IP 주소';
COMMENT ON COLUMN pwd_reset_hist.is_used IS '사용 여부';
COMMENT ON COLUMN pwd_reset_hist.expires_at IS '만료 일시';
COMMENT ON COLUMN pwd_reset_hist.crtd_at IS '생성일시';
COMMENT ON COLUMN pwd_reset_hist.crtd_by IS '생성자 ID';
COMMENT ON COLUMN pwd_reset_hist.updtd_at IS '수정일시';
COMMENT ON COLUMN pwd_reset_hist.updtd_by IS '수정자 ID';


-- ============================================================================
-- 2. 카탈로그·메타데이터 도메인
-- ============================================================================

-- 2-1. domn (데이터 도메인)
COMMENT ON TABLE domn IS '데이터 도메인 — 수자원/수질/에너지 등 업무 도메인 분류';
COMMENT ON COLUMN domn.domn_id IS '도메인 고유 ID';
COMMENT ON COLUMN domn.domn_cd IS '도메인 코드';
COMMENT ON COLUMN domn.domn_nm IS '도메인명';
COMMENT ON COLUMN domn.dc IS '설명';
COMMENT ON COLUMN domn.color IS '도메인 색상 (HEX)';
COMMENT ON COLUMN domn.icon IS '아이콘 클래스';
COMMENT ON COLUMN domn.sort_ord IS '정렬 순서';
COMMENT ON COLUMN domn.is_actv IS '활성 여부';
COMMENT ON COLUMN domn.crtd_at IS '생성일시';
COMMENT ON COLUMN domn.crtd_by IS '생성자 ID';
COMMENT ON COLUMN domn.updtd_at IS '수정일시';
COMMENT ON COLUMN domn.updtd_by IS '수정자 ID';

-- 2-2. src_sys (원천 시스템)
COMMENT ON TABLE src_sys IS '원천 시스템 — 데이터 수집 대상 시스템 정보';
COMMENT ON COLUMN src_sys.sys_id IS '시스템 고유 ID';
COMMENT ON COLUMN src_sys.sys_cd IS '시스템 코드';
COMMENT ON COLUMN src_sys.sys_nm IS '시스템명 (한글)';
COMMENT ON COLUMN src_sys.sys_nm_en IS '시스템명 (영문)';
COMMENT ON COLUMN src_sys.dc IS '설명';
COMMENT ON COLUMN src_sys.dbms_ty IS 'DBMS 유형 (PostgreSQL/Oracle 등)';
COMMENT ON COLUMN src_sys.prtcl IS '프로토콜 (JDBC/REST/gRPC 등)';
COMMENT ON COLUMN src_sys.ntwk_zone IS '네트워크 영역 (DMZ/내부 등)';
COMMENT ON COLUMN src_sys.cnctn_info IS '접속 정보 (JSONB)';
COMMENT ON COLUMN src_sys.owner_dept_id IS '소유 부서 ID (FK → dept)';
COMMENT ON COLUMN src_sys.stat IS '상태';
COMMENT ON COLUMN src_sys.crtd_at IS '생성일시';
COMMENT ON COLUMN src_sys.crtd_by IS '생성자 ID';
COMMENT ON COLUMN src_sys.updtd_at IS '수정일시';
COMMENT ON COLUMN src_sys.updtd_by IS '수정자 ID';

-- 2-3. dset (데이터셋)
COMMENT ON TABLE dset IS '데이터셋 — 관리 대상 데이터 자산 (테이블/API/파일 등)';
COMMENT ON COLUMN dset.dset_id IS '데이터셋 고유 ID (UUID)';
COMMENT ON COLUMN dset.dset_cd IS '데이터셋 코드';
COMMENT ON COLUMN dset.table_nm IS '테이블명';
COMMENT ON COLUMN dset.dset_nm IS '데이터셋명';
COMMENT ON COLUMN dset.dc IS '설명';
COMMENT ON COLUMN dset.domn_id IS '도메인 ID (FK → domn)';
COMMENT ON COLUMN dset.sys_id IS '원천 시스템 ID (FK → src_sys)';
COMMENT ON COLUMN dset.asset_ty IS '자산 유형 (table/api/file/view/stream)';
COMMENT ON COLUMN dset.scrty_lvl IS '보안 등급 (public/internal/restricted/confidential)';
COMMENT ON COLUMN dset.qlity_score IS '품질 점수 (0~100)';
COMMENT ON COLUMN dset.row_co IS '행 건수';
COMMENT ON COLUMN dset.col_co IS '컬럼 수';
COMMENT ON COLUMN dset.size_bytes IS '데이터 크기 (bytes)';
COMMENT ON COLUMN dset.owner_dept_id IS '소유 부서 ID (FK → dept)';
COMMENT ON COLUMN dset.stwrd_usr_id IS '데이터 스튜어드 사용자 ID (FK → usr_acnt)';
COMMENT ON COLUMN dset.stat IS '상태';
COMMENT ON COLUMN dset.last_prfld_at IS '마지막 프로파일링 일시';
COMMENT ON COLUMN dset.crtd_at IS '생성일시';
COMMENT ON COLUMN dset.crtd_by IS '생성자 ID';
COMMENT ON COLUMN dset.updtd_at IS '수정일시';
COMMENT ON COLUMN dset.updtd_by IS '수정자 ID';

-- 2-4. dset_col (데이터셋 컬럼)
COMMENT ON TABLE dset_col IS '데이터셋 컬럼 — 데이터셋의 컬럼 정의 및 프로파일링 결과';
COMMENT ON COLUMN dset_col.col_id IS '컬럼 고유 ID';
COMMENT ON COLUMN dset_col.dset_id IS '데이터셋 ID (FK → dset)';
COMMENT ON COLUMN dset_col.col_nm IS '컬럼명 (영문)';
COMMENT ON COLUMN dset_col.col_nm_ko IS '컬럼명 (한글)';
COMMENT ON COLUMN dset_col.data_ty IS '데이터 유형';
COMMENT ON COLUMN dset_col.data_lt IS '데이터 길이';
COMMENT ON COLUMN dset_col.is_pk IS 'PK 여부';
COMMENT ON COLUMN dset_col.is_fk IS 'FK 여부';
COMMENT ON COLUMN dset_col.is_nulbl IS 'NULL 허용 여부';
COMMENT ON COLUMN dset_col.dflt_val IS '기본값';
COMMENT ON COLUMN dset_col.std_term_id IS '표준용어 ID';
COMMENT ON COLUMN dset_col.dc IS '설명';
COMMENT ON COLUMN dset_col.null_rt IS 'NULL 비율 (%)';
COMMENT ON COLUMN dset_col.unique_rt IS '유일값 비율 (%)';
COMMENT ON COLUMN dset_col.min_val IS '최소값';
COMMENT ON COLUMN dset_col.max_val IS '최대값';
COMMENT ON COLUMN dset_col.smple_vals IS '샘플 값 배열';
COMMENT ON COLUMN dset_col.sort_ord IS '정렬 순서';
COMMENT ON COLUMN dset_col.crtd_at IS '생성일시';
COMMENT ON COLUMN dset_col.crtd_by IS '생성자 ID';
COMMENT ON COLUMN dset_col.updtd_at IS '수정일시';
COMMENT ON COLUMN dset_col.updtd_by IS '수정자 ID';

-- 2-5. tag (태그)
COMMENT ON TABLE tag IS '태그 — 데이터셋에 부여하는 분류 키워드';
COMMENT ON COLUMN tag.tag_id IS '태그 고유 ID';
COMMENT ON COLUMN tag.tag_nm IS '태그명';
COMMENT ON COLUMN tag.tag_ty IS '태그 유형 (keyword 등)';
COMMENT ON COLUMN tag.color IS '태그 색상 (HEX)';
COMMENT ON COLUMN tag.crtd_at IS '생성일시';
COMMENT ON COLUMN tag.crtd_by IS '생성자 ID';
COMMENT ON COLUMN tag.updtd_at IS '수정일시';
COMMENT ON COLUMN tag.updtd_by IS '수정자 ID';

-- 2-6. dset_tag (데이터셋-태그 매핑)
COMMENT ON TABLE dset_tag IS '데이터셋-태그 매핑 — 데이터셋과 태그 간 N:M 관계';
COMMENT ON COLUMN dset_tag.dset_id IS '데이터셋 ID (FK → dset)';
COMMENT ON COLUMN dset_tag.tag_id IS '태그 ID (FK → tag)';
COMMENT ON COLUMN dset_tag.crtd_at IS '생성일시';
COMMENT ON COLUMN dset_tag.crtd_by IS '생성자 ID';
COMMENT ON COLUMN dset_tag.updtd_at IS '수정일시';
COMMENT ON COLUMN dset_tag.updtd_by IS '수정자 ID';

-- 2-7. bmrk (즐겨찾기)
COMMENT ON TABLE bmrk IS '즐겨찾기 — 사용자별 데이터셋 북마크';
COMMENT ON COLUMN bmrk.bmrk_id IS '즐겨찾기 고유 ID';
COMMENT ON COLUMN bmrk.usr_id IS '사용자 ID (FK → usr_acnt)';
COMMENT ON COLUMN bmrk.dset_id IS '데이터셋 ID (FK → dset)';
COMMENT ON COLUMN bmrk.memo IS '메모';
COMMENT ON COLUMN bmrk.crtd_at IS '생성일시';
COMMENT ON COLUMN bmrk.crtd_by IS '생성자 ID';
COMMENT ON COLUMN bmrk.updtd_at IS '수정일시';
COMMENT ON COLUMN bmrk.updtd_by IS '수정자 ID';

-- 2-8. glsry_term (용어사전)
COMMENT ON TABLE glsry_term IS '용어사전 — 업무 용어 정의 및 승인 관리';
COMMENT ON COLUMN glsry_term.term_id IS '용어 고유 ID';
COMMENT ON COLUMN glsry_term.term_nm IS '용어명 (한글)';
COMMENT ON COLUMN glsry_term.term_nm_en IS '용어명 (영문)';
COMMENT ON COLUMN glsry_term.domn_id IS '도메인 ID (FK → domn)';
COMMENT ON COLUMN glsry_term.data_ty IS '데이터 유형';
COMMENT ON COLUMN glsry_term.data_lt IS '데이터 길이';
COMMENT ON COLUMN glsry_term.unit IS '단위';
COMMENT ON COLUMN glsry_term.valid_rng_min IS '유효 범위 최소값';
COMMENT ON COLUMN glsry_term.valid_rng_max IS '유효 범위 최대값';
COMMENT ON COLUMN glsry_term.dfn IS '정의 (설명)';
COMMENT ON COLUMN glsry_term.exmp IS '예시';
COMMENT ON COLUMN glsry_term.synm IS '동의어';
COMMENT ON COLUMN glsry_term.stat IS '승인 상태 (pending/approved/rejected 등)';
COMMENT ON COLUMN glsry_term.aprvd_by IS '승인자 ID (FK → usr_acnt)';
COMMENT ON COLUMN glsry_term.aprvd_at IS '승인 일시';
COMMENT ON COLUMN glsry_term.crtd_at IS '생성일시';
COMMENT ON COLUMN glsry_term.crtd_by IS '생성자 ID (FK → usr_acnt)';
COMMENT ON COLUMN glsry_term.updtd_at IS '수정일시';
COMMENT ON COLUMN glsry_term.updtd_by IS '수정자 ID';

-- 2-9. glsry_hist (용어사전 변경이력)
COMMENT ON TABLE glsry_hist IS '용어사전 변경이력 — 용어 변경/승인 이력 추적';
COMMENT ON COLUMN glsry_hist.hist_id IS '이력 고유 ID';
COMMENT ON COLUMN glsry_hist.term_id IS '용어 ID (FK → glsry_term)';
COMMENT ON COLUMN glsry_hist.chg_desc IS '변경 설명';
COMMENT ON COLUMN glsry_hist.chgd_by IS '변경자 ID (FK → usr_acnt)';
COMMENT ON COLUMN glsry_hist.prev_stat IS '이전 상태';
COMMENT ON COLUMN glsry_hist.new_stat IS '변경 후 상태';
COMMENT ON COLUMN glsry_hist.prev_val IS '이전 값 (JSONB)';
COMMENT ON COLUMN glsry_hist.new_val IS '변경 후 값 (JSONB)';
COMMENT ON COLUMN glsry_hist.crtd_at IS '생성일시';
COMMENT ON COLUMN glsry_hist.crtd_by IS '생성자 ID';
COMMENT ON COLUMN glsry_hist.updtd_at IS '수정일시';
COMMENT ON COLUMN glsry_hist.updtd_by IS '수정자 ID';

-- 2-10. cd_grp (코드 그룹)
COMMENT ON TABLE cd_grp IS '코드 그룹 — 공통 코드 그룹 정의';
COMMENT ON COLUMN cd_grp.grp_id IS '코드그룹 고유 ID';
COMMENT ON COLUMN cd_grp.grp_cd IS '코드그룹 코드';
COMMENT ON COLUMN cd_grp.grp_nm IS '코드그룹명';
COMMENT ON COLUMN cd_grp.dc IS '설명';
COMMENT ON COLUMN cd_grp.is_actv IS '활성 여부';
COMMENT ON COLUMN cd_grp.crtd_at IS '생성일시';
COMMENT ON COLUMN cd_grp.crtd_by IS '생성자 ID';
COMMENT ON COLUMN cd_grp.updtd_at IS '수정일시';
COMMENT ON COLUMN cd_grp.updtd_by IS '수정자 ID';

-- 2-11. cd (코드)
COMMENT ON TABLE cd IS '코드 — 공통 코드 값 정의';
COMMENT ON COLUMN cd.cd_id IS '코드 고유 ID';
COMMENT ON COLUMN cd.grp_id IS '코드그룹 ID (FK → cd_grp)';
COMMENT ON COLUMN cd.cd_val IS '코드값';
COMMENT ON COLUMN cd.cd_nm IS '코드명';
COMMENT ON COLUMN cd.dc IS '설명';
COMMENT ON COLUMN cd.sort_ord IS '정렬 순서';
COMMENT ON COLUMN cd.is_actv IS '활성 여부';
COMMENT ON COLUMN cd.crtd_at IS '생성일시';
COMMENT ON COLUMN cd.crtd_by IS '생성자 ID';
COMMENT ON COLUMN cd.updtd_at IS '수정일시';
COMMENT ON COLUMN cd.updtd_by IS '수정자 ID';

-- 2-12. data_model (데이터 모델)
COMMENT ON TABLE data_model IS '데이터 모델 — 논리/물리 데이터 모델 정의';
COMMENT ON COLUMN data_model.model_id IS '모델 고유 ID';
COMMENT ON COLUMN data_model.model_nm IS '모델명';
COMMENT ON COLUMN data_model.model_ty IS '모델 유형 (logical/physical)';
COMMENT ON COLUMN data_model.domn_id IS '도메인 ID (FK → domn)';
COMMENT ON COLUMN data_model.ver IS '버전';
COMMENT ON COLUMN data_model.dc IS '설명';
COMMENT ON COLUMN data_model.table_co IS '테이블 수';
COMMENT ON COLUMN data_model.namng_cmplnc IS '명명규칙 준수율 (%)';
COMMENT ON COLUMN data_model.ty_cnstnc IS '타입 일관성 (%)';
COMMENT ON COLUMN data_model.ref_intgrty IS '참조 무결성 (%)';
COMMENT ON COLUMN data_model.stat IS '상태';
COMMENT ON COLUMN data_model.owner_usr_id IS '소유자 ID (FK → usr_acnt)';
COMMENT ON COLUMN data_model.crtd_at IS '생성일시';
COMMENT ON COLUMN data_model.crtd_by IS '생성자 ID';
COMMENT ON COLUMN data_model.updtd_at IS '수정일시';
COMMENT ON COLUMN data_model.updtd_by IS '수정자 ID';

-- 2-13. model_entty (모델 엔티티)
COMMENT ON TABLE model_entty IS '모델 엔티티 — 데이터 모델 내 테이블/엔티티 정의';
COMMENT ON COLUMN model_entty.entty_id IS '엔티티 고유 ID';
COMMENT ON COLUMN model_entty.model_id IS '모델 ID (FK → data_model)';
COMMENT ON COLUMN model_entty.entty_nm IS '엔티티명 (영문)';
COMMENT ON COLUMN model_entty.entty_nm_ko IS '엔티티명 (한글)';
COMMENT ON COLUMN model_entty.entty_ty IS '엔티티 유형 (table 등)';
COMMENT ON COLUMN model_entty.dc IS '설명';
COMMENT ON COLUMN model_entty.sort_ord IS '정렬 순서';
COMMENT ON COLUMN model_entty.crtd_at IS '생성일시';
COMMENT ON COLUMN model_entty.crtd_by IS '생성자 ID';
COMMENT ON COLUMN model_entty.updtd_at IS '수정일시';
COMMENT ON COLUMN model_entty.updtd_by IS '수정자 ID';

-- 2-14. model_atrb (모델 속성)
COMMENT ON TABLE model_atrb IS '모델 속성 — 엔티티 내 컬럼/속성 정의';
COMMENT ON COLUMN model_atrb.atrb_id IS '속성 고유 ID';
COMMENT ON COLUMN model_atrb.entty_id IS '엔티티 ID (FK → model_entty)';
COMMENT ON COLUMN model_atrb.atrb_nm IS '속성명 (영문)';
COMMENT ON COLUMN model_atrb.atrb_nm_ko IS '속성명 (한글)';
COMMENT ON COLUMN model_atrb.data_ty IS '데이터 유형';
COMMENT ON COLUMN model_atrb.data_lt IS '데이터 길이';
COMMENT ON COLUMN model_atrb.is_pk IS 'PK 여부';
COMMENT ON COLUMN model_atrb.is_fk IS 'FK 여부';
COMMENT ON COLUMN model_atrb.is_nulbl IS 'NULL 허용 여부';
COMMENT ON COLUMN model_atrb.fk_ref_entty IS 'FK 참조 엔티티명';
COMMENT ON COLUMN model_atrb.fk_ref_atrb IS 'FK 참조 속성명';
COMMENT ON COLUMN model_atrb.dc IS '설명';
COMMENT ON COLUMN model_atrb.sort_ord IS '정렬 순서';
COMMENT ON COLUMN model_atrb.crtd_at IS '생성일시';
COMMENT ON COLUMN model_atrb.crtd_by IS '생성자 ID';
COMMENT ON COLUMN model_atrb.updtd_at IS '수정일시';
COMMENT ON COLUMN model_atrb.updtd_by IS '수정자 ID';


-- ============================================================================
-- 3. 수집 관리 도메인
-- ============================================================================

-- 3-1. ppln (파이프라인)
COMMENT ON TABLE ppln IS '파이프라인 — 데이터 수집 파이프라인 정의';
COMMENT ON COLUMN ppln.ppln_id IS '파이프라인 고유 ID';
COMMENT ON COLUMN ppln.ppln_nm IS '파이프라인명';
COMMENT ON COLUMN ppln.ppln_cd IS '파이프라인 코드';
COMMENT ON COLUMN ppln.sys_id IS '원천 시스템 ID (FK → src_sys)';
COMMENT ON COLUMN ppln.colct_mthd IS '수집 방식 (cdc/batch/api/file/streaming/migration)';
COMMENT ON COLUMN ppln.schdul IS '스케줄 (cron 등)';
COMMENT ON COLUMN ppln.src_table IS '원천 테이블명';
COMMENT ON COLUMN ppln.trget_stg IS '적재 대상 (스토리지)';
COMMENT ON COLUMN ppln.thrput IS '처리량';
COMMENT ON COLUMN ppln.dc IS '설명';
COMMENT ON COLUMN ppln.owner_usr_id IS '소유자 ID (FK → usr_acnt)';
COMMENT ON COLUMN ppln.owner_dept_id IS '소유 부서 ID (FK → dept)';
COMMENT ON COLUMN ppln.stat IS '상태';
COMMENT ON COLUMN ppln.crtd_at IS '생성일시';
COMMENT ON COLUMN ppln.crtd_by IS '생성자 ID';
COMMENT ON COLUMN ppln.updtd_at IS '수정일시';
COMMENT ON COLUMN ppln.updtd_by IS '수정자 ID';

-- 3-2. ppln_exec (파이프라인 실행이력)
COMMENT ON TABLE ppln_exec IS '파이프라인 실행이력 — 파이프라인 실행 결과 기록';
COMMENT ON COLUMN ppln_exec.exec_id IS '실행 고유 ID';
COMMENT ON COLUMN ppln_exec.ppln_id IS '파이프라인 ID (FK → ppln)';
COMMENT ON COLUMN ppln_exec.strtd_at IS '시작 일시';
COMMENT ON COLUMN ppln_exec.fnshed_at IS '종료 일시';
COMMENT ON COLUMN ppln_exec.dur_secnd IS '소요 시간 (초)';
COMMENT ON COLUMN ppln_exec.rcrds_read IS '읽은 레코드 수';
COMMENT ON COLUMN ppln_exec.rcrds_wrtn IS '기록한 레코드 수';
COMMENT ON COLUMN ppln_exec.rcrds_err IS '오류 레코드 수';
COMMENT ON COLUMN ppln_exec.succes_rt IS '성공률 (%)';
COMMENT ON COLUMN ppln_exec.stat IS '실행 상태 (running/success/failed/cancelled)';
COMMENT ON COLUMN ppln_exec.err_msg IS '오류 메시지';
COMMENT ON COLUMN ppln_exec.err_dtl IS '오류 상세 (JSONB)';
COMMENT ON COLUMN ppln_exec.crtd_at IS '생성일시';
COMMENT ON COLUMN ppln_exec.crtd_by IS '생성자 ID';
COMMENT ON COLUMN ppln_exec.updtd_at IS '수정일시';
COMMENT ON COLUMN ppln_exec.updtd_by IS '수정자 ID';

-- 3-3. ppln_col_mapng (파이프라인 컬럼 매핑)
COMMENT ON TABLE ppln_col_mapng IS '파이프라인 컬럼 매핑 — 원천-적재 컬럼 매핑 정의';
COMMENT ON COLUMN ppln_col_mapng.mapng_id IS '매핑 고유 ID';
COMMENT ON COLUMN ppln_col_mapng.ppln_id IS '파이프라인 ID (FK → ppln)';
COMMENT ON COLUMN ppln_col_mapng.src_col IS '원천 컬럼명';
COMMENT ON COLUMN ppln_col_mapng.trget_col IS '적재 컬럼명';
COMMENT ON COLUMN ppln_col_mapng.src_ty IS '원천 데이터 유형';
COMMENT ON COLUMN ppln_col_mapng.trget_ty IS '적재 데이터 유형';
COMMENT ON COLUMN ppln_col_mapng.trsfm_rule IS '변환 규칙';
COMMENT ON COLUMN ppln_col_mapng.is_reqrd IS '필수 여부';
COMMENT ON COLUMN ppln_col_mapng.sort_ord IS '정렬 순서';
COMMENT ON COLUMN ppln_col_mapng.crtd_at IS '생성일시';
COMMENT ON COLUMN ppln_col_mapng.crtd_by IS '생성자 ID';
COMMENT ON COLUMN ppln_col_mapng.updtd_at IS '수정일시';
COMMENT ON COLUMN ppln_col_mapng.updtd_by IS '수정자 ID';

-- 3-4. cdc_cnctr (CDC 커넥터)
COMMENT ON TABLE cdc_cnctr IS 'CDC 커넥터 — Change Data Capture 커넥터 정보';
COMMENT ON COLUMN cdc_cnctr.cnctr_id IS '커넥터 고유 ID';
COMMENT ON COLUMN cdc_cnctr.sys_id IS '원천 시스템 ID (FK → src_sys)';
COMMENT ON COLUMN cdc_cnctr.cnctr_nm IS '커넥터명';
COMMENT ON COLUMN cdc_cnctr.cnctr_ty IS '커넥터 유형';
COMMENT ON COLUMN cdc_cnctr.dbms_ty IS 'DBMS 유형';
COMMENT ON COLUMN cdc_cnctr.table_co IS '대상 테이블 수';
COMMENT ON COLUMN cdc_cnctr.evnt_per_min IS '분당 이벤트 수';
COMMENT ON COLUMN cdc_cnctr.lag_secnd IS '지연 시간 (초)';
COMMENT ON COLUMN cdc_cnctr.cnfg IS '설정 정보 (JSONB)';
COMMENT ON COLUMN cdc_cnctr.stat IS '상태';
COMMENT ON COLUMN cdc_cnctr.crtd_at IS '생성일시';
COMMENT ON COLUMN cdc_cnctr.crtd_by IS '생성자 ID';
COMMENT ON COLUMN cdc_cnctr.updtd_at IS '수정일시';
COMMENT ON COLUMN cdc_cnctr.updtd_by IS '수정자 ID';

-- 3-5. kafka_topc (카프카 토픽)
COMMENT ON TABLE kafka_topc IS '카프카 토픽 — Kafka 토픽 관리 정보';
COMMENT ON COLUMN kafka_topc.topc_id IS '토픽 고유 ID';
COMMENT ON COLUMN kafka_topc.topc_nm IS '토픽명';
COMMENT ON COLUMN kafka_topc.clstr_nm IS '클러스터명';
COMMENT ON COLUMN kafka_topc.prtitn_co IS '파티션 수';
COMMENT ON COLUMN kafka_topc.rplctn IS '복제 팩터';
COMMENT ON COLUMN kafka_topc.rtntn_hr IS '보존 기간 (시간)';
COMMENT ON COLUMN kafka_topc.msg_per_sec IS '초당 메시지 수';
COMMENT ON COLUMN kafka_topc.cnsmr_grps IS '컨슈머 그룹 목록';
COMMENT ON COLUMN kafka_topc.stat IS '상태';
COMMENT ON COLUMN kafka_topc.crtd_at IS '생성일시';
COMMENT ON COLUMN kafka_topc.crtd_by IS '생성자 ID';
COMMENT ON COLUMN kafka_topc.updtd_at IS '수정일시';
COMMENT ON COLUMN kafka_topc.updtd_by IS '수정자 ID';

-- 3-6. extn_intgrn (외부 연동)
COMMENT ON TABLE extn_intgrn IS '외부 연동 — 외부 시스템 연동 정보';
COMMENT ON COLUMN extn_intgrn.intgrn_id IS '연동 고유 ID';
COMMENT ON COLUMN extn_intgrn.intgrn_nm IS '연동명';
COMMENT ON COLUMN extn_intgrn.intgrn_ty IS '연동 유형';
COMMENT ON COLUMN extn_intgrn.src_sys IS '원천 시스템';
COMMENT ON COLUMN extn_intgrn.trget_sys IS '대상 시스템';
COMMENT ON COLUMN extn_intgrn.prtcl IS '프로토콜';
COMMENT ON COLUMN extn_intgrn.endpt_url IS '엔드포인트 URL';
COMMENT ON COLUMN extn_intgrn.freq IS '연동 주기';
COMMENT ON COLUMN extn_intgrn.last_succes_at IS '마지막 성공 일시';
COMMENT ON COLUMN extn_intgrn.last_fail_at IS '마지막 실패 일시';
COMMENT ON COLUMN extn_intgrn.stat IS '상태';
COMMENT ON COLUMN extn_intgrn.crtd_at IS '생성일시';
COMMENT ON COLUMN extn_intgrn.crtd_by IS '생성자 ID';
COMMENT ON COLUMN extn_intgrn.updtd_at IS '수정일시';
COMMENT ON COLUMN extn_intgrn.updtd_by IS '수정자 ID';

-- 3-7. dbt_model (dbt 모델)
COMMENT ON TABLE dbt_model IS 'dbt 모델 — dbt 변환 모델 관리';
COMMENT ON COLUMN dbt_model.dbt_model_id IS 'dbt 모델 고유 ID';
COMMENT ON COLUMN dbt_model.model_nm IS '모델명';
COMMENT ON COLUMN dbt_model.model_path IS '모델 파일 경로';
COMMENT ON COLUMN dbt_model.mtrlzn IS '구체화 유형 (table/view/incremental)';
COMMENT ON COLUMN dbt_model.src_tbls IS '원천 테이블 목록';
COMMENT ON COLUMN dbt_model.trget_table IS '적재 대상 테이블';
COMMENT ON COLUMN dbt_model.dc IS '설명';
COMMENT ON COLUMN dbt_model.tags IS '태그 목록';
COMMENT ON COLUMN dbt_model.last_run_at IS '마지막 실행 일시';
COMMENT ON COLUMN dbt_model.last_run_stat IS '마지막 실행 상태';
COMMENT ON COLUMN dbt_model.run_dur_secnd IS '실행 소요 시간 (초)';
COMMENT ON COLUMN dbt_model.owner_usr_id IS '소유자 ID (FK → usr_acnt)';
COMMENT ON COLUMN dbt_model.stat IS '상태';
COMMENT ON COLUMN dbt_model.crtd_at IS '생성일시';
COMMENT ON COLUMN dbt_model.crtd_by IS '생성자 ID';
COMMENT ON COLUMN dbt_model.updtd_at IS '수정일시';
COMMENT ON COLUMN dbt_model.updtd_by IS '수정자 ID';

-- 3-8. server_invntry (서버 인벤토리)
COMMENT ON TABLE server_invntry IS '서버 인벤토리 — 인프라 서버 자산 관리';
COMMENT ON COLUMN server_invntry.server_id IS '서버 고유 ID';
COMMENT ON COLUMN server_invntry.server_nm IS '서버명';
COMMENT ON COLUMN server_invntry.server_ty IS '서버 유형';
COMMENT ON COLUMN server_invntry.ip_addr IS 'IP 주소';
COMMENT ON COLUMN server_invntry.os_ty IS 'OS 유형';
COMMENT ON COLUMN server_invntry.cpu_cores IS 'CPU 코어 수';
COMMENT ON COLUMN server_invntry.mory_gb IS '메모리 (GB)';
COMMENT ON COLUMN server_invntry.disk_gb IS '디스크 (GB)';
COMMENT ON COLUMN server_invntry.envrn IS '환경 (운영/개발/테스트)';
COMMENT ON COLUMN server_invntry.dtcntr IS '데이터센터';
COMMENT ON COLUMN server_invntry.stat IS '상태';
COMMENT ON COLUMN server_invntry.crtd_at IS '생성일시';
COMMENT ON COLUMN server_invntry.crtd_by IS '생성자 ID';
COMMENT ON COLUMN server_invntry.updtd_at IS '수정일시';
COMMENT ON COLUMN server_invntry.updtd_by IS '수정자 ID';


-- ============================================================================
-- 4. 유통·활용 도메인
-- ============================================================================

-- 4-1. data_product (데이터 상품)
COMMENT ON TABLE data_product IS '데이터 상품 — API/파일 형태의 데이터 유통 상품';
COMMENT ON COLUMN data_product.product_id IS '상품 고유 ID (UUID)';
COMMENT ON COLUMN data_product.product_cd IS '상품 코드';
COMMENT ON COLUMN data_product.product_nm IS '상품명';
COMMENT ON COLUMN data_product.dc IS '설명';
COMMENT ON COLUMN data_product.product_ty IS '상품 유형 (api 등)';
COMMENT ON COLUMN data_product.domn_id IS '도메인 ID (FK → domn)';
COMMENT ON COLUMN data_product.scrty_lvl IS '보안 등급';
COMMENT ON COLUMN data_product.ver IS '버전';
COMMENT ON COLUMN data_product.endpt_url IS '엔드포인트 URL';
COMMENT ON COLUMN data_product.rt_limit IS '호출 제한 (건/일)';
COMMENT ON COLUMN data_product.tot_calls IS '총 호출 수';
COMMENT ON COLUMN data_product.avg_rspns_ms IS '평균 응답 시간 (ms)';
COMMENT ON COLUMN data_product.sla_uptm IS 'SLA 가용률 (%)';
COMMENT ON COLUMN data_product.owner_dept_id IS '소유 부서 ID (FK → dept)';
COMMENT ON COLUMN data_product.owner_usr_id IS '소유자 ID (FK → usr_acnt)';
COMMENT ON COLUMN data_product.stat IS '상태';
COMMENT ON COLUMN data_product.pblshd_at IS '발행 일시';
COMMENT ON COLUMN data_product.crtd_at IS '생성일시';
COMMENT ON COLUMN data_product.crtd_by IS '생성자 ID';
COMMENT ON COLUMN data_product.updtd_at IS '수정일시';
COMMENT ON COLUMN data_product.updtd_by IS '수정자 ID';

-- 4-2. product_src (상품 원천)
COMMENT ON TABLE product_src IS '상품 원천 — 데이터 상품의 원천 데이터셋 매핑';
COMMENT ON COLUMN product_src.src_id IS '원천 매핑 고유 ID';
COMMENT ON COLUMN product_src.product_id IS '상품 ID (FK → data_product)';
COMMENT ON COLUMN product_src.dset_id IS '데이터셋 ID (FK → dset)';
COMMENT ON COLUMN product_src.join_ty IS '조인 유형';
COMMENT ON COLUMN product_src.join_key IS '조인 키';
COMMENT ON COLUMN product_src.dc IS '설명';
COMMENT ON COLUMN product_src.sort_ord IS '정렬 순서';
COMMENT ON COLUMN product_src.crtd_at IS '생성일시';
COMMENT ON COLUMN product_src.crtd_by IS '생성자 ID';
COMMENT ON COLUMN product_src.updtd_at IS '수정일시';
COMMENT ON COLUMN product_src.updtd_by IS '수정자 ID';

-- 4-3. product_field (상품 필드)
COMMENT ON TABLE product_field IS '상품 필드 — 데이터 상품의 응답 필드 정의';
COMMENT ON COLUMN product_field.field_id IS '필드 고유 ID';
COMMENT ON COLUMN product_field.product_id IS '상품 ID (FK → data_product)';
COMMENT ON COLUMN product_field.field_nm IS '필드명 (영문)';
COMMENT ON COLUMN product_field.field_nm_ko IS '필드명 (한글)';
COMMENT ON COLUMN product_field.field_ty IS '필드 데이터 유형';
COMMENT ON COLUMN product_field.is_reqrd IS '필수 여부';
COMMENT ON COLUMN product_field.is_fltrbl IS '필터 가능 여부';
COMMENT ON COLUMN product_field.dc IS '설명';
COMMENT ON COLUMN product_field.smple_val IS '샘플값';
COMMENT ON COLUMN product_field.sort_ord IS '정렬 순서';
COMMENT ON COLUMN product_field.crtd_at IS '생성일시';
COMMENT ON COLUMN product_field.crtd_by IS '생성자 ID';
COMMENT ON COLUMN product_field.updtd_at IS '수정일시';
COMMENT ON COLUMN product_field.updtd_by IS '수정자 ID';

-- 4-4. api_key (API 키)
COMMENT ON TABLE api_key IS 'API 키 — 데이터 상품 접근용 API 키 관리';
COMMENT ON COLUMN api_key.key_id IS 'API 키 고유 ID (UUID)';
COMMENT ON COLUMN api_key.usr_id IS '사용자 ID (FK → usr_acnt)';
COMMENT ON COLUMN api_key.product_id IS '상품 ID (FK → data_product)';
COMMENT ON COLUMN api_key.api_key_hash IS 'API 키 해시값';
COMMENT ON COLUMN api_key.key_prfx IS '키 접두어 (표시용)';
COMMENT ON COLUMN api_key.dc IS '설명';
COMMENT ON COLUMN api_key.is_actv IS '활성 여부';
COMMENT ON COLUMN api_key.expirs_at IS '만료 일시';
COMMENT ON COLUMN api_key.last_used_at IS '마지막 사용 일시';
COMMENT ON COLUMN api_key.tot_calls IS '총 호출 수';
COMMENT ON COLUMN api_key.crtd_at IS '생성일시';
COMMENT ON COLUMN api_key.crtd_by IS '생성자 ID';
COMMENT ON COLUMN api_key.updtd_at IS '수정일시';
COMMENT ON COLUMN api_key.updtd_by IS '수정자 ID';

-- 4-5. didntf_polcy (비식별화 정책)
COMMENT ON TABLE didntf_polcy IS '비식별화 정책 — 개인정보 비식별화 정책 정의';
COMMENT ON COLUMN didntf_polcy.polcy_id IS '정책 고유 ID';
COMMENT ON COLUMN didntf_polcy.polcy_nm IS '정책명';
COMMENT ON COLUMN didntf_polcy.dc IS '설명';
COMMENT ON COLUMN didntf_polcy.trget_lvl IS '대상 보안 등급';
COMMENT ON COLUMN didntf_polcy.rule_co IS '규칙 수';
COMMENT ON COLUMN didntf_polcy.is_actv IS '활성 여부';
COMMENT ON COLUMN didntf_polcy.aprvd_by IS '승인자 ID (FK → usr_acnt)';
COMMENT ON COLUMN didntf_polcy.crtd_at IS '생성일시';
COMMENT ON COLUMN didntf_polcy.crtd_by IS '생성자 ID (FK → usr_acnt)';
COMMENT ON COLUMN didntf_polcy.updtd_at IS '수정일시';
COMMENT ON COLUMN didntf_polcy.updtd_by IS '수정자 ID';

-- 4-6. didntf_rule (비식별화 규칙)
COMMENT ON TABLE didntf_rule IS '비식별화 규칙 — 컬럼별 비식별화 처리 규칙';
COMMENT ON COLUMN didntf_rule.rule_id IS '규칙 고유 ID';
COMMENT ON COLUMN didntf_rule.polcy_id IS '정책 ID (FK → didntf_polcy)';
COMMENT ON COLUMN didntf_rule.col_pttrn IS '대상 컬럼 패턴';
COMMENT ON COLUMN didntf_rule.rule_ty IS '규칙 유형 (masking/pseudonym/aggregation 등)';
COMMENT ON COLUMN didntf_rule.rule_cnfg IS '규칙 설정 (JSONB)';
COMMENT ON COLUMN didntf_rule.priort IS '우선순위';
COMMENT ON COLUMN didntf_rule.dc IS '설명';
COMMENT ON COLUMN didntf_rule.crtd_at IS '생성일시';
COMMENT ON COLUMN didntf_rule.crtd_by IS '생성자 ID';
COMMENT ON COLUMN didntf_rule.updtd_at IS '수정일시';
COMMENT ON COLUMN didntf_rule.updtd_by IS '수정자 ID';

-- 4-7. data_rqst (데이터 신청)
COMMENT ON TABLE data_rqst IS '데이터 신청 — 데이터 이용/반출 신청 및 승인';
COMMENT ON COLUMN data_rqst.rqst_id IS '신청 고유 ID';
COMMENT ON COLUMN data_rqst.rqst_cd IS '신청 코드';
COMMENT ON COLUMN data_rqst.usr_id IS '신청자 ID (FK → usr_acnt)';
COMMENT ON COLUMN data_rqst.dset_id IS '데이터셋 ID (FK → dset)';
COMMENT ON COLUMN data_rqst.product_id IS '상품 ID (FK → data_product)';
COMMENT ON COLUMN data_rqst.rqst_ty IS '신청 유형 (다운로드/API접근/공유/반출)';
COMMENT ON COLUMN data_rqst.purps IS '이용 목적';
COMMENT ON COLUMN data_rqst.is_urgnt IS '긴급 여부';
COMMENT ON COLUMN data_rqst.aprvl_stat IS '승인 상태';
COMMENT ON COLUMN data_rqst.apprvr_id IS '승인자 ID (FK → usr_acnt)';
COMMENT ON COLUMN data_rqst.aprvd_at IS '승인 일시';
COMMENT ON COLUMN data_rqst.expir_at IS '만료 일시';
COMMENT ON COLUMN data_rqst.crtd_at IS '생성일시';
COMMENT ON COLUMN data_rqst.crtd_by IS '생성자 ID';
COMMENT ON COLUMN data_rqst.updtd_at IS '수정일시';
COMMENT ON COLUMN data_rqst.updtd_by IS '수정자 ID';

-- 4-8. rqst_atch (신청 첨부파일)
COMMENT ON TABLE rqst_atch IS '신청 첨부파일 — 데이터 신청 시 첨부 문서';
COMMENT ON COLUMN rqst_atch.atch_id IS '첨부 고유 ID';
COMMENT ON COLUMN rqst_atch.rqst_id IS '신청 ID (FK → data_rqst)';
COMMENT ON COLUMN rqst_atch.file_nm IS '파일명';
COMMENT ON COLUMN rqst_atch.file_path IS '파일 경로';
COMMENT ON COLUMN rqst_atch.file_size IS '파일 크기 (bytes)';
COMMENT ON COLUMN rqst_atch.mime_ty IS 'MIME 유형';
COMMENT ON COLUMN rqst_atch.crtd_at IS '생성일시';
COMMENT ON COLUMN rqst_atch.crtd_by IS '생성자 ID';
COMMENT ON COLUMN rqst_atch.updtd_at IS '수정일시';
COMMENT ON COLUMN rqst_atch.updtd_by IS '수정자 ID';

-- 4-9. rqst_tmln (신청 타임라인)
COMMENT ON TABLE rqst_tmln IS '신청 타임라인 — 데이터 신청 처리 과정 이력';
COMMENT ON COLUMN rqst_tmln.tmln_id IS '타임라인 고유 ID';
COMMENT ON COLUMN rqst_tmln.rqst_id IS '신청 ID (FK → data_rqst)';
COMMENT ON COLUMN rqst_tmln.actn_ty IS '액션 유형';
COMMENT ON COLUMN rqst_tmln.stat IS '처리 상태';
COMMENT ON COLUMN rqst_tmln.actr_usr_id IS '처리자 ID (FK → usr_acnt)';
COMMENT ON COLUMN rqst_tmln.cm IS '코멘트';
COMMENT ON COLUMN rqst_tmln.actn_dt IS '액션 일시';
COMMENT ON COLUMN rqst_tmln.crtd_at IS '생성일시';
COMMENT ON COLUMN rqst_tmln.crtd_by IS '생성자 ID';
COMMENT ON COLUMN rqst_tmln.updtd_at IS '수정일시';
COMMENT ON COLUMN rqst_tmln.updtd_by IS '수정자 ID';

-- 4-10. chart_cntnt (차트 콘텐츠)
COMMENT ON TABLE chart_cntnt IS '차트 콘텐츠 — 시각화 차트/대시보드 콘텐츠';
COMMENT ON COLUMN chart_cntnt.chart_id IS '차트 고유 ID';
COMMENT ON COLUMN chart_cntnt.chart_nm IS '차트명';
COMMENT ON COLUMN chart_cntnt.chart_ty IS '차트 유형 (bar/line/pie 등)';
COMMENT ON COLUMN chart_cntnt.dc IS '설명';
COMMENT ON COLUMN chart_cntnt.cnfg IS '차트 설정 (JSONB)';
COMMENT ON COLUMN chart_cntnt.data_src IS '데이터 소스';
COMMENT ON COLUMN chart_cntnt.thumb_url IS '썸네일 URL';
COMMENT ON COLUMN chart_cntnt.domn_id IS '도메인 ID (FK → domn)';
COMMENT ON COLUMN chart_cntnt.owner_usr_id IS '소유자 ID (FK → usr_acnt)';
COMMENT ON COLUMN chart_cntnt.is_public IS '공개 여부';
COMMENT ON COLUMN chart_cntnt.view_co IS '조회 수';
COMMENT ON COLUMN chart_cntnt.stat IS '상태';
COMMENT ON COLUMN chart_cntnt.crtd_at IS '생성일시';
COMMENT ON COLUMN chart_cntnt.crtd_by IS '생성자 ID';
COMMENT ON COLUMN chart_cntnt.updtd_at IS '수정일시';
COMMENT ON COLUMN chart_cntnt.updtd_by IS '수정자 ID';

-- 4-11. extn_prvsn (외부 제공)
COMMENT ON TABLE extn_prvsn IS '외부 제공 — 외부 기관에 대한 데이터 제공 관리';
COMMENT ON COLUMN extn_prvsn.prvsn_id IS '제공 고유 ID';
COMMENT ON COLUMN extn_prvsn.prvsn_nm IS '제공명';
COMMENT ON COLUMN extn_prvsn.trget_org IS '대상 기관';
COMMENT ON COLUMN extn_prvsn.dset_id IS '데이터셋 ID (FK → dset)';
COMMENT ON COLUMN extn_prvsn.product_id IS '상품 ID (FK → data_product)';
COMMENT ON COLUMN extn_prvsn.prvsn_ty IS '제공 유형';
COMMENT ON COLUMN extn_prvsn.freq IS '제공 주기';
COMMENT ON COLUMN extn_prvsn.rcrd_co IS '레코드 수';
COMMENT ON COLUMN extn_prvsn.last_prvdd IS '마지막 제공 일시';
COMMENT ON COLUMN extn_prvsn.cntrct_strt IS '계약 시작일';
COMMENT ON COLUMN extn_prvsn.cntrct_end IS '계약 종료일';
COMMENT ON COLUMN extn_prvsn.stat IS '상태';
COMMENT ON COLUMN extn_prvsn.crtd_at IS '생성일시';
COMMENT ON COLUMN extn_prvsn.crtd_by IS '생성자 ID';
COMMENT ON COLUMN extn_prvsn.updtd_at IS '수정일시';
COMMENT ON COLUMN extn_prvsn.updtd_by IS '수정자 ID';


-- ============================================================================
-- 5. 데이터 품질 도메인
-- ============================================================================

-- 5-1. dq_rule (품질 규칙)
COMMENT ON TABLE dq_rule IS '품질 규칙 — 데이터 품질 검증 규칙 정의';
COMMENT ON COLUMN dq_rule.rule_id IS '규칙 고유 ID';
COMMENT ON COLUMN dq_rule.rule_nm IS '규칙명';
COMMENT ON COLUMN dq_rule.rule_cd IS '규칙 코드';
COMMENT ON COLUMN dq_rule.rule_ty IS '규칙 유형 (완전성/정확성/일관성 등)';
COMMENT ON COLUMN dq_rule.dset_id IS '데이터셋 ID (FK → dset)';
COMMENT ON COLUMN dq_rule.col_nm IS '대상 컬럼명';
COMMENT ON COLUMN dq_rule.expr IS '검증 표현식';
COMMENT ON COLUMN dq_rule.thrhld IS '임계값 (%)';
COMMENT ON COLUMN dq_rule.svrt IS '심각도 (warning/critical)';
COMMENT ON COLUMN dq_rule.dc IS '설명';
COMMENT ON COLUMN dq_rule.is_actv IS '활성 여부';
COMMENT ON COLUMN dq_rule.crtd_at IS '생성일시';
COMMENT ON COLUMN dq_rule.crtd_by IS '생성자 ID (FK → usr_acnt)';
COMMENT ON COLUMN dq_rule.updtd_at IS '수정일시';
COMMENT ON COLUMN dq_rule.updtd_by IS '수정자 ID';

-- 5-2. dq_exec (품질 실행이력)
COMMENT ON TABLE dq_exec IS '품질 실행이력 — 품질 규칙 검증 실행 결과';
COMMENT ON COLUMN dq_exec.exec_id IS '실행 고유 ID';
COMMENT ON COLUMN dq_exec.rule_id IS '규칙 ID (FK → dq_rule)';
COMMENT ON COLUMN dq_exec.dset_id IS '데이터셋 ID (FK → dset)';
COMMENT ON COLUMN dq_exec.exec_dt IS '실행일';
COMMENT ON COLUMN dq_exec.tot_rows IS '총 행 수';
COMMENT ON COLUMN dq_exec.passd_rows IS '통과 행 수';
COMMENT ON COLUMN dq_exec.faild_rows IS '실패 행 수';
COMMENT ON COLUMN dq_exec.score IS '품질 점수 (%)';
COMMENT ON COLUMN dq_exec.rst IS '결과 (pass/fail/error/skip)';
COMMENT ON COLUMN dq_exec.err_msg IS '오류 메시지';
COMMENT ON COLUMN dq_exec.exec_tm_ms IS '실행 소요 시간 (ms)';
COMMENT ON COLUMN dq_exec.crtd_at IS '생성일시';
COMMENT ON COLUMN dq_exec.crtd_by IS '생성자 ID';
COMMENT ON COLUMN dq_exec.updtd_at IS '수정일시';
COMMENT ON COLUMN dq_exec.updtd_by IS '수정자 ID';

-- 5-3. domn_qlity_score (도메인 품질점수)
COMMENT ON TABLE domn_qlity_score IS '도메인 품질점수 — 도메인별 일자별 6차원 품질 점수';
COMMENT ON COLUMN domn_qlity_score.score_id IS '점수 고유 ID';
COMMENT ON COLUMN domn_qlity_score.domn_id IS '도메인 ID (FK → domn)';
COMMENT ON COLUMN domn_qlity_score.score_dt IS '점수 산정일';
COMMENT ON COLUMN domn_qlity_score.cmpltn IS '완전성 점수 (%)';
COMMENT ON COLUMN domn_qlity_score.accrcy IS '정확성 점수 (%)';
COMMENT ON COLUMN domn_qlity_score.cnstnc IS '일관성 점수 (%)';
COMMENT ON COLUMN domn_qlity_score.tmlns IS '적시성 점수 (%)';
COMMENT ON COLUMN domn_qlity_score.valid IS '유효성 점수 (%)';
COMMENT ON COLUMN domn_qlity_score.uqe IS '유일성 점수 (%)';
COMMENT ON COLUMN domn_qlity_score.ovrall_score IS '종합 점수 (%)';
COMMENT ON COLUMN domn_qlity_score.dset_co IS '데이터셋 수';
COMMENT ON COLUMN domn_qlity_score.rule_co IS '규칙 수';
COMMENT ON COLUMN domn_qlity_score.crtd_at IS '생성일시';
COMMENT ON COLUMN domn_qlity_score.crtd_by IS '생성자 ID';
COMMENT ON COLUMN domn_qlity_score.updtd_at IS '수정일시';
COMMENT ON COLUMN domn_qlity_score.updtd_by IS '수정자 ID';

-- 5-4. qlity_issue (품질 이슈)
COMMENT ON TABLE qlity_issue IS '품질 이슈 — 발견된 데이터 품질 문제 추적';
COMMENT ON COLUMN qlity_issue.issue_id IS '이슈 고유 ID';
COMMENT ON COLUMN qlity_issue.dset_id IS '데이터셋 ID (FK → dset)';
COMMENT ON COLUMN qlity_issue.rule_id IS '규칙 ID (FK → dq_rule)';
COMMENT ON COLUMN qlity_issue.issue_ty IS '이슈 유형';
COMMENT ON COLUMN qlity_issue.svrt IS '심각도 (warning/critical)';
COMMENT ON COLUMN qlity_issue.col_nm IS '대상 컬럼명';
COMMENT ON COLUMN qlity_issue.afctd_rows IS '영향받는 행 수';
COMMENT ON COLUMN qlity_issue.dc IS '설명';
COMMENT ON COLUMN qlity_issue.rsln IS '해결 방안';
COMMENT ON COLUMN qlity_issue.stat IS '상태 (open/investigating/resolved/ignored)';
COMMENT ON COLUMN qlity_issue.asgnd_to IS '담당자 ID (FK → usr_acnt)';
COMMENT ON COLUMN qlity_issue.rslvd_at IS '해결 일시';
COMMENT ON COLUMN qlity_issue.crtd_at IS '생성일시';
COMMENT ON COLUMN qlity_issue.crtd_by IS '생성자 ID';
COMMENT ON COLUMN qlity_issue.updtd_at IS '수정일시';
COMMENT ON COLUMN qlity_issue.updtd_by IS '수정자 ID';


-- ============================================================================
-- 6. 온톨로지 도메인
-- ============================================================================

-- 6-1. onto_class (온톨로지 클래스)
COMMENT ON TABLE onto_class IS '온톨로지 클래스 — 지식그래프 클래스(개념) 정의';
COMMENT ON COLUMN onto_class.class_id IS '클래스 고유 ID';
COMMENT ON COLUMN onto_class.class_nm_ko IS '클래스명 (한글)';
COMMENT ON COLUMN onto_class.class_nm_en IS '클래스명 (영문)';
COMMENT ON COLUMN onto_class.class_uri IS '클래스 URI';
COMMENT ON COLUMN onto_class.parent_class_id IS '부모 클래스 ID (자기참조)';
COMMENT ON COLUMN onto_class.dc IS '설명';
COMMENT ON COLUMN onto_class.instn_co IS '인스턴스 수';
COMMENT ON COLUMN onto_class.icon IS '아이콘 클래스';
COMMENT ON COLUMN onto_class.color IS '색상 (HEX)';
COMMENT ON COLUMN onto_class.sort_ord IS '정렬 순서';
COMMENT ON COLUMN onto_class.crtd_at IS '생성일시';
COMMENT ON COLUMN onto_class.crtd_by IS '생성자 ID';
COMMENT ON COLUMN onto_class.updtd_at IS '수정일시';
COMMENT ON COLUMN onto_class.updtd_by IS '수정자 ID';

-- 6-2. onto_data_prprty (온톨로지 데이터 속성)
COMMENT ON TABLE onto_data_prprty IS '온톨로지 데이터 속성 — 클래스의 데이터 속성 정의';
COMMENT ON COLUMN onto_data_prprty.prprty_id IS '속성 고유 ID';
COMMENT ON COLUMN onto_data_prprty.class_id IS '클래스 ID (FK → onto_class)';
COMMENT ON COLUMN onto_data_prprty.prprty_nm IS '속성명';
COMMENT ON COLUMN onto_data_prprty.prprty_uri IS '속성 URI';
COMMENT ON COLUMN onto_data_prprty.data_ty IS '데이터 유형';
COMMENT ON COLUMN onto_data_prprty.crdnlt IS '카디널리티 (1, 0..*, 등)';
COMMENT ON COLUMN onto_data_prprty.unit IS '단위';
COMMENT ON COLUMN onto_data_prprty.std_term_id IS '표준용어 ID (FK → glsry_term)';
COMMENT ON COLUMN onto_data_prprty.dc IS '설명';
COMMENT ON COLUMN onto_data_prprty.sort_ord IS '정렬 순서';
COMMENT ON COLUMN onto_data_prprty.crtd_at IS '생성일시';
COMMENT ON COLUMN onto_data_prprty.crtd_by IS '생성자 ID';
COMMENT ON COLUMN onto_data_prprty.updtd_at IS '수정일시';
COMMENT ON COLUMN onto_data_prprty.updtd_by IS '수정자 ID';

-- 6-3. onto_rel (온톨로지 관계)
COMMENT ON TABLE onto_rel IS '온톨로지 관계 — 클래스 간 관계(Object Property) 정의';
COMMENT ON COLUMN onto_rel.rel_id IS '관계 고유 ID';
COMMENT ON COLUMN onto_rel.src_class_id IS '원본 클래스 ID (FK → onto_class)';
COMMENT ON COLUMN onto_rel.trget_class_id IS '대상 클래스 ID (FK → onto_class)';
COMMENT ON COLUMN onto_rel.rel_nm_ko IS '관계명 (한글)';
COMMENT ON COLUMN onto_rel.rel_nm_en IS '관계명 (영문)';
COMMENT ON COLUMN onto_rel.rel_uri IS '관계 URI';
COMMENT ON COLUMN onto_rel.crdnlt IS '카디널리티';
COMMENT ON COLUMN onto_rel.drct IS '방향 (output/input/bidirectional)';
COMMENT ON COLUMN onto_rel.dc IS '설명';
COMMENT ON COLUMN onto_rel.sort_ord IS '정렬 순서';
COMMENT ON COLUMN onto_rel.crtd_at IS '생성일시';
COMMENT ON COLUMN onto_rel.crtd_by IS '생성자 ID';
COMMENT ON COLUMN onto_rel.updtd_at IS '수정일시';
COMMENT ON COLUMN onto_rel.updtd_by IS '수정자 ID';


-- ============================================================================
-- 7. 모니터링 도메인
-- ============================================================================

-- 7-1. regn (유역/권역)
COMMENT ON TABLE regn IS '유역/권역 — K-water 관할 유역 정보';
COMMENT ON COLUMN regn.regn_id IS '유역 고유 ID';
COMMENT ON COLUMN regn.regn_cd IS '유역 코드';
COMMENT ON COLUMN regn.regn_nm IS '유역명';
COMMENT ON COLUMN regn.sort_ord IS '정렬 순서';
COMMENT ON COLUMN regn.crtd_at IS '생성일시';
COMMENT ON COLUMN regn.crtd_by IS '생성자 ID';
COMMENT ON COLUMN regn.updtd_at IS '수정일시';
COMMENT ON COLUMN regn.updtd_by IS '수정자 ID';

-- 7-2. office (사업소)
COMMENT ON TABLE office IS '사업소 — K-water 지역 사업소 정보';
COMMENT ON COLUMN office.office_id IS '사업소 고유 ID';
COMMENT ON COLUMN office.regn_id IS '유역 ID (FK → regn)';
COMMENT ON COLUMN office.office_cd IS '사업소 코드';
COMMENT ON COLUMN office.office_nm IS '사업소명';
COMMENT ON COLUMN office.addr IS '주소';
COMMENT ON COLUMN office.sort_ord IS '정렬 순서';
COMMENT ON COLUMN office.crtd_at IS '생성일시';
COMMENT ON COLUMN office.crtd_by IS '생성자 ID';
COMMENT ON COLUMN office.updtd_at IS '수정일시';
COMMENT ON COLUMN office.updtd_by IS '수정자 ID';

-- 7-3. site (시설/현장)
COMMENT ON TABLE site IS '시설/현장 — 정수장/취수장 등 현장 시설 정보';
COMMENT ON COLUMN site.site_id IS '시설 고유 ID';
COMMENT ON COLUMN site.office_id IS '사업소 ID (FK → office)';
COMMENT ON COLUMN site.site_cd IS '시설 코드';
COMMENT ON COLUMN site.site_nm IS '시설명';
COMMENT ON COLUMN site.site_ty IS '시설 유형 (정수장/취수장 등)';
COMMENT ON COLUMN site.la IS '위도';
COMMENT ON COLUMN site.lngt IS '경도';
COMMENT ON COLUMN site.addr IS '주소';
COMMENT ON COLUMN site.cpcty IS '시설 용량';
COMMENT ON COLUMN site.stat IS '상태';
COMMENT ON COLUMN site.crtd_at IS '생성일시';
COMMENT ON COLUMN site.crtd_by IS '생성자 ID';
COMMENT ON COLUMN site.updtd_at IS '수정일시';
COMMENT ON COLUMN site.updtd_by IS '수정자 ID';

-- 7-4. sensor_tag (센서 태그)
COMMENT ON TABLE sensor_tag IS '센서 태그 — IoT 센서 측정점 정보';
COMMENT ON COLUMN sensor_tag.tag_id IS '센서태그 고유 ID';
COMMENT ON COLUMN sensor_tag.site_id IS '시설 ID (FK → site)';
COMMENT ON COLUMN sensor_tag.sensor_cd IS '센서 코드';
COMMENT ON COLUMN sensor_tag.sensor_nm IS '센서명';
COMMENT ON COLUMN sensor_tag.sensor_ty IS '센서 유형';
COMMENT ON COLUMN sensor_tag.unit IS '측정 단위';
COMMENT ON COLUMN sensor_tag.min_rng IS '측정 범위 최소값';
COMMENT ON COLUMN sensor_tag.max_rng IS '측정 범위 최대값';
COMMENT ON COLUMN sensor_tag.instl_dt IS '설치일';
COMMENT ON COLUMN sensor_tag.last_readng IS '마지막 측정값';
COMMENT ON COLUMN sensor_tag.last_read_at IS '마지막 측정 일시';
COMMENT ON COLUMN sensor_tag.stat IS '상태';
COMMENT ON COLUMN sensor_tag.crtd_at IS '생성일시';
COMMENT ON COLUMN sensor_tag.crtd_by IS '생성자 ID';
COMMENT ON COLUMN sensor_tag.updtd_at IS '수정일시';
COMMENT ON COLUMN sensor_tag.updtd_by IS '수정자 ID';

-- 7-5. asset_db (자산 DB)
COMMENT ON TABLE asset_db IS '자산 DB — 데이터베이스 자산 현황';
COMMENT ON COLUMN asset_db.asset_db_id IS '자산 고유 ID';
COMMENT ON COLUMN asset_db.asset_ty IS '자산 유형';
COMMENT ON COLUMN asset_db.asset_nm IS '자산명';
COMMENT ON COLUMN asset_db.tot_co IS '총 건수';
COMMENT ON COLUMN asset_db.actv_co IS '활성 건수';
COMMENT ON COLUMN asset_db.src_sys IS '원천 시스템';
COMMENT ON COLUMN asset_db.last_sync_at IS '마지막 동기화 일시';
COMMENT ON COLUMN asset_db.dc IS '설명';
COMMENT ON COLUMN asset_db.crtd_at IS '생성일시';
COMMENT ON COLUMN asset_db.crtd_by IS '생성자 ID';
COMMENT ON COLUMN asset_db.updtd_at IS '수정일시';
COMMENT ON COLUMN asset_db.updtd_by IS '수정자 ID';


-- ============================================================================
-- 8. 커뮤니티·소통 도메인
-- ============================================================================

-- 8-1. board_post (게시글)
COMMENT ON TABLE board_post IS '게시글 — 커뮤니티 게시판 글';
COMMENT ON COLUMN board_post.post_id IS '게시글 고유 ID';
COMMENT ON COLUMN board_post.usr_id IS '작성자 ID (FK → usr_acnt)';
COMMENT ON COLUMN board_post.tit IS '제목';
COMMENT ON COLUMN board_post.cntnt IS '내용';
COMMENT ON COLUMN board_post.post_ty IS '게시판 유형 (notice/internal/external)';
COMMENT ON COLUMN board_post.is_pinnd IS '고정 여부';
COMMENT ON COLUMN board_post.view_co IS '조회 수';
COMMENT ON COLUMN board_post.like_co IS '좋아요 수';
COMMENT ON COLUMN board_post.cm_co IS '댓글 수';
COMMENT ON COLUMN board_post.stat IS '상태';
COMMENT ON COLUMN board_post.crtd_at IS '생성일시';
COMMENT ON COLUMN board_post.crtd_by IS '생성자 ID';
COMMENT ON COLUMN board_post.updtd_at IS '수정일시';
COMMENT ON COLUMN board_post.updtd_by IS '수정자 ID';

-- 8-2. board_cm (댓글)
COMMENT ON TABLE board_cm IS '댓글 — 게시글 댓글 (대댓글 지원)';
COMMENT ON COLUMN board_cm.cm_id IS '댓글 고유 ID';
COMMENT ON COLUMN board_cm.post_id IS '게시글 ID (FK → board_post)';
COMMENT ON COLUMN board_cm.usr_id IS '작성자 ID (FK → usr_acnt)';
COMMENT ON COLUMN board_cm.parent_id IS '부모 댓글 ID (자기참조, 대댓글)';
COMMENT ON COLUMN board_cm.cm_text IS '댓글 내용';
COMMENT ON COLUMN board_cm.stat IS '상태';
COMMENT ON COLUMN board_cm.crtd_at IS '생성일시';
COMMENT ON COLUMN board_cm.crtd_by IS '생성자 ID';
COMMENT ON COLUMN board_cm.updtd_at IS '수정일시';
COMMENT ON COLUMN board_cm.updtd_by IS '수정자 ID';

-- 8-3. resrce_archv (자료실)
COMMENT ON TABLE resrce_archv IS '자료실 — 공유 문서/자료 파일 관리';
COMMENT ON COLUMN resrce_archv.resrce_id IS '자료 고유 ID';
COMMENT ON COLUMN resrce_archv.usr_id IS '등록자 ID (FK → usr_acnt)';
COMMENT ON COLUMN resrce_archv.resrce_nm IS '자료명';
COMMENT ON COLUMN resrce_archv.dc IS '설명';
COMMENT ON COLUMN resrce_archv.file_nm IS '파일명';
COMMENT ON COLUMN resrce_archv.file_path IS '파일 경로';
COMMENT ON COLUMN resrce_archv.file_size IS '파일 크기 (bytes)';
COMMENT ON COLUMN resrce_archv.mime_ty IS 'MIME 유형';
COMMENT ON COLUMN resrce_archv.ctgry IS '카테고리';
COMMENT ON COLUMN resrce_archv.dwld_co IS '다운로드 수';
COMMENT ON COLUMN resrce_archv.stat IS '상태';
COMMENT ON COLUMN resrce_archv.crtd_at IS '생성일시';
COMMENT ON COLUMN resrce_archv.crtd_by IS '생성자 ID';
COMMENT ON COLUMN resrce_archv.updtd_at IS '수정일시';
COMMENT ON COLUMN resrce_archv.updtd_by IS '수정자 ID';


-- ============================================================================
-- 9. 시스템 관리 도메인
-- ============================================================================

-- 9-1. scrty_polcy (보안 정책)
COMMENT ON TABLE scrty_polcy IS '보안 정책 — 데이터 보안 정책 정의';
COMMENT ON COLUMN scrty_polcy.polcy_id IS '정책 고유 ID';
COMMENT ON COLUMN scrty_polcy.polcy_nm IS '정책명';
COMMENT ON COLUMN scrty_polcy.polcy_ty IS '정책 유형';
COMMENT ON COLUMN scrty_polcy.dc IS '설명';
COMMENT ON COLUMN scrty_polcy.rule_cnfg IS '규칙 설정 (JSONB)';
COMMENT ON COLUMN scrty_polcy.trget_lvl IS '대상 보안 등급';
COMMENT ON COLUMN scrty_polcy.is_actv IS '활성 여부';
COMMENT ON COLUMN scrty_polcy.eftv_from IS '시행 시작일';
COMMENT ON COLUMN scrty_polcy.eftv_to IS '시행 종료일';
COMMENT ON COLUMN scrty_polcy.crtd_at IS '생성일시';
COMMENT ON COLUMN scrty_polcy.crtd_by IS '생성자 ID (FK → usr_acnt)';
COMMENT ON COLUMN scrty_polcy.updtd_at IS '수정일시';
COMMENT ON COLUMN scrty_polcy.updtd_by IS '수정자 ID';

-- 9-2. sys_intrfc (시스템 인터페이스)
COMMENT ON TABLE sys_intrfc IS '시스템 인터페이스 — 시스템 간 인터페이스 정의';
COMMENT ON COLUMN sys_intrfc.intrfc_id IS '인터페이스 고유 ID';
COMMENT ON COLUMN sys_intrfc.intrfc_cd IS '인터페이스 코드';
COMMENT ON COLUMN sys_intrfc.intrfc_nm IS '인터페이스명';
COMMENT ON COLUMN sys_intrfc.src_sys_id IS '원천 시스템 ID (FK → src_sys)';
COMMENT ON COLUMN sys_intrfc.trget_sys_id IS '대상 시스템 ID (FK → src_sys)';
COMMENT ON COLUMN sys_intrfc.intrfc_ty IS '인터페이스 유형';
COMMENT ON COLUMN sys_intrfc.prtcl IS '프로토콜';
COMMENT ON COLUMN sys_intrfc.freq IS '연동 주기';
COMMENT ON COLUMN sys_intrfc.drct IS '방향 (inbound/outbound/bidirectional)';
COMMENT ON COLUMN sys_intrfc.last_succes_at IS '마지막 성공 일시';
COMMENT ON COLUMN sys_intrfc.last_fail_at IS '마지막 실패 일시';
COMMENT ON COLUMN sys_intrfc.succes_rt IS '성공률 (%)';
COMMENT ON COLUMN sys_intrfc.avg_rspns_ms IS '평균 응답 시간 (ms)';
COMMENT ON COLUMN sys_intrfc.stat IS '상태';
COMMENT ON COLUMN sys_intrfc.crtd_at IS '생성일시';
COMMENT ON COLUMN sys_intrfc.crtd_by IS '생성자 ID';
COMMENT ON COLUMN sys_intrfc.updtd_at IS '수정일시';
COMMENT ON COLUMN sys_intrfc.updtd_by IS '수정자 ID';

-- 9-3. audit_log (감사 로그)
COMMENT ON TABLE audit_log IS '감사 로그 — 사용자 활동 감사 기록';
COMMENT ON COLUMN audit_log.log_id IS '로그 고유 ID';
COMMENT ON COLUMN audit_log.usr_id IS '사용자 ID (FK → usr_acnt)';
COMMENT ON COLUMN audit_log.usr_nm IS '사용자명';
COMMENT ON COLUMN audit_log.actn_ty IS '활동 유형';
COMMENT ON COLUMN audit_log.trget_table IS '대상 테이블';
COMMENT ON COLUMN audit_log.trget_id IS '대상 레코드 ID';
COMMENT ON COLUMN audit_log.actn_dtl IS '활동 상세';
COMMENT ON COLUMN audit_log.ip_addr IS 'IP 주소';
COMMENT ON COLUMN audit_log.usr_agent IS 'User-Agent';
COMMENT ON COLUMN audit_log.rst IS '결과 (success/fail/denied)';
COMMENT ON COLUMN audit_log.crtd_at IS '생성일시';
COMMENT ON COLUMN audit_log.crtd_by IS '생성자 ID';
COMMENT ON COLUMN audit_log.updtd_at IS '수정일시';
COMMENT ON COLUMN audit_log.updtd_by IS '수정자 ID';

-- 9-4. ntcn (알림)
COMMENT ON TABLE ntcn IS '알림 — 사용자 알림 메시지';
COMMENT ON COLUMN ntcn.ntcn_id IS '알림 고유 ID';
COMMENT ON COLUMN ntcn.usr_id IS '수신자 ID (FK → usr_acnt)';
COMMENT ON COLUMN ntcn.ntcn_ty IS '알림 유형 (system/approval/quality/security/pipeline)';
COMMENT ON COLUMN ntcn.tit IS '알림 제목';
COMMENT ON COLUMN ntcn.msg IS '알림 내용';
COMMENT ON COLUMN ntcn.link_url IS '연결 URL';
COMMENT ON COLUMN ntcn.is_read IS '읽음 여부';
COMMENT ON COLUMN ntcn.read_at IS '읽은 일시';
COMMENT ON COLUMN ntcn.crtd_at IS '생성일시';
COMMENT ON COLUMN ntcn.crtd_by IS '생성자 ID';
COMMENT ON COLUMN ntcn.updtd_at IS '수정일시';
COMMENT ON COLUMN ntcn.updtd_by IS '수정자 ID';

-- 9-5. widg_tmplat (위젯 템플릿)
COMMENT ON TABLE widg_tmplat IS '위젯 템플릿 — 대시보드 위젯 템플릿 정의';
COMMENT ON COLUMN widg_tmplat.widg_id IS '위젯 고유 ID';
COMMENT ON COLUMN widg_tmplat.widg_cd IS '위젯 코드';
COMMENT ON COLUMN widg_tmplat.widg_nm IS '위젯명';
COMMENT ON COLUMN widg_tmplat.widg_ty IS '위젯 유형';
COMMENT ON COLUMN widg_tmplat.dc IS '설명';
COMMENT ON COLUMN widg_tmplat.cnfg_json IS '설정 (JSONB)';
COMMENT ON COLUMN widg_tmplat.thumb_url IS '썸네일 URL';
COMMENT ON COLUMN widg_tmplat.min_width IS '최소 너비';
COMMENT ON COLUMN widg_tmplat.min_hg IS '최소 높이';
COMMENT ON COLUMN widg_tmplat.max_width IS '최대 너비';
COMMENT ON COLUMN widg_tmplat.max_hg IS '최대 높이';
COMMENT ON COLUMN widg_tmplat.ctgry IS '카테고리';
COMMENT ON COLUMN widg_tmplat.is_actv IS '활성 여부';
COMMENT ON COLUMN widg_tmplat.crtd_at IS '생성일시';
COMMENT ON COLUMN widg_tmplat.crtd_by IS '생성자 ID';
COMMENT ON COLUMN widg_tmplat.updtd_at IS '수정일시';
COMMENT ON COLUMN widg_tmplat.updtd_by IS '수정자 ID';

-- 9-6. usr_widg_layout (사용자 위젯 레이아웃)
COMMENT ON TABLE usr_widg_layout IS '사용자 위젯 레이아웃 — 사용자별 대시보드 위젯 배치';
COMMENT ON COLUMN usr_widg_layout.layout_id IS '레이아웃 고유 ID';
COMMENT ON COLUMN usr_widg_layout.usr_id IS '사용자 ID (FK → usr_acnt)';
COMMENT ON COLUMN usr_widg_layout.widg_id IS '위젯 ID (FK → widg_tmplat)';
COMMENT ON COLUMN usr_widg_layout.positn_x IS 'X 좌표';
COMMENT ON COLUMN usr_widg_layout.positn_y IS 'Y 좌표';
COMMENT ON COLUMN usr_widg_layout.width IS '너비';
COMMENT ON COLUMN usr_widg_layout.hg IS '높이';
COMMENT ON COLUMN usr_widg_layout.cnfg_ovrd IS '사용자 설정 오버라이드 (JSONB)';
COMMENT ON COLUMN usr_widg_layout.is_vsbl IS '표시 여부';
COMMENT ON COLUMN usr_widg_layout.sort_ord IS '정렬 순서';
COMMENT ON COLUMN usr_widg_layout.crtd_at IS '생성일시';
COMMENT ON COLUMN usr_widg_layout.crtd_by IS '생성자 ID';
COMMENT ON COLUMN usr_widg_layout.updtd_at IS '수정일시';
COMMENT ON COLUMN usr_widg_layout.updtd_by IS '수정자 ID';

-- 9-7. lnage_node (리니지 노드)
COMMENT ON TABLE lnage_node IS '리니지 노드 — 데이터 리니지 그래프의 노드';
COMMENT ON COLUMN lnage_node.node_id IS '노드 고유 ID';
COMMENT ON COLUMN lnage_node.node_ty IS '노드 유형 (dataset/table/column/pipeline/system/product)';
COMMENT ON COLUMN lnage_node.obj_id IS '대상 객체 ID';
COMMENT ON COLUMN lnage_node.obj_nm IS '대상 객체명';
COMMENT ON COLUMN lnage_node.dc IS '설명';
COMMENT ON COLUMN lnage_node.mtdata IS '메타데이터 (JSONB)';
COMMENT ON COLUMN lnage_node.crtd_at IS '생성일시';
COMMENT ON COLUMN lnage_node.crtd_by IS '생성자 ID';
COMMENT ON COLUMN lnage_node.updtd_at IS '수정일시';
COMMENT ON COLUMN lnage_node.updtd_by IS '수정자 ID';

-- 9-8. lnage_edge (리니지 엣지)
COMMENT ON TABLE lnage_edge IS '리니지 엣지 — 데이터 리니지 그래프의 관계선';
COMMENT ON COLUMN lnage_edge.edge_id IS '엣지 고유 ID';
COMMENT ON COLUMN lnage_edge.src_node_id IS '원본 노드 ID (FK → lnage_node)';
COMMENT ON COLUMN lnage_edge.trget_node_id IS '대상 노드 ID (FK → lnage_node)';
COMMENT ON COLUMN lnage_edge.edge_ty IS '엣지 유형 (transform 등)';
COMMENT ON COLUMN lnage_edge.trsfmn IS '변환 로직';
COMMENT ON COLUMN lnage_edge.ppln_id IS '파이프라인 ID (FK → ppln)';
COMMENT ON COLUMN lnage_edge.crtd_at IS '생성일시';
COMMENT ON COLUMN lnage_edge.crtd_by IS '생성자 ID';
COMMENT ON COLUMN lnage_edge.updtd_at IS '수정일시';
COMMENT ON COLUMN lnage_edge.updtd_by IS '수정자 ID';

-- 9-9. ai_chat_sesn (AI 채팅 세션)
COMMENT ON TABLE ai_chat_sesn IS 'AI 채팅 세션 — 생성형 AI 대화 세션';
COMMENT ON COLUMN ai_chat_sesn.sesn_id IS '세션 고유 ID (UUID)';
COMMENT ON COLUMN ai_chat_sesn.usr_id IS '사용자 ID (FK → usr_acnt)';
COMMENT ON COLUMN ai_chat_sesn.sesn_tit IS '세션 제목';
COMMENT ON COLUMN ai_chat_sesn.model_nm IS 'AI 모델명';
COMMENT ON COLUMN ai_chat_sesn.msg_co IS '메시지 수';
COMMENT ON COLUMN ai_chat_sesn.is_archvd IS '보관 여부';
COMMENT ON COLUMN ai_chat_sesn.crtd_at IS '생성일시';
COMMENT ON COLUMN ai_chat_sesn.crtd_by IS '생성자 ID';
COMMENT ON COLUMN ai_chat_sesn.updtd_at IS '수정일시';
COMMENT ON COLUMN ai_chat_sesn.updtd_by IS '수정자 ID';

-- 9-10. ai_chat_msg (AI 채팅 메시지)
COMMENT ON TABLE ai_chat_msg IS 'AI 채팅 메시지 — 개별 대화 메시지';
COMMENT ON COLUMN ai_chat_msg.msg_id IS '메시지 고유 ID';
COMMENT ON COLUMN ai_chat_msg.sesn_id IS '세션 ID (FK → ai_chat_sesn)';
COMMENT ON COLUMN ai_chat_msg.role IS '역할 (user/assistant/system)';
COMMENT ON COLUMN ai_chat_msg.msg_text IS '메시지 내용';
COMMENT ON COLUMN ai_chat_msg.tkns_used IS '사용 토큰 수';
COMMENT ON COLUMN ai_chat_msg.rspns_ms IS '응답 시간 (ms)';
COMMENT ON COLUMN ai_chat_msg.mtdata IS '메타데이터 (JSONB)';
COMMENT ON COLUMN ai_chat_msg.crtd_at IS '생성일시';
COMMENT ON COLUMN ai_chat_msg.crtd_by IS '생성자 ID';
COMMENT ON COLUMN ai_chat_msg.updtd_at IS '수정일시';
COMMENT ON COLUMN ai_chat_msg.updtd_by IS '수정자 ID';

-- 9-11. daly_dist_stats (일별 유통 통계)
COMMENT ON TABLE daly_dist_stats IS '일별 유통 통계 — 데이터 상품 일별 호출/사용 통계';
COMMENT ON COLUMN daly_dist_stats.stat_id IS '통계 고유 ID';
COMMENT ON COLUMN daly_dist_stats.stat_dt IS '통계 일자';
COMMENT ON COLUMN daly_dist_stats.product_id IS '상품 ID (FK → data_product)';
COMMENT ON COLUMN daly_dist_stats.tot_calls IS '총 호출 수';
COMMENT ON COLUMN daly_dist_stats.succes_calls IS '성공 호출 수';
COMMENT ON COLUMN daly_dist_stats.fail_calls IS '실패 호출 수';
COMMENT ON COLUMN daly_dist_stats.avg_rspns_ms IS '평균 응답 시간 (ms)';
COMMENT ON COLUMN daly_dist_stats.unique_usrs IS '고유 사용자 수';
COMMENT ON COLUMN daly_dist_stats.data_vlm_mb IS '데이터 전송량 (MB)';
COMMENT ON COLUMN daly_dist_stats.crtd_at IS '생성일시';
COMMENT ON COLUMN daly_dist_stats.crtd_by IS '생성자 ID';
COMMENT ON COLUMN daly_dist_stats.updtd_at IS '수정일시';
COMMENT ON COLUMN daly_dist_stats.updtd_by IS '수정자 ID';

-- 9-12. dept_usg_stats (부서별 사용 통계)
COMMENT ON TABLE dept_usg_stats IS '부서별 사용 통계 — 부서 단위 데이터 활용 통계';
COMMENT ON COLUMN dept_usg_stats.stat_id IS '통계 고유 ID';
COMMENT ON COLUMN dept_usg_stats.stat_dt IS '통계 일자';
COMMENT ON COLUMN dept_usg_stats.dept_id IS '부서 ID (FK → dept)';
COMMENT ON COLUMN dept_usg_stats.dset_co IS '데이터셋 수';
COMMENT ON COLUMN dept_usg_stats.api_calls IS 'API 호출 수';
COMMENT ON COLUMN dept_usg_stats.dwld_co IS '다운로드 수';
COMMENT ON COLUMN dept_usg_stats.search_co IS '검색 수';
COMMENT ON COLUMN dept_usg_stats.actv_usrs IS '활성 사용자 수';
COMMENT ON COLUMN dept_usg_stats.crtd_at IS '생성일시';
COMMENT ON COLUMN dept_usg_stats.crtd_by IS '생성자 ID';
COMMENT ON COLUMN dept_usg_stats.updtd_at IS '수정일시';
COMMENT ON COLUMN dept_usg_stats.updtd_by IS '수정자 ID';

-- 9-13. erp_sync_hist (ERP 동기화 이력)
COMMENT ON TABLE erp_sync_hist IS 'ERP 동기화 이력 — ERP/SAP 연동 동기화 기록';
COMMENT ON COLUMN erp_sync_hist.sync_id IS '동기화 고유 ID';
COMMENT ON COLUMN erp_sync_hist.sync_ty IS '동기화 유형';
COMMENT ON COLUMN erp_sync_hist.sync_drct IS '동기화 방향 (inbound/outbound)';
COMMENT ON COLUMN erp_sync_hist.tot_rcrds IS '총 레코드 수';
COMMENT ON COLUMN erp_sync_hist.crtd_co IS '생성 건수';
COMMENT ON COLUMN erp_sync_hist.updtd_co IS '수정 건수';
COMMENT ON COLUMN erp_sync_hist.skipd_co IS '건너뜀 건수';
COMMENT ON COLUMN erp_sync_hist.err_co IS '오류 건수';
COMMENT ON COLUMN erp_sync_hist.strtd_at IS '시작 일시';
COMMENT ON COLUMN erp_sync_hist.fnshed_at IS '종료 일시';
COMMENT ON COLUMN erp_sync_hist.stat IS '상태 (running/success/failed/cancelled)';
COMMENT ON COLUMN erp_sync_hist.err_dtl IS '오류 상세';
COMMENT ON COLUMN erp_sync_hist.crtd_at IS '생성일시';
COMMENT ON COLUMN erp_sync_hist.crtd_by IS '생성자 ID';
COMMENT ON COLUMN erp_sync_hist.updtd_at IS '수정일시';
COMMENT ON COLUMN erp_sync_hist.updtd_by IS '수정자 ID';


-- ============================================================================
-- 10. K-water 데이터표준 사전 (public 스키마)
-- ============================================================================

-- 10-1. std_word (표준단어사전)
COMMENT ON TABLE std_word IS '표준단어사전 — K-water 데이터관리포탈 기준';
COMMENT ON COLUMN std_word.word_id IS '단어 고유 ID';
COMMENT ON COLUMN std_word.lgc_nm IS '논리명 (한글)';
COMMENT ON COLUMN std_word.phys_nm IS '물리명 (영문약어)';
COMMENT ON COLUMN std_word.phys_mean IS '물리의미 (영문풀네임)';
COMMENT ON COLUMN std_word.attr_cls IS '속성분류어 여부 (Y/N)';
COMMENT ON COLUMN std_word.synm IS '동의어';
COMMENT ON COLUMN std_word.dc IS '설명';
COMMENT ON COLUMN std_word.crtd_at IS '생성일시';
COMMENT ON COLUMN std_word.crtd_by IS '생성자 ID';
COMMENT ON COLUMN std_word.updtd_at IS '수정일시';
COMMENT ON COLUMN std_word.updtd_by IS '수정자 ID';

-- 10-2. std_domn_dict (표준도메인사전)
COMMENT ON TABLE std_domn_dict IS '표준도메인사전 — K-water 데이터관리포탈 기준';
COMMENT ON COLUMN std_domn_dict.std_domn_id IS '도메인 고유 ID';
COMMENT ON COLUMN std_domn_dict.domn_grp_nm IS '도메인그룹명';
COMMENT ON COLUMN std_domn_dict.domn_nm IS '도메인명';
COMMENT ON COLUMN std_domn_dict.domn_lgc_nm IS '도메인논리명';
COMMENT ON COLUMN std_domn_dict.data_ty IS '데이터유형 (NUMERIC/VARCHAR 등)';
COMMENT ON COLUMN std_domn_dict.data_len IS '길이';
COMMENT ON COLUMN std_domn_dict.deci_point IS '소수점 자리수';
COMMENT ON COLUMN std_domn_dict.psnl_info_yn IS '개인정보 여부';
COMMENT ON COLUMN std_domn_dict.enc_yn IS '암호화 여부';
COMMENT ON COLUMN std_domn_dict.scrbl IS '스크램블 유형';
COMMENT ON COLUMN std_domn_dict.dc IS '설명';
COMMENT ON COLUMN std_domn_dict.crtd_at IS '생성일시';
COMMENT ON COLUMN std_domn_dict.crtd_by IS '생성자 ID';
COMMENT ON COLUMN std_domn_dict.updtd_at IS '수정일시';
COMMENT ON COLUMN std_domn_dict.updtd_by IS '수정자 ID';

-- 10-3. std_term (표준용어사전)
COMMENT ON TABLE std_term IS '표준용어사전 — K-water 데이터관리포탈 기준';
COMMENT ON COLUMN std_term.std_term_id IS '용어 고유 ID';
COMMENT ON COLUMN std_term.lgc_nm IS '논리명 (한글)';
COMMENT ON COLUMN std_term.phys_nm IS '물리명 (영문약어 조합)';
COMMENT ON COLUMN std_term.eng_mean IS '영문의미';
COMMENT ON COLUMN std_term.domn_lgc_nm IS '도메인논리명';
COMMENT ON COLUMN std_term.domn_lgc_abbr IS '도메인논리약어';
COMMENT ON COLUMN std_term.domn_grp IS '도메인그룹';
COMMENT ON COLUMN std_term.data_ty IS '데이터유형';
COMMENT ON COLUMN std_term.data_len IS '길이';
COMMENT ON COLUMN std_term.deci_point IS '소수점 자리수';
COMMENT ON COLUMN std_term.psnl_info_yn IS '개인정보 여부';
COMMENT ON COLUMN std_term.enc_yn IS '암호화 여부';
COMMENT ON COLUMN std_term.scrbl IS '스크램블 유형';
COMMENT ON COLUMN std_term.dc IS '설명';
COMMENT ON COLUMN std_term.crtd_at IS '생성일시';
COMMENT ON COLUMN std_term.crtd_by IS '생성자 ID';
COMMENT ON COLUMN std_term.updtd_at IS '수정일시';
COMMENT ON COLUMN std_term.updtd_by IS '수정자 ID';

-- 10-4. std_cd_grp (표준코드그룹사전)
COMMENT ON TABLE std_cd_grp IS '표준코드그룹사전 — K-water 데이터관리포탈 기준';
COMMENT ON COLUMN std_cd_grp.std_cd_grp_id IS '코드그룹 고유 ID';
COMMENT ON COLUMN std_cd_grp.sys_grp IS '코드그룹 시스템구분 (ADT/SCM 등)';
COMMENT ON COLUMN std_cd_grp.lgc_nm IS '논리명';
COMMENT ON COLUMN std_cd_grp.phys_nm IS '물리명';
COMMENT ON COLUMN std_cd_grp.cd_desc IS '코드 설명';
COMMENT ON COLUMN std_cd_grp.cd_cls IS '코드구분 (공통코드 등)';
COMMENT ON COLUMN std_cd_grp.cd_len IS '길이';
COMMENT ON COLUMN std_cd_grp.cd_id IS '코드 ID (원본 키)';
COMMENT ON COLUMN std_cd_grp.crtd_at IS '생성일시';
COMMENT ON COLUMN std_cd_grp.crtd_by IS '생성자 ID';
COMMENT ON COLUMN std_cd_grp.updtd_at IS '수정일시';
COMMENT ON COLUMN std_cd_grp.updtd_by IS '수정자 ID';

-- 10-5. std_cd (표준코드사전)
COMMENT ON TABLE std_cd IS '표준코드사전 — K-water 데이터관리포탈 기준';
COMMENT ON COLUMN std_cd.std_cd_id IS '코드 고유 ID';
COMMENT ON COLUMN std_cd.std_cd_grp_id IS '코드그룹 ID (FK → std_cd_grp)';
COMMENT ON COLUMN std_cd.cd_val IS '코드값';
COMMENT ON COLUMN std_cd.cd_val_nm IS '코드값명';
COMMENT ON COLUMN std_cd.sort_ord IS '정렬 순서';
COMMENT ON COLUMN std_cd.prnt_cd_nm IS '부모 코드명';
COMMENT ON COLUMN std_cd.prnt_cd_val IS '부모 코드값';
COMMENT ON COLUMN std_cd.dc IS '설명';
COMMENT ON COLUMN std_cd.aply_bgn_dt IS '적용 시작일';
COMMENT ON COLUMN std_cd.aply_end_dt IS '적용 종료일';
COMMENT ON COLUMN std_cd.crtd_at IS '생성일시';
COMMENT ON COLUMN std_cd.crtd_by IS '생성자 ID';
COMMENT ON COLUMN std_cd.updtd_at IS '수정일시';
COMMENT ON COLUMN std_cd.updtd_by IS '수정자 ID';

