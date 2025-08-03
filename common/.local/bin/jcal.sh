#!/bin/sh
#
# NAME
#   jcal.sh - 日本のカレンダーを1月分表示する
#
# SYNOPSIS
#   jcal.sh [OPTIONS] [YYYY MM]
#
# DESCRIPTION
#   日本のカレンダーを1月分表示します。
#   基本的に日曜日は赤で、土曜日は青で表示します。
#   コマンドライン引数で年(YYYY)と月(MM)を指定した場合、
#   その1か月分のカレンダーを表示します。
#   年月を省略した場合は今月のカレンダーを表示します。
#   年だけ、あるいは月だけの指定はできません。
#   日本でグレゴリオ暦が適用された 1873 年以降が対象です。
#
#   祝日情報CSVファイルがあれば祝日も赤表示します。
#   祝日情報CSVファイルがない場合、あるいはあっても指定した年の情報がない場合には
#   ワーニングを表示します。
#
# OPTIONS
#   -u, --update
#     祝日情報を更新します。
#     必要な場合、環境変数 `https_proxy` を指定してください。
#
# FILES
#   ~/.local/share/jcal/syukujitsu.csv
#     祝日情報CSVファイル
#     内閣府が提供する祝日情報のCSVファイルをダウンロードして保存します。
#     エンコードはシフトJISのまま保存されます。
#
#   /tmp/syukujitu_XXX.csv
#     祝日情報CSVファイルをダウンロードする場合の一時ファイル。
#     `XXX` 部分は一意なIDに置き換えられます。
#
# SEE ALSO
#   cal(1), date(1)
#
# COPYRIGHT
#   (C) 2025 SATO Yoshiyuki. MIT Licensed.

set -eu
prog="$0"
esc="" # escape
eval "$(printf 'IFS=" \t\n" esc="\033"')"
red="${esc}[31m" # 前景色赤
blue="${esc}[34m" # 前景色青
clr="${esc}[m" # color reset

# 内閣府が提供する祝日情報のCSVファイル
# ref. <https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html>
# ref. <https://data.e-gov.go.jp/data/dataset/cao_20190522_0002/resource/d9ad35a5-6c9c-4127-bdbe-aa138fdffe42>
# ※フォーマットやファイル名が変更されることがあるので注意(2025年時点の仕様を想定)
url_holidays_csv='https://www8.cao.go.jp/chosei/shukujitsu/syukujitsu.csv'
# ホームディレクトリに保存する祝日情報のファイルパス
path_local_share=~/.local/share/jcal
path_holidays_csv="$path_local_share/syukujitsu.csv"

## 曜日を計算して変数に代入する
## ※グレゴリオ暦で計算します
## ※先発グレゴリオ暦の紀元前は正しく計算できないことがあります
## usage: calc_weekday VAR_NAME YEAR MONTH DAY
calc_weekday() {
  if [ "$3" -le 2 ]; then
    # 1月または2月の場合、前年の13月、14月として計算
    set -- "$1" $(( $2 - 1 )) $(( $3 + 12 )) "$4"
  fi
  # ツェラーの公式で計算（カッコ内はツェラーの公式(原書)での変数名）
  # $1=変数名, $2=年, $3=月(m), $4=日(q), $5=年の下2桁(K), $6=年の上2桁(J)
  set -- "$1" "$2" "$3" "$4" $(( $2 % 100 )) $(( $2 / 100 ))
  eval "$1=$(( ( $4 +(13*( $3 +1))/5+ $5 + $5 /4+ $6 /4+5* $6 +6)%7 ))"
}

## 指定年月の月末日を計算して変数に代入する
## ※不正な月のチェックはしません
## ※グレゴリオ暦で計算します
## ※先発グレゴリオ暦の紀元前は正しく計算できないことがあります
## usage: calc_lastday VAR_NAME YEAR MONTH
calc_lastday() {
  case "$3" in
    (4|6|9|11) set -- "$1" 30 ;; # 小の月
    (2)
      if [ $(( $2 % 4 )) -ne 0 ]; then
        set -- "$1" 28 # 平年
      elif [ $(( $2 % 100 )) -ne 0 ]; then
        set -- "$1" 29 # うるう年
      elif [ $(( $2 % 400 )) -ne 0 ]; then
        set -- "$1" 28 # 平年
      else
        set -- "$1" 29 # うるう年
      fi
      ;;
    (*) set -- "$1" 31 ;; # 大の月
  esac
  eval "$1=$2"
}

## 指定のURLからファイルをダウンロードして保存する
## usage: download_url URL OUTPUT_FILE
download_url() {
  if command -v curl >/dev/null 2>&1; then
    curl -LsS "$1" -o "$2"
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$1" -O "$2"
  elif command -v python3 >/dev/null 2>&1 && python3 --version >/dev/null 2>&1; then
    python3 -c "import sys, urllib.request; urllib.request.urlretrieve(sys.argv[1], sys.argv[2])" "$1" "$2"
  elif command -v busybox >/dev/null 2>&1 && busybox wget --help >/dev/null 2>&1; then
    busybox wget -q "$1" -O "$2"
  else
    echo "Error: No suitable download tool found." >&2
    exit 1
  fi
}

## 一時ファイルを作成する
## テンプレート中の `XXX` を一意情報に置き換える
## 生成した一時ファイル名は stdout に出力する
## ※コマンド置換（サブシェル）で呼び出されることを想定している
## usage: make_tempfile TEMPLATE
make_tempfile() {
  now=$(date +'%Y%m%d%H%M%S%z') || return $?
  uniq_id="${now}_$$"
  file="${TMPDIR:-/tmp}/${1%%XXX*}${uniq_id}${1#*XXX}"
  umask 077
  set -C
  echo "" > "$file" || return $?
  echo "$file"
}

## 指定年月の祝日情報を取得する
## 祝日情報は stdout に出力する
## 出力形式は `:1:15:21:` のように祝日の日付の前後にコロンがある
## ただし、指定の年の祝日がない場合には何も出力しない
## 指定の年の祝日はあるが指定の年月の祝日がない場合には `:` を出力する
## ※コマンド置換（サブシェル）で呼び出されることを想定している
## usage: get_holidays YEAR MONTH
get_holidays() {
  year="${1#0}"
  month="${2#0}"
  # 祝日情報CSVファイルはシフトJISで保存されているので
  # 念のためCロケールで読み込む
  export LANG=C
  holidays=""
  has_holidays=0

  ## 該当のデータをパースして、表示対象年月の場合祝日情報に追加する
  ## usage: append_holidays_if_needs CSV_ROW
  append_holidays_if_needs() {
    holiday="${1%%,*}" # 祝日の名前部分を削除
    # 2020年以降はスラッシュ区切りの前ゼロなしだが
    # 2017年3月頃はハイフン区切りの前ゼロありだったので念のため両対応
    # （2017年2月頃のデータはパースが困難なので対応しない）
    # ref. <https://okumuralab.org/~okumura/stat/holidays.html>
    IFS="/-" read -r holiday_year holiday_month holiday_day <<EOF
$holiday
EOF
    holiday_year="${holiday_year#0}"
    holiday_month="${holiday_month#0}"
    holiday_day="${holiday_day#0}"
    if [ "$year" -eq "$holiday_year" ]; then
      has_holidays=1
      if [ "$month" -eq "$holiday_month" ]; then
        holidays="$holidays:$holiday_day"
      fi
    fi
  }

  if [ -r "$path_holidays_csv" ]; then
    first_line=1
    while read -r holiday; do
      if [ "$first_line" -eq 1 ]; then
        first_line=0
        continue
      fi
      append_holidays_if_needs "$holiday"
    done < "$path_holidays_csv"
    if [ -n "$holiday" ]; then
      # 最終行に改行がないCSVだった場合の対応
      # ※2025年版には最終行の改行は存在するが念のため
      append_holidays_if_needs "$holiday"
    fi
    holidays="$holidays:" # すべての日付の前後に ":" がある状態にする
  fi
  if [ "$has_holidays" -eq 1 ]; then
    echo "$holidays"
  fi
}

if [ $# -ge 1 ]; then
  if [ "$1" = "--update" ] || [ "$1" = "-u" ]; then
    # 祝日情報を更新する
    mkdir -p "$path_local_share"
    tempfile=$(make_tempfile "syukujitu_XXX.csv")
    download_url "$url_holidays_csv" "$tempfile"
    mv "$tempfile" "$path_holidays_csv"
    shift
  fi
fi

has_err=0
if [ "$#" -eq 2 ]; then
  year="${1#0}"
  month="${2#0}"
  if [ "$month" -lt 1 ] || [ "$month" -gt 12 ]; then
    has_err=1
  fi
elif [ "$#" -eq 0 ]; then
  read -r year month <<EOF
$(date '+%Y %m')
EOF
  month="${month#0}"
else
  has_err=1
fi

if [ "$has_err" -eq 1 ]; then
  echo "usage: $prog [OPTIONS] [YYYY MM]" >&2
  echo "options:" >&2
  echo "  -u, --update  祝日情報を更新する" >&2
  echo "arguments:" >&2
  echo "  YYYY          年(4桁)" >&2
  echo "  MM            月(1-12)" >&2
  exit 1
fi

if [ "$year" -lt 1873 ]; then
  # 日本では1873年からグレゴリオ暦を採用している
  echo "error: 1873年以降をサポートしています" >&2
  exit 1
fi

# 月初日の曜日(first_day_wday)計算
first_day_wday=""
calc_weekday first_day_wday "$year" "$month" 1

# 月末日(last_mday)計算
last_mday=""
calc_lastday last_mday "$year" "$month"

# 祝日情報を取得
holidays="$(get_holidays "$year" "$month")"
if [ "$holidays" = "" ]; then
  echo "warn: 祝日情報がありません" >&2
fi

# 年月と曜日を出力
echo "     ${year}年${month}月"
echo "${red}日${clr} 月 火 水 木 金 ${blue}土${clr}"

# 月初日までの空白(曜日1つあたり3個のスペース)
row=$(printf "%$((first_day_wday * 3))s" "")

# 初日から月末までの日付を出力
wday=$first_day_wday
for d in $(seq "${last_mday}"); do
  # 出力用日付を2桁(前ゼロなし)に揃える
  if [ "$d" -le 9 ]; then dd=" $d"; else dd="$d"; fi
  # 祝日の判定
  case "$holidays" in
    (*:$d:*) is_holiday=1 ;; # 祝日
    (*)  is_holiday=0 ;; # それ以外
  esac
  # 曜日ごとに色を変えて出力
  case "$wday" in
    (0) row="$row$red$dd$clr " ;;
    (6)
      if [ "$is_holiday" -eq 1 ]; then
        row="$row$red$dd$clr" # 祝日(土)
      else
        row="$row$blue$dd$clr" # 土曜日
      fi
      echo "$row" # 1週間分を出力
      row=""
      ;;
    (*)
      if [ "$is_holiday" -eq 1 ]; then
        row="$row$red$dd$clr " # 祝日(月～金)
      else
        row="$row$dd " # 平日(月～金)
      fi
      ;;
  esac
  wday=$(( ( wday + 1 ) % 7 ))
done

# 出力未済の行があれば出力
if [ -n "$row" ]; then
  echo "$row"
fi
