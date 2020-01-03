---
layout: post
date: 2019-12-20 00:00:00
title: "PowerShell 技能连载 - 退出 PowerShell 管道（第 2 部分：手动退出）"
description: 'PowerTip of the Day - Aborting the PowerShell Pipeline (Part 2: Manual Abort)'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们学到了如何当达到一定次数的时候退出 PowerShell 管道，这样可以节约很多时间：

```powershell
$fileToSearch = 'ngen.log'
Get-ChildItem -Path c:\Windows -Recurse -ErrorAction SilentlyContinue -Filter $fileToSearch |
Select-Object -First 1
```

显然，当一定数量的结果传递给 `Select-Object` 之后，`Select-Object` 会发送秘密的信息到上一级管道的 cmdlet，告知它们停止。实际上，`Select-Object` 会抛出一个特殊的异常，PowerShell 会处理这个异常，才产生这个魔术的效果。

但是如果事先不知道确切的结果数量呢？如果您希望在其它情况下中断管道呢？如果您希望实现某种超时呢？要手动退出一个管道，只需要让 `Select-Object` 发出这个特殊的异常。以下是一个专门做这件事的 `Stop-Pipeline` 函数：

```powershell
function Stop-Pipeline
{
    $pipeline = { Select-Object -First 1 }.GetSteppablePipeline()
    $pipeline.Begin($true)
    $pipeline.Process(1)
    $pipeline.End()
}
```

它调用了一个 `Select-Object` 并且模仿在管道中执行。它是通过 `GetSteppablePipeline()` 实现的。您现在可以通过 `Process()` 人工传递数据给 `Select-Object`。由于通过 `-First 1` 参数执行 `Select-Object` 命令，所以当传递任何数据给 `Select-Object`，都会产生该特殊的异常。

您现在获得了控制权，并且可以通过任何条件来调用 `Stop-Pipeline`。以下示例程序将搜索文件并且在最长 2 秒之内退出管道：

```powershell
function Stop-Pipeline
{
    $pipeline = { Select-Object -First 1 }.GetSteppablePipeline()
    $pipeline.Begin($true)
    $pipeline.Process(1)
    $pipeline.End()
}

# abort pipeline after 2000 milliseconds
$timeout = 2000
# create a stopwatch
$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

Get-ChildItem -Path c:\Windows -Recurse -ErrorAction SilentlyContinue |
  ForEach-Object {
    if ($stopwatch.ElapsedMilliseconds -gt $timeout)
    {
      $stopwatch.Stop()
      Write-Warning "Timeout, Pipeline Aborted."
      # abort pipeline
      Stop-Pipeline
    }

    # return the original object
    $_
  }
```

<!--本文国际来源：[Aborting the PowerShell Pipeline (Part 2: Manual Abort)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/aborting-the-powershell-pipeline-part-2-manual-abort)-->

