---
layout: post
date: 2022-03-23 00:00:00
title: "PowerShell 技能连载 - 从 Internet 下载文件"
description: PowerTip of the Day - Downloading Files from Internet
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Invoke-WebRequest` 不仅能向 web 服务发送请求。此 cmdlet 可以与远程系统通信并来回传输数据。这就是为什么您可以使用它以非常简单直接的方式从 Internet 下载文件：

```powershell
$url = 'https://www.nasa.gov/sites/default/files/thumbnails/image/iss065e009613.jpg'
$destination = "$env:temp\picture_nasa.jpg"

Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $destination


Invoke-Item -Path $destination
```

第一部分下载 NASA 图片并将其保存在本地，下一部分在您的默认查看器中打开下载的图像。

请注意，`Invoke-WebRequest` 可能不适用于较旧的网络和 TLS 协议。

这里还有两点需要注意：

* `-UseBasicParsing` 阻止 cmdlet 使用旧的和已弃用的 "Internet Explorer" 对象模型，这种方法在近期可能导致问题。使用 IE 库从网站解析原始 HTML 曾经很有用。
* `Invoke-WebRequest` 有个大哥叫 `Invoke-RestMethod`。两者的工作方式相同，但 Invoke-RestMethod 会自动将下载的数据转换为正确的格式，即 XML 或 JSON。对于此处示例中的简单二进制下载，该方法没有帮助。

<!--本文国际来源：[Downloading Files from Internet](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/downloading-files-from-internet-2)-->

