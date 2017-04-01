layout: post
title: XAMPP 学习路线
date: 2014-08-14 11:10:16
description: XAMPP guideline
categories: server
tags:
- server
- xampp
- guideline
- link
---
XAMPP = Apache + MySQL + PHP + Perl

> XAMPP是最流行的PHP开发环境

> XAMPP是完全免费且易于安装的Apache发行版，其中包含MySQL、PHP和Perl。XAMPP开放源码包的设置让安装和使用出奇容易。

![](/img/2014-08-14-xampp-guideline-001.svg)

# 网站

[XAMPP 官方网站](https://www.apachefriends.org/zh_cn/index.html)
[XAMPP - SourceForge](http://sourceforge.net/projects/xampp/)

# 文件区别

+ 安装版（适合小型服务器安装）
    * xampp-win32-*-installer.exe - 有安装向导。
    * xampp-win32-*.zip - 解开是一个 xampp 目录，但可以随后注册服务等。
    * xampp-win32-*.7z - 和 .zip 版相同，压缩后体积更小。
+ 便携版（适合开发测试。不包含 FileZilla FTP 和 Mercury Mail Server，不能安装服务）
    * xampp-portable-win32-*-installer.exe
    * xampp-portable-win32-*.zip
    * xampp-portable-win32-*.7z

# 快速起步

**切勿自己摸索！**因为不同的版本的步骤有所不同。请阅读 xampp\readme_en.txt 中的 *QUICK INSTALLATION* 节。**篇幅很短，不用担心** :)

# 潜在陷阱

* 必须安装（或解压到）根目录下。例如 D:\xampp，或者 E:\xampp。
* 注意缺省的 80 和 443 端口未被其它程序占用。`netstat -ano |find "80"`、`netstat -ano |find "443"`
* 如果用安装版的压缩包（.zip 或 .7z），并需要安装服务，请用提升权限的管理员账户打开 xampp-control.exe 进行安装。
* 如果要能让别的机器或外网访问，请注意配置防火墙。
* 通过 xampp-control.exe 启动，可能看不到完整的错误提示。请在命令行下启动 xampp_start.exe，可以看到更详细的错误提示。
* 如果遇到错误，可以根据 xampp-control.exe 面板上的各个 Logs 按钮找到相应的日志。另外，可以通过 Windows 的事件查看部分日志。
