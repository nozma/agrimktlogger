#' 平均価格html取得
#'
#' @param formdata 取得したいテーブルに対応した文字列を指定。
#'     - "VEGI": 野菜
#'     - "FRUIT": 果実
#'     - "FLOWER": 花き
#' @export
shikyo_html <- function(formdata) {
  if(!(formdata %in% c("VEGI", "FRUIT", "FLOWER"))){
    stop('許容されるformdataは"VEGI", "FRUIT", "FLOWER"のみです。\n')
  }
  httr::POST(
    url = "https://www.agrishikyo.jp/TOP2012/AJAX/TOP2012.SIDETABLE.AJAX",
    encode = "form",
    body = list(SIDETAB = formdata)
    ) %>%
    xml2::read_html()
}

#' 時刻抽出
#'
#' テーブルから更新時刻を取得。野菜または果実のhtmlを使うこと。
#'
#' @export
extract_updated_at <- function(form_html) {
  tryCatch(
    {
      form_html %>%
        rvest::html_nodes(css = "p") %>%
        rvest::html_text() %>%
        substring(., regexpr(as.character(lubridate::year(Sys.time())), .)) %>%
        lubridate::ymd_hm(tz = "Asia/Tokyo")
    },
    warning = function(e) stop("野菜または果実のform htmlを指定してください")
  )
}

#' 市況情報抽出
#'
#' @param formdata 取得したいテーブルに対応した文字列を指定。
#'     - "VEGI": 野菜
#'     - "FRUIT": 果実
#'     - "FLOWER": 花き
#' @export
get_shikyo <- function(formdata) {
  shikyo_html(formdata) %>%
    rvest::html_table() %>%
    magrittr::extract2(1) %>%
    magrittr::extract(, 1:2) %>%
    magrittr::set_names(c("item", "price")) %>%
    dplyr::mutate_if(is.character, stringi::stri_trans_nfkc) %>%
    arrange_shikyo_df()
}

#' 〃の処理
#'
#' @param df 市況情報データフレーム
arrange_shikyo_df <- function(df){
  for(i in seq_along(df$item)){
    m <- regexpr(".*(?=\\()", df$item[i], perl=TRUE)
    if(m != -1){
      txt_a <- substring(df$item[i], m, m+attr(m, "match.length") - 1) # ()の前を取得
      if(txt_a == "〃"){ # "〃"が()の前なら確保した文字列に置換
        df$item[i] <- sub("〃", txt_b, df$item[i])
      } else { # ()の前が〃でなければ文字列を確保
        txt_b <- txt_a
      }
    }
  }
  df %>%
    dplyr::mutate(
      item = stringi::stri_replace_all(item, "", regex = "※")
    )
}

#' 平均単価取得
#'
#' 野菜・果実の平均単価を取得
#'
#' @export
get_average_price <- function(){
  xml2::read_html("https://www.agrishikyo.jp/NICHINO2012/AJAX/NICHINO.TOP.AJAX") %>%
    rvest::html_table() %>%
    magrittr::extract2(1) %>%
    magrittr::extract(1:2, 2, drop = FALSE) %>%
    dplyr::rename(price = 1) %>%
    dplyr::mutate(item = c("野菜平均", "果実平均")) ->
    vegi_fru

  httr::POST(
    "https://www.agrishikyo.jp/NICHINO_FLOWER2012/AJAX/NICHINO_FLOWER.DAY.TOP.AJAX",
    encode = "form",
    body = list(cache = NA)
    ) %>%
    xml2::read_html() %>%
    rvest::html_table() %>%
    magrittr::extract2(1) %>%
    magrittr::extract(1, 2, drop = FALSE) %>%
    dplyr::rename(price = 1) %>%
    dplyr::mutate(item = c("切り花平均")) ->
    flo

  dplyr::bind_rows(vegi_fru, flo) %>%
    dplyr::transmute(
      item,
      price = as.numeric(price)
    )
}

#' 全ての市況情報を取得
#'
#' @export
get_shikyo_all <- function() {
  get_shikyo("VEGI") %>%
    dplyr::bind_rows(get_shikyo("FRUIT")) %>%
    dplyr::bind_rows(get_shikyo("FLOWER")) %>%
    dplyr::bind_rows(get_average_price()) %>%
    dplyr::transmute(
      updated_at = extract_updated_at(shikyo_html("VEGI")),
      item,
      price
    )
}
