---
layout: post
title: 如何用 PowerShell 撰写心灵鸡汤
date: 2015-02-08 22:10:11
description: "How to Encourage"
categories: [powershell]
tags:
- powershell
- text
---
关于励志段子
------------
微信上传着一个励志段子，大意是：

如果26个英文字母 A B C D EF G H I J K L M N O P Q R S T U V W X Y Z 分别等于:
1 2 3 4 5 6 7 8 9 10 11 12 13 14 1516 17 18 19 20 21 22 23 24 25 26。那么：

- Knowledge (知识)： K+N+O+W+L+E+D+G+E＝ 11+14+15+23+12+5+4+7+5=96%
- Workhard (努力工作）：W+O+R+K+H+A+R+D＝ 23+15+18+11+8+1+18+4 =98%
- Luck（好运） L+U+C+K＝12+21+3+11=47%
- Love（爱情） L+O+V+E＝12+15+22+5=54%
- Money（金钱） M+O+N+E+Y=13+15+14+5+25=72%
- Leadership（领导能力）L+E+A+D+E+R+S+H+I+P=12+5+1+4+5+18+19+9+16=89%
- ATTITUDE（心态）A+T+T+I+T+U+D+E＝1+20+20+9+20+21+4+5=100%

于是得出结论：用什么样的态度去看待人生，就会得到什么样的人生。

分析
----
这样的心灵鸡汤是怎样来的呢？我们用 PowerShell 脚本来琢磨一下。

```powershell
function Get-Weight([string]$word) {
    $word = $word.ToLower()
    #Write-Host ([System.Text.Encoding]::ASCII.GetBytes($word) |
    #    ForEach-Object { $_ - 96 })
    return ([System.Text.Encoding]::ASCII.GetBytes($word) |
        ForEach-Object { $_ - 96 } |
        Measure-Object -Sum).Sum
}
```

这个函数可以对任意字符串求值，例如以下测试代码将返回 `6`(abc = 1+2+3)：

```powershell
Get-Weight 'abc'
```

现在可以测试一下段子里用到的几个单词，并对结果进行排序：

```powershell
'Knowledge', 'Workhard', 'Luck', 'Love', 'Money', 'Leadership', 'ATTITUDE' |
    Sort-Object -Property @{Expression = { Get-Weight $_ }}
```

结果符合预期：

    Luck
    Love
    Money
    Knowledge
    Leadership
    Workhard
    ATTITUDE

如何撰写鸡汤
------------
以上实现了输入任意字符串数组，对它们进行求值和排序。但是如何选出这些单词呢？我们可以找一篇长文，例如从麻省理工找到莎士比亚的《[哈姆雷特](http://shakespeare.mit.edu/hamlet/full.html)》全文，将它输进去拆解成单词试试：

```powershell
$resp = Invoke-WebRequest 'http://shakespeare.mit.edu/hamlet/full.html'
$fullText = $resp.ParsedHtml.documentElement.innerText
$words = [regex]::Matches($fullText, '\b\w+\b') |
    ForEach-Object { $_.Value } |
    Sort-Object -Unique
```

这样几行代码，就可以将《哈姆雷特》全文的所有单词挑出来进行排序，并将结果保存在 $words 变量中。

最后套用我们上面写好的函数即可实现对所有单词求值排序：

```powershell
$words |
    Sort-Object -Property @{Expression = { Get-Weight $_ }} |
    ForEach-Object {
        "$_`t$(Get-Weight $_)"
    }
```

结果大概是这样：

| word           | weight |
|----------------|--------|
| a              | 1      |
| c              | 3      |
| d              | 4      |
| e              | 5      |
| bad            | 7      |
| be             | 7      |
| I              | 9      |
| ...            | ...    |
| letters        | 99     |
| firmament      | 99     |
| temperance     | 100    |
| Writing        | 100    |
| ...            | ...    |
| prosperously   | 199    |
| unproportioned | 200    |

有了这个长长的表格之后，撰写鸡汤就容易多了。只要按顺序挑出一些单词，设计一下台词即可。

完整的代码如下：


    function Get-Weight([string]$word) {
        $word = $word.ToLower()
        #Write-Host ([System.Text.Encoding]::ASCII.GetBytes($word) |
        #    ForEach-Object { $_ - 96 })
        return ([System.Text.Encoding]::ASCII.GetBytes($word) |
            ForEach-Object { $_ - 96 } |
            Measure-Object -Sum).Sum
    }
    
    # Test
    # Get-Weight 'abc'
    
    if (!$resp) {
        $resp = Invoke-WebRequest 'http://shakespeare.mit.edu/hamlet/full.html'
    }
    
    $fullText = $resp.ParsedHtml.documentElement.innerText
    $words = [regex]::Matches($fullText, '\b\w+\b') |
        ForEach-Object { $_.Value } |
        Sort-Object -Unique
    
    # The following code will procuce output:
    # Luck
    # Love
    # Money
    # Knowledge
    # Leadership
    # Workhard
    # ATTITUDE
    'Knowledge', 'Workhard', 'Luck', 'Love', 'Money', 'Leadership', 'ATTITUDE' |
        Sort-Object -Property @{Expression = { Get-Weight $_ }}
    
    $words |
        Sort-Object -Property @{Expression = { Get-Weight $_ }} |
        ForEach-Object {
            "$_`t$(Get-Weight $_)"
        }

后记
----
完整的代码可以在[这里](/download/encourage.ps1)下载。鸡汤的原文请参见《[是哪位高人琢磨出的这条微信，太牛了](http://mp.weixin.qq.com/s?__biz=MjE1MjMwMzM4MQ==&mid=205847265&idx=2&sn=8e8351bedccb7fc50c3ffe57033c7525&scene=0#rd)》。顺便发现了原文中的一个计算 bug——Leadership（领导能力）应是L+E+A+D+E+R+S+H+I+P=12+5+1+4+5+18+19+8+9+16=97%，而不是 89%。

怎么样，有没有一点理工男秒杀心灵鸡汤的味道？
