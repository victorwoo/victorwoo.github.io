---
layout: post
date: 2017-09-28 00:00:00
title: "PowerShell 技能连载 - 获取缓存的凭据"
description: PowerTip of the Day - Getting Cached Credentials
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们谈到一个名为“PSCredentialManager”的公共模块，可以用来管理缓存的凭据。有些时候，少即是多。当您阅读它的代码时，会发现它是通过一个名为 cmdkey.exe 的控制台命令在和 windows 系统打交道。

要获取您本机缓存的凭据，您只需要这样：

```powershell
PS> cmdkey /list

Currently stored credentials:

    Target: MicrosoftAccount:target=SSO_POP_User
    Type: Domain Extended Credentials
    User: XXXXX.com
    Saved for this logon only

    Target: MicrosoftAccount:target=SSO_POP_Device
    Type: Domain Extended Credentials
    User: 06jbdrfztrwsvsb
    Saved for this logon only
...
```

它输出的是纯文本。然而，PowerShell 可以用 `ForEach-Object` 处理原始数据：

```powershell
cmdkey.exe /list | ForEach-Object {$found=$false} {
    $line = $_.Trim()
    if ($line -eq '')
    {
        if ($found) { $newobject }
        $found = $false
        $newobject = '' | Select-Object -Property Type, User, Info, Target
    }
    else
    {
        if ($line.StartsWith("Target: "))
        {
            $found = $true
            $newobject.Target = $line.Substring(8)
        }
        elseif ($line.StartsWith("Type: "))
        {
            $newobject.Type = $line.Substring(6)
        }
        elseif ($line.StartsWith("User: "))
        {
            $newobject.User = $line.Substring(6)
        }
        else
        {
            $newobject.Info = $line
        }

    }
}
```

结果类似这样：

    Type                        User                   Info                      Target
    ----                        ----                   ----                      ------
    Domain Extended Credentials tabcabcabc@hicsawr.com Saved for this logon only Mi
    Domain Extended Credentials 02jbqxcbqvsb           Saved for this logon only Mi
    Generic                     tabcabcabc@hicsawr.com Local machine persistence Le
    Generic                                            Local machine persistence Le
    Generic                                            Local machine persistence Le
    Generic                                            Local machine persistence Le
    Generic                     tabcabcabc@hicsawr.com Local machine persistence Le
    Generic                                            Local machine persistence Le
    Generic                     02jdrxcbqvsb           Local machine persistence Wi
    Generic                     Martin                                           Le
    Domain Password             Martin                                           Do
    Domain Password             Martin                                           Do
    Domain Password             User                                             Do

<!--本文国际来源：[Getting Cached Credentials](http://community.idera.com/powershell/powertips/b/tips/posts/getting-cached-credentials)-->
