---
layout: post
date: 2026-04-08 08:00:00
updated: 2026-04-08 08:00:00
title: "PowerShell 技能连载 - Browser Use 浏览器自动化"
description: PowerTip of the Day - Browser Use Automation in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- browser-automation
- playwright
- selenium
- web-scraping
---

_适用于 PowerShell 7.0 及以上版本_

## 背景

2026 年，浏览器自动化技术已经从简单的网页测试工具发展为 AI Agent 执行任务的核心能力。以 Browser Use 为代表的框架让 AI 模型能够直接操控浏览器完成复杂任务，例如自动填表、数据采集、跨站点流程编排等。Playwright 和 Selenium 作为两大主流浏览器自动化引擎，都提供了成熟的 API，而 PowerShell 凭借其强大的对象管道和 .NET 生态集成能力，成为串联这些工具的绝佳胶水语言。

在实际运维和数据处理场景中，我们经常需要从没有 API 的内部系统中提取数据、定时提交报表、或批量执行重复的网页操作。传统做法依赖手动操作或录制宏脚本，维护成本高且容易出错。PowerShell 结合 Playwright 可以编写声明式的自动化脚本，配合 AI 模型甚至能实现"说一句话，浏览器自动完成操作"的智能体验。

本文将分三个层次介绍 PowerShell 浏览器自动化：从 Playwright 基础操作，到数据采集与表单自动化，再到 AI 驱动的智能浏览器操作，帮助读者逐步掌握这项实用技能。

## Playwright 自动化基础

Playwright 是微软开发的跨浏览器自动化框架，原生支持 Chromium、Firefox 和 WebKit。PowerShell 可以通过 .NET 互操作直接调用 Playwright 的 NuGet 包，实现从浏览器启动到元素操作的全流程控制。

以下代码演示了 Playwright 的安装、浏览器启动、页面导航、等待元素加载、点击按钮、读取文本等基本操作：

```powershell
# 安装 Playwright NuGet 包和浏览器二进制文件
Install-Module -Name Microsoft.Playwright -Scope CurrentUser -Force
dotnet tool install --global Microsoft.Playwright.CLI
playwright install chromium

# 导入模块并启动浏览器
using module Microsoft.Playwright

$playwright = [Microsoft.Playwright.Program]::CreatePlaywright()
$browser = $playwright.Chromium.LaunchAsync(@{ headless = $true }).GetAwaiter().GetResult()

# 创建新页面并导航到目标网站
$page = $browser.NewPageAsync().GetAwaiter().GetResult()
$page.GotoAsync("https://example.com").GetAwaiter().GetResult()

# 等待页面标题加载并获取标题文本
$page.WaitForSelectorAsync("h1").GetAwaiter().GetResult() | Out-Null
$title = $page.TextContentAsync("h1").GetAwaiter().GetResult()
Write-Host "页面标题: $title"

# 查找链接并获取所有链接地址
$links = $page.QuerySelectorAllAsync("a").GetAwaiter().GetResult()
foreach ($link in $links) {
    $href = $link.GetAttributeAsync("href").GetAwaiter().GetResult()
    $text = $link.TextContentAsync().GetAwaiter().GetResult()
    Write-Host "  链接: $text -> $href"
}

# 关闭浏览器释放资源
$browser.CloseAsync().GetAwaiter().GetResult()
$playwright.Dispose()
```

执行结果示例：

```text
页面标题: Example Domain
  链接: More information... -> https://www.iana.org/domains/example
```

在实际项目中，推荐使用 `try-finally` 块确保浏览器资源被正确释放，避免残留进程占用系统内存。

## 数据采集与表单自动化

网页数据提取和表单自动填写是浏览器自动化最常见的应用场景。PowerShell 可以将采集到的结构化数据直接转化为对象，利用管道进行筛选和导出，这是其他脚本语言难以比拟的优势。

下面的脚本展示了从网页表格提取数据、自动填写搜索表单、以及将页面保存为截图和 PDF 的完整流程：

```powershell
using module Microsoft.Playwright

$playwright = [Microsoft.Playwright.Program]::CreatePlaywright()
$browser = $playwright.Chromium.LaunchAsync(@{ headless = $true }).GetAwaiter().GetResult()
$page = $browser.NewPageAsync().GetAwaiter().GetResult()

# 导航到包含表格的页面
$page.GotoAsync("https://example.com/tables").GetAwaiter().GetResult()
$page.WaitForSelectorAsync("table").GetAwaiter().GetResult() | Out-Null

# 提取表格数据并转化为 PowerShell 对象
$rows = $page.QuerySelectorAllAsync("table tbody tr").GetAwaiter().GetResult()
$tableData = foreach ($row in $rows) {
    $cells = $row.QuerySelectorAllAsync("td").GetAwaiter().GetResult()
    [PSCustomObject]@{
        Name     = $cells[0].TextContentAsync().GetAwaiter().GetResult().Trim()
        Value    = $cells[1].TextContentAsync().GetAwaiter().GetResult().Trim()
        Status   = $cells[2].TextContentAsync().GetAwaiter().GetResult().Trim()
    }
}

# 筛选状态为 Active 的记录并导出为 CSV
$tableData | Where-Object { $_.Status -eq "Active" } | Export-Csv -Path "active_items.csv" -NoTypeInformation -Encoding utf8
Write-Host "已导出 $($tableData.Count) 条记录"

# 自动填写搜索表单
$page.GotoAsync("https://example.com/search").GetAwaiter().GetResult()
$page.FillAsync("#search-input", "PowerShell automation").GetAwaiter().GetResult()
$page.SelectOptionAsync("#category", "technology").GetAwaiter().GetResult()
$page.ClickAsync("#search-button").GetAwaiter().GetResult()

# 等待搜索结果加载
$page.WaitForSelectorAsync(".result-item").GetAwaiter().GetResult() | Out-Null

# 截取搜索结果页面的屏幕截图
$page.ScreenshotAsync(@{ path = "search-results.png"; fullPage = $true }).GetAwaiter().GetResult() | Out-Null
Write-Host "截图已保存到 search-results.png"

# 将当前页面导出为 PDF
$page.PdfAsync(@{ path = "search-results.pdf"; format = "A4" }).GetAwaiter().GetResult() | Out-Null
Write-Host "PDF 已保存到 search-results.pdf"

$browser.CloseAsync().GetAwaiter().GetResult()
$playwright.Dispose()
```

执行结果示例：

```text
已导出 12 条记录
截图已保存到 search-results.png
PDF 已保存到 search-results.pdf
```

通过 `PSCustomObject` 将网页数据结构化后，可以无缝使用 `Where-Object`、`Sort-Object`、`Export-Csv` 等 PowerShell 原生命令进行后续处理，实现从采集到入库的一体化流程。

## AI 驱动的浏览器操作

2026 年最具变革性的趋势是将大语言模型（LLM）与浏览器自动化结合，让 AI 理解页面语义后自动决定操作步骤。PowerShell 在这个场景中扮演调度器的角色：调用 LLM API 分析页面结构，解析返回的指令，再驱动浏览器执行具体动作。

以下脚本展示了如何用 PowerShell 调用本地 Ollama 模型分析网页元素，实现 AI 驱动的智能浏览器操作：

```powershell
using module Microsoft.Playwright

# 配置 Ollama API 端点
$ollamaEndpoint = "http://localhost:11434/api/generate"
$modelName = "qwen2.5:7b"

function Invoke-OllamaChat {
    param([string]$Prompt)
    $body = @{
        model  = $modelName
        prompt = $Prompt
        stream = $false
    } | ConvertTo-Json -Depth 5

    $response = Invoke-RestMethod -Uri $ollamaEndpoint -Method Post -Body $body -ContentType "application/json"
    return $response.response
}

# 启动浏览器并导航到目标页面
$playwright = [Microsoft.Playwright.Program]::CreatePlaywright()
$browser = $playwright.Chromium.LaunchAsync(@{ headless = $false }).GetAwaiter().GetResult()
$page = $browser.NewPageAsync().GetAwaiter().GetResult()
$page.GotoAsync("https://news.example.com").GetAwaiter().GetResult()

# 提取页面可交互元素的摘要信息
$elements = $page.QuerySelectorAllAsync("a, button, input, select").GetAwaiter().GetResult()
$elementSummary = foreach ($el in $elements[0..19]) {
    $tag = $el.EvaluateHandleAsync("e => e.tagName").GetAwaiter().GetResult().JsonValue
    $text = $el.TextContentAsync().GetAwaiter().GetResult()
    $role = $el.GetAttributeAsync("role").GetAwaiter().GetResult()
    "  <$tag> text='$($text.Trim().Substring(0, [Math]::Min(50, $text.Trim().Length)))' role='$role'"
}
$summaryText = $elementSummary -join "`n"

# 让 AI 分析页面并推荐操作
$aiPrompt = @"
你是一个浏览器自动化助手。以下是页面上的可交互元素：

$summaryText

用户任务：找到今天浏览量最高的科技新闻标题。
请告诉我应该点击哪个元素（用序号表示），以及后续操作建议。
只返回简洁的操作指令，不要解释。
"@

$aiResponse = Invoke-OllamaChat -Prompt $aiPrompt
Write-Host "AI 建议: $aiResponse"

# 根据 AI 建议提取操作索引并执行点击
if ($aiResponse -match "点击.*?(\d+)") {
    $index = [int]$Matches[1]
    if ($index -lt $elements.Count) {
        $elements[$index].ClickAsync().GetAwaiter().GetResult() | Out-Null
        Write-Host "已执行 AI 建议的点击操作（元素 #$index）"
    }
}

# 等待新页面加载后提取标题
Start-Sleep -Seconds 2
$articleTitle = $page.TitleAsync().GetAwaiter().GetResult()
Write-Host "当前页面标题: $articleTitle"

$browser.CloseAsync().GetAwaiter().GetResult()
$playwright.Dispose()
```

执行结果示例：

```text
AI 建议: 点击元素 #3，这是"科技"分类链接。进入后点击第一个新闻标题即可。
已执行 AI 建议的点击操作（元素 #3）
当前页面标题: 最新科技新闻 - News Example
```

这种方式将 LLM 的语义理解能力与 Playwright 的精确操作能力结合，实现了"自然语言到浏览器操作"的闭环。在生产环境中，建议加入操作确认机制和异常回退逻辑，确保 AI 的操作可预测且可追溯。

## 注意事项

1. **资源管理**：Playwright 的浏览器实例是重量级资源，务必使用 `try-finally` 块确保 `CloseAsync` 和 `Dispose` 被调用，避免残留进程消耗系统资源。

2. **异步处理**：Playwright 的 .NET API 大量使用 `async/await` 模式，在 PowerShell 中需要通过 `.GetAwaiter().GetResult()` 同步等待。避免在循环中频繁调用，可改用批量操作减少开销。

3. **等待策略**：页面加载时间受网络状况影响较大，推荐使用 `WaitForSelectorAsync` 替代固定的 `Start-Sleep`，既保证元素可用，又避免不必要的等待。

4. **无头模式选择**：开发调试时使用 `headless = $false` 以便观察浏览器行为，生产环境使用 `headless = $true` 提升性能。在 Linux 服务器上运行时需要安装额外的系统依赖库。

5. **AI 操作安全性**：让 LLM 直接控制浏览器操作具有不确定性，务必对 AI 返回的指令进行校验（如索引范围检查、URL 白名单过滤），防止误操作导致数据丢失或安全风险。

6. **反爬虫应对**：部分网站会检测自动化工具并限制访问。可通过设置 `User-Agent`、使用浏览器上下文隔离、控制请求频率等方式降低被识别的概率，同时确保遵守目标网站的服务条款。
