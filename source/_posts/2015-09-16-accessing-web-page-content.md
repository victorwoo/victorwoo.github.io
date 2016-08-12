layout: post
date: 2015-09-16 11:00:00
title: "PowerShell 技能连载 - 访问网页内容"
description: PowerTip of the Day - Accessing Web Page Content
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
从 PowerShell 3.0 开始，`Invoke-WebRequest` 命令可以轻松地下载网页内容。例如这个例子可以从 [www.powertheshell.com](http://www.powertheshell.com) 获取所有链接：

    #requires -Version 3
    
    $url = 'http://www.powertheshell.com'
    $page = Invoke-WebRequest -Uri $url 
    $page.Links

您也可以用这种方式获取原始的 HTML 内容：

    #requires -Version 3 
    
    $url = 'http://www.powertheshell.com'
    $page = Invoke-WebRequest -Uri $url 
    $page.RawContent 

当您用这种方法处理其它 URL 时，您可能偶尔会遇到弹出一个安全警告框，提示需要存储 cookie 的权限。要禁止这些对话框出现并静默执行命令，请使用 `-UseBasicParsing` 参数。

<!--more-->
本文国际来源：[Accessing Web Page Content](http://powershell.com/cs/blogs/tips/archive/2015/09/16/accessing-web-page-content.aspx)
