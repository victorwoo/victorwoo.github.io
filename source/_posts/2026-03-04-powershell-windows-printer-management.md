---
layout: post
date: 2026-03-04 08:00:00
updated: 2026-03-04 08:00:00
title: "PowerShell 技能连载 - 打印机与打印服务管理"
description: PowerTip of the Day - Printer and Print Service Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- printer
- print-server
- windows
- management
---

_适用于 PowerShell 5.1 及以上版本_

在企业 IT 运维中，打印机管理看似简单，实则是一项高频且容易出问题的工作。新员工入职需要分配部门打印机、打印队列卡住需要及时清理、驱动更新需要在多台终端上统一部署——这些操作如果手动执行，不仅耗时而且容易出错。

Windows Server 2012 引入了 PrintManagement 模块，其中包含 `Printer`、`PrinterDriver`、`PrinterPort`、`PrintJob` 等一系列 cmdlet，几乎覆盖了打印机生命周期的所有管理场景。结合 PowerShell 的远程执行能力，可以轻松实现集中化的打印服务管理。

本文将从基础安装配置、批量部署映射、监控故障排查三个层面，介绍如何使用 PowerShell 构建一套完整的打印机管理方案。

## 打印机基础管理

打印机的基础管理包括安装驱动程序、创建 TCP/IP 打印端口以及添加打印机实例。下面这段脚本演示了完整的流程：

```powershell
# 导入 PrintManagement 模块（Windows 8/Server 2012 及以上自带）
Import-Module PrintManagement

# 定义打印机配置参数
$PrinterConfig = @{
    DriverName = 'HP Universal Printing PCL 6'
    DriverInf  = '\\fileserver\drivers\HP\hpcu250u.inf'
    PortName   = 'IP_192.168.1.100'
    IPAddress  = '192.168.1.100'
    PrinterName = 'HP-LaserJet-Finance-3F'
    Location   = '3F-Finance-Dept'
    Comment    = '财务部3楼共享打印机'
}

# 第一步：安装打印机驱动（如果尚未安装）
$existingDriver = Get-PrinterDriver -Name $PrinterConfig.DriverName -ErrorAction SilentlyContinue

if (-not $existingDriver) {
    Add-PrinterDriver -Name $PrinterConfig.DriverName -InfPath $PrinterConfig.DriverInf
    Write-Host "已安装驱动: $($PrinterConfig.DriverName)" -ForegroundColor Green
} else {
    Write-Host "驱动已存在，跳过安装: $($PrinterConfig.DriverName)" -ForegroundColor Yellow
}

# 第二步：创建 TCP/IP 打印端口
$existingPort = Get-PrinterPort -Name $PrinterConfig.PortName -ErrorAction SilentlyContinue

if (-not $existingPort) {
    Add-PrinterPort -Name $PrinterConfig.PortName -PrinterHostAddress $PrinterConfig.IPAddress
    Write-Host "已创建端口: $($PrinterConfig.PortName)" -ForegroundColor Green
} else {
    Write-Host "端口已存在，跳过创建: $($PrinterConfig.PortName)" -ForegroundColor Yellow
}

# 第三步：添加打印机
$existingPrinter = Get-Printer -Name $PrinterConfig.PrinterName -ErrorAction SilentlyContinue

if (-not $existingPrinter) {
    Add-Printer `
        -Name $PrinterConfig.PrinterName `
        -DriverName $PrinterConfig.DriverName `
        -PortName $PrinterConfig.PortName `
        -Location $PrinterConfig.Location `
        -Comment $PrinterConfig.Comment

    Write-Host "已添加打印机: $($PrinterConfig.PrinterName)" -ForegroundColor Green
} else {
    Write-Host "打印机已存在: $($PrinterConfig.PrinterName)" -ForegroundColor Yellow
}

# 验证安装结果
Get-Printer -Name $PrinterConfig.PrinterName |
    Select-Object Name, DriverName, PortName, Location, PrinterStatus |
    Format-List
```

执行结果示例：

```text
驱动已存在，跳过安装: HP Universal Printing PCL 6
已创建端口: IP_192.168.1.100
已添加打印机: HP-LaserJet-Finance-3F

Name          : HP-LaserJet-Finance-3F
DriverName    : HP Universal Printing PCL 6
PortName      : IP_192.168.1.100
Location      : 3F-Finance-Dept
PrinterStatus : Normal
```

脚本中对每一步都做了幂等检查：如果驱动、端口或打印机已经存在，则跳过而不报错。这种写法非常适合放在配置管理工具（如 DSC、Ansible）中反复执行。

## 批量部署与映射

在企业环境中，通常需要按部门为用户批量映射打印机。下面的脚本展示了如何根据部门映射关系表，将打印机部署到对应的工作站：

```powershell
# 定义部门与打印机的映射关系
$PrinterMapping = @(
    @{
        Department      = 'Finance'
        Printers        = @('HP-LaserJet-Finance-3F', 'HP-ColorJet-Finance-3F')
        DefaultPrinter  = 'HP-LaserJet-Finance-3F'
    }
    @{
        Department      = 'HR'
        Printers        = @('HP-LaserJet-HR-5F')
        DefaultPrinter  = 'HP-LaserJet-HR-5F'
    }
    @{
        Department      = 'Engineering'
        Printers        = @('HP-LaserJet-Eng-8F', 'Canon-Eng-LargeFormat')
        DefaultPrinter  = 'HP-LaserJet-Eng-8F'
    }
)

# 远程打印服务器
$PrintServer = 'PRINTSRV01'

# 根据当前用户所属部门自动映射打印机
function Install-DepartmentPrinters {
    param(
        [string[]]$UserDepartments,
        [string]$Server = 'PRINTSRV01'
    )

    foreach ($dept in $UserDepartments) {
        $mapping = $PrinterMapping | Where-Object { $_.Department -eq $dept }

        if (-not $mapping) {
            Write-Warning "未找到部门 '$dept' 的打印机映射配置"
            continue
        }

        Write-Host "`n=== 正在为部门 [$dept] 映射打印机 ===" -ForegroundColor Cyan

        foreach ($printerName in $mapping.Printers) {
            $fullPath = "\\$Server\$printerName"

            try {
                # 检查打印机是否已映射
                $existing = Get-Printer -Name $fullPath -ErrorAction SilentlyContinue

                if (-not $existing) {
                    Add-Printer -ConnectionName $fullPath
                    Write-Host "  已映射: $printerName" -ForegroundColor Green
                } else {
                    Write-Host "  已存在: $printerName" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "  映射失败: $printerName - $($_.Exception.Message)" -ForegroundColor Red
            }
        }

        # 设置默认打印机
        if ($mapping.DefaultPrinter) {
            $defaultPath = "\\$Server\$($mapping.DefaultPrinter)"
            $defaultPrinter = Get-Printer -Name $defaultPath -ErrorAction SilentlyContinue

            if ($defaultPrinter) {
                # 使用 rundll32 设置默认打印机（兼容性好）
                $null = rundll32.exe printui.dll,PrintUIEntry /y /n $defaultPath
                Write-Host "  已设为默认: $($mapping.DefaultPrinter)" -ForegroundColor Green
            }
        }
    }
}

# 模拟：从 Active Directory 获取用户部门信息
$userDepartment = 'Finance'

# 执行映射
Install-DepartmentPrinters -UserDepartments $userDepartment -Server $PrintServer

# 输出当前已安装的打印机列表
Write-Host "`n=== 当前已映射的打印机 ===" -ForegroundColor Cyan
Get-Printer | Where-Object { $_.Type -eq 'Connection' } |
    Select-Object Name, Location, Comment |
    Format-Table -AutoSize
```

执行结果示例：

```text
=== 正在为部门 [Finance] 映射打印机 ===
  已映射: HP-LaserJet-Finance-3F
  已映射: HP-ColorJet-Finance-3F
  已设为默认: HP-LaserJet-Finance-3F

=== 当前已映射的打印机 ===
Name                                    Location         Comment
----                                    --------         -------
\\PRINTSRV01\HP-LaserJet-Finance-3F     3F-Finance-Dept  财务部3楼共享打印机
\\PRINTSRV01\HP-ColorJet-Finance-3F     3F-Finance-Dept  财务部3楼彩色打印机
```

这段脚本可以打包成登录脚本（Logon Script），通过组策略（GPO）分发给所有域用户。用户登录后自动根据其部门信息完成打印机映射和默认设置，无需手动干预。

## 监控与故障排查

打印队列堵塞是日常运维中常见的故障。下面这段脚本提供了队列监控、作业管理和驱动诊断的能力：

```powershell
# 打印服务器监控脚本
$PrintServer = 'PRINTSRV01'

# 获取所有打印机及其队列状态
Write-Host "=== 打印机状态总览 ===" -ForegroundColor Cyan
$allPrinters = Get-Printer -ComputerName $PrintServer

$allPrinters |
    Select-Object Name,
        @{N='状态';E={
            switch ($_.PrinterStatus) {
                0 { 'Paused' }
                1 { 'Error' }
                2 { 'Pending Deletion' }
                3 { 'Paper Jam' }
                4 { 'Paper Out' }
                5 { 'Manual Feed' }
                6 { 'Offline' }
                7 { 'IO Active' }
                8 { 'Busy' }
                9 { 'Printing' }
                10 { 'Output Bin Full' }
                default { 'Ready' }
            }
        }},
        @{N='队列作业数';E={ (Get-PrintJob -PrinterName $_.Name -ErrorAction SilentlyContinue |
            Measure-Object).Count }},
        JobCountUntilNotification,
        Location |
    Format-Table -AutoSize

# 检查卡住的打印作业（超过 30 分钟仍在队列中）
Write-Host "`n=== 超时打印作业检查 ===" -ForegroundColor Cyan
$threshold = (Get-Date).AddMinutes(-30)
$stuckJobs = @()

foreach ($printer in $allPrinters) {
    $jobs = Get-PrintJob -PrinterName $printer.Name -ErrorAction SilentlyContinue

    foreach ($job in $jobs) {
        if ($job.SubmitTime -and $job.SubmitTime -lt $threshold) {
            $stuckJobs += [PSCustomObject]@{
                PrinterName = $printer.Name
                JobId       = $job.Id
                Document    = $job.DocumentName
                SubmitTime  = $job.SubmitTime
                UserName    = $job.UserName
                Size(KB)    = [math]::Round($job.Size / 1KB, 2)
            }
        }
    }
}

if ($stuckJobs) {
    Write-Host "发现 $($stuckJobs.Count) 个超时作业:" -ForegroundColor Yellow
    $stuckJobs | Format-Table -AutoSize

    # 自动清理超时作业
    $confirm = Read-Host "是否清理这些超时作业？(Y/N)"
    if ($confirm -eq 'Y') {
        foreach ($job in $stuckJobs) {
            Remove-PrintJob -PrinterName $job.PrinterName -ID $job.JobId
            Write-Host "  已删除作业: $($job.Document) (ID: $($job.JobId))" -ForegroundColor Green
        }
    }
} else {
    Write-Host "没有发现超时的打印作业" -ForegroundColor Green
}

# 驱动兼容性检查
Write-Host "`n=== 打印机驱动诊断 ===" -ForegroundColor Cyan
$drivers = Get-PrinterDriver -ComputerName $PrintServer

$drivers |
    Select-Object Name,
        @{N='环境';E={ $_.PrinterEnvironment -join ', ' }},
        @{N='驱动版本';E={ $_.DriverVersion }},
        @{N='依赖文件数';E={ ($_.DependentFiles | Measure-Object).Count }} |
    Format-Table -AutoSize

# 检查是否有驱动文件缺失
foreach ($driver in $drivers) {
    $driverPath = Join-Path $env:SystemRoot "System32\spool\drivers"
    $missingFiles = @()

    if ($driver.DependentFiles) {
        foreach ($file in $driver.DependentFiles) {
            $fullPath = Join-Path $driverPath $file
            if (-not (Test-Path $fullPath)) {
                $missingFiles += $file
            }
        }
    }

    if ($missingFiles.Count -gt 0) {
        Write-Host "驱动 '$($driver.Name)' 缺失 $($missingFiles.Count) 个文件:" -ForegroundColor Red
        $missingFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    }
}
```

执行结果示例：

```text
=== 打印机状态总览 ===
Name                        状态   队列作业数 JobCountUntilNotification Location
----                        ----   ---------- ------------------------ --------
HP-LaserJet-Finance-3F      Ready           2                       10 3F-Finance-Dept
HP-ColorJet-Finance-3F      Ready           0                       10 3F-Finance-Dept
HP-LaserJet-HR-5F           Offline         5                       10 5F-HR-Dept
HP-LaserJet-Eng-8F          Ready           0                       10 8F-Engineering
Canon-Eng-LargeFormat       Ready           1                       10 8F-Engineering

=== 超时打印作业检查 ===
发现 3 个超时作业:
PrinterName              JobId Document         SubmitTime          UserName            Size(KB)
------------              ----- --------          -----------          --------            --------
HP-LaserJet-Finance-3F       3 Q1-Report.xlsx   2026/3/4 10:15:22   CONTOSO\zhangsan       512.5
HP-LaserJet-HR-5F           12 payroll.pdf      2026/3/4 09:30:11   CONTOSO\lisi           1024.0
HP-LaserJet-HR-5F           14 onboarding.docx  2026/3/4 10:05:45   CONTOSO\wangwu         256.75

是否清理这些超时作业？(Y/N): Y
  已删除作业: Q1-Report.xlsx (ID: 3)
  已删除作业: payroll.pdf (ID: 12)
  已删除作业: onboarding.docx (ID: 14)

=== 打印机驱动诊断 ===
Name                               环境                          驱动版本  依赖文件数
----                               ----                          --------  ----------
HP Universal Printing PCL 6        Windows x64, Windows x86      6.0.1             24
Canon Generic Plus UFR II Driver   Windows x64                   3.1.0             18
```

这个监控脚本可以集成到定时任务中，每隔一段时间自动扫描打印服务器，发现超时作业和驱动异常时发送告警邮件或钉钉/企业微信通知。

## 注意事项

- PrintManagement 模块仅在 Windows 8 / Windows Server 2012 及以上版本中可用。如果需要在更旧的系统上管理打印机，需要通过 WMI（`Win32_Printer` 类）或 `rundll32 printui.dll` 命令实现。
- 使用 `Add-Printer -ConnectionName` 映射网络打印机时，需要确保 Print Server 的共享权限正确配置，否则会出现"拒绝访问"错误。建议在域环境中通过组策略统一管理权限。
- 清理打印作业前务必确认作业确实卡住（而非用户正在打印大文件）。可以通过文件大小和提交时间综合判断，避免误删正在执行的大文档打印任务。
- 打印机驱动安装涉及 INF 文件路径。如果驱动存放在网络共享路径上，需要确保执行脚本的账户对该共享有读取权限，且路径使用 UNC 格式（如 `\\fileserver\drivers\...`）。
- 远程管理打印服务器时（使用 `-ComputerName` 参数），需要确保 WinRM 服务已启用，且目标服务器防火墙放行了 RPC 动态端口范围。跨子网管理时可能需要配置 WinRM 的 TrustedHosts。
- 在大规模环境中（数百台打印机以上），建议将打印机配置信息存储在 CMDB 或数据库中，脚本从数据源读取配置而非硬编码。这样可以与企业的 IP 地址管理系统（IPAM）联动，实现打印机全生命周期管理。
