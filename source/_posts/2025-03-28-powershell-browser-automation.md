---
layout: post
date: 2025-03-28 08:00:00
updated: 2025-03-28 08:00:00
title: "PowerShell 技能连载 - 浏览器自动化实战"
description: PowerTip of the Day - Browser Automation with PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- web
---
_适用于 PowerShell 7.0 及以上版本_

2025 年，AI + 浏览器（Browser Using）成为技术热点，各大模型厂商纷纷推出浏览器操控能力。浏览器自动化不再只是测试工程师的专属工具——数据采集、运维巡检、表单自动填写、可用性监控等场景都离不开它。

PowerShell 作为 Windows 和 macOS 上广泛使用的脚本语言，同样可以胜任浏览器自动化任务。本文将分别介绍 Selenium 和 Playwright 两种方案，从环境搭建到实际应用，帮助你快速上手。

## 方案一：Selenium

Selenium 是老牌的浏览器自动化框架，生态成熟，社区资源丰富。它的核心思路是通过 WebDriver 协议控制浏览器，PowerShell 可以直接调用其 .NET 绑定。

### 安装环境

首先安装 Selenium 模块和 Chrome WebDriver。以下函数会自动完成这些步骤：

```powershell
function Install-SeleniumDriver {
    param(
        [ValidateSet("Chrome", "Firefox", "Edge")]
        [string]$Browser = "Chrome"
    )

    # 安装 Selenium PowerShell 模块
    Install-Module -Name Selenium -Scope CurrentUser -Force

    # 创建 WebDriver 存放目录
    $driverPath = "$env:TEMP\selenium"
    if (-not (Test-Path $driverPath)) {
        New-Item -Path $driverPath -ItemType Directory | Out-Null
    }

    Write-Host "$Browser WebDriver 已就绪"
}
```

执行安装：

```text
PS> Install-SeleniumDriver
Chrome WebDriver 已就绪
```

### 创建浏览器会话

安装完成后，需要一个函数来启动浏览器。我们支持无头模式（Headless），这样在服务器或 CI 环境中也能正常运行。关键参数 `--headless=new` 使用 Chrome 新版无头模式，兼容性更好。

```powershell
function Start-BrowserSession {
    param(
        [ValidateSet("Chrome", "Firefox", "Edge")]
        [string]$Browser = "Chrome",

        [switch]$Headless
    )

    $options = New-Object OpenQA.Selenium.Chrome.ChromeOptions
    if ($Headless) {
        $options.AddArgument("--headless=new")
    }
    $options.AddArgument("--disable-gpu")
    $options.AddArgument("--no-sandbox")

    $driver = New-Object OpenQA.Selenium.Chrome.ChromeDriver($options)
    return $driver
}
```

### 页面操作封装

每次都手动管理 Driver 的生命周期容易遗漏资源释放。下面封装一个通用的页面操作函数，自动处理会话创建和销毁。你只需传入一个脚本块来定义具体操作。

```powershell
function Invoke-WebPageTask {
    param(
        [Parameter(Mandatory)]
        [string]$Url,

        [scriptblock]$Action,

        [switch]$Headless,

        [int]$TimeoutSeconds = 30
    )

    $driver = Start-BrowserSession -Headless:$Headless
    try {
        # 设置隐式等待，避免元素未加载就操作
        $driver.Manage().Timeouts().ImplicitWait = [TimeSpan]::FromSeconds($TimeoutSeconds)
        $driver.Navigate().GoToUrl($Url)
        Write-Host "已打开: $Url"

        $result = & $Action -Driver $driver
        return $result
    }
    finally {
        # 务必释放浏览器进程
        $driver.Quit()
    }
}
```

使用示例——抓取页面标题和所有 HTTPS 链接：

```powershell
$links = Invoke-WebPageTask -Url "https://learn.microsoft.com/powershell" -Headless -Action {
    param($Driver)

    $title = $Driver.Title
    $links = $Driver.FindElements([OpenQA.Selenium.By]::TagName("a")) |
        Where-Object { $_.GetAttribute("href") -match "^https://" } |
        Select-Object @{ N = "Text"; E = { $_.Text } },
                      @{ N = "Href"; E = { $_.GetAttribute("href") } }

    Write-Host "页面: $title, 链接数: $($links.Count)"
    return $links
}
```

执行结果示例：

```text
已打开: https://learn.microsoft.com/powershell
页面: PowerShell | Microsoft Learn, 链接数: 42

Text                   Href
----                   ----
PowerShell 文档        https://learn.microsoft.com/powershell/
安装 PowerShell        https://learn.microsoft.com/powershell/script...
```

### 截图功能

用 Selenium 可以轻松截取完整页面截图。以下函数设置视口大小后导航到目标页面，等待 2 秒让动态内容加载完毕，再保存截图。

```powershell
function Save-WebPageScreenshot {
    param(
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [int]$Width = 1920,
        [int]$Height = 1080
    )

    $driver = Start-BrowserSession -Headless
    try {
        $driver.Manage().Window.Size = New-Object System.Drawing.Size($Width, $Height)
        $driver.Navigate().GoToUrl($Url)
        Start-Sleep -Seconds 2

        $screenshot = $driver.GetScreenshot()
        $screenshot.SaveAsFile($OutputPath, [OpenQA.Selenium.ScreenshotImageFormat]::Png)
        Write-Host "截图已保存: $OutputPath"
    }
    finally {
        $driver.Quit()
    }
}
```

```text
PS> Save-WebPageScreenshot -Url "https://example.com" -OutputPath "$HOME/Desktop/demo.png"
截图已保存: /Users/wubo/Desktop/demo.png
```

## 方案二：Playwright（推荐）

Playwright 是微软推出的新一代浏览器自动化工具，相比 Selenium 有三大优势：自动等待（不需要手写 Sleep）、内置多浏览器支持、原生支持 PDF 导出。如果你是新项目，强烈推荐直接使用 Playwright。

### 安装 Playwright

Playwright 是基于 Node.js 的工具，需要先安装 Node.js 环境，然后通过 npm 安装 Playwright 并下载浏览器内核。

```powershell
# 全局安装 Playwright 包
npm install -g playwright

# 下载 Chromium 浏览器内核
npx playwright install chromium
```

```text
PS> npx playwright install chromium
Downloading Chromium 131.0.6778.33 (darwin) ... done
```

### 通用调用函数

PowerShell 本身没有 Playwright 的原生绑定，但可以通过生成临时 JS 脚本文件来调用。以下函数封装了这个流程：接收 URL 和 JS 脚本片段，自动拼接完整的 Playwright 程序，执行后删除临时文件。

注意 here-string 内不要嵌入三反引号，否则会导致 PowerShell 解析错误。

```powershell
function Invoke-PlaywrightScript {
    param(
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [string]$Script
    )

    # 拼接完整的 Node.js 脚本
    $fullScript = @"
const { chromium } = require('playwright');

(async () => {
    const browser = await chromium.launch({ headless: true });
    const page = await browser.newPage();
    await page.goto('$Url');

    $Script

    await browser.close();
})();
"@

    # 写入临时文件并执行
    $scriptPath = [System.IO.Path]::GetTempFileName() + ".js"
    $fullScript | Out-File -FilePath $scriptPath -Encoding UTF8
    node $scriptPath
    Remove-Item $scriptPath
}
```

### 截图与 PDF 导出

Playwright 的截图和 PDF 功能比 Selenium 更强大。特别是 PDF 导出，Selenium 需要借助 Chrome DevTools Protocol，而 Playwright 直接提供 API。

```powershell
function Save-PlaywrightScreenshot {
    param(
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [string]$OutputPath
    )

    $jsCode = "await page.screenshot({ path: '$($OutputPath.Replace('\','/'))', fullPage: true });"
    Invoke-PlaywrightScript -Url $Url -Script $jsCode
    Write-Host "截图已保存: $OutputPath"
}

function Save-PlaywrightPdf {
    param(
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [string]$OutputPath
    )

    $jsCode = "await page.pdf({ path: '$($OutputPath.Replace('\','/'))', format: 'A4' });"
    Invoke-PlaywrightScript -Url $Url -Script $jsCode
    Write-Host "PDF 已保存: $OutputPath"
}
```

```text
PS> Save-PlaywrightScreenshot -Url "https://example.com" -OutputPath "$HOME/Desktop/pw.png"
截图已保存: /Users/wubo/Desktop/pw.png

PS> Save-PlaywrightPdf -Url "https://example.com" -OutputPath "$HOME/Desktop/page.pdf"
PDF 已保存: /Users/wubo/Desktop/page.pdf
```

## 网站可用性监控

无论选择哪种方案，浏览器自动化最常见的运维场景就是网站健康检查。以下函数使用 Selenium 批量检测多个 URL 的可访问性和加载耗时，输出结构化的监控数据。

```powershell
function Test-WebsiteHealth {
    param(
        [Parameter(Mandatory)]
        [string[]]$Urls,

        [int]$TimeoutSeconds = 15
    )

    $driver = Start-BrowserSession -Headless
    $results = @()

    try {
        foreach ($url in $Urls) {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                $driver.Manage().Timeouts().PageLoad = [TimeSpan]::FromSeconds($TimeoutSeconds)
                $driver.Navigate().GoToUrl($url)
                $sw.Stop()

                $results += [PSCustomObject]@{
                    Url        = $url
                    Status     = "OK"
                    LoadTimeMs = $sw.ElapsedMilliseconds
                    Title      = $driver.Title
                    Timestamp  = Get-Date
                }
            }
            catch {
                $sw.Stop()
                $results += [PSCustomObject]@{
                    Url        = $url
                    Status     = "FAIL"
                    LoadTimeMs = $sw.ElapsedMilliseconds
                    Title      = ""
                    Timestamp  = Get-Date
                    Error      = $_.Exception.Message
                }
            }
        }
    }
    finally {
        $driver.Quit()
    }

    return $results | Format-Table -AutoSize
}
```

```text
PS> Test-WebsiteHealth -Urls "https://example.com","https://httpbin.org/status/500","https://nonexist.invalid"

Url                      Status LoadTimeMs Title               Timestamp
---                      ------ ---------- -----               ---------
https://example.com      OK           312 Example Domain     2025/3/28 10:00:00
https://httpbin.org/st... OK           587                     2025/3/28 10:00:01
https://nonexist.invalid FAIL        5001                     2025/3/28 10:00:06
```

## 小结

Selenium 适合简单的页面交互场景，依赖 .NET 生态，PowerShell 调用起来比较自然。Playwright 更现代，自动等待、原生 PDF 支持、多浏览器覆盖等特性让它在复杂场景下更可靠。无头模式下务必注意内存回收，长时间运行的任务一定要在 `finally` 块中调用 `Quit()` 或 `close()` 释放浏览器进程。
