---
layout: post
date: 2019-05-22 00:00:00
title: "PowerShell 技能连载 - 检查坏（不安全的）密码（第 1 部分）"
description: PowerTip of the Day - Checking for Bad (Insecure) Passwords (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
复杂的密码不一定安全。例如，"P@ssw0rd" 是一个非常复杂的密码，但是非常不安全。这是为什么安全社区开始建议用更相关的测试取代复杂性标准，并防止使用以前黑客入侵中使用过的密码。这些密码——虽然它们可能很复杂——是字典攻击的一个常规部分并且非常不安全。


如何知道某个密码是否已被泄露？您可以使用类似 [haveibeenpwnd.com](haveibeenpwnd.com) 的网站或者它们的 API。这是它的工作原理：

1. 您根据密码创建哈希值，这样就不会泄漏您的密码。
2. 将哈希的头五个字节发送到 API，这样就不会泄漏哈希值。
3. 您可以获得所有以这五个字节开头的哈希值。
4. 检查返回的哈希中是否有您密码的哈希值。

以下是用 PowerShell 检查密码的方法：

```powershell
# enable all SSL protocols
[Net.ServicePointManager]::SecurityProtocol = 'Ssl3,Tls, Tls11, Tls12'

# get password hash
$stream = [IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($Password))
$hash = Get-FileHash -InputStream $stream -Algorithm SHA1
$stream.Close()
$stream.Dispose()

# find first five and subsequent hash characters
$prefix, $suffix = $hash.Hash -split '(?<=^.{5})'

# ask for matching passwords with the same first 5 hash digits
$url = "https://api.pwnedpasswords.com/range/$prefix"
$response = Invoke-RestMethod -Uri $url -UseBasicParsing

# find the exact match
$lines = $response -split '\r\n'
$seen = foreach ($line in $lines)
{
  if ($line.StartsWith($suffix)) {
    [int]($line -split ':')[-1]
    break
  }
}

"$Password has been seen {0:n0} times." -f $seen
```

试着改变 `$Password` 中的密码来测试这段代码。您会很惊讶地发现许多密码已经泄漏：

    Sunshine has been seen 13.524 times.

<!--本文国际来源：[Checking for Bad (Insecure) Passwords (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/checking-for-bad-insecure-passwords-part-1)-->

