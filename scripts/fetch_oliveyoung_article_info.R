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
    standard_code = NULL,
    option_name = " ",
    liquor_flag = "false",
    output_dir = "data/raw/oliveyoung/article",
    user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36"
  )

  i <- 1
  while (i <= length(args)) {
    key <- args[[i]]
    value <- if (i + 1 <= length(args)) args[[i + 1]] else NULL

    if (identical(key, "--goods-no")) out$goods_no <- value
    if (identical(key, "--standard-code")) out$standard_code <- value
    if (identical(key, "--option-name")) out$option_name <- value
    if (identical(key, "--liquor-flag")) out$liquor_flag <- value
    if (identical(key, "--output-dir")) out$output_dir <- value
    if (identical(key, "--user-agent")) out$user_agent <- value

    i <- i + 2
  }

  if (is.null(out$goods_no) || !nzchar(out$goods_no)) {
    stop("`--goods-no` is required.", call. = FALSE)
  }

  if (is.null(out$standard_code) || !nzchar(out$standard_code)) {
    stop("`--standard-code` is required.", call. = FALSE)
  }

  out$liquor_flag <- tolower(out$liquor_flag) %in% c("true", "1", "y", "yes")
  out
}

main <- function() {
  args <- parse_args(commandArgs(trailingOnly = TRUE))
  dir.create(args$output_dir, recursive = TRUE, showWarnings = FALSE)

  payload <- list(
    goodsNumber = args$goods_no,
    liquorFlag = args$liquor_flag,
    goodsOptionInfoList = list(
      list(
        standardCode = args$standard_code,
        optionName = args$option_name
      )
    )
  )

  response <- httr2::request("https://www.oliveyoung.co.kr/goods/api/v1/article") |>
    httr2::req_user_agent(args$user_agent) |>
    httr2::req_headers(
      Accept = "application/json, text/plain, */*",
      "Accept-Language" = "ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7",
      "Content-Type" = "application/json"
    ) |>
    httr2::req_body_json(payload, auto_unbox = TRUE) |>
    httr2::req_perform()

  json_text <- httr2::resp_body_string(response)
  output_path <- file.path(args$output_dir, paste0(args$goods_no, ".json"))
  writeLines(json_text, output_path, useBytes = TRUE)

  parsed <- jsonlite::fromJSON(json_text, simplifyVector = FALSE)
  article_count <- length(parsed$data$articleInfoList %||% list())

  message("Saved article response: ", output_path)
  message("Article row count: ", article_count)
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

main()
