/*
 * ============================================================================
 *  K-water DataHub Portal — 테이블/컬럼 COMMENT 정의
 * ============================================================================
 *  portal_schm.sql의 모든 68개 테이블 · 전체 컬럼에 대한 한글 코멘트
 *  작성일: 2026-03-11
 * ============================================================================
 */

-- ============================================================================
-- 1. 사용자·조직·권한
-- ============================================================================

-- divs
COMMENT ON TABLE  divs IS '본부/권역 조직 (경영관리본부, 한강권역본부 등)';
COMMENT ON COLUMN divs.divs_id IS '본부 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN divs.divs_cd IS '조직코드 (예: DIV_HQ, DIV_HAN)';
COMMENT ON COLUMN divs.divs_nm IS '조직명 (한글)';
COMMENT ON COLUMN divs.sort_ord IS '정렬 순서';
COMMENT ON COLUMN divs.is_actv IS '활성 여부';
COMMENT ON COLUMN divs.crtd_at IS '등록일시';
COMMENT ON COLUMN divs.crtd_by IS '등록자 ID (usr_acnt.usr_id)';
COMMENT ON COLUMN divs.updtd_at IS '수정일시';
COMMENT ON COLUMN divs.updtd_by IS '수정자 ID (usr_acnt.usr_id)';

-- dept
COMMENT ON TABLE  dept IS '부서/팀 조직';
COMMENT ON COLUMN dept.dept_id IS '부서 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN dept.divs_id IS '소속 본부 FK → divs';
COMMENT ON COLUMN dept.dept_cd IS '부서코드 (유니크)';
COMMENT ON COLUMN dept.dept_nm IS '부서명 (한글)';
COMMENT ON COLUMN dept.hdcnt IS '정원 수';
COMMENT ON COLUMN dept.sort_ord IS '정렬 순서';
COMMENT ON COLUMN dept.is_actv IS '활성 여부';
COMMENT ON COLUMN dept.crtd_at IS '등록일시';
COMMENT ON COLUMN dept.crtd_by IS '등록자 ID';
COMMENT ON COLUMN dept.updtd_at IS '수정일시';
COMMENT ON COLUMN dept.updtd_by IS '수정자 ID';

-- role
COMMENT ON TABLE  role IS '역할 정의 (RBAC)';
COMMENT ON COLUMN role.role_id IS '역할 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN role.role_cd IS '역할코드 (STAFF_USER, ADM_SUPER 등)';
COMMENT ON COLUMN role.role_nm IS '역할명 (한글)';
COMMENT ON COLUMN role.role_grp IS '역할 그룹: 수공직원/협력직원/데이터엔지니어/관리자';
COMMENT ON COLUMN role.role_lvl IS '역할 수준 (0=게스트 ~ 6=슈퍼관리자)';
COMMENT ON COLUMN role.data_clrnc IS '데이터 열람등급 (1=공개 ~ 4=기밀)';
COMMENT ON COLUMN role.dc IS '역할 설명';
COMMENT ON COLUMN role.is_actv IS '활성 여부';
COMMENT ON COLUMN role.crtd_at IS '등록일시';
COMMENT ON COLUMN role.crtd_by IS '등록자 ID';
COMMENT ON COLUMN role.updtd_at IS '수정일시';
COMMENT ON COLUMN role.updtd_by IS '수정자 ID';

-- usr_acnt
COMMENT ON TABLE  usr_acnt IS '사용자 계정';
COMMENT ON COLUMN usr_acnt.usr_id IS '사용자 고유 ID (PK, UUID)';
COMMENT ON COLUMN usr_acnt.login_id IS '로그인 ID (유니크)';
COMMENT ON COLUMN usr_acnt.usr_nm IS '사용자명 (한글)';
COMMENT ON COLUMN usr_acnt.email IS '이메일 주소';
COMMENT ON COLUMN usr_acnt.phone IS '전화번호';
COMMENT ON COLUMN usr_acnt.dept_id IS '소속 부서 FK → dept';
COMMENT ON COLUMN usr_acnt.role_id IS '역할 FK → role';
COMMENT ON COLUMN usr_acnt.login_ty IS '로그인 유형: sso/partner/engineer/admin';
COMMENT ON COLUMN usr_acnt.stat IS '계정 상태: active/inactive/pending/locked/deprecated';
COMMENT ON COLUMN usr_acnt.last_login_at IS '최종 로그인 일시';
COMMENT ON COLUMN usr_acnt.pwd_hash IS '비밀번호 해시 (SSO 사용자는 NULL)';
COMMENT ON COLUMN usr_acnt.pfile_img IS '프로필 이미지 URL';
COMMENT ON COLUMN usr_acnt.crtd_at IS '등록일시';
COMMENT ON COLUMN usr_acnt.crtd_by IS '등록자 ID';
COMMENT ON COLUMN usr_acnt.updtd_at IS '수정일시';
COMMENT ON COLUMN usr_acnt.updtd_by IS '수정자 ID';

-- menu
COMMENT ON TABLE  menu IS '메뉴/화면 정의 (사이드바 IA)';
COMMENT ON COLUMN menu.menu_id IS '메뉴 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN menu.menu_cd IS '메뉴코드 (유니크)';
COMMENT ON COLUMN menu.menu_nm IS '메뉴명 (한글)';
COMMENT ON COLUMN menu.parent_cd IS '상위 메뉴코드 FK → menu (자기참조)';
COMMENT ON COLUMN menu.sctn IS '상위 섹션: dashboard/catalog/collect/distribute/meta/community/system';
COMMENT ON COLUMN menu.scrin_id IS 'HTML screen div ID (navigate 함수 대상)';
COMMENT ON COLUMN menu.icon IS '아이콘 클래스명';
COMMENT ON COLUMN menu.sort_ord IS '정렬 순서';
COMMENT ON COLUMN menu.is_actv IS '활성 여부';
COMMENT ON COLUMN menu.crtd_at IS '등록일시';
COMMENT ON COLUMN menu.crtd_by IS '등록자 ID';
COMMENT ON COLUMN menu.updtd_at IS '수정일시';
COMMENT ON COLUMN menu.updtd_by IS '수정자 ID';

-- role_menu_perm
COMMENT ON TABLE  role_menu_perm IS '역할별 메뉴 권한 매트릭스 (RBAC)';
COMMENT ON COLUMN role_menu_perm.role_id IS '역할 FK → role';
COMMENT ON COLUMN role_menu_perm.menu_id IS '메뉴 FK → menu';
COMMENT ON COLUMN role_menu_perm.can_read IS '조회 권한';
COMMENT ON COLUMN role_menu_perm.can_crt IS '등록 권한';
COMMENT ON COLUMN role_menu_perm.can_updt IS '수정 권한';
COMMENT ON COLUMN role_menu_perm.can_del IS '삭제 권한';
COMMENT ON COLUMN role_menu_perm.can_aprv IS '승인 권한';
COMMENT ON COLUMN role_menu_perm.can_dwld IS '다운로드 권한';
COMMENT ON COLUMN role_menu_perm.crtd_at IS '등록일시';
COMMENT ON COLUMN role_menu_perm.crtd_by IS '등록자 ID';
COMMENT ON COLUMN role_menu_perm.updtd_at IS '수정일시';
COMMENT ON COLUMN role_menu_perm.updtd_by IS '수정자 ID';

-- login_hist
COMMENT ON TABLE  login_hist IS '사용자 로그인/로그아웃 이력';
COMMENT ON COLUMN login_hist.hist_id IS '이력 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN login_hist.usr_id IS '사용자 FK → usr_acnt';
COMMENT ON COLUMN login_hist.login_ty IS '로그인 유형: sso/partner/engineer/admin';
COMMENT ON COLUMN login_hist.login_ip IS '접속 IP 주소';
COMMENT ON COLUMN login_hist.usr_agent IS '브라우저 User-Agent';
COMMENT ON COLUMN login_hist.login_at IS '로그인 일시';
COMMENT ON COLUMN login_hist.logout_at IS '로그아웃 일시';
COMMENT ON COLUMN login_hist.is_succes IS '로그인 성공 여부';
COMMENT ON COLUMN login_hist.fail_rsn IS '로그인 실패 사유';
COMMENT ON COLUMN login_hist.crtd_at IS '등록일시';
COMMENT ON COLUMN login_hist.crtd_by IS '등록자 ID';
COMMENT ON COLUMN login_hist.updtd_at IS '수정일시';
COMMENT ON COLUMN login_hist.updtd_by IS '수정자 ID';


-- ============================================================================
-- 2. 카탈로그·메타데이터
-- ============================================================================

-- domn
COMMENT ON TABLE  domn IS '비즈니스 도메인 (수자원/수질/에너지/인프라/고객 등)';
COMMENT ON COLUMN domn.domn_id IS '도메인 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN domn.domn_cd IS '도메인코드 (WATER, QUALITY 등)';
COMMENT ON COLUMN domn.domn_nm IS '도메인명 (한글)';
COMMENT ON COLUMN domn.dc IS '도메인 설명';
COMMENT ON COLUMN domn.color IS 'HEX 색상코드 (#3B82F6)';
COMMENT ON COLUMN domn.icon IS '아이콘명 (droplet, flask 등)';
COMMENT ON COLUMN domn.sort_ord IS '정렬 순서';
COMMENT ON COLUMN domn.is_actv IS '활성 여부';
COMMENT ON COLUMN domn.crtd_at IS '등록일시';
COMMENT ON COLUMN domn.crtd_by IS '등록자 ID';
COMMENT ON COLUMN domn.updtd_at IS '수정일시';
COMMENT ON COLUMN domn.updtd_by IS '수정자 ID';

-- src_sys
COMMENT ON TABLE  src_sys IS '원천시스템 (RWIS, SAP, SCADA, WIS 등)';
COMMENT ON COLUMN src_sys.sys_id IS '시스템 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN src_sys.sys_cd IS '시스템코드 (유니크)';
COMMENT ON COLUMN src_sys.sys_nm IS '시스템명 (한글)';
COMMENT ON COLUMN src_sys.sys_nm_en IS '시스템명 (영문)';
COMMENT ON COLUMN src_sys.dc IS '시스템 설명';
COMMENT ON COLUMN src_sys.dbms_ty IS 'DBMS 유형: PostgreSQL/Oracle/MySQL/MSSQL/SAP_HANA';
COMMENT ON COLUMN src_sys.prtcl IS '접속 프로토콜: JDBC/REST/SOAP/FTP/MQTT/OPC-UA';
COMMENT ON COLUMN src_sys.ntwk_zone IS '네트워크 구간: internal/dmz/external/cloud';
COMMENT ON COLUMN src_sys.cnctn_info IS '접속정보 JSON (호스트/포트/DB명 등, 암호화 저장)';
COMMENT ON COLUMN src_sys.owner_dept_id IS '담당 부서 FK → dept';
COMMENT ON COLUMN src_sys.stat IS '시스템 상태';
COMMENT ON COLUMN src_sys.crtd_at IS '등록일시';
COMMENT ON COLUMN src_sys.crtd_by IS '등록자 ID';
COMMENT ON COLUMN src_sys.updtd_at IS '수정일시';
COMMENT ON COLUMN src_sys.updtd_by IS '수정자 ID';

-- dset
COMMENT ON TABLE  dset IS '데이터셋/카탈로그 (통합 검색 대상)';
COMMENT ON COLUMN dset.dset_id IS '데이터셋 고유 ID (PK, UUID)';
COMMENT ON COLUMN dset.dset_cd IS '데이터셋코드 (유니크)';
COMMENT ON COLUMN dset.table_nm IS '원천 테이블명';
COMMENT ON COLUMN dset.dset_nm IS '데이터셋명 (한글)';
COMMENT ON COLUMN dset.dc IS '데이터셋 설명';
COMMENT ON COLUMN dset.domn_id IS '비즈니스 도메인 FK → domn';
COMMENT ON COLUMN dset.sys_id IS '원천시스템 FK → src_sys';
COMMENT ON COLUMN dset.asset_ty IS '자산 유형: table/api/file/view/stream';
COMMENT ON COLUMN dset.scrty_lvl IS '보안등급: public/internal/restricted/confidential';
COMMENT ON COLUMN dset.qlity_score IS '품질점수 (0.00 ~ 100.00)';
COMMENT ON COLUMN dset.row_co IS '총 행 수';
COMMENT ON COLUMN dset.col_co IS '총 컬럼 수';
COMMENT ON COLUMN dset.size_bytes IS '데이터 크기 (바이트)';
COMMENT ON COLUMN dset.owner_dept_id IS '소유 부서 FK → dept';
COMMENT ON COLUMN dset.stwrd_usr_id IS '데이터 스튜어드 FK → usr_acnt';
COMMENT ON COLUMN dset.stat IS '데이터셋 상태';
COMMENT ON COLUMN dset.last_prfld_at IS '최종 프로파일링 일시';
COMMENT ON COLUMN dset.crtd_at IS '등록일시';
COMMENT ON COLUMN dset.crtd_by IS '등록자 ID';
COMMENT ON COLUMN dset.updtd_at IS '수정일시';
COMMENT ON COLUMN dset.updtd_by IS '수정자 ID';

-- dset_col
COMMENT ON TABLE  dset_col IS '데이터셋 컬럼 스키마 및 프로파일링 정보';
COMMENT ON COLUMN dset_col.col_id IS '컬럼 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN dset_col.dset_id IS '데이터셋 FK → dset';
COMMENT ON COLUMN dset_col.col_nm IS '컬럼명 (영문)';
COMMENT ON COLUMN dset_col.col_nm_ko IS '컬럼명 (한글)';
COMMENT ON COLUMN dset_col.data_ty IS '데이터 타입 (VARCHAR, INT 등)';
COMMENT ON COLUMN dset_col.data_lt IS '데이터 길이';
COMMENT ON COLUMN dset_col.is_pk IS 'PK 여부';
COMMENT ON COLUMN dset_col.is_fk IS 'FK 여부';
COMMENT ON COLUMN dset_col.is_nulbl IS 'NULL 허용 여부';
COMMENT ON COLUMN dset_col.dflt_val IS '기본값';
COMMENT ON COLUMN dset_col.std_term_id IS '표준용어 FK → glsry_term';
COMMENT ON COLUMN dset_col.dc IS '컬럼 설명';
COMMENT ON COLUMN dset_col.null_rt IS 'NULL 비율 (%) - 프로파일링 결과';
COMMENT ON COLUMN dset_col.unique_rt IS '유일값 비율 (%) - 프로파일링 결과';
COMMENT ON COLUMN dset_col.min_val IS '최솟값 - 프로파일링 결과';
COMMENT ON COLUMN dset_col.max_val IS '최댓값 - 프로파일링 결과';
COMMENT ON COLUMN dset_col.smple_vals IS '샘플 값 배열';
COMMENT ON COLUMN dset_col.sort_ord IS '정렬 순서';
COMMENT ON COLUMN dset_col.crtd_at IS '등록일시';
COMMENT ON COLUMN dset_col.crtd_by IS '등록자 ID';
COMMENT ON COLUMN dset_col.updtd_at IS '수정일시';
COMMENT ON COLUMN dset_col.updtd_by IS '수정자 ID';

-- tag
COMMENT ON TABLE  tag IS '태그 (데이터셋 분류/검색용)';
COMMENT ON COLUMN tag.tag_id IS '태그 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN tag.tag_nm IS '태그명';
COMMENT ON COLUMN tag.tag_ty IS '태그 유형: keyword/domain/business/security';
COMMENT ON COLUMN tag.color IS 'HEX 색상코드';
COMMENT ON COLUMN tag.crtd_at IS '등록일시';
COMMENT ON COLUMN tag.crtd_by IS '등록자 ID';
COMMENT ON COLUMN tag.updtd_at IS '수정일시';
COMMENT ON COLUMN tag.updtd_by IS '수정자 ID';

-- dset_tag
COMMENT ON TABLE  dset_tag IS '데이터셋-태그 N:M 매핑';
COMMENT ON COLUMN dset_tag.dset_id IS '데이터셋 FK → dset';
COMMENT ON COLUMN dset_tag.tag_id IS '태그 FK → tag';
COMMENT ON COLUMN dset_tag.crtd_at IS '등록일시';
COMMENT ON COLUMN dset_tag.crtd_by IS '등록자 ID';
COMMENT ON COLUMN dset_tag.updtd_at IS '수정일시';
COMMENT ON COLUMN dset_tag.updtd_by IS '수정자 ID';

-- bmrk
COMMENT ON TABLE  bmrk IS '사용자 즐겨찾기/보관함';
COMMENT ON COLUMN bmrk.bmrk_id IS '북마크 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN bmrk.usr_id IS '사용자 FK → usr_acnt';
COMMENT ON COLUMN bmrk.dset_id IS '데이터셋 FK → dset';
COMMENT ON COLUMN bmrk.memo IS '메모';
COMMENT ON COLUMN bmrk.crtd_at IS '등록일시';
COMMENT ON COLUMN bmrk.crtd_by IS '등록자 ID';
COMMENT ON COLUMN bmrk.updtd_at IS '수정일시';
COMMENT ON COLUMN bmrk.updtd_by IS '수정자 ID';

-- glsry_term
COMMENT ON TABLE  glsry_term IS '표준용어사전';
COMMENT ON COLUMN glsry_term.term_id IS '용어 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN glsry_term.term_nm IS '표준용어명 (한글)';
COMMENT ON COLUMN glsry_term.term_nm_en IS '표준용어명 (영문)';
COMMENT ON COLUMN glsry_term.domn_id IS '비즈니스 도메인 FK → domn';
COMMENT ON COLUMN glsry_term.data_ty IS '데이터 타입';
COMMENT ON COLUMN glsry_term.data_lt IS '데이터 길이';
COMMENT ON COLUMN glsry_term.unit IS '단위 (m, ㎥/s, mg/L 등)';
COMMENT ON COLUMN glsry_term.valid_rng_min IS '유효 범위 최솟값';
COMMENT ON COLUMN glsry_term.valid_rng_max IS '유효 범위 최댓값';
COMMENT ON COLUMN glsry_term.dfn IS '용어 정의';
COMMENT ON COLUMN glsry_term.exmp IS '예시값';
COMMENT ON COLUMN glsry_term.synm IS '유의어/동의어';
COMMENT ON COLUMN glsry_term.stat IS '승인 상태: pending/approved/rejected/revision_needed/cancelled';
COMMENT ON COLUMN glsry_term.aprvd_by IS '승인자 FK → usr_acnt';
COMMENT ON COLUMN glsry_term.aprvd_at IS '승인 일시';
COMMENT ON COLUMN glsry_term.crtd_at IS '등록일시';
COMMENT ON COLUMN glsry_term.crtd_by IS '등록자 ID';
COMMENT ON COLUMN glsry_term.updtd_at IS '수정일시';
COMMENT ON COLUMN glsry_term.updtd_by IS '수정자 ID';

-- glsry_hist
COMMENT ON TABLE  glsry_hist IS '표준용어 변경이력 추적';
COMMENT ON COLUMN glsry_hist.hist_id IS '이력 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN glsry_hist.term_id IS '용어 FK → glsry_term';
COMMENT ON COLUMN glsry_hist.chg_desc IS '변경 설명';
COMMENT ON COLUMN glsry_hist.chgd_by IS '변경자 FK → usr_acnt';
COMMENT ON COLUMN glsry_hist.prev_stat IS '변경 전 승인 상태';
COMMENT ON COLUMN glsry_hist.new_stat IS '변경 후 승인 상태';
COMMENT ON COLUMN glsry_hist.prev_val IS '변경 전 값 (JSON)';
COMMENT ON COLUMN glsry_hist.new_val IS '변경 후 값 (JSON)';
COMMENT ON COLUMN glsry_hist.crtd_at IS '등록일시';
COMMENT ON COLUMN glsry_hist.crtd_by IS '등록자 ID';
COMMENT ON COLUMN glsry_hist.updtd_at IS '수정일시';
COMMENT ON COLUMN glsry_hist.updtd_by IS '수정자 ID';

-- cd_grp
COMMENT ON TABLE  cd_grp IS '공통코드 그룹 (CD_REGION, CD_STATUS 등)';
COMMENT ON COLUMN cd_grp.grp_id IS '코드그룹 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN cd_grp.grp_cd IS '코드그룹코드 (유니크)';
COMMENT ON COLUMN cd_grp.grp_nm IS '코드그룹명 (한글)';
COMMENT ON COLUMN cd_grp.dc IS '코드그룹 설명';
COMMENT ON COLUMN cd_grp.is_actv IS '활성 여부';
COMMENT ON COLUMN cd_grp.crtd_at IS '등록일시';
COMMENT ON COLUMN cd_grp.crtd_by IS '등록자 ID';
COMMENT ON COLUMN cd_grp.updtd_at IS '수정일시';
COMMENT ON COLUMN cd_grp.updtd_by IS '수정자 ID';

-- cd
COMMENT ON TABLE  cd IS '공통코드 값';
COMMENT ON COLUMN cd.cd_id IS '코드 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN cd.grp_id IS '코드그룹 FK → cd_grp';
COMMENT ON COLUMN cd.cd_val IS '코드값';
COMMENT ON COLUMN cd.cd_nm IS '코드명 (한글)';
COMMENT ON COLUMN cd.dc IS '코드 설명';
COMMENT ON COLUMN cd.sort_ord IS '정렬 순서';
COMMENT ON COLUMN cd.is_actv IS '활성 여부';
COMMENT ON COLUMN cd.crtd_at IS '등록일시';
COMMENT ON COLUMN cd.crtd_by IS '등록자 ID';
COMMENT ON COLUMN cd.updtd_at IS '수정일시';
COMMENT ON COLUMN cd.updtd_by IS '수정자 ID';

-- data_model
COMMENT ON TABLE  data_model IS '논리/물리 데이터모델';
COMMENT ON COLUMN data_model.model_id IS '모델 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN data_model.model_nm IS '모델명';
COMMENT ON COLUMN data_model.model_ty IS '모델 유형: logical/physical';
COMMENT ON COLUMN data_model.domn_id IS '비즈니스 도메인 FK → domn';
COMMENT ON COLUMN data_model.ver IS '버전';
COMMENT ON COLUMN data_model.dc IS '모델 설명';
COMMENT ON COLUMN data_model.table_co IS '테이블 수';
COMMENT ON COLUMN data_model.namng_cmplnc IS '명명규칙 준수율 (%)';
COMMENT ON COLUMN data_model.ty_cnstnc IS '타입 일관성 (%)';
COMMENT ON COLUMN data_model.ref_intgrty IS '참조무결성 (%)';
COMMENT ON COLUMN data_model.stat IS '모델 상태';
COMMENT ON COLUMN data_model.owner_usr_id IS '소유자 FK → usr_acnt';
COMMENT ON COLUMN data_model.crtd_at IS '등록일시';
COMMENT ON COLUMN data_model.crtd_by IS '등록자 ID';
COMMENT ON COLUMN data_model.updtd_at IS '수정일시';
COMMENT ON COLUMN data_model.updtd_by IS '수정자 ID';

-- model_entty
COMMENT ON TABLE  model_entty IS '데이터모델 엔티티 (테이블/뷰)';
COMMENT ON COLUMN model_entty.entty_id IS '엔티티 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN model_entty.model_id IS '데이터모델 FK → data_model';
COMMENT ON COLUMN model_entty.entty_nm IS '엔티티명 (영문)';
COMMENT ON COLUMN model_entty.entty_nm_ko IS '엔티티명 (한글)';
COMMENT ON COLUMN model_entty.entty_ty IS '엔티티 유형: table/view/mview';
COMMENT ON COLUMN model_entty.dc IS '엔티티 설명';
COMMENT ON COLUMN model_entty.sort_ord IS '정렬 순서';
COMMENT ON COLUMN model_entty.crtd_at IS '등록일시';
COMMENT ON COLUMN model_entty.crtd_by IS '등록자 ID';
COMMENT ON COLUMN model_entty.updtd_at IS '수정일시';
COMMENT ON COLUMN model_entty.updtd_by IS '수정자 ID';

-- model_atrb
COMMENT ON TABLE  model_atrb IS '데이터모델 속성 (컬럼)';
COMMENT ON COLUMN model_atrb.atrb_id IS '속성 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN model_atrb.entty_id IS '엔티티 FK → model_entty';
COMMENT ON COLUMN model_atrb.atrb_nm IS '속성명 (영문)';
COMMENT ON COLUMN model_atrb.atrb_nm_ko IS '속성명 (한글)';
COMMENT ON COLUMN model_atrb.data_ty IS '데이터 타입';
COMMENT ON COLUMN model_atrb.data_lt IS '데이터 길이';
COMMENT ON COLUMN model_atrb.is_pk IS 'PK 여부';
COMMENT ON COLUMN model_atrb.is_fk IS 'FK 여부';
COMMENT ON COLUMN model_atrb.is_nulbl IS 'NULL 허용 여부';
COMMENT ON COLUMN model_atrb.fk_ref_entty IS 'FK 참조 엔티티명';
COMMENT ON COLUMN model_atrb.fk_ref_atrb IS 'FK 참조 속성명';
COMMENT ON COLUMN model_atrb.dc IS '속성 설명';
COMMENT ON COLUMN model_atrb.sort_ord IS '정렬 순서';
COMMENT ON COLUMN model_atrb.crtd_at IS '등록일시';
COMMENT ON COLUMN model_atrb.crtd_by IS '등록자 ID';
COMMENT ON COLUMN model_atrb.updtd_at IS '수정일시';
COMMENT ON COLUMN model_atrb.updtd_by IS '수정자 ID';


-- ============================================================================
-- 3. 수집 관리
-- ============================================================================

-- ppln
COMMENT ON TABLE  ppln IS '수집 파이프라인 (ETL/CDC/API/Streaming)';
COMMENT ON COLUMN ppln.ppln_id IS '파이프라인 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN ppln.ppln_nm IS '파이프라인명';
COMMENT ON COLUMN ppln.ppln_cd IS '파이프라인코드 (유니크)';
COMMENT ON COLUMN ppln.sys_id IS '원천시스템 FK → src_sys';
COMMENT ON COLUMN ppln.colct_mthd IS '수집방식: cdc/batch/api/file/streaming/migration';
COMMENT ON COLUMN ppln.schdul IS 'cron 표현식 (0 */6 * * * = 6시간 간격)';
COMMENT ON COLUMN ppln.src_table IS '원천 테이블/경로';
COMMENT ON COLUMN ppln.trget_stg IS '적재 대상 (스키마.테이블 또는 스토리지 경로)';
COMMENT ON COLUMN ppln.thrput IS '예상 처리량 (건/시간)';
COMMENT ON COLUMN ppln.dc IS '파이프라인 설명';
COMMENT ON COLUMN ppln.owner_usr_id IS '담당자 FK → usr_acnt';
COMMENT ON COLUMN ppln.owner_dept_id IS '담당 부서 FK → dept';
COMMENT ON COLUMN ppln.stat IS '파이프라인 상태';
COMMENT ON COLUMN ppln.crtd_at IS '등록일시';
COMMENT ON COLUMN ppln.crtd_by IS '등록자 ID';
COMMENT ON COLUMN ppln.updtd_at IS '수정일시';
COMMENT ON COLUMN ppln.updtd_by IS '수정자 ID';

-- ppln_exec
COMMENT ON TABLE  ppln_exec IS '파이프라인 실행 이력';
COMMENT ON COLUMN ppln_exec.exec_id IS '실행 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN ppln_exec.ppln_id IS '파이프라인 FK → ppln';
COMMENT ON COLUMN ppln_exec.strtd_at IS '실행 시작 일시';
COMMENT ON COLUMN ppln_exec.fnshed_at IS '실행 종료 일시';
COMMENT ON COLUMN ppln_exec.dur_secnd IS '소요 시간 (초)';
COMMENT ON COLUMN ppln_exec.rcrds_read IS '읽은 레코드 수';
COMMENT ON COLUMN ppln_exec.rcrds_wrtn IS '적재한 레코드 수';
COMMENT ON COLUMN ppln_exec.rcrds_err IS '오류 레코드 수';
COMMENT ON COLUMN ppln_exec.succes_rt IS '성공률 (%)';
COMMENT ON COLUMN ppln_exec.stat IS '실행 상태: running/success/failed/cancelled';
COMMENT ON COLUMN ppln_exec.err_msg IS '오류 메시지';
COMMENT ON COLUMN ppln_exec.err_dtl IS '상세 오류 정보 (JSON, 스택트레이스 등)';
COMMENT ON COLUMN ppln_exec.crtd_at IS '등록일시';
COMMENT ON COLUMN ppln_exec.crtd_by IS '등록자 ID';
COMMENT ON COLUMN ppln_exec.updtd_at IS '수정일시';
COMMENT ON COLUMN ppln_exec.updtd_by IS '수정자 ID';

-- ppln_col_mapng
COMMENT ON TABLE  ppln_col_mapng IS '파이프라인 컬럼 매핑 및 변환 규칙';
COMMENT ON COLUMN ppln_col_mapng.mapng_id IS '매핑 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN ppln_col_mapng.ppln_id IS '파이프라인 FK → ppln';
COMMENT ON COLUMN ppln_col_mapng.src_col IS '원천 컬럼명';
COMMENT ON COLUMN ppln_col_mapng.trget_col IS '적재 대상 컬럼명';
COMMENT ON COLUMN ppln_col_mapng.src_ty IS '원천 데이터 타입';
COMMENT ON COLUMN ppln_col_mapng.trget_ty IS '적재 대상 데이터 타입';
COMMENT ON COLUMN ppln_col_mapng.trsfm_rule IS '변환식 (TRIM, TO_DATE, CASE 등)';
COMMENT ON COLUMN ppln_col_mapng.is_reqrd IS '필수 여부';
COMMENT ON COLUMN ppln_col_mapng.sort_ord IS '정렬 순서';
COMMENT ON COLUMN ppln_col_mapng.crtd_at IS '등록일시';
COMMENT ON COLUMN ppln_col_mapng.crtd_by IS '등록자 ID';
COMMENT ON COLUMN ppln_col_mapng.updtd_at IS '수정일시';
COMMENT ON COLUMN ppln_col_mapng.updtd_by IS '수정자 ID';

-- cdc_cnctr
COMMENT ON TABLE  cdc_cnctr IS 'CDC 커넥터 (실시간 변경 데이터 캡처)';
COMMENT ON COLUMN cdc_cnctr.cnctr_id IS '커넥터 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN cdc_cnctr.sys_id IS '원천시스템 FK → src_sys';
COMMENT ON COLUMN cdc_cnctr.cnctr_nm IS '커넥터명';
COMMENT ON COLUMN cdc_cnctr.cnctr_ty IS '커넥터 유형: debezium/oracle_goldengate/sap_slt';
COMMENT ON COLUMN cdc_cnctr.dbms_ty IS 'DBMS 유형';
COMMENT ON COLUMN cdc_cnctr.table_co IS '수집 대상 테이블 수';
COMMENT ON COLUMN cdc_cnctr.evnt_per_min IS '분당 이벤트 처리량';
COMMENT ON COLUMN cdc_cnctr.lag_secnd IS '지연 시간 (초)';
COMMENT ON COLUMN cdc_cnctr.cnfg IS '커넥터 설정 (JSON)';
COMMENT ON COLUMN cdc_cnctr.stat IS '커넥터 상태';
COMMENT ON COLUMN cdc_cnctr.crtd_at IS '등록일시';
COMMENT ON COLUMN cdc_cnctr.crtd_by IS '등록자 ID';
COMMENT ON COLUMN cdc_cnctr.updtd_at IS '수정일시';
COMMENT ON COLUMN cdc_cnctr.updtd_by IS '수정자 ID';

-- kafka_topc
COMMENT ON TABLE  kafka_topc IS 'Kafka 스트리밍 토픽';
COMMENT ON COLUMN kafka_topc.topc_id IS '토픽 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN kafka_topc.topc_nm IS '토픽명 (유니크)';
COMMENT ON COLUMN kafka_topc.clstr_nm IS '클러스터명';
COMMENT ON COLUMN kafka_topc.prtitn_co IS '파티션 수';
COMMENT ON COLUMN kafka_topc.rplctn IS '복제 계수';
COMMENT ON COLUMN kafka_topc.rtntn_hr IS '보관 기간 (시간, 기본 7일=168)';
COMMENT ON COLUMN kafka_topc.msg_per_sec IS '초당 메시지 처리량';
COMMENT ON COLUMN kafka_topc.cnsmr_grps IS '컨슈머 그룹 목록 (배열)';
COMMENT ON COLUMN kafka_topc.stat IS '토픽 상태';
COMMENT ON COLUMN kafka_topc.crtd_at IS '등록일시';
COMMENT ON COLUMN kafka_topc.crtd_by IS '등록자 ID';
COMMENT ON COLUMN kafka_topc.updtd_at IS '수정일시';
COMMENT ON COLUMN kafka_topc.updtd_by IS '수정자 ID';

-- extn_intgrn
COMMENT ON TABLE  extn_intgrn IS '외부 시스템 연계 인터페이스';
COMMENT ON COLUMN extn_intgrn.intgrn_id IS '연계 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN extn_intgrn.intgrn_nm IS '연계명';
COMMENT ON COLUMN extn_intgrn.intgrn_ty IS '연계 유형: api/file/mq/socket';
COMMENT ON COLUMN extn_intgrn.src_sys IS '원천시스템명';
COMMENT ON COLUMN extn_intgrn.trget_sys IS '대상시스템명';
COMMENT ON COLUMN extn_intgrn.prtcl IS '통신 프로토콜';
COMMENT ON COLUMN extn_intgrn.endpt_url IS '엔드포인트 URL';
COMMENT ON COLUMN extn_intgrn.freq IS '연계 주기';
COMMENT ON COLUMN extn_intgrn.last_succes_at IS '최종 성공 일시';
COMMENT ON COLUMN extn_intgrn.last_fail_at IS '최종 실패 일시';
COMMENT ON COLUMN extn_intgrn.stat IS '연계 상태';
COMMENT ON COLUMN extn_intgrn.crtd_at IS '등록일시';
COMMENT ON COLUMN extn_intgrn.crtd_by IS '등록자 ID';
COMMENT ON COLUMN extn_intgrn.updtd_at IS '수정일시';
COMMENT ON COLUMN extn_intgrn.updtd_by IS '수정자 ID';

-- dbt_model
COMMENT ON TABLE  dbt_model IS 'dbt 데이터 변환/정제 모델';
COMMENT ON COLUMN dbt_model.dbt_model_id IS 'dbt 모델 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN dbt_model.model_nm IS '모델명';
COMMENT ON COLUMN dbt_model.model_path IS '모델 파일 경로';
COMMENT ON COLUMN dbt_model.mtrlzn IS '구체화 방식: table/view/incremental/ephemeral';
COMMENT ON COLUMN dbt_model.src_tbls IS '소스 테이블 목록 (배열)';
COMMENT ON COLUMN dbt_model.trget_table IS '대상 테이블명';
COMMENT ON COLUMN dbt_model.dc IS '모델 설명';
COMMENT ON COLUMN dbt_model.tags IS '태그 목록 (배열)';
COMMENT ON COLUMN dbt_model.last_run_at IS '최종 실행 일시';
COMMENT ON COLUMN dbt_model.last_run_stat IS '최종 실행 상태';
COMMENT ON COLUMN dbt_model.run_dur_secnd IS '최종 실행 소요시간 (초)';
COMMENT ON COLUMN dbt_model.owner_usr_id IS '담당자 FK → usr_acnt';
COMMENT ON COLUMN dbt_model.stat IS '모델 상태';
COMMENT ON COLUMN dbt_model.crtd_at IS '등록일시';
COMMENT ON COLUMN dbt_model.crtd_by IS '등록자 ID';
COMMENT ON COLUMN dbt_model.updtd_at IS '수정일시';
COMMENT ON COLUMN dbt_model.updtd_by IS '수정자 ID';

-- server_invntry
COMMENT ON TABLE  server_invntry IS '서버 인프라 자산 목록';
COMMENT ON COLUMN server_invntry.server_id IS '서버 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN server_invntry.server_nm IS '서버명';
COMMENT ON COLUMN server_invntry.server_ty IS '서버 유형: web/was/db/cache/storage/k8s-node';
COMMENT ON COLUMN server_invntry.ip_addr IS 'IP 주소';
COMMENT ON COLUMN server_invntry.os_ty IS 'OS 유형';
COMMENT ON COLUMN server_invntry.cpu_cores IS 'CPU 코어 수';
COMMENT ON COLUMN server_invntry.mory_gb IS '메모리 (GB)';
COMMENT ON COLUMN server_invntry.disk_gb IS '디스크 (GB)';
COMMENT ON COLUMN server_invntry.envrn IS '환경: production/staging/development';
COMMENT ON COLUMN server_invntry.dtcntr IS '데이터센터 위치';
COMMENT ON COLUMN server_invntry.stat IS '서버 상태';
COMMENT ON COLUMN server_invntry.crtd_at IS '등록일시';
COMMENT ON COLUMN server_invntry.crtd_by IS '등록자 ID';
COMMENT ON COLUMN server_invntry.updtd_at IS '수정일시';
COMMENT ON COLUMN server_invntry.updtd_by IS '수정자 ID';


-- ============================================================================
-- 4. 유통·활용
-- ============================================================================

-- data_product
COMMENT ON TABLE  data_product IS 'Data Product (API/다운로드/스트리밍 데이터 패키지)';
COMMENT ON COLUMN data_product.product_id IS 'Product 고유 ID (PK, UUID)';
COMMENT ON COLUMN data_product.product_cd IS 'Product 코드 (유니크)';
COMMENT ON COLUMN data_product.product_nm IS 'Product명';
COMMENT ON COLUMN data_product.dc IS 'Product 설명';
COMMENT ON COLUMN data_product.product_ty IS 'Product 유형: api/download/streaming/dashboard';
COMMENT ON COLUMN data_product.domn_id IS '비즈니스 도메인 FK → domn';
COMMENT ON COLUMN data_product.scrty_lvl IS '보안등급';
COMMENT ON COLUMN data_product.ver IS '버전';
COMMENT ON COLUMN data_product.endpt_url IS 'API 엔드포인트 URL';
COMMENT ON COLUMN data_product.rt_limit IS '분당 최대 API 호출 수';
COMMENT ON COLUMN data_product.tot_calls IS '누적 총 호출 수';
COMMENT ON COLUMN data_product.avg_rspns_ms IS '평균 응답시간 (ms)';
COMMENT ON COLUMN data_product.sla_uptm IS 'SLA 가용률 (%)';
COMMENT ON COLUMN data_product.owner_dept_id IS '소유 부서 FK → dept';
COMMENT ON COLUMN data_product.owner_usr_id IS '소유자 FK → usr_acnt';
COMMENT ON COLUMN data_product.stat IS 'Product 상태';
COMMENT ON COLUMN data_product.pblshd_at IS '게시 일시';
COMMENT ON COLUMN data_product.crtd_at IS '등록일시';
COMMENT ON COLUMN data_product.crtd_by IS '등록자 ID';
COMMENT ON COLUMN data_product.updtd_at IS '수정일시';
COMMENT ON COLUMN data_product.updtd_by IS '수정자 ID';

-- product_src
COMMENT ON TABLE  product_src IS 'Data Product 소스 데이터셋 매핑';
COMMENT ON COLUMN product_src.src_id IS '소스매핑 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN product_src.product_id IS 'Product FK → data_product';
COMMENT ON COLUMN product_src.dset_id IS '데이터셋 FK → dset';
COMMENT ON COLUMN product_src.join_ty IS '조인 유형: primary/lookup/aggregation';
COMMENT ON COLUMN product_src.join_key IS '조인 키';
COMMENT ON COLUMN product_src.dc IS '매핑 설명';
COMMENT ON COLUMN product_src.sort_ord IS '정렬 순서';
COMMENT ON COLUMN product_src.crtd_at IS '등록일시';
COMMENT ON COLUMN product_src.crtd_by IS '등록자 ID';
COMMENT ON COLUMN product_src.updtd_at IS '수정일시';
COMMENT ON COLUMN product_src.updtd_by IS '수정자 ID';

-- product_field
COMMENT ON TABLE  product_field IS 'Data Product 응답 필드 정의';
COMMENT ON COLUMN product_field.field_id IS '필드 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN product_field.product_id IS 'Product FK → data_product';
COMMENT ON COLUMN product_field.field_nm IS '필드명 (영문)';
COMMENT ON COLUMN product_field.field_nm_ko IS '필드명 (한글)';
COMMENT ON COLUMN product_field.field_ty IS '필드 데이터 타입';
COMMENT ON COLUMN product_field.is_reqrd IS '필수 여부';
COMMENT ON COLUMN product_field.is_fltrbl IS '필터링 가능 여부';
COMMENT ON COLUMN product_field.dc IS '필드 설명';
COMMENT ON COLUMN product_field.smple_val IS '샘플값';
COMMENT ON COLUMN product_field.sort_ord IS '정렬 순서';
COMMENT ON COLUMN product_field.crtd_at IS '등록일시';
COMMENT ON COLUMN product_field.crtd_by IS '등록자 ID';
COMMENT ON COLUMN product_field.updtd_at IS '수정일시';
COMMENT ON COLUMN product_field.updtd_by IS '수정자 ID';

-- api_key
COMMENT ON TABLE  api_key IS 'API 키 발급 및 관리';
COMMENT ON COLUMN api_key.key_id IS 'API 키 고유 ID (PK, UUID)';
COMMENT ON COLUMN api_key.usr_id IS '발급 사용자 FK → usr_acnt';
COMMENT ON COLUMN api_key.product_id IS 'Data Product FK → data_product';
COMMENT ON COLUMN api_key.api_key_hash IS 'API 키의 SHA-256 해시 (원문 저장 금지)';
COMMENT ON COLUMN api_key.key_prfx IS '키 앞 8자 (식별용)';
COMMENT ON COLUMN api_key.dc IS 'API 키 설명';
COMMENT ON COLUMN api_key.is_actv IS '활성 여부';
COMMENT ON COLUMN api_key.expirs_at IS '만료 일시';
COMMENT ON COLUMN api_key.last_used_at IS '최종 사용 일시';
COMMENT ON COLUMN api_key.tot_calls IS '누적 호출 수';
COMMENT ON COLUMN api_key.crtd_at IS '등록일시';
COMMENT ON COLUMN api_key.crtd_by IS '등록자 ID';
COMMENT ON COLUMN api_key.updtd_at IS '수정일시';
COMMENT ON COLUMN api_key.updtd_by IS '수정자 ID';

-- didntf_polcy
COMMENT ON TABLE  didntf_polcy IS '비식별화/가명처리 정책';
COMMENT ON COLUMN didntf_polcy.polcy_id IS '정책 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN didntf_polcy.polcy_nm IS '정책명';
COMMENT ON COLUMN didntf_polcy.dc IS '정책 설명';
COMMENT ON COLUMN didntf_polcy.trget_lvl IS '적용 대상 보안등급';
COMMENT ON COLUMN didntf_polcy.rule_co IS '규칙 수';
COMMENT ON COLUMN didntf_polcy.is_actv IS '활성 여부';
COMMENT ON COLUMN didntf_polcy.aprvd_by IS '승인자 FK → usr_acnt';
COMMENT ON COLUMN didntf_polcy.crtd_at IS '등록일시';
COMMENT ON COLUMN didntf_polcy.crtd_by IS '등록자 ID';
COMMENT ON COLUMN didntf_polcy.updtd_at IS '수정일시';
COMMENT ON COLUMN didntf_polcy.updtd_by IS '수정자 ID';

-- didntf_rule
COMMENT ON TABLE  didntf_rule IS '비식별화 규칙 (마스킹/가명/삭제 등)';
COMMENT ON COLUMN didntf_rule.rule_id IS '규칙 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN didntf_rule.polcy_id IS '정책 FK → didntf_polcy';
COMMENT ON COLUMN didntf_rule.col_pttrn IS '대상 컬럼 패턴 (정규식 또는 컬럼명)';
COMMENT ON COLUMN didntf_rule.rule_ty IS '규칙 유형: masking/pseudonym/aggregation/suppression/rounding/encryption';
COMMENT ON COLUMN didntf_rule.rule_cnfg IS '규칙 설정 JSON (예: {"pattern":"***-****","keep_first":3})';
COMMENT ON COLUMN didntf_rule.priort IS '우선순위';
COMMENT ON COLUMN didntf_rule.dc IS '규칙 설명';
COMMENT ON COLUMN didntf_rule.crtd_at IS '등록일시';
COMMENT ON COLUMN didntf_rule.crtd_by IS '등록자 ID';
COMMENT ON COLUMN didntf_rule.updtd_at IS '수정일시';
COMMENT ON COLUMN didntf_rule.updtd_by IS '수정자 ID';

-- data_rqst
COMMENT ON TABLE  data_rqst IS '데이터 활용 신청/승인 워크플로우';
COMMENT ON COLUMN data_rqst.rqst_id IS '신청 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN data_rqst.rqst_cd IS '신청번호 (유니크)';
COMMENT ON COLUMN data_rqst.usr_id IS '신청자 FK → usr_acnt';
COMMENT ON COLUMN data_rqst.dset_id IS '대상 데이터셋 FK → dset';
COMMENT ON COLUMN data_rqst.product_id IS '대상 Product FK → data_product';
COMMENT ON COLUMN data_rqst.rqst_ty IS '신청 유형: download/api_access/share/export';
COMMENT ON COLUMN data_rqst.purps IS '활용 목적';
COMMENT ON COLUMN data_rqst.is_urgnt IS '긴급 여부';
COMMENT ON COLUMN data_rqst.aprvl_stat IS '승인 상태';
COMMENT ON COLUMN data_rqst.apprvr_id IS '승인자 FK → usr_acnt';
COMMENT ON COLUMN data_rqst.aprvd_at IS '승인 일시';
COMMENT ON COLUMN data_rqst.expir_at IS '접근 권한 만료일';
COMMENT ON COLUMN data_rqst.crtd_at IS '등록일시';
COMMENT ON COLUMN data_rqst.crtd_by IS '등록자 ID';
COMMENT ON COLUMN data_rqst.updtd_at IS '수정일시';
COMMENT ON COLUMN data_rqst.updtd_by IS '수정자 ID';

-- rqst_atch
COMMENT ON TABLE  rqst_atch IS '데이터 신청 첨부파일';
COMMENT ON COLUMN rqst_atch.atch_id IS '첨부 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN rqst_atch.rqst_id IS '신청 FK → data_rqst';
COMMENT ON COLUMN rqst_atch.file_nm IS '파일명';
COMMENT ON COLUMN rqst_atch.file_path IS '파일 저장 경로';
COMMENT ON COLUMN rqst_atch.file_size IS '파일 크기 (바이트)';
COMMENT ON COLUMN rqst_atch.mime_ty IS 'MIME 타입';
COMMENT ON COLUMN rqst_atch.crtd_at IS '등록일시';
COMMENT ON COLUMN rqst_atch.crtd_by IS '등록자 ID';
COMMENT ON COLUMN rqst_atch.updtd_at IS '수정일시';
COMMENT ON COLUMN rqst_atch.updtd_by IS '수정자 ID';

-- rqst_tmln
COMMENT ON TABLE  rqst_tmln IS '신청 처리이력 추적 (워크플로우 타임라인)';
COMMENT ON COLUMN rqst_tmln.tmln_id IS '타임라인 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN rqst_tmln.rqst_id IS '신청 FK → data_rqst';
COMMENT ON COLUMN rqst_tmln.actn_ty IS '작업 유형: submit/review/approve/reject/revise/cancel';
COMMENT ON COLUMN rqst_tmln.stat IS '처리 후 승인 상태';
COMMENT ON COLUMN rqst_tmln.actr_usr_id IS '처리자 FK → usr_acnt';
COMMENT ON COLUMN rqst_tmln.cm IS '처리 의견';
COMMENT ON COLUMN rqst_tmln.actn_dt IS '처리 일시';
COMMENT ON COLUMN rqst_tmln.crtd_at IS '등록일시';
COMMENT ON COLUMN rqst_tmln.crtd_by IS '등록자 ID';
COMMENT ON COLUMN rqst_tmln.updtd_at IS '수정일시';
COMMENT ON COLUMN rqst_tmln.updtd_by IS '수정자 ID';

-- chart_cntnt
COMMENT ON TABLE  chart_cntnt IS '시각화 차트 콘텐츠';
COMMENT ON COLUMN chart_cntnt.chart_id IS '차트 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN chart_cntnt.chart_nm IS '차트명';
COMMENT ON COLUMN chart_cntnt.chart_ty IS '차트 유형: bar/line/pie/scatter/heatmap/map/sankey';
COMMENT ON COLUMN chart_cntnt.dc IS '차트 설명';
COMMENT ON COLUMN chart_cntnt.cnfg IS '차트 설정 (JSON, 축/범례/색상 등)';
COMMENT ON COLUMN chart_cntnt.data_src IS '데이터 소스 (쿼리 또는 API URL)';
COMMENT ON COLUMN chart_cntnt.thumb_url IS '썸네일 이미지 URL';
COMMENT ON COLUMN chart_cntnt.domn_id IS '비즈니스 도메인 FK → domn';
COMMENT ON COLUMN chart_cntnt.owner_usr_id IS '소유자 FK → usr_acnt';
COMMENT ON COLUMN chart_cntnt.is_public IS '공개 여부';
COMMENT ON COLUMN chart_cntnt.view_co IS '조회 수';
COMMENT ON COLUMN chart_cntnt.stat IS '차트 상태';
COMMENT ON COLUMN chart_cntnt.crtd_at IS '등록일시';
COMMENT ON COLUMN chart_cntnt.crtd_by IS '등록자 ID';
COMMENT ON COLUMN chart_cntnt.updtd_at IS '수정일시';
COMMENT ON COLUMN chart_cntnt.updtd_by IS '수정자 ID';

-- extn_prvsn
COMMENT ON TABLE  extn_prvsn IS '외부 기관 데이터 제공 현황';
COMMENT ON COLUMN extn_prvsn.prvsn_id IS '제공 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN extn_prvsn.prvsn_nm IS '제공명';
COMMENT ON COLUMN extn_prvsn.trget_org IS '대상 기관명';
COMMENT ON COLUMN extn_prvsn.dset_id IS '데이터셋 FK → dset';
COMMENT ON COLUMN extn_prvsn.product_id IS 'Product FK → data_product';
COMMENT ON COLUMN extn_prvsn.prvsn_ty IS '제공 유형: api/file/db_link/portal';
COMMENT ON COLUMN extn_prvsn.freq IS '제공 주기: daily/weekly/monthly/on_demand';
COMMENT ON COLUMN extn_prvsn.rcrd_co IS '제공 레코드 수';
COMMENT ON COLUMN extn_prvsn.last_prvdd IS '최종 제공 일시';
COMMENT ON COLUMN extn_prvsn.cntrct_strt IS '계약 시작일';
COMMENT ON COLUMN extn_prvsn.cntrct_end IS '계약 종료일';
COMMENT ON COLUMN extn_prvsn.stat IS '제공 상태';
COMMENT ON COLUMN extn_prvsn.crtd_at IS '등록일시';
COMMENT ON COLUMN extn_prvsn.crtd_by IS '등록자 ID';
COMMENT ON COLUMN extn_prvsn.updtd_at IS '수정일시';
COMMENT ON COLUMN extn_prvsn.updtd_by IS '수정자 ID';


-- ============================================================================
-- 5. 데이터 품질
-- ============================================================================

-- dq_rule
COMMENT ON TABLE  dq_rule IS '데이터 품질 검증 규칙';
COMMENT ON COLUMN dq_rule.rule_id IS '규칙 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN dq_rule.rule_nm IS '규칙명';
COMMENT ON COLUMN dq_rule.rule_cd IS '규칙코드 (유니크)';
COMMENT ON COLUMN dq_rule.rule_ty IS '품질 차원: completeness/accuracy/consistency/timeliness/validity/uniqueness';
COMMENT ON COLUMN dq_rule.dset_id IS '대상 데이터셋 FK → dset';
COMMENT ON COLUMN dq_rule.col_nm IS '대상 컬럼명';
COMMENT ON COLUMN dq_rule.expr IS '검증식 (SQL WHERE 조건 등)';
COMMENT ON COLUMN dq_rule.thrhld IS '품질 임계값 (%), 이하 시 경고/오류';
COMMENT ON COLUMN dq_rule.svrt IS '심각도: info/warning/critical';
COMMENT ON COLUMN dq_rule.dc IS '규칙 설명';
COMMENT ON COLUMN dq_rule.is_actv IS '활성 여부';
COMMENT ON COLUMN dq_rule.crtd_at IS '등록일시';
COMMENT ON COLUMN dq_rule.crtd_by IS '등록자 ID';
COMMENT ON COLUMN dq_rule.updtd_at IS '수정일시';
COMMENT ON COLUMN dq_rule.updtd_by IS '수정자 ID';

-- dq_exec
COMMENT ON TABLE  dq_exec IS '데이터 품질 검증 실행 결과';
COMMENT ON COLUMN dq_exec.exec_id IS '실행 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN dq_exec.rule_id IS '품질규칙 FK → dq_rule';
COMMENT ON COLUMN dq_exec.dset_id IS '데이터셋 FK → dset';
COMMENT ON COLUMN dq_exec.exec_dt IS '실행 일자';
COMMENT ON COLUMN dq_exec.tot_rows IS '전체 행 수';
COMMENT ON COLUMN dq_exec.passd_rows IS '합격 행 수';
COMMENT ON COLUMN dq_exec.faild_rows IS '불합격 행 수';
COMMENT ON COLUMN dq_exec.score IS '합격률 (%)';
COMMENT ON COLUMN dq_exec.rst IS '결과: pass/fail/error/skip';
COMMENT ON COLUMN dq_exec.err_msg IS '오류 메시지';
COMMENT ON COLUMN dq_exec.exec_tm_ms IS '실행 소요시간 (ms)';
COMMENT ON COLUMN dq_exec.crtd_at IS '등록일시';
COMMENT ON COLUMN dq_exec.crtd_by IS '등록자 ID';
COMMENT ON COLUMN dq_exec.updtd_at IS '수정일시';
COMMENT ON COLUMN dq_exec.updtd_by IS '수정자 ID';

-- domn_qlity_score
COMMENT ON TABLE  domn_qlity_score IS '도메인별 일별 품질 점수 집계';
COMMENT ON COLUMN domn_qlity_score.score_id IS '점수 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN domn_qlity_score.domn_id IS '도메인 FK → domn';
COMMENT ON COLUMN domn_qlity_score.score_dt IS '집계 일자';
COMMENT ON COLUMN domn_qlity_score.cmpltn IS '완전성 점수 (%)';
COMMENT ON COLUMN domn_qlity_score.accrcy IS '정확성 점수 (%)';
COMMENT ON COLUMN domn_qlity_score.cnstnc IS '일관성 점수 (%)';
COMMENT ON COLUMN domn_qlity_score.tmlns IS '적시성 점수 (%)';
COMMENT ON COLUMN domn_qlity_score.valid IS '유효성 점수 (%)';
COMMENT ON COLUMN domn_qlity_score.uqe IS '유일성 점수 (%)';
COMMENT ON COLUMN domn_qlity_score.ovrall_score IS '종합 점수 (%)';
COMMENT ON COLUMN domn_qlity_score.dset_co IS '대상 데이터셋 수';
COMMENT ON COLUMN domn_qlity_score.rule_co IS '적용 규칙 수';
COMMENT ON COLUMN domn_qlity_score.crtd_at IS '등록일시';
COMMENT ON COLUMN domn_qlity_score.crtd_by IS '등록자 ID';
COMMENT ON COLUMN domn_qlity_score.updtd_at IS '수정일시';
COMMENT ON COLUMN domn_qlity_score.updtd_by IS '수정자 ID';

-- qlity_issue
COMMENT ON TABLE  qlity_issue IS '데이터 품질 이슈 관리';
COMMENT ON COLUMN qlity_issue.issue_id IS '이슈 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN qlity_issue.dset_id IS '데이터셋 FK → dset';
COMMENT ON COLUMN qlity_issue.rule_id IS '품질규칙 FK → dq_rule';
COMMENT ON COLUMN qlity_issue.issue_ty IS '이슈 유형: missing_data/outlier/format_error/duplicate/referential';
COMMENT ON COLUMN qlity_issue.svrt IS '심각도: info/warning/critical';
COMMENT ON COLUMN qlity_issue.col_nm IS '대상 컬럼명';
COMMENT ON COLUMN qlity_issue.afctd_rows IS '영향 행 수';
COMMENT ON COLUMN qlity_issue.dc IS '이슈 설명';
COMMENT ON COLUMN qlity_issue.rsln IS '해결 방안/결과';
COMMENT ON COLUMN qlity_issue.stat IS '이슈 상태: open/investigating/resolved/ignored';
COMMENT ON COLUMN qlity_issue.asgnd_to IS '담당자 FK → usr_acnt';
COMMENT ON COLUMN qlity_issue.rslvd_at IS '해결 일시';
COMMENT ON COLUMN qlity_issue.crtd_at IS '등록일시';
COMMENT ON COLUMN qlity_issue.crtd_by IS '등록자 ID';
COMMENT ON COLUMN qlity_issue.updtd_at IS '수정일시';
COMMENT ON COLUMN qlity_issue.updtd_by IS '수정자 ID';


-- ============================================================================
-- 6. 온톨로지
-- ============================================================================

-- onto_class
COMMENT ON TABLE  onto_class IS '온톨로지 클래스 (지식그래프 노드 유형)';
COMMENT ON COLUMN onto_class.class_id IS '클래스 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN onto_class.class_nm_ko IS '클래스명 (한글)';
COMMENT ON COLUMN onto_class.class_nm_en IS '클래스명 (영문)';
COMMENT ON COLUMN onto_class.class_uri IS 'URI (예: kw:Dam, kw:WaterTreatmentPlant)';
COMMENT ON COLUMN onto_class.parent_class_id IS '상위 클래스 FK → onto_class (자기참조)';
COMMENT ON COLUMN onto_class.dc IS '클래스 설명';
COMMENT ON COLUMN onto_class.instn_co IS '인스턴스 수';
COMMENT ON COLUMN onto_class.icon IS '아이콘명';
COMMENT ON COLUMN onto_class.color IS 'HEX 색상코드';
COMMENT ON COLUMN onto_class.sort_ord IS '정렬 순서';
COMMENT ON COLUMN onto_class.crtd_at IS '등록일시';
COMMENT ON COLUMN onto_class.crtd_by IS '등록자 ID';
COMMENT ON COLUMN onto_class.updtd_at IS '수정일시';
COMMENT ON COLUMN onto_class.updtd_by IS '수정자 ID';

-- onto_data_prprty
COMMENT ON TABLE  onto_data_prprty IS '온톨로지 데이터 속성 (클래스의 필드)';
COMMENT ON COLUMN onto_data_prprty.prprty_id IS '속성 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN onto_data_prprty.class_id IS '소속 클래스 FK → onto_class';
COMMENT ON COLUMN onto_data_prprty.prprty_nm IS '속성명';
COMMENT ON COLUMN onto_data_prprty.prprty_uri IS '속성 URI';
COMMENT ON COLUMN onto_data_prprty.data_ty IS '데이터 타입 (xsd:string, xsd:decimal 등)';
COMMENT ON COLUMN onto_data_prprty.crdnlt IS '카디널리티: 1/0..1/0..*/1..*';
COMMENT ON COLUMN onto_data_prprty.unit IS '단위';
COMMENT ON COLUMN onto_data_prprty.std_term_id IS '표준용어 FK → glsry_term';
COMMENT ON COLUMN onto_data_prprty.dc IS '속성 설명';
COMMENT ON COLUMN onto_data_prprty.sort_ord IS '정렬 순서';
COMMENT ON COLUMN onto_data_prprty.crtd_at IS '등록일시';
COMMENT ON COLUMN onto_data_prprty.crtd_by IS '등록자 ID';
COMMENT ON COLUMN onto_data_prprty.updtd_at IS '수정일시';
COMMENT ON COLUMN onto_data_prprty.updtd_by IS '수정자 ID';

-- onto_rel
COMMENT ON TABLE  onto_rel IS '온톨로지 클래스 간 관계 (지식그래프 엣지)';
COMMENT ON COLUMN onto_rel.rel_id IS '관계 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN onto_rel.src_class_id IS '출발 클래스 FK → onto_class';
COMMENT ON COLUMN onto_rel.trget_class_id IS '도착 클래스 FK → onto_class';
COMMENT ON COLUMN onto_rel.rel_nm_ko IS '관계명 (한글)';
COMMENT ON COLUMN onto_rel.rel_nm_en IS '관계명 (영문)';
COMMENT ON COLUMN onto_rel.rel_uri IS '관계 URI';
COMMENT ON COLUMN onto_rel.crdnlt IS '카디널리티';
COMMENT ON COLUMN onto_rel.drct IS '방향: output/input/bidirectional';
COMMENT ON COLUMN onto_rel.dc IS '관계 설명';
COMMENT ON COLUMN onto_rel.sort_ord IS '정렬 순서';
COMMENT ON COLUMN onto_rel.crtd_at IS '등록일시';
COMMENT ON COLUMN onto_rel.crtd_by IS '등록자 ID';
COMMENT ON COLUMN onto_rel.updtd_at IS '수정일시';
COMMENT ON COLUMN onto_rel.updtd_by IS '수정자 ID';


-- ============================================================================
-- 7. 모니터링
-- ============================================================================

-- regn
COMMENT ON TABLE  regn IS '유역/지사 (한강, 낙동강, 금강, 영산강·섬진강 등)';
COMMENT ON COLUMN regn.regn_id IS '유역 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN regn.regn_cd IS '유역코드 (유니크)';
COMMENT ON COLUMN regn.regn_nm IS '유역명 (한글)';
COMMENT ON COLUMN regn.sort_ord IS '정렬 순서';
COMMENT ON COLUMN regn.crtd_at IS '등록일시';
COMMENT ON COLUMN regn.crtd_by IS '등록자 ID';
COMMENT ON COLUMN regn.updtd_at IS '수정일시';
COMMENT ON COLUMN regn.updtd_by IS '수정자 ID';

-- office
COMMENT ON TABLE  office IS '사무소/관리단';
COMMENT ON COLUMN office.office_id IS '사무소 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN office.regn_id IS '유역 FK → regn';
COMMENT ON COLUMN office.office_cd IS '사무소코드 (유니크)';
COMMENT ON COLUMN office.office_nm IS '사무소명 (한글)';
COMMENT ON COLUMN office.addr IS '주소';
COMMENT ON COLUMN office.sort_ord IS '정렬 순서';
COMMENT ON COLUMN office.crtd_at IS '등록일시';
COMMENT ON COLUMN office.crtd_by IS '등록자 ID';
COMMENT ON COLUMN office.updtd_at IS '수정일시';
COMMENT ON COLUMN office.updtd_by IS '수정자 ID';

-- site
COMMENT ON TABLE  site IS '사업장/현장 (댐, 정수장, 하수처리장 등)';
COMMENT ON COLUMN site.site_id IS '사업장 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN site.office_id IS '사무소 FK → office';
COMMENT ON COLUMN site.site_cd IS '사업장코드 (유니크)';
COMMENT ON COLUMN site.site_nm IS '사업장명 (한글)';
COMMENT ON COLUMN site.site_ty IS '시설 유형: dam/reservoir/water_plant/sewage_plant/weir';
COMMENT ON COLUMN site.la IS '위도';
COMMENT ON COLUMN site.lngt IS '경도';
COMMENT ON COLUMN site.addr IS '주소';
COMMENT ON COLUMN site.cpcty IS '시설 용량 (댐 저수량, 정수장 처리량 등)';
COMMENT ON COLUMN site.stat IS '사업장 상태';
COMMENT ON COLUMN site.crtd_at IS '등록일시';
COMMENT ON COLUMN site.crtd_by IS '등록자 ID';
COMMENT ON COLUMN site.updtd_at IS '수정일시';
COMMENT ON COLUMN site.updtd_by IS '수정자 ID';

-- sensor_tag
COMMENT ON TABLE  sensor_tag IS '센서 태그 메타데이터 (실측값은 원천시스템에 저장)';
COMMENT ON COLUMN sensor_tag.tag_id IS '센서태그 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN sensor_tag.site_id IS '사업장 FK → site';
COMMENT ON COLUMN sensor_tag.sensor_cd IS '센서코드 (유니크)';
COMMENT ON COLUMN sensor_tag.sensor_nm IS '센서명';
COMMENT ON COLUMN sensor_tag.sensor_ty IS '센서 유형: water_level/flow/quality/temperature/pressure';
COMMENT ON COLUMN sensor_tag.unit IS '측정 단위 (m, ㎥/s, mg/L, ℃, kPa)';
COMMENT ON COLUMN sensor_tag.min_rng IS '측정 범위 최솟값';
COMMENT ON COLUMN sensor_tag.max_rng IS '측정 범위 최댓값';
COMMENT ON COLUMN sensor_tag.instl_dt IS '설치일';
COMMENT ON COLUMN sensor_tag.last_readng IS '최신 측정값 캐시 (실시간 조회용)';
COMMENT ON COLUMN sensor_tag.last_read_at IS '최신 측정 시각';
COMMENT ON COLUMN sensor_tag.stat IS '센서 상태';
COMMENT ON COLUMN sensor_tag.crtd_at IS '등록일시';
COMMENT ON COLUMN sensor_tag.crtd_by IS '등록자 ID';
COMMENT ON COLUMN sensor_tag.updtd_at IS '수정일시';
COMMENT ON COLUMN sensor_tag.updtd_by IS '수정자 ID';

-- asset_db
COMMENT ON TABLE  asset_db IS '자산DB 현황 (시설물 자산 유형별 집계)';
COMMENT ON COLUMN asset_db.asset_db_id IS '자산DB 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN asset_db.asset_ty IS '자산 유형: dam/reservoir/pipeline/pump/valve/instrument';
COMMENT ON COLUMN asset_db.asset_nm IS '자산명';
COMMENT ON COLUMN asset_db.tot_co IS '전체 수량';
COMMENT ON COLUMN asset_db.actv_co IS '가동 수량';
COMMENT ON COLUMN asset_db.src_sys IS '원천시스템명';
COMMENT ON COLUMN asset_db.last_sync_at IS '최종 동기화 일시';
COMMENT ON COLUMN asset_db.dc IS '자산 설명';
COMMENT ON COLUMN asset_db.crtd_at IS '등록일시';
COMMENT ON COLUMN asset_db.crtd_by IS '등록자 ID';
COMMENT ON COLUMN asset_db.updtd_at IS '수정일시';
COMMENT ON COLUMN asset_db.updtd_by IS '수정자 ID';


-- ============================================================================
-- 8. 커뮤니티·소통
-- ============================================================================

-- board_post
COMMENT ON TABLE  board_post IS '게시판 (공지사항/내부/외부)';
COMMENT ON COLUMN board_post.post_id IS '게시글 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN board_post.usr_id IS '작성자 FK → usr_acnt';
COMMENT ON COLUMN board_post.tit IS '제목';
COMMENT ON COLUMN board_post.cntnt IS '본문 내용';
COMMENT ON COLUMN board_post.post_ty IS '게시판 유형: notice/internal/external';
COMMENT ON COLUMN board_post.is_pinnd IS '상단 고정 여부';
COMMENT ON COLUMN board_post.view_co IS '조회 수';
COMMENT ON COLUMN board_post.like_co IS '좋아요 수';
COMMENT ON COLUMN board_post.cm_co IS '댓글 수';
COMMENT ON COLUMN board_post.stat IS '게시글 상태';
COMMENT ON COLUMN board_post.crtd_at IS '등록일시';
COMMENT ON COLUMN board_post.crtd_by IS '등록자 ID';
COMMENT ON COLUMN board_post.updtd_at IS '수정일시';
COMMENT ON COLUMN board_post.updtd_by IS '수정자 ID';

-- board_cm
COMMENT ON TABLE  board_cm IS '게시판 댓글 (대댓글 지원)';
COMMENT ON COLUMN board_cm.cm_id IS '댓글 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN board_cm.post_id IS '게시글 FK → board_post';
COMMENT ON COLUMN board_cm.usr_id IS '작성자 FK → usr_acnt';
COMMENT ON COLUMN board_cm.parent_id IS '상위 댓글 FK → board_cm (대댓글)';
COMMENT ON COLUMN board_cm.cm_text IS '댓글 내용';
COMMENT ON COLUMN board_cm.stat IS '댓글 상태';
COMMENT ON COLUMN board_cm.crtd_at IS '등록일시';
COMMENT ON COLUMN board_cm.crtd_by IS '등록자 ID';
COMMENT ON COLUMN board_cm.updtd_at IS '수정일시';
COMMENT ON COLUMN board_cm.updtd_by IS '수정자 ID';

-- resrce_archv
COMMENT ON TABLE  resrce_archv IS '자료실 (매뉴얼, 템플릿, 보고서 등)';
COMMENT ON COLUMN resrce_archv.resrce_id IS '자료 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN resrce_archv.usr_id IS '등록자 FK → usr_acnt';
COMMENT ON COLUMN resrce_archv.resrce_nm IS '자료명';
COMMENT ON COLUMN resrce_archv.dc IS '자료 설명';
COMMENT ON COLUMN resrce_archv.file_nm IS '파일명';
COMMENT ON COLUMN resrce_archv.file_path IS '파일 저장 경로';
COMMENT ON COLUMN resrce_archv.file_size IS '파일 크기 (바이트)';
COMMENT ON COLUMN resrce_archv.mime_ty IS 'MIME 타입';
COMMENT ON COLUMN resrce_archv.ctgry IS '카테고리: manual/template/report/guide/regulation';
COMMENT ON COLUMN resrce_archv.dwld_co IS '다운로드 수';
COMMENT ON COLUMN resrce_archv.stat IS '자료 상태';
COMMENT ON COLUMN resrce_archv.crtd_at IS '등록일시';
COMMENT ON COLUMN resrce_archv.crtd_by IS '등록자 ID';
COMMENT ON COLUMN resrce_archv.updtd_at IS '수정일시';
COMMENT ON COLUMN resrce_archv.updtd_by IS '수정자 ID';


-- ============================================================================
-- 9. 시스템관리
-- ============================================================================

-- scrty_polcy
COMMENT ON TABLE  scrty_polcy IS '보안 정책 (접근제어, 암호화, 감사 등)';
COMMENT ON COLUMN scrty_polcy.polcy_id IS '정책 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN scrty_polcy.polcy_nm IS '정책명';
COMMENT ON COLUMN scrty_polcy.polcy_ty IS '정책 유형: access_control/encryption/audit/password/network';
COMMENT ON COLUMN scrty_polcy.dc IS '정책 설명';
COMMENT ON COLUMN scrty_polcy.rule_cnfg IS '정책 규칙 (JSON)';
COMMENT ON COLUMN scrty_polcy.trget_lvl IS '적용 대상 보안등급';
COMMENT ON COLUMN scrty_polcy.is_actv IS '활성 여부';
COMMENT ON COLUMN scrty_polcy.eftv_from IS '시행 시작일';
COMMENT ON COLUMN scrty_polcy.eftv_to IS '시행 종료일';
COMMENT ON COLUMN scrty_polcy.crtd_at IS '등록일시';
COMMENT ON COLUMN scrty_polcy.crtd_by IS '등록자 ID';
COMMENT ON COLUMN scrty_polcy.updtd_at IS '수정일시';
COMMENT ON COLUMN scrty_polcy.updtd_by IS '수정자 ID';

-- sys_intrfc
COMMENT ON TABLE  sys_intrfc IS '시스템 인터페이스 정의 및 모니터링';
COMMENT ON COLUMN sys_intrfc.intrfc_id IS '인터페이스 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN sys_intrfc.intrfc_cd IS '인터페이스코드 (유니크)';
COMMENT ON COLUMN sys_intrfc.intrfc_nm IS '인터페이스명';
COMMENT ON COLUMN sys_intrfc.src_sys_id IS '송신시스템 FK → src_sys';
COMMENT ON COLUMN sys_intrfc.trget_sys_id IS '수신시스템 FK → src_sys';
COMMENT ON COLUMN sys_intrfc.intrfc_ty IS '인터페이스 유형: api/db_link/file/mq/mcp';
COMMENT ON COLUMN sys_intrfc.prtcl IS '통신 프로토콜';
COMMENT ON COLUMN sys_intrfc.freq IS '연계 주기: realtime/hourly/daily/weekly/monthly/on_demand';
COMMENT ON COLUMN sys_intrfc.drct IS '방향: inbound/outbound/bidirectional';
COMMENT ON COLUMN sys_intrfc.last_succes_at IS '최종 성공 일시';
COMMENT ON COLUMN sys_intrfc.last_fail_at IS '최종 실패 일시';
COMMENT ON COLUMN sys_intrfc.succes_rt IS '성공률 (%)';
COMMENT ON COLUMN sys_intrfc.avg_rspns_ms IS '평균 응답시간 (ms)';
COMMENT ON COLUMN sys_intrfc.stat IS '인터페이스 상태';
COMMENT ON COLUMN sys_intrfc.crtd_at IS '등록일시';
COMMENT ON COLUMN sys_intrfc.crtd_by IS '등록자 ID';
COMMENT ON COLUMN sys_intrfc.updtd_at IS '수정일시';
COMMENT ON COLUMN sys_intrfc.updtd_by IS '수정자 ID';

-- audit_log
COMMENT ON TABLE  audit_log IS '감사 로그 (모든 사용자 작업 추적)';
COMMENT ON COLUMN audit_log.log_id IS '로그 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN audit_log.usr_id IS '사용자 FK → usr_acnt';
COMMENT ON COLUMN audit_log.usr_nm IS '사용자명 (비정규화)';
COMMENT ON COLUMN audit_log.actn_ty IS '작업 유형: login/logout/create/read/update/delete/download/approve/export';
COMMENT ON COLUMN audit_log.trget_table IS '대상 테이블명';
COMMENT ON COLUMN audit_log.trget_id IS '대상 레코드 ID';
COMMENT ON COLUMN audit_log.actn_dtl IS '작업 상세 내용';
COMMENT ON COLUMN audit_log.ip_addr IS '접속 IP 주소';
COMMENT ON COLUMN audit_log.usr_agent IS '브라우저 User-Agent';
COMMENT ON COLUMN audit_log.rst IS '결과: success/fail/denied';
COMMENT ON COLUMN audit_log.crtd_at IS '등록일시';
COMMENT ON COLUMN audit_log.crtd_by IS '등록자 ID';
COMMENT ON COLUMN audit_log.updtd_at IS '수정일시';
COMMENT ON COLUMN audit_log.updtd_by IS '수정자 ID';

-- ntcn
COMMENT ON TABLE  ntcn IS '사용자 알림';
COMMENT ON COLUMN ntcn.ntcn_id IS '알림 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN ntcn.usr_id IS '수신자 FK → usr_acnt';
COMMENT ON COLUMN ntcn.ntcn_ty IS '알림 유형: system/approval/quality/security/pipeline';
COMMENT ON COLUMN ntcn.tit IS '알림 제목';
COMMENT ON COLUMN ntcn.msg IS '알림 내용';
COMMENT ON COLUMN ntcn.link_url IS '관련 화면 링크';
COMMENT ON COLUMN ntcn.is_read IS '읽음 여부';
COMMENT ON COLUMN ntcn.read_at IS '읽은 일시';
COMMENT ON COLUMN ntcn.crtd_at IS '등록일시';
COMMENT ON COLUMN ntcn.crtd_by IS '등록자 ID';
COMMENT ON COLUMN ntcn.updtd_at IS '수정일시';
COMMENT ON COLUMN ntcn.updtd_by IS '수정자 ID';

-- widg_tmplat
COMMENT ON TABLE  widg_tmplat IS '대시보드 위젯 템플릿';
COMMENT ON COLUMN widg_tmplat.widg_id IS '위젯 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN widg_tmplat.widg_cd IS '위젯코드 (유니크)';
COMMENT ON COLUMN widg_tmplat.widg_nm IS '위젯명';
COMMENT ON COLUMN widg_tmplat.widg_ty IS '위젯 유형: kpi/chart/table/map/timeline/calendar';
COMMENT ON COLUMN widg_tmplat.dc IS '위젯 설명';
COMMENT ON COLUMN widg_tmplat.cnfg_json IS '기본 설정 (JSON, 차트유형/데이터소스 등)';
COMMENT ON COLUMN widg_tmplat.thumb_url IS '썸네일 이미지 URL';
COMMENT ON COLUMN widg_tmplat.min_width IS '최소 너비 (그리드 단위)';
COMMENT ON COLUMN widg_tmplat.min_hg IS '최소 높이 (그리드 단위)';
COMMENT ON COLUMN widg_tmplat.max_width IS '최대 너비 (그리드 단위)';
COMMENT ON COLUMN widg_tmplat.max_hg IS '최대 높이 (그리드 단위)';
COMMENT ON COLUMN widg_tmplat.ctgry IS '카테고리: dashboard/quality/collect/distribute/system';
COMMENT ON COLUMN widg_tmplat.is_actv IS '활성 여부';
COMMENT ON COLUMN widg_tmplat.crtd_at IS '등록일시';
COMMENT ON COLUMN widg_tmplat.crtd_by IS '등록자 ID';
COMMENT ON COLUMN widg_tmplat.updtd_at IS '수정일시';
COMMENT ON COLUMN widg_tmplat.updtd_by IS '수정자 ID';

-- usr_widg_layout
COMMENT ON TABLE  usr_widg_layout IS '사용자별 위젯 배치 (개인화 대시보드)';
COMMENT ON COLUMN usr_widg_layout.layout_id IS '배치 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN usr_widg_layout.usr_id IS '사용자 FK → usr_acnt';
COMMENT ON COLUMN usr_widg_layout.widg_id IS '위젯 FK → widg_tmplat';
COMMENT ON COLUMN usr_widg_layout.positn_x IS 'X 위치 (그리드)';
COMMENT ON COLUMN usr_widg_layout.positn_y IS 'Y 위치 (그리드)';
COMMENT ON COLUMN usr_widg_layout.width IS '너비 (그리드 단위)';
COMMENT ON COLUMN usr_widg_layout.hg IS '높이 (그리드 단위)';
COMMENT ON COLUMN usr_widg_layout.cnfg_ovrd IS '사용자 개인 설정 오버라이드 (JSON)';
COMMENT ON COLUMN usr_widg_layout.is_vsbl IS '표시 여부';
COMMENT ON COLUMN usr_widg_layout.sort_ord IS '정렬 순서';
COMMENT ON COLUMN usr_widg_layout.crtd_at IS '등록일시';
COMMENT ON COLUMN usr_widg_layout.crtd_by IS '등록자 ID';
COMMENT ON COLUMN usr_widg_layout.updtd_at IS '수정일시';
COMMENT ON COLUMN usr_widg_layout.updtd_by IS '수정자 ID';

-- lnage_node
COMMENT ON TABLE  lnage_node IS '데이터 리니지 노드 (계보 추적 대상)';
COMMENT ON COLUMN lnage_node.node_id IS '노드 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN lnage_node.node_ty IS '노드 유형: dataset/table/column/pipeline/system/product';
COMMENT ON COLUMN lnage_node.obj_id IS '대상 객체 ID (UUID 또는 코드)';
COMMENT ON COLUMN lnage_node.obj_nm IS '대상 객체명';
COMMENT ON COLUMN lnage_node.dc IS '노드 설명';
COMMENT ON COLUMN lnage_node.mtdata IS '추가 메타 정보 (JSON)';
COMMENT ON COLUMN lnage_node.crtd_at IS '등록일시';
COMMENT ON COLUMN lnage_node.crtd_by IS '등록자 ID';
COMMENT ON COLUMN lnage_node.updtd_at IS '수정일시';
COMMENT ON COLUMN lnage_node.updtd_by IS '수정자 ID';

-- lnage_edge
COMMENT ON TABLE  lnage_edge IS '데이터 리니지 엣지 (계보 흐름)';
COMMENT ON COLUMN lnage_edge.edge_id IS '엣지 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN lnage_edge.src_node_id IS '출발 노드 FK → lnage_node';
COMMENT ON COLUMN lnage_edge.trget_node_id IS '도착 노드 FK → lnage_node';
COMMENT ON COLUMN lnage_edge.edge_ty IS '엣지 유형: transform/derive/copy/aggregate/filter';
COMMENT ON COLUMN lnage_edge.trsfmn IS '변환 설명';
COMMENT ON COLUMN lnage_edge.ppln_id IS '파이프라인 FK → ppln';
COMMENT ON COLUMN lnage_edge.crtd_at IS '등록일시';
COMMENT ON COLUMN lnage_edge.crtd_by IS '등록자 ID';
COMMENT ON COLUMN lnage_edge.updtd_at IS '수정일시';
COMMENT ON COLUMN lnage_edge.updtd_by IS '수정자 ID';

-- ai_chat_sesn
COMMENT ON TABLE  ai_chat_sesn IS 'AI/LLM 대화 세션';
COMMENT ON COLUMN ai_chat_sesn.sesn_id IS '세션 고유 ID (PK, UUID)';
COMMENT ON COLUMN ai_chat_sesn.usr_id IS '사용자 FK → usr_acnt';
COMMENT ON COLUMN ai_chat_sesn.sesn_tit IS '세션 제목';
COMMENT ON COLUMN ai_chat_sesn.model_nm IS '사용 모델명';
COMMENT ON COLUMN ai_chat_sesn.msg_co IS '메시지 수';
COMMENT ON COLUMN ai_chat_sesn.is_archvd IS '보관 여부';
COMMENT ON COLUMN ai_chat_sesn.crtd_at IS '등록일시';
COMMENT ON COLUMN ai_chat_sesn.crtd_by IS '등록자 ID';
COMMENT ON COLUMN ai_chat_sesn.updtd_at IS '수정일시';
COMMENT ON COLUMN ai_chat_sesn.updtd_by IS '수정자 ID';

-- ai_chat_msg
COMMENT ON TABLE  ai_chat_msg IS 'AI 대화 메시지 (질문/응답)';
COMMENT ON COLUMN ai_chat_msg.msg_id IS '메시지 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN ai_chat_msg.sesn_id IS '세션 FK → ai_chat_sesn';
COMMENT ON COLUMN ai_chat_msg.role IS '발화자: user/assistant/system';
COMMENT ON COLUMN ai_chat_msg.msg_text IS '메시지 내용';
COMMENT ON COLUMN ai_chat_msg.tkns_used IS '사용 토큰 수';
COMMENT ON COLUMN ai_chat_msg.rspns_ms IS '응답 소요시간 (ms)';
COMMENT ON COLUMN ai_chat_msg.mtdata IS '참조 데이터셋/검색 컨텍스트 등 (JSON)';
COMMENT ON COLUMN ai_chat_msg.crtd_at IS '등록일시';
COMMENT ON COLUMN ai_chat_msg.crtd_by IS '등록자 ID';
COMMENT ON COLUMN ai_chat_msg.updtd_at IS '수정일시';
COMMENT ON COLUMN ai_chat_msg.updtd_by IS '수정자 ID';

-- daly_dist_stats
COMMENT ON TABLE  daly_dist_stats IS '일별 Data Product 유통 통계';
COMMENT ON COLUMN daly_dist_stats.stat_id IS '통계 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN daly_dist_stats.stat_dt IS '통계 일자';
COMMENT ON COLUMN daly_dist_stats.product_id IS 'Product FK → data_product';
COMMENT ON COLUMN daly_dist_stats.tot_calls IS '총 호출 수';
COMMENT ON COLUMN daly_dist_stats.succes_calls IS '성공 호출 수';
COMMENT ON COLUMN daly_dist_stats.fail_calls IS '실패 호출 수';
COMMENT ON COLUMN daly_dist_stats.avg_rspns_ms IS '평균 응답시간 (ms)';
COMMENT ON COLUMN daly_dist_stats.unique_usrs IS '고유 사용자 수';
COMMENT ON COLUMN daly_dist_stats.data_vlm_mb IS '데이터 전송량 (MB)';
COMMENT ON COLUMN daly_dist_stats.crtd_at IS '등록일시';
COMMENT ON COLUMN daly_dist_stats.crtd_by IS '등록자 ID';
COMMENT ON COLUMN daly_dist_stats.updtd_at IS '수정일시';
COMMENT ON COLUMN daly_dist_stats.updtd_by IS '수정자 ID';

-- dept_usg_stats
COMMENT ON TABLE  dept_usg_stats IS '부서별 일별 활용 통계';
COMMENT ON COLUMN dept_usg_stats.stat_id IS '통계 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN dept_usg_stats.stat_dt IS '통계 일자';
COMMENT ON COLUMN dept_usg_stats.dept_id IS '부서 FK → dept';
COMMENT ON COLUMN dept_usg_stats.dset_co IS '활용 데이터셋 수';
COMMENT ON COLUMN dept_usg_stats.api_calls IS 'API 호출 수';
COMMENT ON COLUMN dept_usg_stats.dwld_co IS '다운로드 수';
COMMENT ON COLUMN dept_usg_stats.search_co IS '검색 수';
COMMENT ON COLUMN dept_usg_stats.actv_usrs IS '활성 사용자 수';
COMMENT ON COLUMN dept_usg_stats.crtd_at IS '등록일시';
COMMENT ON COLUMN dept_usg_stats.crtd_by IS '등록자 ID';
COMMENT ON COLUMN dept_usg_stats.updtd_at IS '수정일시';
COMMENT ON COLUMN dept_usg_stats.updtd_by IS '수정자 ID';

-- erp_sync_hist
COMMENT ON TABLE  erp_sync_hist IS 'ERP(SAP HR) 동기화 이력 (조직/사용자 정보)';
COMMENT ON COLUMN erp_sync_hist.sync_id IS '동기화 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN erp_sync_hist.sync_ty IS '동기화 유형: user/department/division';
COMMENT ON COLUMN erp_sync_hist.sync_drct IS '동기화 방향: inbound(ERP→포탈)/outbound';
COMMENT ON COLUMN erp_sync_hist.tot_rcrds IS '전체 레코드 수';
COMMENT ON COLUMN erp_sync_hist.crtd_co IS '신규 생성 수';
COMMENT ON COLUMN erp_sync_hist.updtd_co IS '수정 수';
COMMENT ON COLUMN erp_sync_hist.skipd_co IS '건너뜀 수';
COMMENT ON COLUMN erp_sync_hist.err_co IS '오류 수';
COMMENT ON COLUMN erp_sync_hist.strtd_at IS '시작 일시';
COMMENT ON COLUMN erp_sync_hist.fnshed_at IS '종료 일시';
COMMENT ON COLUMN erp_sync_hist.stat IS '동기화 상태: running/success/failed/cancelled';
COMMENT ON COLUMN erp_sync_hist.err_dtl IS '오류 상세 내용';
COMMENT ON COLUMN erp_sync_hist.crtd_at IS '등록일시';
COMMENT ON COLUMN erp_sync_hist.crtd_by IS '등록자 ID';
COMMENT ON COLUMN erp_sync_hist.updtd_at IS '수정일시';
COMMENT ON COLUMN erp_sync_hist.updtd_by IS '수정자 ID';

-- ============================================================================
-- 11-2. DB 복구 로그 관리
-- ============================================================================

-- db_rcvry_log
COMMENT ON TABLE  db_rcvry_log IS 'DB별 복구 로그 이력, 복구 실행·검증 관리';
COMMENT ON COLUMN db_rcvry_log.rcvry_log_id IS '복구 로그 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN db_rcvry_log.asset_db_id IS 'DB 자산 FK → asset_db';
COMMENT ON COLUMN db_rcvry_log.rcvry_ty IS '복구 유형: full/incremental/point_in_time/differential';
COMMENT ON COLUMN db_rcvry_log.stat IS '복구 상태: running/success/failed/cancelled';
COMMENT ON COLUMN db_rcvry_log.strtd_at IS '복구 시작 일시';
COMMENT ON COLUMN db_rcvry_log.fnshed_at IS '복구 종료 일시';
COMMENT ON COLUMN db_rcvry_log.dur_secnd IS '소요 시간 (초)';
COMMENT ON COLUMN db_rcvry_log.bkup_src IS '백업 소스 (S3, NFS, Local 등)';
COMMENT ON COLUMN db_rcvry_log.bkup_dt IS '백업 시점 (복구 기준 시점)';
COMMENT ON COLUMN db_rcvry_log.tot_rcrds IS '전체 레코드 수';
COMMENT ON COLUMN db_rcvry_log.rcvrd_rcrds IS '복구 완료 레코드 수';
COMMENT ON COLUMN db_rcvry_log.err_rcrds IS '오류 레코드 수';
COMMENT ON COLUMN db_rcvry_log.data_sz_mb IS '복구 데이터 용량 (MB)';
COMMENT ON COLUMN db_rcvry_log.exec_usr_id IS '실행자 FK → usr_acnt';
COMMENT ON COLUMN db_rcvry_log.vrfy_stat IS '검증 상태: pending/verified/failed';
COMMENT ON COLUMN db_rcvry_log.vrfy_at IS '검증 수행 일시';
COMMENT ON COLUMN db_rcvry_log.vrfy_by IS '검증자 FK → usr_acnt';
COMMENT ON COLUMN db_rcvry_log.vrfy_rslt IS '검증 결과 상세 설명';
COMMENT ON COLUMN db_rcvry_log.err_msg IS '오류 메시지';
COMMENT ON COLUMN db_rcvry_log.err_dtl IS '오류 상세 (JSON)';
COMMENT ON COLUMN db_rcvry_log.dc IS '비고';
COMMENT ON COLUMN db_rcvry_log.crtd_at IS '등록일시';
COMMENT ON COLUMN db_rcvry_log.crtd_by IS '등록자 ID';
COMMENT ON COLUMN db_rcvry_log.updtd_at IS '수정일시';
COMMENT ON COLUMN db_rcvry_log.updtd_by IS '수정자 ID';

-- db_rcvry_dtl
COMMENT ON TABLE  db_rcvry_dtl IS 'DB 복구 상세 내역, 테이블 단위 복구 결과';
COMMENT ON COLUMN db_rcvry_dtl.rcvry_dtl_id IS '복구 상세 고유 ID (PK, 자동증가)';
COMMENT ON COLUMN db_rcvry_dtl.rcvry_log_id IS '복구 로그 FK → db_rcvry_log';
COMMENT ON COLUMN db_rcvry_dtl.trget_table IS '대상 테이블명';
COMMENT ON COLUMN db_rcvry_dtl.tot_rcrds IS '전체 레코드 수';
COMMENT ON COLUMN db_rcvry_dtl.rcvrd_rcrds IS '복구 완료 레코드 수';
COMMENT ON COLUMN db_rcvry_dtl.err_rcrds IS '오류 레코드 수';
COMMENT ON COLUMN db_rcvry_dtl.stat IS '상태: running/success/failed/cancelled';
COMMENT ON COLUMN db_rcvry_dtl.strtd_at IS '시작 일시';
COMMENT ON COLUMN db_rcvry_dtl.fnshed_at IS '종료 일시';
COMMENT ON COLUMN db_rcvry_dtl.dur_secnd IS '소요 시간 (초)';
COMMENT ON COLUMN db_rcvry_dtl.err_msg IS '오류 메시지';
COMMENT ON COLUMN db_rcvry_dtl.crtd_at IS '등록일시';
COMMENT ON COLUMN db_rcvry_dtl.crtd_by IS '등록자 ID';
COMMENT ON COLUMN db_rcvry_dtl.updtd_at IS '수정일시';
COMMENT ON COLUMN db_rcvry_dtl.updtd_by IS '수정자 ID';

-- ============================================================================
-- 끝
-- ============================================================================
