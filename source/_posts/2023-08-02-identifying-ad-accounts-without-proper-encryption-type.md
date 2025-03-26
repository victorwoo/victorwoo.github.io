---
layout: post
date: 2023-08-02 08:00:42
title: "PowerShell 技能连载 - 识别未正确加密的 AD 账户"
description: PowerTip of the Day - Identifying AD Accounts without Proper Encryption Type
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
您可能在 AD 中拥有具有 `msds-SupportedEncryptionTypes` 空值的帐户（包括信任帐户）。它们以前可能是“偶然”工作的，但在加固后可能会出现问题：[KB5021131: How to manage the Kerberos protocol changes related to CVE-2022-37966](https://support.microsoft.com/zh-cn/topic/kb5021131-how-to-manage-the-kerberos-protocol-changes-related-to-cve-2022-37966-fd837ac3-cdec-4e76-a6ec-86e67501407d)。

幸运的是，PowerShell可以轻松找到潜在受影响的帐户：
<!--本文国际来源：[Identifying AD Accounts without Proper Encryption Type](https://blog.idera.com/database-tools/powershell/powertips/identifying-ad-accounts-without-proper-encryption-type/)-->

