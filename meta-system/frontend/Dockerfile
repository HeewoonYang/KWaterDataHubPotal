FROM node:20-alpine

WORKDIR /app

# 의존성 설치
COPY package.json package-lock.json* ./
RUN npm install

# 앱 코드 복사
COPY . .

# Vite 개발 서버 실행 (핫 리로드, 외부 접근 허용)
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
