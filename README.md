# ASCPsra

将速铂下载工具进行封装，以便高效方便地批量下载SRA测序数据。

本脚本试图将速铂进行封装，实现只需提供SRA的ID号，即可完成序列下载和转换。

参考文章：[**SRA、SAM以及Fastq文件高速下载方法**](http://bioinfostar.com/2017/12/23/How-to-download-SRA-data-zh_CN/)。

## 更新信息

* 添加了[**pfastq-dump**](https://github.com/inutano/pfastq-dump)支持，可设定SRA转换fq的线程。若线程数指定为1则仍然采用默认的fastq-dump。

* 默认参数修改。考虑到同时下载太多文件网络可能会拥堵，故将默认的文件下载数目调整为4。

## 程序安装与环境部署

### 获取程序

输入下面的命令：

```
git clone https://gitee.com/wangshun1121/ASCPsra.git
perl ./ASCPsra.pl -h
```

若一切安装就绪，则会显示帮助信息。若部分组件未部署好，则程序会有提示。

### 依赖的perl modules安装

需要安装**Parallel::ForkManager**和**Parallel::Simple**两个perl module，以实现多个SRA并行下载。命令如下：

```
sudo cpan install Parallel::ForkManager
sudo cpan install Parallel::Simple
```

或者通过cpanm安装(cpanm使用方法看[**这里**](https://blog.csdn.net/memray/article/details/17543791))：

```
sudo cpanm --mirror http://mirrors.163.com/cpan Parallel::ForkManager
sudo cpanm --mirror http://mirrors.163.com/cpan Parallel::Simple
```


### 安装 aspera connect

官网下载最新版：http://downloads.asperasoft.com/en/downloads/8?list 。

或者，点[**这里**](https://pan.baidu.com/s/1mXWkCw3yIwoc6LVrdKo9LA)通过百度云盘下载aspera-connect-3.7.4.147727-linux-64.tar.gz。

下载完成后部署aspera connect，下面的命令**不要使用ROOT账户**运行：

```
wget http://download.asperasoft.com/download/sw/connect/3.7.4/aspera-connect-3.7.4.147727-linux-64.tar.gz
tar zxvf aspera-connect-3.7.4.147727-linux-64.tar.gz
bash aspera-connect-3.7.4.147727-linux-64.sh

# 查看是否有.aspera文件夹
cd # 去根目录
ls -a # 如果看到.aspera文件夹，代表安装成功

```

运行结束，在home文件夹的 ～/.aspera/connect 中可发现部署的工具：

### 安装 NCBI fastq-dump

从NCBI的ftp上下载最新的sratoolkit，或者通过[**百度云盘**](https://pan.baidu.com/s/1k6ajnCqE85PfobNn83faFQ)下载sratoolkit.2.9.0-ubuntu64.tar.gz。安装方式按照下面的命令进行：

```
wget https://ftp-private.ncbi.nlm.nih.gov/sra/sdk/current/sratoolkit.current-ubuntu64.tar.gz
tar zxvf sratoolkit.current-ubuntu64.tar.gz

# 永久添加环境变量
echo 'export PATH=/path/to/sratoolkit.current-ubuntu64/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 检查程序是否可用
fastq-dump -h

```

## 使用示例

### SRA数据一键下载

```
perl ASCPsra.pl -i SRR7166333
```

直接将[**SRR7166333**](https://www.ncbi.nlm.nih.gov/sra/SRR7166333)的fastq的序列下载在当前目录。产生SRR7166333.sra、SRR7166333_1.fastq.gz和SRR7166333_2.fastq.gz三个文件。

### 多个SRA数据下载到指定文件夹中

```
perl ASCPsra.pl -l SraAccList.txt -o ./data -t 8
```

SraAccList.txt中给出了5个SRA的ID。通过上面的命令，直接讲它们同时下载在./data的文件夹当中。每个SRA数据，都有SRAXXXXXX.sra、SRAXXXXXX_1.fastq.gz和SRAXXXXXX_2.fastq.gz三个文件。-t参数设置SRA转换fastq时，pfastq-dump的线程数目。

### 可以指定ENA，直接下载Reads

```
perl ASCPsra.pl -I SRR7166333 -s ENA
```

注意：目前`-s ENA`仅仅支持双端Reads的下载。单端的Reads尚未支持。

### 部分SRA数据可能下载失败

经过测试，发现有一部分SRA的数据不能直接通过本脚本下载，例如[**SRR7167489**](https://trace.ncbi.nlm.nih.gov/Traces/sra/?run=SRR7167489)。请大家使用本脚本的时候切记留意程序产生的日志文件和报错信息，以及下载数据是否完整。