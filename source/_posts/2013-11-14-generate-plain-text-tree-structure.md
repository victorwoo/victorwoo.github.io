---
layout: post
title: "快速生成树形结构的纯文本"
date: 2013-11-14 00:00:00
description: Generate Plain Text Tree Structure
categories: text
tags:
- text
- geek
- dos
- command
---
今天帮朋友整理一些材料，需要为这些材料整理一个目录。之前有研究过一些方案，例如：

- [Print plain text tree from tree data structure (java)][Print plain text tree from tree data structure (java)]
- [How to print binary tree diagram?][How to print binary tree diagram?]
- [How do I print out a tree structure?][How do I print out a tree structure?]
- [Expanding a tree-like data structure][Expanding a tree-like data structure]

[Print plain text tree from tree data structure (java)]: http://stackoverflow.com/questions/10861794/print-plain-text-tree-from-tree-data-structure-java
[How to print binary tree diagram?]: http://stackoverflow.com/questions/4965335/how-to-print-binary-tree-diagram/8948691
[How do I print out a tree structure?]: http://stackoverflow.com/questions/1649027/how-do-i-print-out-a-tree-structure/1649223
[Expanding a tree-like data structure]: http://stackoverflow.com/questions/7336985/expanding-a-tree-like-data-structure

这些方案有一个共性：麻烦。也就是无法像手头的工具一样拿来就用。于是发掘了一番，发现 `tree` 这个 dos 时代的命令刚好能满足需要。该命令的帮助如下：

	以图形显示驱动器或路径的文件夹结构。

	TREE [drive:][path] [/F] [/A]

	   /F   显示每个文件夹中文件的名称。
	   /A   使用 ASCII 字符，而不使用扩展字符。

我们可以用以下命令将 D:\work 下的结构输出到 output.txt 文本文件：

	TREE "D:\work" /F /A > output.txt

然后用记事本之类的文本编辑器对它进行简单的编辑，就可以达到目的。

还可以拓展一下思路：在撰写文章的时候，常常需要描述一个有层次的结构（可以是心得体会之类的，不仅限于描述一系列文件）。此时可以在硬盘里创建一个临时目录，在里面创建一些文件夹和文件，用资源管理器拖拽调整目录结构，然后用上述命令导出一个目录文件，就可以快速地用于文档的撰写了。**请不要徒手编辑这样的文本，因为那样很愚蠢，调整起来也相当费功夫。**

命令执行效果参考：

	卷 os 的文件夹 PATH 列表
	卷序列号为 0000002C 000E:BD6F
	C:.
	|   HaxLogs.log
	|   setmockup.log
	|   WEVTUTIL.exe
	|
	+---adt-bundle-windows-x86
	|   |   SDK Manager.exe
	|   |
	|   +---android-ndk-r9
	|   |   |   documentation.html
	|   |   |   GNUmakefile
	...
	|   |   |   README.TXT
	|   |   |   RELEASE.TXT
	|   |   |
	|   |   +---build
	|   |   |   +---awk
	|   |   |   |       check-awk.awk
	|   |   |   |       extract-debuggable.awk
