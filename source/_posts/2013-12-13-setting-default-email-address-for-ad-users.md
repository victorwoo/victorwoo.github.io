---
layout: post
title: "PowerShell 技能连载 - 为 AD 用户设置缺省的 Email 地址"
date: 2013-12-13 00:00:00
description: PowerTip of the Day - Setting Default Email Address for AD Users
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
编写 Active Directory 脚本不需要额外的 module。通过简单的 .NET 框架方法，您可以实现令人惊叹的功能。实际上，这个技术十分强大，您不应该在您的生产环境下运行以下的例子，除非您知道自己在做什么。

一下代码片段在您的 Active Directory 中查找存储于 `CN=Users` 并且没有邮箱地址的的所有用户。然后，脚本将为他们设置一个缺省的邮箱地址。该地址由姓名 + "mycompany.com" 组成。

	# adjust LDAP path (i.e. remove CN=Users to search the entire domain):
	$SearchRoot = 'LDAP://CN=Users,{0}' -f ([ADSI]'').distinguishedName.ToString()
	# adjust LDAPFilter. Example: (!mail=*) = all users with no defined mail attribute
	$LdapFilter = "(&(objectClass=user)(objectCategory=person)(!mail=*))"
	
	$Searcher = New-Object DirectoryServices.DirectorySearcher($SearchRoot, $LdapFilter)
	$Searcher.PageSize = 1000
	$Searcher.FindAll() | ForEach-Object {
	  $User = $_.GetDirectoryEntry()
	  try
	  {
	        # Set mail attribute
	        $User.Put("mail", ('{0}.{1}@mycompany.com' -f $user.givenName.ToString(), $user.sn.ToString()))
	
	        # Commit the change
	        $User.SetInfo()
	  }
	  catch { Write-Warning "Problems with $user. Reason: $_" }
	}

这个示例代码可以读取并且修改、设置任意的属性。它特别适用于不能通过 cmdlet 设置的自定义属性。

<!--more-->
本文国际来源：[Setting Default Email Address for AD Users](http://community.idera.com/powershell/powertips/b/tips/posts/setting-default-email-address-for-ad-users)
