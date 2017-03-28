layout: post
title: "PowerShell 技能连载 - 朗读英文和德文（以及西班牙文，或您指定的语言）"
date: 2014-02-03 00:00:00
description: PowerTip of the Day - Speaking English and German (and Spanish, and you name it)
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
Windows 8 是第一个完整支持本地化的文本到语音引擎的操作系统。所以您现在可以用 PowerShell 来朗读（以及咒骂）。

同时，操作系统永远有英文引擎，所以您的计算机拥有两种语言能力。

以下是一个用于德文系统的示例脚本（它可以很容易改为您的地域）。只需要修改语言 ID 即可（例如“de-de”代表德文），就可以让 Windows 说另一种语言。

请注意，在 Windows 8 之前，只附带了英文引擎。在 Windows 8 中，您可以使用您的本地语言。其它语言不可用。

	$speaker = New-Object -ComObject SAPI.SpVoice
	$speaker.Voice = $speaker.GetVoices() | Where-Object { $_.ID -like '*de-de*'}
	$null = $speaker.Speak('Ich spreche Deutsch')
	$speaker.Voice = $speaker.GetVoices() | Where-Object { $_.ID -like '*en-us*'}
	$speaker.Speak('But I can of course also speak English.')

<!--more-->
本文国际来源：[Speaking English and German (and Spanish, and you name it)](http://community.idera.com/powershell/powertips/b/tips/posts/speaking-english-and-german-and-spanish-and-you-name-it)
