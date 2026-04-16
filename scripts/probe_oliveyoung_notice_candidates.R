#!/usr/bin/env Rscript

parse_args <- function(args) {
  out <- list(
    input_html = NULL,
    output_file = NULL
  )

  i <- 1
  while (i <= length(args)) {
    key <- args[[i]]
    value <- if (i + 1 <= length(args)) args[[i + 1]] else NULL

    if (identical(key, "--input-html")) out$input_html <- value
    if (identical(key, "--output-file")) out$output_file <- value

    i <- i + 2
  }

  if (is.null(out$input_html) || !nzchar(out$input_html)) {
    stop("`--input-html` is required.", call. = FALSE)
  }

  out
}

contains_pattern <- function(text, pattern) {
  grepl(pattern, text, perl = TRUE, ignore.case = FALSE)
}

main <- function() {
  args <- parse_args(commandArgs(trailingOnly = TRUE))
  html_text <- paste(readLines(args$input_html, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

  goods_no <- sub("\\.html$", "", basename(args$input_html))
  report <- data.frame(
    goods_no = goods_no,
    has_notice_title = contains_pattern(html_text, "상품정보 제공고시"),
    has_ingredient_text = contains_pattern(html_text, "전성분"),
    has_usage_period = contains_pattern(html_text, "사용기한"),
    has_volume_text = contains_pattern(html_text, "용량"),
    has_country_of_origin = contains_pattern(html_text, "제조국"),
    has_cautions = contains_pattern(html_text, "주의사항"),
    has_notice_value_hint = contains_pattern(
      html_text,
      "상품정보 제공고시.{0,500}(사용기한|용량|제조국|주의사항)"
    ),
    stringsAsFactors = FALSE
  )

  report$strategy_hint <- ifelse(
    report$has_notice_title & report$has_notice_value_hint,
    "ssr_candidate",
    ifelse(report$has_notice_title, "needs_browser_or_api_trace", "missing_notice_block")
  )

  if (!is.null(args$output_file) && nzchar(args$output_file)) {
    dir.create(dirname(args$output_file), recursive = TRUE, showWarnings = FALSE)
    utils::write.csv(report, args$output_file, row.names = FALSE)
    message("Saved probe report: ", args$output_file)
  } else {
    print(report)
  }
}

main()
