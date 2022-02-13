# 市況情報を取得してBigQueryにアップロードする
library(agrimktlogger)
library(dplyr)
library(dbplyr)
library(lubridate)
library(bigrquery)

# データ取得
d <- get_shikyo_all() %>%
  mutate(updated_at = force_tz(updated_at, "Etc/UTC"))


# データ書き込み
bq_auth(path = Sys.getenv("CREDENTIALS_PATH")) # サービスアカウントのクレデンシャル

ag_table <- bq_table(
    project = Sys.getenv("BQ_HOME_PROJECT_ID"),
    dataset = Sys.getenv("BQ_HOME_DATASET_ID"),
    table = Sys.getenv("BQ_AGM_TABLE")
)

bq_table_upload(
    ag_table, d,
    create_disposition = "CREATE_IF_NEEDED",
    write_disposition = "WRITE_APPEND"
)