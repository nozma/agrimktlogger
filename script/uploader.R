# 市況情報を取得してspreadsheetにアップロードする
library(agrimktlogger)
library(googlesheets)
library(dplyr)

d <- get_shikyo_all()

gs_auth()

gs_read(
  gs_key(Sys.getenv("GSHEET_ID"))
) %>%
  tail(1) %>%
  pull(updated_at) -> last_updated

update_time <- as.character(d$updated_at)[1]

if(update_time != last_updated){
  gs_add_row(
    gs_key(Sys.getenv("GSHEET_ID")),
    input = d
  )
  cat("update success!\n")
} else {
  cat("update skip!\n")
}
