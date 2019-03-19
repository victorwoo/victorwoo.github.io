---
layout: post
title: "PowerShell 技能连载 - 更改桌面背景"
date: 2014-01-10 00:00:00
description: PowerTip of the Day - Change Desktop Wallpaper
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 可以通过调用 Windows API，实现更改当前桌面背景并且立即生效。以下函数实现立刻更换桌面背景：

	function Set-Wallpaper
	{
	    param(
	        [Parameter(Mandatory=$true)]
	        $Path,

	        [ValidateSet('Center', 'Stretch')]
	        $Style = 'Stretch'
	    )

	    Add-Type @"
	using System;
	using System.Runtime.InteropServices;
	using Microsoft.Win32;
	namespace Wallpaper
	{
	public enum Style : int
	{
	Center, Stretch
	}
	public class Setter {
	public const int SetDesktopWallpaper = 20;
	public const int UpdateIniFile = 0x01;
	public const int SendWinIniChange = 0x02;
	[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
	private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);
	public static void SetWallpaper ( string path, Wallpaper.Style style ) {
	SystemParametersInfo( SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange );
	RegistryKey key = Registry.CurrentUser.OpenSubKey("Control Panel\\Desktop", true);
	switch( style )
	{
	case Style.Stretch :
	key.SetValue(@"WallpaperStyle", "2") ;
	key.SetValue(@"TileWallpaper", "0") ;
	break;
	case Style.Center :
	key.SetValue(@"WallpaperStyle", "1") ;
	key.SetValue(@"TileWallpaper", "0") ;
	break;
	}
	key.Close();
	}
	}
	}
	"@

	    [Wallpaper.Setter]::SetWallpaper( $Path, $Style )
	}

	Set-Wallpaper -Path 'C:\Windows\Web\Wallpaper\Characters\img24.jpg'

<!--本文国际来源：[Change Desktop Wallpaper](http://community.idera.com/powershell/powertips/b/tips/posts/change-desktop-wallpaper)-->
