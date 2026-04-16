# Scripts Overview

현재 `scripts/`는 올리브영 상세공시 수집 가능 여부를 검증하기 위한 프로토타입 골격을 포함한다.

## 1. Validation Flow

1. `fetch_oliveyoung_detail_info.R`
2. `fetch_oliveyoung_article_info.R`
3. `fetch_oliveyoung_description_info.R`
4. `extract_oliveyoung_image_urls.R`
5. `fetch_oliveyoung_goods_page.R`
6. `extract_oliveyoung_goods_state.R`
7. `probe_oliveyoung_notice_candidates.R`
8. `inspect_oliveyoung_notice_strategy.R`

## 2. Example Commands

```bash
Rscript scripts/fetch_oliveyoung_detail_info.R \
  --goods-no A000000232212 \
  --output-dir data/raw/oliveyoung/detail
```

```bash
Rscript scripts/fetch_oliveyoung_goods_page.R \
  --goods-no A000000232212 \
  --output-dir data/raw/oliveyoung/html
```

```bash
Rscript scripts/fetch_oliveyoung_article_info.R \
  --goods-no A000000232212 \
  --standard-code 8803463015824 \
  --option-name ' ' \
  --output-dir data/raw/oliveyoung/article
```

```bash
Rscript scripts/fetch_oliveyoung_description_info.R \
  --goods-no A000000232212 \
  --output-dir data/raw/oliveyoung/description
```

```bash
Rscript scripts/extract_oliveyoung_image_urls.R \
  --goods-no A000000232212 \
  --detail-json data/raw/oliveyoung/detail/A000000232212.json \
  --description-json data/raw/oliveyoung/description/A000000232212.json \
  --output-file data/processed/A000000232212_image_urls.csv
```

```bash
Rscript scripts/extract_oliveyoung_goods_state.R \
  --input-html data/raw/oliveyoung/html/A000000232212.html \
  --output-file data/processed/A000000232212_state.csv
```

```bash
Rscript scripts/probe_oliveyoung_notice_candidates.R \
  --input-html data/raw/oliveyoung/html/A000000232212.html \
  --output-file data/processed/A000000232212_notice_probe.csv
```

```bash
Rscript scripts/inspect_oliveyoung_notice_strategy.R \
  --goods-no-file config/sample_goods_nos.txt \
  --html-dir data/raw/oliveyoung/html \
  --output-file data/processed/oliveyoung_notice_strategy.csv
```

## 3. Required Packages

- `httr2`
- `jsonlite`

파싱 스크립트는 현재 base R 중심으로 작성했다. 이후 HTML DOM 파싱이 필요해지면 `xml2`, `rvest`, `stringr`를 추가하는 것이 자연스럽다.
