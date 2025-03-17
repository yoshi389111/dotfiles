#!/usr/bin/env perl
'di';
'ig00';
#!/usr/bin/perl
########################################################################
# 指定したファイルのサイズ・日時を表示するコマンド
#    2002-02-20 v1.0 by yoshi389111
#    2003-04-04 v1.1 カレントディレクトリの場合、ファイル名でソートした
#    2003-08-08 v1.2 ll コマンドに似せて、出力項目を増やした
#
# ll コマンド(ls -l)の簡略版だが、日時を省略せずに表示するのが特徴
#
$VERSION = '@(#)$Header: ll.pl v1.2 2003-08-08 yoshi389111 Exp $';
$USAGE   = "usage: $0 [-ad] files...";
########################################################################

# flag of show with dot-file
$ALL_FILE = 0;

# flag of show only directory
$DIR_NOPRINT = 0;

##############################
# permission to string
##############################
sub str_perm
{
  local($MODE) = $_[0];
  local($perm) = "";

  # file type
  $perm = ' ';
  $perm = 's' if (($MODE & 0170000) == 0140000);
  $perm = 'l' if (($MODE & 0170000) == 0120000);
  $perm = 'n' if (($MODE & 0170000) == 0110000);
  $perm = '-' if (($MODE & 0170000) == 0100000);
  $perm = 'b' if (($MODE & 0170000) == 0060000);
  $perm = 'd' if (($MODE & 0170000) == 0040000);
  $perm = 'c' if (($MODE & 0170000) == 0020000);
  $perm = 'p' if (($MODE & 0170000) == 0010000);

  # user read/write
  $perm .= ($MODE & 0000400) ? 'r' : '-';
  $perm .= ($MODE & 0000200) ? 'w' : '-';

  # user exec
  $perm .= 's' if (($MODE & 0004100) == 0004100);
  $perm .= 'S' if (($MODE & 0004100) == 0004000);
  $perm .= 'x' if (($MODE & 0004100) == 0000100);
  $perm .= '-' if (($MODE & 0004100) == 0000000);

  # group read/write
  $perm .= ($MODE & 0000040) ? 'r' : '-';
  $perm .= ($MODE & 0000020) ? 'w' : '-';

  # group exec
  $perm .= 's' if (($MODE & 0002010) == 0002010);
  $perm .= 'S' if (($MODE & 0002010) == 0002000);
  $perm .= 'x' if (($MODE & 0002010) == 0000010);
  $perm .= '-' if (($MODE & 0002010) == 0000000);

  # other read/write
  $perm .= ($MODE & 0000004) ? 'r' : '-';
  $perm .= ($MODE & 0000002) ? 'w' : '-';

  # other exec
  $perm .= 't' if (($MODE & 0001001) == 0001001);
  $perm .= 'T' if (($MODE & 0001001) == 0001000);
  $perm .= 'x' if (($MODE & 0001001) == 0000001);
  $perm .= '-' if (($MODE & 0001001) == 0000000);

  return $perm;
}

##############################
# print ls format
##############################
sub prt_ls_format
{
  local($FILENAME)  = $_[0];
  local(@stat);
  local(@tm);
  local($perm);
  local(@pwu);
  local(@grp);

  @stat = stat($FILENAME);
  if (@stat == 0) {
    return;
  }

  # permission
  $perm = &str_perm($stat[2]);
  printf("%s ", $perm);

  # user name/id
  @pwu = getpwuid($stat[4]);
  printf("%-10s ", $pwu[0])  if ( $pwu[0] ne '' );
  printf("%-10d ", $stat[4]) if ( $pwu[0] eq '' );

  # group name/id
  @grp = getgrgid($stat[5]);
  printf("%-10s ", $grp[0])  if ( $grp[0] ne '' );
  printf("%-10d ", $stat[5]) if ( $grp[0] eq '' );

  if ( -b $FILENAME || -c $FILENAME ) {
    # device number
    printf("%3d 0x%.6x ",
      ($stat[6]>>24)&0xff,
      $stat[6]      &0xffffff);
  } else {
    # file size
    printf("%12d ", $stat[7]);
  }

  # time stamp
  @tm = localtime($stat[9]);
  printf("%.4d-%.2d-%.2d %.2d:%.2d:%.2d ",
    $tm[5]+1900,
    $tm[4]+1,
    $tm[3],
    $tm[2],
    $tm[1],
    $tm[0]);
}


##############################
# get otption letter
##############################
sub get_opts
{
  local($OPTIONS) = $_[0];
  local($i);
  local($ch);

  for ($i = 1; $i < length($OPTIONS); $i++) {
    $ch = substr($OPTIONS, $i, 1);

    if      ( $ch eq 'a' ) {
      $ALL_FILE = 1;
    } elsif ( $ch eq 'd' ) {
      $DIR_NOPRINT = 1;
    } else {
      print "Invalid option -$ch\n";
      &print_usage_message();
    }
  }
}

########################################################################
# print usage message
########################################################################
sub print_usage_message
{
  print stderr $VERSION, "\n\n";
  print stderr $USAGE, "\n";
  exit(8);
}

# 指定されたファイルのサイズ・日時・ファイル名を表示する
sub print_files {
  local(@files) = @_;
  local(@list);
  local($work_file);
  local($work_file2);

  for $work_file ( @files ) {

    if ( -d $work_file && $DIR_NOPRINT == 0 ) {
      $work_file =~ s#/+$##;
      $work_file = "/" if ($work_file eq "");
      if ( @files != 1 ) {
        printf("\n%s:\n", $work_file);
      }
      opendir(DIR, $work_file);
      if ($ALL_FILE) {
        # . と .. は除く
        @list = grep(!/^\.\.?$/, readdir(DIR));
      } else {
        # ドットから始まるファイルは除く
        @list = grep(!/^\./, readdir(DIR));
      }
      closedir(DIR);
      @list = sort(@list);
      for $work_file2 ( @list ) {
        &prt_ls_format($work_file . "/" . $work_file2);
        print $work_file2 . "\n";
      }
    } else {
      &prt_ls_format($work_file);
      print $work_file . "\n";
    }
  }
}

while ( $x = shift(@ARGV) ) {
  if ( $x =~ /^-/ ) {
    &get_opts($x);

  } else {
    &print_files($x, @ARGV);
    exit 0;
  }
}

&print_files(".");

.00;  # finish .ig
'di         \" finish diversion--previous line must be blank
.nr nl 0-1  \" fake up transition to first page agein
.nr % 0     \" start at page 1
'; __END__ ## manual page ##

.TH ll.pl 1
.AT 3
.SH 名称
ll.pl \- 必ず日時を表示する ll コマンド
.SH 構文
.nf
ll.pl [\-ad] [files...]
.SH 説明
ll コマンド (ls \-l) の簡略版です。
違い(特徴)は、日時を省略せずに必ず表示すること。
.SH オプション
.TP 10
\-a
指定されたディレクトリ内のドットファイルも表示します。
通常はドットファイルを表示しません。スーパーユーザーであっても同様です。

.TP 10
\-d
指定されたディレクトリそのものについて表示します。
通常はディレクトリを指定すると、ディレクトリ内のファイルについて表示します。

.SH 注意
ソートなどの機能は持っていません。
