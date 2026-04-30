---
layout: post
date: 2025-03-28 08:00:00
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
- browser
---
浏览器自动化不仅用于 Web 测试，在数据采集、运维巡检、表单自动填写等场景也很常见。本文介绍在 PowerShell 中使用 Selenium 和 Playwright 两种方案。

## 使用 Selenium

```powershell
function Install-SeleniumDriver {
    param(
        [ValidateSet("Chrome", "Firefox", "Edge")]
        [string]$Browser = "Chrome"
    )

    Install-Module -Name Selenium -Scope CurrentUser -Force

    # 自动下载对应的 WebDriver
    $driverPath = "$env:TEMP\selenium"
    if (-not (Test-Path $driverPath)) {
        New-Item -Path $driverPath -ItemType Directory | Out-Null
    }

    Write-Host "$Browser WebDriver 已就绪"
}

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

## 页面操作封装

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
        $driver.Manage().Timeouts().ImplicitWait = [TimeSpan]::FromSeconds($TimeoutSeconds)
        $driver.Navigate().GoToUrl($Url)
        Write-Host "已打开: $Url"

        $result = & $Action -Driver $driver
        return $result
    }
    finally {
        $driver.Quit()
    }
}

# 示例：抓取页面标题和所有链接
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

## 使用 Playwright（推荐）

Playwright 比 Selenium 更现代，自带自动等待和更可靠的选择器。

```powershell
# 安装 Playwright
npm install -g playwright
npx playwright install chromium

# 通过 PowerShell 调用 Playwright
function Invoke-PlaywrightScript {
    param(
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [string]$Script
    )

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

    $scriptPath = [System.IO.Path]::GetTempFileName() + ".js"
    $fullScript | Out-File -FilePath $scriptPath -Encoding UTF8
    node $scriptPath
    Remove-Item $scriptPath
}
```

## 截图与 PDF 导出

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

function Save-WebPageAsPdf {
    param(
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [string]$OutputPath
    )

    $script = @"
const { chromium } = require('playwright');
(async () => {
    const browser = await chromium.launch();
    const page = await browser.newPage();
    await page.goto('$Url', { waitUntil: 'networkidle' });
    await page.pdf({ path: '$($OutputPath.Replace('\','/'))', format: 'A4' });
    await browser.close();
})();
"@

    $scriptPath = [System.IO.Path]::GetTempFileName() + ".js"
    $script | Out-File -FilePath $scriptPath -Encoding UTF8
    node $scriptPath
    Remove-Item $scriptPath
    Write-Host "PDF 已保存: $OutputPath"
}
```

## 监控网站可用性

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

对于简单的页面交互优先用 Selenium，复杂场景和多浏览器测试推荐 Playwright。无头模式下注意内存回收，长时间运行务必调用 `Quit()` 释放资源。
