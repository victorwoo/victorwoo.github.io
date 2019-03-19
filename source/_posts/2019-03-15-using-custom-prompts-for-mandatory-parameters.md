---
layout: post
date: 2019-03-15 00:00:00
title: "PowerShell 技能连载 - 对必选参数使用自定义提示"
description: PowerTip of the Day - Using Custom Prompts for Mandatory Parameters
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您在 PowerShell 定义了必选参数，那么当用户没有传入这个参数时将会收到提示。如您所见，当您运行这段代码时，该提示只使用了参数的名字：

```powershell
param
(
  [Parameter(Mandatory)]
  [string]
  $UserName

)

"You entered $Username"



UserName: tobi
You entered tobi
```

To get more descriptive prompts, you can use more explicit variable names:
要获得描述的更具体的提示，您需要使用更明确的变量名：

```powershell
param
(
  [Parameter(Mandatory)]
  [string]
  ${Please provide a user name}

)

$username = ${Please provide a user name}
"You entered $Username"



Please provide a user name: tobi
You entered tobi
```

只需要在一个函数中使用 `param()` 块就可以将函数转为命令：

```powershell
function New-CorporateUser
{
    param
    (
      [Parameter(Mandatory)]
      [string]
      ${Please provide a user name}
    )

    $username = ${Please provide a user name}
    "You entered $Username"
}



PS C:\> New-CorporateUser
Cmdlet New-CorporateUser at command pipeline position 1
Supply values for the following parameters:
Please provide a user name: Tobi
You entered Tobi
```

它的副作用是参数名中含有空格和特殊字符，将使它无法通过命令行指定值，因为参数无法用双引号包起来：

```powershell
PS C:\> New-CorporateUser -Please  provide a user name
```

<!--本文国际来源：[Using Custom Prompts for Mandatory Parameters](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-custom-prompts-for-mandatory-parameters)-->

