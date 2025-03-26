---
layout: post
date: 2024-09-04 08:00:00
title: "PowerShell 技能连载 - XML数据处理实战"
description: "掌握PowerShell中XML解析与生成的核心技巧"
categories:
- powershell
- data-processing
tags:
- powershell
- xml
- automation
---

XML作为结构化数据交换标准，在PowerShell中可通过原生命令实现高效处理。

```powershell
# 读取服务器配置XML
$configPath = 'servers.xml'
[xml]$xmlData = Get-Content $configPath

# 查询所有生产环境服务器
$prodServers = $xmlData.Configuration.Servers.Server | Where-Object {
    $_.Environment -eq 'Production'
}

$prodServers | Format-Table Name, IPAddress, Role
```

### XML生成与修改
1. 创建带命名空间的XML文档：
```powershell
$ns = @{ns='http://schemas.vichamp.com/config'}
$xmlWriter = New-Object System.Xml.XmlTextWriter('new_config.xml',$null)
$xmlWriter.WriteStartDocument()
$xmlWriter.WriteStartElement('ns','Configuration','http://schemas.vichamp.com/config')

$xmlWriter.WriteStartElement('Server') 
$xmlWriter.WriteAttributeString('Name','web01')
$xmlWriter.WriteElementString('IP','192.168.1.101')
$xmlWriter.WriteEndElement()

$xmlWriter.WriteEndDocument()
$xmlWriter.Close()
```

2. 使用Select-Xml进行复杂查询：
```powershell
$result = Select-Xml -Path $configPath -XPath "//Server[@Role='Database']"
$result.Node | ForEach-Object {
    [PSCustomObject]@{
        Cluster = $_.ParentNode.Name
        ServerName = $_.Name
        Version = $_.GetAttribute('Version')
    }
}
```

最佳实践：
- 使用强类型[xml]加速处理
- 通过XPath实现精准查询
- 合理处理XML命名空间
- 使用XMLTextWriter生成合规文档