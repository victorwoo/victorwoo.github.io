
<#
Add some style and formatting to a Powershell generated Word document
Microsoft Word must be installed
#>

#where are we going to save the new file
$savepath="C:\work\MyDoc.docx"

#create the WORD COM object
$word=new-object -ComObject "Word.Application"

#create a new document
$doc=$word.documents.Add()

#make it visible if you want to watch what happens
#$word.Visible=$True

#give the document focus
$selection=$word.Selection

$selection.Style="Title"
$selection.TypeText("Operating System Report")
$selection.TypeParagraph()

#format
$selection.Font.Color="wdColorGreen"

#insert some content
$selection.TypeText((Get-Date))

$selection.font.Color="wdColorAutomatic"

#insert a return
$selection.TypeParagraph()

#insert some more text
$os=Get-WmiObject -class win32_OperatingSystem

$selection.Font.Size=12
$selection.TypeText("Operating System Information for $($os.CSName)")

#get an array of class properties
$os.properties | select Name | foreach -begin {$props=@()} -proc {$props+="$($_.name)"}

#text must be strings
$selection.Font.Size=10
$selection.Font.Name="Consolas"

$selection.TypeText(($os | Select -Property $props | Out-String))

$selection.Font.size=8
$selection.Font.Name="Calibri"
$selection.Font.Italic=$True
$selection.Font.Bold=$True

$by="Report created by $env:userdomain\$env:username"
$selection.TypeText($by)

#save it
$doc.SaveAs([ref]$savepath)    
$doc.Close()
    
#exit word
$word.quit()

#uncomment if you want to automatically re-open the document
Invoke-Item $savepath