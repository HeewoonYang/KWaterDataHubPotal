"""
마이그레이션 설정
"""
import os

# PostgreSQL 연결 정보
DB_CONFIG = {
    "host": os.environ.get("DB_HOST", "localhost"),
    "port": int(os.environ.get("DB_PORT", "5434")),
    "dbname": os.environ.get("DB_NAME", "datahub_meta"),
    "user": os.environ.get("DB_USER", "meta_admin"),
    "password": os.environ.get("DB_PASSWORD", "meta1234"),
}

# 엑셀 파일 경로
EXCEL_DIR = os.path.join(os.path.dirname(__file__), "..", "metadata_excel")
WORD_FILE = os.path.join(EXCEL_DIR, "표준 데이터 조회_K-water데이터표준_단어사전.xlsx")
DOMAIN_FILE = os.path.join(EXCEL_DIR, "표준 데이터 조회_K-water데이터표준_도메인사전.xlsx")
TERM_FILE = os.path.join(EXCEL_DIR, "표준 데이터 조회_K-water데이터표준_용어사전.xlsx")
CODE_FILE = os.path.join(EXCEL_DIR, "표준 데이터 조회_K-water데이터표준_코드사전.xlsx")

# 배치 크기
BATCH_SIZE = 5000
