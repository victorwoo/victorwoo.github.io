---
layout: post
title: "PowerShell 技能连载 - 获取 WMI 智能感知信息"
date: 2013-11-26 00:00:00
description: PowerTip of the Day - Getting WMI IntelliSense
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Get-WmiObject` 并未对 WMI 类提供智能感知信息，所以您要么事先知道 WMI 类的名字，要么使用 `-List` 参数来搜索它。

不过有一个聪明的技巧：`Get-CimInstance` 命令几乎完成相同的事情，并且它的参数 `-ClassName` 也接受一个 WMI 类名。而这个参数提供了智能感知支持。

在 PowerShell 3.0 ISE 中进行以下操作：

    PS> Get-CimInstance -ClassName Win32_ 

然后按下 `CTRL+SPACE` 键来调用智能感知。请观察状态栏提示。由于有几百个 WMI 类名，所以首次尝试的时候，智能感知在获取所有类信息的时候可能会超时。过一段时间，或者您稍微限定以下类名，它就可以正常工作了。

所以只要用 `Get-CimInstance` 来代替 `Get-WmiObject`，然后在智能感知的支持下选择类名，然后将 Cmdlet 和参数改回 `Get-WmiObject -Class` 即可。

或者，从头到尾都使用 `Get-CimInstance`。它返回基本相同价值的信息。但在缺省情况下，它使用 WSMan 协议来进行远程操作，而不是 DCOM。
 
<!--本文国际来源：[Getting WMI IntelliSense](http://community.idera.com/powershell/powertips/b/tips/posts/getting-wmi-intellisense)-->
