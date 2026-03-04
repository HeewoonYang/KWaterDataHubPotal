#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
AG Grid 헤더 너비 최적화 v3 — 실측 기반 정밀 수정
═══════════════════════════════════════════════════
실측 결과:
  AG Grid header overhead = 44px (padding 36px + resize 8px)
  안전여유 8px 포함 → 총 오버헤드 52px
  한글 1글자 = 12px

  2글자 → 76px min → 80px  (번호,약어,등급,관리,상태,액션,유형 등)
  3글자 → 88px min → 90px  (도메인,사용자,작성자,스케줄 등)
  4글자 → 100px min → 102px (요청번호,연계방식,표준용어,보안등급 등)
  5글자 → 112px min → 115px (원본시스템,대상데이터,코드그룹명 등)

핵심 전략:
  1. minWidth 70→80 (2글자 한글 글로벌 해결)
  2. 개별 컬럼 정밀 수정 (3글자 이상)
"""

MAIN_JS = r"D:\00_수공프로젝트\datahubPotal\js\main.js"


def main():
    with open(MAIN_JS, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    original = ''.join(lines)
    changes = []

    def fix(line_num, old, new, desc):
        """라인 번호 기반 정밀 교체"""
        idx = line_num - 1
        if idx < len(lines) and old in lines[idx]:
            lines[idx] = lines[idx].replace(old, new)
            changes.append(f'  L{line_num}: {desc}')
            return True
        else:
            changes.append(f'  L{line_num}: [SKIP] "{old}" not found')
            return False

    # ═══════════════════════════════════════════
    # 1. 글로벌: minWidth 70 → 80
    # ═══════════════════════════════════════════
    fix(18, 'minWidth: 70', 'minWidth: 80',
        'minWidth 70→80 (2글자 한글 글로벌 해결: 번호,약어,등급,관리,상태 등)')

    # ═══════════════════════════════════════════
    # 2. 3글자 한글 (need 88→set 90)
    # ═══════════════════════════════════════════
    fix(1783, "width: 84", "width: 90",
        '도메인 84→90 (cat-bookmark)')
    fix(1934, "width: 82", "width: 90",
        '도메인 82→90 (dist-product)')
    fix(2000, "width: 82", "width: 90",
        '도메인 82→90 (meta-glossary)')
    fix(2070, "width: 82", "width: 90",
        '도메인 82→90 (meta-tag-history)')
    fix(2196, "width: 84", "width: 90",
        '사용자 84→90 (sys-audit)')

    # ═══════════════════════════════════════════
    # 3. 4글자 한글 (need 100→set 102)
    # ═══════════════════════════════════════════
    fix(1808, "width: 96", "width: 102",
        '요청번호 96→102 (cat-request)')
    fix(1870, "width: 96", "width: 102",
        '연계방식 96→102 (col-system)')
    fix(1996, "width: 96", "width: 102",
        '표준용어 96→102 (meta-glossary)')
    fix(2051, "width: 96", "width: 102",
        '도메인명 96→102 (meta-domain)')
    fix(2072, "width: 96", "width: 102",
        '보안등급 96→102 (meta-tag-history)')
    fix(2078, "width: 96", "width: 102",
        '업무영역 96→102 (meta-tag-history)')
    fix(2080, "width: 96", "width: 102",
        '변경 유형 96→102 (meta-tag-history)')

    # ═══════════════════════════════════════════
    # 4. 5글자 한글 (need 112→set 115)
    # ═══════════════════════════════════════════
    fix(1810, "width: 105", "width: 115",
        '대상데이터 105→115 (cat-request)')
    fix(1833, "width: 110", "width: 115",
        '원본시스템 110→115 (col-pipeline)')
    fix(2028, "width: 110", "width: 115",
        '코드그룹명 110→115 (meta-code)')

    # ═══════════════════════════════════════════
    # 5. 특수 (코드 수 = 40px text → need 92)
    # ═══════════════════════════════════════════
    fix(2029, "width: 82", "width: 94",
        '코드 수 82→94 (meta-code, 3글자+공백)')

    # ═══════════════════════════════════════════
    # 6. 영문 헤더 (Method = ~48px text → need ~100)
    # ═══════════════════════════════════════════
    fix(2162, "width: 70", "width: 90",
        'Method 70→90 (sys-api-log, 영문6자)')

    # ═══════════════════════════════════════════
    # 7. 보더라인 수정 (유형 75→80, 2글자+패딩부족)
    # ═══════════════════════════════════════════
    fix(2197, "width: 75", "width: 80",
        '유형 75→80 (sys-audit, 보더라인)')

    # ═══════════════════════════════════════════
    # 결과 출력
    # ═══════════════════════════════════════════
    content = ''.join(lines)
    print('=' * 60)
    print('  AG Grid Width Optimization v3 (실측 기반)')
    print('=' * 60)
    for c in changes:
        print(c)

    applied = sum(1 for c in changes if '[SKIP]' not in c)
    skipped = sum(1 for c in changes if '[SKIP]' in c)

    if content != original:
        with open(MAIN_JS, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'\n[OK] {applied}건 적용, {skipped}건 스킵 — main.js 저장됨')
    else:
        print(f'\n[!] 변경사항 없음 ({skipped}건 스킵)')


if __name__ == '__main__':
    main()
