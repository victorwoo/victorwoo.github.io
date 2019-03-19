---
layout: post
date: 2018-06-13 00:00:00
title: "PowerShell 技能连载 - 巧妙地读取事件日志（第 1 部分）"
description: PowerTip of the Day - Reading Event Logs Smart (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您使用 PowerShell 来查询事件，缺省情况下获取到的是日志信息的文本消息。例如，如果您想知道谁登录了您的计算机，您可以使用类似这样的代码（需要管理员权限）：

```powershell
Get-EventLog -LogName Security -InstanceId 4624 |
    Select-Object -Property TimeGenerated, Message
```

结果大概类似这样：

    25.04.2018 07:48:41 An account was successfully logged on....
    25.04.2018 07:48:40 An account was successfully logged on....
    24.04.2018 18:18:17 An account was successfully logged on....
    ...

这并不是很直观，因为 PowerShell 缩短了输出内容。在类似这样的情况下，您可能需要将结果用管道传给 `Format-List`：

```powershell
Get-EventLog -LogName Security -InstanceId 4624 |
    Select-Object -Property TimeGenerated, Message |
    Format-List
```

它现在可以生成详细的数据了：

```powershell
PS> Get-EventLog -LogName Security -InstanceId 4624 |
    Select-Object -Property TimeGenerated, Message -first 1 |
    Format-List




TimeGenerated : 25.05.2018 11:39:29
Message       : An account was successfully logged on.

                Subject:
                    Security ID:		S-1-5-18
                    Account Name:		DESKTOP-7AAMJLF$
                    Account Domain:		WORKGROUP
                    Logon ID:		0x3e7

                Logon Information:
                    Logon Type:		5
                    Restricted Admin Mode:	-
                    Virtual Account:		%%1843
                    Elevated Token:		%%1842

                Impersonation Level:		%%1833

                New Logon:
                    Security ID:		S-1-5-18
                    Account Name:		SYSTEM
                    Account Domain:		NT-AUTORITÄT
                    Logon ID:		0x3e7
                    Linked Logon ID:		0x0
                    Network Account Name:	-
                    Network Account Domain:	-
                    Logon GUID:		{00000000-0000-0000-0000-000000000000}

                Process Information:
                    Process ID:		0x328
                    Process Name:		C:\Windows\System32\services.exe

                Network Information:
                    Workstation Name:	-
                    Source Network Address:	-
                    Source Port:		-

                Detailed Authentication Information:
                    Logon Process:		Advapi
                    Authentication Package:	Negotiate
                    Transited Services:	-
                    Package Name (NTLM only):	-
                    Key Length:		0

                This event is generated when a logon session is created. It is
                generated on the computer that was accessed.

                The subject fields indicate the account on the local system
                which requested the logon. This is most commonly a service
                such as the Server service, or a local process such as
                Winlogon.exe or Services.exe.

                The logon type field indicates the kind of logon that
                occurred. The most common types are 2 (interactive) and 3
                (network).

                The New Logon fields indicate the account for whom the new
                logon was created, i.e. the account that was logged on.

                The network fields indicate where a remote logon request
                originated. Workstation name is not always available and may
                be left blank in some cases.

                The impersonation level field indicates the extent to which a
                process in the logon session can impersonate.

                The authentication information fields provide detailed
                information about this specific logon request.
                    - Logon GUID is a unique identifier that can be used to
                correlate this event with a KDC event.
                    - Transited services indicate which intermediate services
                have participated in this logon request.
                    - Package name indicates which sub-protocol was used among
                the NTLM protocols.
                    - Key length indicates the length of the generated session
                key. This will be 0 if no session key was requested.
```

这个结果很难处理。如果您希望基于这段文本做一些自动化处理，您需要解析这段文本。

有一个简单得多的方法：您见到的消息只是一个文本模板，Windows 以“替换字符串”的方式插入相关的信息。他们是从 `Get-0EventLog` 接收到的事件数据的一部分。该数据存在一个数组中，整个数组对应一个事件 ID 的信息。

当您确定了哪个信息存放在哪个数组元素中，要解析出您关心的信息十分容易：

```powershell
Get-EventLog -LogName Security -InstanceId 4624 |
    ForEach-Object {
    # translate the raw data into a new object
    [PSCustomObject]@{
        Time = $_.TimeGenerated
        User = "{0}\{1}" -f $_.ReplacementStrings[5], $_.ReplacementStrings[6]
        Type = $_.ReplacementStrings[10]
        Path = $_.ReplacementStrings[17]
    }
    }
```

当您运行这一小段代码时，它返回只包含您需要的、美观的验证信息：

    12.05.2018 17:38:58 SYSTEM\NT-AUTORITÄT                     Negotiate C:\Windows\System32\services.exe
    12.05.2018 17:38:58 tobweltner@zumsel.local\InternalAccount Negotiate C:\Windows\System32\svchost.exe
    12.05.2018 17:38:58 SYSTEM\NT-AUTORITÄT                     Negotiate C:\Windows\System32\services.exe
    12.05.2018 17:38:58 SYSTEM\NT-AUTORITÄT                     Negotiate C:\Windows\System32\services.exe
    12.05.2018 17:38:53 SYSTEM\NT-AUTORITÄT                     Negotiate C:\Windows\System32\services.exe


<!--本文国际来源：[Reading Event Logs Smart (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/reading-event-logs-smart-part-1)-->
