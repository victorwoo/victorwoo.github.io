---
layout: post
date: 2025-10-16 08:00:00
updated: 2025-10-16 08:00:00
title: "PowerShell 技能连载 - Ansible 集成"
description: PowerTip of the Day - Ansible Integration with PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- ansible
- automation
- configuration-management
- devops
---
_适用于 PowerShell 5.1 及以上版本（Windows）_

在现代混合 IT 环境中，Windows 和 Linux 服务器往往共存于同一基础设施。Ansible 作为无代理（agentless）的配置管理工具，原生支持通过 WinRM 协议管理 Windows 主机，而 PowerShell 正是 Ansible 在 Windows 端执行任务的核心引擎——每个 Ansible 模块在 Windows 上最终都会转化为 PowerShell 脚本执行。

理解 PowerShell 与 Ansible 的集成方式，不仅可以帮助运维团队构建跨平台的自动化流水线，还能在现有 PowerShell 脚本资产的基础上无缝接入 Ansible 生态。本文将从连接配置、自定义模块编写和脚本集成三个层面，展示如何在 PowerShell 环境中高效使用 Ansible。

## 配置 WinRM 连接

Ansible 通过 WinRM 与 Windows 通信。在开始之前，需要确保目标 Windows 主机的 WinRM 服务已正确配置。微软提供了专门的配置脚本，但生产环境中往往需要更精细的控制。

以下 PowerShell 函数用于配置 WinRM，支持 HTTP 和 HTTPS 两种传输方式，并输出 Ansible inventory 所需的连接参数：

```powershell
function Set-AnsibleWinRM {
    <#
    .SYNOPSIS
    配置 Windows 主机以支持 Ansible 远程管理
    .PARAMETER UseHTTPS
    是否启用 HTTPS 传输（推荐生产环境使用）
    .PARAMETER CertificateThumbprint
    指定 HTTPS 证书的指纹，不指定则生成自签名证书
    #>
    [CmdletBinding()]
    param(
        [bool]$UseHTTPS = $true,
        [string]$CertificateThumbprint
    )

    # 确保 WinRM 服务运行
    $service = Get-Service -Name WinRM -ErrorAction SilentlyContinue
    if ($service.Status -ne 'Running') {
        Start-Service -Name WinRM
        Write-Host "WinRM 服务已启动"
    }

    # 启用基本认证和 CredSSP（Ansible 常用认证方式）
    $winrmPath = 'WSMan:\localhost\Service\Auth'
    Set-Item -Path "$winrmPath\Basic" -Value $true -Force
    Set-Item -Path "$winrmPath\CredSSP" -Value $true -Force
    Write-Host "基本认证和 CredSSP 已启用"

    if ($UseHTTPS) {
        if (-not $CertificateThumbprint) {
            # 创建自签名证书（仅用于测试环境）
            $cert = New-SelfSignedCertificate `
                -DnsName $env:COMPUTERNAME `
                -CertStoreLocation 'Cert:\LocalMachine\My' `
                -FriendlyName 'Ansible WinRM HTTPS'
            $CertificateThumbprint = $cert.Thumbprint
            Write-Host "自签名证书已创建，指纹: $CertificateThumbprint"
        }

        # 创建 HTTPS 监听器
        $existingListener = Get-ChildItem -Path 'WSMan:\localhost\Listener' |
            Where-Object { $_.Keys -match 'Transport=HTTPS' }

        if ($existingListener) {
            Remove-Item -Path "WSMan:\localhost\Listener\$($existingListener.Name)" -Recurse -Force
        }

        New-Item -Path 'WSMan:\localhost\Listener' -Transport HTTPS -Address * `
            -CertificateThumbprint $CertificateThumbprint -Force | Out-Null
        Write-Host "HTTPS 监听器已创建"
    }

    # 配置防火墙规则
    $ports = @{ HTTP = 5985; HTTPS = 5986 }
    foreach ($proto in @('HTTP', 'HTTPS')) {
        $port = $ports[$proto]
        $ruleName = "Ansible WinRM $proto"
        $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
        if (-not $existingRule) {
            New-NetFirewallRule -DisplayName $ruleName `
                -Direction Inbound `
                -Action Allow `
                -Protocol TCP `
                -LocalPort $port | Out-Null
            Write-Host "防火墙规则已添加: $ruleName (端口 $port)"
        }
    }

    # 输出 Ansible inventory 配置参考
    $ansibleUser = "$env:COMPUTERNAME\Administrator"
    $ansiblePort = if ($UseHTTPS) { 5986 } else { 5985 }
    $ansibleScheme = if ($UseHTTPS) { 'https' } else { 'http' }

    Write-Host "`n--- Ansible Inventory 配置参考 ---"
    Write-Host "[windows]"
    Write-Host "$($env:COMPUTERNAME.ToLower()) ansible_host=<目标IP>"
    Write-Host "[windows:vars]"
    Write-Host "ansible_user=$ansibleUser"
    Write-Host "ansible_password=<密码>"
    Write-Host "ansible_connection=winrm"
    Write-Host "ansible_winrm_transport=basic"
    Write-Host "ansible_winrm_server_cert_validation=ignore"
    Write-Host "ansible_port=$ansiblePort"
}
```

执行结果示例：

```
WinRM 服务已启动
基本认证和 CredSSP 已启用
自签名证书已创建，指纹: A1B2C3D4E5F6789012345678901234567890ABCD
HTTPS 监听器已创建
防火墙规则已添加: Ansible WinRM HTTP (端口 5985)
防火墙规则已添加: Ansible WinRM HTTPS (端口 5986)

--- Ansible Inventory 配置参考 ---
[windows]
winserver01 ansible_host=<目标IP>
[windows:vars]
ansible_user=WINSERVER01\Administrator
ansible_password=<密码>
ansible_connection=winrm
ansible_winrm_transport=basic
ansible_winrm_server_cert_validation=ignore
ansible_port=5986
```

## 编写 Ansible 自定义模块

Ansible 的 Windows 模块本质上就是遵循特定输入输出约定的 PowerShell 脚本。当内置模块无法满足需求时，可以编写自定义模块，直接复用已有的 PowerShell 函数和模块。

自定义模块需要遵循 Ansible 的 JSON 通信协议：从标准输入读取 JSON 参数，通过 `Exit-Json` 返回成功结果，或通过 `Fail-Json` 返回失败信息。以下示例实现了一个检查 Windows 服务状态的自定义模块：

```powershell
#!powershell
# Ansible Windows 自定义模块: win_service_health
# 文件位置: library/win_service_health.ps1

# ANSIBLE_METADATA 块（Ansible 2.10+ 使用 DOCUMENTATION 替代）
$ErrorActionPreference = 'Stop'

# 加载 Ansible 模块工具函数
# 在实际部署中这些函数由 Ansible 自动注入
function Exit-Json {
    param([hashtable]$Result)
    $Result.ansible_facts = $Result.ansible_facts
    $jsonOutput = $Result | ConvertTo-Json -Depth 10 -Compress
    Write-Output $jsonOutput
    exit 0
}

function Fail-Json {
    param([hashtable]$Result, [string]$Message)
    $Result.failed = $true
    $Result.msg = $Message
    $jsonOutput = $Result | ConvertTo-Json -Depth 10 -Compress
    Write-Output $jsonOutput
    exit 1
}

# 解析模块参数（生产环境使用 Ansible.ModuleUtils）
$params = @{
    name        = ''
    state       = 'started'
    start_mode  = 'auto'
    check_only  = $false
}

$result = @{
    changed = $false
    services = @()
}

# 获取目标服务列表
$serviceNames = $params.name -split ',' | ForEach-Object { $_.Trim() }
$allServices = @()

foreach ($svcName in $serviceNames) {
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if (-not $svc) {
        Fail-Json -Result $result -Message "服务 '$svcName' 不存在"
    }

    $wmiSvc = Get-CimInstance -ClassName Win32_Service -Filter "Name='$svcName'"
    $serviceInfo = @{
        name        = $svcName
        displayname = $svc.DisplayName
        status      = $svc.Status.ToString()
        starttype   = $wmiSvc.StartMode
    }

    if (-not $params.check_only) {
        # 检查启动类型是否符合预期
        if ($wmiSvc.StartMode -ne $params.start_mode) {
            Set-Service -Name $svcName -StartupType $params.start_mode
            $serviceInfo.starttype = $params.start_mode
            $result.changed = $true
        }

        # 检查运行状态是否符合预期
        $desiredState = $params.state
        if ($desiredState -eq 'started' -and $svc.Status -ne 'Running') {
            Start-Service -Name $svcName
            $serviceInfo.status = 'Running'
            $result.changed = $true
        }
        elseif ($desiredState -eq 'stopped' -and $svc.Status -ne 'Stopped') {
            Stop-Service -Name $svcName -Force
            $serviceInfo.status = 'Stopped'
            $result.changed = $true
        }
    }

    $allServices += $serviceInfo
}

$result.services = $allServices
$result.msg = "已检查 $($allServices.Count) 个服务"
Exit-Json -Result $result
```

执行结果示例（Ansible playbook 调用后的 JSON 输出）：

```
TASK [检查并修复服务状态] ********************************************************
ok: [winserver01] => {
    "changed": true,
    "services": [
        {
            "name": "wuauserv",
            "displayname": "Windows Update",
            "status": "Running",
            "starttype": "auto"
        },
        {
            "name": "WinRM",
            "displayname": "Windows Remote Management (WS-Management)",
            "status": "Running",
            "starttype": "auto"
        }
    ],
    "msg": "已检查 2 个服务"
}
```

## 将现有 PowerShell 脚本封装为 Ansible Playbook

许多团队已经积累了大量的 PowerShell 运维脚本。通过 Ansible 的 `script` 模块或 `win_shell` 模块，可以直接在 playbook 中调用这些脚本，但更推荐的做法是使用 `win_task` 或结构化的方式封装，以便获得更好的幂等性和错误处理。

以下函数演示如何从一个目录中的 PowerShell 脚本自动生成 Ansible playbook：

```powershell
function New-AnsiblePlaybookFromScripts {
    <#
    .SYNOPSIS
    从 PowerShell 脚本目录生成 Ansible playbook
    .PARAMETER ScriptPath
        PowerShell 脚本所在目录
    .PARAMETER OutputFile
        生成的 playbook 输出路径
    .PARAMETER TargetHosts
        playbook 的目标主机组名称
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath,

        [Parameter(Mandatory)]
        [string]$OutputFile,

        [string]$TargetHosts = 'windows'
    )

    $scripts = Get-ChildItem -Path $ScriptPath -Filter '*.ps1' |
        Sort-Object -Property Name

    if ($scripts.Count -eq 0) {
        Write-Warning "目录 $ScriptPath 中没有找到 PowerShell 脚本"
        return
    }

    # 构建 playbook 任务列表
    $tasks = @()
    foreach ($script in $scripts) {
        $scriptName = $script.BaseName
        # 从脚本文件头部提取注释作为任务描述
        $description = $scriptName
        $firstLine = Get-Content -Path $script.FullName -TotalCount 1
        if ($firstLine -match '^\s*#\s*(.+)') {
            $description = $Matches[1]
        }

        $task = @{
            name   = $description
            script = $script.FullName
            register = "result_$($scriptName -replace '[^a-zA-Z0-9]', '_')"
        }
        $tasks += $task
        Write-Host "  已添加任务: $description ($($script.Name))"
    }

    # 构建完整的 playbook 结构
    $playbook = @(
        @{
            name       = "执行 PowerShell 运维脚本"
            hosts      = $TargetHosts
            gather_facts = $false
            tasks      = $tasks
        }
    )

    # 生成 YAML 文件（手动构建以控制格式）
    $yamlLines = @(
        '---'
        ''
        "- name: 执行 PowerShell 运维脚本"
        "  hosts: $TargetHosts"
        '  gather_facts: false'
        '  tasks:'
    )

    foreach ($script in $scripts) {
        $scriptName = $script.BaseName
        $firstLine = Get-Content -Path $script.FullName -TotalCount 1
        $description = $scriptName
        if ($firstLine -match '^\s*#\s*(.+)') {
            $description = $Matches[1]
        }

        $regName = "result_$($scriptName -replace '[^a-zA-Z0-9]', '_')"
        $yamlLines += @(
            "    - name: $description"
            "      script: scripts/$($script.Name)"
            "      register: $regName"
            ''
        )
    }

    Set-Content -Path $OutputFile -Value $yamlLines -Encoding UTF8
    Write-Host "`nPlaybook 已生成: $OutputFile"
    Write-Host "共包含 $($scripts.Count) 个任务"
}

# 使用示例：从 D:\ops-scripts 目录生成 playbook
# New-AnsiblePlaybookFromScripts `
#     -ScriptPath 'D:\ops-scripts' `
#     -OutputFile 'site.yml' `
#     -TargetHosts 'production_windows'
```

执行结果示例：

```
  已添加任务: 清理临时文件 (01-CleanTempFiles.ps1)
  已添加任务: 检查磁盘空间 (02-CheckDiskSpace.ps1)
  已添加任务: 更新 Windows (03-InstallUpdates.ps1)
  已添加任务: 重启挂起检测 (04-CheckRebootPending.ps1)
  已添加任务: 导出系统信息 (05-ExportSystemInfo.ps1)

Playbook 已生成: site.yml
共包含 5 个任务
```

## 在 PowerShell 中调用 Ansible Playbook

除了从 Ansible 端管理 Windows，有时也需要从 Windows 主机本身触发 Ansible 操作。例如在 CI/CD 流水线中，由 PowerShell 编排整个部署流程。以下函数封装了通过 WSL 或远程 Linux 跳板机执行 Ansible playbook 的逻辑：

```powershell
function Invoke-AnsiblePlaybook {
    <#
    .SYNOPSIS
    从 Windows 端触发 Ansible playbook 执行
    .PARAMETER PlaybookPath
        playbook 文件的相对路径或绝对路径
    .PARAMETER Inventory
        inventory 文件路径
    .PARAMETER ExtraVars
        额外的变量，以键值对形式传入
    .PARAMETER UseWSL
        是否通过 WSL 调用 Ansible（默认通过 SSH 到跳板机）
    .PARAMETER RemoteHost
        Ansible 控制节点的 SSH 地址（不使用 WSL 时必填）
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PlaybookPath,

        [string]$Inventory = 'inventory/hosts',

        [hashtable]$ExtraVars,

        [bool]$UseWSL = $true,

        [string]$RemoteHost
    )

    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $logFile = "ansible_run_${timestamp}.log"

    # 构建额外变量参数
    $extraVarsStr = ''
    if ($ExtraVars) {
        $varParts = @()
        foreach ($key in $ExtraVars.Keys) {
            $varParts += "$key=$($ExtraVars[$key])"
        }
        $extraVarsStr = " --extra-vars `"$($varParts -join ' ')`""
    }

    $ansibleCmd = "ansible-playbook -i $Inventory$extraVarsStr $PlaybookPath"

    if ($UseWSL) {
        # 通过 WSL 执行 Ansible
        Write-Host "通过 WSL 执行: $ansibleCmd"
        $result = wsl bash -c "$ansibleCmd 2>&1 | tee $logFile"
    }
    else {
        if (-not $RemoteHost) {
            throw "不使用 WSL 时必须指定 RemoteHost 参数"
        }
        # 通过 SSH 在远程 Ansible 控制节点执行
        Write-Host "通过 SSH 在 $RemoteHost 执行: $ansibleCmd"
        $result = ssh $RemoteHost "$ansibleCmd 2>&1 | tee $logFile"
    }

    # 解析执行结果
    $successPattern = 'ok=.*changed=.*unreachable=0.*failed=0'
    $lastLine = ($result | Where-Object { $_ -match 'PLAY RECAP' -or $_ -match 'ok=' }) |
        Select-Object -Last 1

    if ($lastLine -match 'failed=0' -and $lastLine -match 'unreachable=0') {
        Write-Host "`nPlaybook 执行成功" -ForegroundColor Green
    }
    else {
        Write-Host "`nPlaybook 执行存在问题，请检查日志: $logFile" -ForegroundColor Red
    }

    return $result
}

# 使用示例
# Invoke-AnsiblePlaybook `
#     -PlaybookPath 'site.yml' `
#     -Inventory 'inventory/production' `
#     -ExtraVars @{ target = 'web_servers'; action = 'deploy' } `
#     -UseWSL $true
```

执行结果示例：

```
通过 WSL 执行: ansible-playbook -i inventory/production --extra-vars "target=web_servers action=deploy" site.yml

PLAY [部署 Web 应用] ***********************************************************

TASK [Gathering Facts] *********************************************************
ok: [web01.vichamp.com]
ok: [web02.vichamp.com]

TASK [拉取最新代码] *************************************************************
changed: [web01.vichamp.com]
changed: [web02.vichamp.com]

TASK [重启应用服务] *************************************************************
changed: [web01.vichamp.com]
changed: [web02.vichamp.com]

PLAY RECAP *********************************************************************
web01.vichamp.com : ok=3    changed=2    unreachable=0    failed=0
web02.vichamp.com : ok=3    changed=2    unreachable=0    failed=0

Playbook 执行成功
```

## 注意事项

1. **WinRM 认证安全**：生产环境务必使用 HTTPS 传输，并配合域账户或证书认证。基本认证（Basic Auth）以明文传输密码，仅适合测试环境。如果使用域环境，推荐配置 Kerberos 认证，安全性更高且支持委派。

2. **执行策略与脚本签名**：Ansible 在 Windows 端执行脚本时，WinRM 会话的执行策略可能与交互式会话不同。确保 Ansible 连接用户的执行策略允许脚本运行（`RemoteSigned` 或 `Unrestricted`），同时注意自定义模块中的 `Set-ExecutionPolicy` 不会影响系统全局策略。

3. **双跃点（Double Hop）问题**：当 Ansible 通过 WinRM 连接到 Windows 主机后，该主机再尝试访问网络资源（如文件共享、远程数据库）时，会遇到凭据委派失败的问题。解决方案包括启用 CredSSP、使用 Kerberos 约束委派，或在目标主机上使用 `Invoke-Command` 配合 `-Authentication CredSSP` 参数。

4. **模块幂等性**：编写自定义 Ansible 模块时，务必保证幂等性——同一模块多次执行应产生相同结果。在修改任何状态之前先检查当前状态，仅在确实需要变更时才标记 `changed = true`。这样可以让 playbook 安全地重复执行。

5. **输出编码问题**：PowerShell 的输出编码默认可能不是 UTF-8，导致中文路径或错误信息在 Ansible 日志中显示为乱码。建议在模块开头设置 `$OutputEncoding = [System.Text.Encoding]::UTF8`，并在 playbook 中配置 `ansible_winrm_codepage = 65001`。

6. **WSL 与 Ansible 控制节点**：在 Windows 上通过 WSL 运行 Ansible 是开发环境的常见方案，但需注意 WSL 的文件系统性能问题。Playbook 和 inventory 文件建议放在 Linux 文件系统（如 `~/ansible/`）下而非挂载的 Windows 盘（`/mnt/c/`）上，可以显著提升执行速度。
