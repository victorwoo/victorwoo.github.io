---
layout: post
date: 2017-03-24 00:00:00
title: "PowerShell 技能连载 - 使用 PowerShell 参数验证器"
description: PowerTip of the Day - Using a PowerShell Parameter Validator
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
PowerShell 的函数参数支持 `ValidateScript` 属性，可以关联到一段 PowerShell 代码。当该参数接收到一个值时，该代码将会被调用，并且返回 `$true` 或 `$false`。如果该代码返回 `$false` 则该参数被拒绝。

以下是一个仅接受 Windows 文件夹中存在的文件的文件名的例子：

```powershell
function Get-File
{
    param
    (
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -Path "$env:windir\$_" })]
        [string]
        $File
    )

    "$File exists in your Windows folder."
}
```

以下是使用效果：

```powershell
PS C:\> Get-File  -File explorer.exe
explorer.exe exists  in your Windows folder.

PS C:\> Get-File  -File something.exe
Get-File : Cannot validate argument on parameter  'File'. The " Test-Path -Path "$env:windir\$_" " validation  script for the argument with value "something.exe" did not return a  result of True. Determine why the validation script failed, and then try the  command again.
At line:1 char:16
+ Get-File -File something.exe
+                 ~~~~~~~~~~~~~
    +  CategoryInfo          : InvalidData: (:)  [Get-File], ParameterBindingValidationException
    +  FullyQualifiedErrorId : ParameterArgumentValidationError,Get-File

PS C:\> Get-File  -File memory.dmp
memory.dmp exists in  your Windows folder.
```

<!--more-->
本文国际来源：[Using a PowerShell Parameter Validator](http://community.idera.com/powershell/powertips/b/tips/posts/using-a-powershell-parameter-validator)
