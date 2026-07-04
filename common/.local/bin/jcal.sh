#!/bin/sh
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 SATO Yoshiyuki

# NAME
#   jcal.sh - 日本のカレンダーを表示する
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
#   オプション(-3, --three-months)により前後3か月のカレンダーを表示します。
#   日本でグレゴリオ暦が適用された 1873 年以降が対象です。
#
#   祝日情報CSVファイルがあれば祝日も赤表示します。
#   祝日情報CSVファイルがない場合、あるいはあっても指定した年の情報がない場合には
#   ワーニングを表示します。
#
#   和暦には対応していません。
#
# OPTIONS
#   -u, --update
#     祝日情報を更新します。
#     必要な場合、環境変数 `https_proxy` を指定してください。
#   -3, --three-months
#     3か月分のカレンダーを表示します。
#
# FILES
#   ~/.local/share/jcal/syukujitsu.csv
#     祝日情報CSVファイル
#     内閣府が提供する祝日情報のCSVファイルをダウンロードして保存します。
#     エンコードはシフトJISのまま保存されます。
#
#   /tmp/syukujitsu_XXX.csv
#     祝日情報CSVファイルをダウンロードする場合の一時ファイル。
#     `XXX` 部分は一意なIDに置き換えられます。
#
# SEE ALSO
#   cal(1), date(1)

set -eu
script_name=${0##*/}
esc=""
eval "$(printf 'IFS=" \t\n" esc="\033"')"
fg_red="${esc}[38;5;09m"
bg_red="${esc}[30m${esc}[48;5;09m"
fg_blue="${esc}[38;5;33m"
bg_blue="${esc}[30m${esc}[48;5;33m"
bg_white="${esc}[30m${esc}[47;5;15m"
reset_color="${esc}[m"

# 内閣府が提供する祝日情報CSVファイル
# ref. <https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html>
# ref. <https://data.e-gov.go.jp/data/dataset/cao_20190522_0002/resource/d9ad35a5-6c9c-4127-bdbe-aa138fdffe42>
# ※フォーマットやファイル名が変更されることがあるので注意(2025年時点の仕様を想定)
url_holidays_csv='https://www8.cao.go.jp/chosei/shukujitsu/syukujitsu.csv'
# ホームディレクトリに保存する祝日情報のファイルパス
path_local_share=~/.local/share/jcal
path_holidays_csv="${path_local_share}/syukujitsu.csv"

# 使い方を表示
# usage: print_usage
print_usage() {
  cat - <<EOD
usage: $script_name [OPTIONS] [YYYY MM]
options:
  -u, --update
        祝日情報を更新する
  -3, --three-months
        3か月分のカレンダーを表示する
arguments:
  YYYY  年(1873年以降)
  MM    月(1-12)
EOD
}

# エラーメッセージ出力して終了
# usage: error_exit [MESSAGE]
error_exit() {
  [ $# -eq 1 ] && printf "error: %s\n\n" "$1" >&2
  print_usage >&2
  exit 1
}

# 数字の判定
# 結果は終了コードで返却します
# usage: is_number <STRING>
is_number() {
  case "$1" in
  '' | *[!0-9]*) return 1 ;;
  *) return 0 ;;
  esac
}

# ゼロサプレス
# usage: remove_leading_zeros <VAR_NAME> <VALUE>
remove_leading_zeros() {
  [ -z "$2" ] && return
  while [ "${2#0}" != "$2" ]; do
    set -- "$1" "${2#0}"
  done
  [ -z "$2" ] && set -- "$1" 0
  eval "$1=\$2"
}

# 後ろスペーストリム
# usage: trim_right_spaces <VAR_NAME> <VALUE>
trim_right_spaces() {
  [ -z "$2" ] && return
  while [ "${2% }" != "$2" ]; do
    set -- "$1" "${2% }"
  done
  eval "$1=\$2"
}

# 曜日の計算
# - グレゴリオ暦で計算します
# - 先発グレゴリオ暦の紀元前は正しく計算できないことがあります
# usage: get_weekday <VAR_NAME> <YEAR> <MONTH> <DAY>
get_weekday() {
  # 1月または2月の場合、前年の13月、14月として計算
  [ "$3" -le 2 ] && set -- "$1" $(($2 - 1)) $(($3 + 12)) "$4"
  # ツェラーの公式で計算（カッコ内はツェラーの公式(原書)での変数名）
  # $1=変数名, $2=年, $3=月(m), $4=日(q), $5=年の下2桁(K), $6=年の上2桁(J)
  set -- "$1" "$2" "$3" "$4" $(($2 % 100)) $(($2 / 100))
  eval "$1=$((($4 + (13 * ($3 + 1)) / 5 + $5 + $5 / 4 + $6 / 4 + 5 * $6 + 6) % 7))"
}

# うるう年の判定
# 結果は終了コードで返却します
# - グレゴリオ暦で計算します
# - 先発グレゴリオ暦の紀元前は正しく計算できないことがあります
# usage: is_leap_year <YEAR>
is_leap_year() {
  if [ $(($1 % 4)) -eq 0 ]; then
    if [ $(($1 % 100)) -ne 0 ] || [ $(($1 % 400)) -eq 0 ]; then
      return 0 # うるう年
    fi
  fi
  return 1 # 平年
}

# 月末日の計算
# - グレゴリオ暦で計算します
# - 先発グレゴリオ暦の紀元前は正しく計算できないことがあります
# - 不正な月のチェックはしていません
# usage: get_last_day_of_month <VAR_NAME> <YEAR> <MONTH>
get_last_day_of_month() {
  case "$3" in
  2)
    if is_leap_year "$2"; then
      set -- "$1" 29 # うるう年
    else
      set -- "$1" 28 # 平年
    fi
    ;;
  4 | 6 | 9 | 11) set -- "$1" 30 ;;
  *) set -- "$1" 31 ;;
  esac
  eval "$1=\$2"
}

# 指定のURLからファイルをダウンロード
# usage: download_file <URL> <OUTPUT_FILE>
download_file() {
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
    return 1
  fi
}

# 一時ファイルの作成
# テンプレート中の `XXX` を一意情報に置き換えます
# 生成した一時ファイル名は stdout に出力します
# コマンド置換（サブシェル）で呼び出されることが前提です
# usage: create_tempfile <TEMPLATE>
create_tempfile() {
  now=$(date +'%Y%m%d%H%M%S%z') || return $?
  uniq_id="${now}_$$"
  file="${TMPDIR:-/tmp}/${1%%XXX*}${uniq_id}${1#*XXX}"
  umask 077
  set -C
  : >"$file" || return $?
  echo "$file"
}

# 文字列を IFS で分割
# usage: split_string <STRING> <VAR_NAME>...
split_string() {
  [ $# -lt 2 ] && return 1
  eval "$2=\$1; shift; read -r \"\$@\" <<EOD
\$$2
EOD"
}

# 祝日情報の取得
# 指定された年月の祝日情報を stdout に出力します
# 出力形式は `:1:15:21:` のように祝日の日付の前後にコロンがあります
# ただし、指定の年の祝日がない場合には何も出力しません。
# 指定の年の祝日はあるが指定の年月の祝日がない場合には `:` を出力します。
# コマンド置換（サブシェル）で呼び出されることが前提です。
# usage: get_holidays_for_month <YEAR> <MONTH>
get_holidays_for_month() {
  year=$1
  month=$2
  # 祝日情報CSVファイルはシフトJISで保存されているので
  # 念のためCロケールで読み込む
  export LANG=C
  holidays=""
  has_holidays=""

  if [ -r "$path_holidays_csv" ]; then
    while read -r holiday || [ "$holiday" ]; do
      holiday=${holiday%%,*} # 祝日の名前部分を削除
      # 2020年以降はスラッシュ区切りの前ゼロなしだが
      # 2017年3月頃はハイフン区切りの前ゼロありだったので念のため両対応
      # （2017年2月頃のデータはパースが困難なので対応しない）
      # ref. <https://okumuralab.org/~okumura/stat/holidays.html>
      case "$holiday" in
      [1-9][0-9][0-9][0-9][-/][0-1][0-9][-/][0-3][0-9]) ;;
      [1-9][0-9][0-9][0-9][-/][0-1][0-9][-/][1-9]) ;;
      [1-9][0-9][0-9][0-9][-/][1-9][-/][0-3][0-9]) ;;
      [1-9][0-9][0-9][0-9][-/][1-9][-/][1-9]) ;;
      *) continue ;; # それ以外はスキップ
      esac
      holiday_year="" holiday_month="" holiday_day=""
      IFS="/-" split_string "$holiday" holiday_year holiday_month holiday_day
      remove_leading_zeros holiday_month "$holiday_month"
      remove_leading_zeros holiday_day "$holiday_day"
      if [ "$year" -eq "$holiday_year" ]; then
        has_holidays=1
        if [ "$month" -eq "$holiday_month" ]; then
          holidays="$holidays:$holiday_day"
        fi
      fi
    done <"$path_holidays_csv"
  fi
  if [ "$has_holidays" ]; then
    echo "$holidays:"
  fi
}

# 先月の年月を計算して指定の変数に格納します
# usage: get_previous_month_and_year <YEAR_VAR> <MONTH_VAR> <YEAR> <MONTH>
get_previous_month_and_year() {
  [ $# -ne 4 ] && return 1
  if [ "$4" -eq 1 ]; then
    eval "$1=$(($3 - 1))"
    eval "$2=12"
  else
    eval "$1=$3"
    eval "$2=$(($4 - 1))"
  fi
}

# 来月の年月を計算して指定の変数に格納します
# usage: get_next_month_and_year <YEAR_VAR> <MONTH_VAR> <YEAR> <MONTH>
get_next_month_and_year() {
  [ $# -ne 4 ] && return 1
  if [ "$4" -eq 12 ]; then
    eval "$1=$(($3 + 1))"
    eval "$2=1"
  else
    eval "$1=$3"
    eval "$2=$(($4 + 1))"
  fi
}

# カレンダーのヘッダー（年月）を指定の変数に追加する
# usage: append_calendar_header <VAR_NAME> <YEAR> <MONTH>
append_calendar_header() {
  [ $# -ne 3 ] && return 1
  if [ "$3" -le 9 ]; then
    set -- "$1" "$2" " $3"
  else
    set -- "$1" "$2" "$3"
  fi
  eval "$1=\"\${$1}     ${2}年${3}月     \""
}

# カレンダーの曜日ヘッダーを指定の変数に追加する
# usage: append_calendar_weekdays <VAR_NAME>
append_calendar_weekdays() {
  [ $# -ne 1 ] && return 1
  eval "$1=\"\${$1}${fg_red}日${reset_color} 月 火 水 木 金 ${fg_blue}土${reset_color}\""
}

# 指定の日を曜日・祝日に応じて色を変えて変数に格納する
# usage: append_day <VAR_NAME> <YEAR> <MONTH> <DAY> <WEEKDAY> <HOLIDAYS>
# 注
#   参照するグローバル変数: current_year, current_month, current_day
#   更新するグローバルな変数: wk_day, is_holiday, lastday
append_day() {
  [ $# -ne 6 ] && return 1
  lastday=""
  get_last_day_of_month lastday "$2" "$3"
  if [ "$4" -lt 1 ] || [ "$4" -gt "$lastday" ]; then
    eval "$1=\"\${$1}  \""
    return 0
  fi
  wk_day=$4
  if [ "$wk_day" -le 9 ]; then wk_day=" $wk_day"; fi
  case "$6" in
  *:$4:*) is_holiday=1 ;; # 祝日
  *) is_holiday="" ;;     # それ以外
  esac
  if [ "$2" -eq "$current_year" ] &&
    [ "$3" -eq "$current_month" ] &&
    [ "$4" -eq "$current_day" ]; then
    # 今日の場合
    if [ "$5" -eq 0 ] || [ "$is_holiday" ]; then
      eval "$1=\"\${$1}${bg_red}${wk_day}${reset_color}\"" # 今日(日曜日 or 祝日)
    elif [ "$5" -eq 6 ]; then
      eval "$1=\"\${$1}${bg_blue}${wk_day}${reset_color}\"" # 今日(土曜日)
    else
      eval "$1=\"\${$1}${bg_white}${wk_day}${reset_color}\"" # 今日(平日)
    fi
  else
    # 今日以外の場合
    if [ "$5" -eq 0 ] || [ "$is_holiday" ]; then
      eval "$1=\"\${$1}${fg_red}${wk_day}${reset_color}\"" # 日曜日 or 祝日
    elif [ "$5" -eq 6 ]; then
      eval "$1=\"\${$1}${fg_blue}${wk_day}${reset_color}\"" # 土曜日
    else
      eval "$1=\"\${$1}${wk_day}\"" # 平日
    fi
  fi
}

# 指定の年月のカレンダー1週間分を指定の変数に追加する
# usage: append_calendar_week <VAR_NAME> <YEAR> <MONTH> <WEEK_NUMBER> <HOLIDAYS>
# 注：
#  更新するグローバル変数: weekday_of_first_day
append_calendar_week() {
  [ $# -ne 5 ] && return 1
  # 月初の曜日を取得
  weekday_of_first_day=""
  get_weekday weekday_of_first_day "$2" "$3" 1
  append_day "$1" "$2" "$3" $(($4 * 7 - weekday_of_first_day + 1)) 0 "$5"
  eval "$1=\"\${$1} \""
  append_day "$1" "$2" "$3" $(($4 * 7 - weekday_of_first_day + 2)) 1 "$5"
  eval "$1=\"\${$1} \""
  append_day "$1" "$2" "$3" $(($4 * 7 - weekday_of_first_day + 3)) 2 "$5"
  eval "$1=\"\${$1} \""
  append_day "$1" "$2" "$3" $(($4 * 7 - weekday_of_first_day + 4)) 3 "$5"
  eval "$1=\"\${$1} \""
  append_day "$1" "$2" "$3" $(($4 * 7 - weekday_of_first_day + 5)) 4 "$5"
  eval "$1=\"\${$1} \""
  append_day "$1" "$2" "$3" $(($4 * 7 - weekday_of_first_day + 6)) 5 "$5"
  eval "$1=\"\${$1} \""
  append_day "$1" "$2" "$3" $(($4 * 7 - weekday_of_first_day + 7)) 6 "$5"
}

show_three_months=""
while [ $# -ge 1 ]; do
  if [ "$1" = "--update" ] || [ "$1" = "-u" ]; then
    # 祝日情報を更新する
    mkdir -p "$path_local_share"
    tempfile=$(create_tempfile "syukujitsu_XXX.csv")
    download_file "$url_holidays_csv" "$tempfile"
    mv "$tempfile" "$path_holidays_csv"
    shift
  elif [ "$1" = "--three-months" ] || [ "$1" = "-3" ]; then
    # 3か月分のカレンダーを表示する
    show_three_months=1
    shift
  else
    break
  fi
done

today=$(date +'%Y-%m-%d')
current_year="" current_month="" current_day=""
IFS=- split_string "$today" current_year current_month current_day

if [ $# -eq 2 ]; then
  year=$1
  month=$2
elif [ $# -eq 0 ]; then
  year=$current_year
  month=$current_month
else
  error_exit "引数の指定が正しくありません"
fi

remove_leading_zeros year "$year"
remove_leading_zeros month "$month"

if ! is_number "$year"; then
  error_exit "年は数値を指定してください"
elif [ "$year" -lt 1873 ]; then
  # 日本では1873年からグレゴリオ暦を採用している
  error_exit "1873年以降のみをサポートしています" >&2
elif [ "$year" -eq 1873 ] && [ "$month" -eq 1 ] && [ "$show_three_months" ]; then
  # 3か月表示で1873年1月を指定した場合
  error_exit "3か月表示は1873年2月以降のみをサポートしています" >&2
elif ! is_number "$month"; then
  error_exit "月は数値を指定してください"
elif [ "$month" -lt 1 ] || [ "$month" -gt 12 ]; then
  error_exit "月は1から12の範囲で指定してください"
fi

if [ "$show_three_months" ]; then
  # 3か月分のカレンダーを表示する
  # 該当月の祝日情報を取得
  holidays=$(get_holidays_for_month "$year" "$month")
  prev_year="" prev_month=""
  get_previous_month_and_year prev_year prev_month "$year" "$month"
  holidays_prev=$(get_holidays_for_month "$prev_year" "$prev_month")
  next_year="" next_month=""
  get_next_month_and_year next_year next_month "$year" "$month"
  holidays_next=$(get_holidays_for_month "$next_year" "$next_month")
  if [ -z "$holidays" ] || [ -z "$holidays_prev" ] || [ -z "$holidays_next" ]; then
    echo "warn: 祝日情報がありません" >&2
  fi

  line=""
  append_calendar_header line "$prev_year" "$prev_month"
  line="${line}  "
  append_calendar_header line "$year" "$month"
  line="${line}  "
  append_calendar_header line "$next_year" "$next_month"
  trim_right_spaces line "$line"
  printf "%s\n" "$line"

  line=""
  append_calendar_weekdays line
  line="${line}  "
  append_calendar_weekdays line
  line="${line}  "
  append_calendar_weekdays line
  trim_right_spaces line "$line"
  printf "%s\n" "$line"

  week_number=0
  while [ "$week_number" -lt 6 ]; do
    line=""
    append_calendar_week line "$prev_year" "$prev_month" "$week_number" "$holidays_prev"
    line="${line}  "
    append_calendar_week line "$year" "$month" "$week_number" "$holidays"
    line="${line}  "
    append_calendar_week line "$next_year" "$next_month" "$week_number" "$holidays_next"
    trim_right_spaces line "$line"
    if [ -z "$line" ]; then
      break
    fi
    printf "%s\n" "$line"
    week_number=$((week_number + 1))
  done
else
  # 該当月の祝日情報を取得
  holidays=$(get_holidays_for_month "$year" "$month")
  if [ -z "$holidays" ]; then
    echo "warn: 祝日情報がありません" >&2
  fi

  line=""
  append_calendar_header line "$year" "$month"
  trim_right_spaces line "$line"
  printf "%s\n" "$line"

  line=""
  append_calendar_weekdays line
  trim_right_spaces line "$line"
  printf "%s\n" "$line"

  week_number=0
  while [ "$week_number" -lt 6 ]; do
    line=""
    append_calendar_week line "$year" "$month" "$week_number" "$holidays"
    trim_right_spaces line "$line"
    if [ -z "$line" ]; then
      break
    fi
    printf "%s\n" "$line"
    week_number=$((week_number + 1))
  done
fi
