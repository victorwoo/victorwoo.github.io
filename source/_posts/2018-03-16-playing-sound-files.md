---
layout: post
date: 2018-03-16 00:00:00
title: "PowerShell 技能连载 - 播放声音文件"
description: PowerTip of the Day - Playing Sound Files
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能里我们演示了如何用 PowerShell 播放系统声音。对于更灵活一些的场景，PowerShell 也可以播放任意的 *.wav 声音文件：

```powershell
$soundPlayer = New-Object System.Media.SoundPlayer
$soundPlayer.SoundLocation="$env:windir\Media\notify.wav"
$soundPlayer.Play()
```

默认情况下，PowerShell 并不会等待声音播放完毕。如果您需要同步播放声音，请试试这段代码：

```powershell
$soundPlayer = New-Object System.Media.SoundPlayer
$soundPlayer.SoundLocation="$env:windir\Media\notify.wav"
$soundPlayer.PlaySync()
"Done."
```

要播放不同的声音文件，只需要将路径替换为声音文件即可：

sound player 也可以用后台线程循环播放一个文件：

```powershell
$soundPlayer = New-Object System.Media.SoundPlayer
$soundPlayer.SoundLocation="$env:windir\Media\notify.wav"
$soundPlayer.PlayLooping()
```

当后台正在播放声音时，请确保用这段代码停止播放声音：

```powershell
$soundPlayer.Stop()
```

<!--本文国际来源：[Playing Sound Files](http://community.idera.com/powershell/powertips/b/tips/posts/playing-sound-files)-->
