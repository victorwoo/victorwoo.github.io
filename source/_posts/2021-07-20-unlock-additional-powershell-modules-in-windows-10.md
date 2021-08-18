---
layout: post
date: 2021-07-20 00:00:00
title: "PowerShell 技能连载 - 在 Windows 10 中解锁额外的 PowerShell 模块"
description: PowerTip of the Day - Unlock Additional PowerShell Modules in Windows 10
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows 10 附带了许多可用于控制服务器功能的 PowerShell 模块 - 例如 WSUS 更新管理，这只是众多模块中的一个。

在早期的 Windows 10 版本中，这些 PowerShell 模块是所谓的 RSAT 工具（远程服务器管理工​​具）的一部分，需要单独下载。在最近的版本中，您已经拥有 RSAT 工具（本技巧中的所有命令都需要提升权限）：

```powershell
\#requires -RunAsAdmin
Get-WindowsCapability -Online -Name "Rsat.*" |  Format-Table -AutoSize -Wrap -GroupBy Name -Property DisplayName, Description
```

结果类似于：

    Name: Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0


    DisplayName
    -----------
    RSAT: Active Directory Domain Services and Lightweight Directory Services Tools	Description
    -----------
    Active Directory Domain Services (AD DS) and Active Directory Lightweight Directory Services (AD LDS) Tools include snap-ins and command-line tools for remotely managing AD DS and AD LDS on Windows Server.

        Name: Rsat.BitLocker.Recovery.Tools~~~~0.0.1.0


    DisplayName
    -----------
    RSAT: BitLocker Drive Encryption Administration Utilities	Description
    -----------
    BitLocker Drive Encryption Administration Utilities include tools for managing BitLocker Drive Encryption features.
    BitLocker Active Directory Recovery Password Viewer helps to locate BitLocker drive encryption recovery passwords in Active Directory Domain Services (AD DS).

        Name: Rsat.CertificateServices.Tools~~~~0.0.1.0


    DisplayName
    -----------
    RSAT: Active Directory Certificate Services Tools	Description
    -----------
    Active Directory Certificate Services Tools include the Certification Authority, Certificate Templates, Enterprise PKI, and Online Responder Management snap-ins for remotely managing AD CS on Windows Server

        Name: Rsat.DHCP.Tools~~~~0.0.1.0


    DisplayName
    -----------
    RSAT: DHCP Server Tools	Description
    -----------
    DHCP Server Tools include the DHCP MMC snap-in, DHCP server netsh context and Windows PowerShell module for DHCP Server.

        Name: Rsat.Dns.Tools~~~~0.0.1.0


    DisplayName
    -----------
    RSAT: DNS Server Tools	Description
    -----------
    DNS Server Tools include the DNS Manager snap-in, dnscmd.exe command-line tool and Windows PowerShell module for DNS Server.

        Name: Rsat.FailoverCluster.Management.Tools~~~~0.0.1.0


    DisplayName
    -----------
    RSAT: Failover Clustering Tools	Description
    -----------
    Failover Clustering Tools include the Failover Cluster Manager snap-in, the Cluster-Aware Updating interface, and the Failover Cluster module for Windows PowerShell

        Name: Rsat.FileServices.Tools~~~~0.0.1.0


    DisplayName
    -----------
    RSAT: File Services Tools	Description
    -----------
    File Services Tools include snap-ins and command-line tools for remotely managing the File Services role on Windows Server.

        Name: Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0


    DisplayName
    -----------
    RSAT: Group Policy Management Tools	Description
    -----------
    Group Policy Management Tools include Group Policy Management Console, Group Policy Management Editor, and Group Policy Starter GPO Editor.

        Name: Rsat.IPAM.Client.Tools~~~~0.0.1.0


    DisplayName
    -----------
    RSAT: IP Address Management (IPAM) Client	Description
    -----------
    IP Address Management (IPAM) Client is used to connect to and manage a remote IPAM server. IPAM provides a central framework for managing IP address space and corresponding infrastructure servers such as DHCP and DNS in an Active Directory forest.

        Name: Rsat.LLDP.Tools~~~~0.0.1.0


    DisplayName
    -----------
    RSAT: Data Center Bridging LLDP Tools	Description
    -----------
    Data Center Bridging LLDP Tools include PowerShell tools for remotely managing LLDP agents on Windows Server.

        Name: Rsat.NetworkController.Tools~~~~0.0.1.0


    DisplayName
    -----------
    RSAT: Network Controller Management Tools	Description
    -----------
    Network Controller Management Tools include PowerShell tools for managing the Network Controller role on Windows Server.

        Name: Rsat.NetworkLoadBalancing.Tools~~~~0.0.1.0


    DisplayName
    -----------
    RSAT: Network Load Balancing Tools	Description
    -----------
    Network Load Balancing Tools include the Network Load Balancing Manager snap-in, the Network Load Balancing module for Windows PowerShell, and the nlb.exe and wlbs.exe command-line tools.

        Name: Rsat.RemoteAccess.Management.Tools~~~~0.0.1.0


    DisplayName
    -----------
    RSAT: Remote Access Management Tools	Description
    -----------
    Remote Access Management Tools include graphical and PowerShell tools for managing the Remote Access role on Windows Server.

        Name: Rsat.RemoteDesktop.Services.Tools~~~~0.0.1.0


    DisplayName
    -----------
    RSAT: Remote Desktop Services Tools	Description
    -----------
    Remote Desktop Services Tools include snap-ins for Remote Desktop Licensing Manager, Remote Desktop Licensing Diagnostics and Remote Desktop Gateway Manager. Use Server Manager to administer all other RDS role services.

        Name: Rsat.ServerManager.Tools~~~~0.0.1.0


    DisplayName
    -----------
    RSAT: Server Manager	Description
    -----------
    Server Manager includes the Server Manager console and PowerShell tools for remotely managing Windows Server, and includes tools to remotely configure NIC teaming on Windows Server and Best Practices Analyzer.

        Name: Rsat.Shielded.VM.Tools~~~~0.0.1.0


    DisplayName
    -----------
    SAT: Shielded VM Tools	Description
    -----------
    Shielded VM Tools include the Provisioning Data File Wizard and the Template Disk Wizard.

        Name: Rsat.StorageMigrationService.Management.Tools~~~~0.0.1.0


    DisplayName
    -----------
    RSAT: Storage Migration Service Management Tools	Description
    -----------
    Provides management tools for storage migration jobs.

        Name: Rsat.StorageReplica.Tools~~~~0.0.1.0


    DisplayName
    -----------
    RSAT: Storage Replica Module for Windows PowerShell	Description
    -----------
    Includes PowerShell module to remotely manage the Storage Replica feature on Windows Server 2016.

        Name: Rsat.SystemInsights.Management.Tools~~~~0.0.1.0


    DisplayName
    -----------
    RSAT: System Insights Module for Windows PowerShell	Description
    -----------
    System Insights module for Windows PowerShell provides the ability to manage System Insights feature.

        Name: Rsat.VolumeActivation.Tools~~~~0.0.1.0


    DisplayName
    -----------
    RSAT: Volume Activation Tools	Description
    -----------
    Volume activation Tools can be used to manage volume activation license keys on a Key Management Service (KMS) host or in Microsoft Active Directory Domain Services. These tools can be used to install, activate, and manage one or more volume activation license keys, and to configure KMS settings on Windows Server.

    Name: Rsat.WSUS.Tools~~~~0.0.1.0


    DisplayName
    -----------
    RSAT: Windows Server Update Services Tools	Description
    -----------
    Windows Server Update Services Tools include graphical and PowerShell tools for managing WSUS.

要访问所有 RSAT PowerShell 模块和工具，您可以像这样启用它们：

```powershell
#requires -RunAsAdmin
Get-WindowsCapability -Online -Name "Rsat.*" |
  Add-WindowsCapability -Online -Verbose
```

<!--本文国际来源：[Unlock Additional PowerShell Modules in Windows 10](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/unlock-additional-powershell-modules-in-windows-10)-->

