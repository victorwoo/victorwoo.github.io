---
layout: post
date: 2016-11-07 00:00:00
title: "PowerShell 技能连载 - 获取PowerShell Gallery 模块的最新版本"
description: PowerTip of the Day - Getting Latest PowerShell Gallery Module Version
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 [www.powershellgallery.com](http://www.powershellgallery.com) ，Microsoft 发布了一个公开的脚本和模块的仓库。您可以在这里和其他人交流 PowerShell 代码（请见网站）。

要使用这个仓库，您需要 PowerShell 5 或者手动安装 PowerShellGet 模块（在 powershellgallery.com 可以下载到）。接下来您可以使用诸如 Find/Save/Install/Update/Remove-Script/Module 等 cmdlet。

目前缺乏的是一个查看模块当前最新版本号的方法。以下是解决方案：

```powershell
function Get-PublishedModuleVersion($Name)
{
   # access the main module page, and add a random number to trick proxies
   $url = "https://www.powershellgallery.com/packages/$Name/?dummy=$(Get-Random)"
   $request = [System.Net.WebRequest]::Create($url)
   # do not allow to redirect. The result is a "MovedPermanently"
   $request.AllowAutoRedirect=$false
   try
   {
     # send the request
     $response = $request.GetResponse()
     # get back the URL of the true destination page, and split off the version
     $response.GetResponseHeader("Location").Split("/")[-1] -as [Version]
     # make sure to clean up
     $response.Close()
     $response.Dispose()
   }
   catch
   {
     Write-Warning $_.Exception.Message
   }
}

Get-PublishedModuleVersion -Name ISESteroids
```

当您运行 `Get-PublishedModuleVersion` 并传入发布的模块名，执行结果类似如下：

    PS C:\> Get-PublishedModuleVersion -Name ISESteroids

    Major  Minor  Build  Revision
    -----  -----  -----  --------
    2      6      3      25

这个操作非常非常快，而且可以用来检测已安装的模块，看它们是否是最新版本。

<!--本文国际来源：[Getting Latest PowerShell Gallery Module Version](http://community.idera.com/powershell/powertips/b/tips/posts/getting-latest-powershell-gallery-module-version)-->
