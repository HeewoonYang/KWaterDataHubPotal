"""
전체 마이그레이션 순차 실행
실행 순서: 도메인그룹 → 단어사전 → 도메인사전 → 용어사전 → 코드사전
"""
import time
import importlib


def run():
    print("=" * 60)
    print("K-water 메타데이터 표준사전 마이그레이션 시작")
    print("=" * 60)

    start = time.time()
    scripts = [
        ("01_migrate_domain_group", "도메인그룹"),
        ("02_migrate_word_dict", "단어사전"),
        ("03_migrate_domain_dict", "도메인사전"),
        ("04_migrate_term_dict", "용어사전"),
        ("05_migrate_code_dict", "코드사전"),
    ]

    results = {}
    for module_name, label in scripts:
        print(f"\n{'=' * 60}")
        print(f"실행: {label}")
        print(f"{'=' * 60}")
        t = time.time()
        try:
            mod = importlib.import_module(module_name)
            count = mod.migrate()
            elapsed = time.time() - t
            results[label] = {"count": count, "elapsed": f"{elapsed:.1f}s", "status": "성공"}
            print(f"  → {label} 완료: {count}건 ({elapsed:.1f}초)")
        except Exception as e:
            elapsed = time.time() - t
            results[label] = {"count": 0, "elapsed": f"{elapsed:.1f}s", "status": f"실패: {e}"}
            print(f"  → {label} 실패: {e}")

    total_elapsed = time.time() - start

    print("\n" + "=" * 60)
    print("마이그레이션 결과 요약")
    print("=" * 60)
    for label, info in results.items():
        print(f"  {label}: {info['count']}건 | {info['elapsed']} | {info['status']}")
    print(f"\n  총 소요시간: {total_elapsed:.1f}초")
    print("=" * 60)


if __name__ == "__main__":
    run()
