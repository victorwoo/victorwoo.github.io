layout: post
title: "字幕整理脚本"
description: Subtitle Optimizer
date: 2015-08-13 18:53:47
categories:
- powershell
tags:
- powershell
- text
- geek
---
从看过的电影、美剧里学英语是一件很棒的事。因为你曾经被带入过那个场景，曾经和主角一同喜怒哀乐。如果能将电影里的中英文对白整理出来，对做笔记和搜索回顾将大有帮助。

我们可以从网上（例如射手网）下载视频的中英文字幕，需要是 .srt 格式的。它实际上是一个文本文件，内容类似如下：

```text
13
00:04:42,050 --> 00:04:45,010
{\an2}{\pos(212,240)}第三季  第一集

14
00:01:56,000 --> 00:01:56,990
爸
Hey, Pop.

15
00:01:56,880 --> 00:02:04,020
{\an8}凯文·安德伍德

16
00:01:59,750 --> 00:02:01,510
好久不见啊
Been a while, hasn't it?
```

我们希望将它整理成这样的格式：

```text
第三季  第一集

爸
Hey, Pop.

凯文·安德伍德

好久不见啊
Been a while, hasn't it?
```

这个任务可以用 PowerShell + 正则表达式轻松搞定。

```powershell
if (!(Test-Path dst)) {
    md dst | Out-Null
}

Get-ChildItem src\*.srt | ForEach-Object {
    $srcFile = $_
    Write-Output "Processing $($srcFile.Name)"
    $dstFile = (Join-Path 'dst' $srcFile.BaseName) + '.txt'
    Get-Content $srcFile | ForEach-Object {
        $line = $_
        if ($line -cmatch '\A\d+\z') { return }
        if ($line -cmatch '\d\d:\d\d:\d\d,\d\d\d --> \d\d:\d\d:\d\d,\d\d\d') { return }
        $line = $line -creplace '\s*\{\\.*?\}\s*', ''
        return $line
    } | Out-File $dstFile
}
```

只需要将字幕源文件放在_src_目录下，运行脚本，就可以在_dst_目录下得到期望的文本文件。执行效果如下：

![](/img/2015-08-13-Subtitle-Optimizer-002.png)

文件目录如下：
![](/img/2015-08-13-Subtitle-Optimizer-001.png)

您也可以在这里[下载](/download/Optimize-Srt.zip)完整的脚本。
