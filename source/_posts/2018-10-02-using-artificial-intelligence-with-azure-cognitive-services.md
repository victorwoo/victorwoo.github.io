---
layout: post
date: 2018-10-02 00:00:00
title: "PowerShell 技能连载 - 通过 Azure 认知服务使用人工智能"
description: PowerTip of the Day - Using Artificial Intelligence with Azure Cognitive Services
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
现在的云服务不仅提供虚拟机和存储，而且提供全新且令人兴奋的服务，例如认知服务。如果您需要直接访问这些服务，您需要一个 Azure 订阅密钥（可以在以下网站免费获得）。否则，您也可以使用这里提供的免费的互动 DEMO：
[https://azure.microsoft.com/en-us/services/cognitive-services/computer-vision/#analyze](https://azure.microsoft.com/en-us/services/cognitive-services/computer-vision/#analyze)

以下是一个发送图片文件到 Azure 图片分析的脚本，您将获得关于照片内容的详细描述，包括面部的坐标、性别，以及估计的年龄：

```powershell
# MAKE SURE YOU SPECIFY YOUR FREE OR PAID AZURE SUBSCRIPTION ID HERE:
$subscription = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"


Add-Type -AssemblyName System.Net.Http
# MAKE SURE YOU SPECIFY A PATH TO A VALID IMAGE ON YOUR COMPUTER
$image = "C:\sadjoey.jpg"
$uriBase = "https://westcentralus.api.cognitive.microsoft.com/vision/v2.0/analyze";
$requestParameters = "visualFeatures=Categories,Tags,Faces,ImageType,Description,Color,Adult"
$uri = $uriBase + "?" + $requestParameters

# get image file as a byte array
$imageData = Get-Content $image -Encoding Byte 

# wrap image into byte array content
$content = [System.Net.Http.ByteArrayContent]::new($imageData)
$content.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::new("application/octet-stream")

# get a webclient ready
$webclient = [System.Net.Http.HttpClient]::new()
$webclient.DefaultRequestHeaders.Add("Ocp-Apim-Subscription-Key",$subscription)

# post the request to Azure Cognitive Services
$response = $webclient.PostAsync($uri, $content).Result
$result = $response.Content.ReadAsStringAsync().Result

# convert information from JSON into objects
$data = $result | ConvertFrom-Json

# get image detail information
$data.description.captions
$data.Faces | Out-String
$data.description.Tags
```

结果类似这样：

```powershell
PS C:\> $data.description.captions

text                                          confidence
----                                          ----------
a man and a woman standing in a room 0,94136500176759652



PS C:\> $data.faces

age gender faceRectangle                            
--- ------ -------------                            
    23 Female @{top=114; left=229; width=47; height=47}



PS C:\> $data.description.tags
person
indoor
man
holding
woman
standing
window
table
room
front
living
young
video
computer
kitchen
playing
remote
wii
people
white
game 
```

您也可以查看一下通过 Web Service 返回的 JSON 数据：

```powershell
$result
{"categories":[{"name":"indoor_","score":0.42578125},{"name":"others_","score":0
.00390625}],"tags":[{"name":"person","confidence":0.999438464641571},{"name":"in
door","confidence":0.99413836002349854},{"name":"wall","confidence":0.9905883073
8067627}],"description":{"tags":["person","indoor","man","holding","woman","stan
ding","window","table","room","front","living","young","video","computer","kitch
en","playing","remote","wii","people","white","game"],"captions":[{"text":"a man
    and a woman standing in a room","confidence":0.94136500176759652}]},"faces":[{"
age":23,"gender":"Female","faceRectangle":{"top":114,"left":229,"width":47,"heig
ht":47}}],"adult":{"isAdultContent":false,"adultScore":0.023264557123184204,"isR
acyContent":false,"racyScore":0.042826898396015167},"color":{"dominantColorForeg
round":"Brown","dominantColorBackground":"Black","dominantColors":["Brown","Blac
k","Grey"],"accentColor":"6E432C","isBwImg":false},"imageType":{"clipArtType":0,
"lineDrawingType":0},"requestId":"8aebed85-68eb-4b9f-b6f9-5243cd20e4d7","metadat
a":{"height":306,"width":408,"format":"Jpeg"}}
```

<!--more-->
本文国际来源：[Using Artificial Intelligence with Azure Cognitive Services](http://community.idera.com/powershell/powertips/b/tips/posts/using-artificial-intelligence-with-azure-cognitive-services)
