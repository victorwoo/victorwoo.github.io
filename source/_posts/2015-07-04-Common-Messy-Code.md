layout: post
date: 2015-07-04 20:55:31
title: "常见的乱码"
description: Common Messy Code
categories:
- program
tags:
- encoding
---
这是一个程序员段子，实际上是几种常见的乱码：

    手持两把锟斤拷，
    口中疾呼烫烫烫。
    脚踏千朵屯屯屯，
    笑看万物锘锘锘。

# 锟斤拷的来历

Unicode和老编码体系的转化过程中，肯定有一些字，用Unicode是没法表示的，Unicode官方用了一个占位符来表示这些文字，这就是：U+FFFD REPLACEMENT CHARACTER。

那么U+FFFD的UTF-8编码出来，恰好是 '\xef\xbf\xbd'。如果这个'\xef\xbf\xbd'，重复多次，例如 '\xef\xbf\xbd\xef\xbf\xbd'，然后放到GBK/CP936/GB2312/GB18030的环境中显示的话，一个汉字2个字节，最终的结果就是：锟斤拷——锟(0xEFBF)，斤（0xBDEF），拷（0xBFBD）

# 烫烫烫的来历

在windows平台下，ms的编译器（也就是vc带的那个）在 Debug 模式下，会把未初始化的栈内存全部填成 0xcc，用字符串来看就是"烫烫烫烫烫烫烫"，也就是说出现了烫烫烫，赶紧检查初始化吧。。。

# 屯屯屯的来历

同上，未初始化的堆内存全部填成0xcd，字符串看就是“屯屯屯屯屯屯屯屯”。

# 锘的来历

微软在 UTF-8 文件头部加上了 `EF BB BF` BOM 标记。在不支持 BOM 的环境下对其进行 UTF-8 解码得到“锘”字。
