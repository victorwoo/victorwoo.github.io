---
layout: post
date: 2018-10-19 00:00:00
title: "PowerShell 技能连载 - 性能（第 3 部分）：更快的管道函数"
description: 'PowerTip of the Day - Performance (Part 3): Faster Pipeline Functions'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在之前的技能中我们演示了如何改进循环，尤其是管道操作。要将这个知识点转为函数，请看一下这个简单的管道相关的函数，它的功能是统计管道传送过来的元素数量：

```powershell
function Count-Stuff
{
    param
    (
        # pipeline-aware input parameter
        [Parameter(ValueFromPipeline)]
        $InputElement
    )

    begin
    {
        # initialize counter
        $c = 0
    }
    process
    {
        # increment counter for each incoming object
        $c++
    }
    end
    {
        # output sum
        $c
    }
}
```

当您运行这个函数来统计一个非常大数量的对象时，可能会得到这样的结果：

```powershell
PS> $start = Get-Date
1..1000000 | Count-Stuff
(Get-Date) - $start

1000000

...
TotalMilliseconds : 3895,5848
...
```

现在我们去掉属性，将这个函数转换为一个“简单函数”

```powershell
function Count-Stuff
{
    begin
    {
        # initialize counter
        $c = 0
    }
    process
    {
        # increment counter for each incoming object
        $c++
    }
    end
    {
        # output sum
        $c
    }
}
```

由于没有定义管道参数，从管道的输入在 process 块中保存在 "`$_`" 变量中；以及在 end 块中，一个名为 "`$input`" 的迭代器保存了所有收到的数据。请注意我们的计数示例并不需要这些变量，因为它只是统计了输入的数量。

以下是执行结果：

```powershell
$start = Get-Date
1..1000000 | Count-Stuff
(Get-Date) - $start

1000000

...
TotalMilliseconds : 690,1558
...
```

显然，处理大量对象的时候，简单函数比管道函数的性能要高得多。

当然，仅当用管道传输大量对象的时候效果比较明显。但当做更多复杂操作的时候，效果会更加明显。例如，以下代码创建 5 位的服务器列表，用高级函数的时候，它在我们的测试系统上大约消耗 10 秒钟：

```powershell
function Get-Servername
{
    param
    (
        # pipeline-aware input parameter
        [Parameter(ValueFromPipeline)]
        $InputElement
    )

    process
    {
        "Server{0:n5}" -f $InputElement
    }
}



$start = Get-Date
$list = 1..1000000 | Get-ServerName
(Get-Date) - $start
```

使用简单函数可以在 2 秒之内得到相同的结果（在 PowerShell 5.1 和 6.1 相同）：

```powershell
function Get-ServerName
{
    process
    {
        "Server{0:n5}" -f $InputElement
    }
}



$start = Get-Date
$list = 1..1000000 | Get-ServerName
(Get-Date) - $start
```

<!--本文国际来源：[Performance (Part 3): Faster Pipeline Functions](http://community.idera.com/powershell/powertips/b/tips/posts/performance-part-3-faster-pipeline-functions)-->
