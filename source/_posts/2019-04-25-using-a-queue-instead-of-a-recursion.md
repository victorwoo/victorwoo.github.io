---
layout: post
date: 2019-04-25 00:00:00
title: "PowerShell 技能连载 - 用队列代替嵌套"
description: PowerTip of the Day - Using a Queue instead of a Recursion
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
与其使用递归函数，您可能会希望使用一个 `Queue` 对象，这样在加载新的任务时可以卸载已处理的数据。

Lee Homes 最近贴出了以下示例，它不使用递归调用的方式而搜索了整个文件系统的文件夹树：

```powershell
# create a new queue
$dirs = [System.Collections.Queue]::new()

# add an initial path to the queue
# any folder path in the queue will later be processed
$dirs.Enqueue('c:\windows')

# process all elements on the queue until all are taken
While ($current = $dirs.Dequeue())
{
    # find subfolders of current folder, and if present,
    # add them all to the queue
    try
    {
        foreach ($_ in [IO.Directory]::GetDirectories($current))
        {
                $dirs.Enqueue($_)
        }
    } catch {}

    try
    {
        # find all files in the folder currently processed
        [IO.Directory]::GetFiles($current, "*.exe")
        [IO.Directory]::GetFiles($current, "*.ps1")
    } catch { }
}
```

`try-catch` 语句块是必要的，因为当没有文件或文件夹权限时，.NET 方法会抛出异常。

<!--本文国际来源：[Using a Queue instead of a Recursion](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-a-queue-instead-of-a-recursion)-->

