---
layout: post
date: 2015-01-02 12:00:00
title: "PowerShell 技能连载 - 不通过 ProgID 操作 COM 对象"
description: PowerTip of the Day - Accessing COM Objects without ProgID
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
_适用于 PowerShell 所有版本_

通常在操作 COM 对象时，它们需要将自身在注册表中注册，并且 PowerShell 需要注册的 ProgID 字符串来加载对象。

以下是一个例子：

    $object = New-Object -ComObject Scripting.FileSystemObject
    $object.Drives 

若不使用 `New-Object` 命令，您也可以用 .NET 方法来实现相同的目的：

    $type = [Type]::GetTypeFromProgID('Scripting.FileSystemObject')
    $object = [Activator]::CreateInstance($type)
    $object.Drives 

采用后一种方法，您甚至可以实例化一个未暴露 ProgID 的 COM 对象。您所需的只是 GUID：

    $clsid = New-Object Guid '0D43FE01-F093-11CF-8940-00A0C9054228'
    $type = [Type]::GetTypeFromCLSID($clsid)
    $object = [Activator]::CreateInstance($type)
    $object.Drives

<!--more-->
本文国际来源：[Accessing COM Objects without ProgID](http://community.idera.com/powershell/powertips/b/tips/posts/accessing-com-objects-without-progid)
