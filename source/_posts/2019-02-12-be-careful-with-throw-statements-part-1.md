---
layout: post
date: 2019-02-12 00:00:00
title: "PowerShell 技能连载 - 小心“Throw”语句（第 1 部分）"
description: "PowerTip of the Day - Be Careful With “Throw” Statements (Part 1)"
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
`throw` 是一个 PowerShell 语句，会抛出一个异常到调用者，并退出代码。至少理论上是这样。实际中，`throw` 可能不会退出代码，而且结果可能是毁灭性的。

要理解这个问题，请查看这个演示函数：

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
```

当您运行 `Copy-Log` 时，它模拟了一个失败情况，假设一个目标路径不存在。当目标路径不存在时，不能复制日志文件。如果日志文件没有复制，那么不能删除它们。这是为什么调用 throw 时代码需要退出得原因。而且它确实有效：

```powershell
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

PS> 
```

然而，这是基于 `$ErrorActionPreference` 为缺省值 "Continue" 时的行为。当一个用户恰好将它改为 "SilentlyContinue" 来禁止错误信息时，throw 会被彻底忽略，而且所有代码将会执行：

```powershell
PS> $ErrorActionPreference = 'SilentlyContinue'

PS> Copy-Log
Doing prerequisites
Testing whether target path exists
If target path does not exist, bail out
Copy log files to target path
Delete log files in original location
```

在这个场景中，您可能会丢失所有日志文件，因为复制操作没有生效，而代码继续执行并删除了原始文件。

重要的知识点：

* 如果退出函数对您来说很重要，`throw` 可能并不会真正地退出函数。您可能需要用其他方法来退出代码，例如 `return` 语句。

<!--more-->
本文国际来源：[Be Careful With “Throw” Statements (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/be-careful-with-throw-statements-part-1)
