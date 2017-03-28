layout: post
title: 快速选取百度云盘文件
date: 2014-09-29 11:39:47
description: Quick Selection on BaiDu Pan
categories: javascript
tags:
- javascript
- geek
---
网页版百度云盘一次性只能选取 100 个文件。如果我要对 500 个文件做批量操作就很困难了。

这时候我们可以在浏览器的地址栏内敲入这行代码，就自动帮您勾选前 100 个文件（夹）了：

    javascript:$("span[node-type='chk']:lt(101)").addClass("chked")
