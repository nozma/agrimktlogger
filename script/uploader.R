# 市況情報を取得してspreadsheetにアップロードする
library(agrimktlogger)
library(googlesheets4)
library(dplyr)
library(lubridate)

d <- get_shikyo_all() %>%
  mutate(updated_at = force_tz(updated_at, "Etc/UTC"))

gs4_auth(path = "/home/pi/agrimktlogger/script/credentials.json")

read_sheet(
  Sys.getenv("GSHEET_ID"),
  sheet = "最終更新日",
  col_names = FALSE,
  col_types = "c"
) %>%
  pull() ->
  last_updated

if(last_updated != as.character(d$updated_at[1])){
  sheet_append(
    Sys.getenv("GSHEET_ID"),
    data = d,
    sheet = "data"
  )
  cat("update success!\n")
} else {
  cat("update skip!\n")
}

