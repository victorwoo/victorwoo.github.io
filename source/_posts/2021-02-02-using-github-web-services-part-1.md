---
layout: post
date: 2021-02-02 00:00:00
title: "PowerShell 技能连载 - 使用 GitHub Web Service（第 1 部分）"
description: PowerTip of the Day - Using GitHub Web Services (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如今，GitHub 托管了许多开源软件。这包括诸如 Windows Terminal 或 Visual Studio Code 编辑器之类的强大工具。

GitHub 提供公共 web service 来查询已注册组织（例如 Microsoft）的 repository 详细信息，因此，如果您想了解特定软件是否有新版本，请尝试查询该 web service。

下面的示例查询组织 "Microsoft" 中 "Windows Terminal" repository 的详细信息：

```powershell
PS> $url = 'https://api.github.com/repos/microsoft/terminal/releases/latest'
PS> Invoke-RestMethod -UseBasicParsing -Uri $url


url              : https://api.github.com/repos/microsoft/terminal/releases/34250658
assets_url       : https://api.github.com/repos/microsoft/terminal/releases/34250658/assets
upload_url       : https://uploads.github.com/repos/microsoft/terminal/releases/34250658/asse
                    ts{?name,label}
html_url         : https://github.com/microsoft/terminal/releases/tag/v1.4.3243.0
id               : 34250658
author           : @{login=DHowett; id=189190; node_id=MDQ6VXNlcjE4OTE5MA==;
                    avatar_url=https://avatars2.githubusercontent.com/u/189190?v=4;
                    gravatar_id=; url=https://api.github.com/users/DHowett;
                    html_url=https://github.com/DHowett;
                    followers_url=https://api.github.com/users/DHowett/followers; following_ur
                    l=https://api.github.com/users/DHowett/following{/other_user};
                    gists_url=https://api.github.com/users/DHowett/gists{/gist_id};
                    starred_url=https://api.github.com/users/DHowett/starred{/owner}{/repo};
                    subscriptions_url=https://api.github.com/users/DHowett/subscriptions;
                    organizations_url=https://api.github.com/users/DHowett/orgs;
                    repos_url=https://api.github.com/users/DHowett/repos;
                    events_url=https://api.github.com/users/DHowett/events{/privacy};
                    received_events_url=https://api.github.com/users/DHowett/received_events;
                    type=User; site_admin=False}
node_id          : MDc6UmVsZWFzZTM0MjUwNjU4
tag_name         : v1.4.3243.0
target_commitish : main
name             : Windows Terminal v1.4.3243.0
draft            : False
prerelease       : False
created_at       : 2020-11-20T21:34:28Z
published_at     : 2020-11-20T21:43:33Z
assets           : {@{url=https://api.github.com/repos/microsoft/terminal/releases/assets/285
                    75927; id=28575927; node_id=MDEyOlJlbGVhc2VBc3NldDI4NTc1OTI3;
                    name=Microsoft.WindowsTerminal_1.4.3243.0_8wekyb3d8bbwe.msixbundle;
                    label=; uploader=; content_type=application/octet-stream; state=uploaded;
                    size=22834909; download_count=28268; created_at=2020-11-20T21:43:26Z;
                    updated_at=2020-11-20T21:43:28Z; browser_download_url=https://github.com/m
                    icrosoft/terminal/releases/download/v1.4.3243.0/Microsoft.WindowsTerminal_
                    1.4.3243.0_8wekyb3d8bbwe.msixbundle}, @{url=https://api.github.com/repos/m
                    icrosoft/terminal/releases/assets/28575931; id=28575931;
                    node_id=MDEyOlJlbGVhc2VBc3NldDI4NTc1OTMx; name=Microsoft.WindowsTerminal_1
                    .4.3243.0_8wekyb3d8bbwe.msixbundle_Windows10_PreinstallKit.zip; label=;
                    uploader=; content_type=application/zip; state=uploaded; size=22311138;
                    download_count=5063; created_at=2020-11-20T21:43:31Z;
                    updated_at=2020-11-20T21:43:32Z; browser_download_url=https://github.com/m
                    icrosoft/terminal/releases/download/v1.4.3243.0/Microsoft.WindowsTerminal_
                    1.4.3243.0_8wekyb3d8bbwe.msixbundle_Windows10_PreinstallKit.zip}}
tarball_url      : https://api.github.com/repos/microsoft/terminal/tarball/v1.4.3243.0
zipball_url      : https://api.github.com/repos/microsoft/terminal/zipball/v1.4.3243.0
body             : This is a quick servicing release to address a couple glaring issues in
                    the 1.4 stable release.

                    A [preinstallation](https://docs.microsoft.com/en-us/windows/msix/desktop/
                    deploy-preinstalled-apps) kit is available for system integrators and
                    OEMs interested in prepackaging Windows Terminal with a Windows image.
                    More information is available in the [DISM documentation on preinstallatio
                    n](https://docs.microsoft.com/windows-hardware/manufacture/desktop/preinst
                    all-apps-using-dism). Users who do not intend to preinstall Windows
                    Terminal should continue using the _msixbundle_ distribution.

                    Bugs fixed in this release:

                    * We reverted the tab switcher to _off by default_, because we changed
                    your defaults on you so that tab switching was both enabled and _in
                    most-recently-used order_. I'm sorry about that. (#8325)
                        * To turn the switcher back on, in MRU order, add the global setting
                    `"useTabSwitcher": true`.
                    * We'd previously said the default value for `backgroundImageStretch` was
                    `uniformToFill`, but it was actually `fill`. We've updated the code to
                    make it `uniformToFill`. (#8280)
                    * The tab switcher used to occasionally eat custom key bindings and
                    break, but @Don-Vito came through and helped it not do that. Thanks!
                    (#8250)
```

从这些丰富的信息中，您可以选择需要了解的详细信息，即各种格式的最新下载位置：

```powershell
$url = 'https://api.github.com/repos/microsoft/terminal/releases/latest'
$info = Invoke-RestMethod -UseBasicParsing -Uri $url

[PSCustomObject]@{
    TAR =  $info.tarball_url
    ZIP =  $info.zipball_url
    AppX = $info.Assets.Browser_Download_url[0]
} | Format-List
```

结果如下：

    TAR  : https://api.github.com/repos/microsoft/terminal/tarball/v1.4.3243.0
    ZIP  : https://api.github.com/repos/microsoft/terminal/zipball/v1.4.3243.0
    AppX : https://github.com/microsoft/terminal/releases/download/v1.4.3243.0/Microsoft.WindowsT
           erminal_1.4.3243.0_8wekyb3d8bbwe.msixbundle

<!--本文国际来源：[Using GitHub Web Services (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-github-web-services-part-1)-->

