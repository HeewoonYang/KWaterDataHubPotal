# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 작업 방식

- 토큰량이 많은 대규모 작업(파일 생성, 코드 작성 등)은 **한 번에 전부 처리하지 말고 분할하여 순차적으로 작성 및 개선**한다.
- 분할 단위는 논리적 블록(인터페이스 1건, 화면 1개, 함수 단위 등) 기준으로 나눈다.

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

### 스키마 구조 (9개 도메인, 68개 테이블)

| 도메인 | 테이블 수 | 핵심 테이블 |
|--------|:---------:|------------|
| 사용자·조직·권한 | 7 | `user_account`, `role`, `role_menu_perm`, `login_history` |
| 카탈로그·메타데이터 | 14 | `dataset`, `dataset_column`, `glossary_term`, `data_model`, `tag` |
| 수집 관리 | 8 | `pipeline`, `pipeline_execution`, `cdc_connector`, `kafka_topic` |
| 유통·활용 | 11 | `data_product`, `api_key`, `data_request`, `deidentify_policy` |
| 데이터 품질 | 4 | `dq_rule`, `dq_execution`, `domain_quality_score`, `quality_issue` |
| 온톨로지 | 3 | `onto_class`, `onto_data_property`, `onto_relationship` |
| 모니터링 | 5 | `region`, `office`, `site`, `sensor_tag`, `asset_database` |
| 커뮤니티 | 3 | `board_post`, `board_comment`, `resource_archive` |
| 시스템관리 | 13 | `audit_log`, `notification`, `lineage_node`, `ai_chat_session` |

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
3. **KPI/통계 항목 추가 시** → 집계 테이블(`daily_dist_stats`, `dept_usage_stats`, `domain_quality_score`) 컬럼 반영
4. **신규 엔티티/기능 추가 시** → `portal_schema.sql`에 테이블 추가, `portal_erd_summary.md` 업데이트
5. **RBAC 역할/권한 변경 시** → `role` 테이블 초기 데이터 및 `role_menu_perm` 구조 반영
6. **폼 필드 추가/변경 시** → 대응하는 테이블 컬럼 추가/변경 (타입, 제약조건 포함)
7. **상태값/코드값 변경 시** → ENUM 타입 또는 `code_group`/`code` 초기 데이터 업데이트

변경 후 `portal_erd_summary.md`의 테이블 수, 관계도도 함께 갱신할 것.

### 레거시 스키마 (참고용)

`db/001_schema.sql`, `db/003_comments_*.sql`, `db/datahub_schema_full.sql`은 이전 버전 스키마로 참고용이다. 실제 운영 스키마는 `db/portal_schema.sql`을 기준으로 한다.
