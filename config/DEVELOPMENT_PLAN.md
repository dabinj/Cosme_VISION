# Cosme_VISION Development Plan

## 1. Objective

이 프로젝트의 1차 목표는 화장품 판매 사이트에서 상품명, 브랜드, 카테고리, 전성분, 가격, 리뷰 등 분석 가능한 메타데이터를 안정적으로 수집하고 정규화하는 것이다.

이 프로젝트의 2차 목표는 정규화된 전성분 데이터를 기반으로 사용자가 원하는 성분, 피하고 싶은 성분, 피부 타입/민감 조건에 맞춰 화장품을 비교 분석할 수 있는 Shiny 기반 웹 플랫폼을 구축하는 것이다.

## 2. Current Scope

현재 구현 범위는 아직 초기 세팅 단계이며, 우선 아래 범위를 기준으로 개발을 시작한다.

- 프로젝트 문서 구조 수립
- 수집 대상 데이터 모델 정의
- 성분 표준화 기준 설계
- 사용자 성분 선호/비선호 비교 로직 정의
- Shiny 앱 모듈 구조 설계

## 3. Phase Scope

### 3.1 Data Acquisition

- 판매 사이트 상품 목록 수집
- 상품 상세 페이지 수집
- 전성분 텍스트 추출
- 브랜드 / 카테고리 / 가격 / 용량 / 리뷰 수 메타데이터 수집
- 수집 실패 / 차단 케이스 로그 적재

### 3.2 Ingredient Normalization

- 전성분 문자열 정제
- 구분자 / 괄호 / 특수문자 정규화
- 국문 / 영문 / INCI 명칭 매핑
- 동의어 사전 구축
- 알레르겐 / 향료 / 보존제 / 기능성 성분 태깅

### 3.3 Product Scoring

- 사용자 선호 성분 매칭 점수
- 사용자 비선호 성분 패널티 점수
- 피부 타입별 rule-based 적합도 점수
- 제품 간 상대 비교 지표
- 위험 신호 요약 생성

### 3.4 Shiny Platform

- 상품 검색 페이지
- 전성분 상세 분석 페이지
- 제품 비교 페이지
- 사용자 맞춤 필터 페이지
- 결과 다운로드 및 리포트 출력

## 4. Next Development Tasks

### 4.1 Repository Skeleton

- `app.R` 또는 `run_app.R` 엔트리포인트 결정
- `R/`, `scripts/`, `data/`, `config/`, `www/` 디렉터리 구성
- 환경변수 / 수집 설정 파일 분리

### 4.2 Crawling / Ingestion

- `goodsNo` 수집 후 `detail` API로 상품 메타와 썸네일 확보
- `article` API로 상세공시와 전성분 확보
- `description` API로 상세 이미지 URL 보조 수집
- 올리브영 `goodsNo` 기준 상세 페이지 수집 검증
- `상품정보 제공고시` 본문이 SSR HTML인지, hydration 이후 데이터인지 판별
- 클릭 이벤트 시 추가 API 호출 존재 여부 확인
- 카테고리 / 검색 기반 상품 목록 수집기 작성
- 상품 상세 HTML 저장 구조 정의
- 상세 페이지 파서 작성
- 수집 간격 / 재시도 / 중복 방지 정책 추가

### 4.2.1 Olive Young Notice Validation Prototype

- 단일 `goodsNo` 대상 상세 페이지 원문 HTML 저장
- HTML 내 `self.__next_f` 또는 dehydrated state에서 상품 메타 추출
- `상품정보 제공고시`, `전성분`, `사용기한`, `용량`, `제조국` 문자열 존재 여부 점검
- 초기 HTML에 본문이 없으면 브라우저 Network 기준 추가 엔드포인트 후보 추적
- 검증 결과를 `collectible`, `requires_browser`, `needs_api_trace` 상태로 분류

### 4.3 Ingredient Dictionary

- 원문 전성분 저장
- 토큰화 결과 저장
- canonical ingredient dictionary 설계
- 금지 / 주의 / 권장 성분 rule table 설계

### 4.4 Analysis Engine

- 사용자 프로필 입력 스키마 설계
- ingredient match / mismatch 함수 작성
- 제품 비교 랭킹 로직 작성
- explainable summary 문구 생성 로직 작성

### 4.5 UI / Reporting

- 검색 결과 테이블
- 상품 상세 카드
- 비교 결과 heatmap 또는 matrix
- 성분 위험도 요약 배지
- CSV / HTML 리포트 출력

## 5. Risks

- 특정 판매 사이트의 구조 변경으로 크롤러가 쉽게 깨질 수 있음
- robots / 이용약관 / 트래픽 제한 정책 검토가 필요함
- 전성분 표기가 상품별로 불완전하거나 누락될 수 있음
- 동일 성분의 국문/영문/약칭 표기가 일관되지 않을 수 있음
- 사용자 피부 적합도는 의료적 판단이 아니라 rule-based 보조 정보로 제한해야 함

## 6. Recommended Immediate Order

1. `goodsNo -> detail -> article -> description` 수집 순서 고정
2. 올리브영 상세공시 수집 가능 여부 프로토타입 검증
3. 수집 대상 필드와 저장 포맷 고정
4. 상품 상세 HTML 파서와 전성분 추출기 작성
5. 성분 정규화 사전 초안 구축
6. 사용자 선호/비선호 기반 비교 함수 작성
7. Shiny MVP 화면 연결
