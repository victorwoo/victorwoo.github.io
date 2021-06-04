---
layout: post
date: 2021-05-13 00:00:00
title: "PowerShell 技能连载 - 更好的 PowerShell 帮助（第 2 部分）"
description: PowerTip of the Day - Better PowerShell Help (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们更改了 `Get-Help` 的默认参数值，以在您使用 `Get-Help` 或通用参数 `-?` 时自动显示丰富的联机帮助。但是，当 cmdlet 没有联机帮助时，此方法会产生错误。

更好的方法是首先检查给定命令是否存在联机帮助，然后才打开联机帮助。如果没有在线帮助，则应显示默认的本地帮助。

此方法无法通过默认参数实现。相反，`Get-Help` cmdlet 本身需要进行调整。要将逻辑添加到 `Get-Help`，可以使用以下代理函数：

```powershell
function Get-Help{
  \# clone the original param block taken from Get-Help  [CmdletBinding(DefaultParameterSetName='AllUsersView', HelpUri='https://go.microsoft.com/fwlink/?LinkID=113316')]
  param(
    [Parameter(Position=0, ValueFromPipelineByPropertyName)]
    [string]
    $Name,    [Parameter(ParameterSetName='Online', Mandatory)]
    [switch]
    $Online,    [ValidateSet('Alias','Cmdlet','Provider','General','FAQ','Glossary','HelpFile','ScriptCommand','Function','Filter','ExternalScript','All','DefaultHelp','Workflow','DscResource','Class','Configuration')]
    [string[]]
    $Category,    [string]
    $Path,    [string[]]
    $Component,    [string[]]
    $Functionality,    [string[]]
    $Role,    [Parameter(ParameterSetName='DetailedView', Mandatory)]
    [switch]
    $Detailed,    [Parameter(ParameterSetName='AllUsersView')]
    [switch]
    $Full,    [Parameter(ParameterSetName='Examples', Mandatory)]
    [switch]
    $Examples,    [Parameter(ParameterSetName='Parameters', Mandatory)]
    [string]
    $Parameter,    [Parameter(ParameterSetName='ShowWindow', Mandatory)]
    [switch]
    $ShowWindow  )

  begin  {
    \# determine whether -Online should be made a default    if (
      \# user submitted -Name only      (   $PSBoundParameters.Count -eq 1 -and
        $PSBoundParameters.ContainsKey('Name')
      ) -or      \# system submitted -Name and -Category (when using -?)      (
        $PSBoundParameters.Count -eq 2 -and
        $PSBoundParameters.ContainsKey('Name') -and
        $PSBoundParameters.ContainsKey('Category')
      )
    )
    {
      \# prerequisites are OK, now check whether there IS online help      \# available at all
      \# retrieve the help URI      $help = Microsoft.PowerShell.Core\Get-Command -Name $Name
      \# set the -Online parameter only if there is a help URI      $PSBoundParameters['Online']=      [string]::IsNullOrWhiteSpace($help.HelpUri) -eq $false    }

    \# once the parameter adjustment has been processed, call the original    \# Get-Help cmdlet with the parameters found in $PSBoundParameters
    \# turn the original Get-Help cmdlet into a proxy command receiving the    \# adjusted parameters    \# with a proxy command, you can invoke its begin, process, and end    \# logic separately. That's required to preserve pipeline functionality    $cmd = Get-Command -Name 'Get-Help' -CommandType Cmdlet    $proxy = {& $cmd @PSBoundParameters}.    GetSteppablePipeline($myInvocation.CommandOrigin)

    \# now, call its default begin, process, and end blocks in the appropriate     \# script blocks so it integrates in real-time pipelines    $proxy.Begin($PSCmdlet)
  }

  process { $proxy.Process($_) }

  end     { $proxy.End() }

  \# use the original help taken from Get-Help for this function  <#
      .ForwardHelpTargetName Microsoft.PowerShell.Core\Get-Help      .ForwardHelpCategory Cmdlet  \#>}
```

运行此代码时，`Get-Help` 函数现在将覆盖原始的 `Get-Help` cmdlet。在内部，该函数调用原生的 cmdlet，但在此之前，该函数检查 `-Online` 是否应设为默认参数。

现在，仅当用户未提交任何有冲突的参数时才发生这种情况，并且仅当首先有可用于所请求命令的联机帮助时才发生这种情况。

现在，无论何时使用 `Get-Help` 或通用参数 `-?`，您都会获得丰富的在线帮助（如果可用）或本地默认帮助。

试试以下代码：

```powershell
PS> Get-Service -?

PS> Connect-IscsiTarget -?

PS> Get-Help Get-Service

PS> Get-Help Get-Service -ShowWindow
```

由于有可用于 `Get-Service` 的联机帮助，因此第一个调用将打开浏览器窗口并显示帮助。第二个调用说明了没有可用的联机帮助时发生的情况：此处未将 "`-Online`" 作为默认参数，而是显示了默认的本地帮助。

第三和第四次调用说明 `Get-Help` 仍然可以正常运行。默认情况下，该命令现在会打开联机帮助，但是如果您添加其他参数（例如 `-ShowWindow`），它们仍将按预期运行。

如果您喜欢此功能，则应将其添加到您的配置文件脚本中。

注意：如果您已通过 `$PSDefaultParameter` 为 `Get-Help` 设置了任何默认参数（即，按照前面的提示进行操作时），则这些参数将生效，并且上面的功能无法为您带来任何改善。

确保您没有定义任何会影响 "`Get-Help`" 的默认参数：

```powershell
PS> $PSDefaultParameterValues.Keys.ToLower() -like 'get-help*'
```

<!--本文国际来源：[Better PowerShell Help (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/better-powershell-help-part-2)-->

