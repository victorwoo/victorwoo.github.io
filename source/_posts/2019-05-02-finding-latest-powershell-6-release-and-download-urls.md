---
layout: post
date: 2019-05-02 00:00:00
title: "PowerShell 技能连载 - 查找最新的 PowerShell 6 发行信息（以及下载地址）"
description: PowerTip of the Day - Finding Latest PowerShell 6 Release (and Download URLs)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 6 是开源的并且在 GitHub 上维护了一个公共的仓库。在仓库中频繁发行新版本。

如果您不希望深入到 GitHub 的前端来获取最新版 PowerShell 6 发行的下载地址，那么可以采用这个 PowerShell 的方法：

```powershell
$AllProtocols = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[Net.ServicePointManager]::SecurityProtocol = $AllProtocols

# get all releases
Invoke-RestMethod -Uri https://github.com/PowerShell/PowerShell/releases.atom -UseBasicParsing |
    # sort in descending order
    Sort-Object -Property Updated -Descending |
    # pick the first (newest) release and get a link
    Select-Object -ExpandProperty Link -First 1 |
    # pick a URL
    Select-Object -ExpandProperty HRef
```

（请注意只有在 Windows 10 1803 之前才需要显式启用 SSL。）

这将货渠道最新的 PowerShell 发行页面的 URL。在页面中，您可以获取到不同平台的下载地址。

不过，还有一个更简单的方法：访问 [https://github.com/PowerShell/PowerShell/releases/latest](https://github.com/PowerShell/PowerShell/releases/latest)

然而，这并不能提供 URL 和标签信息。而只是被跳转到一个对应的 URL。

以下是两者的混合：使用最新发行版的快捷方式，但是不允许跳转。通过这种方式，PowerShell 将返回完整的 URL：

```powershell
$AllProtocols = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[Net.ServicePointManager]::SecurityProtocol = $AllProtocols


# add a random number to the URL to trick proxies
$url = "https://github.com/PowerShell/PowerShell/releases/latest?dummy=$(Get-Random)"

$request = [System.Net.WebRequest]::Create($url)
# do not allow to redirect. The result is a "MovedPermanently"
$request.AllowAutoRedirect=$false
# send the request
$response = $request.GetResponse()
# get back the URL of the true destination page, and split off the version
$realURL = $response.GetResponseHeader("Location")
# make sure to clean up
$response.Close()
$response.Dispose()

$realURL
```

<!--本文国际来源：[Finding Latest PowerShell 6 Release (and Download URLs)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/finding-latest-powershell-6-release-and-download-urls)-->

