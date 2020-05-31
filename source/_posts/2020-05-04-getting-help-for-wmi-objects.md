---
layout: post
date: 2020-05-04 00:00:00
title: "PowerShell 技能连载 - 获取 WMI 对象的帮助"
description: PowerTip of the Day - Getting Help for WMI Objects
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
WMI 非常强大，但文档不太够。要改变这个情况，已经成立了一个小组并正在编写用于 PowerShell 的 WMI 参考文档：[https://powershell.one/wmi](https://powershell.one/wmi)

为了轻松查找帮助，可以将 `Help()` 方法添加到所有WMI和CIM实例对象。只需运行以下代码：

```powershell
$codeCim = {
  $url = 'https://powershell.one/wmi/{0}/{1}' -f $this.CimSystemProperties.Namespace.Replace("/","\"),
  # add class
  $this.CimSystemProperties.ClassName

  Start-Process -FilePath $url.ToLower()
}
$codeWmi = {
  $url = 'https://powershell.one/wmi/{0}/{1}' -f $this.__Namespace, $this.__Class

  Start-Process -FilePath $url.ToLower()
}

Update-TypeData -TypeName Microsoft.Management.Infrastructure.CimInstance -MemberType ScriptMethod -MemberName Help -Value $codeCim -Force
Update-TypeData -TypeName System.Management.ManagementObject -MemberType ScriptMethod -MemberName Help -Value $codeWmi -Force
```

现在，当您从 `Get-WmiObject` 或 `Get-CimInstance` 检索信息时，每个对象都具有新的 `Help()` 方法，该方法会自动在浏览器中打开相应的参考页：

```powershell
PS> $result = Get-WmiObject -Class Win32_Share

PS> $result[0].Help()

PS> $result.Help()



PS> $result = Get-CimInstance -ClassName Win32_StartupCommand

PS> $result.Help()
```

如果您想参加并获得有用的 WMI 示例代码，请转到相应的参考页面，并通过底部的注释功能添加您的代码。

<!--本文国际来源：[Getting Help for WMI Objects](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/getting-help-for-wmi-objects)-->

