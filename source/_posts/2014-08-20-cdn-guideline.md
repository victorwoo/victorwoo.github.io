layout: post
title: CDN 资源
date: 2014-08-20 10:57:48
description: CDN resources
categories: web
tags:
- web
- develop
- cdn
---
# 常用 CDN 列表

* [Make the Web Faster — Google Developers](https://developers.google.com/speed/* libraries/?hl=zh-CN)
* [Microsoft Ajax Content Delivery Network - ASP.NET Ajax Library](http://www.asp* .net/ajaxlibrary/cdn.ashx)
* [docs/cplat/libs - 百度开放云平台](http://developer.baidu.com/wiki/index.* php?title=docs/cplat/libs)
* [Public Resources on SAE](http://lib.sinaapp.com/)
* [开放静态文件 CDN](http://www.staticfile.org/)
* [cdnjs.com - the missing cdn for javascript and css](http://cdnjs.com/)

# 命令行

由 [开放静态文件 CDN](http://www.staticfile.org/) 提供的：

    npm install -g sfile

详见 [staticfile/cli](https://github.com/staticfile/cli#readme)

# 故障转移代码

    <script type="text/javascript" src="//cdnjs.cloudflare.com/ajax/libs/jquery/2.0.3/jquery.min.js"></script>
    <script type="text/javascript">!window.jQuery && document.write('<script type="text/javascript" src="/js/libs/jquery-2.0.3.min.js"><\/script>')</script>  

# 引用多个script

    <script type="text/javascript" src="http://www.google.com/jsapi"></script>

引用 jQuery 时：

    google.load("jquery","1.3.2");
