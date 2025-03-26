---
layout: post
date: 2025-02-07 08:00:00
title: "PowerShell 技能连载 - JSON 处理技巧"
description: PowerTip of the Day - PowerShell JSON Processing Tips
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中处理 JSON 数据是一项常见任务，本文将介绍一些实用的 JSON 处理技巧。

首先，让我们看看基本的 JSON 操作：

```powershell
# 创建 JSON 信息获取函数
function Get-JSONInfo {
    param(
        [string]$JSONPath
    )
    
    try {
        $json = Get-Content $JSONPath -Raw | ConvertFrom-Json
        
        return [PSCustomObject]@{
            FileName = Split-Path $JSONPath -Leaf
            FileSize = (Get-Item $JSONPath).Length
            PropertyCount = ($json.PSObject.Properties | Measure-Object).Count
            IsArray = $json -is [Array]
            Depth = Get-JSONDepth $json
        }
    }
    catch {
        Write-Host "获取 JSON 信息失败：$_"
    }
}

# 获取 JSON 深度
function Get-JSONDepth {
    param($Object)
    
    if ($Object -is [Array]) {
        return 1 + ($Object | ForEach-Object { Get-JSONDepth $_ } | Measure-Object -Maximum).Maximum
    }
    elseif ($Object -is [PSCustomObject]) {
        return 1 + ($Object.PSObject.Properties | ForEach-Object { Get-JSONDepth $_.Value } | Measure-Object -Maximum).Maximum
    }
    return 0
}
```

JSON 数据验证：

```powershell
# 创建 JSON 数据验证函数
function Test-JSONData {
    param(
        [string]$JSONPath,
        [string]$SchemaPath
    )
    
    try {
        $json = Get-Content $JSONPath -Raw
        $schema = Get-Content $SchemaPath -Raw
        
        # 使用 Newtonsoft.Json 进行验证
        Add-Type -Path "Newtonsoft.Json.dll"
        $validator = [Newtonsoft.Json.Schema.JSchema]::Parse($schema)
        $reader = [Newtonsoft.Json.JsonTextReader]::new([System.IO.StringReader]::new($json))
        
        $valid = $validator.IsValid($reader)
        $errors = $validator.Errors
        
        return [PSCustomObject]@{
            IsValid = $valid
            Errors = $errors
        }
    }
    catch {
        Write-Host "验证失败：$_"
    }
}
```

JSON 数据转换：

```powershell
# 创建 JSON 数据转换函数
function Convert-JSONData {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [ValidateSet("xml", "csv", "yaml")]
        [string]$TargetFormat,
        [hashtable]$Options
    )
    
    try {
        $json = Get-Content $InputPath -Raw | ConvertFrom-Json
        
        switch ($TargetFormat) {
            "xml" {
                $xml = [System.Xml.XmlDocument]::new()
                $root = $xml.CreateElement("root")
                $xml.AppendChild($root) | Out-Null
                
                ConvertTo-XML $json $root $xml
                $xml.Save($OutputPath)
            }
            "csv" {
                if ($json -is [Array]) {
                    $json | ConvertTo-Csv -NoTypeInformation | Out-File $OutputPath
                }
                else {
                    [PSCustomObject]@{ $json.PSObject.Properties.Name = $json.PSObject.Properties.Value } |
                    ConvertTo-Csv -NoTypeInformation | Out-File $OutputPath
                }
            }
            "yaml" {
                # 使用 YamlDotNet 进行转换
                Add-Type -Path "YamlDotNet.dll"
                $yaml = [YamlDotNet.Serialization.Serializer]::new().Serialize($json)
                $yaml | Out-File $OutputPath
            }
        }
        
        Write-Host "数据转换完成：$OutputPath"
    }
    catch {
        Write-Host "转换失败：$_"
    }
}

# 将 JSON 对象转换为 XML
function ConvertTo-XML {
    param($Object, $Parent, $Document)
    
    if ($Object -is [Array]) {
        foreach ($item in $Object) {
            $element = $Document.CreateElement("item")
            $Parent.AppendChild($element) | Out-Null
            ConvertTo-XML $item $element $Document
        }
    }
    elseif ($Object -is [PSCustomObject]) {
        foreach ($property in $Object.PSObject.Properties) {
            $element = $Document.CreateElement($property.Name)
            $Parent.AppendChild($element) | Out-Null
            ConvertTo-XML $property.Value $element $Document
        }
    }
    else {
        $Parent.InnerText = $Object.ToString()
    }
}
```

JSON 数据查询：

```powershell
# 创建 JSON 数据查询函数
function Search-JSONData {
    param(
        [string]$JSONPath,
        [string]$Query,
        [ValidateSet("exact", "contains", "regex")]
        [string]$MatchType = "contains"
    )
    
    try {
        $json = Get-Content $JSONPath -Raw | ConvertFrom-Json
        $results = @()
        
        function Search-Object {
            param($Object, $Path = "")
            
            if ($Object -is [Array]) {
                for ($i = 0; $i -lt $Object.Count; $i++) {
                    Search-Object $Object[$i] "$Path[$i]"
                }
            }
            elseif ($Object -is [PSCustomObject]) {
                foreach ($property in $Object.PSObject.Properties) {
                    $newPath = if ($Path) { "$Path.$($property.Name)" } else { $property.Name }
                    Search-Object $property.Value $newPath
                }
            }
            else {
                $value = $Object.ToString()
                $matched = switch ($MatchType) {
                    "exact" { $value -eq $Query }
                    "contains" { $value -like "*$Query*" }
                    "regex" { $value -match $Query }
                }
                
                if ($matched) {
                    $results += [PSCustomObject]@{
                        Path = $Path
                        Value = $value
                    }
                }
            }
        }
        
        Search-Object $json
        return $results
    }
    catch {
        Write-Host "查询失败：$_"
    }
}
```

这些技巧将帮助您更有效地处理 JSON 数据。记住，在处理 JSON 时，始终要注意数据的完整性和格式的正确性。同时，建议在处理大型 JSON 文件时使用流式处理方式，以提高性能。 