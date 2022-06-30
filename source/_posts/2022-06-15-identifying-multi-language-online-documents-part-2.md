---
layout: post
date: 2022-06-15 00:00:00
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
要如何自动检查在线文档所支持的语言？

如果 URL 使用语言 ID，则很容易创建具有所有可用语言 ID 的 URL 列表。 这就是我们到目前为止第一部分中所做的：

```powershell
$list = RL -f
```

在第二部分中，我们现在确定列表中实际存在的 URL。但是，仅仅试图通过 `Invoke-WebRequest` 访问 URL 是不够的：

```powershell
$list = RL -f
```

事实证明，所有 URL 访问的都是微软的 WEB 服务器，并且返回的状态都是 "OK"（包括不存在的语言）：

```powershell
PS> New-SCode  
```

这是因为微软的 WEB 服务器（与许多其它服务器一样）首先接受所有URL。然后，在内部，WEB 服务器弄清楚下一步该怎么做，并将新的 URL 返回到浏览器中。可能是原始的 URL（如果 WEB 服务器找到了资源），也可以是一个全新的 URL，例如通用搜索站点或自定义的“未找到”通知。"OK" 状态与 URL 的有效性无关。

您实际上可以通过禁止自动重定向来查看内部工作。对 `Invoke-WebRequest` 命令添加参数 "`-MaximumRedirection 0 -ErrorAction Ignore`"：

```powershell
$list = RL -f
```

现在，您可以看到 Web 服务器如何告诉浏览器，URL 转移到其他地方，有效地将浏览器重定向到新 URL。

因此检查 URL 是否存在，取决于特定的 WEB 服务器的工作原理。在微软的例子中，事实证明有效的 URL 会导致单次重定向，而无效的 URL 会导致更多此重定向。将重定向限制为一次，可以区分有效和无效的 URL。

这是最终解决方案，还支持一个实时的进度条。

它在网格视图窗口中显示可用的本地化在线文档，您可以选择一个或多个以在浏览器中显示。您也可以在 `$result` 中取得结果，将其打印到 PDF 并将其提交给多种语言的员工。

```powershell
    $list = $h.Keys |
      ForEach-Object { $URL -f
```

<!--本文国际来源：[Identifying Multi-Language Online Documents (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-multi-language-online-documents-part-2)-->

