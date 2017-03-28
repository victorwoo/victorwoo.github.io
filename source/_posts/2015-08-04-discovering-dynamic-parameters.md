layout: post
date: 2015-08-04 11:00:00
title: "PowerShell 技能连载 - 发现动态参数"
description: PowerTip of the Day - Discovering Dynamic Parameters
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
在前一个技能中我们展示了如何查找暴露了动态参数的 cmdlet。现在让我们来探索什么事动态参数。这个 `Get-CmdletDynamicParameter` 函数将返回一个动态参数的列表和它们的缺省值：

    #requires -Version 2
    function Get-CmdletDynamicParameter
    {
      param (
        [Parameter(ValueFromPipeline = $true,Mandatory = $true)]
        [String]
        $CmdletName
      )
    
      process
      {
        $command = Get-Command -Name $CmdletName -CommandType Cmdlet
        if ($command)
        {
          $cmdlet = New-Object -TypeName $command.ImplementingType.FullName
          if ($cmdlet -is [Management.Automation.IDynamicParameters])
          {
            $flags = [Reflection.BindingFlags]'Instance, Nonpublic'
            $field = $ExecutionContext.GetType().GetField('_context', $flags)
            $context = $field.GetValue($ExecutionContext)
            $property = [Management.Automation.Cmdlet].GetProperty('Context', $flags)
            $property.SetValue($cmdlet, $context, $null)
    
            $cmdlet.GetDynamicParameters()
          }
        }
      }
    }
    
    Get-CmdletDynamicParameter -CmdletName Get-ChildItem

该函数使用一些黑客的办法来暴露动态参数，这种方法是受到 Dave Wyatt 的启发。请参见他的文章 [https://davewyatt.wordpress.com/2014/09/01/proxy-functions-for-cmdlets-with-dynamic-parameters/](https://davewyatt.wordpress.com/2014/09/01/proxy-functions-for-cmdlets-with-dynamic-parameters/)。

<!--more-->
本文国际来源：[Discovering Dynamic Parameters](http://community.idera.com/powershell/powertips/b/tips/posts/discovering-dynamic-parameters)
