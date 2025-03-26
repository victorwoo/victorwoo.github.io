---
layout: post
date: 2022-07-29 00:00:00
title: "PowerShell 技能连载 - 将语言 ID 转为语言名称"
description: PowerTip of the Day - Converting Language IDs in Language Names
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在我们以前的迷你系列中，我们展示了使用不同的 PowerShell 方法来获取安装 OS 语言名称的几种方法。结果都是语言 ID 的列表，类似这样：

    de-DE
    en-US
    fr-FR

如果我需要将它们转换为完整的国家名称怎么办？幸运的是，这只是数据类型的问题。我们演示的所有方法都可以以字符串的形式返回安装的语言包。让我们以 WMI 示例为例：

```powershell
$os = Get-CIMInstance -ClassName Win32_OperatingSystem
$os.MUILanguages
```

当您将结果转换到更合适的数据类型时，将获得合适的数据。相对于字符串，让我们使用表示国家名称的数据类型：`CultureInfo`！

```powershell
$os = Get-CIMInstance -ClassName Win32_OperatingSystem
[CultureInfo[]]$os.MUILanguages
```

瞬间，相同的数据现在可以以更丰富的格式表示：

    LCID             Name             DisplayName
    ----             ----             -----------
    1031             de-DE            German (Germany)
    1033             en-US            English (United States)
    1036             fr-FR            French (France)

<!--本文国际来源：[Converting Language IDs in Language Names](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/converting-language-ids-in-language-names)-->
