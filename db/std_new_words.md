# K-water 표준사전 신규 등록 대상 단어 목록

> 포탈 운영 DB 스키마에서 사용되나 K-water 표준 단어사전에 미등록된 단어
> 작성일: 2026-03-11

## 신규 등록 필요 단어 (데이터 거버넌스/플랫폼 특화)

| # | 한글명 | 영문약어 | 영문풀명 | 속성분류 | 비고 |
|---|--------|----------|----------|----------|------|
| 1 | 활성 | ACTV | ACTIVE | N | 상태값 |
| 2 | 영향 | AFCTD | AFFECTED | N | 품질 이슈 관련 |
| 3 | 승인 | APRV | APPROVE | N | 동사형 |
| 4 | 승인됨 | APRVD | APPROVED | N | 과거분사형 |
| 5 | 보관됨 | ARCHVD | ARCHIVED | N | 상태값 |
| 6 | 자산 | ASSET | ASSET | N | 데이터 자산 |
| 7 | 배정됨 | ASGND | ASSIGNED | N | 품질 이슈 담당자 |
| 8 | 속성 | ATTR | ATTRIBUTE | N | 약어 유지 |
| 9 | 게시판 | BOARD | BOARD | N | 커뮤니티 |
| 10 | 바이트 | BYTES | BYTES | N | 데이터 크기 단위 |
| 11 | 호출 | CALLS | CALLS | N | API 호출 횟수 |
| 12 | 가능 | CAN | CAN | N | 권한 접두어 |
| 13 | 카디널리티 | CRDNLT | CARDINALITY | N | 온톨로지 관계 |
| 14 | CDC | CDC | CHANGE DATA CAPTURE | N | 수집 방식 |
| 15 | 변경됨 | CHGD | CHANGED | N | 이력 관련 |
| 16 | 대화 | CHAT | CHAT | N | AI 대화 |
| 17 | 접근등급 | CLRNC | CLEARANCE | N | 보안 접근 등급 |
| 18 | 클러스터 | CLSTR | CLUSTER | N | Kafka 클러스터 |
| 19 | 수집 | COLCT | COLLECT | N | 데이터 수집 |
| 20 | 완전성 | CMPLTN | COMPLETENESS | N | 품질 차원 |
| 21 | 준수율 | CMPLNC | COMPLIANCE | N | 표준 준수율 |
| 22 | 설정 | CNFG | CONFIG | N | 설정 JSON |
| 23 | 커넥터 | CNCTR | CONNECTOR | N | CDC 커넥터 |
| 24 | 일관성 | CNSTNC | CONSISTENCY | N | 품질 차원 |
| 25 | 코어 | CORES | CORES | N | CPU 코어 수 |
| 26 | 생성 | CRT | CREATE | N | 동사형 |
| 27 | 생성됨 | CRTD | CREATED | N | 감사 컬럼 |
| 28 | 데이터센터 | DTCNTR | DATACENTER | N | 서버 위치 |
| 29 | 데이터셋 | DSET | DATASET | N | 데이터 카탈로그 |
| 30 | DBT | DBT | DATA BUILD TOOL | N | 변환 도구 |
| 31 | 비식별화 | DIDNTF | DEIDENTIFY | N | 개인정보 비식별 |
| 32 | 설명약어 | DESC | DESCRIPTION SHORT | N | 약어 유지 |
| 33 | 유통 | DIST | DISTRIBUTION | N | 데이터 유통 |
| 34 | 품질 | DQ | DATA QUALITY | N | 약어 |
| 35 | 엣지 | EDGE | EDGE | N | 리니지 관계 |
| 36 | 유효 | EFTV | EFFECTIVE | N | 정책 유효기간 |
| 37 | 영문 | EN | ENGLISH | N | 언어 구분 |
| 38 | 엔드포인트 | ENDPT | ENDPOINT | N | API URL |
| 39 | 이벤트 | EVNT | EVENTS | N | CDC 이벤트 |
| 40 | 만료 | EXPIR | EXPIRE | N | 동사형 |
| 41 | 만료됨 | EXPIRS | EXPIRES | N | API 키 만료 |
| 42 | 실패 | FAIL | FAIL | N | 상태값 |
| 43 | 실패됨 | FAILD | FAILED | N | 상태값 |
| 44 | 필터가능 | FLTRBL | FILTERABLE | N | 필드 속성 |
| 45 | 완료시각 | FNSHED | FINISHED | N | 실행 완료 |
| 46 | 기가바이트 | GB | GIGABYTE | N | 저장 단위 |
| 47 | 그룹복수 | GRPS | GROUPS | N | 복수형 |
| 48 | 해시 | HASH | HASH | N | API 키 해시 |
| 49 | 인원수 | HDCNT | HEADCOUNT | N | 부서 인원 |
| 50 | 시간 | HR | HOURS | N | 보존 시간 |
| 51 | 설치 | INSTL | INSTALL | N | 센서 설치 |
| 52 | 연계 | INTGRN | INTEGRATION | N | 외부 연계 |
| 53 | 카프카 | KAFKA | KAFKA | N | 스트리밍 플랫폼 |
| 54 | 한글 | KO | KOREAN | N | 언어 구분 |
| 55 | 지연 | LAG | LAG | N | CDC 지연 |
| 56 | 좋아요 | LIKE | LIKE | N | 게시판 좋아요 |
| 57 | 리니지 | LNAGE | LINEAGE | N | 데이터 계보 |
| 58 | 실체화 | MTRLZN | MATERIALIZATION | N | dbt 모델 |
| 59 | 메가바이트 | MB | MEGABYTE | N | 데이터 크기 |
| 60 | 메시지 | MSG | MESSAGE | N | 알림/채팅 |
| 61 | 메타데이터 | MTDATA | METADATA | N | 부가 정보 |
| 62 | MIME | MIME | MIME TYPE | N | 파일 유형 |
| 63 | 명명 | NAMNG | NAMING | N | 명명 규칙 |
| 64 | 알림 | NOTI | NOTIFICATION | N | 약어 |
| 65 | 널허용 | NULBL | NULLABLE | N | 컬럼 속성 |
| 66 | 온톨로지 | ONTO | ONTOLOGY | N | 지식 체계 |
| 67 | 조직 | ORG | ORGANIZATION | N | 외부 조직 |
| 68 | 전체 | OVRALL | OVERALL | N | 종합 점수 |
| 69 | 재정의 | OVRD | OVERRIDE | N | 위젯 설정 |
| 70 | 파티션 | PRTITN | PARTITION | N | Kafka 파티션 |
| 71 | 통과됨 | PASSD | PASSED | N | 품질 결과 |
| 72 | 전화 | PHONE | PHONE | N | 연락처 |
| 73 | 고정됨 | PINND | PINNED | N | 공지사항 |
| 74 | 파이프라인 | PPLN | PIPELINE | N | 수집 파이프라인 |
| 75 | 접두어 | PRFX | PREFIX | N | API 키 |
| 76 | 프로파일됨 | PRFLD | PROFILED | N | 프로파일링 |
| 77 | 제공됨 | PRVDD | PROVIDED | N | 외부 제공 |
| 78 | 발행됨 | PBLSHD | PUBLISHED | N | 데이터 발행 |
| 79 | 범위 | RNG | RANGE | N | 센서 범위 |
| 80 | 레코드복수 | RCRDS | RECORDS | N | 복수형 |
| 81 | 참조 | REF | REFERENCE | N | FK 참조 |
| 82 | 복제 | RPLCTN | REPLICATION | N | Kafka 복제 |
| 83 | 필수 | REQRD | REQUIRED | N | 필드 속성 |
| 84 | 해결됨 | RSLVD | RESOLVED | N | 이슈 해결 |
| 85 | 보존 | RTNTN | RETENTION | N | 보존 기간 |
| 86 | 행복수 | ROWS | ROWS | N | 복수형 |
| 87 | 실행 | RUN | RUN | N | dbt 실행 |
| 88 | 초 | SEC | SECOND | N | 시간 단위 |
| 89 | 건너뜀 | SKIPD | SKIPPED | N | 동기화 결과 |
| 90 | 시작됨 | STRTD | STARTED | N | 실행 시작 |
| 91 | 스튜어드 | STWRD | STEWARD | N | 데이터 관리 |
| 92 | 테이블복수 | TBLS | TABLES | N | 복수형 |
| 93 | 태그복수 | TAGS | TAGS | N | 복수형 |
| 94 | 용어 | TERM | TERM | N | 표준용어 |
| 95 | 처리량 | THRPUT | THROUGHPUT | N | 파이프라인 |
| 96 | 타임라인 | TMLN | TIMELINE | N | 처리 이력 |
| 97 | 적시성 | TMLNS | TIMELINESS | N | 품질 차원 |
| 98 | 토큰 | TKNS | TOKENS | N | AI 사용량 |
| 99 | 토픽 | TOPC | TOPIC | N | Kafka 토픽 |
| 100 | 변환 | TRSFM | TRANSFORM | N | 데이터 변환 |
| 101 | 변환규칙 | TRSFMN | TRANSFORMATION | N | 변환 정의 |
| 102 | 유일성 | UNQNS | UNIQUENESS | N | 품질 차원 |
| 103 | 수정됨 | UPDTD | UPDATED | N | 감사 컬럼 |
| 104 | 가동률 | UPTM | UPTIME | N | SLA 가동률 |
| 105 | 긴급 | URGNT | URGENT | N | 신청 긴급 |
| 106 | 활용 | USG | USAGE | N | 활용 통계 |
| 107 | 사용자복수 | USRS | USERS | N | 복수형 |
| 108 | 값복수 | VALS | VALUES | N | 복수형 |
| 109 | 표시여부 | VSBL | VISIBLE | N | 위젯 표시 |

## 보정 단어 (기존 표준사전 약어 수정 권고)

| # | 한글명 | 현재약어 | 권고약어 | 사유 |
|---|--------|----------|----------|------|
| 1 | 엔티티 | ENTIY | ENTTY | 오타 보정 |
| 2 | 일자 | DE | DT | 직관성 향상 |
| 3 | 시스템 | SYST | SYS | IT 관용 약어 |
| 4 | 율 | RO | RT | 직관성 향상 |
| 5 | 이력 | HSTRY | HIST | IT 관용 약어 |
| 6 | 세션 | SESION | SESN | 축약 일관성 |
| 7 | 원천 | SORC | SRC | IT 관용 약어 |
| 8 | 실행 | EXC | EXEC | IT 관용 약어 |
| 9 | 필드 | FIED | FIELD | 이미 짧음 |
| 10 | 파일 | FL | FILE | 이미 짧음 |
| 11 | 빈도 | FQ | FREQ | 직관성 향상 |
| 12 | 표현식 | EPRSS | EXPR | IT 관용 약어 |
