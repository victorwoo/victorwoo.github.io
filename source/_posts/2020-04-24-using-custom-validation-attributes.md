---
layout: post
date: 2020-04-24 00:00:00
title: "PowerShell 技能连载 - 使用自定义的验证器属性"
description: PowerTip of the Day - Using Custom Validation Attributes
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
从 PowerShell 5开始，您可以创建自己的属性，即自定义验证程序。它们可以应用于变量（和参数），并且一旦分配的值与验证程序不匹配，就会引发异常。

这是一个路径验证器的示例。将其应用于变量时，只能将有效文件路径应用于该变量：

```powershell
class ValidatePathExistsAttribute : System.Management.Automation.ValidateArgumentsAttribute
{
    # the value to be checked surfaces in $path and must be of type [object]
    [void]Validate([object]$path, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics)
    {
        # if anything is wrong with the value, throw an exception
        if([string]::IsNullOrWhiteSpace($path))
        {
            Throw [System.ArgumentNullException]::new()
        }
        if(-not (Test-Path -Path $path))
        {
            Throw [System.IO.FileNotFoundException]::new()
        }

        # if NO exception was thrown, the value is accepted
    }
}
#endregion


[ValidatePathExists()][string]$Path = "c:\windows"
$Path = "c:\test123"
```

当您分配不存在的路径时，PowerShell都将*不*分配它，而是保留现有值。

<!--本文国际来源：[Using Custom Validation Attributes](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-custom-validation-attributes)-->

