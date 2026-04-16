# Olive Young Notice Prototype Plan

## 1. Goal

올리브영 상품 상세 페이지에서 `상품정보 제공고시`와 화장품 분석에 필요한 핵심 필드가 상품별로 안정적으로 수집 가능한지 검증한다.

## 2. Validation Questions

- `goodsNo`만으로 상세 페이지에 안정적으로 접근 가능한가
- 초기 HTML에 기본 상품 메타가 포함되는가
- `상품정보 제공고시` 본문이 초기 HTML에 포함되는가
- `전성분` 텍스트가 초기 HTML에 포함되는가
- 본문이 없다면 hydration 또는 별도 API 호출로 로드되는가
- 브라우저 자동화 없이 HTTP 수집만으로 배치 수집이 가능한가

## 3. Target Fields

- `goods_no`
- `goods_name`
- `brand_name`
- `category_name`
- `price_current`
- `volume_text`
- `ingredients_raw_text`
- `notice_title`
- `notice_body`
- `usage_period`
- `country_of_origin`
- `cautions`

## 4. Decision Criteria

### 4.1 Collectible By SSR

아래를 만족하면 SSR/HTTP 기반 우선 수집 대상으로 본다.

- 초기 HTML에 기본 메타데이터가 존재
- 공시 본문 또는 전성분 텍스트가 직접 포함
- 상품 간 마크업 변동이 크지 않음

### 4.2 Needs Browser

아래를 만족하면 브라우저 자동화 fallback이 필요하다.

- 공시 제목만 있고 본문이 초기 HTML에 없음
- 클릭 이후 DOM에서만 본문이 나타남
- hydration 후 렌더링 완료까지 대기 필요

### 4.3 Needs Network Trace

아래를 만족하면 내부 API 추적이 최우선이다.

- 클릭 시 XHR / fetch 응답으로 공시 본문이 로드
- JSON 응답에 구조화된 필드가 존재
- 동일 endpoint를 상품별로 재사용 가능

## 5. Prototype Workflow

1. `fetch_oliveyoung_goods_page.R`로 샘플 상품 HTML 저장
2. `extract_oliveyoung_goods_state.R`로 SSR 메타 추출
3. `probe_oliveyoung_notice_candidates.R`로 상세공시 존재 여부 판정
4. JS 번들 또는 브라우저 Network에서 상세공시 API endpoint 추적
5. `fetch_oliveyoung_article_info.R`로 상품정보 제공고시 API 직접 호출
6. 여러 샘플을 `inspect_oliveyoung_notice_strategy.R`로 비교
7. 결과에 따라 SSR 우선 / API 우선 / 브라우저 fallback 전략 결정

## 6. Sample Goods Strategy

- 스킨케어 3개
- 선케어 2개
- 메이크업 2개
- 바디/헤어 2개
- 비화장품 1개

이렇게 샘플링하면 카테고리별 상세공시 구조 차이를 빠르게 확인할 수 있다.

## 7. Output Artifacts

- 샘플 HTML 원문
- 상품 메타 추출 결과 CSV
- 공시 탐지 리포트 CSV
- 전략 판정 요약표
- 실패 케이스 로그

## 8. Exit Condition

아래 중 하나가 만족되면 프로토타입 단계를 종료한다.

- 10개 샘플 중 8개 이상에서 공시 본문 수집 경로가 재현 가능
- 내부 API endpoint가 식별되어 `goodsNo` 기반 호출 규칙이 확인됨
- 브라우저 자동화만으로도 공시 본문 추출이 안정적임이 확인됨
