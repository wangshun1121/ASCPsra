# ASCPsra

将速铂下载工具进行封装，以便高效方便地批量下载SRA测序数据。

本脚本试图将速铂进行封装，实现只需提供SRA的ID号，即可完成序列下载和转换。

参考文章：[**SRA、SAM以及Fastq文件高速下载方法**](http://bioinfostar.com/2017/12/23/How-to-download-SRA-data-zh_CN/)。

## 更新信息

* 默认下载源更新为ENA

* ENA下载fastq文件实现了自动的md5校验，且通过md5校验信息，自动识别ID对应的测序文件是单端还是双端

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

### 直接下载Reads

```
perl ASCPsra.pl -i SRR7166333
```

直接将[**SRR7166333**](https://www.ebi.ac.uk/ena/data/view/SRR7166333)的fastq的序列下载在当前目录。RR7166333_1.fastq.gz和SRR7166333_2.fastq.gz两个文件。还有一个md5文件。下载结束，请使用下面的命令校验一下文件：

```
md5sum -c md5
```



### SRA数据一键下载

```
perl ASCPsra.pl -s SRA -i SRR7166333
```

直接将[**SRR7166333**](https://www.ncbi.nlm.nih.gov/sra/SRR7166333)的fastq的序列下载在当前目录。产生SRR7166333.sra、SRR7166333_1.fastq.gz和SRR7166333_2.fastq.gz三个文件。

SRA数据源没有给md5，因为只有完整的SRA文件才能够成功释放出fastq。

### 多个数据下载到指定文件夹中

**SraAccList.txt**中，两个ID都是大肠杆菌的测序数据。其中**SRR7167489**是双端数据，**ERR2002452**是单端数据。

```
perl ASCPsra.pl -l SraAccList.txt -o ./data
```

通过上面的命令，直接讲它们同时下载在./data的文件夹当中。每个ID，都有对应的fastq.gz文件。还有一个md5文件，下载结束务必校验一下文件完整性。

> * 文件下载结束，可将下载命令重新运行一遍，程序会自动检查文件完整性，正确下载的文件会自动跳过，未正确下载的文件会继续下载。
> * 这个福利仅限于ENA来源的数据

### 下载单端测序数据

**若给出SRA ID列表下载多个数据时，目前单端跟双端不可以从NCBI SRA源同时下！但是ENA可以。**

针对SRA数据源，添加单端single end数据，只需添加-single即可。(在将来的版本更新中，希望将这个参数取消，即让程序自动识别单端与双端)。

单端数据下载实例见：**ERR2002452**([SRA](https://trace.ncbi.nlm.nih.gov/Traces/sra/?run=ERR2002452),[ENA](https://www.ebi.ac.uk/ena/data/view/ERR2002452))。

```
perl ASCPsra.pl -i ERR2002452 -s SRA
```
