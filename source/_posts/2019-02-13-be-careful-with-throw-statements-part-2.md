---
layout: post
date: 2019-02-13 00:00:00
title: "PowerShell 技能连载 - 小心“Throw”语句（第 2 部分）"
description: "PowerTip of the Day - Be Careful With “Throw” Statements (Part 2)"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们解释了将 `$ErrorActionPreference` 设为 "SilentlyContinue" 将如何影响 throw 语句，而且该 throw 将不会正常地退出函数代码。以下还是我们使用过的例子：

```powershell
function Copy-Log
{
    "Doing prerequisites"
    "Testing whether target path exists"
    "If target path does not exist, bail out"
    throw "Target path does not exist"
    "Copy log files to target path"
    "Delete log files in original location"
}


    
PS> Copy-Log
Doing prerequisites
Testing whether target path exists
If target path does not exist, bail out
Target path does not exist
In Zeile:8 Zeichen:3
+   throw "Target path does not exist"
+   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (Target path does not exist:String) [], RuntimeExceptio 
    n
    + FullyQualifiedErrorId : Target path does not exist


PS> $ErrorActionPreference = 'SilentlyContinue'

PS> Copy-Log
Doing prerequisites
Testing whether target path exists
If target path does not exist, bail out
Copy log files to target path
Delete log files in original location
```

虽然 `ErrorAction` 为默认值时，throw 语句能够退出函数，但是当 `ErrorAction` 设为 "SilentlyContinue" 时代码将继续执行。这很可能是一个 bug，因为 `ErrorAction` 的值设为 "Continue" 和 "SilentlyContinue" 的唯一区别只应该是错误信息可见与否。这些设置不应该影响实际执行的代码。

这个 throw 中的 bug 只发生在 throw 抛出的终止错误没有被处理的时候。当您使用 try..catch 语句或者甚至添加一个简单的（完全为空的）`trap` 语句时，一切都正确了，throw 能够像预期地工作了：

```powershell
# add a trap to fix
trap {}

$ErrorActionPreference = "SilentlyContinue"
Copy-Log
$ErrorActionPreference = "Continue"
Copy-Log 
```

一旦添加了捕获语句，这段代码将会在 throw 语句处跳出，无论 `$ErrorActionPreference` 的设置为什么。您可以在 PowerShell 用户设置脚本中添加一个空白的捕获语句来防止这个 bug，或者重新考虑是否使用 throw 语句。

重要的知识点：

* `throw` 是错误处理系统的一部分，通过 throw 抛出的异常需要用 `try..catch` 或者 `trap` 语句。如果异常没有捕获，`throw` 的工作方式可能和预期的不一致。
* 因为存在这个问题，所以对于暴露给最终用户的函数，不要用 `throw` 来退出函数代码。对于最终用户，与其抛出一个（丑陋的）异常，还不如用 `Write-Warning` 或 `Write-Host` 抛出一条对人类友好的错误信息，然后用 `return` 语句友好地退出代码。
* 如果您必须抛出一个异常，以便调用者能够在他们的错误处理器中捕获它，但也需要确保无论 `$ErrorActionPreference` 为何值都能可靠地退出代码，请使用 `Write-Error` 和 `return` 语句的组合：

```powershell
function Copy-Log
{
    "Doing prerequisites"
    "Testing whether target path exists"
    "If target path does not exist, bail out"
    Write-Error "Target path does not exist"; return
    "Copy log files to target path"
    "Delete log files in original location"
}
```

由于 `return` 语句不受 `$ErrorActionPreference` 的影响，您的代码总是能够退出。让我们做个测试：

```powershell     
PS> Copy-Log
Doing prerequisites
Testing whether target path exists
If target path does not exist, bail out
Copy-Log : Target path does not exist
In Zeile:1 Zeichen:1
+ Copy-Log
+ ~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [Write-Error], WriteErrorException
    + FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException,Copy-Log  
```

如果将 `$ErrorActionPreference` 设为 SilentlyContinue，错误信息和预期一致地被屏蔽了，但是代码确实退出了：

```powershell
PS> $ErrorActionPreference = 'SilentlyContinue'

PS> Copy-Log
Doing prerequisites
Testing whether target path exists
If target path does not exist, bail out
```

<!--本文国际来源：[Be Careful With “Throw” Statements (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/be-careful-with-throw-statements-part-2)-->
