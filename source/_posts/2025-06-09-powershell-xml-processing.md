---
layout: post
date: 2025-06-09 08:00:00
updated: 2025-06-09 08:00:00
title: "PowerShell 技能连载 - XML 处理与配置管理"
description: PowerTip of the Day - XML Processing and Configuration Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- xml
- config-management
- data-parsing
---

_适用于 PowerShell 5.1 及以上版本_

XML 是 Windows 生态中最常见的配置格式——从 web.config、app.config 到 NuGet 的 packages.config，从 WIX 安装配置到 MSBuild 项目文件，XML 无处不在。PowerShell 对 XML 有一流的内置支持，`[xml]` 类型加速器可以将 XML 文档直接转换为可导航的对象图，比传统的正则表达式解析简单得多。

本文将讲解 XML 的读取、查询、修改和创建，以及常见的配置文件管理场景。

<!-- more -->

## XML 文档读取

```powershell
# 使用 [xml] 类型加速器解析 XML
$xml = [xml]@"
<configuration>
  <appSettings>
    <add key="AppName" value="MyApp" />
    <add key="Version" value="2.5.0" />
    <add key="Debug" value="true" />
  </appSettings>
  <connectionStrings>
    <add name="Default" connectionString="Server=localhost;Database=mydb;" />
    <add name="Audit" connectionString="Server=audit-db;Database=audit;" />
  </connectionStrings>
  <system.web>
    <compilation debug="true" targetFramework="4.8" />
    <httpRuntime targetFramework="4.8" maxRequestLength="4096" />
  </system.web>
</configuration>
"@

# 通过点号导航 XML 节点
$xml.configuration.appSettings.add | ForEach-Object {
    [PSCustomObject]@{ Key = $_.key; Value = $_.value }
} | Format-Table -AutoSize

# 读取连接字符串
$xml.configuration.connectionStrings.add |
    Select-Object name, connectionString |
    Format-Table -AutoSize

# 从文件加载 XML
$configPath = "C:\Projects\MyApp\web.config"
$config = [xml](Get-Content $configPath)
Write-Host "已加载配置文件：$configPath"

# 读取特定配置值
$appName = $config.configuration.appSettings.add |
    Where-Object { $_.key -eq 'AppName' } |
    Select-Object -ExpandProperty value
Write-Host "应用名称：$appName"
```

执行结果示例：

```
Key     Value
---     -----
AppName MyApp
Version 2.5.0
Debug   true

name    connectionString
----    ----------------
Default Server=localhost;Database=mydb;
Audit   Server=audit-db;Database=audit;

应用名称：MyApp
```

## XPath 查询

XPath 是 XML 的查询语言，适合在复杂 XML 结构中精确查找节点：

```powershell
# 使用 Select-XmlNode 执行 XPath 查询
$nav = $xml.CreateNavigator()

# 查找所有 add 节点
$nodes = $xml.SelectNodes('//add')
$nodes | ForEach-Object { "$($_.key) = $($_.value)" }

# 精确查找特定 key
$debugNode = $xml.SelectSingleNode("//add[@key='Debug']")
Write-Host "Debug 设置：$($debugNode.value)"

# 查找所有带 connectionString 的节点
$connections = $xml.SelectNodes("//connectionStrings/add")
$connections | ForEach-Object {
    Write-Host "  $($_.name): $($_.connectionString)"
}

# 使用 PowerShell 的 XPath 更复杂的查询
$allAttributes = $xml.SelectNodes('//add/@*') |
    ForEach-Object { "$($_.ParentNode.key).$($_.Name) = $($_.Value)" }

$allAttributes | ForEach-Object { Write-Host $_ }
```

执行结果示例：

```
AppName = MyApp
Version = 2.5.0
Debug = true
Debug 设置：true
  Default: Server=localhost;Database=mydb;
  Audit: Server=audit-db;Database=audit;
```

## 修改 XML 配置

```powershell
function Set-AppConfig {
    <#
    .SYNOPSIS
    修改 .NET 应用配置文件
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [hashtable]$Settings,

        [switch]$Backup
    )

    # 备份原文件
    if ($Backup) {
        Copy-Item $Path "$Path.bak" -Force
        Write-Host "已备份：$Path.bak" -ForegroundColor Green
    }

    # 加载 XML
    $xml = [xml](Get-Content $Path)

    # 修改配置值
    foreach ($key in $Settings.Keys) {
        $node = $xml.SelectSingleNode("//appSettings/add[@key='$key']")
        if ($node) {
            $oldValue = $node.value
            $node.value = $Settings[$key]
            Write-Host "$key : $oldValue => $($Settings[$key])" -ForegroundColor Cyan
        } else {
            # 如果 key 不存在，创建新节点
            $newNode = $xml.CreateElement('add')
            $newNode.SetAttribute('key', $key)
            $newNode.SetAttribute('value', $Settings[$key])
            $xml.configuration.appSettings.AppendChild($newNode) | Out-Null
            Write-Host "$key : (新增) => $($Settings[$key])" -ForegroundColor Yellow
        }
    }

    # 保存
    $xml.Save($Path)
    Write-Host "配置已保存：$Path" -ForegroundColor Green
}

# 修改应用配置
Set-AppConfig -Path "C:\Projects\MyApp\web.config" -Backup -Settings @{
    Debug     = 'false'
    LogLevel  = 'Warning'
    CacheTime = '3600'
}
```

执行结果示例：

```
已备份：C:\Projects\MyApp\web.config.bak
Debug : true => false
LogLevel : (新增) => Warning
CacheTime : (新增) => 3600
配置已保存
```

## 创建 XML 文档

```powershell
# 方法一：使用 XmlDocument 创建
$doc = [System.Xml.XmlDocument]::new()
$doc.AppendChild($doc.CreateXmlDeclaration('1.0', 'UTF-8', $null)) | Out-Null

$root = $doc.CreateElement('servers')
$doc.AppendChild($root) | Out-Null

$serverData = @(
    @{ Name = 'WEB-01'; IP = '192.168.1.101'; Role = 'Web'; Enabled = 'true' }
    @{ Name = 'WEB-02'; IP = '192.168.1.102'; Role = 'Web'; Enabled = 'true' }
    @{ Name = 'DB-01';  IP = '192.168.1.201'; Role = 'Database'; Enabled = 'true' }
)

foreach ($srv in $serverData) {
    $serverNode = $doc.CreateElement('server')
    $serverNode.SetAttribute('name', $srv.Name)
    $serverNode.SetAttribute('ip', $srv.IP)
    $serverNode.SetAttribute('role', $srv.Role)
    $serverNode.SetAttribute('enabled', $srv.Enabled)
    $root.AppendChild($serverNode) | Out-Null
}

$doc.Save('C:\Config\servers.xml')
Write-Host "XML 配置文件已创建" -ForegroundColor Green

# 方法二：使用 here-string 快速生成简单 XML
$manifest = @"
<?xml version="1.0" encoding="UTF-8"?>
<application>
    <metadata>
        <name>MyApp</name>
        <version>2.5.0</version>
        <author>DevOps Team</author>
    </metadata>
    <dependencies>
        <dependency name="SqlServer" version="2019+" />
        <dependency name="IIS" version="10.0" />
        <dependency name=".NET" version="8.0" />
    </dependencies>
</application>
"@

Set-Content -Path "C:\Config\manifest.xml" -Value $manifest -Encoding UTF8
```

执行结果示例：

```
XML 配置文件已创建
```

## 注意事项

1. **XML 声明编码**：保存 XML 时使用 `$xml.Save()` 方法会正确处理编码，避免使用 `Out-File` 导致编码问题
2. **命名空间处理**：带命名空间的 XML（如 WSDL、SVG）需要使用 `XmlNamespaceManager` 进行 XPath 查询
3. **大型 XML 文件**：处理大 XML 时使用 `XmlReader`（流式读取）代替 `[xml]`（全部加载到内存）
4. **空节点处理**：XML 中的空节点和自闭合节点 `<node />` 与 `<node></node>` 是等价的
5. **特殊字符转义**：XML 中 `<`, `>`, `&`, `'`, `"` 需要转义，使用 `$xml.CreateTextNode()` 自动处理
6. **配置文件热更新**：修改 IIS 或应用配置后，可能需要重启应用池使配置生效
