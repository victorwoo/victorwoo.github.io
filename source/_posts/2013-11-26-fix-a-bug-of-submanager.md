layout: post
title: "修正 SubManager 的一个 bug"
date: 2013-11-26 00:00:00
description: Fix A Bug of SubManager
categories: powershell
tags: .net
---
目前最好的字幕下载工具是[爱页工作室][爱页工作室]的 [SubManager 字幕管理器][SubManager 字幕管理器]。程序通过射手网开放的API自批量动下载电影对应的字幕，省去逐个找字幕的麻烦。其工作原理与射手播放器一致，但有十余项增强。

![SubManager 字幕管理器](/img/2013-11-26-fix-a-bug-of-submanager-001.png)

目前它的最新版是 [v2013.7.2](http://www.ayeah.net/submanager/submanager-20130702-1)，我在使用过程中发现一个问题：

当搜索目录中含有扩展名为空的文件时，程序出现异常：

	有关调用实时(JIT)调试而不是此对话框的详细信息，
	请参见此消息的结尾。
	
	************** 异常文本 **************
	System.ArgumentException: 字符串的长度不能为零。
	参数名: oldValue
	   在 System.String.Replace(String oldValue, String newValue)
	   在 ShooterDownloader.DownloadForm.PopulateFileList(String dir, String[] fileList)
	   在 ShooterDownloader.DownloadForm.PopulateFileList(String dir)
	   在 ShooterDownloader.DownloadForm.PopulateFileList(String dir, String[] fileList)
	   在 ShooterDownloader.DownloadForm.PopulateFileList(String dir)
	   在 ShooterDownloader.DownloadForm.PopulateFileList(String dir, String[] fileList)
	   在 ShooterDownloader.DownloadForm.PopulateFileList(String dir)
	   在 ShooterDownloader.DownloadForm.PopulateFileList(String dir, String[] fileList)
	   在 ShooterDownloader.DownloadForm.PopulateFileList(String dir)
	   在 ShooterDownloader.DownloadForm.PopulateFileList(String dir, String[] fileList)
	   在 ShooterDownloader.DownloadForm.PopulateFileList(String dir)
	   在 ShooterDownloader.DownloadForm.PopulateFileList(String dir, String[] fileList)
	   在 ShooterDownloader.DownloadForm.PopulateFileList(String dir)
	   在 ShooterDownloader.DownloadForm.txtDir_KeyUp(Object sender, KeyEventArgs e)
	   在 System.Windows.Forms.Control.OnKeyUp(KeyEventArgs e)
	   在 System.Windows.Forms.Control.ProcessKeyEventArgs(Message& m)
	   在 System.Windows.Forms.Control.ProcessKeyMessage(Message& m)
	   在 System.Windows.Forms.Control.WmKeyChar(Message& m)
	   在 System.Windows.Forms.Control.WndProc(Message& m)
	   在 System.Windows.Forms.TextBoxBase.WndProc(Message& m)
	   在 System.Windows.Forms.TextBox.WndProc(Message& m)
	   在 System.Windows.Forms.Control.ControlNativeWindow.OnMessage(Message& m)
	   在 System.Windows.Forms.Control.ControlNativeWindow.WndProc(Message& m)
	   在 System.Windows.Forms.NativeWindow.Callback(IntPtr hWnd, Int32 msg, IntPtr wparam, IntPtr lparam)

用 [Reflector][Reflector] 将 SubManager.exe 反编译，得到它的源代码，定位到 `DownloadForm` 的 `PopulateFileList(String, String[]) : Void` 方法。其中只有一行用到 `String.Replace()` 方法：

	if ((File.Exists(info.FullName.Replace(info.Extension, ".srt")) || File.Exists(info.FullName.Replace(info.Extension, ".ass"))) || (File.Exists(info.FullName.Replace(info.Extension, ".ssa")) || File.Exists(info.FullName.Replace(info.Extension, ".smi"))))

把它改为：

	if (string.IsNullOrEmpty(info.Extension) || (File.Exists(info.FullName.Replace(info.Extension, ".srt")) || File.Exists(info.FullName.Replace(info.Extension, ".ass"))) || (File.Exists(info.FullName.Replace(info.Extension, ".ssa")) || File.Exists(info.FullName.Replace(info.Extension, ".smi"))))

并重新编译，该错误提示消失了。

我联系了作者 ayeah，他表示将在下一个版本修复。

[爱页工作室]:            http://www.ayeah.net/
[SubManager 字幕管理器]: http://www.ayeah.net/submanager
[Reflector]:             http://www.red-gate.com/products/dotnet-development/reflector/ "RedGate Reflector"
