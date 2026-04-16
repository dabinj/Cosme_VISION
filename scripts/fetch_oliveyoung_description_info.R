#!/usr/bin/env Rscript

required_packages <- c("httr2")
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
    output_dir = "data/raw/oliveyoung/description",
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

main <- function() {
  args <- parse_args(commandArgs(trailingOnly = TRUE))
  dir.create(args$output_dir, recursive = TRUE, showWarnings = FALSE)

  response <- httr2::request("https://www.oliveyoung.co.kr/goods/api/v1/description") |>
    httr2::req_user_agent(args$user_agent) |>
    httr2::req_headers(
      Accept = "application/json, text/plain, */*",
      "Accept-Language" = "ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7"
    ) |>
    httr2::req_url_query(goodsNumber = args$goods_no) |>
    httr2::req_perform()

  output_path <- file.path(args$output_dir, paste0(args$goods_no, ".json"))
  writeLines(httr2::resp_body_string(response), output_path, useBytes = TRUE)

  message("Saved description response: ", output_path)
}

main()
