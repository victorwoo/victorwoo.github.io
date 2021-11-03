---
layout: post
date: 2021-10-22 00:00:00
title: "PowerShell 技能连载 - Working with Get-WinEvent"
description: PowerTip of the Day - Working with Get-WinEvent
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您想从 Windows 事件日志中读取系统事件，`Get-Eventlog` 是个易于使用且简单的选择。这段代码能够获取最新的 10 个错误和警告事件：

```powershell
PS> Get-EventLog -LogName System -EntryType Error,Warning -Newest 10
```

不幸的是，`Get-Eventlog` 已被弃用，并且它不再可用于 PowerShell 7。弃用有很明显的原因：该 cmdlet 只能从“经典”日志文件中读取，它很缓慢并且具有其他限制。

这就是为什么 PowerShell 在3.0版中推出更好的替代命令：`Get-WinEvent`。PowerShell 7 也有此 cmdlet。

Unfortunately, Get-WinEvent is much harder to use because there are no intuitive parameters, and instead your filter criteria needs to be specified as a hash table.
不幸的是，`Get-Winevent` 更难使用，因为没有直观的参数，而是需要通过哈希表指定过滤条件。

但是，通过“代理函数”，您可以指导 `Get-WinEvent` 使用您所熟悉的旧式参数。以下是代码：

```powershell
<#Suggestion to improve Get-WinEvent in order to make it compatible to the commonly used Get-EventLog callsBelow is a prototype using a proxy function. Run it to enhance Get-WinEvent.To get rid of the enhancement, either restart PowerShell or run:Remove-Item -Path function:Get-WinEventNote that the prototype emits the composed hash table to the console (green)
\#>function Get-WinEvent
{    [CmdletBinding(DefaultParameterSetName='GetLogSet', HelpUri='https://go.microsoft.com/fwlink/?LinkID=138336')]
    param(

        [Parameter(ParameterSetName='ListLogSet', Mandatory=$true, Position=0)]
        [AllowEmptyCollection()]
        [string[]]
        ${ListLog},        [Parameter(ParameterSetName='LogNameGetEventlog', Mandatory=$true, Position=0)] <#NEW\#>
        [Parameter(ParameterSetName='GetLogSet', Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string[]]
        ${LogName},        [Parameter(ParameterSetName='ListProviderSet', Mandatory=$true, Position=0)]
        [AllowEmptyCollection()]
        [string[]]
        ${ListProvider},        <# Get-EventLog supports wildcards, Get-WinEvent does not. Needs to be corrected. #>        [Parameter(ParameterSetName='GetProviderSet', Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
        [string[]]
        ${ProviderName},        [Parameter(ParameterSetName='FileSet', Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
        [Alias('PSPath')]
        [string[]]
        ${Path},        [Parameter(ParameterSetName='FileSet')]
        [Parameter(ParameterSetName='GetProviderSet')]
        [Parameter(ParameterSetName='GetLogSet')]
        [Parameter(ParameterSetName='HashQuerySet')]
        [Parameter(ParameterSetName='XmlQuerySet')]
        [ValidateRange(1, 9223372036854775807)]
        [long]
        ${MaxEvents},
        <# NEW \#>        [Parameter(ParameterSetName='LogNameGetEventlog')]
        [ValidateRange(0, 2147483647)]
        [int]
        ${Newest},
        [Parameter(ParameterSetName='GetProviderSet')]
        [Parameter(ParameterSetName='ListProviderSet')]
        [Parameter(ParameterSetName='ListLogSet')]
        [Parameter(ParameterSetName='GetLogSet')]
        [Parameter(ParameterSetName='HashQuerySet')]
        [Parameter(ParameterSetName='XmlQuerySet')]
        [Parameter(ParameterSetName='LogNameGetEventlog')] <#NEW\#>
        [Alias('Cn')]
        [ValidateNotNullOrEmpty()] <#CORRECTED\#>        [string] <# used to be [String[]], Get-WinEvent accepts [string] only, should be changed to accept string arrays \#>        ${ComputerName},        [Parameter(ParameterSetName='GetProviderSet')]
        [Parameter(ParameterSetName='ListProviderSet')]
        [Parameter(ParameterSetName='ListLogSet')]
        [Parameter(ParameterSetName='GetLogSet')]
        [Parameter(ParameterSetName='HashQuerySet')]
        [Parameter(ParameterSetName='XmlQuerySet')]
        [Parameter(ParameterSetName='FileSet')]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},        [Parameter(ParameterSetName='FileSet')]
        [Parameter(ParameterSetName='GetProviderSet')]
        [Parameter(ParameterSetName='GetLogSet')]
        [ValidateNotNull()]
        [string]
        ${FilterXPath},        [Parameter(ParameterSetName='XmlQuerySet', Mandatory=$true, Position=0)]
        [xml]
        ${FilterXml},        [Parameter(ParameterSetName='HashQuerySet', Mandatory=$true, Position=0)]
        [hashtable[]]
        ${FilterHashtable},        [Parameter(ParameterSetName='GetProviderSet')]
        [Parameter(ParameterSetName='ListLogSet')]
        [Parameter(ParameterSetName='GetLogSet')]
        [Parameter(ParameterSetName='HashQuerySet')]
        [switch]
        ${Force},        [Parameter(ParameterSetName='GetLogSet')]
        [Parameter(ParameterSetName='GetProviderSet')]
        [Parameter(ParameterSetName='FileSet')]
        [Parameter(ParameterSetName='HashQuerySet')]
        [Parameter(ParameterSetName='XmlQuerySet')]
        [switch]
        ${Oldest},
        <# NEW \#>        [Parameter(ParameterSetName='LogNameGetEventlog')]
        [ValidateNotNullOrEmpty()]
        [datetime]
        ${After},        <# NEW \#>        [Parameter(ParameterSetName='LogNameGetEventlog')]
        [ValidateNotNullOrEmpty()]
        [datetime]
        ${Before},
        <# NEW \#>        [Parameter(ParameterSetName='LogNameGetEventlog')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${UserName},        <# NEW \#>        [Parameter(ParameterSetName='LogNameGetEventlog', Position=1)]
        [ValidateRange(0, 9223372036854775807)]
        [ValidateNotNullOrEmpty()]
        [long[]]
        ${InstanceId},        <# NEW \#>        [Parameter(ParameterSetName='LogNameGetEventlog')]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 2147483647)]
        [int[]]
        ${Index},        <# NEW \#>        [Parameter(ParameterSetName='LogNameGetEventlog')]
        [Alias('ET')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Error','Information','FailureAudit','SuccessAudit','Warning')]
        [string[]]
        ${EntryType},        <# NEW \#>        [Parameter(ParameterSetName='LogNameGetEventlog')]
        [Alias('ABO')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${Source},        <# NEW \#>        [Parameter(ParameterSetName='LogNameGetEventlog')]
        [Alias('MSG')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Message},        <# NEW \#>        [Parameter(ParameterSetName='LogNameGetEventlog')]
        [switch]
        ${AsBaseObject},
        [Parameter(ParameterSetName='ListGetEventlog')]
        [switch]
        ${List},        [Parameter(ParameterSetName='ListGetEventlog')]
        [switch]
        ${AsString}



    )

    begin    {
        try {
            $outBuffer = $null            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Diagnostics\Get-WinEvent', [System.Management.Automation.CommandTypes]::Cmdlet)

            \# if the user chose the Get-EventLog compatible parameters,            \# compose the appropriate filter hash table            $scriptCmd = if ($PSCmdlet.ParameterSetName -eq 'LogNameGetEventlog')
            {
                \# mandatory parameter                $filter = @{
                    LogName = $PSBoundParameters['Logname']
                }
                $null = $PSBoundParameters.Remove('LogName')

                if ($PSBoundParameters.ContainsKey('Before'))
                {
                    $filter['EndTime'] = $PSBoundParameters['Before']
                    $null = $PSBoundParameters.Remove('Before')
                }
                if ($PSBoundParameters.ContainsKey('After'))
                {
                    $filter['StartTime'] = $PSBoundParameters['After']
                    $null = $PSBoundParameters.Remove('After')
                }
                if ($PSBoundParameters.ContainsKey('EntryType'))
                {
                    \# severity is translated to an integer array
                    $levelFlags = [System.Collections.Generic.List[int]]@()

                    \# string input converted to integer array                    if ($PSBoundParameters['EntryType'] -contains 'Error')
                    {
                        $levelFlags.Add(1) \# critical                        $levelFlags.Add(2) \# error                    }
                    if ($PSBoundParameters['EntryType'] -contains 'Warning')
                    {
                        $levelFlags.Add(3) \# warning                    }
                    if ($PSBoundParameters['EntryType'] -contains 'Information')
                    {
                        $levelFlags.Add(4) \# informational                        $levelFlags.Add(5) \# verbose                    }


                    \# default to 0                    if ($levelFlags.Count -gt 0)
                    {
                        $filter['Level'] = [int[]]$levelFlags                    }

                    \# audit settings stored in Keywords key                    if ($PSBoundParameters['EntryType'] -contains 'FailureAudit')
                    {
                        $filter['Keywords'] += 0x10000000000000                    }
                    if ($PSBoundParameters['EntryType'] -contains 'SuccessAudit')
                    {
                        $filter['Keywords'] += 0x20000000000000                    }
                    $null = $PSBoundParameters.Remove('EntryType')
                }
                if ($PSBoundParameters.ContainsKey('InstanceId'))
                {
                    $filter['ID'] = $PSBoundParameters['InstanceId']
                    $null = $PSBoundParameters.Remove('InstanceId')
                }
                if ($PSBoundParameters.ContainsKey('Source'))
                {
                    $filter['ProviderName'] = $PSBoundParameters['Source']
                    $null = $PSBoundParameters.Remove('Source')
                }

                $PSBoundParameters['FilterHashtable'] = $filter                Write-Host ($filter | Out-String) -ForegroundColor Green
                if ($PSBoundParameters.ContainsKey('Newest'))
                {
                    $PSBoundParameters['MaxEvents'] = $PSBoundParameters['Newest']
                    $null = $PSBoundParameters.Remove('Newest')
                }
            }


            $scriptCmd =
            {
                & $wrappedCmd @PSBoundParameters            }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw        }
    }

    process    {
        try {
            $steppablePipeline.Process($_)
        } catch {
            throw        }
    }

    end    {
        try {
            $steppablePipeline.End()
        } catch {
            throw        }
    }
    <#

            .ForwardHelpTargetName Microsoft.PowerShell.Diagnostics\Get-WinEvent            .ForwardHelpCategory Cmdlet    \#>}
```

当您执行完这个函数，就可以通过您在 `Get-EventLog` 中熟悉的相同参数使用 `Get-WinEvent`：

```powershell
PS> Get-WinEvent -LogName System -EntryType Error,Warning -Newest 10

Name                           Value
----                           -----
LogName                        {System}
Level                          {1, 2, 3}
```

您还可以获得基于参数使用的哈希表过滤器的键和值。

<!--本文国际来源：[Working with Get-WinEvent](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/working-with-get-winevent)-->

