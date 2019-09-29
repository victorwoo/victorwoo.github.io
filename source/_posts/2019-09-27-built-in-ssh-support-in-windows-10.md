---
layout: post
date: 2019-09-27 00:00:00
title: "PowerShell 技能连载 - 使用 Windows 10 内置的 SSH 支持"
description: PowerTip of the Day - Built-In SSH support in Windows 10
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 2018 年 10 月份，一个 Windows 10 更新加入了内置的 SSH 支持。从此之后，Windows 10 附带了一个名为 "ssh" 的命令行工具。您可以在 PowerShell 中使用它来连接到其它设备（包括 IoT、树莓派等设备）而不需要第三方工具：

```bash
PS> ssh
usage: ssh [-46AaCfGgKkMNnqsTtVvXxYy] [-B bind_interface]
            [-b bind_address] [-c cipher_spec] [-D [bind_address:]port]
            [-E log_file] [-e escape_char] [-F configfile] [-I pkcs11]
            [-i identity_file] [-J [user@]host[:port]] [-L address]
            [-l login_name] [-m mac_spec] [-O ctl_cmd] [-o option] [-p port]
            [-Q query_option] [-R address] [-S ctl_path] [-W host:port]
            [-w local_tun[:remote_tun]] destination [command]
PS>
```

<!--本文国际来源：[Built-In SSH support in Windows 10](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/built-in-ssh-support-in-windows-10)-->

