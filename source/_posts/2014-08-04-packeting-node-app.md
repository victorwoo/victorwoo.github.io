layout: post
title: 打包 node 应用程序为单一文件可执行程序
date: 2014-08-04 20:58:00
description: Guideline to packet node app into single executable application
categories: nodejs
tags:
- nodejs
---
# 解决方案
* [crcn/nexe](https://github.com/crcn/nexe) - create a single executable out of your node.js apps。支持多个平台，似乎靠谱。
* [areve/node2exe](https://github.com/areve/node2exe) - 只支持 Windows，用 `copy /b` 合并多个文件。
* [appjs/appjs](https://github.com/appjs/appjs) - 已过期，被 node-webkit 替代。
* [rogerwang/node-webkit](https://github.com/rogerwang/node-webkit) - Call all Node.js modules directly from DOM and enable a new way of writing applications with all Web technologies. 带图形界面的不二选择。
* [creationix/topcube](https://github.com/creationix/topcube) - Gives node developers a way to have a desktop GUI to their node servers using HTML5 + CSS3 as the GUI platform.

# 讨论
* [javascript - Packaging a node.js webapp as a normal desktop app - Stack Overflow](http://stackoverflow.com/questions/6834537/packaging-a-node-js-webapp-as-a-normal-desktop-app/12486874#12486874)
* [javascript - Make exe files from node.js app - Stack Overflow](http://stackoverflow.com/questions/8173232/make-exe-files-from-node-js-app)
