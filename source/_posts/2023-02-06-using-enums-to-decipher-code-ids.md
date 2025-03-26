---
layout: post
date: 2023-02-06 06:00:18
title: "PowerShell 技能连载 - 使用枚举来解析序号"
description: PowerTip of the Day - Using Enums to Decipher Code IDs
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
WMI 是一个简单的获取计算机信息的方法。例如要确定您所使用的计算机类型，是一件很容易的事：

```powershell
$info = (Get-CimInstance -ClassName win32_computersystem).PCSystemType
$info
```

不幸的是，WMI 属性往往返回的是幻数而不是友好的文本，所以当您在笔记本电脑上运行以上代码，将得到结果 "2"。如果返回其它结果，还需要上 google 搜索该数字的含义。

一旦你获得了代码，在 PowerShell 中就有一种简单而有效的方法可以使用枚举将数字转换为友好的文本：

```powershell
enum ServerTypes
{
    Unspecified
    Desktop
    Mobile
    Workstation
    EnterpriseServer
    SOHOServer
    AppliancePC
    PerformanceServer
    Maximum
}

[ServerTypes]$info = (Get-CimInstance -ClassName win32_computersystem).PCSystemType
$info
```

枚举将友好的文本与代码号绑定，默认情况下以 0 开头。上面的枚举将 "Unspecified" 绑定为代码 0，"Mobile" 绑定为代码 2。

By assigning the enum type [ServerTypes] to your result variable, all translating is performed automatically, and cryptic code numbers now show as friendly text.
通过将枚举类型 `[ServerTypes]` 绑定到您的结果变量，所有转换都会自动进行，而且现在幻数可以转换为友好的文本。

由于 ID 数字在不断变化，因此可能会遇到新的代码，所以必须扩展枚举。
<!--本文国际来源：[Using Enums to Decipher Code IDs](https://blog.idera.com/database-tools/powershell/powertips/using-enums-to-decipher-code-ids/)-->

