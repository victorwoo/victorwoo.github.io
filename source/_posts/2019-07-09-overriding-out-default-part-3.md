---
layout: post
date: 2019-07-09 00:00:00
title: "PowerShell 技能连载 - 覆盖 Out-Default（第 3 部分）"
description: PowerTip of the Day - Overriding Out-Default (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
高级的 PowerShell 用户常常发现他们在做以下三件事之一：

* 他们运行前面的命令并添加 `Get-Member`，以了解产生的对象的更多信息
* 他们运行前面的命令并添加 `Select-Object *` 来查看所有属性
* 他们运行前面的命令并将其通过管道传输到 `Out-GridView` 来查看图形化结果

这三条都可以更容易地实现，并且在所有 PowerShell 中都可工作，包括控制台、PowerShell ISE，或 Visual Studio Code。只需要覆盖 `Out-Default` 并且监听按键。当按下特定按键及回车键时，`Out-Default` 将会自动为您执行以上额外任务：

* 左方向键 + 回车按下时，对执行结果运行 `Get-Member` 并且将结果显示在网格视图中
* 右方向键 + 回车按下时，将所有执行结果显示在一个网格试图窗口中，这样您可以接触到数据
* TAB + 回车按下时，将对结果执行 `Select-Object *`，同时也将结果显示在网格视图中

```powershell
cls
Write-Host ([PSCustomObject]@{
  'Left Arrow + ENTER' = 'Show Member'
  'Right Arrow + ENTER' = 'Echo results'
  'Tab + ENTER' = 'Show all properties'
} | Format-List | Out-String)

function Out-Default
{
  param(
    [switch]
    ${Transcript},

    [Parameter(ValueFromPipeline=$true)]
    [psobject]
  ${InputObject})

  begin
  {
    $scriptCmd = {& 'Microsoft.PowerShell.Core\Out-Default' @PSBoundParameters }
    $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
    $steppablePipeline.Begin($PSCmdlet)
    Add-Type -AssemblyName WindowsBase
    Add-Type -AssemblyName PresentationCore
    $showGridView = [System.Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::Right)
    $showAllProps = [System.Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::Tab)
    $showMember = [System.Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::Left)

    if ($showGridView)
    {
      $cmd = {& 'Microsoft.PowerShell.Utility\Out-GridView' -Title (Get-Date -Format 'HH:mm:ss')  }
      $out = $cmd.GetSteppablePipeline()
      $out.Begin($true)

    }
    if ($showMember)
    {

      $cmd = {& 'Microsoft.PowerShell.Utility\Get-Member' | Select-Object -Property @{Name = 'Type';Expression = { $_.TypeName }}, Name, MemberType, Definition | Sort-Object -Property Type, {
        if ($_.MemberType -like '*Property')
        { 'B' }
        elseif ($_.MemberType -like '*Method')
        { 'C' }
        elseif ($_.MemberType -like '*Event')
        { 'A' }
        else
        { 'D' }
      }, Name | Out-GridView -Title Member  }
      $outMember = $cmd.GetSteppablePipeline()
      $outMember.Begin($true)

    }

  }

  process
  {
    $isError = $_ -is [System.Management.Automation.ErrorRecord]

    if ($showMember -and (-not $isError))
    {
      $outMember.Process($_)
    }
    if ($showAllProps -and (-not $isError))
    {
      $_ = $_ | Select-Object -Property *
    }
    if (($showGridView) -and (-not $isError))
    {
      $out.Process($_)
    }
    $steppablePipeline.Process($_)
  }

  end
  {
    $steppablePipeline.End()
    if ($showGridView)
    {
      $out.End()
    }
    if ($showMember)
    {
      $outMember.End()
    }

  }
}
```

要移除这个覆盖函数，只需要运行：

```powershell
PS C:\> del function:Out-Default
```

<!--本文国际来源：[Overriding Out-Default (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/overriding-out-default-part-3)-->

