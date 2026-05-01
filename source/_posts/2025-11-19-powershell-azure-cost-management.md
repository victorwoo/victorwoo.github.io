---
layout: post
date: 2025-11-19 08:00:00
title: "PowerShell 技能连载 - Azure 成本管理"
description: PowerTip of the Day - Azure Cost Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- cost-management
- billing
- optimization
---

_适用于 PowerShell 5.1 及以上版本_

云上资源用起来方便，但月底账单一来往往让人心惊。Azure 提供了 Cost Management 服务，可以帮助我们追踪、分析和优化云支出。然而，通过门户网站手动查看报表既慢又不灵活，尤其当你管理多个订阅时，逐个点开查看效率极低。

PowerShell 结合 Az 模块和 Cost Management REST API，可以让我们以脚本化的方式自动采集费用数据、设置预算告警、识别闲置资源。这意味着你可以将成本管控嵌入 CI/CD 流水线，或者每天早上自动生成一份费用摘要邮件发给团队，从被动等账单变为主动管理成本。

本文将从实际场景出发，演示如何用 PowerShell 查询 Azure 订阅的消费明细、创建预算和告警规则、以及自动扫描可优化资源。所有操作均通过脚本完成，无需登录门户。

## 连接 Azure 并获取订阅信息

在开始之前，需要先安装 Az 模块并登录 Azure 账户。如果你已经安装过 Az 模块，可以跳过安装步骤直接连接。下面的代码展示如何连接 Azure 并列出当前账户下的所有订阅，包括每个订阅的计费状态。

```powershell
# 安装 Az 模块（如已安装可跳过）
# Install-Module -Name Az -Scope CurrentUser -Force

# 连接 Azure 账户
Connect-AzAccount

# 获取所有订阅信息
$subscriptions = Get-AzSubscription
foreach ($sub in $subscriptions) {
    $info = [ordered]@{
        Name      = $sub.Name
        Id        = $sub.Id
        State     = $sub.State
        TenantId  = $sub.TenantId
    }
    New-Object -TypeName PSCustomObject -Property $info
}
```

执行结果示例：

```
Name      : Production
Id        : a1b2c3d4-e5f6-7890-abcd-ef1234567890
State     : Enabled
TenantId  : 11111111-2222-3333-4444-555555555555

Name      : Development
Id        : b2c3d4e5-f6a7-8901-bcde-f12345678901
State     : Enabled
TenantId  : 11111111-2222-3333-4444-555555555555

Name      : Sandbox
Id        : c3d4e5f6-a7b8-9012-cdef-123456789012
State     : Disabled
TenantId  : 11111111-2222-3333-4444-555555555555
```

连接成功后，我们就能基于订阅维度查询各项费用数据。建议在生产环境中使用服务主体（Service Principal）进行非交互式登录，避免手动输入凭据。

## 查询订阅消费明细

Azure Cost Management 提供了 REST API，可以通过 `Invoke-AzRestMethod` 调用来获取指定时间范围的费用数据。下面的函数封装了查询逻辑，支持按日期范围和服务类型筛选，返回格式化的费用报表。

```powershell
function Get-AzCostDetail {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,

        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate = (Get-Date).AddDays(-30),

        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate = (Get-Date),

        [Parameter(Mandatory = $false)]
        [int]$Top = 10
    )

    # 选择目标订阅上下文
    $null = Set-AzContext -SubscriptionId $SubscriptionId

    # 构建 Cost Management REST API 请求
    $apiVersion = "2023-11-01"
    $uri = "/subscriptions/$SubscriptionId/providers/Microsoft.CostManagement/query?api-version=$apiVersion"

    # 构建请求体，按服务维度分组汇总
    $body = @{
        type       = "ActualCost"
        timeframe  = "Custom"
        timePeriod = @{
            from = $StartDate.ToString("yyyy-MM-dd")
            to   = $EndDate.ToString("yyyy-MM-dd")
        }
        dataset    = @{
            granularity = "None"
            aggregation = @{
                totalCost = @{
                    name     = "Cost"
                    function = "Sum"
                }
            }
            grouping    = @(
                @{
                    type = "Dimension"
                    name = "ServiceName"
                }
            )
        }
    } | ConvertTo-Json -Depth 10

    # 调用 REST API
    $response = Invoke-AzRestMethod -Path $uri -Method POST -Payload $body

    if ($response.StatusCode -ne 200) {
        Write-Error "查询失败，状态码：$($response.StatusCode)"
        Write-Error $response.Content
        return
    }

    # 解析返回结果
    $result = $response.Content | ConvertFrom-Json
    $columns = $result.properties.columns
    $rows = $result.properties.rows

    # 按费用降序排列，取前 N 条
    $sortedRows = $rows | Sort-Object { $_[0] } -Descending | Select-Object -First $Top

    foreach ($row in $sortedRows) {
        $costUSD = [math]::Round($row[0], 2)
        $serviceName = $row[1]
        $currency = $row[2]

        $detail = [ordered]@{
            ServiceName = $serviceName
            CostUSD     = $costUSD
            Currency    = $currency
        }
        New-Object -TypeName PSCustomObject -Property $detail
    }
}

# 查询最近 30 天费用 Top 10 服务
Get-AzCostDetail -SubscriptionId "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -Top 10
```

执行结果示例：

```
ServiceName                   CostUSD Currency
-----------                   -------- --------
Virtual Machines               342.58 USD
Azure SQL Database             128.30 USD
Storage Accounts                67.45 USD
App Service                     52.00 USD
Azure Kubernetes Service        41.20 USD
Virtual Network                 12.80 USD
Azure Monitor                    8.60 USD
Key Vault                        3.20 USD
Azure DNS                        1.50 USD
Public IP Addresses              0.90 USD
```

从结果可以看到，虚拟机是最大的开支来源，占了总费用的近一半。这类数据可以帮助我们快速定位成本优化的重点方向。如果需要更细粒度的分析，可以把 `grouping` 维度改为 `ResourceGroupName` 或 `ResourceType`。

## 创建预算和告警规则

光看费用报表还不够，我们需要在超支之前收到告警。Azure Cost Management 支持创建预算（Budget），并在消费达到阈值时触发告警。下面的脚本演示如何创建月度预算，并设置两个告警阈值：当实际消费达到 80% 和 100% 时分别发送通知。

```powershell
function Set-AzCostBudget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,

        [Parameter(Mandatory = $true)]
        [string]$BudgetName,

        [Parameter(Mandatory = $true)]
        [decimal]$Amount,

        [Parameter(Mandatory = $false)]
        [string[]]$NotificationEmails = @("admin@contoso.com"),

        [Parameter(Mandatory = $false)]
        [string]$TimeZone = "UTC"
    )

    $null = Set-AzContext -SubscriptionId $SubscriptionId

    $apiVersion = "2023-11-01"
    $uri = "/subscriptions/$SubscriptionId/providers/Microsoft.Consumption/budgets/$BudgetName?api-version=$apiVersion"

    $now = Get-Date
    $year = $now.Year
    $month = $now.Month

    # 构建预算请求体
    $body = @{
        properties = @{
            timePeriod = @{
                startDate = "$year-$($month.ToString('00'))-01"
                endDate   = "$($year + 1)-12-31"
            }
            timeGrain  = "Monthly"
            amount     = $Amount
            currentSpend = @{
                amount   = 0
                unit     = "USD"
            }
            notifications = @{
                Notification80 = @{
                    enabled       = $true
                    operator      = "GreaterThan"
                    threshold     = 80
                    contactEmails = $NotificationEmails
                }
                Notification100 = @{
                    enabled       = $true
                    operator      = "GreaterThan"
                    threshold     = 100
                    contactEmails = $NotificationEmails
                }
            }
        }
    } | ConvertTo-Json -Depth 10

    $response = Invoke-AzRestMethod -Path $uri -Method PUT -Payload $body

    if ($response.StatusCode -in @(200, 201)) {
        $result = $response.Content | ConvertFrom-Json
        Write-Host "预算 '$BudgetName' 创建成功！" -ForegroundColor Green
        Write-Host "  月度预算金额: `$$Amount USD"
        Write-Host "  告警阈值: 80%, 100%"
        Write-Host "  通知邮箱: $($NotificationEmails -join ', ')"
        Write-Host "  预算 ID: $($result.name)"
    }
    else {
        Write-Error "预算创建失败，状态码：$($response.StatusCode)"
        Write-Error $response.Content
    }
}

# 创建月度 500 美元的预算
Set-AzCostBudget `
    -SubscriptionId "a1b2c3d4-e5f6-7890-abcd-ef1234567890" `
    -BudgetName "Monthly-Production-Budget" `
    -Amount 500 `
    -NotificationEmails @("admin@contoso.com", "finance@contoso.com")
```

执行结果示例：

```
预算 'Monthly-Production-Budget' 创建成功！
  月度预算金额: $500 USD
  告警阈值: 80%, 100%
  通知邮箱: admin@contoso.com, finance@contoso.com
  预算 ID: Monthly-Production-Budget
```

预算创建后，Azure 会在每月消费累计达到 400 美元（80%）时发邮件提醒你注意控制开支，达到 500 美元（100%）时再次告警。你也可以结合 Logic Apps 或 Azure Functions，在告警触发后自动执行扩缩容或关停非关键资源。

## 扫描可优化的闲置资源

很多云成本的浪费来自于闲置或低利用率资源。下面的脚本会扫描常见类型的闲置资源，包括未挂载的磁盘、未分配的公网 IP、停止的虚拟机以及空闲的 SQL 数据库，生成一份优化建议报告。

```powershell
function Find-AzIdleResources {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId
    )

    $null = Set-AzContext -SubscriptionId $SubscriptionId
    $findings = @()

    # 1. 检查停止状态的虚拟机
    $vms = Get-AzVM -Status
    foreach ($vm in $vms) {
        $powerState = ($vm.Statuses | Where-Object { $_.Code -like "PowerState/*" }).Code
        if ($powerState -eq "PowerState/deallocated") {
            $estimatedMonthly = [math]::Round(
                ($vm.HardwareProfile.VmSize -match "Standard_" -and $true) * 0
            )
            $rgName = $vm.ResourceGroupName
            $findings += [ordered]@{
                ResourceType  = "Virtual Machine"
                ResourceName  = $vm.Name
                ResourceGroup = $rgName
                Status        = "Deallocated"
                Suggestion    = "已释放但仍保留配置，如不再使用建议删除"
                Priority      = "Medium"
            }
        }
        elseif ($powerState -eq "PowerState/stopped") {
            $findings += [ordered]@{
                ResourceType  = "Virtual Machine"
                ResourceName  = $vm.Name
                ResourceGroup = $vm.ResourceGroupName
                Status        = "Stopped (not deallocated)"
                Suggestion    = "停止但未释放，仍在计费！建议 deallocate 或删除"
                Priority      = "High"
            }
        }
    }

    # 2. 检查未挂载的磁盘
    $disks = Get-AzDisk
    foreach ($disk in $disks) {
        if ($null -eq $disk.ManagedBy -and $disk.DiskState -eq "Unattached") {
            $sizeGB = $disk.DiskSizeGB
            $sku = $disk.Sku.Name
            $findings += [ordered]@{
                ResourceType  = "Managed Disk"
                ResourceName  = $disk.Name
                ResourceGroup = $disk.ResourceGroupName
                Status        = "Unattached ($sizeGB GB, $sku)"
                Suggestion    = "未挂载的磁盘，删除可节省约 `$$([math]::Round($sizeGB * 0.05, 2))/月"
                Priority      = "High"
            }
        }
    }

    # 3. 检查未关联的公网 IP
    $publicIps = Get-AzPublicIpAddress
    foreach ($pip in $publicIps) {
        if (-not $pip.IpConfiguration) {
            $findings += [ordered]@{
                ResourceType  = "Public IP Address"
                ResourceName  = $pip.Name
                ResourceGroup = $pip.ResourceGroupName
                Status        = "Unassociated"
                Suggestion    = "未关联的公网 IP，删除可节省约 `$3.65/月"
                Priority      = "Medium"
            }
        }
    }

    # 4. 检查暂停的 SQL 数据库
    $sqlServers = Get-AzSqlServer
    foreach ($server in $sqlServers) {
        $databases = Get-AzSqlDatabase -ServerName $server.ServerName -ResourceGroupName $server.ResourceGroupName
        foreach ($db in $databases) {
            if ($db.Status -eq "Paused") {
                $findings += [ordered]@{
                    ResourceType  = "SQL Database"
                    ResourceName  = "$($server.ServerName)/$($db.DatabaseName)"
                    ResourceGroup = $db.ResourceGroupName
                    Status        = "Paused"
                    Suggestion    = "已暂停但仍保留，确认是否需要恢复或删除"
                    Priority      = "Low"
                }
            }
        }
    }

    # 按优先级排序输出
    $priorityOrder = @{ "High" = 1; "Medium" = 2; "Low" = 3 }
    $sorted = $findings | Sort-Object { $priorityOrder[$_.Priority] }

    foreach ($item in $sorted) {
        New-Object -TypeName PSCustomObject -Property $item
    }

    Write-Host "`n共发现 $($findings.Count) 个可优化项，其中 High 优先级 $(($findings | Where-Object { $_.Priority -eq 'High' }).Count) 个。" -ForegroundColor Yellow
}

# 扫描生产订阅的闲置资源
Find-AzIdleResources -SubscriptionId "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
```

执行结果示例：

```
ResourceType     : Virtual Machine
ResourceName     : web-server-old
ResourceGroup    : rg-legacy
Status           : Stopped (not deallocated)
Suggestion       : 停止但未释放，仍在计费！建议 deallocate 或删除
Priority         : High

ResourceType     : Managed Disk
ResourceName     : web-server-old_OsDisk
ResourceGroup    : rg-legacy
Status           : Unattached (128 GB, Premium_LRS)
Suggestion       : 未挂载的磁盘，删除可节省约 $6.40/月
Priority         : High

ResourceType     : Public IP Address
ResourceName     : pip-test-unused
ResourceGroup    : rg-sandbox
Status           : Unassociated
Suggestion       : 未关联的公网 IP，删除可节省约 $3.65/月
Priority         : Medium

ResourceType     : SQL Database
ResourceName     : sql-prod/legacy-reporting
ResourceGroup    : rg-database
Status           : Paused
Suggestion       : 已暂停但仍保留，确认是否需要恢复或删除
Priority         : Low

共发现 4 个可优化项，其中 High 优先级 2 个。
```

扫描结果清楚地列出了每个闲置资源的类型、名称、所在资源组和优化建议。High 优先级的项应当优先处理，尤其是"停止但未释放"的虚拟机，它们虽然处于关机状态但仍然在产生计算费用。

## 生成月度成本摘要报告

将前面的查询和分析整合起来，可以生成一份结构化的月度成本摘要报告，方便通过邮件或即时消息发送给团队。

```powershell
function New-AzCostSummaryReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$SubscriptionIds,

        [Parameter(Mandatory = $false)]
        [int]$DaysBack = 30
    )

    $reportLines = @()
    $startDate = (Get-Date).AddDays(-$DaysBack)
    $endDate = Get-Date

    $reportLines += "=" * 60
    $reportLines += "Azure 成本管理月度摘要报告"
    $reportLines += "生成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $reportLines += "统计周期: $($startDate.ToString('yyyy-MM-dd')) 至 $($endDate.ToString('yyyy-MM-dd'))"
    $reportLines += "=" * 60

    $totalCostAll = 0

    foreach ($subId in $SubscriptionIds) {
        $sub = Get-AzSubscription -SubscriptionId $subId
        $reportLines += ""
        $reportLines += "--- 订阅: $($sub.Name) ($subId) ---"

        try {
            $costs = Get-AzCostDetail -SubscriptionId $subId -StartDate $startDate -EndDate $endDate -Top 5
            $subTotal = 0

            foreach ($item in $costs) {
                $reportLines += "  [$($item.ServiceName)] `$$($item.CostUSD) $($item.Currency)"
                $subTotal += $item.CostUSD
            }

            $reportLines += "  小计: `$$([math]::Round($subTotal, 2))"
            $totalCostAll += $subTotal
        }
        catch {
            $reportLines += "  [错误] 无法获取费用数据: $($_.Exception.Message)"
        }
    }

    $reportLines += ""
    $reportLines += "=" * 60
    $reportLines += "所有订阅合计: `$$([math]::Round($totalCostAll, 2)) USD"
    $reportLines += "=" * 60

    # 输出到控制台
    $reportLines | Write-Host

    # 可选：保存到文件
    $reportPath = ".\AzureCostSummary_$(Get-Date -Format 'yyyyMMdd').txt"
    $reportLines | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "`n报告已保存至: $reportPath" -ForegroundColor Cyan
}

# 为多个订阅生成月度报告
New-AzCostSummaryReport -SubscriptionIds @(
    "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
    "b2c3d4e5-f6a7-8901-bcde-f12345678901"
) -DaysBack 30
```

执行结果示例：

```
============================================================
Azure 成本管理月度摘要报告
生成时间: 2025-11-19 10:30:00
统计周期: 2025-10-20 至 2025-11-19
============================================================

--- 订阅: Production (a1b2c3d4-e5f6-7890-abcd-ef1234567890) ---
  [Virtual Machines] $342.58 USD
  [Azure SQL Database] $128.30 USD
  [Storage Accounts] $67.45 USD
  [App Service] $52.00 USD
  [Azure Kubernetes Service] $41.20 USD
  小计: $631.53

--- 订阅: Development (b2c3d4e5-f6a7-8901-bcde-f12345678901) ---
  [Virtual Machines] $85.20 USD
  [Storage Accounts] $12.30 USD
  [App Service] $22.00 USD
  [Azure Database for PostgreSQL] $18.50 USD
  [Virtual Network] $5.60 USD
  小计: $143.60

============================================================
所有订阅合计: $775.13 USD
============================================================

报告已保存至: .\AzureCostSummary_20251119.txt
```

## 注意事项

1. **API 版本兼容性**：Cost Management REST API 版本迭代较快，本文使用 `2023-11-01`。如果遇到错误，请查阅 Azure 官方文档确认当前可用的最新稳定版本，并相应更新脚本中的 `api-version` 参数。

2. **权限要求**：执行成本查询需要订阅级别的 `Microsoft.CostManagement/query/action` 权限，创建预算需要 `Microsoft.Consumption/budgets/write` 权限。建议为自动化服务主体分配"成本管理读者"（Cost Management Reader）或"参与者"（Contributor）角色。

3. **数据延迟**：Azure Cost Management 的消费数据存在约 8-24 小时的延迟。如果你需要实时监控，建议结合 Azure Monitor 的指标告警，对关键资源（如虚拟机 CPU 利用率）设置实时阈值。

4. **停止与释放的区别**：Azure 虚拟机"停止"（Stopped）状态仍会收取计算费用，只有"释放"（Deallocated）状态才停止计费。在脚本中调用 `Stop-AzVM` 时务必加上 `-StayProvisioned:$false` 参数确保释放资源。

5. **多订阅批量操作**：在遍历多个订阅时，每次都需要通过 `Set-AzContext` 切换上下文。如果订阅数量很多，建议使用 `-AsJob` 参数将查询并行化，或者利用 Azure Resource Graph 进行跨订阅查询，效率更高。

6. **费用估算的准确性**：脚本中对闲置资源的费用估算是近似值，实际费用取决于 SKU、区域和预留实例折扣等因素。做最终决策前，建议在 Azure 门户的定价计算器中验证具体金额。
