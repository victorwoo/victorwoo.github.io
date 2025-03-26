---
layout: post
date: 2023-07-21 08:00:16
title: "PowerShell 技能连载 - 轻松过渡至 Get-WinEvent"
description: PowerTip of the Day - Easily Transition to Get-WinEvent
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
出于多种原因，你不应继续使用 `Get-EventLog`，我们之前已经解释了一些原因。在 PowerShell 7 中，`Get-EventLog`` 已经被弃用。相反，应该使用 `Get-WinEvent`。它可以做到 `Get-EventLog`` 能做的所有事情，而且更多。

不过，`Get-WinEvent` 使用起来可能有些麻烦，因为它需要使用类似哈希表或 XML 的结构来定义你所需的事件。因此，在下面，我们为你提供了一个相当冗长的代理函数，用于为  `Get-WinEvent` 添加向后兼容性。运行下面的代理函数后，你可以使用 `Get-WinEvent` 并传入与之前使用 `Get-EventLog` 时相同的参数。而且，你还会获得全新的 IntelliSense 功能，提示所有包含可能有趣信息的日志名称。

```powershell
function Get-WinEvent
{
    [CmdletBinding(DefaultParameterSetName='GetLogSet', HelpUri='https://go.microsoft.com/fwlink/?LinkID=138336')]
    param(

        [Parameter(ParameterSetName='ListLogSet', Mandatory, Position=0)]
        [AllowEmptyCollection()]
        [string[]]
        ${ListLog},

        [Parameter(ParameterSetName='LogNameGetEventlog', Mandatory, Position=0)] <#NEW#>
        [Parameter(ParameterSetName='GetLogSet', Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        [ArgumentCompleter({
          # receive information about current state:
          param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

          # list all log files in the path
          Get-WinEvent -ListLog * -ErrorAction Ignore |
          Where-Object RecordCount -gt 0 |
          Sort-Object -Property LogName |
          # filter results by word to complete
          Where-Object { $_.LogName -like "$wordToComplete*" } |
          Foreach-Object {
            # create completionresult items:
            $completion = $_.LogName
            if ($completion -like '* *')
            {
                $completion = "'$completion'"
            }
            $displayname = $_.LogName
            $tooltip = '{0:n0} Records, {1:n0} MB' -f $_.RecordCount, ($_.MaximumSizeInBytes/1MB)
            [System.Management.Automation.CompletionResult]::new($completion, $displayname, "ParameterValue", $tooltip)
          }
            })]
        ${LogName},

        [Parameter(ParameterSetName='ListProviderSet', Mandatory, Position=0)]
        [AllowEmptyCollection()]
        [string[]]
        ${ListProvider},

        <# Get-EventLog supports wildcards, Get-WinEvent does not. Needs to be corrected. #>
        [Parameter(ParameterSetName='GetProviderSet', Mandatory, Position=0, ValueFromPipelineByPropertyName)]
        [string[]]
        ${ProviderName},

        [Parameter(ParameterSetName='FileSet', Mandatory, Position=0, ValueFromPipelineByPropertyName)]
        [Alias('PSPath')]
        [string[]]
        ${Path},

        [Parameter(ParameterSetName='FileSet')]
        [Parameter(ParameterSetName='GetProviderSet')]
        [Parameter(ParameterSetName='GetLogSet')]
        [Parameter(ParameterSetName='HashQuerySet')]
        [Parameter(ParameterSetName='XmlQuerySet')]
        [ValidateRange(1, 9223372036854775807)]
        [long]
        ${MaxEvents},

        <# NEW #>
        [Parameter(ParameterSetName='LogNameGetEventlog')]
        [ValidateRange(0, 2147483647)]
        [int]
        ${Newest},

        [Parameter(ParameterSetName='GetProviderSet')]
        [Parameter(ParameterSetName='ListProviderSet')]
        [Parameter(ParameterSetName='ListLogSet')]
        [Parameter(ParameterSetName='GetLogSet')]
        [Parameter(ParameterSetName='HashQuerySet')]
        [Parameter(ParameterSetName='XmlQuerySet')]
        [Parameter(ParameterSetName='LogNameGetEventlog')] <#NEW#>
        [Alias('Cn')]
        [ValidateNotNullOrEmpty()] <#CORRECTED#>
        [string] <# used to be [String[]], Get-WinEvent accepts [string] only, should be changed to accept string arrays #>
        ${ComputerName},

        [Parameter(ParameterSetName='GetProviderSet')]
        [Parameter(ParameterSetName='ListProviderSet')]
        [Parameter(ParameterSetName='ListLogSet')]
        [Parameter(ParameterSetName='GetLogSet')]
        [Parameter(ParameterSetName='HashQuerySet')]
        [Parameter(ParameterSetName='XmlQuerySet')]
        [Parameter(ParameterSetName='FileSet')]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName='FileSet')]
        [Parameter(ParameterSetName='GetProviderSet')]
        [Parameter(ParameterSetName='GetLogSet')]
        [ValidateNotNull()]
        [string]
        ${FilterXPath},

        [Parameter(ParameterSetName='XmlQuerySet', Mandatory, Position=0)]
        [xml]
        ${FilterXml},

        [Parameter(ParameterSetName='HashQuerySet', Mandatory, Position=0)]
        [hashtable[]]
        ${FilterHashtable},

        [Parameter(ParameterSetName='GetProviderSet')]
        [Parameter(ParameterSetName='ListLogSet')]
        [Parameter(ParameterSetName='GetLogSet')]
        [Parameter(ParameterSetName='HashQuerySet')]
        [switch]
        ${Force},

        [Parameter(ParameterSetName='GetLogSet')]
        [Parameter(ParameterSetName='GetProviderSet')]
        [Parameter(ParameterSetName='FileSet')]
        [Parameter(ParameterSetName='HashQuerySet')]
        [Parameter(ParameterSetName='XmlQuerySet')]
        [switch]
        ${Oldest},

        <# NEW #>
        [Parameter(ParameterSetName='LogNameGetEventlog')]
        [ValidateNotNullOrEmpty()]
        [datetime]
        ${After},

        <# NEW #>
        [Parameter(ParameterSetName='LogNameGetEventlog')]
        [ValidateNotNullOrEmpty()]
        [datetime]
        ${Before},

        <# NEW #>
        [Parameter(ParameterSetName='LogNameGetEventlog')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${UserName},

        <# NEW #>
        [Parameter(ParameterSetName='LogNameGetEventlog', Position=1)]
        [ValidateRange(0, 9223372036854775807)]
        [ValidateNotNullOrEmpty()]
        [long[]]
        ${InstanceId},

        <# NEW #>
        [Parameter(ParameterSetName='LogNameGetEventlog')]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 2147483647)]
        [int[]]
        ${Index},

        <# NEW #>
        [Parameter(ParameterSetName='LogNameGetEventlog')]
        [Alias('ET','LevelDisplayName')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Error','Information','FailureAudit','SuccessAudit','Warning')]
        [string[]]
        ${EntryType},

        <# NEW #>
        [Parameter(ParameterSetName='LogNameGetEventlog')]
        [Alias('ABO')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        [ArgumentCompleter({
          # receive information about current state:
          param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

          if ($fakeBoundParameters.ContainsKey('LogName'))
          {
            $nofilter = $false
            $chosenLog = $fakeBoundParameters['LogName']
          }
          else
          {
            $nofilter = $true
            $chosenLog = ''
          }
          # list all log files in the path
          Get-WinEvent -ListProvider * -ErrorAction Ignore |
          Where-Object { $nofilter -or ($_.LogLinks.LogName -contains $chosenLog) } |
          Select-Object -ExpandProperty Name |
          Sort-Object |
          # filter results by word to complete
          Where-Object { $_ -like "$wordToComplete*" } |
          Foreach-Object {
            # create completionresult items:
            $completion = $_
            if ($completion -like '* *')
            {
                $completion = "'$completion'"
            }
            $displayname = $_
            $tooltip = $_
            [System.Management.Automation.CompletionResult]::new($completion, $displayname, "ParameterValue", $tooltip)
          }
            })]
        ${Source},

        <# NEW #>
        [Parameter(ParameterSetName='LogNameGetEventlog')]
        [Alias('MSG')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Message},

        <# NEW #>
        [Parameter(ParameterSetName='LogNameGetEventlog')]
        [switch]
        ${AsBaseObject},

        [Parameter(ParameterSetName='ListGetEventlog')]
        [switch]
        ${List},

        [Parameter(ParameterSetName='ListGetEventlog')]
        [switch]
        ${AsString}


    )

    begin
    {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Diagnostics\Get-WinEvent', [System.Management.Automation.CommandTypes]::Cmdlet)

            # if the user chose the Get-EventLog compatible parameters,
            # compose the appropriate filterhashtable:
            $scriptCmd = if ($PSCmdlet.ParameterSetName -eq 'LogNameGetEventlog')
            {
                # mandatory parameter:
                $filter = @{
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
                    # severity is translated to an integer array:

                    $levelFlags = [System.Collections.Generic.List[int]]@()

                    # string input converted to integer array:
                    if ($PSBoundParameters['EntryType'] -contains 'Error')
                    {
                        $levelFlags.Add(1) # critical
                        $levelFlags.Add(2) # error
                    }
                    if ($PSBoundParameters['EntryType'] -contains 'Warning')
                    {
                        $levelFlags.Add(3) # warning
                    }
                    if ($PSBoundParameters['EntryType'] -contains 'Information')
                    {
                        $levelFlags.Add(4) # informational
                        $levelFlags.Add(5) # verbose
                    }


                    # default to 0:
                    if ($levelFlags.Count -gt 0)
                    {
                        $filter['Level'] = [int[]]$levelFlags
                    }

                    # audit settings stored in Keywords key:
                    if ($PSBoundParameters['EntryType'] -contains 'FailureAudit')
                    {
                        $filter['Keywords'] += 0x10000000000000
                    }
                    if ($PSBoundParameters['EntryType'] -contains 'SuccessAudit')
                    {
                        $filter['Keywords'] += 0x20000000000000
                    }
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

                $PSBoundParameters['FilterHashtable'] = $filter
                Write-Verbose ("FilterHashtable: " + ($filter | Out-String))

                if ($PSBoundParameters.ContainsKey('Newest'))
                {
                    $PSBoundParameters['MaxEvents'] = $PSBoundParameters['Newest']
                    $null = $PSBoundParameters.Remove('Newest')
                }
            }
            $scriptCmd = if ($PSBoundParameters.ContainsKey('Message'))
                {
                    $null = $PSBoundParameters.Remove('Message')
                    { & $wrappedCmd @PSBoundParameters | Where-Object Message -like $Message }
                }
                else
                {
                    { & $wrappedCmd @PSBoundParameters }
                }



            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }

    process
    {
        try {
            $steppablePipeline.Process($_)
        } catch {
            throw
        }
    }

    end
    {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }
    }
    <#

            .ForwardHelpTargetName Microsoft.PowerShell.Diagnostics\Get-WinEvent
            .ForwardHelpCategory Cmdlet

    #>

}
```

我们来做一个测试并尝试从系统日志文件中获取最新的 20 个错误。正如你很快看到的，`Get-WinEvent` 现在接受与 `Get-EventLog` 相同的参数。在查看结果时，你会迅速发现 `Get-EventLog` 没有正确返回事件日志消息，而 `Get-WinEvent` 则做到了。

```powershell
PS> Get-EventLog -LogName System -EntryType Error -Newest 3

   Index Time          EntryType   Source                 InstanceID Message
   ----- ----          ---------   ------                 ---------- -------
  551873 Jun 02 06:40  Error       DCOM                        10010 The description for Event ID '10010' ...
  551872 Jun 02 06:38  Error       DCOM                        10010 The description for Event ID '10010' ...
  551848 Jun 02 03:35  Error       DCOM                        10010 The description for Event ID '10010' ...

PS> Get-WinEvent -LogName System -EntryType Error -Newest 3

   ProviderName: Microsoft-Windows-DistributedCOM

TimeCreated                      Id LevelDisplayName Message
-----------                      -- ---------------- -------

02.06.2023 06:40:14           10010 Error            The server {A463FCB9-6B1C-4E0D-A80B-A2CA7999E25D} did...
02.06.2023 06:38:14           10010 Error            The server {A463FCB9-6B1C-4E0D-A80B-A2CA7999E25D} did...
02.06.2023 03:35:23           10010 Error            The server {776DBC8D-7347-478C-8D71-791E12EF49D8} did...
```

请在参数中添加 `-Verbose` 选项，以获取关于过滤哈希表值或XML查询的详细信息：

```powershell
PS> Get-WinEvent -LogName System -EntryType Error -Newest 3 -Verbose
VERBOSE: FilterHashtable:
Name                           Value
----                           -----
LogName                        {System}
Level                          {1, 2}

VERBOSE: Constructed structured query:
<QueryList><Query Id="0" Path="system"><Select Path="system">*[((System/Level=1) or
(System/Level=2))]</Select></Query></QueryList>.

   ProviderName: Microsoft-Windows-DistributedCOM
TimeCreated                      Id LevelDisplayName Message
-----------                      -- ---------------- -------
02.06.2023 06:40:14           10010 Error            The server {A463FCB9-6B1C-4E0D-A80B-A2CA7999E25D} did not register with
DCOM ...
02.06.2023 06:38:14           10010 Error            The server {A463FCB9-6B1C-4E0D-A80B-A2CA7999E25D} did not register with
DCOM ...
02.06.2023 03:35:23           10010 Error            The server {776DBC8D-7347-478C-8D71-791E12EF49D8} did not register with
DCOM ...
```
<!--本文国际来源：[Easily Transition to Get-WinEvent](https://blog.idera.com/database-tools/powershell/powertips/easily-transition-to-get-winevent/)-->

