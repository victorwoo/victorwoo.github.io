---
layout: post
date: 2025-09-12 08:00:00
updated: 2025-09-12 08:00:00
title: "PowerShell 技能连载 - DNS 记录管理"
description: PowerTip of the Day - DNS Record Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- dns
- dns-records
- name-resolution
---

_适用于 PowerShell 5.1（Windows），需要 DnsServer 模块及管理员权限_

在企业网络管理中，DNS 记录的维护是一项高频且容易出错的工作。当服务器迁移、应用上线或域名变更时，运维人员需要快速准确地添加、修改或删除 DNS 记录。手动操作 DNS 管理控制台不仅效率低下，还容易因为误操作导致服务中断。

Windows Server 自带的 DnsServer 模块提供了一整套 PowerShell cmdlet，能够以脚本化的方式管理 DNS 区域中的各类记录。结合 PowerShell 的管道和循环能力，我们可以实现批量操作、配置审计和自动化巡检，大幅提升运维效率和准确性。

本文将介绍如何使用 DnsServer 模块完成 DNS 记录的查询、创建、修改和删除操作，并提供批量管理的实用脚本模板。

## 查询 DNS 记录

查询是最基础的操作。使用 `Get-DnsServerResourceRecord` 可以列出指定区域中的所有记录，也可以按名称和类型精确筛选。下面演示了几种常见的查询方式。

```powershell
# 导入 DnsServer 模块
Import-Module DnsServer

# 列出指定区域的所有 A 记录
Get-DnsServerResourceRecord -ZoneName "contoso.com" -RRType A |
    Select-Object -First 10

# 按主机名精确查询
Get-DnsServerResourceRecord -ZoneName "contoso.com" -Name "webapp01"

# 按名称模糊查询——找出所有包含 "test" 的记录
Get-DnsServerResourceRecord -ZoneName "contoso.com" |
    Where-Object { $_.HostName -like "*test*" } |
    Format-Table HostName, RecordType, RecordData -AutoSize
```

执行结果示例：

```
HostName  RecordType Timestamp            RecordData
--------  ---------- ---------            ----------
webapp01  A          2025/9/10 上午 10:30  10.0.1.100
dbserver  A          2025/9/8  上午 9:15   10.0.2.50
mail      A          2025/9/1  下午 3:00   10.0.3.10

HostName  RecordType Timestamp            RecordData
--------  ---------- ---------            ----------
webapp01  A          2025/9/10 上午 10:30  10.0.1.100

HostName    RecordType Timestamp            RecordData
--------    ---------- ---------            ----------
test-api    A          2025/9/9  上午 11:20  10.0.5.80
test-web    A          2025/9/7  下午 2:45   10.0.5.81
test-db     CNAME      2025/9/5  上午 8:00   dbserver.contoso.com.
```

## 创建 DNS 记录

使用 `Add-DnsServerResourceRecord` 系列 cmdlet 可以创建不同类型的 DNS 记录。常用的包括 A 记录、CNAME 记录、MX 记录和 TXT 记录。创建时需要指定区域名称、记录名称和对应的值。

下面展示如何创建几种常见的 DNS 记录类型。

```powershell
# 创建 A 记录——将 webapp02.contoso.com 指向 10.0.1.200
Add-DnsServerResourceRecordA -ZoneName "contoso.com" `
    -Name "webapp02" `
    -IPv4Address "10.0.1.200" `
    -TimeToLive 01:00:00

# 创建 CNAME 记录——将 www 指向 webapp01
Add-DnsServerResourceRecordCName -ZoneName "contoso.com" `
    -Name "www" `
    -HostNameAlias "webapp01.contoso.com" `
    -TimeToLive 01:00:00

# 创建 MX 记录——邮件交换记录
Add-DnsServerResourceRecordMX -ZoneName "contoso.com" `
    -Name "." `
    -MailExchange "mail.contoso.com" `
    -Preference 10 `
    -TimeToLive 01:00:00

# 创建 TXT 记录——例如 SPF 记录
Add-DnsServerResourceRecordTxt -ZoneName "contoso.com" `
    -Name "@" `
    -DescriptiveText "v=spf1 ip4:10.0.0.0/8 -all" `
    -TimeToLive 01:00:00

# 验证刚创建的记录
Get-DnsServerResourceRecord -ZoneName "contoso.com" -Name "webapp02"
```

执行结果示例：

```
HostName  RecordType Timestamp            RecordData
--------  ---------- ---------            ----------
webapp02  A          2025/9/12 上午 8:05   10.0.1.200
```

## 批量导入 DNS 记录

在实际运维场景中，经常需要根据 CSV 文件批量导入 DNS 记录，例如新机房上线或大批量服务迁移。以下脚本从一个结构化的 CSV 文件中读取记录信息，逐条创建对应的 DNS 记录，并在完成后输出操作摘要。

首先准备 CSV 文件 `dns-records.csv`，格式如下：

```
Name,Type,Value,TTL
app-server01,A,10.0.10.50,3600
app-server02,A,10.0.10.51,3600
api-gateway,CNAME,app-server01.contoso.com,3600
```

然后运行批量导入脚本：

```powershell
# 批量导入 DNS 记录
$zoneName = "contoso.com"
$csvPath = "C:\Scripts\dns-records.csv"
$records = Import-Csv -Path $csvPath

$successCount = 0
$failCount = 0
$results = @()

foreach ($record in $records) {
    $ttl = New-TimeSpan -Seconds $record.TTL

    try {
        switch ($record.Type) {
            "A" {
                Add-DnsServerResourceRecordA -ZoneName $zoneName `
                    -Name $record.Name `
                    -IPv4Address $record.Value `
                    -TimeToLive $ttl `
                    -ErrorAction Stop
            }
            "CNAME" {
                Add-DnsServerResourceRecordCName -ZoneName $zoneName `
                    -Name $record.Name `
                    -HostNameAlias $record.Value `
                    -TimeToLive $ttl `
                    -ErrorAction Stop
            }
            default {
                Write-Warning "不支持的记录类型: $($record.Type) ($($record.Name))"
                continue
            }
        }

        $successCount++
        $results += [PSCustomObject]@{
            Name   = $record.Name
            Type   = $record.Type
            Value  = $record.Value
            Status = "成功"
        }
        Write-Host "  [OK] $($record.Type) 记录: $($record.Name) -> $($record.Value)" -ForegroundColor Green
    }
    catch {
        $failCount++
        $results += [PSCustomObject]@{
            Name   = $record.Name
            Type   = $record.Type
            Value  = $record.Value
            Status = "失败: $($_.Exception.Message)"
        }
        Write-Host "  [FAIL] $($record.Type) 记录: $($record.Name) -> $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 输出操作摘要
Write-Host "`n===== 导入摘要 =====" -ForegroundColor Cyan
Write-Host "成功: $successCount 条"
Write-Host "失败: $failCount 条"
Write-Host "总计: $($records.Count) 条"
$results | Format-Table -AutoSize
```

执行结果示例：

```
  [OK] A 记录: app-server01 -> 10.0.10.50
  [OK] A 记录: app-server02 -> 10.0.10.51
  [OK] CNAME 记录: api-gateway -> app-server01.contoso.com

===== 导入摘要 =====
成功: 3 条
失败: 0 条
总计: 3 条

Name          Type  Value                           Status
----          ----  -----                           ------
app-server01  A     10.0.10.50                      成功
app-server02  A     10.0.10.51                      成功
api-gateway   CNAME app-server01.contoso.com        成功
```

## 修改和删除 DNS 记录

DNS 记录的修改需要先获取旧记录的引用，然后用新值创建一条记录覆盖旧记录。删除操作则相对简单，直接指定名称和类型即可。以下脚本演示了如何安全地更新 IP 地址并清理过期记录。

```powershell
$zoneName = "contoso.com"

# 修改 A 记录——更新 webapp01 的 IP 地址
$oldRecord = Get-DnsServerResourceRecord -ZoneName $zoneName `
    -Name "webapp01" -RRType A |
    Select-Object -First 1

$newRecord = $oldRecord.Clone()
$newRecord.RecordData.IPv4Address = [System.Net.IPAddress]::Parse("10.0.1.150")

Set-DnsServerResourceRecord -ZoneName $zoneName `
    -OldInputObject $oldRecord `
    -NewInputObject $newRecord

Write-Host "已将 webapp01 的 IP 从 $($oldRecord.RecordData.IPv4Address) 更新为 $($newRecord.RecordData.IPv4Address)"

# 删除指定记录
Remove-DnsServerResourceRecord -ZoneName $zoneName `
    -Name "webapp02" `
    -RRType A `
    -Force `
    -Confirm:$false

Write-Host "已删除 webapp02 的 A 记录"

# 验证修改结果
Get-DnsServerResourceRecord -ZoneName $zoneName -Name "webapp01"
```

执行结果示例：

```
已将 webapp01 的 IP 从 10.0.1.100 更新为 10.0.1.150
已删除 webapp02 的 A 记录

HostName  RecordType Timestamp            RecordData
--------  ---------- ---------            ----------
webapp01  A          2025/9/12 上午 8:10   10.0.1.150
```

## DNS 记录审计报告

定期审计 DNS 记录有助于发现残留的过期记录、重复指向和异常配置。以下脚本生成一份简洁的审计报告，包含各类型记录的统计信息和即将过期的静态记录。

```powershell
$zoneName = "contoso.com"

# 获取所有记录
$allRecords = Get-DnsServerResourceRecord -ZoneName $zoneName

# 按类型统计
$summary = $allRecords |
    Group-Object RecordType |
    Sort-Object Count -Descending

Write-Host "===== DNS 区域审计报告: $zoneName =====" -ForegroundColor Cyan
Write-Host "生成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"

foreach ($group in $summary) {
    $pct = [math]::Round(($group.Count / $allRecords.Count) * 100, 1)
    Write-Host ("{0,-10} {1,5} 条 ({2,5}%)" -f $group.Name, $group.Count, $pct)
}

Write-Host "`n总计: $($allRecords.Count) 条记录"

# 检查可能的过期 A 记录（超过 30 天未更新的静态记录）
$cutoff = (Get-Date).AddDays(-30)
$staleRecords = $allRecords | Where-Object {
    $_.RecordType -eq "A" -and
    $_.Timestamp -lt $cutoff -and
    $_.Timestamp -gt [datetime]::MinValue
}

if ($staleRecords) {
    Write-Host "`n--- 可能过期的 A 记录 (超过 30 天未更新) ---" -ForegroundColor Yellow
    foreach ($rec in $staleRecords) {
        Write-Host ("  {0,-25} -> {1,-15} (最后更新: {2})" -f `
            $rec.HostName, `
            $rec.RecordData.IPv4Address, `
            ($rec.Timestamp.ToString("yyyy-MM-dd")))
    }
    Write-Host "`n共 $($staleRecords.Count) 条可能过期的记录，建议人工确认后清理。"
}
else {
    Write-Host "`n未发现超过 30 天未更新的动态 A 记录。" -ForegroundColor Green
}
```

执行结果示例：

```
===== DNS 区域审计报告: contoso.com =====
生成时间: 2025-09-12 08:15:00

A          42 条 ( 52.5%)
CNAME      18 条 ( 22.5%)
MX          3 条 (  3.8%)
TXT        12 条 ( 15.0%)
SRV         5 条 (  6.3%)

总计: 80 条记录

--- 可能过期的 A 记录 (超过 30 天未更新) ---
  legacy-app                  -> 10.0.99.10      (最后更新: 2025-07-15)
  old-printer                 -> 10.0.99.20      (最后更新: 2025-06-28)

共 2 条可能过期的记录，建议人工确认后清理。
```

## 注意事项

1. **管理员权限要求**：DnsServer 模块的所有写操作（添加、修改、删除）都需要以管理员身份运行 PowerShell。可以在脚本开头添加 `#Requires -RunAsAdministrator` 确保权限正确。

2. **区域名称区分大小写**：虽然 DNS 协议本身不区分大小写，但在 PowerShell cmdlet 中传入区域名称时应保持与 DNS 服务器上的一致，避免因大小写差异导致查询失败。

3. **TTL 设置要合理**：为即将变更的记录设置较短的 TTL（如 300 秒），可以缩短切换期间的 DNS 缓存影响；长期稳定的记录则可使用较长的 TTL（如 3600 秒）以减轻 DNS 服务器负载。

4. **修改记录必须使用 Clone 方法**：`Set-DnsServerResourceRecord` 要求同时提供旧记录和新记录对象。务必使用 `Clone()` 方法创建副本再修改，直接修改原始对象会导致比较失败。

5. **批量操作建议使用事务日志**：在批量导入或大规模变更前，先将现有记录导出为 CSV 备份。如果脚本中途出错，可以快速回滚到原始状态。

6. **CNAME 与 A 记录的冲突**：同一个主机名不能同时存在 CNAME 记录和其他类型的记录。如果需要将 CNAME 改为 A 记录，必须先删除 CNAME 再创建 A 记录，顺序不能颠倒。
