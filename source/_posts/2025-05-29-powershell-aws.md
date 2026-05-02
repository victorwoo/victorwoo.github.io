---
layout: post
date: 2025-05-29 08:00:00
updated: 2025-05-29 08:00:00
title: "PowerShell 技能连载 - AWS 自动化管理"
description: PowerTip of the Day - AWS Automation Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- aws
- cloud
- aws-tools
---

_适用于 PowerShell 5.1 及以上版本，需安装 AWS Tools for PowerShell_

Amazon Web Services（AWS）是全球最大的公有云平台，拥有最丰富的云服务生态。AWS Tools for PowerShell 让 Windows 运维人员可以用熟悉的 PowerShell 语法管理 AWS 资源，无需切换到 Python 或 AWS CLI。从 EC2 实例管理到 S3 存储操作，从 IAM 权限控制到 CloudWatch 监控，所有 AWS 服务都可以通过 PowerShell 命令操作。

本文将讲解 AWS Tools 的安装配置、EC2 实例管理、S3 存储操作，以及常见的自动化场景。

<!-- more -->

## 安装与配置

```powershell
# 安装 AWS Tools for PowerShell
Install-Module -Name AWS.Tools.Installer -Scope CurrentUser -Force
Install-AWSToolsModule AWS.Tools.EC2, AWS.Tools.S3, AWS.Tools.IAM, AWS.Tools.CloudWatch

# 查看已安装的 AWS 模块
Get-InstalledModule | Where-Object { $_.Name -match 'AWS' } |
    Select-Object Name, Version |
    Format-Table -AutoSize

# 配置 AWS 凭据（方式一：使用访问密钥）
Set-AWSCredential -AccessKey 'AKIAIOSFODNN7EXAMPLE' `
    -SecretKey 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY' `
    -StoreAs 'default'

# 配置 AWS 凭据（方式二：使用 IAM 角色的实例配置文件）
# 在 EC2 实例上运行时自动使用 IAM 角色

# 查看当前凭据
Get-AWSCredential -ListProfileDetail

# 设置默认区域
Set-DefaultAWSRegion -Region 'ap-northeast-1'

# 查看当前区域
Get-DefaultAWSRegion
```

执行结果示例：

```
Name                     Version
----                     -------
AWS.Tools.Installer      1.0.0
AWS.Tools.EC2            4.1.0
AWS.Tools.S3             4.1.0
AWS.Tools.IAM            4.1.0
AWS.Tools.CloudWatch     4.1.0

ProfileName  Store  Location
-----------  -----  --------
default      NetSDK C:\Users\admin\...

Region
------
ap-northeast-1
```

## EC2 实例管理

EC2 是 AWS 的核心计算服务：

```powershell
# 列出所有 EC2 实例
Get-EC2Instance | ForEach-Object {
    $_.RunningInstance | Select-Object InstanceId,
        @{N='类型'; E={$_.InstanceType.Value}},
        @{N='状态'; E={$_.State.Name.Value}},
        @{N='名称'; E={$_.Tags | Where-Object Key -eq 'Name' | Select-Object -ExpandProperty Value}},
        @{N='私有IP'; E={$_.PrivateIpAddress}},
        @{N='公有IP'; E={$_.PublicIpAddress}} |
        Format-Table -AutoSize
}

# 查看特定实例详情
$instanceId = "i-0abc123def456"
$detail = (Get-EC2Instance -InstanceId $instanceId).RunningInstance[0]
[PSCustomObject]@{
    实例ID   = $detail.InstanceId
    类型     = $detail.InstanceType.Value
    状态     = $detail.State.Name.Value
    AMI      = $detail.ImageId
    私有IP   = $detail.PrivateIpAddress
    公有IP   = $detail.PublicIpAddress
    子网     = $detail.SubnetId
    可用区   = $detail.Placement.AvailabilityZone
} | Format-List

# 启动/停止/重启实例
Start-EC2Instance -InstanceId $instanceId
Stop-EC2Instance -InstanceId $instanceId -Force
Restart-EC2Instance -InstanceId $instanceId

# 创建新 EC2 实例
$newInstance = New-EC2Instance -ImageId 'ami-0c3fd0f5d33134a76' `
    -InstanceType 't3.medium' `
    -KeyName 'my-key-pair' `
    -SecurityGroup @('sg-12345678') `
    -SubnetId 'subnet-abcdef12' `
    -TagSpecification @{ ResourceType = 'instance'; Tags = @{ Key = 'Name'; Value = 'web-server-01' } }

Write-Host "新实例已创建：$($newInstance.Instances[0].InstanceId)" -ForegroundColor Green
```

执行结果示例：

```
InstanceId          类型      状态     名称           私有IP       公有IP
-----------          ----      ----     ----           ------       ------
i-0abc123def456     t3.medium  running  web-server-01  10.0.1.100  52.69.x.x
i-0def456abc789     t3.small   stopped  db-server-01   10.0.2.50   N/A
i-0ghi789jkl012     t3.large   running  api-server-01  10.0.1.200  52.69.y.y

实例ID   : i-0abc123def456
类型     : t3.medium
状态     : running
AMI      : ami-0c3fd0f5d33134a76
私有IP   : 10.0.1.100
公有IP   : 52.69.x.x
子网     : subnet-abcdef12
可用区   : ap-northeast-1a
```

## S3 存储操作

S3 是 AWS 最常用的对象存储服务：

```powershell
# 列出所有 S3 存储桶
Get-S3Bucket | Select-Object BucketName, CreationDate |
    Format-Table -AutoSize

# 创建存储桶
New-S3Bucket -BucketName "my-app-backups-20250529" -Region "ap-northeast-1"

# 上传文件
Write-S3Object -BucketName "my-app-backups-20250529" `
    -File "C:\Backups\app-20250529.zip" `
    -Key "backups/app-20250529.zip"

# 上传整个目录
$files = Get-ChildItem "C:\Logs" -Recurse -File
foreach ($file in $files) {
    $key = "logs/" + $file.FullName.Replace("C:\Logs\", "").Replace("\", "/")
    Write-S3Object -BucketName "my-app-logs" -File $file.FullName -Key $key
}
Write-Host "已上传 $($files.Count) 个文件" -ForegroundColor Green

# 列出存储桶中的对象
Get-S3Object -BucketName "my-app-backups-20250529" |
    Select-Object Key,
        @{N='大小MB'; E={[math]::Round($_.Size/1MB, 2)}},
        LastModified |
    Sort-Object LastModified -Descending |
    Format-Table -AutoSize

# 下载文件
Read-S3Object -BucketName "my-app-backups-20250529" `
    -Key "backups/app-20250529.zip" `
    -File "C:\Downloads\app-20250529.zip"

# 删除对象
Remove-S3Object -BucketName "my-app-backups-20250529" `
    -Key "backups/old-backup.zip" -Force
```

执行结果示例：

```
BucketName                CreationDate
----------                ------------
my-app-backups-20250529   2025-05-29 08:00:00
my-app-logs               2024-01-15 10:30:00

已上传 45 个文件

Key                          大小MB  LastModified
---                          ------  -------------
backups/app-20250529.zip     234.56  2025-05-29 08:30:00
backups/app-20250528.zip     228.12  2025-05-28 08:30:00
```

## IAM 用户与角色管理

```powershell
# 列出 IAM 用户
Get-IAMUser | Select-Object UserName, CreateDate,
    @{N='最后活动'; E={$_.PasswordLastUsed?.ToString('yyyy-MM-dd') ?? '从未'}} |
    Format-Table -AutoSize

# 创建 IAM 用户
New-IAMUser -UserName "automation-service"

# 创建访问密钥
$keys = New-IAMAccessKey -UserName "automation-service"
Write-Host "Access Key: $($keys.AccessKeyId)" -ForegroundColor Cyan
Write-Host "Secret Key: $($keys.SecretAccessKey)" -ForegroundColor Yellow

# 附加策略到用户
Register-IAMUserPolicy -UserName "automation-service" `
    -PolicyArn "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"

# 列出用户的策略
Get-IAMUserPolicyList -UserName "automation-service"

# 创建 IAM 角色（用于 EC2 实例配置文件）
$rolePolicy = @{
    Version = "2012-10-17"
    Statement = @(
        @{
            Effect = "Allow"
            Principal = @{ Service = "ec2.amazonaws.com" }
            Action = "sts:AssumeRole"
        }
    )
} | ConvertTo-Json -Depth 5

New-IAMRole -RoleName "EC2-BackupRole" -AssumeRolePolicyDocument $rolePolicy

# 附加策略到角色
Register-IAMRolePolicy -RoleName "EC2-BackupRole" `
    -PolicyArn "arn:aws:iam::aws:policy/AmazonS3FullAccess"
```

执行结果示例：

```
UserName            CreateDate           最后活动
--------            -----------          --------
admin               2024-01-15 10:00:00  2025-05-29
automation-service  2025-05-29 08:00:00  从未

Access Key: AKIAIOSFODNN7EXAMPLE
Secret Key: wJalrXUtnFEMI/...

AmazonEC2ReadOnlyAccess
```

## CloudWatch 监控

```powershell
# 获取 EC2 实例的 CPU 使用率
$endTime = Get-Date
$startTime = $endTime.AddHours(-24)

$cpuMetrics = Get-CWMetricStatistics `
    -Namespace "AWS/EC2" `
    -MetricName "CPUUtilization" `
    -Dimension @{ Name = "InstanceId"; Value = "i-0abc123def456" } `
    -StartTime $startTime `
    -EndTime $endTime `
    -Period 3600 `
    -Statistic "Average"

$cpuMetrics.Datapoints | Sort-Object Timestamp |
    Select-Object Timestamp,
        @{N='CPU平均%'; E={[math]::Round($_.Average, 1)}} |
    Format-Table -AutoSize

# 设置告警
Write-CWAlarm -AlarmName "High-CPU-WebServer" `
    -AlarmDescription "Web 服务器 CPU 使用率超过 80%" `
    -Namespace "AWS/EC2" `
    -MetricName "CPUUtilization" `
    -Dimension @{ Name = "InstanceId"; Value = "i-0abc123def456" } `
    -Statistic "Average" `
    -Period 300 `
    -EvaluationPeriod 2 `
    -Threshold 80 `
    -ComparisonOperator "GreaterThanThreshold" `
    -AlarmAction @("arn:aws:sns:ap-northeast-1:123456789:alerts")

Write-Host "告警已创建" -ForegroundColor Green
```

执行结果示例：

```
Timestamp            CPU平均%
---------            --------
2025-05-28 09:00:00     15.3
2025-05-28 10:00:00     22.7
2025-05-28 11:00:00     45.2
2025-05-28 12:00:00     67.8
2025-05-28 13:00:00     82.1

告警已创建
```

## 注意事项

1. **凭据安全**：不要在脚本中硬编码 AWS 访问密钥，使用 IAM 角色或 AWS 凭据配置文件
2. **区域设置**：AWS 命令默认使用 `Set-DefaultAWSRegion` 设置的区域，也可以通过 `-Region` 参数临时指定
3. **API 限流**：AWS API 有速率限制，大批量操作时应添加适当延迟或使用分页
4. **资源标签**：为所有资源添加标签（Name、Environment、CostCenter），便于管理和成本追踪
5. **最小权限原则**：为服务账户和 IAM 角色仅授予必要的权限，避免使用 AdministratorAccess
6. **成本监控**：使用 `Get-CECostAndUsage`（Cost Explorer）定期检查云资源开支
