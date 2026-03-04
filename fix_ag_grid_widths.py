#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
AG Grid 헤더 너비 최적화 스크립트
─────────────────────────────────
한글 헤더 '...' 잘림 해결
최소 너비 = 글자수 x 13.5 + 40 (패딩+정렬아이콘)
  2자: 70px, 3자: 84px, 4자: 96px, 5자: 110px
"""

MAIN_JS = r"D:\00_수공프로젝트\datahubPotal\js\main.js"

# (old_text, new_text)  -  str.replace 로 전체 교체
CHANGES = [
    # ━━━━━ 커뮤니티 게시판 (4 tables) ━━━━━
    ("headerName: '첨부', width: 55",       "headerName: '첨부', width: 70"),
    ("headerName: '조회', width: 55",       "headerName: '조회', width: 70"),
    ("headerName: '댓글', width: 55",       "headerName: '댓글', width: 70"),       # x2 tables
    ("headerName: '다운', width: 60",       "headerName: '다운', width: 70"),
    ("headerName: '받기', width: 55",       "headerName: '받기', width: 70"),

    # ━━━━━ 카탈로그 (3 tables) ━━━━━
    ("headerName: '프로파일링', width: 95",  "headerName: '프로파일링', width: 110"),
    ("headerName: '품질', width: 65",        "headerName: '품질', width: 70"),
    ("headerName: '도메인', width: 75",      "headerName: '도메인', width: 84"),     # cat-bookmark
    ("headerName: '요청번호', width: 85",    "headerName: '요청번호', width: 96"),
    ("headerName: '요청자', width: 75",      "headerName: '요청자', width: 84"),
    ("headerName: '요청일', width: 70",      "headerName: '요청일', width: 84"),

    # ━━━━━ 수집·정제 (3 tables) ━━━━━
    ("headerName: '원본시스템', width: 100",  "headerName: '원본시스템', width: 110"),
    ("headerName: '스케줄', width: 80",      "headerName: '스케줄', width: 84"),
    ("headerName: '처리량', width: 80",      "headerName: '처리량', width: 84"),
    ("headerName: '최근실행', width: 80",    "headerName: '최근실행', width: 96"),
    ("headerName: '연계방식', width: 90",    "headerName: '연계방식', width: 96"),
    ("headerName: '최근동기화', width: 90",  "headerName: '최근동기화', width: 110"),
    ("headerName: '레코드수', width: 75",    "headerName: '레코드수', width: 96"),
    ("headerName: '실행시간', width: 70",    "headerName: '실행시간', width: 96"),

    # ━━━━━ 유통·활용 (2 tables) ━━━━━
    ("headerName: '등급', width: 60",        "headerName: '등급', width: 70"),
    ("headerName: '유통상태', width: 80",    "headerName: '유통상태', width: 96"),
    ("headerName: '일간호출', width: 75",    "headerName: '일간호출', width: 96"),
    ("headerName: '최종갱신', width: 80",    "headerName: '최종갱신', width: 96"),
    ("headerName: '적용등급', width: 70",    "headerName: '적용등급', width: 96"),

    # ━━━━━ 메타데이터 (4 tables) ━━━━━
    ("headerName: '표준용어', width: 80",    "headerName: '표준용어', width: 96"),
    ("headerName: '약어', width: 55",        "headerName: '약어', width: 70"),
    ("headerName: '도메인', width: 70",      "headerName: '도메인', width: 82"),     # x3 tables
    ("headerName: '단위', width: 55",        "headerName: '단위', width: 70"),
    ("headerName: '코드그룹명', width: 90",  "headerName: '코드그룹명', width: 110"),
    ("headerName: '코드 수', width: 65",     "headerName: '코드 수', width: 82"),
    ("headerName: '최종수정', width: 90",    "headerName: '최종수정', width: 96"),
    ("headerName: '도메인명', width: 80",    "headerName: '도메인명', width: 96"),
    ("headerName: '연결 자산', width: 80",   "headerName: '연결 자산', width: 96"),
    ("headerName: '색상', width: 55",        "headerName: '색상', width: 70"),
    ("headerName: '관리자', width: 75",      "headerName: '관리자', width: 84"),
    ("headerName: '보안등급', width: 65",    "headerName: '보안등급', width: 96"),
    ("headerName: '업무영역', width: 60",    "headerName: '업무영역', width: 96"),
    ("headerName: '변경 유형', width: 75",   "headerName: '변경 유형', width: 96"),
    ("headerName: '변경자', width: 65",      "headerName: '변경자', width: 84"),

    # ━━━━━ 시스템관리 (4 tables) ━━━━━
    ("headerName: '데이터접근', width: 80",  "headerName: '데이터접근', width: 110"),
    ("headerName: '최종로그인', width: 105",  "headerName: '최종로그인', width: 110"),
    ("headerName: '최근 동기화', width: 90",  "headerName: '최근 동기화', width: 110"),
    ("headerName: '응답크기', width: 75",    "headerName: '응답크기', width: 96"),
    ("headerName: '사용자', width: 80",      "headerName: '사용자', width: 84"),

    # ━━━━━ 공통 패턴 (복수 테이블) ━━━━━
    ("headerName: '관리', width: 55",        "headerName: '관리', width: 70"),       # x5 tables
    ("headerName: '액션', width: 55",        "headerName: '액션', width: 70"),       # x2 tables
    ("headerName: '액션', width: 65",        "headerName: '액션', width: 70"),       # meta-domain
    ("headerName: '상태', width: 60",        "headerName: '상태', width: 70"),       # meta-domain
    ("headerName: '상태', width: 65",        "headerName: '상태', width: 70"),       # col-dbt
]


def main():
    with open(MAIN_JS, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    total = 0
    not_found = []

    print('=' * 56)
    print('  AG Grid Header Width Optimization')
    print('=' * 56)

    for old_text, new_text in CHANGES:
        count = content.count(old_text)
        if count > 0:
            content = content.replace(old_text, new_text)
            new_w = new_text.split('width: ')[1]
            old_w = old_text.split('width: ')[1]
            hdr = old_text.split("'")[1]
            print(f'  [{count}] {hdr:8s}  {old_w:>3s} -> {new_w}')
            total += count
        else:
            not_found.append(old_text)

    if not_found:
        print(f'\n  [SKIP] {len(not_found)}건 - 이미 적용 또는 패턴 없음')
        for nf in not_found:
            hdr = nf.split("'")[1]
            w = nf.split('width: ')[1]
            print(f'         {hdr} (width: {w})')

    if content != original:
        with open(MAIN_JS, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'\n[OK] {total}건 교체 완료 - main.js 저장됨')
    else:
        print('\n[!] 변경사항 없음')


if __name__ == '__main__':
    main()
