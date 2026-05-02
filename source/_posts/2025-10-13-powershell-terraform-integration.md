---
layout: post
date: 2025-10-13 08:00:00
updated: 2025-10-13 08:00:00
title: "PowerShell 技能连载 - Terraform 集成"
description: PowerTip of the Day - Terraform Integration with PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- terraform
- iac
- infrastructure-as-code
- devops
---

_适用于 PowerShell 7.0 及以上版本（跨平台）_

## 为什么要用 PowerShell 桥接 Terraform

Terraform 是目前最主流的基础设施即代码（IaC）工具，它通过声明式的 HCL 语言定义云资源，并用 `terraform plan` 和 `terraform apply` 实现可重复、可审计的部署流程。但 Terraform 本身是一个命令行工具，它不擅长处理动态逻辑、条件判断和外部系统集成。当部署流程涉及读取配置中心、调用审批 API、解析 CSV 数据源或发送通知等操作时，纯 HCL 的实现会变得笨重且难以维护。

PowerShell 作为跨平台的任务自动化框架，恰好弥补了这一空白。通过将 PowerShell 与 Terraform CLI 组合使用，可以用 PowerShell 编排整个部署生命周期：动态生成 `tfvars` 文件、在 apply 前插入审批检查、解析 plan 输出并生成可读报告、甚至实现漂移检测与自动修复。本文将围绕三个典型场景，演示如何用 PowerShell 脚本高效集成 Terraform。

## 动态生成 Terraform 配置并执行部署

在实际项目中，环境参数（实例规格、区域、节点数量等）通常存储在外部系统中，例如 JSON 配置文件、Consul KV 或者是 REST API 返回的结果。下面的脚本演示如何从 JSON 配置文件读取环境参数，动态生成 Terraform 变量文件，然后自动执行完整的 `init`、`plan`、`apply` 流程。

```powershell
# 环境配置文件路径
$configPath = Join-Path $PSScriptRoot "environments.json"
$tfWorkDir  = Join-Path $PSScriptRoot "terraform"

# 读取环境配置
$environments = Get-Content -Path $configPath -Raw | ConvertFrom-Json

# 选择目标环境
$targetEnv = "staging"
$envConfig = $environments.$targetEnv

if (-not $envConfig) {
    throw "未找到环境配置: $targetEnv"
}

Write-Host "目标环境: $targetEnv" -ForegroundColor Cyan
Write-Host "区域: $($envConfig.location) | 实例规格: $($envConfig.vm_size) | 节点数: $($envConfig.node_count)"

# 动态生成 terraform.tfvars.json
$tfVars = @{
    environment    = $targetEnv
    location       = $envConfig.location
    vm_size        = $envConfig.vm_size
    node_count     = $envConfig.node_count
    tags           = @{
        ManagedBy  = "PowerShell"
        CreatedAt  = (Get-Date -Format "yyyy-MM-dd")
        CostCenter = $envConfig.cost_center
    }
}

$tfVarsPath = Join-Path $tfWorkDir "terraform.tfvars.json"
$tfVars | ConvertTo-Json -Depth 5 | Set-Content -Path $tfVarsPath -Encoding UTF8
Write-Host "[OK] 已生成变量文件: $tfVarsPath" -ForegroundColor Green

# 执行 Terraform 初始化
Write-Host "`n>>> terraform init" -ForegroundColor Yellow
$initResult = terraform -chdir=$tfWorkDir init -input=false -no-color 2>&1
$initExit = $LASTEXITCODE
Write-Host $initResult

if ($initExit -ne 0) {
    throw "Terraform init 失败，退出码: $initExit"
}

# 执行 Plan
Write-Host "`n>>> terraform plan" -ForegroundColor Yellow
$planFile = Join-Path $tfWorkDir "current.tfplan"
$planResult = terraform -chdir=$tfWorkDir plan -out=$planFile -var-file="terraform.tfvars.json" -no-color 2>&1
$planExit = $LASTEXITCODE
Write-Host $planResult

if ($planExit -ne 0) {
    throw "Terraform plan 失败，退出码: $planExit"
}

# 解析 Plan 摘要
$addCount    = if ($planResult -match '(\d+) to add')    { $Matches[1] } else { "0" }
$changeCount = if ($planResult -match '(\d+) to change') { $Matches[1] } else { "0" }
$destroyCount = if ($planResult -match '(\d+) to destroy') { $Matches[1] } else { "0" }

Write-Host "`nPlan 摘要: +$addCount ~$changeCount -$destroyCount" -ForegroundColor Cyan

# 安全检查：如果存在销毁操作，要求人工确认
if ($destroyCount -gt 0) {
    $confirm = Read-Host "检测到 $destroyCount 个资源将被销毁，是否继续？(yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "已取消部署" -ForegroundColor Yellow
        return
    }
}

# 执行 Apply
Write-Host "`n>>> terraform apply" -ForegroundColor Yellow
$applyResult = terraform -chdir=$tfWorkDir apply -auto-approve $planFile -no-color 2>&1
$applyExit = $LASTEXITCODE
Write-Host $applyResult

if ($applyExit -ne 0) {
    throw "Terraform apply 失败，退出码: $applyExit"
}

Write-Host "`n[OK] 部署完成！" -ForegroundColor Green
```

```text
目标环境: staging
区域: eastasia | 实例规格: Standard_D2s_v3 | 节点数: 3
[OK] 已生成变量文件: /deploy/terraform/terraform.tfvars.json

>>> terraform init
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully initialized!

>>> terraform plan
Terraform will perform the following actions:
  # module.vm.azurerm_linux_virtual_machine.main[0] will be created
  # module.vm.azurerm_linux_virtual_machine.main[1] will be created
  # module.vm.azurerm_linux_virtual_machine.main[2] will be created
Plan: 3 to add, 0 to change, 0 to destroy.

Plan 摘要: +3 ~0 -0

>>> terraform apply
module.vm.azurerm_linux_virtual_machine.main[0]: Creating...
module.vm.azurerm_linux_virtual_machine.main[0]: Creation complete after 2m35s
module.vm.azurerm_linux_virtual_machine.main[1]: Creating...
module.vm.azurerm_linux_virtual_machine.main[1]: Creation complete after 2m40s
module.vm.azurerm_linux_virtual_machine.main[2]: Creating...
module.vm.azurerm_linux_virtual_machine.main[2]: Creation complete after 2m38s

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

[OK] 部署完成！
```

## 解析 Terraform State 生成资源清单

Terraform 的状态文件（`terraform.tfstate`）记录了所有已部署资源的详细属性。在多环境、多项目的运维场景中，定期导出资源清单有助于成本审计、安全合规检查和资产盘点。下面的脚本演示如何通过 `terraform show -json` 将状态输出为结构化数据，并用 PowerShell 提取关键字段生成 CSV 报告。

```powershell
function Get-TerraformResourceInventory {
    <#
    .SYNOPSIS
    从 Terraform 状态中提取资源清单并导出报告
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TerraformDir,

        [string]$OutputPath = "./resource-inventory-$(Get-Date -Format 'yyyyMMdd').csv"
    )

    # 验证 Terraform 工作目录
    if (-not (Test-Path (Join-Path $TerraformDir ".terraform"))) {
        throw "目录未初始化: $TerraformDir - 请先运行 terraform init"
    }

    # 获取 JSON 格式的状态
    Write-Host "正在读取 Terraform 状态..." -ForegroundColor Cyan
    $stateJson = terraform -chdir=$TerraformDir show -json 2>$null

    if ($LASTEXITCODE -ne 0) {
        throw "无法读取 Terraform 状态。请确认已成功执行过 terraform apply"
    }

    $state = $stateJson | ConvertFrom-Json

    # 提取资源信息
    $inventory = @()

    foreach ($resource in $state.values.root_module.resources) {
        # 根据资源类型提取不同的关键属性
        $keyAttrs = switch -Regex ($resource.type) {
            'azurerm_linux_virtual_machine|azurerm_windows_virtual_machine' {
                @{
                    'VM 名称'   = $resource.values.name
                    'VM 规格'   = $resource.values.size
                    '区域'      = $resource.values.location
                    '资源组'    = $resource.values.resource_group_name
                }
            }
            'azurerm_storage_account' {
                @{
                    '存储账户'  = $resource.values.name
                    'SKU'       = $resource.values.account_tier
                    '复制策略'  = $resource.values.account_replication_type
                    '区域'      = $resource.values.location
                }
            }
            'azurerm_virtual_network' {
                @{
                    'VNet 名称' = $resource.values.name
                    '地址空间'  = ($resource.values.address_space -join ', ')
                    '区域'      = $resource.values.location
                }
            }
            default {
                @{
                    '名称'      = $resource.values.name
                    '属性'      = "N/A"
                }
            }
        }

        $row = [ordered]@{
            资源类型   = $resource.type
            资源名称   = $resource.name
            模块路径   = if ($resource.module) { $resource.module } else { "root" }
            提供者     = ($resource.provider_name -split '::')[-1]
            依赖数量   = if ($resource.depends_on) { $resource.depends_on.Count } else { 0 }
            模式       = $resource.mode
        }

        # 合并类型特定的属性
        foreach ($key in $keyAttrs.Keys) {
            $row[$key] = $keyAttrs[$key]
        }

        $inventory += [PSCustomObject]$row
    }

    # 处理子模块中的资源
    if ($state.values.root_module.child_modules) {
        foreach ($child in $state.values.root_module.child_modules) {
            foreach ($resource in $child.resources) {
                $row = [ordered]@{
                    资源类型 = $resource.type
                    资源名称 = $resource.name
                    模块路径 = $child.address
                    提供者   = ($resource.provider_name -split '::')[-1]
                    依赖数量 = if ($resource.depends_on) { $resource.depends_on.Count } else { 0 }
                    模式     = $resource.mode
                }
                $inventory += [PSCustomObject]$row
            }
        }
    }

    # 输出统计信息
    $typeSummary = $inventory | Group-Object 资源类型 | Sort-Object Count -Descending

    Write-Host "`n资源统计:" -ForegroundColor Cyan
    foreach ($group in $typeSummary) {
        Write-Host ("  {0,-45} {1,3} 个" -f $group.Name, $group.Count)
    }
    Write-Host ("  {0,-45} {1,3} 个" -f "总计", $inventory.Count)

    # 导出到 CSV
    $inventory | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "`n[OK] 资源清单已导出: $OutputPath" -ForegroundColor Green

    return $inventory
}

# 执行资源盘点
$inventory = Get-TerraformResourceInventory -TerraformDir "./terraform" -Verbose

# 筛选需要关注的资源（如公网 IP、未加密存储等）
$publicResources = $inventory | Where-Object {
    $_.资源类型 -match 'public_ip|lb$'
}

if ($publicResources.Count -gt 0) {
    Write-Host "`n[WARN] 发现 $($publicResources.Count) 个公网暴露资源，请检查安全策略:" -ForegroundColor Yellow
    foreach ($pr in $publicResources) {
        Write-Host "  - $($pr.资源类型): $($pr.资源名称)" -ForegroundColor Yellow
    }
}
```

```text
正在读取 Terraform 状态...

资源统计:
  azurerm_linux_virtual_machine                    3 个
  azurerm_network_interface                        3 个
  azurerm_virtual_network                          1 个
  azurerm_public_ip                                3 个
  azurerm_network_security_group                   1 个
  azurerm_storage_account                          1 个
  总计                                            12 个

[OK] 资源清单已导出: ./resource-inventory-20251013.csv

[WARN] 发现 3 个公网暴露资源，请检查安全策略:
  - azurerm_public_ip: main_public_ip[0]
  - azurerm_public_ip: main_public_ip[1]
  - azurerm_public_ip: main_public_ip[2]
```

## 配置漂移检测与自动通知

基础设施配置漂移是指实际运行资源的状态与 Terraform 状态文件中记录的期望状态不一致的情况。漂移可能由手动操作、自动化脚本的副作用或外部系统变更引起。下面的脚本将漂移检测封装为一个可定期执行的巡检任务，在发现漂移时自动通过 Webhook 发送告警通知。

```powershell
function Test-TerraformDrift {
    <#
    .SYNOPSIS
    检测 Terraform 管理的基础设施是否存在配置漂移
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$WorkDirs,

        [string]$WebhookUrl,

        [int]$WarningThreshold = 5
    )

    $allResults = @()

    foreach ($dir in $WorkDirs) {
        $dirName = Split-Path $dir -Leaf
        Write-Host "`n检查工作目录: $dirName" -ForegroundColor Cyan

        # 确保 Terraform 已初始化
        $initCheck = terraform -chdir=$dir init -backend=false -input=false -no-color 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [SKIP] 初始化失败，跳过此目录" -ForegroundColor Red
            continue
        }

        # 执行 Plan（不保存计划文件，仅检测差异）
        $planOutput = terraform -chdir=$dir plan -detailed-exitcode -input=false -no-color 2>&1
        $exitCode = $LASTEXITCODE

        # 详细退出码：0=无变化 1=错误 2=有变化
        $driftStatus = switch ($exitCode) {
            0 { "无漂移" }
            1 { "检测失败" }
            2 { "存在漂移" }
            default { "未知 ($exitCode)" }
        }

        # 解析变化数量
        $changes = @{
            Add     = if ($planOutput -match '(\d+) to add')     { [int]$Matches[1] } else { 0 }
            Change  = if ($planOutput -match '(\d+) to change') { [int]$Matches[1] } else { 0 }
            Destroy = if ($planOutput -match '(\d+) to destroy'){ [int]$Matches[1] } else { 0 }
        }
        $totalChanges = $changes.Add + $changes.Change + $changes.Destroy

        # 提取具体变化的资源列表
        $changedResources = @()
        $planLines = $planOutput -split "`n"
        foreach ($line in $planLines) {
            if ($line -match '#\s+(\S+)\s+will be\s+(created|updated|deleted|replaced)') {
                $changedResources += [PSCustomObject]@{
                    Resource = $Matches[1]
                    Action   = $Matches[2]
                }
            }
        }

        $result = [PSCustomObject]@{
            工作目录   = $dirName
            漂移状态   = $driftStatus
            新增       = $changes.Add
            变更       = $changes.Change
            销毁       = $changes.Destroy
            总变化数   = $totalChanges
            检测时间   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            变化资源   = $changedResources
        }

        $allResults += $result

        # 控制台输出
        $color = if ($totalChanges -eq 0) { "Green" } elseif ($totalChanges -lt $WarningThreshold) { "Yellow" } else { "Red" }
        Write-Host "  状态: $driftStatus | 变化: +$($changes.Add) ~$($changes.Change) -$($changes.Destroy)" -ForegroundColor $color
    }

    # 汇总报告
    $driftCount = ($allResults | Where-Object { $_.漂移状态 -eq "存在漂移" }).Count
    $summary = [PSCustomObject]@{
        检测目录数   = $WorkDirs.Count
        正常目录数   = $WorkDirs.Count - $driftCount
        漂移目录数   = $driftCount
        总变化资源   = ($allResults | Measure-Object -Property 总变化数 -Sum).Sum
        检测完成时间 = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    Write-Host "`n========== 漂移检测汇总 ==========" -ForegroundColor Cyan
    Write-Host "  检测目录: $($summary.检测目录数) 个"
    Write-Host "  正常: $($summary.正常目录数) | 漂移: $($summary.漂移目录数)"
    Write-Host "  总变化资源数: $($summary.总变化资源)"

    # 发送 Webhook 通知
    if ($WebhookUrl -and $driftCount -gt 0) {
        $severity = if ($summary.总变化资源 -ge $WarningThreshold) { "HIGH" } else { "MEDIUM" }

        $payload = @{
            text     = "[Terraform 漂移告告警] 级别: $severity | 漂移目录: $driftCount/$($WorkDirs.Count) | 变化资源: $($summary.总变化资源) 个"
            sections = @()
        }

        foreach ($res in ($allResults | Where-Object { $_.漂移状态 -eq "存在漂移" })) {
            $payload.sections += @{
                activityTitle = "目录: $($res.工作目录)"
                facts = @(
                    @{ name = "新增"; value = $res.新增 },
                    @{ name = "变更"; value = $res.变更 },
                    @{ name = "销毁"; value = $res.销毁 }
                )
            }
        }

        $body = $payload | ConvertTo-Json -Depth 5 -Compress
        try {
            Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
            Write-Host "[OK] Webhook 通知已发送" -ForegroundColor Green
        }
        catch {
            Write-Host "[WARN] Webhook 发送失败: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    return $allResults
}

# 定期巡检：检查多个 Terraform 工作目录
$workDirs = @(
    "/infra/terraform/networking"
    "/infra/terraform/compute"
    "/infra/terraform/storage"
)

$driftReport = Test-TerraformDrift `
    -WorkDirs $workDirs `
    -WebhookUrl "https://hooks.example.com/infra-alerts" `
    -WarningThreshold 5

# 导出历史记录
$historyPath = "./drift-history-$(Get-Date -Format 'yyyyMMdd').json"
$driftReport | ConvertTo-Json -Depth 3 | Set-Content -Path $historyPath -Encoding UTF8
```

```text
检查工作目录: networking
  状态: 无漂移 | 变化: +0 ~0 -0

检查工作目录: compute
  状态: 存在漂移 | 变化: +0 ~2 -1

检查工作目录: storage
  状态: 无漂移 | 变化: +0 ~0 -0

========== 漂移检测汇总 ==========
  检测目录: 3 个
  正常: 2 | 漂移: 1
  总变化资源数: 3
[OK] Webhook 通知已发送
```

## 注意事项

1. **Terraform CLI 依赖**：本文所有脚本都依赖本地安装的 Terraform CLI。在 CI/CD 管道中建议使用 `tfenv` 或 `mise` 管理版本，确保团队使用相同的 Terraform 版本。版本不一致可能导致状态文件不兼容或 Provider 下载失败。

2. **状态文件安全**：`terraform show -json` 输出的状态数据可能包含敏感信息（数据库密码、连接字符串等）。在生成报告时应避免将敏感字段写入明文 CSV，可通过 `-sensitive=false` 参数或在 PowerShell 中过滤 `sensitive = true` 的属性来降低泄露风险。生产环境务必使用远程状态后端（如 Azure Storage、S3）并启用加密。

3. **plan 退出码语义**：`terraform plan -detailed-exitcode` 返回三种退出码：0 表示无变化、1 表示执行出错、2 表示存在变更。漂移检测脚本必须区分这三种状态，不能简单地将非零退出码都视为错误，否则会误报正常的 plan 结果。

4. **跨平台路径处理**：PowerShell 7 支持在 Linux 和 macOS 上运行，但 Terraform 的 `-chdir` 参数在不同操作系统上对路径分隔符有严格要求。统一使用 `Join-Path` 拼接路径（而非硬编码 `/` 或 `\`），可以保证脚本在 Windows 和 Linux 上行为一致。

5. **并发执行与状态锁**：如果同时对多个工作目录执行 `terraform apply`，且这些目录共享同一个远程状态后端，可能会触发状态锁定冲突。建议使用 `-lock-timeout` 参数设置合理的等待时间（如 `terraform apply -lock-timeout=60s`），或通过 PowerShell 的串行控制逻辑确保同一时间只有一个操作访问共享状态。

6. **错误处理与回滚策略**：`terraform apply` 失败时 Terraform 会自动标记 tainted 资源并在下次 apply 时重建。但 PowerShell 脚本层面的错误处理同样重要：应在每次 Terraform CLI 调用后立即检查 `$LASTEXITCODE`，并在脚本顶层使用 `try/catch/finally` 确保临时文件（如 `.tfplan`）被清理，避免残留的计划文件影响下次执行。
