---
layout: post
date: 2025-07-11 08:00:00
updated: 2025-07-11 08:00:00
title: "PowerShell 技能连载 - XML 高级处理"
description: PowerTip of the Day - Advanced XML Processing in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- xml
- xpath
- data-processing
---

_适用于 PowerShell 5.1 及以上版本_

虽然 JSON 已经成为现代应用配置的主流格式，但 XML 仍然在许多场景中扮演重要角色——Windows 配置文件（`.config`）、NuGet 包定义（`.nuspec`）、SOAP Web 服务、Office 文档（`.docx`/`.xlsx` 底层是 XML）、以及大量遗留系统的数据交换格式。PowerShell 通过 `[xml]` 类型加速器和 .NET 的 `System.Xml` 命名空间，提供了强大的 XML 处理能力。

本文将讲解 XML 文档的创建、查询（XPath）、修改，以及与常见 XML 格式的交互。

<!-- more -->

## XML 解析与导航

```powershell
# 解析 XML 字符串
[xml]$config = @"
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <appSettings>
        <add key="ServerName" value="prod-db01" />
        <add key="Port" value="5432" />
        <add key="Database" value="MyApp" />
        <add key="Timeout" value="30" />
    </appSettings>
    <connectionStrings>
        <add name="Default" connectionString="Server=prod-db01;Database=MyApp;Integrated Security=True" />
        <add name="ReadOnly" connectionString="Server=prod-db01;Database=MyApp_ReadOnly;Integrated Security=True" />
    </connectionStrings>
    <logging>
        <level>Warning</level>
        <path>C:\Logs\MyApp</path>
        <maxSizeMB>100</maxSizeMB>
    </logging>
</configuration>
"@

# 属性访问（点表示法）
Write-Host "服务器：$($config.configuration.appSettings.add[0].value)"
Write-Host "端口：$($config.configuration.appSettings.add[1].value)"
Write-Host "日志级别：$($config.configuration.logging.level)"

# 提取所有 appSettings 为哈希表
$settings = @{}
foreach ($add in $config.configuration.appSettings.add) {
    $settings[$add.key] = $add.value
}
Write-Host "`nAppSettings："
$settings.GetEnumerator() | Sort-Object Key | ForEach-Object {
    Write-Host "  $($_.Key) = $($_.Value)"
}

# 提取连接字符串
Write-Host "`n连接字符串："
foreach ($cs in $config.configuration.connectionStrings.add) {
    Write-Host "  $($cs.name)：$($cs.connectionString)"
}

# 从文件加载 XML
# [xml]$doc = Get-Content "C:\MyApp\web.config" -Encoding UTF8
```

执行结果示例：

```
服务器：prod-db01
端口：5432
日志级别：Warning

AppSettings：
  Database = MyApp
  Port = 5432
  ServerName = prod-db01
  Timeout = 30

连接字符串：
  Default：Server=prod-db01;Database=MyApp;Integrated Security=True
  ReadOnly：Server=prod-db01;Database=MyApp_ReadOnly;Integrated Security=True
```

## XPath 查询

```powershell
# XPath 提供强大的 XML 查询能力
[xml]$servers = @"
<inventory>
    <server env="production" role="web">
        <name>WEB01</name>
        <ip>10.0.1.10</ip>
        <cpu>8</cpu>
        <ram>32</ram>
        <status>running</status>
    </server>
    <server env="production" role="db">
        <name>DB01</name>
        <ip>10.0.1.20</ip>
        <cpu>16</cpu>
        <ram>64</ram>
        <status>running</status>
    </server>
    <server env="staging" role="web">
        <name>WEB-STG01</name>
        <ip>10.0.2.10</ip>
        <cpu>4</cpu>
        <ram>16</ram>
        <status>stopped</status>
    </server>
    <server env="production" role="web">
        <name>WEB02</name>
        <ip>10.0.1.11</ip>
        <cpu>8</cpu>
        <ram>32</ram>
        <status>running</status>
    </server>
</inventory>
"@

# SelectNodes 使用 XPath 查询
$nav = $servers.CreateNavigator()

# 查询所有生产环境服务器
$prodServers = $servers.SelectNodes("//server[@env='production']")
Write-Host "生产环境服务器：" -ForegroundColor Cyan
foreach ($s in $prodServers) { Write-Host "  $($s.name) ($($s.ip)) - $($s.status)" }

# 查询所有 Web 角色
$webServers = $servers.SelectNodes("//server[@role='web']")
Write-Host "`nWeb 服务器：" -ForegroundColor Cyan
foreach ($s in $webServers) { Write-Host "  $($s.name) - CPU: $($s.cpu), RAM: $($s.ram)GB" }

# 复杂查询：生产环境中 CPU 大于 8 的服务器
$powerful = $servers.SelectNodes("//server[@env='production' and cpu > 8]")
Write-Host "`n高配生产服务器（CPU>8）：" -ForegroundColor Cyan
foreach ($s in $powerful) { Write-Host "  $($s.name) - CPU: $($s.cpu)" }

# 统计总资源
$totalCpu = $servers.SelectNodes("sum(//server[@env='production']/cpu)")
$totalRam = $servers.SelectNodes("sum(//server[@env='production']/ram)")
Write-Host "`n生产环境总资源：CPU $totalCpu 核，RAM $totalRam GB"
```

执行结果示例：

```
生产环境服务器：
  WEB01 (10.0.1.10) - running
  DB01 (10.0.1.20) - running
  WEB02 (10.0.1.11) - running

Web 服务器：
  WEB01 - CPU: 8, RAM: 32GB
  WEB-STG01 - CPU: 4, RAM: 16GB
  WEB02 - CPU: 8, RAM: 32GB

高配生产服务器（CPU>8）：
  DB01 - CPU: 16

生产环境总资源：CPU 32 核，RAM 128 GB
```

## XML 创建与修改

```powershell
# 创建新的 XML 文档
function New-ReportXml {
    param(
        [string]$ReportName = "系统巡检报告",
        [string]$OutputPath = "C:\Reports\report.xml"
    )

    $xmlDoc = [System.Xml.XmlDocument]::new()

    # XML 声明
    $declaration = $xmlDoc.CreateXmlDeclaration("1.0", "UTF-8", $null)
    $xmlDoc.AppendChild($declaration) | Out-Null

    # 根元素
    $root = $xmlDoc.CreateElement("report")
    $root.SetAttribute("name", $ReportName)
    $root.SetAttribute("generated", (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))

    # 服务器信息
    $serversNode = $xmlDoc.CreateElement("servers")

    foreach ($srvName in @("WEB01", "WEB02", "DB01")) {
        $srvNode = $xmlDoc.CreateElement("server")
        $srvNode.SetAttribute("name", $srvName)
        $srvNode.SetAttribute("status", "running")

        $cpuNode = $xmlDoc.CreateElement("cpu")
        $cpuNode.InnerText = Get-Random -Min 10 -Max 90
        $srvNode.AppendChild($cpuNode) | Out-Null

        $memNode = $xmlDoc.CreateElement("memory")
        $memNode.InnerText = Get-Random -Min 20 -Max 80
        $srvNode.AppendChild($memNode) | Out-Null

        $serversNode.AppendChild($srvNode) | Out-Null
    }

    $root.AppendChild($serversNode) | Out-Null
    $xmlDoc.AppendChild($root) | Out-Null

    $xmlDoc.Save($OutputPath)
    Write-Host "XML 报告已生成：$OutputPath" -ForegroundColor Green
}

New-ReportXml

# 修改现有 XML
[xml]$doc = Get-Content "C:\Reports\report.xml"

# 修改属性值
$server = $doc.SelectSingleNode("//server[@name='WEB01']")
if ($server) {
    $server.status = "maintenance"
    Write-Host "已修改 WEB01 状态为 maintenance" -ForegroundColor Yellow
}

# 添加新节点
$newServer = $doc.CreateElement("server")
$newServer.SetAttribute("name", "WEB03")
$newServer.SetAttribute("status", "running")
$cpu = $doc.CreateElement("cpu")
$cpu.InnerText = "25"
$newServer.AppendChild($cpu) | Out-Null

$doc.SelectSingleNode("//servers").AppendChild($newServer) | Out-Null
Write-Host "已添加新服务器 WEB03" -ForegroundColor Green

# 保存修改
$doc.Save("C:\Reports\report.xml")
```

执行结果示例：

```
XML 报告已生成：C:\Reports\report.xml
已修改 WEB01 状态为 maintenance
已添加新服务器 WEB03
```

## XML 与对象转换

```powershell
# 将 PowerShell 对象导出为 XML（Clixml）
$servers = @(
    [PSCustomObject]@{ Name = "SRV01"; IP = "10.0.1.1"; Role = "Web" },
    [PSCustomObject]@{ Name = "SRV02"; IP = "10.0.1.2"; Role = "DB" },
    [PSCustomObject]@{ Name = "SRV03"; IP = "10.0.1.3"; Role = "App" }
)

$servers | Export-Clixml -Path "C:\Data\servers.xml" -Encoding UTF8
Write-Host "对象已导出为 Clixml" -ForegroundColor Green

# 从 Clixml 导入
$imported = Import-Clixml -Path "C:\Data\servers.xml"
$imported | Format-Table -AutoSize

# Clixml 保留类型信息（包括 DateTime、PSCredential 等）
$config = [PSCustomObject]@{
    AppName   = "MyApp"
    Version   = [version]"2.5.0"
    StartTime = Get-Date
    Servers   = $servers
}

$config | Export-Clixml -Path "C:\Data\config.xml"
$restored = Import-Clixml -Path "C:\Data\config.xml"
Write-Host "应用：$($restored.AppName) v$($restored.Version)"
Write-Host "类型保留：Version=$($restored.Version.GetType().Name)"
```

执行结果示例：

```
对象已导出为 Clixml
Name           IP       Role
----           --       ----
SRV01          10.0.1.1 Web
SRV02          10.0.1.2 DB
SRV03          10.0.1.3 App
应用：MyApp v2.5.0
类型保留：Version=Version
```

## 注意事项

1. **XPath 区分大小写**：XML 元素和属性名是大小写敏感的，查询时注意匹配
2. **命名空间**：带命名空间的 XML（如 SOAP）需要使用 `XmlNamespaceManager` 才能用 XPath 查询
3. **编码**：XML 文件可能有各种编码，使用 `Get-Content -Encoding UTF8` 或 `XmlDocument.Load()` 正确处理
4. **大文件**：超大 XML 文件（>100MB）应使用 `XmlReader`（前向只读）代替 `XmlDocument`（全加载到内存）
5. **Clixml 安全**：`Export-Clixml` 可以安全存储 `PSCredential` 对象（DPAPI 加密），但仅限同一台机器解密
6. **修改后保存**：通过点表示法修改 XML 属性后，需要调用 `Save()` 方法持久化到文件
