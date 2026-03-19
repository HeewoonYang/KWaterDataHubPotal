# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 작업 방식

- 토큰량이 많은 대규모 작업(파일 생성, 코드 작성 등)은 **한 번에 전부 처리하지 말고 분할하여 순차적으로 작성 및 개선**한다.
- 분할 단위는 논리적 블록(인터페이스 1건, 화면 1개, 함수 단위 등) 기준으로 나눈다.

## "메인 반영" 프롬프트 규칙

사용자가 **"메인 반영"**이라고 입력하면 아래 절차를 순서대로 실행한다.

1. **`git pull origin master`** — 원격 최신 변경사항을 가져온다
2. **변경사항 확인** — `git status`로 커밋할 파일이 있는지 확인한다
3. **`git add` + `git commit`** — 변경된 파일을 스테이징하고 한글 커밋 메시지로 커밋한다 (변경사항이 없으면 건너뛴다)
4. **브랜치 머지** (현재 브랜치가 master가 아닌 경우):
   - `git checkout master`
   - `git merge {현재브랜치명}`
5. **`git push origin master`** — master 브랜치를 원격에 푸시한다
6. **브랜치 정리** (브랜치에서 머지한 경우): 머지 완료 후 작업 브랜치 삭제 여부를 사용자에게 확인한다

> 각 단계에서 충돌이나 에러 발생 시 즉시 중단하고 사용자에게 상황을 알린다.

## 언어 지침

- 모든 결과값, 설명, 주석, 커밋 메시지, 응답은 **반드시 한글**로 작성한다.
- 코드 내 변수명/함수명은 영문 유지하되, 주석과 사용자에게 보이는 텍스트(UI 라벨, 토스트 메시지 등)는 한글로 작성한다.

## Project Overview

K-water DataHub Portal - a static prototype for a data governance portal (Korean Water Resources Corporation). No build tools, no bundler, no package manager. Purely CDN-based.

## Tech Stack

- **Tailwind CSS v4 Browser** (runtime, via CDN `@tailwindcss/browser@4`)
- **daisyUI v5** (CSS-only CDN, loaded before Tailwind)
- **AG Grid Community v31.3.4** (CDN, pre-Theming API)
- **No build step** - open `index.html` directly in a browser or serve with any static server

## Critical: daisyUI v5 Component Styles Don't Render

daisyUI v5 component classes (`.btn`, `.badge`, `.card`, `.select`, etc.) do NOT work with Tailwind CSS v4 Browser mode due to CSS layer ordering conflicts. **Custom replacements are defined in `css/style.css`**. Tailwind utility classes (`w-full`, `flex`, `mt-2`, etc.) work fine.

When adding UI elements, use the custom CSS classes from `style.css`, not raw daisyUI component classes.

## Architecture

```
index.html          -- App shell: login screen, top nav, sidebar, all <div class="screen"> containers
pages/*.html         -- NOT loaded dynamically; content is embedded in index.html screen divs
                       The pages/ files are reference/source for screen content
js/main.js           -- All JS: login, RBAC, navigation, AG Grid helper, screen-specific init functions
css/style.css        -- All custom CSS: variables, component classes, dark mode, page-specific styles
```

### Key Patterns

- **Login**: `doLogin('sso'|'partner'|'engineer'|'admin')` reads role from a `<select>`, sets `window.currentRoleKey`
- **Navigation**: `navigate('screen-id')` hides all `.screen` divs, shows `#screen-{id}`, applies RBAC permissions
- **RBAC**: `RBAC_MATRIX` defines allowed screens per role. `RBAC_SCREEN_PERMS` controls per-screen action levels (read/write/manage/admin). Elements with `data-perm` attribute are hidden/shown based on permission level
- **Screen parent mapping**: `SCREEN_PARENT_MAP` maps detail/sub-screens to parent screens for sidebar highlighting and permission inheritance
- **AG Grid**: `initAGGrid(containerId, columnDefs, rowData, options)` creates grids with standard defaults (sorting, filtering, pagination at 15 rows). All instances tracked in `agGridInstances` object
- **Dark mode**: `toggleTheme()` sets `data-theme="dark"` on `<html>`. CSS variables in `:root` / `[data-theme="dark"]`. Many inline style overrides needed due to hardcoded colors in HTML
- **Toast**: `showToast(msg, 'success'|'error')` for notifications
- **Modal**: `.modal-overlay` + `.modal-card` 패턴 사용. 아래 모달 규칙 참고

## Modal (모달 팝업) 규칙

모달을 새로 생성하거나 수정할 때 반드시 아래 규칙을 따른다.

### 필수 동작
1. **외부 클릭 닫기**: 모달 오버레이(반투명 배경) 클릭 시 모달이 닫혀야 한다
2. **드래그 이동**: 모달 헤더를 마우스로 드래그하면 모달 위치가 이동되어야 한다

### HTML 구조
```html
<div class="modal-overlay" id="my-modal" style="display:none;">
  <div class="modal-card" style="width:640px; max-height:90vh;">
    <div class="modal-header">
      <h3 class="modal-title">제목</h3>
      <button class="modal-close" onclick="...">×</button>
    </div>
    <div class="modal-body">내용</div>
    <div class="modal-footer">
      <button class="btn btn-outline" onclick="...">닫기</button>
    </div>
  </div>
</div>
```

### 자동 적용
- `main.js`의 `DOMContentLoaded` 이벤트에서 모든 `.modal-overlay`에 외부 클릭 닫기(`initModalOverlayClose`)와 드래그 이동(`initModalDrag`)이 자동 바인딩된다
- 새 모달을 HTML에 `.modal-overlay` 클래스로 추가하면 별도 JS 없이 두 기능이 자동 적용된다
- compact 레이아웃이 필요하면 `.modal-card`에 `modal-compact` 클래스를 추가한다

### 닫기 시 위치 초기화
- 모달을 JS로 닫을 때는 드래그 위치를 초기화해야 한다:
```javascript
var card = modal.querySelector('.modal-card');
if (card) { card.style.transform = ''; card.style.left = ''; card.style.top = ''; card.style.position = ''; card.style.margin = ''; }
```

## Custom CSS Classes (defined in style.css, NOT daisyUI)

- `.badge .badge-success/warning/error/info/ghost/secondary` - status badges
- `.btn .btn-primary/outline`, `.btn-sm` - buttons
- `.card`, `.card-title`, `.card-head`, `.card-body` - card containers
- `.kpi-card .kpi-label .kpi-value .kpi-sub` - KPI metric cards
- `.data-table` - styled HTML tables (non-AG Grid)
- `.grid-2/3/4`, `.filter-bar` - layout helpers

## Cache Busting

When modifying `style.css` or `main.js`, update the version query string in `index.html`:
```html
<link rel="stylesheet" href="css/style.css?v=20260305c">
```
Format: `?v=YYYYMMDD[letter]` (increment letter for same-day changes).

## Database Schema

포탈 운영 DB 스키마는 `db/portal_schema.sql`에 정의되어 있다 (ERD 요약: `db/portal_erd_summary.md`).

### 명명 규칙

- K-water 표준사전 영문약어 기반 snake_case (소문자)
- ENUM 타입명은 풀네임 유지 (변환 대상 아님)
- 감사 컬럼: `crtd_at`, `crtd_by`, `updtd_at`, `updtd_by` (모든 테이블 공통)
- 신규 단어 등록 목록: `db/std_new_words.md`

### 표준단어·용어 필수 사용 규칙

DB 모델(테이블, 컬럼, 인덱스, 제약조건 등)을 **생성·수정할 때 반드시 아래 절차를 따른다.**

1. **표준단어 조회**: 테이블명·컬럼명에 사용할 한글 단어의 영문약어를 `db/std_new_words.md`에서 먼저 확인한다
2. **기존 약어 우선**: 이미 등록된 표준약어가 있으면 **반드시 해당 약어를 사용**한다 (임의 축약 금지)
   - 예: "파이프라인" → `PPLN` (O), `PIPELINE` (X), `PIPE` (X)
   - 예: "데이터셋" → `DSET` (O), `DATASET` (X), `DS` (X)
3. **보정 약어 반영**: `db/std_new_words.md`의 "보정 단어" 섹션에 권고약어가 있으면 권고약어를 사용한다
   - 예: "실행" → `EXEC` (O, 권고), `EXC` (X, 구약어)
4. **미등록 단어 처리**: 표준사전에 없는 새 단어가 필요한 경우:
   - `db/std_new_words.md`에 해당 단어를 추가 등록한다 (한글명, 영문약어, 영문풀명, 속성분류, 비고)
   - 약어 생성 규칙: 자음 중심 축약, 4~6자 이내, 기존 약어와 충돌 없을 것
5. **복합어 조합**: 테이블명·컬럼명은 표준단어를 `_`로 조합하여 구성한다
   - 예: 검색기록 → `srch_hist` (검색=`SRCH` + 기록=`HIST`)
6. **검증**: 스키마 변경 후 사용된 모든 약어가 `db/std_new_words.md` 또는 K-water 표준사전에 존재하는지 확인한다

### 스키마 구조 (9개 도메인, 68개 테이블)

| 도메인 | 테이블 수 | 핵심 테이블 |
|--------|:---------:|------------|
| 사용자·조직·권한 | 7 | `usr_acnt`, `role`, `role_menu_perm`, `lgn_hist` |
| 카탈로그·메타데이터 | 14 | `dset`, `dset_col`, `glsry_term`, `data_mdl`, `tag` |
| 수집 관리 | 8 | `ppln`, `ppln_exec`, `cdc_cnctr`, `kafka_topc` |
| 유통·활용 | 11 | `data_prdct`, `api_key`, `data_rqst`, `didntf_plcy` |
| 데이터 품질 | 4 | `dq_rule`, `dq_exec`, `domn_qlty_scr`, `qlty_issue` |
| 온톨로지 | 3 | `onto_cls`, `onto_data_prprty`, `onto_rel` |
| 모니터링 | 5 | `rgn`, `offc`, `site`, `snsr_tag`, `asset_db` |
| 커뮤니티 | 3 | `board_post`, `board_cm`, `resrce_archv` |
| 시스템관리 | 13 | `audt_log`, `noti`, `lnage_node`, `ai_chat_sesn` |
| K-water 데이터표준 사전 | 5 | `std_word`, `std_domn_dict`, `std_term`, `std_cd_grp`, `std_cd` |

### K-water 데이터표준 사전 (데이터관리포탈 연동)

기존 데이터관리포탈에서 관리하는 표준 사전 4종을 수용하는 테이블이다. 시드 데이터는 별도 SQL 파일로 관리한다.

| 테이블 | 시드 파일 | 건수 | 설명 |
|--------|-----------|:----:|------|
| `std_word` | `db/seed_std_word.sql` | 6,306 | 표준단어사전 |
| `std_domn_dict` | `db/seed_std_domn_dict.sql` | 615 | 표준도메인사전 |
| `std_term` | `db/seed_std_term.sql` | 41,724 | 표준용어사전 |
| `std_cd_grp` + `std_cd` | `db/seed_std_cd.sql` | 3,572 + 139,288 | 표준코드사전 |

### 주요 ENUM 타입

- `data_security_level`: public / internal / restricted / confidential
- `entity_status`: active / inactive / pending / locked / deprecated
- `approval_status`: pending / approved / rejected / revision_needed / cancelled
- `collect_method`: cdc / batch / api / file / streaming / migration
- `data_asset_type`: table / api / file / view / stream
- `login_type`: sso / partner / engineer / admin
- `noti_type`: system / approval / quality / security / pipeline
- `deidentify_rule_type`: masking / pseudonym / aggregation / suppression / rounding / encryption

### UI ↔ DB 동기화 규칙 (필수)

**UI 화면을 추가/변경/삭제할 때 반드시 DB 스키마도 함께 업데이트한다.**

1. **화면(screen) 추가/삭제 시** → `menu` 테이블에 해당 메뉴 행 추가/삭제, `role_menu_perm`에 권한 매핑 반영
2. **AG Grid 컬럼 변경 시** → 해당 테이블의 컬럼 정의 확인 및 `portal_schema.sql` 업데이트
3. **KPI/통계 항목 추가 시** → 집계 테이블(`daly_dist_stts`, `dept_usg_stts`, `domn_qlty_scr`) 컬럼 반영
4. **신규 엔티티/기능 추가 시** → `portal_schema.sql`에 테이블 추가, `portal_erd_summary.md` 업데이트
5. **RBAC 역할/권한 변경 시** → `role` 테이블 초기 데이터 및 `role_menu_perm` 구조 반영
6. **폼 필드 추가/변경 시** → 대응하는 테이블 컬럼 추가/변경 (타입, 제약조건 포함)
7. **상태값/코드값 변경 시** → ENUM 타입 또는 `code_group`/`code` 초기 데이터 업데이트

변경 후 `portal_erd_summary.md`의 테이블 수, 관계도도 함께 갱신할 것.

### 레거시 스키마 (참고용)

`db/001_schema.sql`, `db/003_comments_*.sql`, `db/datahub_schema_full.sql`은 이전 버전 스키마로 참고용이다. 실제 운영 스키마는 `db/portal_schema.sql`을 기준으로 한다.

## 개발표준정의서 (KWDP-SD-DS-03 v0.6)

K-water 디지털플랫폼 구축 사업의 개발 표준. 본 프로젝트(데이터허브 포탈, DH)에 적용되는 핵심 사항을 아래에 정리한다.

### 프로젝트 명명 규칙

- 프로젝트명: `KWDP-[모듈영문약어]-[프로그램유형약어]` (KWDP = K-Water DigitalPlatform)
- 영역별 코드: 메인포탈=`MP`, 데이터허브=`DH`, SaaS갤러리=`SG`, 생성형AI=`GA`
- 프로그램 유형: WEB=`web`, BATCH=`bat`, API=`api`

### 공통 코드 표준

- 모든 이름은 `a-z`, `A-Z`, `0-9`만 사용, 표준용어 기반
- 이름 길이 64자 이내, 약어는 표준용어사전에 등록된 것만 사용
- 특수기호 사용 금지, 의미가 비슷하거나 대소문자만 다른 이름 금지
- **하드코딩 금지 항목**: IP주소/도메인/호스트명, 포트, 계정/비밀번호, 암호화키 → 설정에서 관리

### 표기법 가이드

| 표기법 | 예제 | 적용 대상 |
|--------|------|-----------|
| PascalCase | `ContentManagement` | 클래스, 인터페이스, React 컴포넌트 |
| camelCase | `contentManagement` | 변수, 함수, 메서드, 파일명 |
| UPPER_SNAKE_CASE | `DEFAULT_COLOR` | 상수(Constants) |
| snake_case | `content_management` | DB 컬럼, Python 변수/함수 |
| kebab-case | `content-management` | CSS 클래스, URL |

### JavaScript 표준 (본 프로젝트 직접 적용)

- **파일명**: 소문자, 단어 구분은 `.` 사용 (예: `order.view.js`)
- **변수**: `const`(상수) / `let`(재할당 가능) 사용 권장, `var` 지양
- **비교**: 반드시 `===` (일치 연산자) 사용, `==` (동등 연산자) 금지
- **문자열**: 작은따옴표(`'`) 기본, 템플릿 리터럴(`` ` ``) 활용
- **들여쓰기**: 스페이스 4칸
- **세미콜론**: 문장 끝에 반드시 `;`
- **중괄호**: 한 줄이라도 반드시 사용 (if/for/while 등)
- **주석**: 단일행 `//`, 블록 `/* */`, 직관적 변수명으로 주석 최소화
- **Strict Mode**: `"use strict"` 사용 권장 (ES6 모듈 사용 시 자동 적용)
- **IIFE**: 전역변수 오염 방지를 위해 즉시실행함수 사용 고려
- **네임스페이스**: 모듈 간 호출 시 단일 전역 네임스페이스 패턴 사용

### Java/Springboot 표준 (백엔드 참조용)

- 클래스: PascalCase + Postfix (`Controller`, `Service`, `ServiceImpl`, `Mapper`, `DTO`)
- 메서드 Prefix: 단건조회=`select`, 다건조회=`selectList`, 입력=`insert`, 수정=`update`, 삭제=`delete`, 입력+수정=`regist`
- Ajax 호출: Postfix `Ajax` (예: `selectBoardAjax`)
- 필드/변수: camelCase, `private` 필수, getter/setter 접근
- 예외처리: catch 블록 비우기 금지, 에러 로그 기록 필수, CUD 트랜잭션은 rollback 처리
- **API 응답 표준**: `{ success, code, message, data }` 형식
- **에러 응답 표준**: `{ success: false, code, message, errors[], traceId }` 형식
- **예외 분류**: ValidationException(400), AuthException(401/403), NotFoundException(404), BusinessException(409), SystemException(500)
- DTO/Entity 분리 필수, Controller에서 Entity 직접 노출 금지
- 로그 레벨: DEBUG(개발), INFO(운영), WARN(잠재적 에러), ERROR(복구불가), FATAL(서비스불가)

### Python 표준 (데이터허브 백엔드)

- PEP 8 준수, 변수/함수: `snake_case`, 클래스: `PascalCase`, 상수: `UPPER_SNAKE_CASE`
- 함수는 "한 가지 역할" 원칙
- 주석은 "왜(Why)" 중심, 공용 모듈에 타입힌트 권장
- 포맷: black, 린트: ruff, 타입체크: mypy
- 공통 예외 계층: `DomainError`, `ValidationError`, `InfraError`

### Go 표준 (데이터허브 백엔드)

- Go 1.21+, `go.mod`/`go.sum` 커밋 필수
- 포맷: `gofmt`/`goimports`, 린트: `golangci-lint`
- goroutine 사용 시 `context.Context` 필수, 종료 조건 명확화
- 에러는 `%w`로 래핑하여 원인 추적 가능하게 유지

### React 표준 (메인포탈 참조용)

- 컴포넌트: `PascalCase` (예: `UserList.tsx`), 훅: `useXxx`
- Presentational / Container 분리 권장
- `any` 타입 사용 금지
- API 레이어 분리, 화면에서 URL 하드코딩 금지

### 자원 관리

- JDBC Connection 등 외부 자원은 명시적으로 반납 (HikariCP auto close 활용)
- 트랜잭션: `@Transactional` 어노테이션 기반, `readOnly=true` 시 `Propagation.SUPPORTS` 설정
