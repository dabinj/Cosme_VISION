#!/usr/bin/env Rscript

parse_args <- function(args) {
  out <- list(
    goods_no_file = NULL,
    html_dir = "data/raw/oliveyoung/html",
    output_file = "data/processed/oliveyoung_notice_strategy.csv"
  )

  i <- 1
  while (i <= length(args)) {
    key <- args[[i]]
    value <- if (i + 1 <= length(args)) args[[i + 1]] else NULL

    if (identical(key, "--goods-no-file")) out$goods_no_file <- value
    if (identical(key, "--html-dir")) out$html_dir <- value
    if (identical(key, "--output-file")) out$output_file <- value

    i <- i + 2
  }

  if (is.null(out$goods_no_file) || !nzchar(out$goods_no_file)) {
    stop("`--goods-no-file` is required.", call. = FALSE)
  }

  out
}

contains_pattern <- function(text, pattern) {
  grepl(pattern, text, perl = TRUE, ignore.case = FALSE)
}

probe_one <- function(goods_no, html_dir) {
  html_path <- file.path(html_dir, paste0(goods_no, ".html"))
  if (!file.exists(html_path)) {
    return(data.frame(
      goods_no = goods_no,
      html_exists = FALSE,
      has_notice_title = FALSE,
      has_notice_value_hint = FALSE,
      strategy_hint = "html_missing",
      stringsAsFactors = FALSE
    ))
  }

  html_text <- paste(readLines(html_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  has_notice_title <- contains_pattern(html_text, "상품정보 제공고시")
  has_notice_value_hint <- contains_pattern(
    html_text,
    "상품정보 제공고시.{0,500}(사용기한|용량|제조국|주의사항)"
  )

  strategy_hint <- if (has_notice_title && has_notice_value_hint) {
    "ssr_candidate"
  } else if (has_notice_title) {
    "needs_browser_or_api_trace"
  } else {
    "missing_notice_block"
  }

  data.frame(
    goods_no = goods_no,
    html_exists = TRUE,
    has_notice_title = has_notice_title,
    has_notice_value_hint = has_notice_value_hint,
    strategy_hint = strategy_hint,
    stringsAsFactors = FALSE
  )
}

main <- function() {
  args <- parse_args(commandArgs(trailingOnly = TRUE))
  goods_nos <- readLines(args$goods_no_file, warn = FALSE, encoding = "UTF-8")
  goods_nos <- trimws(goods_nos)
  goods_nos <- goods_nos[nzchar(goods_nos)]

  reports <- lapply(goods_nos, probe_one, html_dir = args$html_dir)
  result <- do.call(rbind, reports)

  dir.create(dirname(args$output_file), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(result, args$output_file, row.names = FALSE)
  message("Saved strategy summary: ", args$output_file)
}

main()
