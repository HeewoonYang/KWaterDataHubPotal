# K-water DataHub Portal - 프로젝트 인수인계서

> **작성일**: 2026-03-06
> **프로젝트명**: K-water 데이터허브 포털 (정적 프로토타입)
> **상태**: 개발 진행 중 (Ant Design → Tailwind+daisyUI+AG Grid 마이그레이션 완료)

---

## 1. 프로젝트 개요

한국수자원공사(K-water) 데이터 거버넌스 포털의 **정적 UI 프로토타입**입니다. 빌드 도구 없이 CDN만으로 구성되며, 브라우저에서 `index.html`을 직접 열어 실행합니다.

### 목적
- 데이터 수집·유통·카탈로그·메타데이터·시스템관리 등 데이터 거버넌스 기능의 UI/UX 프로토타입
- 역할 기반 접근 제어(RBAC) 시뮬레이션
- 실제 백엔드 없이 더미 데이터로 화면 흐름 검증

---

## 2. 기술 스택

| 구분 | 기술 | 버전 | 비고 |
|------|------|------|------|
| CSS 프레임워크 | Tailwind CSS Browser | v4 | CDN 런타임 (`@tailwindcss/browser@4`) |
| 컴포넌트 | daisyUI | v5 | CSS-only CDN, **컴포넌트 클래스 미작동** (아래 주의사항 참조) |
| 데이터 그리드 | AG Grid Community | v31.3.4 | CDN, pre-Theming API |
| 빌드 | 없음 | - | 패키지 매니저·번들러 미사용 |

### 핵심 주의사항: daisyUI v5 호환성 문제

daisyUI v5의 컴포넌트 클래스(`.btn`, `.badge`, `.card`, `.select` 등)는 Tailwind CSS v4 Browser 모드에서 CSS 레이어 순서 충돌로 **렌더링되지 않습니다**. 이를 대체하기 위해 `css/style.css`에 커스텀 컴포넌트 CSS를 정의해 사용합니다. Tailwind **유틸리티 클래스**(`w-full`, `flex`, `mt-2` 등)는 정상 작동합니다.

---

## 3. 파일 구조

```
datahubPotal/
├── index.html              # 앱 셸: 로그인, 상단 네비, 사이드바, 모든 screen 컨테이너
├── css/
│   └── style.css           # 커스텀 CSS (변수, 컴포넌트, 다크모드, 페이지별 스타일) ~5,600줄
├── js/
│   └── main.js             # 모든 JS 로직 (로그인, RBAC, 네비게이션, AG Grid, 화면별 초기화) ~6,700줄
├── pages/                  # 화면 참조용 HTML (index.html에 직접 포함됨, 동적 로드 아님)
│   ├── dashboard.html
│   ├── catalog.html
│   ├── collect.html
│   ├── distribute.html
│   ├── metadata.html
│   ├── system.html
│   └── community.html
├── db/                     # PostgreSQL 스키마 참조 파일 (프론트엔드 미사용)
│   ├── 001_schema.sql
│   ├── datahub_schema_full.sql
│   └── ...
├── docs/                   # 요구사항·시나리오·인프라 규모산정 문서
│   ├── REQ-PORTAL-UI-EXTRACT.md
│   ├── role-scenarios.md
│   ├── 데이터허브포탈_온프레미스_규모산정.md
│   └── 데이터허브포탈_클라우드_규모산정.md
├── CLAUDE.md               # AI 코딩 보조 지침
└── PLAN.md                 # 현재 작업 계획 (외부사용자 신청/승인)
```

---

## 4. 핵심 아키텍처 패턴

### 4.1 SPA 방식 네비게이션

모든 화면은 `index.html` 내 `<div>` 컨테이너로 존재합니다. `navigate('screen-id')` 함수가 모든 화면을 숨기고 해당 화면만 표시합니다.

### 4.2 로그인 및 역할 시스템

- `doLogin('sso'|'partner'|'engineer'|'admin')` 함수로 로그인 처리
- 로그인 시 `<select>`에서 선택한 역할을 `window.currentRoleKey`에 저장
- 4가지 로그인 유형: SSO(수공직원), 협력직원, 데이터엔지니어, 관리자

### 4.3 RBAC (역할 기반 접근 제어)

`RBAC_MATRIX` 객체에 역할별 접근 가능 화면 목록을 정의합니다.

**주요 역할 (10종)**:
| 그룹 | 역할 |
|------|------|
| 수공직원 | 일반사용자, 부서관리자, 데이터스튜어드 |
| 협력직원 | 데이터조회, 외부개발자 |
| 데이터엔지니어 | 파이프라인관리자, ETL운영자 |
| 관리자 | 시스템관리자, 보안관리자, 슈퍼관리자 |

**RBAC 동작**:
- `RBAC_SCREEN_PERMS`: 역할별 화면 권한 수준 (read/write/manage/admin)
- `data-perm` 속성: HTML 요소에 필요 권한 명시, 권한 부족 시 자동 숨김
- `SCREEN_PARENT_MAP`: 상세/하위 화면의 부모 화면 매핑 (사이드바 하이라이팅, 권한 상속)

### 4.4 AG Grid 사용

```javascript
initAGGrid(containerId, columnDefs, rowData, options)
```
- 기본값: 정렬, 필터링, 페이지네이션(15행)
- 모든 인스턴스는 `agGridInstances` 객체에서 추적
- 총 20개 이상의 테이블을 AG Grid로 구현

### 4.5 다크 모드

- `toggleTheme()` 함수로 전환
- `<html>`에 `data-theme="dark"` 속성 설정
- CSS 변수를 `:root` / `[data-theme="dark"]`에서 관리
- HTML 내 인라인 스타일 때문에 일부 CSS 선택자 오버라이드 필요

### 4.6 토스트 알림

```javascript
showToast('메시지', 'success'|'error')
```

---

## 5. 커스텀 CSS 클래스 목록

`css/style.css`에 정의된 주요 커스텀 클래스 (daisyUI 대체):

| 분류 | 클래스 | 용도 |
|------|--------|------|
| 배지 | `.badge`, `.badge-success/warning/error/info/ghost/secondary` | 상태 표시 |
| 버튼 | `.btn`, `.btn-primary`, `.btn-outline`, `.btn-sm` | 액션 버튼 |
| 카드 | `.card`, `.card-title`, `.card-head`, `.card-body` | 카드 컨테이너 |
| KPI | `.kpi-card`, `.kpi-label`, `.kpi-value`, `.kpi-sub` | 지표 카드 |
| 테이블 | `.data-table` | HTML 테이블 (AG Grid 외) |
| 레이아웃 | `.grid-2/3/4`, `.filter-bar` | 그리드·필터 레이아웃 |

---

## 6. 주요 화면 목록

### 대시보드
- `home` - 메인 대시보드 (KPI, 차트, 프로세스 현황)
- `process`, `quality`, `measurement`, `ai` - 대시보드 하위 탭
- `gallery`, `widget-settings`, `sitemap` - 부가 기능

### 데이터 카탈로그
- `cat-search` - 카탈로그 검색
- `cat-detail` - 카탈로그 상세
- `cat-graph`, `cat-lineage` - 데이터 그래프/리니지
- `cat-bookmark`, `cat-request` - 즐겨찾기/데이터 요청

### 데이터 수집
- `col-pipeline`, `col-register`, `col-cdc`, `col-kafka` - 수집 파이프라인
- `col-external`, `col-arch`, `col-monitor`, `col-log`, `col-dbt` - 수집 관리

### 데이터 유통
- `dist-product`, `dist-deidentify`, `dist-approval` - 유통 관리
- `dist-api`, `dist-external`, `dist-stats`, `dist-chart-content` - API/통계

### 메타데이터
- `meta-glossary`, `meta-tag`, `meta-model`, `meta-dq`, `meta-ontology` - 메타 관리

### 시스템관리
- `sys-user`, `sys-role`, `sys-perm`, `sys-security` - 사용자/권한
- `sys-interface`, `sys-k8s`, `sys-audit`, `sys-config`, `sys-backup` - 시스템 운영

### 커뮤니티
- `comm-notice`, `comm-internal`, `comm-external`, `comm-archive` - 게시판

---

## 7. 마이그레이션 이력

Ant Design CDN 기반에서 Tailwind + daisyUI + AG Grid 기반으로 완전 마이그레이션 완료:

1. **Phase 0-1**: Ant Design CDN 제거, Tailwind+daisyUI+AG Grid CDN 도입, 로그인/네비 마이그레이션
2. **Phase 2**: 대시보드 `ant-*` 클래스 → 리네이밍 클래스 전환
3. **Phase 3**: `status-badge` → `badge badge-*` (35개 인스턴스), 커스텀 btn/badge CSS 작성
4. **Phase 4**: 전체 20개 테이블 → AG Grid 전환
5. **Phase 5-6**: 미사용 CSS 제거 (~230줄 삭감, 4,353 → 4,123줄)

---

## 8. 캐시 버스팅

`style.css`나 `main.js` 수정 시 `index.html`의 버전 쿼리 스트링을 갱신해야 합니다:

```html
<link rel="stylesheet" href="css/style.css?v=20260305c">
<script src="js/main.js?v=20260305c"></script>
```

형식: `?v=YYYYMMDD[문자]` (같은 날 변경 시 문자를 증가)

---

## 9. 현재 진행 중인 작업

### 외부 사용자 사용신청/승인 프로세스 (`PLAN.md` 참조)

- 로그인 화면에 **외부 사용자 사용신청 폼** 추가
- 시스템관리 > **외부사용자 신청관리** 화면 (`sys-ext-register`) 추가
- 신청 상세/승인/반려 처리 화면 (`sys-ext-register-detail`)
- 관리자 역할만 접근 가능 (RBAC 반영)

### 미반영 변경사항 (Working Tree)

현재 커밋되지 않은 변경사항이 있습니다 (총 ~4,100줄 추가/수정):
- `index.html`: 로그인 화면 수정
- `js/main.js`: 대규모 기능 추가 (~1,400줄)
- `css/style.css`: 스타일 추가 (~166줄)
- `pages/`: 대시보드, 수집, 유통, 메타데이터, 시스템 화면 확장

---

## 10. 개발 환경 설정

### 실행 방법
```bash
# 방법 1: 브라우저에서 직접 열기
# index.html을 더블클릭

# 방법 2: 정적 서버 사용
npx serve .
# 또는
python -m http.server 8000
```

### 개발 시 참고사항
- 빌드 도구가 없으므로 파일 저장 후 브라우저 새로고침으로 확인
- 캐시 방지를 위해 버전 쿼리 스트링 갱신 필요
- daisyUI 컴포넌트 클래스 사용 금지 → `css/style.css`의 커스텀 클래스 사용
- 새 화면 추가 시: `index.html`에 screen div 추가 + `RBAC_MATRIX`에 등록 + `SCREEN_PARENT_MAP` 매핑

---

## 11. 참조 문서

| 문서 | 위치 | 내용 |
|------|------|------|
| UI 요구사항 | `docs/REQ-PORTAL-UI-EXTRACT.md` | 포털 UI/UX 관련 전체 요구사항 |
| 역할 시나리오 | `docs/role-scenarios.md` | RBAC 역할별 사용 시나리오 |
| 온프레미스 규모산정 | `docs/데이터허브포탈_온프레미스_규모산정.md` | 서버 인프라 규모 |
| 클라우드 규모산정 | `docs/데이터허브포탈_클라우드_규모산정.md` | 클라우드 인프라 규모 |
| DB 스키마 | `db/datahub_schema_full.sql` | PostgreSQL 전체 스키마 |
| AI 코딩 지침 | `CLAUDE.md` | Claude Code 사용 시 지침 |
| 작업 계획 | `PLAN.md` | 현재 진행 작업 상세 계획 |

---

## 12. 알려진 제약사항 및 주의사항

1. **정적 프로토타입**: 백엔드 없음, 모든 데이터는 JS 내 더미 데이터
2. **단일 파일 구조**: `main.js`가 ~6,700줄로 비대 (모듈 분리 미적용)
3. **인라인 스타일**: HTML 내 인라인 스타일이 많아 다크모드 오버라이드에 CSS 선택자 해킹 필요
4. **daisyUI 비호환**: 컴포넌트 클래스 사용 불가, 커스텀 CSS 의존
5. **pages/ 폴더**: 참조용이며 실제로 동적 로드되지 않음 (index.html에 직접 포함)
