layout: post
date: 2014-12-02 12:00:00
title: "PowerShell 技能连载 - 配置 PowerShell 的步骤（第 1 部分）"
description: PowerTip of the Day - Steps to Configure PowerShell (Part 1)
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
_适用于 PowerShell 2.0 及以上版本_

如果您在家中或其它不重要的场合使用 PowerShell，那么可以通过以下步骤使 PowerShell 发挥最大功能。

您可以通过以下代码查看正在使用的 PowerShell 版本：

```
PS> $PSVersionTable.PSVersion.Major

4
```

如果版本号小于 4，请审查一下为什么使用过期的版本，是不是可以升级了。

要启用脚本执行功能，请运行以下代码：

```
PS> Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
```

您现在可以自由地执行任意位置的脚本了。如果您是初学者并且希望得到更多的安全保障，请将“`Bypass`”改为“`RemoteSigned`”。这将防止您运行下载自 Internet 或电子邮件附件的脚本。它也将防止您运行您拥有的域之外的脚本。

<!--more-->
本文国际来源：[Steps to Configure PowerShell (Part 1)](http://powershell.com/cs/blogs/tips/archive/2014/12/02/steps-to-configure-powershell-part-1.aspx)
