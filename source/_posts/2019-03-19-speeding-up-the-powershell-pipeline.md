---
layout: post
date: 2019-03-19 00:00:00
title: "PowerShell 技能连载 - 提升 PowerShell 管道的速度"
description: PowerTip of the Day - Speeding Up the PowerShell Pipeline
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当 a) 需要处理许多项目时 b) 使用 PowerShell 管道时，PowerShell 脚本可能会变得非常缓慢。今天让我们找出它的原因，以及解决的方法。

要重现这个问题，让我们先创建一个用例，体现 PowerShell 如何明显变慢。我们需要准备许多项目。这里我们用代码生成 Windows 文件夹下所有文件的列表，这需要几秒钟才能生成完。

```powershell
# get large data sets
$files = Get-ChildItem -Path c:\windows -File -Recurse -ErrorAction SilentlyContinue
$files.Count
```

我们将这些文件发送到管道，并且只挑出大于 1MB 的文件。在以下栗子中，我们将 `$file` 的内容全部发到管道，是为了有可复制的数据。实际情况中，当然不应该使用变量，而应该直接将结果输出到管道。

```powershell
Measure-Command {
    $largeFiles = $files | Where-Object { $_.Length -gt 1MB }
}
$largeFiles.Count
```

在我们的测试中，以上代码需要消耗 3-4 秒，并且产生了 3485 个“大”文件。在您的机器上结果可能不同。

`Where-Object` 实际上只是一个包含了 `If` 语句的 `ForEach-Object` 命令，那么让我们试着将 `Where-Object` 替换成 `If`：

```powershell
Measure-Command {
$largeFiles = $Files | ForEach-Object {
        if ($_.Length -gt 1MB)
        { $_ }
    }
}
$largeFiles.Count
```

结果是一样的，而时间减少到一半。

`ForEach-Object` 实际上只是一个有 `process` 块的匿名脚本块，所以接下来请试试这段代码：

```powershell
Measure-Command {
$largeFiles = $Files | & {
        process
        {
            if ($_.Length -gt 1MB)
            { $_ }
        }
    }
}
$largeFiles.Count
```

结果再次相同，但是结果从原来的 4 秒减少到大约 100 毫秒（四十分之一）。

可见，当通过管道传入数据时，PowerShell 对每个传入的对象调用绑定的参数方法，这将显著地增加时间开销。由于 `ForEach-Object` 和 `Where-Object` 使用参数，所以会激活绑定。

当您不使用内部包含 `process` 脚本块的匿名脚本块时，将忽略所有的参数绑定并显著加速 PowerShell 管道的执行速度。
z
<!--本文国际来源：[Speeding Up the PowerShell Pipeline](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/speeding-up-the-powershell-pipeline)-->

