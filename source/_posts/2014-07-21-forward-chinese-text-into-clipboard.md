title: 用 PowerShell 输出中文到剪贴板
description: Forward Chinese Text into Clipboard with PowerShell
date: 2014-07-21 18:30:27
categories:
- powershell
- text
tags:
- powershell
- text
---
# 方法一 通过 clip.exe

用 PowerShell 将字符串输出到剪贴板的最简单方式是：

    'abc' | clip.exe

不过直接这么使用的话，如果待输出的字符串是包含中文的，那么剪贴板里的内容会出现“乱码”：

    'abc中文def' | clip.exe

剪贴板里的内容变成：

    abc??def

这是因为为了兼容旧程序，管道操作缺省将字符串采用 ASCII 编码，因此对于中文字符，被转换成了“??”。解决方案如下：

    $OutputEncoding = [Console]::OutputEncoding
    'abc中文def' | clip.exe

# 方法二 通过 WPF 方法

以 `-sta` 参数启动 PowerShell 后，执行以下代码：

    Add-Type -Assembly PresentationCore
    [Windows.Clipboard]::SetText('abc中文def')

PowerShell 2.0 的控制台，缺省设置是 MTA；PowerShell 3.0 的控制台，缺省设置是 STA。

关于 `-sta` 的知识，请参见[PowerShell中的 STA和MTA](http://www.pstips.net/powershell-sta-and-mta.html)。

参考材料：
- [$OutputEncoding to the rescue](http://blogs.msdn.com/b/powershell/archive/2006/12/11/outputencoding-to-the-rescue.aspx)
- [Powershell能否将文件列表写入剪切板](http://bathome.net/thread-30850-1-1.html)
- [PowerShell中的 STA和MTA](http://www.pstips.net/powershell-sta-and-mta.html)
- [PowerShell.exe Command-Line Help](http://technet.microsoft.com/zh-cn/library/hh847736.aspx)
- QQ 群 [*PowerShell技术交流（271143343）](http://url.cn/Jq5bta) 2014-07-01 的讨论
