#!/usr/bin/env Rscript

required_packages <- c("httr2", "jsonlite")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop(
    "Missing packages: ",
    paste(missing_packages, collapse = ", "),
    ". Install them before running this script.",
    call. = FALSE
  )
}

parse_args <- function(args) {
  out <- list(
    goods_no = NULL,
    output_dir = "data/raw/oliveyoung/html",
    user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36"
  )

  i <- 1
  while (i <= length(args)) {
    key <- args[[i]]
    value <- if (i + 1 <= length(args)) args[[i + 1]] else NULL

    if (identical(key, "--goods-no")) out$goods_no <- value
    if (identical(key, "--output-dir")) out$output_dir <- value
    if (identical(key, "--user-agent")) out$user_agent <- value

    i <- i + 2
  }

  if (is.null(out$goods_no) || !nzchar(out$goods_no)) {
    stop("`--goods-no` is required.", call. = FALSE)
  }

  out
}

build_goods_url <- function(goods_no) {
  paste0(
    "https://www.oliveyoung.co.kr/store/goods/getGoodsDetail.do?goodsNo=",
    utils::URLencode(goods_no, reserved = TRUE)
  )
}

main <- function() {
  args <- parse_args(commandArgs(trailingOnly = TRUE))
  dir.create(args$output_dir, recursive = TRUE, showWarnings = FALSE)

  url <- build_goods_url(args$goods_no)
  response <- httr2::request(url) |>
    httr2::req_user_agent(args$user_agent) |>
    httr2::req_headers(
      Accept = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "Accept-Language" = "ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7"
    ) |>
    httr2::req_perform()

  html_text <- httr2::resp_body_string(response)
  html_path <- file.path(args$output_dir, paste0(args$goods_no, ".html"))
  meta_path <- file.path(args$output_dir, paste0(args$goods_no, ".meta.json"))

  writeLines(html_text, html_path, useBytes = TRUE)

  meta <- list(
    goods_no = args$goods_no,
    source_url = url,
    fetched_at = format(Sys.time(), tz = "Asia/Seoul", usetz = TRUE),
    status_code = httr2::resp_status(response),
    html_path = html_path
  )

  writeLines(
    jsonlite::toJSON(meta, auto_unbox = TRUE, pretty = TRUE),
    meta_path,
    useBytes = TRUE
  )

  message("Saved HTML: ", html_path)
  message("Saved meta: ", meta_path)
}

main()
