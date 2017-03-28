layout: post
date: 2017-02-22 00:00:00
title: "PowerShell 技能连载 - 设置环境变量"
description: PowerTip of the Day - Setting Environment Variables
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
当通过 PowerShell 的 "`env:`" 驱动器来设置环境变量，您只需要操作其中的数据即可。它会应用到当前的 PowerShell 实例，和所有由它启动的应用程序。不过改变并不会保存。

要设置环境变量并使之持久化，请用这段代码代替：

```powershell
$name = 'Test'
$value = 'hello'
$scope = [EnvironmentVariableTarget]::User

[Environment]::SetEnvironmentVariable($name, $value, $scope)
```

这个例子设置了一个名为 "test"，值为 "hello" 的用户级别新环境变量。请注意这个改变只会影响设置这个变量之后启动的应用程序。

要彻底删除一个环境变量，请将 `$value` 设置成一个空字符串。

<!--more-->
本文国际来源：[Setting Environment Variables](http://community.idera.com/powershell/powertips/b/tips/posts/setting-environment-variables)
