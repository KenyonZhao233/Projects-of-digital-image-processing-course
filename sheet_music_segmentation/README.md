# 乐谱分割与识别

这里提供了一个很弱的Baseline程序供参考

程序主要以水平与垂直两个方向的像素和作为依据对乐谱进行分割

![](example/h.jpg)

![](example/v.jpg)

更多的数据集：

链接：https://pan.baidu.com/s/1DCwv6aw42PTHv2y0QDlXNA 
提取码：cut1

(目前Baseline程序仅针对吉他谱)



Bug修改记录：

1.空字符串报错bug

2.32位png读取bug

3.加入了简单的去水印操作（未测试）

4.加入了简单的去图片顶部干扰操作（未测试）



TODO LIST：

多种模式下都能正确显示简谱与歌词区域（目前此功能十分孱弱）

支持更多种乐器的乐谱