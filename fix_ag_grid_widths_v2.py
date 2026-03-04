#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
AG Grid 헤더 너비 최적화 v2
─────────────────────────────
문제: flex 없는 테이블, 과도한 너비, 아직 잘리는 헤더
해결: 라인번호 기반 정밀 수정
"""

MAIN_JS = r"D:\00_수공프로젝트\datahubPotal\js\main.js"

def main():
    with open(MAIN_JS, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    original = ''.join(lines)
    changes = []

    # ━━━━━ 1. comm-notice: 조회 65→70 (line 1671) ━━━━━
    ln = 1671 - 1
    if "headerName: '조회', width: 65" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 65", "width: 70")
        changes.append("L1671: 조회 65→70")

    # ━━━━━ 2. comm-internal: 작성자 80→90 (line 1690) ━━━━━
    ln = 1690 - 1
    if "headerName: '작성자', width: 80" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 80", "width: 90")
        changes.append("L1690: 작성자 80→90")

    # ━━━━━ 3. comm-external: 작성자 80→90 (line 1710) ━━━━━
    ln = 1710 - 1
    if "headerName: '작성자', width: 80" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 80", "width: 90")
        changes.append("L1710: 작성자 80→90")

    # ━━━━━ 4. cat-bookmark: 시스템 80→90 (line 1782) ━━━━━
    ln = 1782 - 1
    if "headerName: '시스템', width: 80" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 80", "width: 90")
        changes.append("L1782: 시스템 80→90")

    # ━━━━━ 5. col-pipeline: 수집방식 95→105 (line 1835) ━━━━━
    ln = 1835 - 1
    if "headerName: '수집방식', width: 95" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 95", "width: 105")
        changes.append("L1835: 수집방식 95→105")

    # ━━━━━ 6. col-system: 프로토콜 95→105 (line 1871) ━━━━━
    ln = 1871 - 1
    if "headerName: '프로토콜', width: 95" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 95", "width: 105")
        changes.append("L1871: 프로토콜 95→105")

    # ━━━━━ 7. col-dbt: 소스 110→85 (너무 넓음, line 1904) ━━━━━
    ln = 1904 - 1
    if "headerName: '소스', width: 110" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 110", "width: 85")
        changes.append("L1904: 소스 110→85 (과도)")

    # ━━━━━ 8. dist-product: 포맷 80→85 (line 1935) ━━━━━
    ln = 1935 - 1
    if "headerName: '포맷', width: 80" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 80", "width: 85")
        changes.append("L1935: 포맷 80→85")

    # ━━━━━ 9. dist-deidentify: 대상필드 140→120 (과도, line 1966) ━━━━━
    ln = 1966 - 1
    if "headerName: '대상필드', width: 140" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 140", "width: 120")
        changes.append("L1966: 대상필드 140→120 (과도)")

    # ━━━━━ 10. dist-deidentify: 처리기법 110→100 (line 1967) ━━━━━
    ln = 1967 - 1
    if "headerName: '처리기법', width: 110" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 110", "width: 100")
        changes.append("L1967: 처리기법 110→100")

    # ━━━━━ 11. dist-deidentify: 상태 75→80 (line 1975) ━━━━━
    ln = 1975 - 1
    if "headerName: '상태', width: 75" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 75", "width: 80")
        changes.append("L1975: 상태 75→80")

    # ━━━━━ 12. dist-deidentify: 적용대상 120→100 (과도, line 1981) ━━━━━
    ln = 1981 - 1
    if "headerName: '적용대상', width: 120" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 120", "width: 100")
        changes.append("L1981: 적용대상 120→100 (과도)")

    # ━━━━━ 13. meta-glossary: 영문명 130→110 (과도, line 1997) ━━━━━
    ln = 1997 - 1
    if "headerName: '영문명', width: 130" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 130", "width: 110")
        changes.append("L1997: 영문명 130→110 (과도)")

    # ━━━━━ 14. meta-code: 코드그룹 120→105 (과도, line 2027) ━━━━━
    ln = 2027 - 1
    if "headerName: '코드그룹', width: 120" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 120", "width: 105")
        changes.append("L2027: 코드그룹 120→105 (과도)")

    # ━━━━━ 15. sys-user: 이름 width:130 → flex:1 (flex 없음 문제 해결) ━━━━━
    ln = 2104 - 1
    if "headerName: '이름', width: 130" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 130", "flex: 1")
        changes.append("L2104: 이름 width:130→flex:1 (핵심수정)")

    # ━━━━━ 16. sys-user: 부서 110→90 (line 2105) ━━━━━
    ln = 2105 - 1
    if "headerName: '부서', width: 110" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 110", "width: 90")
        changes.append("L2105: 부서 110→90")

    # ━━━━━ 17. sys-user: 역할 110→100 (line 2106) ━━━━━
    ln = 2106 - 1
    if "headerName: '역할', width: 110" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 110", "width: 100")
        changes.append("L2106: 역할 110→100")

    # ━━━━━ 18. sys-user: 상태 85→80 (line 2109) ━━━━━
    ln = 2109 - 1
    if "headerName: '상태', width: 85" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 85", "width: 80")
        changes.append("L2109: 상태 85→80")

    # ━━━━━ 19. sys-user: SSO 55→65 (line 2116) ━━━━━
    ln = 2116 - 1
    if "headerName: 'SSO', width: 55" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 55", "width: 65")
        changes.append("L2116: SSO 55→65")

    # ━━━━━ 20. sys-user: 가입일 95→90 (line 2118) ━━━━━
    ln = 2118 - 1
    if "headerName: '가입일', width: 95" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 95", "width: 90")
        changes.append("L2118: 가입일 95→90")

    # ━━━━━ 21. sys-user: 관리 65→70 (line 2120) ━━━━━
    ln = 2120 - 1
    if "headerName: '관리', width: 65" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 65", "width: 70")
        changes.append("L2120: 관리 65→70")

    # ━━━━━ 22. sys-interface: 상태 75→80 (line 2140) ━━━━━
    ln = 2140 - 1
    if "headerName: '상태', width: 75" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 75", "width: 80")
        changes.append("L2140: 상태 75→80")

    # ━━━━━ 23. sys-interface: 관리 60→70 (line 2148) ━━━━━
    ln = 2148 - 1
    if "headerName: '관리', width: 60" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 60", "width: 70")
        changes.append("L2148: 관리 60→70")

    # ━━━━━ 24. sys-api-log: Status 65→75 (line 2169) ━━━━━
    ln = 2169 - 1
    if "headerName: 'Status', width: 65" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 65", "width: 75")
        changes.append("L2169: Status 65→75")

    # ━━━━━ 25. sys-api-log: 결과 80→75 (line 2177) ━━━━━
    ln = 2177 - 1
    if "headerName: '결과', width: 80" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 80", "width: 75")
        changes.append("L2177: 결과 80→75")

    # ━━━━━ 26. cat-schema: 영문명 130→115 (과도, line 1763) ━━━━━
    ln = 1763 - 1
    if "headerName: '영문명', width: 130" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 130", "width: 115")
        changes.append("L1763: 영문명 130→115 (과도)")

    # ━━━━━ 27. cat-schema: 타입 110→100 (과도, line 1764) ━━━━━
    ln = 1764 - 1
    if "headerName: '타입', width: 110" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 110", "width: 100")
        changes.append("L1764: 타입 110→100 (과도)")

    # ━━━━━ 28. cat-schema: 표준용어 100→96 (line 1767) ━━━━━
    ln = 1767 - 1
    if "headerName: '표준용어', width: 100" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 100", "width: 96")
        changes.append("L1767: 표준용어 100→96")

    # ━━━━━ 29. comm-external: 소속기관 120→100 (과도, line 1711) ━━━━━
    ln = 1711 - 1
    if "headerName: '소속기관', width: 120" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 120", "width: 100")
        changes.append("L1711: 소속기관 120→100 (과도)")

    # ━━━━━ 30. cat-request: 대상데이터 120→105 (과도, line 1810) ━━━━━
    ln = 1810 - 1
    if "headerName: '대상데이터', width: 120" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 120", "width: 105")
        changes.append("L1810: 대상데이터 120→105 (과도)")

    # ━━━━━ 31. cat-request: 상태 85→80 (line 1814) ━━━━━
    ln = 1814 - 1
    if "headerName: '상태', width: 85" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 85", "width: 80")
        changes.append("L1814: 상태 85→80")

    # ━━━━━ 32. meta-glossary: 데이터타입 110→100 (line 2004) ━━━━━
    ln = 2004 - 1
    if "headerName: '데이터타입', width: 110" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 110", "width: 100")
        changes.append("L2004: 데이터타입 110→100")

    # ━━━━━ 33. comm-notice: 작성자 100→90 (line 1669) ━━━━━
    ln = 1669 - 1
    if "headerName: '작성자', width: 100" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 100", "width: 90")
        changes.append("L1669: 작성자 100→90")

    # ━━━━━ 34. comm-notice: 등록일 100→90 (line 1670) ━━━━━
    ln = 1670 - 1
    if "headerName: '등록일', width: 100" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 100", "width: 90")
        changes.append("L1670: 등록일 100→90")

    # ━━━━━ 35. comm-internal: 부서 100→90 (line 1691) ━━━━━
    ln = 1691 - 1
    if "headerName: '부서', width: 100" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 100", "width: 90")
        changes.append("L1691: 부서 100→90")

    # ━━━━━ 36. comm-internal: 등록일 100→90 (line 1692) ━━━━━
    ln = 1692 - 1
    if "headerName: '등록일', width: 100" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 100", "width: 90")
        changes.append("L1692: 등록일 100→90")

    # ━━━━━ 37. comm-external: 등록일 100→90 (line 1719) ━━━━━
    ln = 1719 - 1
    if "headerName: '등록일', width: 100" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 100", "width: 90")
        changes.append("L1719: 등록일 100→90")

    # ━━━━━ 38. comm-archive: 작성자 100→90 (line 1735) ━━━━━
    ln = 1735 - 1
    if "headerName: '작성자', width: 100" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 100", "width: 90")
        changes.append("L1735: 작성자 100→90")

    # ━━━━━ 39. comm-archive: 등록일 100→90 (line 1744) ━━━━━
    ln = 1744 - 1
    if "headerName: '등록일', width: 100" in lines[ln]:
        lines[ln] = lines[ln].replace("width: 100", "width: 90")
        changes.append("L1744: 등록일 100→90")

    # ━━━━━ Results ━━━━━
    content = ''.join(lines)

    print('=' * 56)
    print('  AG Grid Width Optimization v2')
    print('=' * 56)

    for c in changes:
        print(f'  {c}')

    if content != original:
        with open(MAIN_JS, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'\n[OK] {len(changes)}건 수정 완료 - main.js 저장됨')
    else:
        print('\n[!] 변경사항 없음')


if __name__ == '__main__':
    main()
