---
layout: post
date: 2018-02-07 00:00:00
title: "PowerShell 技能连载 - 用管道传递文件和文件夹"
description: PowerTip of the Day - Piping Files and Folders
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
假设您想创建一个函数，接受一个文件路径参数。文件可以进行许多操作。您可能希望拷贝文件，压缩文件，将它们设置为隐藏文件，或其它各种操作。我们在这里并不关注具体需要做什么操作。我们希望关注 PowerShell 函数如何接受文件参数。

您应该遇到过这样的函数：

```powershell
function Process-File
{
    param
    (
        $Path
    )

    # do something with the file
    $file = Get-Item -Path $Path
    'File {0} is of size {1} bytes.' -f $file.FullName, $file.Length
}

Process-File -Path C:\windows\explorer.exe
```

结果看起来类似这样：

```powershell
PS> Process-File -Path C:\windows\explorer.exe

File C:\windows\explorer.exe is of size 3903784 bytes.

PS>
```

这个函数每次只处理一个路径。如果希望传入多个路径，您需要这样做：

```powershell
function Process-File
{
    param
    (
        [string[]]
        $Path
    )

    foreach($SinglePath in $Path)
    {
        # do something with the file
        $file = Get-Item -Path $SinglePath
        'File {0} is of size {1} bytes.' -f $file.FullName, $file.Length
    }
}

Process-File -Path C:\windows\explorer.exe, C:\windows\notepad.exe
```

现在，您的函数可以接受任意多个逗号分隔的路径。如果您希望也能从管道输入路径呢？需要增加这些代码：

```powershell
function Process-File
{
    param
    (
        [Parameter(ValueFromPipeline)]
        [string[]]
        $Path
    )

    process
    {
        foreach($SinglePath in $Path)
        {
            # do something with the file
            $file = Get-Item -Path $SinglePath
            'File {0} is of size {1} bytes.' -f $file.FullName, $file.Length
        }
    }
}

Process-File -Path C:\windows\explorer.exe, C:\windows\notepad.exe
'C:\windows\explorer.exe', 'C:\windows\notepad.exe' | Process-File
```

基本上，您现在有两个嵌套的循环：`process {}` 是管道对象使用的循环，而其中的 `foreach` 循环处理用户传入的的字符串数组。

如果您希望 `Get-ChildItem` 提供路径给函数呢？它并不是返回字符串。它返回的是文件系统对象，而且在对象之内，有一个名为 "FullName" 的属性，存储对象的路径。以下是您要做的：

```powershell
function Process-File
{
    param
    (
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string[]]
        [Alias("FullName")]
        $Path
    )

    process
    {
        foreach($SinglePath in $Path)
        {
            # do something with the file
            $file = Get-Item -Path $SinglePath
            'File {0} is of size {1} bytes.' -f $file.FullName, $file.Length
        }
    }
}

Process-File -Path C:\windows\explorer.exe, C:\windows\notepad.exe
'C:\windows\explorer.exe', 'C:\windows\notepad.exe' | Process-File
Get-ChildItem -Path c:\windows -Filter *.exe | Process-File
```

现在，这个函数不止能接受管道传来的字符串 (ValueFromPipeline)，而且还能接受有某个属性名或别名与参数 (Path) 相似的对象 (ValueFromPipelineByPropertyName)。任务完成了。您的函数现在能够为用户提供最大的灵活性，这基本上也是 cmdlet 所做的事。

<!--more-->
本文国际来源：[Piping Files and Folders](http://community.idera.com/powershell/powertips/b/tips/posts/piping-files-and-folders)
