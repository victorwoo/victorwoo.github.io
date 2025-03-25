if (Get-Module Get-Identity) { Remove-Module Get-Identity }
Import-Module .\Get-Identity.psm1

Get-RandomName # 生成随机的姓名
Get-RandomQQ # 生成随机的 QQ 号
Get-RandomEMail # 生成随机的 e-mail
Get-RandomMobile # 生成随机的手机号
'{0:yyyy/MM/dd}' -f (Get-RandomBirthday) # 生成随机的生日
Get-RandomSex # 生成随机的性别
Get-RandomID # 生成随机的身份证号

Get-RandomIdentity # 生成随机的身份信息

# 批量生成 20 个完整的身份信息
1..20 | % {
    Get-RandomIdentity
} | Out-GridView -Title 随机身份信息
