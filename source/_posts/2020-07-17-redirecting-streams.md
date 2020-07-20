---
layout: post
date: 2020-07-17 00:00:00
title: "PowerShell 技能连载 - 重定向流"
description: PowerTip of the Day - Redirecting Streams
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 将输出信息写入六个不同的流，并且仅将输出流分配给变量：

```powershell
function Invoke-Test
{
  "Regular Output"
  Write-Host "You always see me!"
  Write-Information "Info"
  Write-Warning "Warning"
  Write-Error "Error"
  Write-Debug "Debug"
  Write-Verbose "Verbose"
  Write-Output "Output"
}

$result = Invoke-Test
```

其余所有流要么显示在控制台中，要么隐藏在控制台中，具体取决于其适当的首选项变量的设置：

```powershell
PS> Get-Variable -Name *preference -Exclude *confirm*,*whatif*,*progress*

Name                           Value
----                           -----
DebugPreference                SilentlyContinue
ErrorActionPreference          Continue
InformationPreference          SilentlyContinue
VerbosePreference              SilentlyContinue
WarningPreference              Continue
```

有时，可能还需要捕获其他流的输出并对其进行处理，而不是将其输出到控制台。为此，您可以将所有流重定向到输出流，并将总结果捕获到变量中：

```powershell
function Invoke-Test
{
  "Regular Output"
  Write-Host "You always see me!"
  Write-Information "Info"
  Write-Warning "Warning"
  Write-Error "Error"
  Write-Debug "Debug"
  Write-Verbose "Verbose"
  Write-Output "Output"
}


$all = Invoke-Test *>&1
```

现在，此变量包含所有流的组合输出。为了单独处理流，您可能需要按类型对内容进行分组：

```powershell
PS> $groups = $all | Group-Object -Property { $_.GetType().Name } -AsHashTable -AsString

PS> $groups

Name                           Value
----                           -----
WarningRecord                  {Warning}
InformationRecord              {You always see me!, Info}
ErrorRecord                    {Error}
String                         {Regular Output, Output}


PS> $groups.WarningRecord
WARNING: Warning

PS> $groups.InformationRecord
You always see me!
Info
```

<!--本文国际来源：[Redirecting Streams](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/redirecting-streams)-->
