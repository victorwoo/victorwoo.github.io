---
layout: post
title: 用 XAMPP 搭建反向代理服务器
date: 2014-08-14 11:05:05
description: Reverse proxy with xampp
categories: server
tags:
- server
- geek
- xampp
- apache
- proxy
---
公网 IP 地址 + 80 端口是稀缺资源。在开发、测试阶段，我们常常需要在一个公网 IP 的 80 端口上，绑定多个 WEB 服务，这些服务可能部署在内网的多台异构服务器上（不同操作系统、不同服务器软件）。

用表格来表达就是：

| 外网访问             | 重定向到            |
|----------------------|---------------------|
| http://home.test.com | http://127.0.0.1:81 |
| http://img.test.com  | http://127.0.0.1:82 |
| http://js.test.com   | http://127.0.0.1:83 |

在 Linux 下，可以通过 vhost 程序来实现这个需求。在 Windows 下，我们有 XAMPP 和 IIS 两种选择。本文重点介绍 XAMPP 的实现方式。

# 分别搭建 3 个测试服务器

可以采用这些小工具快速创建测试服务器：

* [anywhere](https://www.npmjs.org/package/anywhere)
* [HFS ~ HTTP File Server](http://www.rejetto.com/hfs/)


# 设置 hosts 以便测试

首先要让 3 个域名都指向本机。我们可以直接修改本地 hosts 文件以便测试。这种方式立刻生效，免去申请域名的麻烦。

用提升权限的记事本打开 `%windir%\system32\drivers\etc\hosts` 文件，加入这段：

    127.0.0.1 home.test.com
    127.0.0.1 img.test.com
    127.0.0.1 js.test.com

这里有个快捷的方法，参见：[PowerShell 技能连载 - 编辑“hosts”文件](/powershell/tip/2014/08/05/edit-network-hosts-file/)。

# 搭建 XAMPP 环境

请参见 [XAMPP 学习路线](/server/2014/08/14/xampp-guideline/)。只需要其中的 Apache 模块即可。确保 XAMPP 能够正常启动，并能够通过 http://127.0.0.1 访问缺省页面。

# 设置 XAMPP

编辑 `xampp\apache\conf\httpd.conf`，将 `LoadModule proxy_http_module modules/mod_proxy_http.so` 前的 `#` 号去掉。

编辑 `xampp\apache\conf\extra\httpd-vhosts.conf`，在尾部添加：

    ProxyRequests Off

    <Proxy *>
        Order deny,allow
        Allow from all
    </Proxy>

    <VirtualHost *:80>
        ServerName blog.test.com
        ProxyPass / http://127.0.0.1:81/
        ProxyPassReverse / http://127.0.0.1:81/
    </VirtualHost>

    <VirtualHost *:80>
        ServerName img.test.com
        ProxyPass / http://127.0.0.1:82/
        ProxyPassReverse / http://127.0.0.1:82/
    </VirtualHost>

    <VirtualHost *:80>
        ServerName js.test.com
        ProxyPass / http://127.0.0.1:83/
        ProxyPassReverse / http://127.0.0.1:83/
    </VirtualHost>

重启 XAMPP 中的 Apache 组件

# 姊妹篇 - 用 IIS 搭建反向代理服务器

用 IIS 也可以实现相同的功能。

* [IIS实现反向代理 - 爱做梦的鱼 - 博客园](http://www.cnblogs.com/dreamer-fish/p/3911953.html)
* [iis7 配置反向代理_justin_新浪博客](http://blog.sina.com.cn/s/blog_532f78a40100rlpn.html)

注意有个坑：

用 `%windir%\System32\inetsrv\iis.msc` 或通过“这台电脑 - 右键 - 计算机管理” 启动 IIS 管理器，可能看不到 ARR 组件；而通过 `%windir%\system32\inetsrv\InetMgr.exe` 则可以看到。

# 鸣谢
* XAMPP 方式，在网友 _坎坎_ 的指导下实现。
* IIS 方式，在网友 _莫名_ 的指导下实现。
* 参考文章 [XAMPP 反向代理配置 - 绿的日志 - 网易博客](http://remember.green.blog.163.com/blog/static/1234157362013924112027624/) - 里面的路径等稍有不对，所以本文重新整理。
