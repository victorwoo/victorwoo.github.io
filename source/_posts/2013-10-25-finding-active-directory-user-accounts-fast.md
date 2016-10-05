layout: post
title: "PowerShell 技能连载 - 快速查找 Active Directory 用户账户"
date: 2013-10-25 00:00:00
description: PowerTip of the Day - Finding Active Directory User Accounts Fast
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
LDAP 查询条件越明确，查询速度就越快，占用的资源就越少，并且查询结果越清晰。

例如，许多人使用 `objectClass` 来限制查询结果为某个指定的对象类型。若只需要查询用户账户，他们常常使用 `"objectClass=user"` 的写法。许多人不知道计算机账户也共享这个对象类型。让我们来验证这一点：

这个例子将会查找所有 SamAccountName 以 "a" 开头，并且 objectClass="user" 的账户。

	# get all users with a SamAccountName that starts with "a"
	$searcher = [ADSISearcher]"(&(objectClass=User)(sAMAccountName=a*))"
	
	# see how long this takes
	$result = Measure-Command {
	  $all = $searcher.FindAll() 
	  $found = $all.Count
	}
	
	$seconds = $result.TotalSeconds
	
	"The search returned $found objects and took $sec seconds."

然后使用这行来代替上面的代码：

	$searcher = [ADSISearcher]"(&(sAMAccountType=$(0x30000000))(sAMAccountName=a*))" 

当您换成这行代码以后，查询速度显著提升了。并且结果更清晰。这是因为普通用户账户和计算机账户的 SamAccountType 不同：

* SAM_NORMAL_USER_ACCOUNT 0x30000000
* SAM_MACHINE_ACCOUNT 0x30000001

两者的 objectClass 都属于 "User"。
<!--more-->
本文国际来源：[Finding Active Directory User Accounts Fast](http://community.idera.com/powershell/powertips/b/tips/posts/finding-active-directory-user-accounts-fast)
