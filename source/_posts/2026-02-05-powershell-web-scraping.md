---
layout: post
date: 2026-02-05 08:00:00
updated: 2026-02-05 08:00:00
title: "PowerShell 技能连载 - Web 数据采集"
description: PowerTip of the Day - Web Data Scraping in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- web-scraping
- html
- data-collection
- automation
---

_适用于 PowerShell 7.0 及以上版本_

在运维和数据分析工作中，经常需要从网页上采集数据——监控页面上的状态信息、采集竞争对手的价格数据、抓取内部系统的报表。这些场景看似简单，但手动操作既耗时又容易出错，尤其是当数据源多、更新频繁时，人工采集几乎无法持续。

PowerShell 通过 `Invoke-WebRequest` 和内置的 HTML 解析能力，可以快速构建轻量级的数据采集脚本。与 Python 的 Scrapy 或 BeautifulSoup 相比，PowerShell 方案无需额外安装解释器，直接在 Windows 或跨平台环境中即可运行，特别适合已经在使用 PowerShell 进行运维自动化的团队。

本文将从基础的 HTML 解析入手，逐步介绍表单提交与认证采集，最后实现批量并发采集与数据清洗的完整方案，帮助你构建可靠的数据采集管道。

## HTML 解析与数据提取

`Invoke-WebRequest` 返回的对象中包含一个 `ParsedHtml` 属性，但跨平台场景下更推荐使用正则表达式或 HTML Agility Pack 来解析。下面演示如何从一个示例页面中提取表格数据。

```powershell
# 从示例页面采集表格数据
$url = "https://example.com/status"
$response = Invoke-WebRequest -Uri $url -UseBasicParsing

# 方法一：使用正则表达式提取 HTML 表格中的数据
$pattern = '<tr>\s*<td>(.*?)</td>\s*<td>(.*?)</td>\s*<td>(.*?)</td>\s*</tr>'
$matches = [regex]::Matches($response.Content, $pattern)

$results = foreach ($m in $matches) {
    [PSCustomObject]@{
        ServerName = $m.Groups[1].Value.Trim()
        Status     = $m.Groups[2].Value.Trim()
        ResponseMs = $m.Groups[3].Value.Trim()
    }
}

$results | Format-Table -AutoSize

# 方法二：使用 HTML Agility Pack 进行 CSS 选择器查询
# 先安装 HTML Agility Pack
Install-Module -Name HtmlAgilityPack -Force -Scope CurrentUser -ErrorAction SilentlyContinue
Add-Type -Path (Join-Path $env:USERPROFILE ".nuget\packages\htmlagilitypack\1.11.72\lib\netstandard2.0\HtmlAgilityPack.dll") -ErrorAction SilentlyContinue

# 使用 HtmlDocument 解析
$doc = [HtmlAgilityPack.HtmlDocument]::new()
$doc.LoadHtml($response.Content)

# 通过 XPath 精确定位
$nodes = $doc.DocumentNode.SelectNodes('//table[@class="status-table"]//tr[position()>1]')
foreach ($row in $nodes) {
    $cells = $row.SelectNodes('.//td')
    [PSCustomObject]@{
        ServerName = $cells[0].InnerText.Trim()
        Status     = $cells[1].InnerText.Trim()
        ResponseMs = $cells[2].InnerText.Trim()
    }
}
```

执行结果示例：

```
ServerName Status   ResponseMs
---------- ------   ----------
WEB-01     Online   45
WEB-02     Online   38
DB-01      Online   120
DB-02      Offline  N/A
CACHE-01   Online   12
```

## 表单提交与认证采集

很多数据藏在需要登录的系统后面。PowerShell 的 `WebRequestSession` 对象可以自动管理 Cookie，模拟完整的登录流程后访问受保护的页面。

```powershell
# 创建会话变量，用于保持登录状态
$loginUrl = "https://internal.example.com/login"
$reportUrl = "https://internal.example.com/report/daily"

# 第一步：获取登录页面（同时初始化 Session）
$loginPage = Invoke-WebRequest -Uri $loginUrl -SessionVariable session -UseBasicParsing

# 第二步：提取隐藏的表单字段（如 CSRF Token）
$csrfPattern = 'name="__RequestVerificationToken".*?value="([^"]+)"'
$csrfMatch = [regex]::Match($loginPage.Content, $csrfPattern)
$csrfToken = if ($csrfMatch.Success) { $csrfMatch.Groups[1].Value } else { "" }

# 第三步：提交登录表单
$loginBody = @{
    username                  = "admin"
    password                  = "P@ssw0rd123!"
    __RequestVerificationToken = $csrfToken
    RememberMe                = "true"
}

$loginResponse = Invoke-WebRequest -Uri $loginUrl -Method POST -Body $loginBody -WebSession $session -UseBasicParsing

# 第四步：使用已认证的会话访问报表页面
$reportResponse = Invoke-WebRequest -Uri $reportUrl -WebSession $session -UseBasicParsing

# 第五步：从报表页面提取数据
$dataPattern = '<tr[^>]*>\s*<td>(\d{4}-\d{2}-\d{2})</td>\s*<td>([\d,.]+)</td>\s*<td>([\d,.]+)</td>\s*</tr>'
$dataMatches = [regex]::Matches($reportResponse.Content, $dataPattern)

$reportData = foreach ($m in $dataMatches) {
    [PSCustomObject]@{
        Date       = $m.Groups[1].Value
        Revenue    = $m.Groups[2].Value
        Cost       = $m.Groups[3].Value
    }
}

$reportData | Format-Table -AutoSize
Write-Host "`n采集完成，共获取 $($reportData.Count) 条记录"
```

执行结果示例：

```
Date       Revenue       Cost
----       -------      ----
2026-01-30 125,680.00 89,340.00
2026-01-31 132,450.00 91,200.00
2026-02-01 118,930.00 87,650.00
2026-02-02 141,200.00 93,100.00
2026-02-03 156,780.00 95,420.00

采集完成，共获取 5 条记录
```

## 批量采集与数据清洗

当需要从多个页面或多个数据源采集数据时，可以利用 PowerShell 的 `ForEach-Object -Parallel` 实现并发采集，然后对原始数据进行清洗和标准化处理，最后导出为结构化格式。

```powershell
# 定义采集目标列表
$targets = @(
    @{ Name = "北京"; Url = "https://api.example.com/weather/beijing" }
    @{ Name = "上海"; Url = "https://api.example.com/weather/shanghai" }
    @{ Name = "广州"; Url = "https://api.example.com/weather/guangzhou" }
    @{ Name = "深圳"; Url = "https://api.example.com/weather/shenzhen" }
    @{ Name = "成都"; Url = "https://api.example.com/weather/chengdu" }
)

# 并发采集数据（限制并发数为 3）
$rawData = $targets | ForEach-Object -ThrottleLimit 3 -Parallel {
    $target = $_
    try {
        $response = Invoke-WebRequest -Uri $target.Url -UseBasicParsing -TimeoutSec 10
        # 解析 JSON 响应
        $json = $response.Content | ConvertFrom-Json
        [PSCustomObject]@{
            City        = $target.Name
            Temperature = $json.temperature
            Humidity    = $json.humidity
            Wind        = $json.wind
            AQI         = $json.aqi
            Status      = "Success"
            ErrorMsg    = ""
        }
    }
    catch {
        [PSCustomObject]@{
            City        = $target.Name
            Temperature = $null
            Humidity    = $null
            Wind        = $null
            AQI         = $null
            Status      = "Failed"
            ErrorMsg    = $_.Exception.Message
        }
    }
}

# 数据清洗：过滤失败记录，标准化数值
$cleanData = $rawData | Where-Object { $_.Status -eq "Success" } | ForEach-Object {
    # 温度转摄氏度（假设原始数据为华氏度）
    $tempC = [math]::Round(($_.Temperature - 32) * 5 / 9, 1)
    # 湿度取整
    $humidity = [int]$_.Humidity

    [PSCustomObject]@{
        City           = $_.City
        TemperatureC   = $tempC
        HumidityPct    = $humidity
        WindSpeed      = $_.Wind
        AQI            = [int]$_.AQI
        AQILevel       = switch ([int]$_.AQI) {
            { $_ -le 50 }  { "优" }
            { $_ -le 100 } { "良" }
            { $_ -le 150 } { "轻度污染" }
            { $_ -le 200 } { "中度污染" }
            default        { "重度污染" }
        }
        CollectTime    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

# 显示结果
$cleanData | Format-Table -AutoSize

# 导出到 CSV
$csvPath = Join-Path $env:USERPROFILE "Desktop\weather_data.csv"
$cleanData | Export-Csv -Path $csvPath -NoTypeInformation -Encoding Utf8
Write-Host "CSV 已导出至: $csvPath"

# 导出到 JSON
$jsonPath = Join-Path $env:USERPROFILE "Desktop\weather_data.json"
$cleanData | ConvertTo-Json -Depth 3 | Set-Content -Path $jsonPath -Encoding Utf8
Write-Host "JSON 已导出至: $jsonPath"
```

执行结果示例：

```
City  TemperatureC HumidityPct WindSpeed AQI AQILevel CollectTime
----  ------------ ----------- --------- --- -------- -----------
北京  2.3          45          3.2m/s    82  良       2026-02-05 08:15:32
上海  6.8          62          4.1m/s    68  良       2026-02-05 08:15:33
广州  15.2         78          2.8m/s    55  良       2026-02-05 08:15:33
深圳  17.6         75          3.0m/s    48  优       2026-02-05 08:15:33
成都  8.1          70          1.5m/s    92  良       2026-02-05 08:15:34

CSV 已导出至: C:\Users\admin\Desktop\weather_data.csv
JSON 已导出至: C:\Users\admin\Desktop\weather_data.json
```

## 注意事项

1. **遵守 robots.txt 和法律合规**：采集前检查目标网站的 `robots.txt` 文件，尊重网站的爬取规则。对敏感数据或受版权保护的内容，务必获得授权后再采集，避免触犯法律。

2. **请求频率控制**：高频率请求可能对目标服务器造成压力，甚至触发 IP 封禁。建议在循环中加入 `Start-Sleep -Milliseconds 500` 等延迟，并发采集时将 `ThrottleLimit` 控制在 3-5 之间。

3. **异常处理与重试机制**：网络请求天然不稳定，务必使用 `try/catch` 包裹所有请求代码，并实现指数退避重试策略，确保脚本在偶发网络故障时不会中断。

4. **User-Agent 伪装**：部分网站会拒绝默认的 PowerShell User-Agent。可以通过 `-Headers @{ 'User-Agent' = 'Mozilla/5.0 ...' }` 设置合理的浏览器标识，但这并不意味着可以绕过反爬机制去做不当采集。

5. **编码与字符集处理**：中文网页常见 GBK、GB2312 等编码，PowerShell 默认使用 UTF-8。采集后需要用 `[System.Text.Encoding]::GetEncoding('GBK').GetString(...)` 进行转码，否则会出现乱码。

6. **数据验证与清洗**：从网页提取的原始数据通常包含空白字符、HTML 实体（如 `&amp;`、`&nbsp;`）和格式不一致的数值。建议封装一个 `Invoke-DataClean` 函数统一处理这些常见问题，确保导出数据的规范性。
