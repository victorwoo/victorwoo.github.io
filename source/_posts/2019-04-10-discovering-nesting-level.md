---
layout: post
date: 2019-04-10 00:00:00
title: "PowerShell 技能连载 - 发现嵌套层数"
description: PowerTip of the Day - Discovering Nesting Level
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Get-PSCallStack` 返回所谓的“调用堆栈”——它最基本的功能是告诉您代码的嵌套深度：每次进入一个脚本块，就将向堆栈加入一个新的对象。让我们看一看：

```powershell
function test1
{
    $callstack = Get-PSCallStack
    $nestLevel = $callstack.Count - 1
    "TEST1: Nest Level: $nestLevel"
    test2
}

function test2
{
    $callstack = Get-PSCallStack
    $nestLevel = $callstack.Count - 1
    "TEST2: Nest Level: $nestLevel"
}

# calls test1 which in turn calls test2
test1
# calls test2 directly
test2
```

在这个例子中，您会看到两个函数。它们使用 `Get-PSCallStack` 来确定它们的“嵌套深度”。当运行 `test1` 时，它内部调用 `test2`，所以 `test2` 的嵌套深度为 2。而当您直接调用 `test2`，它的嵌套深度为 1:

    TEST1: Nest Level: 1
    TEST2: Nest Level: 2
    TEST2: Nest Level: 1

还有一个使用相同技术的，更有用的示例：一个递归的函数调用，当嵌套深度为 10 层时停止递归：

```powershell
function testRecursion
{
    $callstack = Get-PSCallStack
    $nestLevel = $callstack.Count - 1
    "TEST3: Nest Level: $nestLevel"

    # function calls itself if nest level is below 10
    if ($nestLevel -lt 10) { testRecursion }

}

# call the function
testRecursion
```

以下是执行结果：

    TEST3: Nest Level: 1
    TEST3: Nest Level: 2
    TEST3: Nest Level: 3
    TEST3: Nest Level: 4
    TEST3: Nest Level: 5
    TEST3: Nest Level: 6
    TEST3: Nest Level: 7
    TEST3: Nest Level: 8
    TEST3: Nest Level: 9
    TEST3: Nest Level: 10

<!--本文国际来源：[Discovering Nesting Level](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/discovering-nesting-level)-->

