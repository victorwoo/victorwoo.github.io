layout: post
date: 2015-09-30 15:42:00
title: "小米路由器 mini 与 OpenWRT"
description: miwifi-mini and OpenWRT
categories:
- embedded
tags:
- embedded
- linux
---
今天拿到小米路由器 mini ，准备对它刷入 OpenWRT 固件。这类操作通常都有些坑，所以将过程记录如下：

初始化
======
| 难度 | ★★☆☆☆ |
|------|-------|
| 陷阱 | ★☆☆☆☆ |

小米路由器 mini 开箱以后，按照内附的纸质说明书对它进行简单的初始化，使得电脑可以通过它上网。这个过程是面向普通消费者的，所以过程不再赘述。

初始化完成后，路由器 WEB 管理界面中可能会提示有可升级的固件，在此可以忽略，因为我们下一步可能对它进行降级。

在路由器的 USB 口中插入一个格式化为 FAT32 的空白 U 盘，容量在 1GB 以上即可，最好是带指示灯的，这样可以看得到它的读写状态。首次插入 U 盘的时候，小米路由器会向 U 盘里写入十来兆的数据，要等 U 盘指示灯停止闪烁以后再进行后续的断电、刷机等操作比较保险。

用小米路由器的手机 APP（扫盒子上的二维码下载）将路由器和小米账户绑定。这步是打开 SSH 的基础。

固件降级
========
| 难度 | ★★☆☆☆ |
|------|-------|
| 陷阱 | ★★★☆☆ |

为了打开 SSH 功能，我们需要刷入小米路由 mini 的开发版固件。注意，我们不仅不能刷入最新版的固件，相反，要对已有的固件降级。因为经过一系列实验，发现若使用高版本的小米路由器 mini 固件，在后续打开 SSH 操作的时候，会遇到黄灯闪烁 3 秒后变成了红灯的问题。

请自行搜索 0.6.40 版的 `miwifi_r1cm_all_ace8a_0.6.40.bin` 并下载，这个版本亲测可以用。官网的[MiWiFi成长日志](http://miwifi.com/miwifi_log.html)提供的 0.8.x 和 0.7.x 版都无法打开 SSH。

然后在路由器的 WEB 控制台的路由设置中手动刷入上述 .bin 文件。按照提示等待 5-8 分钟，就可以再次进入路由器的 WEB 控制台了。可以在 WEB 控制台中确认降级成功。

打开 SSH
========
| 难度 | ★★★☆☆ |
|------|-------|
| 陷阱 | ★★☆☆☆ |

打开 SSH 意味着失去保修。不过准备继续折腾的人早已做好放弃保修的准备了。

访问[MiWiFi – 小米路由器官网](http://www1.miwifi.com/)，点击“开放/开启 SSH 工具/下载工具包”，并记下 root 密码。注意这将下载一个专属的 `miwifi_ssh.bin` 文件，同款不同机器是不通用的。

把下载下来的 `miwifi_ssh.bin` 复制到刚才的 U 盘中。断电，插入 U 盘，按住复位键，通电，在黄色指示灯闪烁的时候，放开复位键，等待....
当指示灯变成 蓝色长亮的时候，说明我们获取到 root 权限并启动 SSH 服务了。

刷入 PandoraBox
===============
| 难度 | ★★★☆☆ |
|------|-------|
| 陷阱 | ★★★☆☆ |

访问 [Index of /PandoraBox/Xiaomi-Mini-R1CM/](http://downloads.openwrt.org.cn/PandoraBox/Xiaomi-Mini-R1CM/)，目前 *stable* 目录下没东西，只有 *testing* 目录下有东西，也就是只有测试版。

下载最新的 [PandoraBox-ralink-mt7620-xiaomi-mini-squashfs-sysupgrade-r460-20150216.bin](http://downloads.openwrt.org.cn/PandoraBox/Xiaomi-Mini-R1CM/testing/PandoraBox-ralink-mt7620-xiaomi-mini-squashfs-sysupgrade-r460-20150216.bin)（还有个文件名不带 mt7620 字样的固件不知道是做什么的）。

用 XSHELL、SecureCRT、PUTTY 等 SSH 客户端，以及 WinSCP 文件传输器（以 SCP 协议）以前面记录的 root 密码登录 192.168.31.1。

用 WinSCP 把下载的 PandoraBox 固件上传到小米路由 mini 的 /tmp/ 目录下，顺便改个短点的名字 *PandoraBox.bin*。

在 SSH 客户端中执行以下命令开始刷入 PandoraBox 固件：

    mtd -r write /tmp/PandoraBox.bin firmware

注意，如果遇到 **Could not open mtd device: firmware** 提示，请按前面的步骤进行固件降级。

等路由重启后，可以搜索到信号`PandoraBox_XXXX`，没有密码，连上去后进入192.168.1.1，密码 admin，之后就能看到可爱的 OpenWRT 界面了。

刷 u-boot
=========
**刷 u-boot 应该在刷 PandoraBox 步骤之前。刷 PandoraBox u-boot 不是必须的，但是刷了可以方便后续的上传固件，不用一直SS H 操作。**

u-boot是一种普遍用于嵌入式系统中的Bootloader,Bootloader是在操作系统运行之前执行的一小段程序。他可以用来恢复小米路由器的固件，可以说只要刷了uboot，你的路由器基本上刷不死了。

- 小米 u-boot 的用法是将固件命名为 miwifi.bin，存在 FAT32 U 盘根目录中，插入路由器，按住 reset 键接通电源，待黄灯闪烁之后松开。
- PandoraBox u-boot 的用法是将 PC 网卡配置成 192.168.1.2/255.255.255.0/192.168.1.1，按住 reset 键接通电源，待黄灯闪烁之后松开，用 PC 浏览器打开 http://192.168.1.1，即可通过上传 PandoraBox 的固件来刷。

**注意，小米官方的 u-boot 和 PandoraBox 的不同。刷了 PandoraBox 的固件之后，不能通过 WEB 方式刷小米固件，但可以通过 WEB 方式刷小米 u-boot，然后通过小米 u-boot 可以刷小米固件。这样来实现从 PandoraBox 刷回原产小米固件。**

主要攻略如下：

[小米路由器mini折腾之刷不死uboot篇 - 老高的技术博客](http://www.phpgao.com/xiaomi_router_uboot.html)
[小米mini使用不死uboot刷宽带宝教程 - 交流讨论 - 宽带宝论坛 - Powered by Discuz!](http://www.91kdb.com/thread-377-1-1.html)

参考
====
- [MiWiFi – 小米路由器官网](http://miwifi.com/) 如果通过小米路由器来访问，实际上访问的可能是路由器内部的管理界面。
- [使用小米路由器mini刷pandorabox并使用ChinaDNS-C + dnsmasq + shadowsocks 实现透明翻墙](http://www.fancycoding.com/miroute-mini-dnsmasq-chinadns-shadowsocks/)
- [小米路由mini潘多拉+OpenWrt+stable版+完美解决软件源+Transmission+MultiWan+Python](http://www.right.com.cn/forum/thread-158625-1-1.html)
- [【小米路由器mini刷机】mini刷潘多拉固件教程（固件已更新）_小米路由器_MIUI论坛](http://www.miui.com/thread-2036705-1-1.html)
