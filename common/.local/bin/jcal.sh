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
#   和暦には対応していません。
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
#   /tmp/syukujitsu_XXX.csv
#     祝日情報CSVファイルをダウンロードする場合の一時ファイル。
#     `XXX` 部分は一意なIDに置き換えられます。
#
# SEE ALSO
#   cal(1), date(1)
#
# COPYRIGHT
#   (C) 2025 SATO Yoshiyuki. MIT Licensed.

set -eu
script_name=${0##*/}
esc=""
eval "$(printf 'IFS=" \t\n" esc="\033"')"
red="${esc}[38;5;09m"                         # 前景色:赤
rev_red="${esc}[30m${esc}[48;5;09m"   # 背景色:赤
blue="${esc}[38;5;33m"                        # 前景色:青
rev_blue="${esc}[30m${esc}[48;5;33m"  # 背景色:青
rev_white="${esc}[30m${esc}[47;5;15m" # 背景色:白
reset_color="${esc}[m"                        # color reset

# 内閣府が提供する祝日情報CSVファイル
# ref. <https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html>
# ref. <https://data.e-gov.go.jp/data/dataset/cao_20190522_0002/resource/d9ad35a5-6c9c-4127-bdbe-aa138fdffe42>
# ※フォーマットやファイル名が変更されることがあるので注意(2025年時点の仕様を想定)
url_holidays_csv='https://www8.cao.go.jp/chosei/shukujitsu/syukujitsu.csv'
# ホームディレクトリに保存する祝日情報のファイルパス
path_local_share=~/.local/share/jcal
path_holidays_csv="${path_local_share}/syukujitsu.csv"

# 使い方を表示する
# usage: print_usage
print_usage() {
  cat - <<EOD
usage: $script_name [OPTIONS] [YYYY MM]
options:
  -u, --update
        祝日情報を更新する
arguments:
  YYYY  年(1873年以降)
  MM    月(1-12)
EOD
}

# エラーメッセージ出力して終了する
# usage: error_exit [MESSAGE]
error_exit() {
  [ $# -eq 1 ] && printf "error: %s\n\n" "$1" >&2
  print_usage >&2
  exit 1
}

# 数字であるかを判定する
# 結果は終了コードで返却する
# usage: is_number <STRING>
is_number() {
  case "$1" in
  '' | *[!0-9]*) return 1 ;;
  *) return 0 ;;
  esac
}

# ゼロサプレスを行う
# usage: remove_leading_zeros <VAR_NAME> <VALUE>
remove_leading_zeros() {
  [ -z "$2" ] && return
  while [ "${2#0}" != "$2" ]; do
    set -- "$1" "${2#0}"
  done
  [ -z "$2" ] && set -- "$1" 0
  eval "$1=\$2"
}

# 曜日を計算して変数に代入する
# - グレゴリオ暦で計算します
# - 先発グレゴリオ暦の紀元前は正しく計算できないことがあります
# usage: get_weekday <VAR_NAME> <YEAR> <MONTH> <DAY>
get_weekday() {
  if [ "$3" -le 2 ]; then
    # 1月または2月の場合、前年の13月、14月として計算
    set -- "$1" $(($2 - 1)) $(($3 + 12)) "$4"
  fi
  # ツェラーの公式で計算（カッコ内はツェラーの公式(原書)での変数名）
  # $1=変数名, $2=年, $3=月(m), $4=日(q), $5=年の下2桁(K), $6=年の上2桁(J)
  set -- "$1" "$2" "$3" "$4" $(($2 % 100)) $(($2 / 100))
  eval "$1=$((($4 + (13 * ($3 + 1)) / 5 + $5 + $5 / 4 + $6 / 4 + 5 * $6 + 6) % 7))"
}

# うるう年かどうかを判定する
# 結果は終了コードで返却する
# usage: is_leap_year <YEAR>
is_leap_year() {
  if [ $(($1 % 4)) -eq 0 ] && [ $(($1 % 100)) -ne 0 ] || [ $(($1 % 400)) -eq 0 ]; then
    return 0 # うるう年
  else
    return 1 # 平年
  fi
}

# 指定年月の月末日を計算して変数に代入する
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

# 指定のURLからファイルをダウンロードして保存する
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

# 一時ファイルを作成する
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

# 文字列を IFS で分割して変数に代入する
# usage: split_string <STRING> <VAR_NAME>...
split_string() {
  [ $# -lt 2 ] && return 1
  eval "$2=\$1; shift; read -r \"\$@\" <<EOD
\$$2
EOD"
}

# 指定年月の祝日情報を取得する
# 祝日情報は stdout に出力する
# 出力形式は `:1:15:21:` のように祝日の日付の前後にコロンがある
# ただし、指定の年の祝日がない場合には何も出力しない
# 指定の年の祝日はあるが指定の年月の祝日がない場合には `:` を出力する
# コマンド置換（サブシェル）で呼び出されることが前提です
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

if [ $# -ge 1 ]; then
  if [ "$1" = "--update" ] || [ "$1" = "-u" ]; then
    # 祝日情報を更新する
    mkdir -p "$path_local_share"
    tempfile=$(create_tempfile "syukujitsu_XXX.csv")
    download_file "$url_holidays_csv" "$tempfile"
    mv "$tempfile" "$path_holidays_csv"
    shift
  fi
fi

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
elif ! is_number "$month"; then
  error_exit "月は数値を指定してください"
elif [ "$month" -lt 1 ] || [ "$month" -gt 12 ]; then
  error_exit "月は1から12の範囲で指定してください"
fi

# 月初の曜日
weekday_of_first_day=""
get_weekday weekday_of_first_day "$year" "$month" 1

# 月末日
last_day_of_month=""
get_last_day_of_month last_day_of_month "$year" "$month"

# 該当月の祝日情報を取得
holidays=$(get_holidays_for_month "$year" "$month")
if [ -z "$holidays" ]; then
  echo "warn: 祝日情報がありません" >&2
fi

# カレンダーの年月と曜日を出力
echo "     ${year}年${month}月"
echo "${red}日${reset_color} 月 火 水 木 金 ${blue}土${reset_color}"

# 月初日までの空白(曜日1つあたり3個のスペース)
line=$(printf "%$((weekday_of_first_day * 3))s" "")

# 初日から月末までの日付を出力
weekday=$weekday_of_first_day
for d in $(seq "$last_day_of_month"); do
  # 出力用日付を2桁(前ゼロなし)に揃える
  if [ "$d" -le 9 ]; then dd=" $d"; else dd="$d"; fi
  # 祝日の判定
  case "$holidays" in
  *:$d:*) is_holiday=1 ;; # 祝日
  *) is_holiday="" ;;     # それ以外
  esac
  # 曜日ごとに色を変えて出力
  if [ "$year" -eq "$current_year" ] && [ "$month" -eq "$current_month" ] && [ "$d" -eq "$current_day" ]; then
    if [ "$weekday" -eq 0 ] || [ "$is_holiday" ]; then
      line="${line}${rev_red}${dd}${reset_color}" # 今日(日曜日 or 祝日)
    elif [ "$weekday" -eq 6 ]; then
      line="${line}${rev_blue}${dd}${reset_color}" # 今日(土曜日)
    else
      line="${line}${rev_white}${dd}${reset_color}" # 今日(平日)
    fi
  else
    if [ "$weekday" -eq 0 ] || [ "$is_holiday" ]; then
      line="${line}${red}${dd}${reset_color}" # 日曜日 or 祝日
    elif [ "$weekday" -eq 6 ]; then
      line="${line}${blue}${dd}${reset_color}" # 土曜日
    else
      line="${line}${dd}" # 平日
    fi
  fi
  if [ "$weekday" -eq 6 ]; then
    echo "$line" # 1週間分を出力
    line=""
  else
    line="$line "
  fi
  weekday=$(((weekday + 1) % 7))
done

# 出力未済の行があれば出力
if [ "$line" ]; then
  echo "$line"
fi
