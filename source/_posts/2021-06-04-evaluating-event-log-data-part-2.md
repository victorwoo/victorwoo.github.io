---
layout: post
date: 2021-06-04 00:00:00
title: "PowerShell 技能连载 - 评估事件日志数据（第 2 部分）"
description: PowerTip of the Day - Evaluating Event Log Data (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们查看了 `Get-WinEvent` 以及如何使用哈希表来指定查询。上一个提示使用以下代码列出了 Windows 更新客户端使用事件 ID 19 写入的所有事件日志文件中的所有事件：

```powershell
Get-WinEvent -FilterHashTable @{
    ID=19
    ProviderName='Microsoft-Windows-WindowsUpdateClient'
} | Select-Object -Property TimeCreated, Message
```

结果是已安装更新的列表：

    TimeCreated         Message
    -----------         -------
    05.05.2021 18:13:34 Installation erfolgreich: Das folgende Update wurde installiert. Security Intelligence-Update für
                        Microsoft Defender Antivirus - KB2267602 (Version 1.337.679.0)
    05.05.2021 00:11:33 Installation erfolgreich: Das folgende Update wurde installiert. Security Intelligence-Update für
                        Microsoft Defender Antivirus - KB2267602 (Version 1.337.615.0)
    04.05.2021 12:07:03 Installation erfolgreich: Das folgende Update wurde installiert. Security Intelligence-Update für
                        Microsoft Defender Antivirus - KB2267602 (Version 1.337.572.0)
    03.05.2021 23:54:58 Installation erfolgreich: Das folgende Update wurde installiert. Security Intelligence-Update für
                        Microsoft Defender Antivirus - KB2267602 (Version 1.337.528.0)
    ...

通常，您只需要一个实际安装软件的列表，当您查看 "Message" 列时，需要删除大量无用的文本。

分析：事件日志消息由带有占位符的静态文本模板和插入到模板中的实际数据组成。实际数据可以在名为 "Properties" 的属性中找到，您需要做的就是找出这些属性中的哪些是您需要的信息。

这是上述代码的改进版本，它使用一个名为 "Software" 的计算属性读取属性（索引为 0）中的第一个数组元素，它恰好是已安装软件的实际名称：

```powershell
$software = @{
    Name = 'Software'
    Expression = { $_.Properties[0].Value  }
}


Get-WinEvent -FilterHashTable @{
    Logname='System'
    ID=19
    ProviderName='Microsoft-Windows-WindowsUpdateClient'
} | Select-Object -Property TimeCreated, $software
```

所以现在代码返回一个更新列表以及它们的安装时间——不需要文本解析：

    TimeCreated         Software
    -----------         --------
    05.05.2021 18:13:34 Security Intelligence-Update für Microsoft Defender Antivirus - KB2267602 (Version 1.337.679.0)
    05.05.2021 00:11:33 Security Intelligence-Update für Microsoft Defender Antivirus - KB2267602 (Version 1.337.615.0)
    04.05.2021 12:07:03 Security Intelligence-Update für Microsoft Defender Antivirus - KB2267602 (Version 1.337.572.0)
    03.05.2021 23:54:58 Security Intelligence-Update für Microsoft Defender Antivirus - KB2267602 (Version 1.337.528.0)
    03.05.2021 00:57:52 9WZDNCRFJ3Q2-Microsoft.BingWeather
    03.05.2021 00:57:25 9NCBCSZSJRSB-SpotifyAB.SpotifyMusic
    03.05.2021 00:57:06 9PG2DK419DRG-Microsoft.WebpImageExtension

<!--本文国际来源：[Evaluating Event Log Data (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/evaluating-event-log-data-part-2)-->

