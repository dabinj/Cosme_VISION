#!/usr/bin/env Rscript

required_packages <- c("jsonlite")
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
    detail_json = NULL,
    description_json = NULL,
    output_file = NULL
  )

  i <- 1
  while (i <= length(args)) {
    key <- args[[i]]
    value <- if (i + 1 <= length(args)) args[[i + 1]] else NULL

    if (identical(key, "--goods-no")) out$goods_no <- value
    if (identical(key, "--detail-json")) out$detail_json <- value
    if (identical(key, "--description-json")) out$description_json <- value
    if (identical(key, "--output-file")) out$output_file <- value

    i <- i + 2
  }

  if (is.null(out$goods_no) || !nzchar(out$goods_no)) {
    stop("`--goods-no` is required.", call. = FALSE)
  }

  if (is.null(out$detail_json) || !nzchar(out$detail_json)) {
    stop("`--detail-json` is required.", call. = FALSE)
  }

  if (is.null(out$description_json) || !nzchar(out$description_json)) {
    stop("`--description-json` is required.", call. = FALSE)
  }

  if (is.null(out$output_file) || !nzchar(out$output_file)) {
    stop("`--output-file` is required.", call. = FALSE)
  }

  out
}

extract_image_urls <- function(html_text) {
  patterns <- c(
    'data-src="([^"]+)"',
    'src="([^"]+)"'
  )

  urls <- character()
  for (pattern in patterns) {
    match <- gregexec(pattern, html_text, perl = TRUE)
    captured <- regmatches(html_text, match)[[1]]
    if (length(captured) == 0) {
      next
    }

    for (entry in captured) {
      value <- sub(pattern, "\\1", entry, perl = TRUE)
      urls <- c(urls, value)
    }
  }

  urls <- unique(urls[nzchar(urls)])
  urls[grepl("^https?://", urls, perl = TRUE)]
}

build_thumbnail_rows <- function(goods_no, detail_obj) {
  thumbs <- detail_obj$data$thumbnailImage
  if (is.null(thumbs) || length(thumbs) == 0) {
    return(data.frame())
  }

  rows <- lapply(seq_along(thumbs), function(idx) {
    item <- thumbs[[idx]]
    data.frame(
      goods_no = goods_no,
      image_type = "thumbnail",
      image_seq = idx,
      image_url = paste0(item$url, "/", item$path),
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, rows)
}

build_detail_rows <- function(goods_no, description_obj) {
  html_text <- description_obj$data$descriptionContents %||% ""
  urls <- extract_image_urls(html_text)
  if (length(urls) == 0) {
    return(data.frame())
  }

  data.frame(
    goods_no = goods_no,
    image_type = "detail",
    image_seq = seq_along(urls),
    image_url = urls,
    stringsAsFactors = FALSE
  )
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

main <- function() {
  args <- parse_args(commandArgs(trailingOnly = TRUE))
  detail_obj <- jsonlite::fromJSON(args$detail_json, simplifyVector = FALSE)
  description_obj <- jsonlite::fromJSON(args$description_json, simplifyVector = FALSE)

  thumb_rows <- build_thumbnail_rows(args$goods_no, detail_obj)
  detail_rows <- build_detail_rows(args$goods_no, description_obj)
  row_list <- Filter(function(x) is.data.frame(x) && nrow(x) > 0, list(thumb_rows, detail_rows))
  if (length(row_list) == 0) {
    combined <- data.frame(
      goods_no = character(),
      image_type = character(),
      image_seq = integer(),
      image_url = character(),
      stringsAsFactors = FALSE
    )
  } else {
    combined <- do.call(rbind, row_list)
  }

  if (nrow(combined) > 0) {
    combined <- combined[!duplicated(combined[c("image_type", "image_url")]), , drop = FALSE]
    combined$image_seq <- ave(combined$image_type, combined$image_type, FUN = seq_along)
  }

  dir.create(dirname(args$output_file), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(combined, args$output_file, row.names = FALSE)

  message("Saved image URL index: ", args$output_file)
  message("Image row count: ", nrow(combined))
}

main()
