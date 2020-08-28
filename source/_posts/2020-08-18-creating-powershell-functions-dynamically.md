---
layout: post
date: 2020-08-18 00:00:00
title: "PowerShell 技能连载 - 动态创建 PowerShell 函数"
description: PowerTip of the Day - Creating PowerShell Functions Dynamically
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`New-Item` 可以在任何PowerShell驱动器上创建新对象，包括功能：具有所有 PowerShell 功能的驱动器。

如果需要，您可以在代码内部动态定义新功能。这些新功能将仅存在于定义它们的作用域内。要使它们成为脚本全局脚本，请添加脚本：作用域标识符。这是一个例子：

```powershell
function New-DynamicFunction
{
    # creates a new function dynamically
    $Name = 'Test-NewFunction'
    $Code = {
        "I am a new function defined dynamically."
        Write-Host -ForegroundColor Yellow 'I can do whatever you want!'
        Get-Process
    }

    # create new function in function: drive and set scope to "script:"
    $null = New-Item -Path function: -Name "script:$Name" -Value $Code
}
```

要测试效果，请运行 `New-DynamicFunction`。完成后，会有一个称为 `Test-NewFunction` 的新函数：

```powershell
# this function does not (yet) exist:
PS> Test-NewFunction
Test-NewFunction : The term 'Test-NewFunction' is not recognized as the name of a cmdlet, function, script
file, or operable program. Check the spelling of the name, or if a path was included, verify that the path
is correct and try again.

PS> New-DynamicFunction

# now the function exists:
PS> Test-NewFunction
I am a new function defined dynamically.
I can do whatever you want!

Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
-------  ------    -----      -----     ------     --  -- -----------
    219      18     3384      10276      89,52  13088   1 AppleMobileDeviceProcess
    574      35    29972      84500       3,50   8548   1 ApplicationFrameHost
    147       9     1376       5644              4472   0 armsvc
```

请注意，我们如何将新功能的代码定义为大括号中的脚本块。这不是必需的。您还可以将其定义为纯文本字符串，这可以为您提供更多灵活性来编写新函数的源代码：

```powershell
$a = "not"
$b = "AD"
$c = "EP"

# use -Force to overwrite existing functions
$null = New-Item -Force -Path function: -Name "script:Test-This" -Value @"
'Source code can be a string.'
$a$c$b
"@

Test-This
```

还要注意，除非指定 `-Force`，否则 `New-Item` 不会覆盖现有函数。

<!--本文国际来源：[Creating PowerShell Functions Dynamically](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/creating-powershell-functions-dynamically)-->

