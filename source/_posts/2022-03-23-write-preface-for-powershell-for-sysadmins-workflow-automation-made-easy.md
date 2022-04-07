---
layout: post
date: 2022-03-23 00:00:00
title: "为《PowerShell 实战》撰序"
description: "Write preface for PowerShell for Sysadmins: Workflow Automation Made Easy"
categories:
- powershell
tags:
- powershell
- book
- preface
---
受人民邮电出版社图灵公司委托，为图灵即将在五月出版的《PowerShell 实战》（英文原版为 PowerShell for Sysadmins: Workflow Automation Made Easy）撰写序言。这是微软 MVP Adam Bertram 的大作，亚马逊评分 4.7 分。

![PowerShell for Sysadmins: Workflow Automation Made Easy](/img/2022-03-23-write-preface-for-powershell-for-sysadmins-workflow-automation-made-easy.jpg)

以下是序言的全文。

---
**推荐序**

从 2016 年开始，细心的 Windows 10 用户发现，右键单击桌面的开始按钮，“命令提示符”选项不见了，取而代之的是 "Windows PowerShell"。这意味着存在多年的“小黑窗”遇到了变革。事实上，PowerShell 的第一个版本发布于 2006 年。作为新式的命令行 shell、脚本语言和配置管理框架，它已伴随我们走过 16 个年头。如今 PowerShell 已成为 Windows 高级用户、企业 IT 工程师、云服务管理员得心应手的利器。2016 年，开源及跨平台版推出后，PowerShell 在 Windows、Linux 和 macOS 平台上迎来了快速增长期，甚至使 Linux 用户成为 PowerShell 的核心用户。

PowerShell 之父 Jeffrey Snover 介绍了开发 PowerShell 项目的动机——主要是由于 Windows 和 Linux 核心架构的区别。在 Linux 上，一切管理操作的配置都是文本文件，因此所有的管理类软件其实就是处理文本文件的程序。而 Windows 其实是基于 API 的操作系统，所有的 API 返回的都是结构化的数据，因此那些 Unix 软件没什么帮助。这些需求推动了 PowerShell 的诞生。

从诞生之初，PowerShell 就具有一系列惊艳的特点。

- 一致性的设计，语法、命名清晰明了。
- 简单易学，能兼容现有的脚本程序和命令行工具。
- 内置丰富的标准命令 (cmdlet)，在默认环境下即可完成常见的系统管理工作。
- 具备完整的扩展体系 (PowerShellGet)、庞大的模块和脚本市场 (PowerShell Gallery)。
- 完整的强类型支持。它构建在 .NET CLR 基础之上，能接受并返回 .NET 对象。对象甚至能在管道和进程之间传递。
- 最新的 PowerShell 7 是开源和跨平台的，其推动的不仅是一家企业的产品，而是整个行业。

伟大的设计必然对应宏大的叙事，理论上需要一部鸿篇巨著才能将诸多特性介绍清楚。而当出版社向我推荐这本《PowerShell 实战》（英文原版名为 _PowerShell for Sysadmins: Workflow Automation Made Easy_）时，粗略浏览目录后，我感到十分惊讶——作者是如何仅用区区 200 多页的篇幅，兼顾语法基础、操作实战，以至完成大型项目？带着浓浓的好奇心，我读完了整本书。

作者的写作思路是针对 IT 系统管理员完成日常管理任务这一核心目标，循序介绍必要的知识，以任务目标为导向带领读者逐步构建实用的脚本，穿插介绍有用的技巧、设计模式和最佳实践。对于有兴趣的读者，作者还给出了获取扩展资料的指引，这是一种友好的结构。全书分为三个部分，层层递进。第一部分用近全书一半的篇幅介绍 PowerShell 语法、远程处理功能、自动化测试框架，这是一切后续行动的基础。语法部分避免“回字有四种写法”的枯燥理论，例如只介绍 [CmdletBinding()] 高级函数的编写，但不再介绍基本函数。而对错误处理，则重点着墨，有利于培养技术人员良好的素养。第二部分带领读者完成管理报表、AD 管理、Azure 管理、AWS 管理等日常管理任务，让读者在理论学习和动手实践的结合中产生现实收益。第三部分带领读者构建一款名为 PowerLab 的 PowerShell 模块，不时地放慢脚步对代码进行重构整理，使脚本随时处于可阅读、可维护的最佳状态。无论是 PowerShell 新手、高级用户，还是 IT 运维人员，都能从中受益。

致敬原著者 Adam Bertram（微软 Cloud and Datacenter Management MVP）、中文版译者安道，愿本书为你开启奇妙的 PowerShell 之旅。

吴波

微软 Cloud and Datacenter Management MVP
