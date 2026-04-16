# Cosme_VISION Module Specification

## 1. Directory Overview

- `config/`: 개발 계획, 로그, 모듈 명세, 운영 메모
- `scripts/`: 수집, 파싱, 정규화, 적재 스크립트
- `R/`: Shiny 서버/화면/분석 함수 모듈
- `data/raw/`: 원본 HTML, API 응답, 수집 로그
- `data/processed/`: 정규화된 상품 및 성분 테이블
- `data/cache/`: 중간 산출물과 재사용 캐시
- `www/`: CSS, JS, 이미지 등 정적 리소스

## 2. Prototype Validation Scripts

### 2.1 `scripts/fetch_oliveyoung_goods_page.R`

역할:

- 단일 `goodsNo` 기준 올리브영 상세 페이지 HTML을 저장한다.

입력:

- `--goods-no`
- `--output-dir`
- `--user-agent` 선택

출력:

- `data/raw/oliveyoung/html/{goods_no}.html`
- `data/raw/oliveyoung/html/{goods_no}.meta.json`

주요 로직:

- 상세 URL 생성
- 브라우저 user-agent로 GET 요청
- 응답 HTML 원문 저장
- 요청 시각과 원본 URL 메타 저장

### 2.2 `scripts/extract_oliveyoung_goods_state.R`

역할:

- 저장된 상세 HTML에서 SSR 상태 기반 기본 상품 메타를 추출한다.

입력:

- `--input-html`
- `--output-file` 선택

출력:

- 단일 상품 메타 CSV 또는 TSV

주요 로직:

- HTML 원문 로드
- `goodsNumber`, `goodsName`, 브랜드, 카테고리, 가격 패턴 추출
- 추출 성공 / 실패 여부 기록

### 2.3 `scripts/probe_oliveyoung_notice_candidates.R`

역할:

- 저장된 HTML 안에 상세공시 / 전성분 관련 문자열과 본문 후보가 존재하는지 검사한다.

입력:

- `--input-html`
- `--output-file` 선택

출력:

- 수집 가능성 판정 리포트

주요 로직:

- `상품정보 제공고시`, `전성분`, `사용기한`, `용량`, `제조국`, `주의사항` 키워드 탐지
- 제목만 존재하는지, 본문 값이 함께 존재하는지 구분
- SSR 수집 가능 / 브라우저 fallback 필요 여부 판정

### 2.4 `scripts/inspect_oliveyoung_notice_strategy.R`

역할:

- 여러 `goodsNo` 샘플에 대해 수집 전략을 비교 검증한다.

입력:

- `--goods-no-file`
- `--html-dir`
- `--output-file`

출력:

- 상품별 전략 판정 테이블

주요 로직:

- 샘플 HTML 반복 검사
- `ssr_only`, `needs_browser`, `needs_network_trace` 분류
- 공시 수집 우선순위 후보 선정

### 2.5 `scripts/fetch_oliveyoung_article_info.R`

역할:

- 올리브영 `goods/api/v1/article`를 호출해 상품정보 제공고시를 구조화된 JSON으로 수집한다.

입력:

- `--goods-no`
- `--standard-code`
- `--option-name`
- `--liquor-flag` 선택
- `--output-dir`

출력:

- `data/raw/oliveyoung/article/{goods_no}.json`

주요 로직:

- 상품정보 제공고시 API payload 생성
- POST 요청 수행
- 응답 JSON 저장
- `articleInfoList` 존재 여부 확인

주요 필드:

- `articleInfoList[].title`
- `articleInfoList[].content`
- `certifications[]`

### 2.6 `scripts/fetch_oliveyoung_detail_info.R`

역할:

- 올리브영 `goods/api/v1/detail`을 호출해 상품 메타와 옵션, 썸네일 정보를 JSON으로 저장한다.

입력:

- `--goods-no`
- `--display-category-number` 선택
- `--tracking-code` 선택
- `--output-dir`

출력:

- `data/raw/oliveyoung/detail/{goods_no}.json`

주요 로직:

- 상품 상세 API GET 요청
- 기본 메타 저장
- `thumbnailImage[]`, `options[]`, 가격 정보 보관

주요 필드:

- `goodsNumber`
- `goodsName`
- `onlineBrandName`
- `displayCategory`
- `thumbnailImage[]`
- `options[].standardCode`
- `options[].optionName`

### 2.7 `scripts/fetch_oliveyoung_description_info.R`

역할:

- 올리브영 `goods/api/v1/description`을 호출해 상세설명 HTML과 상세 이미지 원본 URL 후보를 저장한다.

입력:

- `--goods-no`
- `--output-dir`

출력:

- `data/raw/oliveyoung/description/{goods_no}.json`

주요 로직:

- 상품 설명 API GET 요청
- `descriptionContents` HTML 저장
- 추후 이미지 URL 파싱용 원본 보관

주요 필드:

- `descriptionTypeCode`
- `descriptionContents`
- `goodsDetailImages`

### 2.8 `scripts/extract_oliveyoung_image_urls.R`

역할:

- `detail`과 `description` 응답에서 썸네일과 상세 이미지 URL을 통합 추출한다.

입력:

- `--goods-no`
- `--detail-json`
- `--description-json`
- `--output-file`

출력:

- `data/processed/{goods_no}_image_urls.csv`

주요 로직:

- `thumbnailImage[].url + path` 조합
- `descriptionContents` 내 `src` / `data-src` 추출
- 중복 제거 후 `thumbnail`, `detail` 타입으로 정리

## 3. Planned Script Modules

### 3.1 `scripts/fetch_oliveyoung_listing.R`

역할:

- 카테고리 또는 검색어 기준으로 상품 목록을 수집한다.

입력:

- `--category-id` 또는 `--query`
- `--page-start`
- `--page-end`
- `--output-dir`

출력:

- 상품 목록 raw HTML
- 상품 목록 정규화 CSV / RDS

주요 로직:

- 목록 페이지 요청
- 상품 URL / 상품 ID 추출
- 브랜드 / 상품명 / 가격 / 평점 / 리뷰 수 파싱
- 중복 상품 제거

### 3.2 `scripts/fetch_product_detail.R`

역할:

- 개별 상품 상세 페이지를 수집하고 raw HTML을 저장한다.

입력:

- `--product-id`
- `--input-product-list`
- `--output-dir`

출력:

- 상품별 raw HTML
- 수집 성공/실패 로그

주요 로직:

- 상세 페이지 요청
- 요청 실패 재시도
- 이미 저장된 상품 skip
- 수집 상태 기록

### 3.3 `scripts/parse_product_detail.R`

역할:

- 상품 상세 HTML에서 분석용 필드를 추출한다.

입력:

- `--input-dir`
- `--output-dir`

출력:

- `products` 테이블
- `product_ingredients_raw` 테이블

주요 로직:

- 상품명 / 브랜드 / 카테고리 / 가격 / 용량 추출
- 전성분 텍스트 추출
- 프로모션 / 옵션 여부 추출
- 파싱 실패 케이스 로그화

주요 컬럼:

- `product_id`
- `brand_name`
- `product_name`
- `category_name`
- `price_current`
- `volume_text`
- `ingredients_raw_text`
- `source_url`
- `collected_at`

### 3.4 `scripts/normalize_ingredients.R`

역할:

- 전성분 원문을 토큰화하고 canonical ingredient로 정규화한다.

입력:

- `--input-raw-ingredients`
- `--dictionary-path`
- `--output-dir`

출력:

- `product_ingredients_normalized`
- `ingredient_alias_map`
- 미매핑 성분 목록

주요 로직:

- 문자열 정제
- 구분자 통일
- 토큰 분리
- alias -> canonical 매핑
- 위험 / 기능 / 선호 태그 부여

### 3.5 `scripts/build_product_scores.R`

역할:

- 사용자 조건에 따라 제품 적합도 점수와 비교 요약을 생성한다.

입력:

- `--product-table`
- `--ingredient-table`
- `--profile-path`

출력:

- `analysis_results`
- 비교 요약 테이블

주요 로직:

- 선호 성분 가산점
- 비선호 성분 감점
- 민감 성분 탐지
- 설명 가능한 summary 생성

## 4. Planned Shiny Modules

### 4.1 `R/mod_search_products.R`

역할:

- 브랜드, 카테고리, 키워드, 성분 필터 기반 상품 검색 UI와 서버 로직을 제공한다.

주요 기능:

- 다중 필터 검색
- 결과 테이블 정렬
- 상세 분석 페이지 이동

### 4.2 `R/mod_product_profile.R`

역할:

- 단일 제품의 전성분 구조와 요약 분석을 보여준다.

주요 기능:

- 원문 전성분 표시
- 정규화 성분 목록 표시
- 위험 / 기능 태그 배지
- 사용자 적합도 요약

### 4.3 `R/mod_compare_products.R`

역할:

- 여러 제품의 성분 공통점/차이점과 적합도 점수를 비교한다.

주요 기능:

- 제품 간 성분 overlap matrix
- 제외 성분 포함 여부 강조
- 비교 요약 표와 다운로드

### 4.4 `R/mod_user_profile.R`

역할:

- 사용자 선호 성분, 비선호 성분, 피부 특성을 입력받아 분석 엔진에 전달한다.

주요 기능:

- 관심 성분 선택
- 피해야 할 성분 선택
- 피부 타입 / 민감 조건 입력
- profile 저장 및 재사용

## 5. Data Artifacts

### 5.1 Raw HTML

용도:

- 원본 보관
- 파서 디버깅
- 사이트 구조 변경 대응
- 상세공시 로딩 방식 검증

예시:

- `data/raw/oliveyoung/product_12345678.html`

### 5.2 Product Table

용도:

- 검색 UI 기본 데이터
- 가격 / 브랜드 / 카테고리 필터링

예시:

- `data/processed/products.parquet`

### 5.3 Ingredient Tables

용도:

- 성분 검색
- 제품 비교
- 사용자 맞춤 스코어링

예시:

- `data/processed/product_ingredients_normalized.parquet`
- `data/processed/ingredient_dictionary.parquet`

## 6. Recommended Future Modules

- `scripts/update_incremental_catalog.R`
- `scripts/extract_review_text.R`
- `scripts/tag_functional_ingredients.R`
- `scripts/export_comparison_report.R`
- `R/mod_dashboard_summary.R`
- `R/utils_scoring.R`
