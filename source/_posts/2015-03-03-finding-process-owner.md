---
layout: post
date: 2015-03-03 12:00:00
title: "PowerShell 技能连载 - 查找进程所有者"
description: PowerTip of the Day - Finding Process Owner
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 3.0 及以上版本_

`Get-Process` 能够返回所有运行中的进程，但是它并不包含进程所有者。要查看进程所有者，您需要采用调用 WMI 服务等方法。

要让使用过程更方便些，一下是一个小巧的工具函数：

    filter Get-ProcessOwner
    {
      $id = $_.ID
      $info = (Get-WmiObject -Class Win32_Process -Filter "Handle=$id").GetOwner()
      if ($info.ReturnValue -eq 2)
      {
        $owner = '[Access Denied]'
      }
      else
      {
        $owner = '{0}\{1}' -f $info.Domain, $info.User
      }
      $_ | Add-Member -MemberType NoteProperty -Name Owner -Value $owner -PassThru
    }

当您将进程对象通过管道传递给 `Get-ProcessOwner` 时，它为进程对象附加了一个新的 "`Owner`" 属性。该属性是一个隐藏属性，要通过 `Select-Object` 才能显示：

    PS> Get-Process -Id $pid | Get-ProcessOwner | Select-Object -Property Name, ID, Owner

    Name                    Id Owner
    ----                    -- -----
    powershell_ise       10080 TOBI2\Tobias

它也适用于多个进程对象：

    PS> Get-Process | Where-Object MainWindowTitle | Get-ProcessOwner | Select-Object -Property Name, ID, Owner

    Name                    Id Owner
    ----                    -- -----
    chrome               13028 TOBI2\Tobias
    devenv               13724 TOBI2\Tobias
    Energy Manager        6120 TOBI2\Tobias
    ILSpy                14928 TOBI2\Tobias
    (...)

请注意只有获得了管理员权限才可以获取进程所有者。如果没有货的管理员权限，您只能获得您自己进程的所有者，这样相对意义不大。

<!--本文国际来源：[Finding Process Owner](http://community.idera.com/powershell/powertips/b/tips/posts/finding-process-owner)-->
