#Microsoft Word must be installed

#where are we going to save the new file
$savepath="C:\work\MyDoc.docx"

#create the WORD COM object
$word=new-object -ComObject "Word.Application"

#create a new document
$doc=$word.documents.Add()

#make it visible
#$word.Visible=$True

#give the document focus
$selection=$word.Selection

#insert some content
$selection.TypeText((Get-Date))

#insert a return
$selection.TypeParagraph()

#insert some more text
$os=Get-WmiObject -class win32_OperatingSystem
$selection.TypeText("Operating System Information for $($os.CSName)")

#get an array of class properties
$os.properties | select Name | foreach -begin {$props=@()} -proc {$props+="$($_.name)"}

#text must be strings
$selection.TypeText(($os | Select -Property $props | Out-String))

#save it
$doc.SaveAs([ref]$savepath)    
$doc.Close()
    
#exit word
$word.quit()