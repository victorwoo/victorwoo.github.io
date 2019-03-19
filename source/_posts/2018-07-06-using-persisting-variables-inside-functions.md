---
layout: post
date: 2018-07-06 00:00:00
title: "PowerShell 技能连载 - 在函数内使用持久变量"
description: PowerTip of the Day - Using persisting variables inside functions
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
默认情况下，当一个 PowerShell 函数退出时，它将“忘记”所有的内部变量。然而，有一种办法可以创建持久的内部变量。以下是实现方法：

```powershell
# create a script block with internal variables
# that will persist
$c = & {
    # define an internal variable that will
    # PERSIST and keep its value even though
    # the function exits
    $a = 0

    {
        # use the internal variable
        $script:a++
        "You called me $a times!"
    }.GetNewClosure()
}
```

这段代码创建一个包含内部变量的脚本块。当您多次运行这个脚本块时，计数器会累加：

```powershell
PS> & $c
You called me 1 times!

PS> & $c
You called me 2 times!

PS> & $c
You called me 3 times!
```

然而，脚本内的 `$a` 变量的作用域既不是 `global` 也不是 `scriptglobal`。它的作用域只在脚本块的内部：

```powershell
PS> $a
```

要将脚本块转换为函数，请加上这段代码：

```powershell
PS> Set-Item -Path function:Test-Function -Value $c

PS> Test-Function
You called me 5 times!

PS> Test-Function
You called me 6 times!
```

<!--本文国际来源：[Using persisting variables inside functions](http://community.idera.com/powershell/powertips/b/tips/posts/using-persisting-variables-inside-functions)-->
