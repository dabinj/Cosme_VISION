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

extract_first <- function(text, patterns) {
  for (pattern in patterns) {
    match <- regexec(pattern, text, perl = TRUE)
    captured <- regmatches(text, match)[[1]]

    if (length(captured) < 2) {
      next
    }

    return(captured[[2]])
  }

  NA_character_
}

extract_state <- function(html_text) {
  list(
    goods_no = extract_first(html_text, c('"goodsNumber":"([^"]+)"', '\\\\"goodsNumber\\\\":\\\\"([^\\\\"]+)\\\\"')),
    goods_name = extract_first(html_text, c('"goodsName":"([^"]+)"', '\\\\"goodsName\\\\":\\\\"([^\\\\"]+)\\\\"')),
    brand_name = extract_first(html_text, c('"onlineBrandName":"([^"]+)"', '\\\\"onlineBrandName\\\\":\\\\"([^\\\\"]+)\\\\"')),
    category_name = extract_first(html_text, c('"lowerCategoryName":"([^"]+)"', '\\\\"lowerCategoryName\\\\":\\\\"([^\\\\"]+)\\\\"')),
    supplier_name = extract_first(html_text, c('"supplierName":"([^"]+)"', '\\\\"supplierName\\\\":\\\\"([^\\\\"]+)\\\\"')),
    sale_price = extract_first(html_text, c('"salePrice":([0-9]+)', '\\\\"salePrice\\\\":([0-9]+)')),
    final_price = extract_first(html_text, c('"finalPrice":([0-9]+)', '\\\\"finalPrice\\\\":([0-9]+)'))
  )
}

main <- function() {
  args <- parse_args(commandArgs(trailingOnly = TRUE))
  html_text <- paste(readLines(args$input_html, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  extracted <- extract_state(html_text)
  output <- as.data.frame(extracted, stringsAsFactors = FALSE)

  if (!is.null(args$output_file) && nzchar(args$output_file)) {
    dir.create(dirname(args$output_file), recursive = TRUE, showWarnings = FALSE)
    utils::write.csv(output, args$output_file, row.names = FALSE, na = "")
    message("Saved parsed state: ", args$output_file)
  } else {
    print(output)
  }
}

main()
