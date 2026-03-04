# K-water DataHub Portal — 역할별 업무진행 시나리오

> **작성일**: 2026-02-28
> **버전**: v1.0
> **대상**: K-water 데이터허브 포털 (4개 역할 그룹 · 12개 세부역할)

---

## 목차

1. [역할 체계 총괄표](#1-역할-체계-총괄표)
2. [시나리오 1 — 수공직원 (박수원 과장)](#2-시나리오-1--수공직원)
3. [시나리오 2 — 협력직원 (최외부 연구원)](#3-시나리오-2--협력직원)
4. [시나리오 3 — 데이터엔지니어 (김데이터)](#4-시나리오-3--데이터엔지니어)
5. [시나리오 4 — 관리자 (admin)](#5-시나리오-4--관리자)
6. [역할별 접근 화면 비교표](#6-역할별-접근-화면-비교표)

---

## 1. 역할 체계 총괄표

| 역할 그룹 | 세부 역할 | 데이터 등급 | 접근 화면수 | 핵심 업무 영역 |
|-----------|----------|-----------|-----------|-------------|
| **수공직원** | 일반사용자 | Lv.2 (내부일반) | 20개 | 검색·조회·신청 |
| | 부서관리자 | Lv.3 (내부중요) | 25개 | + 수집모니터링·메타관리 |
| | 데이터스튜어드 | Lv.4 (기밀) | 36개 | + 파이프라인·품질·보안정책 |
| **협력직원** | 데이터조회 | Lv.1 (공개) | 13개 | 공개데이터 열람만 |
| | 외부개발자 | Lv.1 (공개) | 14개 | + API 활용 |
| **데이터엔지니어** | 파이프라인관리자 | Lv.4 (기밀) | 29개 | 수집·파이프라인·인터페이스 |
| | ETL운영자 | Lv.4 (기밀) | 29개 | 수집·정제·인터페이스 |
| | DBA | Lv.4 (기밀) | 29개 | 메타데이터·온톨로지 |
| **관리자** | 시스템관리자 | Lv.4 (기밀) | 36개 | 시스템 전반 운영 |
| | 보안관리자 | Lv.4 (기밀) | 22개 | 보안·감사·비식별화 |
| | 슈퍼관리자 | Lv.4 (기밀) | **전체** | 모든 기능 |

---

## 2. 시나리오 1 — 수공직원

### 페르소나
| 항목 | 내용 |
|------|------|
| 이름 | 박수원 (과장) |
| 소속 | 수자원부 댐운영처 |
| 역할 | 수공직원 > 부서관리자 |
| 로그인 | SSO 통합인증 |
| 데이터등급 | Lv.3 (내부중요까지 열람) |

### 일일 업무 시나리오

#### 08:30 — 출근 후 대시보드 확인
```
로그인: doLogin('sso') → 수공직원|부서관리자
navigate('home') → 개인 대시보드
```
- KPI 위젯에서 금일 수위/유량 현황 파악
- 알림 배지 확인 (공지 3건, 신청 승인대기 1건)
- 데이터 워크플로우 현황 확인 (`navigate('process')`)

#### 09:00 — 데이터 품질현황 점검
```
navigate('quality') → 품질현황 종합
```
- DQ 검증 통과율(94.2%) 확인
- 경고/실패 규칙 2건 클릭하여 상세 확인
- 담당 엔지니어(김데이터)에게 조치 요청

#### 09:30 — 카탈로그 검색 및 데이터 활용
```
navigate('cat-search') → 통합데이터 검색
```
- "댐수위" 키워드 검색
- TB_WATER_LEVEL 데이터셋 상세 확인 (`navigate('cat-detail')`)
- 지식그래프에서 연관 데이터 탐색 (`navigate('cat-graph')`)
- 리니지 추적으로 데이터 흐름 파악 (`navigate('cat-lineage')`)
- 주요 데이터셋 북마크 등록 (`navigate('cat-bookmark')`)

#### 10:30 — 수집현황 모니터링
```
navigate('col-monitor') → 수집현황 모니터링
navigate('col-arch')    → 연계아키텍처 구조도
```
- 실시간 수집 파이프라인 상태(정상/경고/중단) 확인
- 아키텍처 구조도에서 전체 데이터 흐름 파악
- (부서관리자 권한으로 수집 모니터링만 가능, 파이프라인 생성 불가)

#### 11:00 — Data Product 조회 및 활용신청
```
navigate('dist-product')  → Data Product 목록
navigate('dist-approval') → 데이터 신청·승인
```
- 수질측정 데이터 API 활용 신청서 작성 (REQ-043)
- 기존 승인된 데이터 제품 목록 확인
- 유통통계 확인 (`navigate('dist-stats')`)

#### 13:00 — 메타데이터 관리 (부서관리자 권한)
```
navigate('meta-glossary') → 표준용어·코드관리
navigate('meta-tag')      → 분류체계·태그관리
navigate('meta-model')    → 데이터모델관리
navigate('meta-dq')       → DQ 검증·프로파일링
```
- 표준용어사전에서 "수위" 용어 영문명·약어 검토
- 분류체계 태그 정합성 확인
- 데이터모델(논리/물리) 최신 변경이력 확인
- DQ 규칙 실행결과 — 위반건수 8건 상세 분석

#### 14:30 — 비식별화 정책 확인
```
navigate('dist-deidentify') → 비식별화·가명처리 관리
```
- 고객개인정보 마스킹 정책 적용현황 확인
- 비식별화 처리율 95.6% 확인
- 검토 대기 정책 3건 검토

#### 15:30 — 커뮤니티 확인
```
navigate('comm-notice')   → 공지사항
navigate('comm-internal') → 내부게시판
navigate('comm-archive')  → 자료실
```
- 데이터거버넌스 회의 공지 확인
- 내부게시판에서 품질 개선 사례 공유글 확인
- 자료실에서 DQ 가이드 문서 다운로드

#### 16:30 — AI 검색 활용
```
navigate('ai') → AI 검색 및 질의응답
```
- "이번 달 수위 이상치가 발생한 테이블은?" 자연어 질의
- AI 추천 결과에서 관련 데이터셋 바로가기

---

### 역할 승격 시나리오 (일반사용자 → 데이터스튜어드)

데이터스튜어드로 승격되면 추가되는 업무:

```
[추가 접근 화면]
navigate('col-pipeline')     → 파이프라인 직접 생성/수정
navigate('col-cdc')          → CDC 연계 관리
navigate('col-kafka')        → Kafka 스트리밍 관리
navigate('col-dbt')          → dbt 정제·변환 관리
navigate('meta-ontology')    → 온톨로지 관리
navigate('sys-security')     → 데이터등급·보안정책 열람
navigate('dist-chart-content') → 차트 콘텐츠 관리
```

---

## 3. 시나리오 2 — 협력직원

### 페르소나
| 항목 | 내용 |
|------|------|
| 이름 | 최외부 (연구원) |
| 소속 | 환경부 수질정책과 |
| 역할 | 협력직원 > 외부개발자 |
| 로그인 | 협력직원 전용 로그인 |
| 데이터등급 | Lv.1 (공개 데이터만 열람) |

### 일일 업무 시나리오

#### 09:00 — 로그인 및 대시보드
```
로그인: doLogin('partner') → 협력직원|외부개발자
navigate('home') → 협력직원 대시보드
```
- 공개 데이터 현황 위젯 확인
- 공지사항 알림 확인

#### 09:30 — 공개 데이터 검색
```
navigate('cat-search') → 통합데이터 검색
```
- "수질측정" 키워드로 공개 데이터 검색
- **Lv.1(공개)** 등급만 결과에 표시됨 (내부일반·중요·기밀 데이터 미노출)
- 수질측정 데이터셋 상세 확인 (`navigate('cat-detail')`)
- 지식그래프에서 관련 데이터 탐색 (`navigate('cat-graph')`)

#### 10:00 — 데이터 리니지 확인
```
navigate('cat-lineage') → 데이터 리니지(계보)
```
- 수질측정 데이터의 원천→가공→활용 흐름 파악
- 데이터 품질 증적(evidence) 확인

#### 10:30 — 데이터 활용 신청
```
navigate('dist-approval') → 데이터 신청·승인
```
- 수질측정 실시간 API 활용 신청서 작성
- 기존 승인된 신청 진행현황 확인 (REQ-038: 승인완료)

#### 11:00 — API 연동 확인 (외부개발자 전용)
```
navigate('dist-api') → 유통 API 관리
```
- 승인된 REST API 엔드포인트 확인
- API Key 발급 현황 확인
- Swagger 문서 참조하여 연동 테스트
- *(데이터조회 역할은 이 화면 접근 불가)*

#### 13:00 — AI 검색 활용
```
navigate('ai') → AI 검색 및 질의응답
```
- "환경부에서 활용 가능한 수질 공개데이터 목록" 자연어 질의
- AI 추천 결과 확인 (공개 등급만 응답)

#### 14:00 — 시각화 갤러리 참조
```
navigate('gallery') → 시각화·차트 갤러리
```
- 공개 차트 템플릿 확인
- 수질 대시보드 차트 참고하여 자체 시스템 적용 검토

#### 14:30 — 커뮤니티 확인
```
navigate('comm-notice')   → 공지사항 (읽기 전용)
navigate('comm-external') → 외부게시판
navigate('comm-archive')  → 자료실
```
- API 연동 가이드 공지 확인
- 외부게시판에서 타 기관 활용 사례 확인
- 자료실에서 API 명세서 다운로드

### 협력직원 접근 제한 사항
| 기능 | 접근 여부 |
|------|----------|
| 내부게시판 | **차단** (외부게시판만 가능) |
| 수집·정제 메뉴 | **전체 차단** |
| 메타데이터 관리 | **전체 차단** |
| 시스템관리 | **전체 차단** |
| 데이터 워크플로우 | **차단** |
| 품질현황 종합 | **차단** |
| 비식별화 관리 | **차단** |
| 내부일반 이상 데이터 | **미노출** |

---

## 4. 시나리오 3 — 데이터엔지니어

### 페르소나
| 항목 | 내용 |
|------|------|
| 이름 | 김데이터 (엔지니어) |
| 소속 | 정보화전략처 데이터팀 |
| 역할 | 데이터엔지니어 > 파이프라인관리자 |
| 로그인 | 엔지니어 전용 인증 |
| 데이터등급 | Lv.4 (기밀까지 전체 열람) |

### 일일 업무 시나리오

#### 08:00 — 출근 전 모니터링 대시보드 확인
```
로그인: doLogin('engineer') → 데이터엔지니어|파이프라인관리자
navigate('home') → 엔지니어 대시보드
```
- 실시간 파이프라인 상태 위젯 (정상 42개, 경고 2개, 중단 0개)
- 야간 배치 처리 결과 요약
- 긴급 알림 확인

#### 08:15 — 실시간 계측DB 모니터링
```
navigate('measurement') → 실시간 계측DB 모니터링
navigate('asset-db')    → 자산DB 모니터링
```
- 수위·유량·수질 센서 데이터 실시간 입수 현황
- 자산DB(Oracle, PostgreSQL) 연결 상태 확인
- 지연/누락 센서 3개 식별 → 조치

#### 08:45 — 파이프라인 관리
```
navigate('col-pipeline') → 파이프라인 관리
```
- 전체 파이프라인 목록 조회 (42개 활성)
- 야간 배치 실패 파이프라인 1건 원인 분석
- 스케줄 조정 (1초→3초 인터벌 변경)
- 신규 파이프라인 등록 (`navigate('col-register')`)

#### 09:30 — CDC 연계 및 Kafka 관리
```
navigate('col-cdc')   → CDC 연계현황
navigate('col-kafka') → Kafka 스트리밍
```
- SAP/Oracle CDC 동기화 상태 확인 (정상)
- Kafka 브로커 6대 상태, 토픽별 Lag 확인
- 스마트미터 토픽 파티션 재조정

#### 10:30 — 수집현황 종합 모니터링
```
navigate('col-monitor') → 수집현황 모니터링
navigate('col-log')     → 실시간 로그·알림
navigate('col-arch')    → 연계아키텍처 구조도
```
- 금일 수집 건수 24.8K 확인
- 에러 로그 필터링 → 타임아웃 2건 식별
- 아키텍처 구조도에서 병목 구간 파악

#### 11:00 — 외부연계 데이터 관리
```
navigate('col-external') → 외부연계
```
- 기상청 API 연계 상태 확인 (정상)
- 환경부 수질 데이터 수신 현황
- 신규 외부연계 등록 검토

#### 13:00 — dbt 정제·변환 관리
```
navigate('col-dbt') → 정제·변환 관리(dbt)
```
- dbt 모델 실행 결과 확인
- 수질측정 데이터 정제 모델 수정 (이상치 필터 추가)
- 변환 파이프라인 테스트 실행

#### 14:00 — DQ 검증·프로파일링
```
navigate('meta-dq') → DQ 검증·프로파일링
```
- 금일 DQ 검증 156회 결과 확인
- 실패 규칙 2건 상세 분석 (PK 유일성, NULL 비율)
- 프로파일링 결과 — TB_SAP_FI_DOC NULL률 4.8% 확인
- 임계값 조정 검토

#### 15:00 — 데이터 워크플로우 점검
```
navigate('process') → 데이터 워크플로우
navigate('quality') → 데이터 품질현황 종합
```
- 전체 워크플로우 진행 현황 시각화 확인
- 품질 점수 추이 분석 (월간 94.2% → 목표 95%)

#### 15:30 — Interface 관리
```
navigate('sys-interface') → Interface 관리
```
- MCP/REST 인터페이스 응답시간 확인
- API 로그 분석

#### 16:00 — Data Product 및 유통통계
```
navigate('dist-product')      → Data Product 구성
navigate('dist-stats')        → 데이터 유통통계
navigate('dist-chart-content') → 차트 콘텐츠 관리
```
- 유통 중인 Data Product 활성 상태 확인
- API 호출량 추이 분석 (원격검침 API 892K/월)
- 차트 콘텐츠 신규 등록

#### 16:30 — 카탈로그 점검
```
navigate('cat-search')  → 통합데이터 검색
navigate('cat-graph')   → 지식그래프·온톨로지
navigate('cat-lineage') → 데이터 리니지
```
- 신규 등록 데이터셋 카탈로그 반영 확인
- 리니지 자동 생성 결과 검토

### DBA 역할 추가 업무
DBA 역할인 경우 메타데이터 관리 전체 접근 가능:
```
navigate('meta-glossary')  → 표준용어 관리
navigate('meta-tag')       → 분류체계·태그 관리
navigate('meta-model')     → 데이터모델 관리
navigate('meta-ontology')  → 온톨로지 관리
```

---

## 5. 시나리오 4 — 관리자

### 페르소나
| 항목 | 내용 |
|------|------|
| 이름 | admin (시스템관리자) |
| 소속 | 정보화전략처 시스템운영팀 |
| 역할 | 관리자 > 시스템관리자 |
| 로그인 | 관리자 전용 인증 |
| 데이터등급 | Lv.4 (기밀 전체) |

### 일일 업무 시나리오

#### 08:00 — 시스템 전체 현황 확인
```
로그인: doLogin('admin') → 관리자|시스템관리자
navigate('home') → 관리자 대시보드
```
- 시스템 가동률, 접속자 수, 처리 건수 위젯 확인
- 야간 배치 결과 요약
- 보안 이벤트 알림 확인 (이상탐지 0건)

#### 08:30 — 접속통계 및 감사로그 점검
```
navigate('sys-audit') → 접속통계·감사로그
```
- 금일 접속자 142명 현황 확인
- 시간대별 접속 히트맵 분석
- 감사로그에서 주요 활동 검토:
  - 10:45 비활성 계정 로그인 차단 1건 확인
  - 메타데이터 변경 56건 중 주요 변경 점검
- 엔티티별 변경이력 트리에서 TB_WATER_LEVEL 8건 변경 확인
- 보안 이벤트 타임라인 — 전체 양호

#### 09:30 — 사용자 관리
```
navigate('sys-user') → 조직 및 사용자관리
navigate('sys-role') → 권한 및 역할관리
```
- 신규 계정 요청 2건 검토 및 승인
  - 홍신규: 수공직원|일반사용자 → 승인
  - 외부파견: 협력직원|데이터조회 → 승인
- 역할 변경 요청 1건 처리
  - 이분석: 수공직원|일반사용자 → 데이터엔지니어|ETL운영자
- 비활성 계정 정리 (90일 미접속 5건)
- 부서별 사용자 분포 현황 확인

#### 10:30 — 데이터등급·보안정책 관리
```
navigate('sys-security') → 데이터등급·보안정책
```
- 데이터 등급 분류 현황 (공개 234, 내부일반 156, 내부중요 89, 기밀 42)
- 보안정책 규칙 5개 적용현황 확인
- 비식별화 정책과의 연동 상태 점검

#### 11:00 — Interface 관리
```
navigate('sys-interface') → Interface 관리
```
- MCP 서버 5대 연결 상태 확인
- REST API 응답시간 분석 (평균 128ms)
- API 로그에서 504 타임아웃 1건 원인 분석

#### 14:00 — 수집·정제 현황 확인
```
navigate('col-pipeline') → 파이프라인 관리
navigate('col-monitor')  → 수집현황 모니터링
navigate('col-cdc')      → CDC 연계현황
navigate('col-kafka')    → Kafka 스트리밍
navigate('col-arch')     → 연계아키텍처 구조도
navigate('col-log')      → 실시간 로그·알림
navigate('col-dbt')      → 정제·변환 관리
```
- 전체 수집 파이프라인 상태 종합 확인
- 에러율 추이 분석
- dbt 변환 작업 결과 확인

#### 15:00 — 위젯 템플릿 관리
```
navigate('sys-widget-template') → 위젯 템플릿관리
```
- 대시보드 위젯 템플릿 목록 관리
- 신규 위젯 등록 요청 검토
- 역할별 위젯 접근 권한 설정

#### 15:30 — 데이터 유통 및 차트 관리
```
navigate('dist-stats')         → 데이터 유통통계
navigate('dist-chart-content') → 차트 콘텐츠 관리
```
- 월간 데이터 유통량 추이 분석
- 인기 API Top 5 확인
- 차트 콘텐츠 승인 대기 2건 처리

#### 16:00 — 커뮤니티 관리
```
navigate('comm-notice')   → 공지사항
navigate('comm-internal') → 내부게시판
navigate('comm-external') → 외부게시판
navigate('comm-archive')  → 자료실
```
- 시스템 점검 공지 등록 (3/5 23:00~06:00)
- 내부게시판 신규 게시글 확인
- 외부게시판 문의 응대
- 자료실 문서 업데이트

#### 17:00 — 일일 마감 점검
```
navigate('quality') → 데이터 품질현황 종합
navigate('process') → 데이터 워크플로우
```
- 일일 품질 점수 최종 확인
- 워크플로우 완료율 확인
- 야간 배치 스케줄 최종 점검

### 보안관리자 역할 업무 차이

보안관리자는 시스템 운영보다 **보안·감사·컴플라이언스**에 집중:

```
[핵심 접근 화면]
navigate('sys-user')        → 사용자 계정 보안 감사
navigate('sys-role')        → 역할·권한 정책 검토
navigate('sys-security')    → 데이터등급·보안정책 관리 (핵심)
navigate('sys-audit')       → 접속통계·감사로그 (핵심)
navigate('dist-deidentify') → 비식별화·가명처리 감사

[접근 불가]
수집·정제 파이프라인 (col-pipeline, col-cdc 등) → 차단
메타데이터 관리 (meta-glossary 등) → 차단
```

---

## 6. 역할별 접근 화면 비교표

### 범례
- O : 접근 가능
- X : 접근 불가
- ALL : 전체 접근

| 화면 (screen-id) | 일반사용자 | 부서관리자 | 스튜어드 | 데이터조회 | 외부개발자 | 파이프라인 | DBA | 시스템관리자 | 보안관리자 |
|------------------|----------|----------|--------|----------|----------|----------|-----|-----------|----------|
| **통합대시보드** | | | | | | | | | |
| home | O | O | O | O | O | O | O | O | O |
| process | O | O | O | X | X | O | O | O | O |
| quality | O | O | O | X | X | O | O | O | O |
| measurement | O | O | O | X | X | O | O | O | O |
| asset-db | X | X | X | X | X | O | O | O | X |
| ai | O | O | O | O | O | O | O | O | O |
| gallery | O | O | O | O | O | O | O | O | O |
| **카탈로그·탐색** | | | | | | | | | |
| cat-search | O | O | O | O | O | O | O | O | O |
| cat-detail | O | O | O | O | O | O | O | O | O |
| cat-graph | O | O | O | O | O | O | O | O | O |
| cat-lineage | O | O | O | O | O | O | O | O | O |
| cat-bookmark | O | O | O | O | O | O | O | O | O |
| cat-request | O | O | O | O | O | O | O | O | O |
| **수집·정제** | | | | | | | | | |
| col-pipeline | X | X | O | X | X | O | O | O | X |
| col-register | X | X | O | X | X | O | O | X | X |
| col-cdc | X | X | O | X | X | O | O | O | X |
| col-kafka | X | X | O | X | X | O | O | O | X |
| col-external | X | X | O | X | X | O | O | O | X |
| col-arch | X | O | O | X | X | O | O | O | O |
| col-monitor | X | O | O | X | X | O | O | O | X |
| col-log | X | X | X | X | X | O | O | O | X |
| col-dbt | X | X | O | X | X | O | O | O | X |
| **유통·활용** | | | | | | | | | |
| dist-product | O | O | O | X | X | O | O | X | X |
| dist-deidentify | X | O | O | X | X | X | X | X | O |
| dist-approval | O | O | O | O | O | O | O | X | X |
| dist-api | X | O | O | X | O | X | X | X | X |
| dist-external | X | O | O | X | X | X | X | X | X |
| dist-stats | O | O | O | X | X | O | O | O | X |
| dist-chart-content | X | X | O | X | X | O | O | O | O |
| **메타데이터 관리** | | | | | | | | | |
| meta-glossary | X | O | O | X | X | X | O | X | X |
| meta-tag | X | O | O | X | X | X | O | X | X |
| meta-model | X | O | O | X | X | X | O | X | X |
| meta-dq | X | O | O | X | X | O | O | X | X |
| meta-ontology | X | X | O | X | X | X | O | X | X |
| **시스템관리** | | | | | | | | | |
| sys-user | X | X | X | X | X | X | X | O | O |
| sys-role | X | X | X | X | X | X | X | O | O |
| sys-security | X | X | O | X | X | X | X | O | O |
| sys-interface | X | X | X | X | X | O | X | O | X |
| sys-audit | X | X | X | X | X | X | X | O | O |
| sys-widget-template | X | X | X | X | X | X | X | O | O |
| **커뮤니티** | | | | | | | | | |
| comm-notice | O | O | O | O | O | O | O | O | O |
| comm-internal | O | O | O | X | X | O | O | O | X |
| comm-external | X | X | X | O | O | X | X | O | X |
| comm-archive | O | O | O | O | O | O | O | O | O |

> **슈퍼관리자**는 위 모든 화면에 접근 가능 (ALL)

---

## 부록: 화면 네비게이션 요약

### 수공직원 추천 동선 (일반사용자)
```
home → quality → cat-search → cat-detail → cat-lineage
→ dist-product → dist-approval → comm-notice
```

### 협력직원 추천 동선 (외부개발자)
```
home → cat-search → cat-detail → cat-graph
→ dist-approval → dist-api → comm-external
```

### 데이터엔지니어 추천 동선 (파이프라인관리자)
```
home → measurement → col-pipeline → col-monitor → col-cdc
→ col-kafka → col-dbt → meta-dq → sys-interface
```

### 관리자 추천 동선 (시스템관리자)
```
home → sys-audit → sys-user → sys-security
→ sys-interface → col-monitor → quality
```
