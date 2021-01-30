---
layout: post
date: 2021-01-01 00:00:00
title: "PowerShell 技能连载 - 更好的递归"
description: PowerTip of the Day - A Better Recursion
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当函数调用自身时，称为“递归”。当脚本想要遍历文件系统的一部分时，您会经常看到这种技术：一个函数处理文件夹内容，当它遇到子文件夹时，它会调用自身。

递归的功能很强大，但是却很难调试，并且有潜在的危险。因为当您犯错时，您将陷入无休止的循环。此外，递归深度过高时，始终存在堆栈溢出的风险。

许多通常需要递归的任务也可以通过使用“队列”来设计：当您的代码遇到新任务时，无需再次调用自身，而是将新任务放在队列中，一旦完成初始任务，开始解决队列中的任务。

感谢 Lee Holmes，这是一个遍历整个驱动器 C:\ 但不使用递归的简单示例。相反，您可以看到正在使用的队列：

```powershell
# get a new queue
[System.Collections.Queue]$queue = [System.Collections.Queue]::new()
# place the initial search path(s) into the queue
$queue.Enqueue('c:\')
# add as many more search paths as you need
# they will eventually all be traversed
#$queue.Enqueue('D:\')

# while there are still elements in the queue...
    while ($queue.Count -gt 0)
    {
        # get one item off the queue
        $currentDirectory = $queue.Dequeue()
        try
        {
            # find all subfolders and add them to the queue
            # a classic recurse approach would have called itself right here
            # this approach instead pushes the future tasks just onto
            # the queue for later use
            [IO.Directory]::GetDirectories($currentDirectory) | ForEach-Object {
                $queue.Enqueue($_)
            }
        }
        catch {}

        try
        {
            # find all files in this folder with the given extensions
            [IO.Directory]::GetFiles($currentDirectory, '*.psm1')
            [IO.Directory]::GetFiles($currentDirectory, '*.ps1')
        }
        catch{}
    }
```

<!--本文国际来源：[A Better Recursion](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/a-better-recursion)-->

