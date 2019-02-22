---
layout: post
date: 2018-10-29 00:00:00
title: "PowerShell 技能连载 - 接受不同的参数类型"
description: PowerTip of the Day - Accepting Different Parameter Types
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
个别情况下，您可能会希望创建一个可以接受不同参数类型的函数。假设您希望用户既可以传入一个雇员姓名，也可以传入一个 Active Directory 对象。

在 PowerShell 中有一个固定的原则：变量不能在同一时刻有不同的数据类型。由于参数是变量，所以一个指定的参数只能有一个唯一的类型。

然而，您可以使用参数集来定义互斥的参数，这是一种解决多个输入类型的好方法。以下是一个既可以输入服务名，也可以输入服务对象的示例函数。这基本上是 `Get-Service` 内部的工作原理，以下示例展示了它的实现方式：

```powershell
function Get-MyService
{
  [CmdletBinding(DefaultParameterSetName="String")]
  param
  (
    [String]
    [Parameter(Mandatory,Position=0,ValueFromPipeline,ParameterSetName='String')]
    $Name,

    [Parameter(Mandatory,Position=0,ValueFromPipeline,ParameterSetName='Object')]
    [System.ServiceProcess.ServiceController]
    $Service
  )

  process
  {
    # if the user entered a string, get the real object
    if ($PSCmdlet.ParameterSetName -eq 'String')
    {
      $Service = Get-Service -Name $Name
    }
    else
    {
        # else, if the user entered (piped) the expected object in the first place,
        # you are good to go
    }

    # this call tells you which parameter set was invoked
    $PSCmdlet.ParameterSetName

    # at the end, you have an object
    $Service
  }

}
```

我们看看该函数的使用：

```powershell
PS> Get-MyService -Name spooler
String

Status   Name               DisplayName
------   ----               -----------
Running  spooler            Print Spooler



PS> $spooler = Get-Service -Name Spooler

PS> Get-MyService -Service $spooler
Object

Status   Name               DisplayName
------   ----               -----------
Running  Spooler            Print Spooler



PS> "Spooler" | Get-MyService
String

Status   Name               DisplayName
------   ----               -----------
Running  Spooler            Print Spooler



PS> $spooler | Get-MyService
Object

Status   Name               DisplayName
------   ----               -----------
Running  Spooler            Print Spooler
```

如您所见，用户可以传入一个服务名或是 Service 对象。`Get-MyService` 函数模仿 `Get-Service` 内部的实现机制，并且返回一个 Service 对象，无论输入什么类型。以下是上述函数的语法：

```powershell
**Syntax**
        Get-MyService [-Name] <string> [<CommonParameters>]
        Get-MyService [-Service] <ServiceController> [<CommonParameters>]
```

<!--本文国际来源：[Accepting Different Parameter Types](http://community.idera.com/powershell/powertips/b/tips/posts/accepting-different-parameter-types)-->
