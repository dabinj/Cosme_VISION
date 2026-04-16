# Cosme_VISION Analysis Log

## 2026-04-16 Summary

아래 내용은 `Cosme_VISION` 프로젝트 착수 시점에 확정한 요구사항과 초기 기술 판단을 기록한 것이다.

## 1. Product Goal

확인 사항:

- 사용자는 화장품 판매 사이트에서 상품 정보를 수집해 전성분 분석을 수행하려고 한다.
- 핵심 사용 시나리오는 "원하는 성분이 포함된 제품 찾기"와 "맞지 않는 성분이 들어간 제품 제외하기"이다.
- 결과는 Shiny 기반 웹 플랫폼에서 탐색형으로 제공한다.

결론:

- 단순 크롤러 프로젝트가 아니라 데이터 수집, 성분 표준화, 비교 분석, 리포팅까지 포함하는 분석 플랫폼으로 정의한다.

## 2. Data Collection Strategy

초기 판단:

- 특정 판매 사이트에 공개 API가 없거나 안정적이지 않을 가능성을 전제로 설계한다.
- 따라서 1차 수집 방식은 HTML 기반 크롤링 / 파싱 구조를 우선 고려한다.
- 수집 레이어는 사이트별 adapter 구조로 분리하는 것이 안전하다.

실무 결론:

- `source adapter -> raw html -> parsed product table -> normalized ingredient table` 순서의 다단계 파이프라인으로 간다.

## 2.1 Olive Young Detail Page Probe

검증 대상 URL:

- `https://www.oliveyoung.co.kr/store/goods/getGoodsDetail.do?goodsNo=A000000232212`

2026-04-16 확인 사항:

- 상품 상세 페이지는 Next.js 기반 SSR + hydration 구조로 보인다.
- 초기 HTML 안에서 `goodsNumber`, `goodsName`, 브랜드, 카테고리, 가격 등 기본 메타데이터는 확인 가능했다.
- 화면 레벨에서는 `상품정보 제공고시` 아코디언 제목이 존재했다.
- 그러나 초기 응답에서 `상품정보 제공고시` 본문과 `전성분` 텍스트는 직접 확인되지 않았다.

현재 해석:

- 기본 상품 메타는 SSR state에서 수집 가능하다.
- 상세공시 본문은 접힘 상태의 클라이언트 렌더링이거나 추가 API 호출로 내려올 가능성이 높다.
- 따라서 정적 HTML 파싱만으로 전 상품 상세공시를 안정적으로 확보할 수 있다고 단정하면 안 된다.

다음 검증 순서:

- 단일 상품 HTML 저장
- SSR state 필드 추출
- 공시/전성분 키워드 존재 여부 탐지
- 브라우저 개발자도구 기준 네트워크 호출 추적
- 필요 시 Playwright 기반 fallback 설계

## 2.2 Olive Young Notice API Finding

2026-04-16 추가 확인 사항:

- `상품정보 제공고시` 아코디언은 초기 HTML 본문이 아니라 클릭 시 별도 API 데이터를 사용한다.
- JS 번들 기준 상품정보 제공고시 로딩 query는 `ARTICLE` 키를 사용한다.
- 실제 호출 endpoint는 `goods/api/v1/article` 이다.
- 요청 payload는 최소 아래 필드를 포함한다.
  - `goodsNumber`
  - `liquorFlag`
  - `goodsOptionInfoList[].standardCode`
  - `goodsOptionInfoList[].optionName`

샘플 호출 결과:

- 상품 `A000000232212` 기준 `goods/api/v1/article` 응답에서 아래 항목을 확인했다.
  - `내용물의 용량 또는 중량`
  - `제품 주요 사양`
  - `사용기한(또는 개봉 후 사용기간)`
  - `제조국`
  - `화장품법에 따라 기재해야 하는 모든 성분`
  - `사용할 때의 주의사항`
  - `품질보증기준`
  - `소비자상담 전화번호`

결론:

- 올리브영 화장품의 상세공시는 브라우저 DOM 파싱보다 API 직접 수집이 더 안정적이다.
- 화장품 성분 분석에 필요한 핵심 필드는 `goods/api/v1/article`에서 직접 확보 가능하다.

## 2.3 Olive Young Preferred Collection Order

2026-04-16 기준 수집 우선순위:

- `goodsNo`
- `goods/api/v1/detail`
- `goods/api/v1/article`
- `goods/api/v1/description`

세부 판단:

- `detail`은 상품명, 브랜드, 카테고리, 가격, `thumbnailImage[]`, `options[].standardCode`를 제공한다.
- `article`은 상세공시와 전성분 텍스트를 구조화된 `title/content` 쌍으로 제공한다.
- `description`은 마케팅용 상세 HTML과 이미지 URL을 제공하지만, 성분 분석 핵심 데이터는 아니다.

실무 결론:

- 카탈로그 기본키는 `goodsNo`
- 공시 조회는 `goodsNo + standardCode`
- 이미지 수집은 `detail`의 썸네일과 `description`의 상세 이미지 URL만 보조적으로 적재

샘플 검증 결과:

- 상품 `A000000232212`
  - `detail`: 썸네일 3건 확인
  - `article`: 공시 항목 11건 확인
  - `description`: 상세 이미지 URL 53건 확인

## 3. Core Entities

우선 정의한 엔터티:

- `products`
- `product_prices`
- `product_ingredients_raw`
- `ingredient_dictionary`
- `ingredient_alias_map`
- `user_profiles`
- `analysis_results`

결론:

- 상품 메타데이터와 성분 사전을 분리해야 재분석 비용을 줄일 수 있다.

## 4. Ingredient Interpretation

확인 사항:

- 전성분은 하나의 긴 문자열로 제공될 가능성이 높다.
- 쉼표, 중점, 괄호, 별표, 함량 표시 등 표기 흔들림이 존재할 수 있다.
- 국문명과 영문 INCI명을 함께 관리해야 검색과 비교가 쉬워진다.

필요 처리:

- 원문 보존
- 문자열 정제
- 토큰화
- canonical ingredient로 매핑
- 기능 태깅과 위험 태깅

결론:

- 성분 분석 정확도는 크롤링보다 정규화 사전 품질에 더 크게 좌우된다.

## 5. Comparison Logic

핵심 비교 축:

- 포함 여부: 원하는 성분 포함
- 제외 여부: 비선호 성분 포함
- 민감 신호: 향료, 에센셜오일, 보존제, 산류 등
- 제품 유사도: 두 제품 간 성분 겹침 / 차이
- 사용자 맞춤 점수: 선호/비선호 가중치 기반 score

초기 결론:

- 첫 버전은 ML보다 rule-based scoring이 적합하다.
- score와 함께 "왜 이런 점수가 나왔는지"를 설명문으로 제공해야 한다.

## 6. Shiny UX Direction

우선 구성할 화면:

- 상품 검색 / 필터 화면
- 단일 제품 성분 분석 화면
- 2개 이상 제품 비교 화면
- 사용자 프로필 기반 추천 / 제외 화면

실무 결론:

- 분석 엔진과 UI 모듈을 분리해두면 나중에 API 서버 또는 배치 분석으로 확장하기 쉽다.

## 7. Open Issues

- 대상 사이트의 상세공시 본문 로딩 방식 미확정
- 전성분 노출 위치가 SSR인지 추가 데이터 호출인지 미확정
- 수집 주기와 증분 업데이트 정책 미정
- 성분 위험도 rule source 미정
- 리뷰 텍스트 분석 포함 여부 미정
- 이미지 OCR이 필요한 케이스 존재 여부 미정
