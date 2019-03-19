---
layout: post
date: 2018-10-08 00:00:00
title: "PowerShell 技能连载 - 自动化操作网站"
description: "PowerTip of the Day - Automating “Live” Websites"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有些时候，需要自动化操作某些已经人工打开的网站。也许您需要先用 WEB 表单登录到内部的网页。假设网站是通过 Internet Explorer 加载的（不是 Edge 或任何第三方浏览器），您可以使用 COM 接口来访问浏览器的实时内容。

当您访问动态网页时，纯 HTML 元素可能会更有用。一个纯 `WebClient`（或是 `Invoke-WebRequest` cmdlet）只会返回静态 HTML，并不是用户在浏览器中看到的内容。当使用一个真实的浏览器显示网页内容时，您的脚本需要访问驱动显示内容的完整 HTML。

要测试这一点，请打开 Internet Explorer 或者 Edge，并浏览到需要的网站。在我们的例子中，我们导航到 [www.powershellmagazine.com](http://www.powershellmagazine.com/)。

```powershell
$obj = New-Object -ComObject Shell.Application
$browser = $obj.Windows() |
    Where-Object FullName -like '*iexplore.exe' |
    # adjust the below to match your URL
    Where-Object LocationUrl -like '*powershellmagazine.com*' |
    # take the first browser that matches in case there are
    # more than one
    Select-Object -First 1
```

在 `$browser` 中，您可以访问打开的浏览器中的对象模型。如果 `$browser` 为空，请确保您调整了 `LocationUrl` 的过滤条件。不要忘了两端的星号。

如果您希望挖掘网页中的所有图片，以下是获取所有图片列表的方法：

```powershell
$browser.Document.images | Out-GridView
```

类似地，如果您希望挖掘网页的内容信息，以下代码返回页面的 HTML：

```powershell
PS> $browser.Document.building.innerHTML
```

您可以使用正则表达式来挖掘内容。不过有一个限制：如果您需要以已登录的 WEB 用户的上下文来进行额外的操作，那么别指望了。例如，如果您需要下载一个需要登录才能获取的文件，那么您需要通过对象模型调用 Internet Explorer 的下载操作。

您可能无法通过 Invoke-WebRequest 或是其它简单的 WEB 客户端来下载文件，因为 PowerShell 运行在它自己的上下文中。而对于网站而言，看到的是一个匿名访问者。

使用 Internet Explorer 对象模型来进行更多高级操作，例如下载文件或视频，并不是完全不可行。但基本上是十分复杂的，您需要向用户界面发送点击和按键动作。

<!--本文国际来源：[Automating “Live” Websites](http://community.idera.com/powershell/powertips/b/tips/posts/automating-live-websites)-->
