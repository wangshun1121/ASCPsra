#!/usr/bin/perl
# Wangshun @ Xiamen
# 2018.5.15

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use Cwd;
use POSIX ":sys_wait_h";
use FindBin qw($Bin);
use Parallel::ForkManager;
use Parallel::Simple qw(prun);

# 下面三行代码中涉及的程序路径可根据实际情况修改
our $ascp='~/.aspera/connect/bin/ascp';
our $KEY='~/.aspera/connect/etc/asperaweb_id_dsa.openssh';
our $fastq_dump='fastq-dump';

my $Check=`$ascp -h`;
unless($Check){
  print "Aspera should be installed first, see https://gitee.com/wangshun1121/ASCPsra \n";
  exit();
}
$Check= `$fastq_dump -h`;
unless($Check){
  print "NCBI fastq-dump should be installed first, see https://gitee.com/wangshun1121/ASCPsra \n";
  exit();
}

our $work_dir = getcwd;
our $Core = `grep \"process\" /proc/cpuinfo | wc -l `;
chomp($Core); # Core number of server


my $id;
my $source='SRA';
my $list;
my $link;
my $outdir='.';
my $cpu=$Core/2;
my $help;

GetOptions(
  'i|id=s' => \$id,
  'l|list=s' => \$list,
  'o|outdir=s' => \$outdir,
  's|source=s' => \$source,
  'p|cpu=i' => \$cpu,

  'h|help' => \$help,
);

my $usage=<<USAGE;

Usage:
  perl $0 -i SRRXXXXXX
  perl $0 -l SraAccList.txt -o ./sequences -p 20

  -i|-id	<str> 	   SRA accession ID
  -l|-list 	<file>	   SRA ID list, all IDs should be in one column

  -o|-outdir	<dir>	   Output directory [working directory $work_dir]
  -p|-cpu	<int>	   Threads number used for multi detasets downloading [$Core at most, $cpu default]

  -h|-help                 Show this message

USAGE

# ENA的下载暂时隐藏
# -s|-source    <str>      Where the data are from. SRA(default) or ENA. NO .sra files when downloading from ENA


if ($help) {
	print $usage;
	exit;
}

unless ($id or $list or $link) {
	print $usage;
	exit;
}

$source=uc($source);
unless(($source eq 'ENA') or ($source eq 'SRA')){
  print "Data source should only be SRA or ENA \n";
  exit;
}

unless(-e $outdir){
  system("mkdir -p $outdir");
}

if($id){
  &download($id,$outdir,$source);
  exit;
}

if($link){
  #帮助文件中暂时把这部分先隐藏吧
  &linkdownload($link,$outdir);
  exit;
}

if(-e $list){
  my @ids=();
  open I,"<$list";
  while (<I>) {
    chomp;
    s/\r//g; #Windows换行符考虑兼容
    push(@ids,(split/\t/)[0]);
  }

  if($cpu>scalar(@ids)){$cpu=scalar(@ids);}

  my $pm=new Parallel::ForkManager($cpu);
  foreach my $id (@ids) {
  	my $pid=$pm->start and next;
  	&download($id,$outdir,$source);

  	$pm->finish;
  };
  $pm->wait_all_children;

}

sub linkdownload{
  #直接给出下载链接，下载SRA数据
  #单纯下载数据，不再直接转换SRA到fastq了
  #这里先暂时用wget来代替。
  my $link=shift;
  my $outdir=shift;
  chdir($outdir);
  my $CMD="wget $link";
  chdir($work_dir);
}

sub download{
  # 下载SRA的核心函数
  my $id=shift;
  my $outdir=shift;
  my $source=shift;

  my $sub1=substr($id,0,3);
  my $sub2 =substr($id,0,6);

  my $link=();
  if($source eq 'SRA'){
    $link='anonftp@ftp-private.ncbi.nlm.nih.gov:/sra/sra-instant/reads/ByRun/sra';
    $link="$link/$sub1/$sub2/$id/$id.sra";
    my $CMD1="$ascp -v -i $KEY -k 1 -T -l 300m $link .";
    chdir($outdir);
    &run($CMD1);
    my $CMD2="$fastq_dump --gzip --split-3 $id.sra";
    &run($CMD2);
    chdir($work_dir);
  }
  if($source eq 'ENA'){
    print STDERR "Warning: downloading single end sequences from ENA are not taken into consideration\n";
    # ENA可直接下载fq数据，本版本中暂时仅考虑双端序列的情况
    $link='era-fasp@fasp.sra.ebi.ac.uk:/vol1/fastq';
    $link="$link/$sub2/$id/$id";

    my $CMD1="$ascp -QT -l 300m -P33001 -i $KEY $link\_1.fastq.gz .";
    my $CMD2="$ascp -QT -l 300m -P33001 -i $KEY $link\_2.fastq.gz .";

    #开双线程下载
    chdir($outdir);
    prun(
  		sub1=>[\&run,($CMD1)],
  		sub2=>[\&run,($CMD2)],
  	)or die(Parallel::Simple::errplus());
    chdir($work_dir);
  }


  sub run{
  	my $CMD = shift;
    my $log="$CMD\nStart:";
    $log.=localtime();
    $log.="\n";
  	$log.=`$CMD`;
    $log.="End:";
    $log.=localtime();
    $log.="\n\n";
    print $log;
  }
}
