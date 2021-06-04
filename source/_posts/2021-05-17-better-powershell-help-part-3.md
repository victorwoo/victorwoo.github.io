---
layout: post
date: 2021-05-17 00:00:00
title: "PowerShell 技能连载 - 更好的 PowerShell 帮助（第 3 部分）"
description: PowerTip of the Day - Better PowerShell Help (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们使用自定义代理功能对原始的 `Get-Help` cmdlet 进行了“影子”处理。该功能检查命令是否存在联机帮助，如果存在，则默认情况下会打开丰富的联机帮助。这极大地改善了 PowerShell 中的帮助体验。

但是，通过简单的调整，您可以使该功能更进一步：为什么不同时检查另一种方式呢？如果用户使用 `-Online` 参数，但是没有在线帮助，则 `Get-Help` 会抛出一个丑陋的异常。显示内置的本地帮助而不是抛出异常，不是更好吗？

当用户将 `Get-Help` 的默认值设置为 `-Online` 时，也可使该函数能适应 `$PSDefaultParameterValue` 的调整。

这是更新的函数：

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
    \# we do the adjustments only when the user has submitted    \# the -Name, -Category, and -Online parameters
    if ( (@($PSBoundParameters.Keys) -ne 'Name' -ne 'Category' -ne 'Online').         Count -eq 0       )
    {
      \# check whether there IS online help available at all
      \# retrieve the help URI      $help = Microsoft.PowerShell.Core\Get-Command -Name $Name
      \# reset the parameter -Online based on availability of online help      $PSBoundParameters['Online']=      [string]::IsNullOrWhiteSpace($help.HelpUri) -eq $false    }

    \# once the parameter adjustment has been processed, call the original    \# Get-Help cmdlet with the parameters found in $PSBoundParameters
    \# turn the original Get-Help cmdlet into a proxy command receiving the    \# adjusted parameters    \# with a proxy command, you can invoke its begin, process, and end    \# logic separately. That's required to preserve pipeline functionality    $cmd = Get-Command -Name 'Get-Help' -CommandType Cmdlet    $proxy = {& $cmd @PSBoundParameters}.    GetSteppablePipeline($myInvocation.CommandOrigin)

    \# now, call its default begin, process, and end blocks in the appropriate     \# script blocks so it integrates in real-time pipelines    $proxy.Begin($PSCmdlet)
  }

  process { $proxy.Process($_) }

  end     { $proxy.End() }

  \# use the original help taken from Get-Help for this function  <#
      .ForwardHelpTargetName Microsoft.PowerShell.Core\Get-Help      .ForwardHelpCategory Cmdlet  \#>}
```

运行这段代码之后，无论使用 `Get-Help`，`help` 还是公共参数 `-?`，您的帮助系统现在都变得更加智能。

如果有可用于命令的联机帮助，则默认情况下显示：

```powershell
PS> Get-Help Get-Service

PS> Get-Service -?
```

如果没有可用的联机帮助，它将始终显示本地帮助（即使您不小心指定了 `-Online` 或使用 `$PSDefaultParameterValue` 来显式使用 `-Online`）：

```powershell
PS> Connect-IscsiTarget -?

PS> Get-Help Connect-IscsiTarget -Online
```

并且，如果您指定其他参数，它们仍然可以按预期继续工作：

```powershell
PS> Get-Help Get-Service -ShowWindow
```

本质上，该调整仅包含同时提供丰富在线帮助内容，并在可用时显示它。

如果您喜欢此功能，请将其添加到配置文件脚本中，以便在启动 PowerShell 时对其进行定义。路径可以在这里找到：`$profile.CurrentUserAllHosts`。

<!--本文国际来源：[Better PowerShell Help (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/better-powershell-help-part-3)-->
