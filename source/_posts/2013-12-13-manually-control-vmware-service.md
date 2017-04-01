layout: post
title: "手动控制 VMware 服务"
date: 2013-12-13 00:00:00
description: Manually Control VMware Service
categories: powershell
tags:
- powershell
- geek
- vmware
---
VMware Workstation 想必是很多朋友的必装软件，强大的虚拟机功能已经不用多解释了。这里提点小小的内存优化建议，就是我们在安装完 VMware Workstation 之后，它默认是开机自启动的。那有人会说，打开msconfig，在启动项里将它关闭不就行了吗？其实不然，VMware的几个进程都是以服务方式启动的，vmware-authd.exe、vmnetdhcp.exe、vmnat.exe等等，如不经处理，它们会常驻在系统内存中。而我们并不是每天都会使用虚拟机，所以那些进程大部分时间是在浪费我们的系统资源。

但如果在服务里面将它们全部禁用，那么 VMware 也就不能使用了。最好的方法就是打开服务管理器，将它的几个服务项先全部右击停止，然后双击进去，在启动类型中改为“手动”。这样一来，开机就不会自动启动了。那么，要开 VMware 的时候怎么办呢？一个个手工开启？没必要，写个 PowerShell 脚本就可以了，我用的是最新版VMware Workstation 10，代码如下：

将所有 VMware 服务设置为手动：

	# Set-VMWareServiceToManual.ps1
	Get-Service -DisplayName vmware* | % {
	    Set-Service -Name $_.Name -StartupType Manual
	}

将所有 VMware 服务设置为自动（缺省）：

	# Set-VMWareServiceToAuto.ps1
	Get-Service -DisplayName vmware* | % {
	    Set-Service -Name $_.Name -StartupType Automatic
	}

启动所有 VMware 服务（准备运行 VMware 的时候）：

	# Start-VMWareService.ps1
	Get-Service -DisplayName vmware* | % {
	    Start-Service -Name $_.Name
	}

停止所有 VMware 服务（运行 VMware 完毕以后）：

	# Stop-VMWareService.ps1
	Get-Service -DisplayName vmware* | % {
	    Stop-Service -Name $_.Name -Force
	}

下载地址：[VMWareService.zip](/assets/download/VMWareService.zip)
