---
layout: post
date: 2017-07-07 00:00:00
title: "PowerShell 技能连载 - 查找 PowerShell 类"
description: PowerTip of the Day - Finding PowerShell Classes
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
从 PowerShell 5 开始，您可以定义 PowerShell 类。它们是动态定义的，并且存在于内存中。那么要如何知道这些类的名字？

我们首先定义一个简单的，没有任何内容的类：

```powershell
class TestClass
{

}
```

如何确认内存中确实存在一个名为 "TestClass" 的类？以下是一个名为 `Get-PSClass` 的工具函数：

```powershell
function Get-PSClass($Name = '*')
{
    [AppDomain]::CurrentDomain.GetAssemblies() |
    Where-Object { $_.GetCustomAttributes($false) |
        Where-Object { $_ -is [System.Management.Automation.DynamicClassImplementationAssemblyAttribute]} } |
        ForEach-Object { $_.GetTypes() |
        Where-Object IsPublic |
        Where-Object { $_.Name -like $Name } |
        Select-Object -ExpandProperty Name
    }
}
```

执行这个函数后，它会返回当前内存中所有定义的 PowerShell 类（在我们的 PowerShell 例子中，在前几个技能实验中有好几个 PowerShell 类）：

```powershell
PS> Get-PSClass
HelperStuff
Employee
TestClass

PS>
```

您也可以显示地测试一个类名：

```powershell
PS> Get-PSClass -Name TestClass
TestClass

PS> (Get-PSClass -Name TestClass) -ne $null
True

PS> (Get-PSClass -Name TestClassNotExisting) -ne $null
False
```

您也可以使用通配符。一下代码将返回所有以 "A" 至 "H" 字母开头的类：

```powershell
PS> Get-PSClass -Name '[A-H]*'
HelperStuff
Employee
```

<!--本文国际来源：[Finding PowerShell Classes](http://community.idera.com/powershell/powertips/b/tips/posts/finding-powershell-classes)-->
