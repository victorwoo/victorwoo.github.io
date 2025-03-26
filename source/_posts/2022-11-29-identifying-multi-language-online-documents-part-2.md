---
layout: post
date: 2022-11-29 13:47:06
title: "PowerShell 技能连载 - 检测多语言在线文档（第 2 部分）"
description: PowerTip of the Day - Identifying Multi-Language Online Documents (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
要如何检测一份在线文档支持哪些语言？

如果 URL 使用语言 ID，则很容易创建包含所有可用语言 ID 的 URL 列表。这就是我们到目前为止第一部分中所做的：

```powershell
$list  =  RL  -f
```

在第二部分中，我们现在确定列表中哪些 URL 实际中可用。但是，只是通过 `Invoke-Webrequest` 访问该 URL 是不够的：

```powershell
$list  =  RL  -f
```

事实证明，所有 URL 都能正常地访问 Microsoft WEB 服务器，并返回状态 "OK"（包括不存在的文档地址）：

```powershell
PS> New-SCode
```

这是因为 Microsoft WEB 服务器（与许多其它的一样）首先接受所有 URL。然后，在内部，WEB 服务器弄清楚下一步该怎么做，并将新的 URL 返回到浏览器中。可能返回的是原始的 URL（如果 WEB 服务器找到了资源），也可能是一个全新的URL，例如通用搜索站点或自定义的“未找到”通知。状态 "OK" 与 URL 的有效性并没有关联。

您实际上可以通过禁止自动重定向来查看内部工作过程。对 `Invoke-WebRequest` 命令添加参数 `"-MaximumRedirection 0 -ErrorAction Ignore"`。

```powershell
$list  =  RL  -f
```

现在，您看到 Web 服务器如何告诉浏览器，URL 跳转至其他地方，有效地将浏览器重定向到新的 URL。

检查 URL 是否存在，取决于特定的 Web 服务器的工作原理。在微软的例子中，事实证明有效的 URL 会导致单次重定向，而无效的 URL 会导致多次重定向。用重定向的次次数是否为一次，可以区分合法和非法的 URL。

这是最终解决方案，它还支持实时进度条。

它在网格视图窗口中显示可用的本地化在线文档，您可以选择一个或多个以在浏览器中显示。您也可以以 `$result` 的形式获取结果，然后将其打印到 PDF 并将其提交给其它语言的员工。

```powershell
$list  =  $h.Keys  |  ForEach-Object { $URL  -f
```

<!--本文国际来源：[Identifying Multi-Language Online Documents (Part 2)](https://blog.idera.com/database-tools/identifying-multi-language-online-documents-part-2)-->

