---
layout: post
date: 2020-11-16 00:00:00
title: "PowerShell 技能连载 - Repairing PowerShell Gallery Access"
标题：“ PowerShell技能连载-修复PowerShell Gallery Access”
description: PowerTip of the Day - Repairing PowerShell Gallery Access
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
The PowerShell Gallery ([www.powershellgallery.com](http://www.powershellgallery.com/)) 是查找新的 PowerShell 命令的理想场所。借助 `Install-Module`，您可以轻松下载并安装新的 PowerShell 模块。

但是，有时候会失败，有两个主要原因。

有时，Windows 10 自带的 PowerShellGet 模块已过时。然后，您会收到有关提示缺少参数或错误参数的异常信息。

要解决此问题，您需要手动更新 PowerShellGet。使用管理员权限运行以下行：

```powershell
Install-Module -Name PowerShellGet -Repository PSGallery -Force
```

第二个常见原因：Windows 版本不支持 TLS 1.2 协议。在这种情况下，您会遇到连接问题。尝试运行以下命令：

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```

此设置适用于当前的 PowerShell 会话。如果要保留此设置，请将该行放入您的配置文件脚本中。该路径可以在 `$profile` 中找到。

<!--本文国际来源：[Repairing PowerShell Gallery Access](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/repairing-powershell-gallery-access)-->

