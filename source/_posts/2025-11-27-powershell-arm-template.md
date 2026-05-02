---
layout: post
date: 2025-11-27 08:00:00
updated: 2025-11-27 08:00:00
title: "PowerShell 技能连载 - ARM 模板部署"
description: PowerTip of the Day - ARM Template Deployment in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- arm-template
- azure
- infrastructure-as-code
- deployment
---

_适用于 PowerShell 5.1 及以上版本_

Azure Resource Manager（ARM）模板是微软 Azure 平台原生的基础设施即代码（Infrastructure as Code，IaC）解决方案。通过 JSON 格式声明式地定义云资源，团队可以在版本控制系统中追踪每一次基础设施变更，实现与应用代码同等严谨的发布流程。

在实际运维中，手动点击 Azure 门户创建资源既容易出错，也难以在多环境间保持一致。ARM 模板配合 PowerShell 的 `Az` 模块，能够一键完成从资源组、虚拟网络到虚拟机的完整环境搭建，并且天然支持幂等部署——无论执行多少次，最终状态始终一致。

本文将从零开始演示如何用 PowerShell 编写、参数化和部署 ARM 模板，涵盖模板验证、增量部署以及多环境参数管理等常见场景。

<!-- more -->

## 基础：部署一个简单的 ARM 模板

我们先从最简单的存储账户部署开始。ARM 模板是一个 JSON 文件，包含 `$schema`、`contentVersion`、`resources` 等固定节。下面是一个最小化的存储账户模板和对应的参数文件。

首先创建模板文件：

```powershell
$templateJson = @'
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "storageAccountName": {
      "type": "string",
      "metadata": {
        "description": "存储账户名称，全局唯一"
      }
    },
    "location": {
      "type": "string",
      "defaultValue": "[resourceGroup().location]",
      "metadata": {
        "description": "资源位置，默认为资源组所在区域"
      }
    }
  },
  "resources": [
    {
      "type": "Microsoft.Storage/storageAccounts",
      "apiVersion": "2023-05-01",
      "name": "[parameters('storageAccountName')]",
      "location": "[parameters('location')]",
      "sku": {
        "name": "Standard_LRS"
      },
      "kind": "StorageV2"
    }
  ]
}
'@

$templateJson | Set-Content -Path '.\storage-template.json' -Encoding UTF8
```

然后创建参数文件，为不同环境提供不同的值：

```powershell
$parametersJson = @'
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "storageAccountName": {
      "value": "stpowershelldemo001"
    }
  }
}
'@

$parametersJson | Set-Content -Path '.\storage-parameters.json' -Encoding UTF8
```

执行部署：

```powershell
# 连接到 Azure（如果尚未登录）
Connect-AzAccount

# 选择目标订阅
$context = Get-AzSubscription | Where-Object { $_.Name -eq 'MySubscription' }
Set-AzContext -SubscriptionId $context.Id

# 创建资源组
New-AzResourceGroup -Name 'rg-demo' -Location 'eastasia' -Force

# 部署 ARM 模板
$deployment = New-AzResourceGroupDeployment `
    -ResourceGroupName 'rg-demo' `
    -TemplateFile '.\storage-template.json' `
    -TemplateParameterFile '.\storage-parameters.json' `
    -Mode Incremental

$deployment
```

执行结果示例：

```text
DeploymentName          : storage-template
ResourceGroupName       : rg-demo
ProvisioningState       : Succeeded
Timestamp               : 2025-11-27 08:15:32
Mode                    : Incremental
TemplateParameterString :
  Name                  Type    Value
  ====================  ======  ==========
  storageAccountName    String  stpowershelldemo001
  location              String  eastasia
```

`ProvisioningState` 为 `Succeeded` 表示部署成功。`-Mode Incremental` 意味着模板中定义的资源会被创建或更新，但不会删除资源组中已有的其他资源。

## 进阶：参数化多环境部署

在企业实践中，开发、测试、生产三套环境的配置各不相同。与其维护多份参数文件，不如用 PowerShell 的哈希表动态生成参数，实现一套模板走天下。

下面我们构建一个包含虚拟网络和子网的模板，并用 PowerShell 哈希表为不同环境注入参数：

```powershell
# 定义环境配置
$environments = @{
    dev = @{
        ResourceGroupName = 'rg-dev-network'
        Location          = 'eastasia'
        VnetName          = 'vnet-dev'
        AddressPrefix     = '10.0.0.0/16'
        SubnetName        = 'snet-dev-default'
        SubnetPrefix      = '10.0.1.0/24'
    }
    staging = @{
        ResourceGroupName = 'rg-staging-network'
        Location          = 'eastasia'
        VnetName          = 'vnet-staging'
        AddressPrefix     = '10.1.0.0/16'
        SubnetName        = 'snet-staging-default'
        SubnetPrefix      = '10.1.1.0/24'
    }
    prod = @{
        ResourceGroupName = 'rg-prod-network'
        Location          = 'eastasia'
        VnetName          = 'vnet-prod'
        AddressPrefix     = '10.2.0.0/16'
        SubnetName        = 'snet-prod-default'
        SubnetPrefix      = '10.2.1.0/24'
    }
}

# 目标环境
$envName = 'dev'
$envConfig = $environments[$envName]

# 构建模板参数哈希表
$templateParams = @{
    vnetName      = $envConfig.VnetName
    addressPrefix = $envConfig.AddressPrefix
    subnetName    = $envConfig.SubnetName
    subnetPrefix  = $envConfig.SubnetPrefix
    location      = $envConfig.Location
}

Write-Host "正在部署 [$envName] 环境的网络资源..." -ForegroundColor Cyan
Write-Host "  资源组: $($envConfig.ResourceGroupName)"
Write-Host "  VNet:   $($envConfig.VnetName) ($($envConfig.AddressPrefix))"
Write-Host "  Subnet: $($envConfig.SubnetName) ($($envConfig.SubnetPrefix))"

# 确保资源组存在
New-AzResourceGroup -Name $envConfig.ResourceGroupName `
    -Location $envConfig.Location -Force | Out-Null

# 使用哈希表参数直接部署（无需参数文件）
$result = New-AzResourceGroupDeployment `
    -ResourceGroupName $envConfig.ResourceGroupName `
    -TemplateFile '.\vnet-template.json' `
    @templateParams `
    -Mode Incremental

Write-Host "部署状态: $($result.ProvisioningState)" -ForegroundColor Green
```

执行结果示例：

```text
正在部署 [dev] 环境的网络资源...
  资源组: rg-dev-network
  VNet:   vnet-dev (10.0.0.0/16)
  Subnet: snet-dev-default (10.0.1.0/24)
部署状态: Succeeded
```

这种方式的妙处在于切换环境只需修改 `$envName` 变量，所有配置自动跟随变化。配合 CI/CD 管道中的环境变量，可以轻松实现自动化多环境发布。

## 高级：模板验证与批量部署

在真正执行部署之前，先用 `Test-AzResourceGroupDeployment` 进行干跑验证，能够在不创建任何资源的情况下检查模板语法和参数是否正确。这在批量部署多个关联模板时尤其重要，可以提前发现错误，避免半途而废。

下面展示一个完整的批量部署流程，包含预验证、逐模板部署和结果汇总：

```powershell
# 定义需要部署的模板列表
$templates = @(
    @{
        Name     = '网络基础'
        Template = '.\templates\vnet.json'
        Params   = '.\parameters\vnet.dev.json'
    }
    @{
        Name     = '存储账户'
        Template = '.\templates\storage.json'
        Params   = '.\parameters\storage.dev.json'
    }
    @{
        Name     = '虚拟机'
        Template = '.\templates\vm.json'
        Params   = '.\parameters\vm.dev.json'
    }
)

$resourceGroupName = 'rg-dev-infra'
$deploymentResults = @()

# 第一步：批量验证所有模板
Write-Host '=' * 60 -ForegroundColor DarkGray
Write-Host '第一阶段：模板验证' -ForegroundColor Cyan
Write-Host '=' * 60 -ForegroundColor DarkGray

$allValid = $true

foreach ($item in $templates) {
    Write-Host "`n验证: $($item.Name)..." -NoNewline

    $errorMessages = @()
    $testResult = Test-AzResourceGroupDeployment `
        -ResourceGroupName $resourceGroupName `
        -TemplateFile $item.Template `
        -TemplateParameterFile $item.Params `
        -ErrorAction SilentlyContinue `
        -ErrorVariable errorMessages

    if ($errorMessages.Count -eq 0) {
        Write-Host ' 通过' -ForegroundColor Green
    } else {
        Write-Host ' 失败' -ForegroundColor Red
        foreach ($msg in $errorMessages) {
            Write-Host "  错误: $msg" -ForegroundColor Red
        }
        $allValid = $false
    }
}

# 第二步：如果全部通过，执行批量部署
if ($allValid) {
    Write-Host "`n$('=' * 60)" -ForegroundColor DarkGray
    Write-Host '第二阶段：执行部署' -ForegroundColor Cyan
    Write-Host '=' * 60 -ForegroundColor DarkGray

    foreach ($item in $templates) {
        Write-Host "`n部署: $($item.Name)..." -ForegroundColor Yellow

        $deployResult = New-AzResourceGroupDeployment `
            -ResourceGroupName $resourceGroupName `
            -TemplateFile $item.Template `
            -TemplateParameterFile $item.Params `
            -Mode Incremental

        $deploymentResults += [PSCustomObject]@{
            Name       = $item.Name
            Status     = $deployResult.ProvisioningState
            Timestamp  = $deployResult.Timestamp
            Template   = Split-Path $item.Template -Leaf
        }

        if ($deployResult.ProvisioningState -eq 'Succeeded') {
            Write-Host "  完成 ($($deployResult.Timestamp))" -ForegroundColor Green
        } else {
            Write-Host "  失败" -ForegroundColor Red
            break
        }
    }
} else {
    Write-Host "`n验证未全部通过，终止部署。请修复上述错误后重试。" -ForegroundColor Red
}

# 汇总输出
Write-Host "`n$('=' * 60)" -ForegroundColor DarkGray
Write-Host '部署结果汇总' -ForegroundColor Cyan
Write-Host '=' * 60 -ForegroundColor DarkGray

$deploymentResults | Format-Table -AutoSize
```

执行结果示例：

```text
============================================================
第一阶段：模板验证
============================================================

验证: 网络基础... 通过
验证: 存储账户... 通过
验证: 虚拟机... 通过

============================================================
第二阶段：执行部署
============================================================

部署: 网络基础...
  完成 (2025-11-27 08:22:15)

部署: 存储账户...
  完成 (2025-11-27 08:22:48)

部署: 虚拟机...
  完成 (2025-11-27 08:24:03)

============================================================
部署结果汇总
============================================================

Name       Status    Timestamp           Template
----       ------    ---------           --------
网络基础   Succeeded 2025-11-27 08:22:15 vnet.json
存储账户   Succeeded 2025-11-27 08:22:48 storage.json
虚拟机     Succeeded 2025-11-27 08:24:03 vm.json
```

这个脚本有两个关键设计：第一，`Test-AzResourceGroupDeployment` 在验证阶段不会创建任何真实资源，可以在安全的环境中提前发现问题；第二，部署阶段使用 `foreach` 遍历模板列表，一旦某个模板部署失败立即 `break` 退出，避免在错误的基础上继续部署后续资源。

## 注意事项

1. **模板语法检查先行**：在提交代码前，始终使用 `Test-AzResourceGroupDeployment` 进行验证。模板 JSON 的语法错误（如缺少逗号、引号不匹配）会导致整个部署失败，而这类错误在验证阶段就能被捕获。

2. **资源命名规则**：Azure 对资源名称有严格限制，例如存储账户名只能包含小写字母和数字，长度 3-24 个字符。建议在参数文件中使用命名前缀 + 环境缩写 + 序号的规则（如 `st` + `dev` + `001`），并在 PowerShell 中用 `-match` 正则表达式做前置校验。

3. **幂等性依赖模板设计**：ARM 模板本身支持幂等部署，但前提是模板中完整定义了资源的所有关键属性。如果只定义了 `name` 和 `location` 而省略了 `sku`，多次部署可能不会报错，但资源配置可能不是预期的最终状态。

4. **增量模式与完整模式的区别**：`-Mode Incremental` 是安全的默认选择，它只处理模板中声明的资源。`-Mode Complete` 会删除资源组中所有未在模板中声明的资源，生产环境慎用。建议在脚本中显式指定 `-Mode`，不要依赖默认值。

5. **大模板拆分为链接模板**：当模板超过 200 行或包含 10 个以上资源时，建议使用链接模板（Linked Templates）将不同层（网络、存储、计算）拆分为独立文件，由主模板统一编排。这样既降低单文件复杂度，也便于团队分工维护。

6. **敏感参数使用 Key Vault 引用**：虚拟机密码、数据库连接字符串等敏感信息不要明文写在参数文件中。在参数文件的 `value` 字段中使用 Key Vault 引用格式（`"reference"` + `"keyVault"` + `"secretName"`），部署时 PowerShell 会自动从 Azure Key Vault 安全读取。
