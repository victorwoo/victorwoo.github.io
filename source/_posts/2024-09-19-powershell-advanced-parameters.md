---
layout: post
date: 2024-09-19 08:00:00
title: "PowerShell 技能连载 - 高级参数处理"
description: PowerTip of the Day - PowerShell Advanced Parameters
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---

## 动态参数机制

```powershell
function Get-EnvironmentData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$EnvironmentName
    )
    
    dynamicparam {
        $paramDictionary = New-Object Management.Automation.RuntimeDefinedParameterDictionary
        
        if ($EnvironmentName -eq 'Production') {
            $attribute = [System.Management.Automation.ParameterAttribute]@{
                Mandatory = $true
                HelpMessage = "生产环境专属参数"
            }
            $param = New-Object Management.Automation.RuntimeDefinedParameter(
                'ProductionKey',
                [string],
                $attribute
            )
            $paramDictionary.Add('ProductionKey', $param)
        }
        return $paramDictionary
    }
}
```

## 参数集应用
```powershell
function Set-SystemConfiguration {
    [CmdletBinding(DefaultParameterSetName='Basic')]
    param(
        [Parameter(ParameterSetName='Basic', Mandatory=$true)]
        [string]$BasicConfig,
        
        [Parameter(ParameterSetName='Advanced', Mandatory=$true)]
        [string]$AdvancedConfig,
        
        [Parameter(ParameterSetName='Advanced')]
        [ValidateRange(1,100)]
        [int]$Priority
    )
    # 根据参数集执行不同逻辑
}
```

## 最佳实践
1. 使用Parameter属性定义清晰的参数关系
2. 为复杂场景设计参数集
3. 通过dynamicparam实现条件参数
4. 保持参数命名的语义清晰

```powershell
function Invoke-CustomOperation {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [ValidateScript({
            if ($_.OperationType -notin 'Read','Write') {
                throw "无效的操作类型"
            }
            $true
        })]
        [object]$InputObject
    )
    # 管道参数处理逻辑
}