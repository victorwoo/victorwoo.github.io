---
layout: post
date: 2020-11-30 00:00:00
title: "PowerShell 技能连载 - 恒定函数"
description: PowerTip of the Day - Constant Functions
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell中，您可以对函数进行写保护。当您这样做时，将无法在运行的 PowerShell 会话期间更改、覆盖或删除函数。尽管可能没有明显的作用。该方法如下：

```powershell
$code =
{
    param
    (
        [string]
        [Parameter(Mandatory)]
        $SomeParameter
    )

    "I have received $SomeParameter and could now process it..."
}

$null = New-Item -Path function:Invoke-Something -Options Constant,AllScope -Value $code

# run the function like this
Invoke-Something -SomeParameter "My Data"
```

由于该函数现在是恒定的，因此尝试重新定义它将会失败：

```powershell
# you can no longer overwrite the function
# the following code raises an exception now
function Invoke-Something
{
    # some new code
}
```

取消该效果的唯一方法是重新启动 PowerShell 会话。恒定变量是一个更有用的方案：通过将重要数据存储在写保护变量中，可以确保它们不会因意外或有意更改。此行定义了一个写保护变量 `$testserver1`，其中包含一些内容：

```powershell
Set-Variable -Name testserver1 -Value server1 -Option Constant, AllScope
```

<!--本文国际来源：[Constant Functions](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/constant-functions)-->

