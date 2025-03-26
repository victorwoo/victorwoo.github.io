---
layout: post
date: 2025-02-28 08:00:00
title: "PowerShell 技能连载 - 基础设施即代码实践"
description: PowerTip of the Day - PowerShell Infrastructure as Code Practices
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在现代IT运维领域，基础设施即代码(Infrastructure as Code, IaC)已成为标准实践。本文将介绍如何使用PowerShell实现高效的IaC解决方案。

首先，让我们创建一个基础环境配置定义函数：

```powershell
# 创建环境配置定义函数
function New-InfrastructureDefinition {
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentName,
        
        [Parameter(Mandatory)]
        [string]$OutputPath,
        
        [string]$Description = "",
        
        [ValidateSet("Development", "Testing", "Staging", "Production")]
        [string]$EnvironmentType = "Development",
        
        [switch]$Force
    )
    
    try {
        # 创建基础环境配置对象
        $infrastructureDefinition = [PSCustomObject]@{
            EnvironmentName = $EnvironmentName
            EnvironmentType = $EnvironmentType
            Description = $Description
            CreatedBy = $env:USERNAME
            CreatedOn = Get-Date
            Version = "1.0"
            Resources = @{
                VirtualMachines = @()
                NetworkResources = @()
                StorageResources = @()
                SecurityResources = @()
                DatabaseResources = @()
                ApplicationResources = @()
            }
            Dependencies = @{}
            DeploymentOrder = @()
            State = "Draft"
            Metadata = @{}
        }
        
        # 创建JSON定义文件
        $definitionFile = Join-Path -Path $OutputPath -ChildPath "$EnvironmentName.json"
        
        if ((Test-Path -Path $definitionFile) -and (-not $Force)) {
            throw "定义文件 '$definitionFile' 已存在。使用 -Force 参数覆盖现有文件。"
        }
        
        # 创建输出目录（如果不存在）
        if (-not (Test-Path -Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        # 保存定义
        $infrastructureDefinition | ConvertTo-Json -Depth 10 | Out-File -FilePath $definitionFile -Encoding UTF8
        
        Write-Host "已创建基础设施定义: $definitionFile" -ForegroundColor Green
        return $infrastructureDefinition
    }
    catch {
        Write-Error "创建基础设施定义时出错: $_"
    }
}
```

接下来，添加虚拟机资源定义：

```powershell
# 添加虚拟机资源定义
function Add-VMResource {
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSObject]$InfrastructureDefinition,
        
        [Parameter(Mandatory)]
        [string]$VMName,
        
        [Parameter(Mandatory)]
        [string]$Size,
        
        [string]$OSType = "Windows",
        
        [string]$OSVersion = "2022-Datacenter",
        
        [string]$NetworkName,
        
        [string]$SubnetName,
        
        [hashtable]$Tags = @{},
        
        [string[]]$DependsOn = @(),
        
        [hashtable]$Properties = @{},
        
        [string]$OutputPath
    )
    
    process {
        try {
            # 创建VM定义
            $vmResource = [PSCustomObject]@{
                Name = $VMName
                ResourceType = "VirtualMachine"
                Size = $Size
                OSType = $OSType
                OSVersion = $OSVersion
                NetworkName = $NetworkName
                SubnetName = $SubnetName
                Tags = $Tags
                Properties = $Properties
                DependsOn = $DependsOn
                ResourceId = [guid]::NewGuid().ToString()
                CreatedOn = Get-Date
            }
            
            # 添加到定义中
            $InfrastructureDefinition.Resources.VirtualMachines += $vmResource
            
            # 添加依赖关系
            foreach ($dependency in $DependsOn) {
                if (-not $InfrastructureDefinition.Dependencies.ContainsKey($VMName)) {
                    $InfrastructureDefinition.Dependencies[$VMName] = @()
                }
                $InfrastructureDefinition.Dependencies[$VMName] += $dependency
            }
            
            # 如果提供了输出路径，更新定义文件
            if ($OutputPath) {
                $definitionFile = Join-Path -Path $OutputPath -ChildPath "$($InfrastructureDefinition.EnvironmentName).json"
                $InfrastructureDefinition | ConvertTo-Json -Depth 10 | Out-File -FilePath $definitionFile -Encoding UTF8
                Write-Host "已更新基础设施定义: $definitionFile" -ForegroundColor Green
            }
            
            return $InfrastructureDefinition
        }
        catch {
            Write-Error "添加虚拟机资源定义时出错: $_"
        }
    }
}
```

添加网络资源定义：

```powershell
# 添加网络资源定义
function Add-NetworkResource {
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSObject]$InfrastructureDefinition,
        
        [Parameter(Mandatory)]
        [string]$NetworkName,
        
        [Parameter(Mandatory)]
        [string]$AddressSpace,
        
        [Parameter(Mandatory)]
        [PSObject[]]$Subnets,
        
        [bool]$EnableDnsSupport = $true,
        
        [hashtable]$Tags = @{},
        
        [string[]]$DependsOn = @(),
        
        [hashtable]$Properties = @{},
        
        [string]$OutputPath
    )
    
    process {
        try {
            # 创建网络定义
            $networkResource = [PSCustomObject]@{
                Name = $NetworkName
                ResourceType = "VirtualNetwork"
                AddressSpace = $AddressSpace
                Subnets = $Subnets
                EnableDnsSupport = $EnableDnsSupport
                Tags = $Tags
                Properties = $Properties
                DependsOn = $DependsOn
                ResourceId = [guid]::NewGuid().ToString()
                CreatedOn = Get-Date
            }
            
            # 添加到定义中
            $InfrastructureDefinition.Resources.NetworkResources += $networkResource
            
            # 添加依赖关系
            foreach ($dependency in $DependsOn) {
                if (-not $InfrastructureDefinition.Dependencies.ContainsKey($NetworkName)) {
                    $InfrastructureDefinition.Dependencies[$NetworkName] = @()
                }
                $InfrastructureDefinition.Dependencies[$NetworkName] += $dependency
            }
            
            # 如果提供了输出路径，更新定义文件
            if ($OutputPath) {
                $definitionFile = Join-Path -Path $OutputPath -ChildPath "$($InfrastructureDefinition.EnvironmentName).json"
                $InfrastructureDefinition | ConvertTo-Json -Depth 10 | Out-File -FilePath $definitionFile -Encoding UTF8
                Write-Host "已更新基础设施定义: $definitionFile" -ForegroundColor Green
            }
            
            return $InfrastructureDefinition
        }
        catch {
            Write-Error "添加网络资源定义时出错: $_"
        }
    }
}
```

生成部署顺序：

```powershell
# 生成资源部署顺序
function Set-DeploymentOrder {
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSObject]$InfrastructureDefinition,
        
        [switch]$Validate,
        
        [string]$OutputPath
    )
    
    process {
        try {
            # 创建依赖图
            $dependencyGraph = @{}
            $resourceList = @()
            
            # 收集所有资源
            foreach ($vmResource in $InfrastructureDefinition.Resources.VirtualMachines) {
                $resourceList += $vmResource.Name
                $dependencyGraph[$vmResource.Name] = $vmResource.DependsOn
            }
            
            foreach ($netResource in $InfrastructureDefinition.Resources.NetworkResources) {
                $resourceList += $netResource.Name
                $dependencyGraph[$netResource.Name] = $netResource.DependsOn
            }
            
            # 添加其他资源类型...
            
            # 检测循环依赖
            $visited = @{}
            $recStack = @{}
            
            function Test-CyclicDependency {
                param([string]$Node)
                
                $visited[$Node] = $true
                $recStack[$Node] = $true
                
                foreach ($neighbor in $dependencyGraph[$Node]) {
                    if (-not $visited.ContainsKey($neighbor)) {
                        if (Test-CyclicDependency -Node $neighbor) {
                            return $true
                        }
                    }
                    elseif ($recStack.ContainsKey($neighbor)) {
                        return $true
                    }
                }
                
                $recStack.Remove($Node)
                return $false
            }
            
            foreach ($resource in $resourceList) {
                if (-not $visited.ContainsKey($resource)) {
                    if (Test-CyclicDependency -Node $resource) {
                        throw "检测到循环依赖关系。无法确定部署顺序。"
                    }
                }
            }
            
            # 拓扑排序
            $visited = @{}
            $deploymentOrder = [System.Collections.ArrayList]::new()
            
            function Sort-Topology {
                param([string]$Node)
                
                $visited[$Node] = $true
                
                foreach ($neighbor in $dependencyGraph[$Node]) {
                    if (-not $visited.ContainsKey($neighbor)) {
                        Sort-Topology -Node $neighbor
                    }
                }
                
                $deploymentOrder.Add($Node) | Out-Null
            }
            
            foreach ($resource in $resourceList) {
                if (-not $visited.ContainsKey($resource)) {
                    Sort-Topology -Node $resource
                }
            }
            
            # 反转列表，因为我们需要先部署没有依赖的资源
            [Array]::Reverse($deploymentOrder)
            
            # 更新部署顺序
            $InfrastructureDefinition.DeploymentOrder = $deploymentOrder
            
            # 验证部署顺序
            if ($Validate) {
                Write-Host "验证部署顺序..." -ForegroundColor Yellow
                $deploymentSet = @{}
                $isValid = $true
                
                foreach ($resource in $deploymentOrder) {
                    foreach ($dependency in $dependencyGraph[$resource]) {
                        if (-not $deploymentSet.ContainsKey($dependency)) {
                            Write-Host "错误: 资源 '$resource' 依赖于 '$dependency'，但该资源尚未部署。" -ForegroundColor Red
                            $isValid = $false
                        }
                    }
                    $deploymentSet[$resource] = $true
                }
                
                if ($isValid) {
                    Write-Host "部署顺序有效。" -ForegroundColor Green
                } else {
                    throw "部署顺序无效。请检查资源依赖关系。"
                }
            }
            
            # 如果提供了输出路径，更新定义文件
            if ($OutputPath) {
                $definitionFile = Join-Path -Path $OutputPath -ChildPath "$($InfrastructureDefinition.EnvironmentName).json"
                $InfrastructureDefinition | ConvertTo-Json -Depth 10 | Out-File -FilePath $definitionFile -Encoding UTF8
                Write-Host "已更新基础设施定义: $definitionFile" -ForegroundColor Green
            }
            
            return $InfrastructureDefinition
        }
        catch {
            Write-Error "生成部署顺序时出错: $_"
        }
    }
}
```

部署基础设施资源：

```powershell
# 部署基础设施资源
function Deploy-InfrastructureResource {
    param(
        [Parameter(Mandatory)]
        [PSObject]$Resource,
        
        [Parameter(Mandatory)]
        [PSObject]$InfrastructureDefinition,
        
        [switch]$WhatIf,
        
        [PSObject]$DeploymentContext = @{}
    )
    
    try {
        $resourceName = $Resource.Name
        $resourceType = $Resource.ResourceType
        
        Write-Host "开始部署资源: $resourceName (类型: $resourceType)" -ForegroundColor Cyan
        
        switch ($resourceType) {
            "VirtualMachine" {
                if ($WhatIf) {
                    Write-Host "[WhatIf] 将创建虚拟机 '$resourceName' (大小: $($Resource.Size), OS: $($Resource.OSType)-$($Resource.OSVersion))" -ForegroundColor Yellow
                } else {
                    # 这里是虚拟机部署的实际代码
                    # 示例: 使用 Azure PowerShell 模块创建虚拟机
                    Write-Host "正在创建虚拟机 '$resourceName'..." -ForegroundColor White
                    
                    # 模拟部署
                    Start-Sleep -Seconds 2
                    
                    # 返回部署结果
                    $deploymentResult = [PSCustomObject]@{
                        ResourceName = $resourceName
                        ResourceType = $resourceType
                        Status = "Success"
                        DeploymentId = [guid]::NewGuid().ToString()
                        DeploymentTime = Get-Date
                        Properties = @{
                            IPAddress = "10.0.0.$((Get-Random -Minimum 2 -Maximum 255))"
                            FQDN = "$resourceName.example.com"
                        }
                    }
                    
                    Write-Host "虚拟机 '$resourceName' 部署成功" -ForegroundColor Green
                    return $deploymentResult
                }
            }
            "VirtualNetwork" {
                if ($WhatIf) {
                    Write-Host "[WhatIf] 将创建虚拟网络 '$resourceName' (地址空间: $($Resource.AddressSpace))" -ForegroundColor Yellow
                } else {
                    # 这里是虚拟网络部署的实际代码
                    Write-Host "正在创建虚拟网络 '$resourceName'..." -ForegroundColor White
                    
                    # 模拟部署
                    Start-Sleep -Seconds 1
                    
                    # 返回部署结果
                    $deploymentResult = [PSCustomObject]@{
                        ResourceName = $resourceName
                        ResourceType = $resourceType
                        Status = "Success"
                        DeploymentId = [guid]::NewGuid().ToString()
                        DeploymentTime = Get-Date
                        Properties = @{
                            AddressSpace = $Resource.AddressSpace
                            SubnetCount = $Resource.Subnets.Count
                        }
                    }
                    
                    Write-Host "虚拟网络 '$resourceName' 部署成功" -ForegroundColor Green
                    return $deploymentResult
                }
            }
            default {
                Write-Warning "不支持的资源类型: $resourceType"
            }
        }
        
        if ($WhatIf) {
            return [PSCustomObject]@{
                ResourceName = $resourceName
                ResourceType = $resourceType
                Status = "WhatIf"
            }
        }
    }
    catch {
        Write-Error "部署资源 '$resourceName' 时出错: $_"
        return [PSCustomObject]@{
            ResourceName = $resourceName
            ResourceType = $resourceType
            Status = "Failed"
            Error = $_.ToString()
        }
    }
}
```

执行完整基础设施部署：

```powershell
# 部署完整基础设施
function Deploy-Infrastructure {
    param(
        [Parameter(Mandatory)]
        [PSObject]$InfrastructureDefinition,
        
        [switch]$WhatIf,
        
        [switch]$Force,
        
        [string]$DeploymentLogPath,
        
        [scriptblock]$OnSuccessAction,
        
        [scriptblock]$OnFailureAction
    )
    
    try {
        $environmentName = $InfrastructureDefinition.EnvironmentName
        $deploymentResults = @()
        $deploymentContext = @{}
        $deploymentStart = Get-Date
        $deploymentSuccess = $true
        
        Write-Host "开始部署环境: $environmentName" -ForegroundColor Cyan
        
        # 检查是否有部署顺序
        if ($InfrastructureDefinition.DeploymentOrder.Count -eq 0) {
            Write-Warning "部署顺序为空。正在尝试生成部署顺序..."
            $InfrastructureDefinition = Set-DeploymentOrder -InfrastructureDefinition $InfrastructureDefinition -Validate
        }
        
        # 创建资源映射
        $resourceMap = @{}
        foreach ($vmResource in $InfrastructureDefinition.Resources.VirtualMachines) {
            $resourceMap[$vmResource.Name] = $vmResource
        }
        
        foreach ($netResource in $InfrastructureDefinition.Resources.NetworkResources) {
            $resourceMap[$netResource.Name] = $netResource
        }
        
        # 按照部署顺序部署资源
        foreach ($resourceName in $InfrastructureDefinition.DeploymentOrder) {
            $resource = $resourceMap[$resourceName]
            
            if (-not $resource) {
                Write-Warning "资源 '$resourceName' 在部署顺序中但未找到资源定义。跳过。"
                continue
            }
            
            $result = Deploy-InfrastructureResource -Resource $resource -InfrastructureDefinition $InfrastructureDefinition -WhatIf:$WhatIf -DeploymentContext $deploymentContext
            $deploymentResults += $result
            
            # 如果部署失败且未强制继续，则终止部署
            if ($result.Status -eq "Failed" -and -not $Force) {
                Write-Error "资源 '$resourceName' 部署失败。终止部署。"
                $deploymentSuccess = $false
                break
            }
            
            # 更新部署上下文
            if ($result.Status -eq "Success") {
                $deploymentContext[$resourceName] = $result
            }
        }
        
        $deploymentEnd = Get-Date
        $deploymentDuration = $deploymentEnd - $deploymentStart
        
        # 生成部署摘要
        $deploymentSummary = [PSCustomObject]@{
            EnvironmentName = $environmentName
            StartTime = $deploymentStart
            EndTime = $deploymentEnd
            Duration = $deploymentDuration
            Status = if ($deploymentSuccess) { "Success" } else { "Failed" }
            ResourceCount = $deploymentResults.Count
            SuccessCount = ($deploymentResults | Where-Object { $_.Status -eq "Success" }).Count
            FailedCount = ($deploymentResults | Where-Object { $_.Status -eq "Failed" }).Count
            WhatIfCount = ($deploymentResults | Where-Object { $_.Status -eq "WhatIf" }).Count
            DetailedResults = $deploymentResults
        }
        
        # 保存部署日志
        if ($DeploymentLogPath) {
            $logFile = Join-Path -Path $DeploymentLogPath -ChildPath "Deployment_$environmentName`_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
            
            # 创建目录（如果不存在）
            if (-not (Test-Path -Path $DeploymentLogPath)) {
                New-Item -Path $DeploymentLogPath -ItemType Directory -Force | Out-Null
            }
            
            $deploymentSummary | ConvertTo-Json -Depth 10 | Out-File -FilePath $logFile -Encoding UTF8
            Write-Host "部署日志已保存至: $logFile" -ForegroundColor Green
        }
        
        # 部署成功或失败时执行的操作
        if ($deploymentSuccess -and $OnSuccessAction) {
            & $OnSuccessAction -DeploymentSummary $deploymentSummary
        }
        elseif (-not $deploymentSuccess -and $OnFailureAction) {
            & $OnFailureAction -DeploymentSummary $deploymentSummary
        }
        
        # 输出部署摘要
        Write-Host "部署摘要:" -ForegroundColor Cyan
        Write-Host "  环境: $environmentName" -ForegroundColor White
        Write-Host "  状态: $($deploymentSummary.Status)" -ForegroundColor $(if ($deploymentSummary.Status -eq "Success") { "Green" } else { "Red" })
        Write-Host "  持续时间: $($deploymentDuration.TotalMinutes) 分钟" -ForegroundColor White
        Write-Host "  资源总数: $($deploymentSummary.ResourceCount)" -ForegroundColor White
        Write-Host "  成功: $($deploymentSummary.SuccessCount)" -ForegroundColor Green
        Write-Host "  失败: $($deploymentSummary.FailedCount)" -ForegroundColor $(if ($deploymentSummary.FailedCount -gt 0) { "Red" } else { "White" })
        Write-Host "  WhatIf: $($deploymentSummary.WhatIfCount)" -ForegroundColor Yellow
        
        return $deploymentSummary
    }
    catch {
        Write-Error "部署环境 '$environmentName' 时出错: $_"
    }
}
```

现在，让我们看一个使用示例：

```powershell
# 定义输出路径
$outputPath = "C:\IaC\Definitions"

# 创建一个新的环境定义
$envDef = New-InfrastructureDefinition -EnvironmentName "DevTest" -EnvironmentType "Development" -OutputPath $outputPath -Description "开发测试环境"

# 添加网络资源
$subnets = @(
    [PSCustomObject]@{ Name = "Frontend"; AddressPrefix = "10.0.1.0/24" },
    [PSCustomObject]@{ Name = "Backend"; AddressPrefix = "10.0.2.0/24" },
    [PSCustomObject]@{ Name = "Database"; AddressPrefix = "10.0.3.0/24" }
)

$envDef = Add-NetworkResource -InfrastructureDefinition $envDef -NetworkName "DevVNet" -AddressSpace "10.0.0.0/16" -Subnets $subnets -OutputPath $outputPath

# 添加虚拟机资源
$envDef = Add-VMResource -InfrastructureDefinition $envDef -VMName "WebServer01" -Size "Standard_B2s" -OSType "Windows" -OSVersion "2022-Datacenter" -NetworkName "DevVNet" -SubnetName "Frontend" -DependsOn @("DevVNet") -OutputPath $outputPath

$envDef = Add-VMResource -InfrastructureDefinition $envDef -VMName "AppServer01" -Size "Standard_B2s" -OSType "Windows" -OSVersion "2022-Datacenter" -NetworkName "DevVNet" -SubnetName "Backend" -DependsOn @("DevVNet", "WebServer01") -OutputPath $outputPath

$envDef = Add-VMResource -InfrastructureDefinition $envDef -VMName "DbServer01" -Size "Standard_B2ms" -OSType "Windows" -OSVersion "2022-Datacenter" -NetworkName "DevVNet" -SubnetName "Database" -DependsOn @("DevVNet") -OutputPath $outputPath

# 生成部署顺序
$envDef = Set-DeploymentOrder -InfrastructureDefinition $envDef -Validate -OutputPath $outputPath

# 预览部署（WhatIf）
$deploymentPreview = Deploy-Infrastructure -InfrastructureDefinition $envDef -WhatIf -DeploymentLogPath "C:\IaC\Logs"

# 实际部署
$deploymentResult = Deploy-Infrastructure -InfrastructureDefinition $envDef -DeploymentLogPath "C:\IaC\Logs"
```

这些PowerShell函数提供了一个强大的基础设施即代码解决方案，可以帮助自动化环境部署流程。随着基础设施复杂性的增加，您可以扩展这些函数来支持更多的资源类型和部署场景。结合版本控制系统如Git，这种方法能够确保环境配置的一致性和可重复性，从而提高IT运维的效率和可靠性。 