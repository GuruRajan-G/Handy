cls
$env:PSModulePath = $env:PSModulePath + ";C:\Program Files\Microsoft SQL Server\110\Tools\PowerShell\Modules"
$env:PSModulePath = $env:PSModulePath + ";C:\Program Files\WindowsPowerShell\Modules;"


Push-Location
Import-Module "sqlps" –DisableNameChecking
Pop-Location

#Email Configuration
$From = "DBComponentsVerificationScript@humana.com"
$sendMailTo = "Ggopal3@gmail.com"
$Mailer = new-object Net.Mail.SMTPclient('pobox.gmail.com')
$Subject = "DB Components Verification"
#$Msg.IsBodyHTML = $False
$Body="DB Components Verification"
$ErrorMessage=""

$output_path 		= "C:\OnlyGuru\Compare\DBComponentsValidation"
$schema 		= "dbo"
$table_path 		= "$output_path\Table\"
$storedProcs_path 	= "$output_path\StoredProcedure\"
$triggers_path 		= "$output_path\Triggers\"
$views_path 		= "$output_path\View\"
$udfs_path 		= "$output_path\UserDefinedFunction\"
$textCatalog_path 	= "$output_path\FullTextCatalog\"
$udtts_path 		= "$output_path\UserDefinedTableTypes\"


# Opens a file dialog to select an CSV File 
function Select-FileDialog {  
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null 
    $objForm = New-Object System.Windows.Forms.OpenFileDialog 
    $ShellApp = New-Object -com Shell.Application 
    $objForm.InitialDirectory = ($ShellApp.namespace(0x10)).Self.Path 
    $objForm.Filter = "CSV Files|*.csv"
    $objForm.Title = "Select an CSV file" 
    $ShellApp.MinimizeAll()  
    $Show = $objForm.ShowDialog() 
    $ShellApp.UndoMinimizeALL()  
    If ($Show -eq "OK") 
    { 
    
        Return $objForm.FileName
    } 
    else
    {
        Return "ER100"
    }
} 

Function Invoke-Exe{
    [CmdletBinding(SupportsShouldProcess=$true)]

    param(
        [parameter(mandatory=$true,position=0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Executable,

        [parameter(mandatory=$true,position=1)]
        $Arguments
    )

    if($Arguments -eq "")
    {
        Write-Verbose "Running $ReturnFromEXE = Start-Process -FilePath $Executable -ArgumentList $Arguments -NoNewWindow -Wait -Passthru"
        $ReturnFromEXE = Start-Process -FilePath $Executable -NoNewWindow -Wait -Passthru
    }
    else{
        Write-Verbose "Running $ReturnFromEXE = Start-Process -FilePath $Executable -ArgumentList $Arguments -NoNewWindow -Wait -Passthru"
        $ReturnFromEXE = Start-Process -FilePath $Executable -ArgumentList $Arguments -NoNewWindow -Wait -Passthru
    }
    Write-Verbose "Returncode is $($ReturnFromEXE.ExitCode)"
    Return $ReturnFromEXE.ExitCode
}


function GenerateCompareHtml($Source ,$Destination ,$ResultPath ,$Compname)
{
$arg1 = "@C:\SharedFolder\BEYONDCOMPARE\Script.txt" 
$arg2 = $Source
$arg3 = $Destination
$arg4 = $ResultPath+$Compname+".html" 
$nameparamater = $Compname+".html" 

Write-Host "Resultpath value is " $ResultPath

if (-not (Test-Path $arg4)) {

        Write-Host "Path will be created"
    
		New-Item -path "$ResultPath" -name "$nameparamater" -type "file" -value $Compname

        Write-Host "Path  created"
	}

$allArgs = @($arg1, $arg2, $arg3,$arg4)

#$BCPResult = & "C:\Program Files (x86)\Beyond Compare 3\BComp.exe" $allArgs 



$EXEPath="C:\Program Files (x86)\Beyond Compare 3\BComp.exe"

$BCPResult=Invoke-exe  $EXEPath $allArgs

write-host "BCP result " $BCPResult

Return $BCPResult
}


WORKFLOW WF_DBComponentsCompare
{

param([string]$Sourceserver,[string]$Destinationserver, [string]$database,[string]$objectname,[string]$objecttype)

function Script-DBObjectsIntoFolders([string]$server, [string]$database,[string]$objectname,[string]$objecttype){

function CopyObjectsToFiles($objects, $outDir ,$server) {
	
	if (-not (Test-Path $outDir)) {
		[System.IO.Directory]::CreateDirectory($outDir)
	}
	
	foreach ($o in $objects) { 
	
		if ($o -ne $null) {
			
			$schemaPrefix = ""
			
			if ($o.Schema -ne $null -and $o.Schema -ne "") {
				$schemaPrefix = $o.Schema + "."
			}
		
			$scripter.Options.FileName = $outDir + $schemaPrefix + $o.Name +"_$server.sql"
			Write-Host "Object creation started for " $scripter.Options.FileName (Get-Date)
			$scripter.EnumScript($o)
            Return "true"
		}
	}
}


$output_path 		= "C:\OnlyGuru\Compare\DBComponentsValidation"
$schema 		= "dbo"
$table_path 		= "$output_path\Table\"
$storedProcs_path 	= "$output_path\StoredProcedure\"
$triggers_path 		= "$output_path\Triggers\"
$views_path 		= "$output_path\View\"
$udfs_path 		= "$output_path\UserDefinedFunction\"
$textCatalog_path 	= "$output_path\FullTextCatalog\"
$udtts_path 		= "$output_path\UserDefinedTableTypes\"


[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null

$srv 		= New-Object "Microsoft.SqlServer.Management.SMO.Server" $server
$db 		= New-Object ("Microsoft.SqlServer.Management.SMO.Database")
$tbl 		= New-Object ("Microsoft.SqlServer.Management.SMO.Table")
$scripter 	= New-Object ("Microsoft.SqlServer.Management.SMO.Scripter") ($server)


# Set scripter options to ensure only data is scripted
$scripter.Options.ScriptSchema 	= $true;
$scripter.Options.ScriptData 	= $false;

#Exclude GOs after every line
$scripter.Options.NoCommandTerminator 			= $false;
$scripter.Options.ToFileOnly 				= $true
$scripter.Options.AllowSystemObjects 			= $false
$scripter.Options.Permissions 				= $true
$scripter.Options.DriAllConstraints 			= $true
$scripter.Options.SchemaQualify 			= $true
$scripter.Options.AnsiFile 				= $true

$scripter.Options.SchemaQualifyForeignKeysReferences 	= $true

$scripter.Options.Indexes 				= $true
$scripter.Options.DriIndexes 				= $true
$scripter.Options.DriClustered 				= $true
$scripter.Options.DriNonClustered 			= $true
$scripter.Options.NonClusteredIndexes 			= $true
$scripter.Options.ClusteredIndexes 			= $true
$scripter.Options.FullTextIndexes 			= $true

$scripter.Options.EnforceScriptingOptions 		= $true



# Get the database and table objects
$db = $srv.Databases[$database]

if($objecttype -eq "Table")
{
Write-Host "Entered into Table for the $objectname"(Get-Date)
$tbl		 	= $db.tables | Where-object { $_.schema -eq $schema  -and -not $_.IsSystemObject -and $_.name -eq $objectname} 
Write-Host "Table found"(Get-Date)
$Result = CopyObjectsToFiles $tbl $table_path $server
if($Result -eq "true")
{
 Write-host "Function completed"
}
}


if($objecttype -eq "StoredProcedures" -OR $objecttype -eq "SP")
{
Write-Host "Entered into StoredProcedures for $objectname"(Get-Date)
$storedProcs		= $db.StoredProcedures | Where-object { $_.schema -eq $schema -and -not $_.IsSystemObject -and $_.name -eq $objectname} 
Write-Host "StoredProcedures Found"(Get-Date)
$Result=CopyObjectsToFiles $storedProcs $storedProcs_path $server
if($Result -eq "true")
{
  Write-host "Function completed"
}
}

if($objecttype -eq "Triggers")
{
Write-Host "Entered into Triggers for $objectname"(Get-Date)
$triggers		= $db.Triggers + ($tbl | % { $_.Triggers -and $_.name -eq $objectname })
Write-Host "Triggers Found"(Get-Date)
$Result=CopyObjectsToFiles $triggers $triggers_path $server
if($Result -eq "true")
{
 Write-host "Function completed"
}
}

if($objecttype -eq "Views")
{
Write-Host "Entered into Views for $objectname"(Get-Date)
$views 		 	= $db.Views | Where-object { $_.schema -eq $schema -and $_.name -eq $objectname } 
Write-Host "Views Found"(Get-Date)
$Result=CopyObjectsToFiles $views $views_path $server
if($Result -eq "true")
{
 Write-host "Function completed"
}
}

if($objecttype -eq "UserDefinedFunctions")
{
Write-Host "Entered into UserDefinedFunctions for $objectname"(Get-Date)
$udfs		 	= $db.UserDefinedFunctions | Where-object { $_.schema -eq $schema -and -not $_.IsSystemObject -and $_.name -eq $objectname } 
Write-Host "UserDefinedFunctions Found"(Get-Date)
$Result=CopyObjectsToFiles $udfs $udfs_path $server
if($Result -eq "true")
{
 Write-host "Function completed"
}
}

if($objecttype -eq "UserDefinedTableTypes")
{
Write-Host "Entered into UserDefinedTableTypes for $objectname"(Get-Date)
$udtts		 	= $db.UserDefinedTableTypes | Where-object { $_.schema -eq $schema -and $_.name -eq $objectname }
Write-Host "UserDefinedTableTypes Found"(Get-Date)
$Result=CopyObjectsToFiles $udtts $udtts_path $server
if($Result -eq "true")
{
 Write-host "Function completed"
}
}

}

parallel
{
  Script-DBObjectsIntoFolders $Sourceserver $database $objectname $objecttype

  Script-DBObjectsIntoFolders $Destinationserver $database $objectname $objecttype

}

}
try
{
$InputComponentsList = Select-FileDialog 

IF($InputComponentsList -ne 'ER100') 
{
$InputDrivePath = split-path $InputComponentsList 

$ImportCList = Import-CSV $InputComponentsList 

$CListOutParams=""
$CListOutput = New-Object System.Collections.ArrayList


$ImportCList | ForEach-Object {

   WF_DBComponentsCompare $_.SourceServer $_.DestinationServer $_.DBName $_.Name $_.Type 

   if($_.Type -eq "UserDefinedTableTypes")
   {
   $variable=$_.SourceServer
   $variable2=$_.DestinationServer
   $SourceArgument = Get-ChildItem  $udtts_path -Filter *.sql -Recurse |Where-Object { $_.Name -like '*'+$variable+'*'}| % { $_.FullName }
   $DestinationArgument = Get-ChildItem $udtts_path -Filter *.sql -Recurse |Where-Object { $_.Name -like '*'+$variable2+'*'}| % { $_.FullName }
   

    Write-Host "Argue2 value is " $SourceArgument

    Write-Host "Argue3 value is" $DestinationArgument

    if($SourceArgument -ne  ""  -and $DestinationArgument -ne "" )
    {

    $hTMLRESULT=GenerateCompareHtml  $SourceArgument $DestinationArgument $udtts_path $_.Name

    IF($hTMLRESULT -EQ "0")
    {

    Write-Host "Deletion process for UDTT - Started"-ForegroundColor Yellow

    $Deletionpath=$udtts_path+"dbo."+$_.Name+"*.sql"

    Write-Host "Deletetion paht   $Deletionpath"

    Remove-Item -Path $Deletionpath

    Write-Host "Deletion process for UDTT - Completed"-ForegroundColor Yellow
    }
    }
   }     
     

   if($_.Type -eq "StoredProcedures")
   {
   $variable=$_.SourceServer
   $variable2=$_.DestinationServer
   $Objectname=$_.Name
   $SourceArgument = Get-ChildItem $storedProcs_path -Filter *.sql -Recurse |Where-Object { $_.Name -like '*'+$Objectname+'*'+$variable+'*'}| % { $_.FullName }
   $DestinationArgument = Get-ChildItem $storedProcs_path -Filter *.sql -Recurse |Where-Object { $_.Name -like '*'+$Objectname+'*'+$variable2+'*'}| % { $_.FullName }
   

    Write-Host "Argue2 value is " $SourceArgument

    Write-Host "Argue3 value is" $DestinationArgument

    if($SourceArgument -ne  ""  -and $DestinationArgument -ne "" )
    {
    write-host "entered into generatedhtml"

    $hTMLRESULT=GenerateCompareHtml  $SourceArgument $DestinationArgument $storedProcs_path $_.Name

     IF($hTMLRESULT -EQ "0")
    {


    Write-Host "Deletion process  for SP- Started"-ForegroundColor Yellow

    $Deletionpath=$storedProcs_path+"dbo."+$_.Name+"*.sql"

    Write-Host "Deletetion paht   $Deletionpath"

    Remove-Item -Path $Deletionpath

    Write-Host "Deletion process for SP - Completed"-ForegroundColor Yellow

    }

    }
   }

   
   
   if($_.Type -eq "Table")
   {
   
   $variable=$_.SourceServer
   $variable2=$_.DestinationServer
   $SourceArgument = Get-ChildItem $table_path -Filter *.sql -Recurse |Where-Object { $_.Name -like '*'+$variable+'*'}| % { $_.FullName }
   $DestinationArgument = Get-ChildItem $table_path -Filter *.sql -Recurse |Where-Object { $_.Name -like '*'+$variable2+'*'}| % { $_.FullName }
   

    Write-Host "Argue2 value is " $SourceArgument

    Write-Host "Argue3 value is" $DestinationArgument

    if($SourceArgument -ne  ""  -and $DestinationArgument -ne "" )
    {   

    $hTMLRESULT=    GenerateCompareHtml  $SourceArgument $DestinationArgument $table_path $_.Name

      IF($hTMLRESULT -EQ "0")
    {


     Write-Host "Deletion process for table- Started"-ForegroundColor Yellow

     $Deletionpath=$table_path+"dbo."+$_.Name+"*.sql"

     Write-Host "Deletetion paht   $Deletionpath"

    Remove-Item -Path $Deletionpath

    Write-Host "Deletion process for table- Completed"-ForegroundColor Yellow  
    

    }

    }
   
   }
 
   

 }

  
  
}
ELSE
{
$Body = "No input files provided for verification."
$Msg = new-object Net.Mail.MailMessage($From,$sendMailTo,$Subject,$Body)
$Mailer.send($Msg)
}
}
catch
{
    $ErrorMessage = $_.Exception.Message
    $Body = "SCRIPT : "+"'"+$ScriptName +"'"+" Executed at : "+ $env:COMPUTERNAME +" has an error. `n"+"THE ERROR MESSAGE GENERATED IS  "+"`n"+"`n"+$ErrorMessage+"`n"+"`n"+ $error

    Send-MailMessage -To $sendMailTo -Body $Body -Subject $Subject -from $From -smtpServer 'pobox.gmail.com' -Priority High
}
