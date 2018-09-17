cls

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null

$ExeServerName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the environment where script to executed TEST,TEST2,TEST3,INT,INT2,INT3,QA,QA2,QA3", "ExeServerName")
 
$ExecutingServerName=$ExeServerName

$env:PSModulePath = $env:PSModulePath + ";C:\Program Files\Microsoft SQL Server\110\Tools\PowerShell\Modules"
$env:PSModulePath = $env:PSModulePath + ";C:\Program Files\WindowsPowerShell\Modules;"

Push-Location
Import-Module "sqlps" –DisableNameChecking
Pop-Location


#region FunctionRelated to Powershell


Function Invoke-Exe
{
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
    }else{
        Write-Verbose "Running $ReturnFromEXE = Start-Process -FilePath $Executable -ArgumentList $Arguments -NoNewWindow -Wait -Passthru"
        $ReturnFromEXE = Start-Process -FilePath $Executable -ArgumentList $Arguments -NoNewWindow -Wait -Passthru
    }
    Write-Verbose "Returncode is $($ReturnFromEXE.ExitCode)"
    Return $ReturnFromEXE.ExitCode
}
function GenerateCompareHtml($BCScript,$BCPath,$Source ,$Destination ,$ResultPath ,$Compname)
{
WRITE-HOST "`nGenerate BC Script - Started"
Add-Content $BATCH_FilePath\BCScript.txt "data-report layout:interleaved options:line-numbers &
output-to:`"%3`" &
output-options:html-color `"%1`" `"%2`" "
WRITE-HOST "`nGenerate BC Script $BCScript - Completedd"

$arg1 = $BCScript
$arg2 = $Source
$arg3 = $Destination
$arg4 = $ResultPath+"\"+$Compname+".html" 
$nameparamater = $Compname+".html" 
<#
Write-Host "Resultpath value is " $ResultPath
Write-Host "Source value is " $arg2
Write-Host "Destination value is " $arg3
Write-Host "arg4 value is " $arg4
#>

if (-not (Test-Path $arg4)) {

        Write-Host "Path will be created"
    
		New-Item -path "$ResultPath" -name "$nameparamater" -type "file" -value $Compname

        Write-Host "Path  created"
	}

$allArgs = @($arg1, $arg2, $arg3,$arg4)

$EXEPath=$BCPath

$BCPResult=Invoke-exe  $EXEPath $allArgs

write-host "Return param vale '$arg4'"

Return $arg4

}
function ReportGeneration($SSISserver,$Folder,$project,$Pacakge,$CGXQuery,$CDMQuery,$CDMserver,$CGXSERVER,$CDMdATABASE,$CGXDATABASE,$LASTDATE,$BATCH_FilePath,$SendMailTo,$BCScript,$BCPath)
{

SSISCatalogReport $SSISserver $Folder $project $Pacakge $LASTDATE $BATCH_FilePath

$sOURCErESULT=Invoke-Sqlcmd -Query $CGXQuery -ErrorAction Stop -ServerInstance $CGXSERVER -Database $CGXDATABASE  -QueryTimeout 0

$dESTINATIONrESULT=Invoke-Sqlcmd -Query $CDMQuery -ErrorAction Stop -ServerInstance $CDMserver -Database $CDMdATABASE  -QueryTimeout 0



$sOURCErESULT |Export-Csv -Path $BATCH_FilePath\sOURCErESULT.csv  -NoTypeInformation
$dESTINATIONrESULT|Export-Csv -Path $BATCH_FilePath\dESTINATIONrESULT.csv  -NoTypeInformation

 Write-Host "`nExcel Creation for the run - Started`n"-ForegroundColor Yellow
 
    # Create Excel COM Object
    $excel = New-Object -ComObject excel.application
    $excel.visible=$true
    # Pause while Excel opens
    Start-Sleep -Seconds 2
    
    # Create a "blank" workbook
    $reportOut = $excel.Workbooks.Add()
       
     # Open workbook and copy into $reportOut
    $wb = $excel.WorkBooks.Open("$BATCH_FilePath\SSISExecutionResult.csv")
    $wb.Worksheets.Item(1).Name = "SSISExecutionReport"
    $wb.Worksheets.Copy($reportOut.WorkSheets.Item(1))
    $wb.Close(0)

    # Open workbook and copy into $reportOut
    $wb = $excel.WorkBooks.Open("$BATCH_FilePath\SSISmESSAGEResult.csv")
    $wb.Worksheets.Item(1).Name = "SSISExecutionMessage"
    $wb.Worksheets.Copy($reportOut.WorkSheets.Item(1))
    $wb.Close(0)

    # Open workbook and copy into $reportOut
    $wb = $excel.WorkBooks.Open("$BATCH_FilePath\sOURCErESULT.csv")
    $wb.Worksheets.Item(1).Name = "SourceRecords"
    $wb.Worksheets.Copy($reportOut.WorkSheets.Item(1))
    $wb.Close(0)
    
    # Open workbook and copy into $reportOut
    $wb = $excel.WorkBooks.Open("$BATCH_FilePath\dESTINATIONrESULT.csv")
    $wb.Worksheets.Item(1).Name = "DestinationRecords"
    $wb.Worksheets.Copy($reportOut.WorkSheets.Item(1))
    $wb.Close(0)
    
    # Delete "Sheet1"
    $reportOut.WorkSheets.Item(5).Delete()   
    # Delete "Sheet2"
    $reportOut.WorkSheets.Item(6).Delete()
    # Delete "Sheet3"
    $reportOut.WorkSheets.Item(5).Delete() 
    
    # Save Report and cleanup

    $date = (get-date).AddDays(-1).ToString("yyyy.MM.dd")     
    $SendMailFrom = $Pacakge+"_"+$SSISserver+"_"+$date+"@humana.com"
    $excelname=$SSISserver+"_"+$Pacakge+"_"+$date+".xlsx"

    $reportOut.SaveAs("$BATCH_FilePath\$excelname",[Microsoft.Office.Interop.Excel.XlFileFormat]::xlOpenXMLWorkbook)
    $reportOut.Close(0)
    $excel.Quit()
    
    Write-Host "Excel Creation for the run - completed"-ForegroundColor Yellow

   $SourceArgument = $BATCH_FilePath+"\SourceResult.csv"
   $DestinationArgument =$BATCH_FilePath+"\DestinationResult.csv"
   $HTMLname="Comparison"
   
   $hTMLRESULT=GenerateCompareHtml $BCScript $BCPath $SourceArgument $DestinationArgument $BATCH_FilePath $HTMLname
     
   
    Write-Host "`nMail Task - Started`n"-ForegroundColor Yellow


    $a = "<style>"
    $a = $a + "BODY{background-color:peachpuff;}"
    $a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
    $a = $a + "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:thistle}"
    $a = $a + "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:PaleGoldenrod}"
    $a = $a + "</style>"
    
    
    
      
    $Subject = "Run Result For "+$Pacakge+"on the server"+"$SSISserver"+"of the date "+$date
    
   
    
    $Body_Source  = $sOURCErESULT| SELECT * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors|ConvertTo-HTML -head $a -Body "<H4>'$Pacakge' Source Data Avaialable For the Date '$date'</H4>" | Out-String
    $Body_Destincation  = $dESTINATIONrESULT| SELECT * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors|ConvertTo-HTML -head $a -Body "<H4>'$Pacakge' Destination Data Avaialable For the Date '$date'</H4>" | Out-String
   
    $Body=$Body_Source+"`n"+"`n"+$Body_Destincation

    $EmailAttachment1= $BATCH_FilePath+"\"+$excelname

    $EmailAttachment2=  $BATCH_FilePath+"\"+$HTMLname+".html"
    
   
    Send-MailMessage -To $SendMailTo -Body $Body -BodyAsHtml -Attachments $EmailAttachment2,$EmailAttachment1   -Subject $Subject -From $SendMailFrom -SmtpServer 'pobox.humana.com' -Priority High

    Write-Host "`nMail Task - Completed`n"-ForegroundColor Yellow

    
   Write-Host "`nDeletion process - Started`n"-ForegroundColor Yellow

   Remove-Item $BATCH_FilePath\*.* -Exclude *$SSISserver*

   Write-Host "Deletion process - Completed"-ForegroundColor Yellow


}
function SSISCatalogReport($server,$folder,$project,$package,$Lastrundate,$BATCH_FilePath,$SendMailTo,$BCScript,$BCPath)
{
$SSISExecutionReportquery="SELECT  [project_name] 'Project Name', [package_name] 'Package Name', 
	[Execution_id], [Start_Time] 'Start Time', [End_Time] 'End Time',
	CASE [status]
		 WHEN 1 THEN 'Created'
		 WHEN 2 THEN 'Running'
		 WHEN 3 THEN 'Canceled'
		 WHEN 4 THEN 'Failed'
		 WHEN 5 THEN 'Pending'
		 WHEN 6 THEN 'Ended unexpectedly'
		 WHEN 7 THEN 'Succeeded'
		 WHEN 8 THEN 'Stopping'
		 WHEN 9 THEN 'Completed'
	END 'Run Status',
	DATEDIFF(mi, start_time, end_time) as 'Duration (Min)',
	[Stopped_By_Name]
 FROM    [catalog].[executions] (NOLOCK)
 WHERE Execution_id=(SELECT MAX(execution_id) FROM SSISDB.catalog.executions where project_name='$project' and package_name = '$package' and Created_time >= '$Lastrundate')
 and [project_name]='$project'
 and [package_name] ='$package'"

$SSISExecutionMessage="
SELECT message_time,event_message_id,MESSAGE,package_name,event_name,message_source_name,package_path,execution_path,message_type,message_source_type
FROM   (
       SELECT  em.*
       FROM    SSISDB.catalog.event_messages em
       WHERE   em.operation_id = (SELECT MAX(execution_id) FROM SSISDB.catalog.executions where project_name='$project' and package_name = '$package'
       and Created_time >= '$Lastrundate')                                 
                                  
                                  
           AND event_name NOT LIKE '%Validate%'
       )q
/* Put in whatever WHERE predicates you might like*/
--WHERE	event_name = 'OnError'
WHERE	package_name = '$package'
--WHERE execution_path LIKE '%<some executable>%'
ORDER BY message_time DESC
"

 Write-Host "`nGetting SSISExecutionResult from $server $folder $project $package $Lastrundate - Started"-ForegroundColor Yellow

 $SSISExecutionResult=Invoke-Sqlcmd -Query $SSISExecutionReportquery -ErrorAction Stop -ServerInstance $server -Database "SSISDB"  -QueryTimeout 0

 $SSISmESSAGEResult=Invoke-Sqlcmd -Query $SSISExecutionMessage -ErrorAction Stop -ServerInstance $server -Database "SSISDB"  -QueryTimeout 0

 $SSISExecutionResult |Export-Csv -Path $BATCH_FilePath\SSISExecutionResult.csv  -NoTypeInformation

 $SSISmESSAGEResult |Export-Csv -Path $BATCH_FilePath\SSISmESSAGEResult.csv  -NoTypeInformation

 Write-Host "`nGetting SSISExecutionResult from $server $folder $project $package $Lastrundate  - Completed"-ForegroundColor Yellow 

 

}

#endregion 


#region FunctionRelated to TableQuery
<###################################################################### Begining of Table Function ###############################################################################



#################################################################################################################################################################################>
function Tablename($SSISserver,$Folder,$project,$Pacakge,$CDMserver,$CGXSERVER,$CDMdATABASE,$CGXDATABASE,$LASTDATE,$BATCH_FilePath,$SendMailTo,$BCScript,$BCPath)
{

$CompCGXQuery= "Declare @Lastrundate datetime='$LASTDATE'
;WITH tblReferral_tmp(
[Src_cOLUMNS]

)
	AS ( SELECT * FROM TABLENAME with(nolock) WHERE ISNULL(Update_dt,Insert_dt)>@Lastrundate	

       UNION ALL

       SELECT * FROM TABLENAME with(nolock) WHERE ISNULL(Update_dt,Insert_dt)>@Lastrundate

	)
	
	
	SELECT * from tblReferral_tmp order by ISNULL(Update_dt,Insert_dt) desc"

$compCDMQuery="Declare @Lastrundate datetime='$LASTDATE'
SELECT * FROM TABLENAME with(nolock) WHERE ISNULL(Update_dt,Insert_dt)>@Lastrundate ORDER BY ISNULL(Update_dt,Insert_dt) DESC"
Write-Host "`nPLOC_UMTool  - Started"-ForegroundColor Yellow
ReportGeneration $SSISserver $Folder $project $Pacakge $CompCGXQuery $compCDMQuery $CDMserver $CGXSERVER $CDMdATABASE $CGXDATABASE $LASTDATE $BATCH_FilePath $SendMailTo $BCScript $BCPath
Write-Host "`nPLOC_UMTool  - Completed"-ForegroundColor Yellow
}

<########################################################################## END of Table Function ###############################################################################>
#endregion




IF ($ExecutingServerName -eq "TEST" )
{
$LASTDATE= (get-date).AddDays(-2).ToString("yyyy.MM.dd")
$BATCH_FilePath = "\\SharedFolder\PowershellAutomation"
$SSISserver="Specify SSIS Server"
$folder="Specify SSIS Folder"
$CDMserver="Specify Destination Server"
$CGXSERVER="Specify Source Server"
$CDMdATABASE="Specify Destination Database"
$CGXDATABASE="Specify Source Database" 
$SendMailTo = "Specify Your MailID"  
$BCScript= "@"+$BATCH_FilePath+"\BCScript.txt"
$BCPath="C:\Program Files (x86)\Beyond Compare 3\BComp.exe"
}


TRY
{
Remove-Item $BATCH_FilePath\*.* 

Tablename    $SSISserver $folder "CDM_PRJ_CompAssessmentLoad" "CDM_PKG_CompAssessment.dtsx"   $CDMserver $CGXSERVER $CDMdATABASE $CGXDATABASE $LASTDATE $BATCH_FilePath $SendMailTo $BCScript $BCPath
   
}
CATCH
{
  
$ErrorMessage = $_.Exception.Message
Write-Host $ErrorMessage
$reportOut.Close(0)
$excel.Quit()  

}
