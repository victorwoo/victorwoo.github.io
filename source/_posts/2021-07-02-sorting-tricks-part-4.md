---
layout: post
date: 2021-07-02 00:00:00
title: "PowerShell 技能连载 - Sorting Tricks (Part 4)"
标题：“PowerShell 技能连载 - 排序技巧（第 4 部分）”
description: PowerTip of the Day - Sorting Tricks (Part 4)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
In the previous tip we showed that Sort-Object accepts property names, hash tables or plain script blocks to sort things, and we used script blocks to control the sort algorithms, and sort string information by date and time, not alphanumerical.
在上一个技巧中，我们展示了 Sort-Object 接受属性名称、哈希表或普通脚本块来排序，并且我们使用脚本块来控制排序算法，并按日期和时间而不是字母数字对字符串信息进行排序。

In this final example, let’s use this to sort IPv4 addresses. By default, Sort-Object treats them as plain text and uses alphanumeric sorting:
在最后一个示例中，让我们使用它来对 IPv4 地址进行排序。默认情况下，Sort-Object 将它们视为纯文本并使用字母数字排序：

```powershell
PS> '10.12.11.1', '298.12.11.112', '8.8.8.8' | Sort-Object
10.12.11.1
298.12.11.112
8.8.8.8
```

To correctly sort IPv4 addresses, you can cast them to the [version] type which also consists of four numbers:
要正确排序 IPv4 地址，您可以将它们转换为 [version] 类型，该类型也包含四个数字：

```powershell
PS> '10.12.11.1', '298.12.11.112', '8.8.8.8' | Sort-Object -Property { $_ -as [version] }

8.8.8.8
10.12.11.1
298.12.11.112
```

<!--本文国际来源：[Sorting Tricks (Part 4)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/sorting-tricks-part-4)-->

