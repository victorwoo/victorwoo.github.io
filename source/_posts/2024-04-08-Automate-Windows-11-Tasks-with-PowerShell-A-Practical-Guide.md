---
layout: post
date: 2024-04-08 00:00:00
title: "PowerShell 技能连载 - 使用 PowerShell 自动化 Windows 11 任务：实用指南"
description: "Automate Windows 11 Tasks with PowerShell: A Practical Guide"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
您想通过自动化Windows 11系统上的各种任务来节省时间和精力吗？如果是这样，您应该学习如何使用PowerShell，这是一种强大的脚本语言和命令行工具，可以帮助您更快速、更轻松地完成任务。在本博客中，我们将向您展示如何使用PowerShell来自动化Windows 11上常见或复杂任务的一些实际示例，例如：

- 使用PowerShell管理网络设置和连接
- 使用PowerShell监视系统性能和资源
- 使用PowerShell备份和恢复文件夹与文件
- 使用PowerShell安装和更新Windows功能
- 使用PowerShell创建并运行定时任务

## 使用 PowerShell 管理网络设置与连接

PowerShell 可以帮助您轻松高效地管理 Windows 11 系统上的网络设置与连接。您可以使用 PowerShell 执行各种操作，比如配置 IP 地址、DNS 服务器、防火墙、代理以及 VPN。 您还可以使用 PowerShell 测试网络连通性、ping 命令、traceroute 和解析主机名。

```powershell
# 定义接口别名, IP 地址, 子网掩码, 网关 和 DNS 服务器
$interface = "Ethernet"
$ip = "192.168.1.100"
$subnet = "255.255.255.0"
$gateway = "192.168.1.1"
$dns = "8.8.8.8"

# 设置接口的IP地址, DNS服务器 和 防火墙配置文件
Set-NetIPAddress -InterfaceAlias $interface -IPAddress $ip -PrefixLength $subnet -DefaultGateway $gateway
Set-DnsClientServerAddress -InterfaceAlias $interface -ServerAddresses $dns
Set-NetFirewallProfile -Profile Private -Enabled True
```

## 使用 PowerShell 监控系统性能和资源

PowerShell 可以帮助您轻松高效地监控 Windows 11 系统的系统性能和资源。您可以使用 PowerShell 执行各种操作，如获取 CPU、内存、磁盘和网络使用情况，测量命令或脚本的执行时间和内存消耗，并生成性能报告和图表。

```powershell
# PowerShell script for monitoring system performance
# Define the performance counters for CPU and memory usage
$cpu = "\Processor(_Total)\% Processor Time"
$memory = "\Memory\Available MBytes"

# Get the performance counter data for CPU and memory usage
$data = Get-Counter -Counter $cpu,$memory -SampleInterval 1 -MaxSamples 10

# Create a chart object from the performance counter data
$chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
$chart.Width = 800
$chart.Height = 600
$chart.BackColor = "White"

# Add a chart area, a series for CPU usage, a series for memory usage, and a legend to the chart object
$area = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
$area.AxisX.Title = "Time (seconds)"
$area.AxisY.Title = "Usage (%)"
$area.AxisY2.Title = "Available (MB)"
$chart.ChartAreas.Add($area)

$series1 = New-Object System.Windows.Forms.DataVisualization.Charting.Series
$series1.Name = "CPU"
$series1.ChartType = "Line"
$series1.Color = "Red"
$series1.BorderWidth = 3
$series1.Points.DataBindXY($data.Timestamps,$data.CounterSamples[0].CookedValue)
$chart.Series.Add($series1)

$series2 = New-Object System.Windows.Forms.DataVisualization.Charting.Series
$series2.Name = "Memory"
$series2.ChartType = "Line"
$series2.Color = "Blue"
$series2.BorderWidth = 3
$series2.YAxisType = "Secondary"
$series2.Points.DataBindXY($data.Timestamps,$data.CounterSamples[1].CookedValue)
$chart.Series.Add($series2)

$legend = New-Object System.Windows.Forms.DataVisualization.Charting.Legend
$legend.Docking = "Top"
$chart.Legends.Add($legend)

# Save the chart object as an image file
$chart.SaveImage("C:\Performance.png","png")

```

## 使用 PowerShell 备份和恢复文件夹

PowerShell 可以帮助您轻松高效地备份和恢复 Windows 11 系统中的文件夹。您可以使用 PowerShell 执行各种操作，如创建、复制、移动、重命名、删除、搜索和压缩文件夹。您还可以使用 PowerShell 创建和使用备份策略、备份集和备份项。

```powershell
# PowerShell script for backing up and restoring files and folders
# Define the folder to backup and the backup location
$folder = "C:\Users\YourName\Documents"
$location = "D:\Backup"

# Create a backup policy that runs daily and keeps backups for 30 days
$policy = New-BackupPolicy -Frequency Daily -RetentionPeriod 30

# Set the backup policy for the computer
Set-BackupPolicy -Policy $policy

# Backup the folder to the backup location
Backup-File -Source $folder -Destination $location
```

Here is a summary of a PowerShell script that restores a file or folder from a backup to a specified location:

```powershell
# Define the file or folder to restore and the restore location
$file = "C:\Users\YourName\Documents\Report.docx"
$location = "C:\Users\YourName\Desktop"

# Get the latest backup set that contains the file or folder
$set = Get-BackupSet | Sort-Object -Property CreationTime -Descending | Select-Object -First 1

# Get the backup item that matches the file or folder
$item = Get-BackupItem -BackupSet $set -Path $file

# Restore the file or folder to the restore location
Restore-File -BackupItem $item -Destination $location

```

## 使用 PowerShell 安装和更新 Windows 功能

PowerShell 可以帮助您轻松高效地在 Windows 11 系统上安装和更新 Windows 功能。您可以使用 PowerShell 执行各种操作，如列出、启用、禁用或更新诸如 Hyper-V、Windows 子系统 for Linux 或 Windows 沙盒等 Windows 功能。

```powershell
# 用于安装和更新 Windows 功能的 PowerShell 脚本
# 在计算机上安装 Hyper-V 功能
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart
```

以下是一个概要说明了一个 PowerShell 脚本，该脚本从计算机中卸载了 Windows 子系统 for Linux 功能并移除相关文件：

```powershell
# 从计算机中卸载 Windows 子系统 for Linux 功能
Uninstall-WindowsFeature -Name Microsoft-Windows-Subsystem-Linux -Remove
```

## 使用 PowerShell 创建和运行定时任务

PowerShell 可以帮助您轻松高效地在 Windows 11 系统上创建和运行定时任务。您可以使用 PowerShell 执行各种操作，如创建、注册、启动、停止或禁用定时任务，例如运行一个 PowerShell 脚本、发送电子邮件或显示消息。

```powershell
# 用于创建和运行定时任务的 PowerShell 脚本
# 定义要运行的 PowerShell 脚本
$script = "C:\Scripts\Backup.ps1"

# 创建一个新的定时任务动作来运行这个 PowerShell 脚本
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File $script"

# 创建一个新的触发器，在每天早上10点执行该任务
$trigger = New-ScheduledTaskTrigger -Daily -At 10am

# 创建一组新的设置，如果任务执行时间过长则停止该任务
$setting = New-ScheduledTaskSettingSet -ExecutionTimeLimit (New-TimeSpan -Minutes 30)

# 在计算机上注册这个新的定时任务，并指定名称、动作、触发器及设置
Register-ScheduledTask –Name "Backup" –Action $action –Trigger $trigger –Setting $setting
```

## 结论

PowerShell 是一款多才多艺且强大的工具，可帮助您自动化处理在Windows 11系统上进行各种操作。您可以在官方PowerShell文档中找到更多关于PowerShell 的信息和示例。感谢阅读此篇博客文章。希望对你有所帮助并且有趣。 😊

<!--本文国际来源：[Automate Windows 11 Tasks with PowerShell: A Practical Guide](https://powershellguru.com/automate-windows-11-tasks-with-powershell/)-->
