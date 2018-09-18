################################
#### Softwares Needed  ######
#1. Powershell Version 5.1 is needed to use this tool. (If not we need to remap the class objects with local variable)
#2. Excel is needed
#3. Sql Powershell modules needed C:\Program Files\Microsoft SQL Server\110\Tools\PowerShell\Modules"
################################ 

################################
#### Steps To be Followed ######
#1. Provide the Mandatory Parameters and Execute the powershell
#2. Specify the SSIS server,Folder,DBObject,and project values in Graphical User Interface
#1.
#1.
#1.
################################ 
cls
$env:PSModulePath = $env:PSModulePath + ";C:\Program Files\Microsoft SQL Server\110\Tools\PowerShell\Modules"
$env:PSModulePath = $env:PSModulePath + ";C:\Program Files\WindowsPowerShell\Modules;"

Push-Location
Import-Module "sqlps" –DisableNameChecking
Pop-Location

class SSISPackageMover
{
[string] $Source
[string] $Destination
[string] $Name
[string] $FolderName
[string] $Server
[string] $Database
[string] $SMTP
}

TRY
{

################################
#### Mandatory PARAMETERS ######
################################ 
$SendMailTo =  "Ggopal3@gmail.com"
$Evironment = " SSISReference_Report" 
$SendMailFrom = $Evironment+"@gmail.com"
$DownloadFolder = "U:\MyIspacs\"
$SsisServer=@("ABCD110","ABCD26","ABCDQS116","ABCD115")   #Specify the SSIS server you require here
$PowerobjTemp = [SSISPackageMover]::New()
$PowerobjTemp.Server="(LocalDB)\V11.0"
$PowerobjTemp.Database ="tempdb"
$SMTP='pobox.gmail.com'
$UIResult=$null
$UIResult= GUI

if($UIResult -ne $null)
{

Write-Host "UI result '$UIResult'"
#ExcelandMailcreation $UIResult $DownloadFolder $SendMailFrom $SendMailTo $SMTP $PowerobjTemp.Server.ToString() $PowerobjTemp.Database.ToString()SS

}
 
   
}
CATCH
{  
$ErrorMessage = $_.Exception.Message
Write-Host $ErrorMessage
}


function DownloadProdPackage($SsisServer,$FolderName,$ProjectName,$DownloadFolder,$CreateSubfolders,$UnzipIspac)
{

#################################################
########## DO NOT EDIT BELOW THIS LINE ##########
#################################################
clear
Write-Host "========================================================================================================================================================"
Write-Host "== Used parameters =="
Write-Host "========================================================================================================================================================"
Write-Host "SSIS Server             :" $SsisServer
Write-Host "Folder Name             :" $FolderName
Write-Host "Project Name            :" $ProjectName
Write-Host "Local Download Folder   :" $DownloadFolder
Write-Host "Create Subfolders       :" $CreateSubfolders
Write-Host "Unzip ISPAC (> .NET4.5) :" $UnzipIspac
Write-Host "========================================================================================================================================================"


##########################################
########## Mandatory parameters ##########
##########################################
if ($SsisServer -eq "")
{
    Throw [System.Exception] "SsisServer parameter is mandatory"
}
if ($DownloadFolder -eq "")
{
    Throw [System.Exception] "DownloadFolder parameter is mandatory"
}
elseif (-not $DownloadFolder.EndsWith("\"))
{
    # Make sure the download path ends with an slash
    # so we can concatenate an subfolder and filename
    $DownloadFolder = $DownloadFolder = "\"
}


############################
########## SERVER ##########
############################
# Load the Integration Services Assembly
Write-Host "Connecting to server $SsisServer "
$SsisNamespace = "Microsoft.SqlServer.Management.IntegrationServices"
[System.Reflection.Assembly]::LoadWithPartialName($SsisNamespace) | Out-Null;

# Create a connection to the server
$SqlConnectionstring = "Data Source=" + $SsisServer + ";Initial Catalog=master;Integrated Security=SSPI;"
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection $SqlConnectionstring

# Create the Integration Services object
$IntegrationServices = New-Object $SsisNamespace".IntegrationServices" $SqlConnection

# Check if connection succeeded
if (-not $IntegrationServices)
{
    Throw [System.Exception] "Failed to connect to server $SsisServer "
}
else
{
    Write-Host "Connected to server" $SsisServer
}


#############################
########## CATALOG ##########
#############################
# Create object for SSISDB Catalog
$Catalog = $IntegrationServices.Catalogs["SSISDB"]

# Check if the SSISDB Catalog exists
if (-not $Catalog)
{
    # Catalog doesn't exists. Different name used?
    Throw [System.Exception] "SSISDB catalog doesn't exist."
}
else
{
    Write-Host "Catalog SSISDB found"
}


############################
########## FOLDER ##########
############################
if ($FolderName -ne "")
{
    # Create object to the folder
    $Folder = $Catalog.Folders[$FolderName]
    # Check if folder exists
    if (-not $Folder)
    {
        # Folder doesn't exists, so throw error.
        Write-Host "Folder" $FolderName "not found"
        Throw [System.Exception] "Aborting, folder not found"
    }
    else
    {
        Write-Host "Folder" $FolderName "found"
    }
}


#############################
########## Project ##########
#############################
if ($ProjectName -ne "" -and $FolderName -ne "")
{
    $Project = $Folder.Projects[$ProjectName]
    # Check if project already exists
    if (-not $Project)
    {
        # Project doesn't exists, so throw error.
        Write-Host "Project" $ProjectName "not found"
        Throw [System.Exception] "Aborting, project not found"
    }
    else
    {
        Write-Host "Project" $ProjectName "found"
    }
}


##############################
########## DOWNLOAD ##########
##############################
Function DownloadIspac
{
    Param($DownloadFolder, $Project, $CreateSubfolders, $UnzipIspac)
    if ($CreateSubfolders)
    {
        $DownloadFolder = ($DownloadFolder + $Project.Parent.Name)
    }

    # Create download folder if it doesn't exist
    New-Item -ItemType Directory -Path $DownloadFolder -Force > $null

    # Check if new ispac already exists
    if (Test-Path ($DownloadFolder + $Project.Name + ".ispac"))
    {
        Write-Host ("Downloading [" + $Project.Name + ".ispac" + "] to " + $DownloadFolder + " (Warning: replacing existing file)")
    }
    else
    {
        Write-Host ("Downloading [" + $Project.Name + ".ispac" + "] to " + $DownloadFolder)
    }

    # Download ispac
    $ISPAC = $Project.GetProjectBytes()
    [System.IO.File]::WriteAllBytes(($DownloadFolder + "\" + $Project.Name + ".ispac"),$ISPAC)
    if ($UnzipIspac)
    {
        # Add reference to compression namespace
        Add-Type -assembly "system.io.compression.filesystem"

        # Extract ispac file to temporary location (.NET Framework 4.5) 
        Write-Host ("Unzipping [" + $Project.Name + ".ispac" + "]")

        # Delete unzip folder if it already exists
        if (Test-Path ($DownloadFolder + "\" + $Project.Name))
        {
            [System.IO.Directory]::Delete(($DownloadFolder + "\" + $Project.Name), $true)
        }

        # Unzip ispac
        [io.compression.zipfile]::ExtractToDirectory(($DownloadFolder + "\" + $Project.Name + ".ispac"), ($DownloadFolder + "\" + $Project.Name))

        # Delete ispac
        Write-Host ("Deleting [" + $Project.Name + ".ispac" + "]")
        [System.IO.File]::Delete(($DownloadFolder + "\" + $Project.Name + ".ispac"))
    }
    
    $searchFolder =$DownloadFolder + "\" + $Project.Name +"\" +"*.dtsx"

    ##Insert Package Metadta from PackageXML into Package table

    DownloadMetadataFrmPckgXML $searchFolder $Powerobj.Destination.ToString()

   
}


#############################
########## LOOPING ##########
#############################
# Counter for logging purposes
$ProjectCount = 0

# Finding projects to download
if ($FolderName -ne "" -and $ProjectName -ne "")
{
    # We have folder and project
    $ProjectCount++
    DownloadIspac $DownloadFolder $Project $CreateSubfolders $UnzipIspac
}
elseif ($FolderName -ne "" -and $ProjectName -eq "")
{
    # We have folder, but no project => loop projects
    foreach ($Project in $Folder.Projects)
    {
        $ProjectCount++
        DownloadIspac $DownloadFolder $Project $CreateSubfolders $UnzipIspac
    }
}
elseif ($FolderName -eq "" -and $ProjectName -ne "")
{
    # We only have a projectname, so search
    # in all folders
    foreach ($Folder in $Catalog.Folders)
    {
        foreach ($Project in $Folder.Projects)
        {
            if ($Project.Name -eq $ProjectName)
            {
                Write-Host "Project" $ProjectName "found in" $Folder.Name
                $ProjectCount++
                DownloadIspac $DownloadFolder $Project $CreateSubfolders $UnzipIspac
            }
        }
    }
}
else
{
    # Download all projects in all folders
    foreach ($Folder in $Catalog.Folders)
    {
        foreach ($Project in $Folder.Projects)
        {
            $ProjectCount++
            DownloadIspac $DownloadFolder $Project $CreateSubfolders $UnzipIspac
        }
    }
}

###########################
########## READY ##########
###########################
# Kill connection to SSIS
$IntegrationServices = $null
Write-Host "`nFinished, total downloads" $ProjectCount
}

function DownloadMetadataFrmPckgXML ($SelectedFolder,$Searchkey,$tempServername,$tempdatabase)
{ 
 Write-Host "`nEntered into Deploying process for the Project- '$SelectedFolder' and search key is '$Searchkey'"

$query=@"
sp_configure 'show advanced options', 1;
reconfigure;
GO
sp_configure 'xp_cmdshell', 1;
reconfigure;
GO

USE [tempdb]
GO

IF NOT EXISTS(SELECT 1
          FROM   sys.objects
          WHERE  name = 'Package')
BEGIN

CREATE TABLE dbo.Package
  (
     PackageName nvarchar(max) null,
PackagePath nvarchar(max) null,
TaskXML xml,	   
TaskName nvarchar(max) null,
TaskType nvarchar(max) null,
DFTTaskValue nvarchar(max) null,
EsqlTQuery nvarchar(max) null
  )
END
GO


DECLARE	@Path	VARCHAR(2000); 
SET @Path = '$SelectedFolder'; --Must be of form [drive letter]\...\*.dtsx

DECLARE @id NVARCHAR(MAX)
SELECT @id = '$SearchKey'


DECLARE	@MyFiles TABLE (MyID INT IDENTITY(1,1) PRIMARY KEY, FullPath VARCHAR(2000));
DECLARE	@CommandLine VARCHAR(4000) ;

SELECT	@CommandLine =LEFT('dir "' + @Path + '" /A-D /B /S ',4000);
INSERT	INTO @MyFiles (FullPath) 
EXECUTE	xp_cmdshell @CommandLine;
DELETE
FROM	@MyFiles
WHERE	FullPath IS NULL 
OR		FullPath='File Not Found' 
OR		FullPath = 'The system cannot find the path specified.'
OR		FullPath = 'The system cannot find the file specified.'
OR        FullPath LIKE '%obj%'; 

--SELECT * FROM @MyFiles

--pkgStats needs to be a proper table (rather than a table variable) because we later use it in dynamic SQL
IF EXISTS (select * from sys.tables where name = N'pkgStats')
		DROP	TABLE pkgStats;
CREATE	 TABLE pkgStats(
		PackagePath	varchar(900)	NOT NULL PRIMARY KEY
,		PackageXML	XML				NOT NULL
);

DECLARE	@FullPath	varchar(2000);
DECLARE	file_cursor CURSOR
FOR		SELECT FullPath FROM @MyFiles;
OPEN	file_cursor
FETCH	NEXT FROM file_cursor INTO @FullPath;
WHILE	@@FETCH_STATUS = 0
BEGIN
		--Needs to be dynamic SQL because OPENROWSET won't take a variable as an argument
		declare	@sql	nvarchar(max);
		SET @sql = '
		INSERT	pkgStats (PackagePath,PackageXML)
		select  ''@FullPath'' as PackagePath
		,		cast(BulkColumn as XML) as PackageXML
		from    openrowset(bulk ''@FullPath'',
								single_blob) as pkgColumn';
		SELECT	@sql = REPLACE(@sql, '@FullPath', @FullPath);
		EXEC	sp_executesql @sql;
		
		FETCH	NEXT FROM file_cursor INTO @FullPath;
END
CLOSE	file_cursor;
DEALLOCATE file_cursor;

IF Object_id('tempdb..#T') IS NOT NULL
  BEGIN
      DROP TABLE #T
  END

SELECT t.PackagePath,
Package.node.value('declare namespace p1="www.microsoft.com/SqlServer/Dts";string(./@p1:ObjectName)', 'nvarchar(max)')  AS PackageName,
Package.node.query('.') As Packagexml
 INTO   #T
FROM   (SELECT PackageXML AS pkgXML,PackagePath FROM   pkgStats) t
CROSS APPLY pkgXML.nodes('declare namespace DTS="www.microsoft.com/SqlServer/Dts";/DTS:Executable')AS Package(node)
--WHERE pkgXML.exist('//*/text()[contains(.,sql:variable("@id"))]') = 1


IF Object_id('tempdb..#T2') IS NOT NULL
  BEGIN
      DROP TABLE #T2
  END

IF Object_id('tempdb..#T3') IS NOT NULL
  BEGIN
      DROP TABLE #T3
  END
  
/********************************************************Extracting DFT task From Executable Xml******************************************************************************************************************/
;WITH XMLNAMESPACES('www.microsoft.com/SqlServer/Dts' AS p1,
                    'www.microsoft.com/sqlserver/dts/tasks/sqltask' AS p2 )
SELECT 
	   PackageName,
	   PackagePath,
	   Pkg.props.query('.') as TaskXML,
	   
	   Pkg.props.value('./@p1:ObjectName', 'nvarchar(max)') AS TaskName,
	   Pkg.props.value('./@p1:ExecutableType', 'nvarchar(max)') AS TaskType,
	   Pkg.Props.value('.', 'nvarchar(max)') AS DFTTaskValue,
	   CAST(NULL AS nvarchar(MAX)) AS EsqlTQuery
	   INTO   #T2   
        FROM   #T tx
	  		CROSS APPLY tx.Packagexml.nodes('declare namespace DTS="www.microsoft.com/SqlServer/Dts";
                            //DTS:Executable[@DTS:ExecutableType!=''STOCK:SEQUENCE''
                        and    @DTS:ExecutableType!=''STOCK:FORLOOP''
                        and    @DTS:ExecutableType!=''STOCK:FOREACHLOOP''
                        and not(contains(@DTS:ExecutableType,''.Package.''))]') Pkg(props)     


/************************************************************Extracting ESQL task From Executable Xml*************************************************************************************************************/

;WITH XMLNAMESPACES('www.microsoft.com/SqlServer/Dts' AS p1,
                    'www.microsoft.com/sqlserver/dts/tasks/sqltask' AS p2 )

SELECT 
PackageName,
PackagePath,
TaskXML,	   
TaskName,
TaskType,
CAST(NULL AS nvarchar(MAX)) AS DFTTaskValue,
Props.Prop.value('./@p2:SqlStatementSource', 'nvarchar(max)')  AS EsqlTQuery 
INTO   #T3
FROM #T2 ty
CROSS APPLY  ty.TaskXML.nodes('/p1:Executable/p1:ObjectData/p2:SqlTaskData') Props(Prop)
WHERE  ty.EsqlTQuery is null
AND ty.TaskType='Microsoft.SqlServer.Dts.Tasks.ExecuteSQLTask.ExecuteSQLTask, Microsoft.SqlServer.SQLTask, Version=11.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91'


/************************************************************Extracting ESQL task From Executable Xml*************************************************************************************************************/
 
 --TRUNCATE TABLE dbo.Package

 INSERT INTO Package (PackageName,PackagePath,TaskXML,TaskName,TaskType,DFTTaskValue,EsqlTQuery)

 SELECT * FROM #T2 WHERE EsqlTQuery is null and   DFTTaskValue IS NOT  NULL and TaskType!='Microsoft.SqlServer.Dts.Tasks.ExecuteSQLTask.ExecuteSQLTask, Microsoft.SqlServer.SQLTask, Version=11.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91'
 UNION ALL
 SELECT * FROM #T3
 
  

 SELECT * FROM Package
 
"@

$result =Invoke-Sqlcmd -Query $query -Serverinstance $PowerobjTemp.Server -Database $PowerobjTemp.Database  -QueryTimeout 0

Write-Host "`nDeploying process Completed for the Project- '$SelectedFolder' and search key is '$Searchkey'"

Remove-Item $SelectedFolder

} 

function GUI()
{
   [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
   [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
    
    # Set the size of your form
    $Form = New-Object System.Windows.Forms.Form
    $Form.width = 500
    $Form.height = 500
    $Form.Text = ”SSIS Reference Finder”
 
    # Set the font of the text to be used within the form
    $Font = New-Object System.Drawing.Font("Times New Roman",12)
    $Form.Font = $Font
 
    $SourceDropDown = new-object System.Windows.Forms.ComboBox
    $SourceDropDown.Location = new-object System.Drawing.Size(130,20)
    $SourceDropDown.Size = new-object System.Drawing.Size(200,90)
    $SourceDropDown.Text ="Select SSIS server"

 
    $ObjecttextBox = new-object System.Windows.Forms.TextBox
    $ObjecttextBox.Location = new-object System.Drawing.Size(130,60)
    $ObjecttextBox.Size = new-object System.Drawing.Size(280,90)
    $ObjecttextBox.Text ="Enter the DBObject Name"

    $FolderDropdown = New-Object System.Windows.Forms.ComboBox
    $FolderDropdown.Location = new-object System.Drawing.Size(130,100)
    $FolderDropdown.Size = new-object System.Drawing.Size(280,40)
    $FolderDropdown.Text ="Select Folder"


    $ProjectDropdown = New-Object System.Windows.Forms.ComboBox
    $ProjectDropdown.Location = new-object System.Drawing.Size(130,140)
    $ProjectDropdown.Size = new-object System.Drawing.Size(280,90)
    $ProjectDropdown.Text ="Select All / Select Project"

    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Point(175,280)
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Text = 'Search'
    $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $OKButton
    $form.Controls.Add($OKButton)
    
    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Point(250,280)
    $CancelButton.Size = New-Object System.Drawing.Size(75,23)
    $CancelButton.Text = 'Cancel'
    $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $CancelButton
    $form.Controls.Add($CancelButton)   

  
    ForEach ($Server in $SsisServer) {    [void] $SourceDropDown.Items.Add($Server)        }
 
    $Form.Controls.Add($SourceDropDown)

    $SourceDropDown.Add_SelectedIndexChanged({populate_projects $SourceDropDown.SelectedItem})      
    
 
    $Form.Add_Shown({$Form.Activate()})
    
    $result = $Form.ShowDialog()

 if ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
       

        $Powerobj = [SSISPackageMover]::New()
        $Powerobj.Source = $SourceDropDown.SelectedItem
        $Powerobj.Destination=$ObjecttextBox.Text
        $Powerobj.Name=$ProjectDropdown.SelectedItem
        $Powerobj.FolderName=$FolderDropdown.SelectedItem

        if( $Powerobj.Name -eq $null)
        {
        DownloadProdPackage $Powerobj.Source.ToString() $Powerobj.FolderName.ToString() $Powerobj.Name.ToString() $null $true $true   #FolderName is null so All the Package will be downloaded
        }
        else
        { 
        DownloadProdPackage $Powerobj.Source.ToString() $Powerobj.FolderName.ToString() $Powerobj.Name.ToString() $DownloadFolder $true $true   #FolderName is Provided respective prj pckgs will be downloaded

        }
             
        
         write-host "Download completed"    

         $SearchString=$Powerobj.Destination.ToString()

        $SearchQuery="SELECT * FROM Package WHERE DFTTaskValue LIKE '%$SearchString%' OR EsqlTQuery LIKE '%$SearchString%'"

Write-Host $SearchQuery

$Search_Result=Invoke-Sqlcmd -Query $SearchQuery -ErrorAction Stop -ServerInstance $PowerobjTemp.Server.ToString() -Database $PowerobjTemp.Database.ToString()  -QueryTimeout 0

if($Search_Result -ne $null)
{

GenerateForm $Search_Result
}
          return $Powerobj.Destination.ToString()
               
        

 }

 if ($result -eq 'Cancel') {  return $null }
 


}

function populate_projects($SourceDropDownValue)
{
  
 
    $ServerInstance =$SourceDropDownValue     

    $CompleteProjectquery="SELECT DISTINCT NAME as Projects FROM catalog.projects WITH(NOLOCK)"
          
    $Projects=(Invoke-Sqlcmd -Query $CompleteProjectquery -ErrorAction Stop -ServerInstance $ServerInstance -Database "SSISDB"  -QueryTimeout 0).Projects

    $CompleteFolderquery="SELECT DISTINCT NAME as Folders FROM CATALOG.folders WITH(NOLOCK)"
          
    $Folders=(Invoke-Sqlcmd -Query $CompleteFolderquery -ErrorAction Stop -ServerInstance $ServerInstance -Database "SSISDB"  -QueryTimeout 0).Folders

    foreach($Folder in $Folders)
    {
        [void] $FolderDropdown.Items.Add($Folder)
    }

    
    $Form.Controls.Add($FolderDropdown) 
    
    foreach($Project in $Projects)
    {
        [void] $ProjectDropdown.Items.Add($Project)
    }
 
     $Form.Controls.Add($ProjectDropdown)

      
     $Form.Controls.Add($ObjecttextBox)

    }

function ExcelandMailcreation ($Search_Result,$DownloadFolder,$SendMailFrom,$SendMailTo,$SMTP)
{

Write-Host "`nExcel Creation for the run - Started`n"-ForegroundColor Yellow
$Search_Result |Export-Csv -Path $DownloadFolder\SSISReferenceFinderResult.csv  -NoTypeInformation

    
    Write-Host "Excel Creation for the run - completed"-ForegroundColor Yellow

   #Mail Task - Start
   
   Write-Host "`nMail Task  - Started`n"-ForegroundColor Yellow


    $a = "<style>"
    $a = $a + "BODY{background-color:peachpuff;}"
    $a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
    $a = $a + "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:thistle}"
    $a = $a + "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:PaleGoldenrod}"
    $a = $a + "</style>"
    
    
    
      
    $Subject = "SSISReferenceFinder_Result"  

   
    $Body_Summary   = $Search_Result| Select-Object PackageName,PackagePath,TaskName,TaskType| ConvertTo-HTML -head $a -Body "<H4>SSIS Object Impact in the Below Items</H4>" | Out-String
   
    $Body=$Body_Summary   
    
   
    Send-MailMessage -To $SendMailTo -Body $Body -BodyAsHtml -Attachments $DownloadFolder\SSISReferenceFinderResult.csv  -Subject $Subject -From $SendMailFrom -SmtpServer $SMTP -Priority High


    Write-Host "Mail Task - Completed"-ForegroundColor Yellow

   #Mail Task -END


   #Deletion process -Delete all csv created for the run

   Write-Host "`nDeletion process - Started`n"-ForegroundColor Yellow

   Remove-Item $DownloadFolder\*.* -Exclude *SSISReferenceResult_*

   Write-Host "Deletion process - Completed"-ForegroundColor Yellow

   
}

#Generated Form Function 
function GenerateForm ($Search_Result)
{ 
Add-Type -AssemblyName "System.Drawing"
Add-Type -AssemblyName "System.Windows.Forms" 

$formRDP = New-Object System.Windows.Forms.Form
$labelLoading = New-Object System.Windows.Forms.Label
$dgvServers = New-Object System.Windows.Forms.DataGridView 
$OKButton = New-Object System.Windows.Forms.Button
$CancelButton = New-Object System.Windows.Forms.Button

# formRDP
$formRDP.Name = "SSISReferenceFinder"
$formRDP.Text = "SSISReferenceFinder"
$formRDP.ClientSize = '454, 330'

$formRDP.Controls.Add($dgvServers)
$formRDP.Controls.Add($labelLoading)

# labelLoading
$labelLoading.Name = "labelLoading"
$labelLoading.Text = "Loading..."
$labelLoading.Location = '26, 26'
$labelLoading.Size = '100, 23'
$labelLoading.Font = "Microsoft Sans Serif, 12pt, style=Bold" 


# dgvServers
$dgvServers.Name = "dgvServers"
$dgvServers.Location = '13, 13'
$dgvServers.Size = '429, 800'





$dgvServers.Anchor = 'Top, Left, Right'
$dgvServers.AllowUserToAddRows = $False
$dgvServers.AllowUserToDeleteRows = $False 
$dgvServers.ReadOnly = $True 

 #$dgvServers.Dock = [System.Windows.Forms.DockStyle]::Fill
 $dgvServers.ColumnHeadersHeightSizeMode = [System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode]::AutoSize
 	
 # Enable wrap mode on the cells and make the grid autosize the rows when the columns wrap
 $dgvServers.defaultCellStyle.wrapMode= [System.Windows.Forms.DataGridViewTriState]::True
 $dgvServers.AutoSizeRowsMode = [System.Windows.Forms.DataGridViewAutoSizeRowsMode]::AllCells
 	
 ###$dgvServers.SelectionMode = 'FullRowSelect'
 $dgvServers.Visible = $False



# RDP form OnShown event handler
$formRDP_Shown = 
{
$formRDP.ClientSize = '900, 1000'

$formRDP.Refresh()

$Script:ServerData = $Search_Result | Select PackageName,TaskName,DFTTaskValue,EsqlTQuery | sort -Property PackageName 

$Script:ServerGridData = New-Object System.Collections.ArrayList
$Script:ServerGridData.AddRange( $Script:ServerData )
$dgvServers.DataSource = $Script:ServerGridData


$dgvServers.Visible = $True
$dgvServers.AutoResizeColumns( "AllCells" )

$OKButton.Location = '450, 910'
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = 'Export'
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$formRDP.AcceptButton = $OKButton
$formRDP.Controls.Add($OKButton)



$CancelButton.Location = New-Object System.Drawing.Point(580,910)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = 'Cancel'
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$formRDP.CancelButton = $CancelButton
$formRDP.Controls.Add($CancelButton)   



}

# Add event handlers to form
$formRDP.add_Shown( $formRDP_Shown )


# Show the Form
####$formRDP.ShowDialog() | Out-Null


  $result = $formRDP.ShowDialog()

   if ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
    ExcelandMailcreation    $Search_Result $DownloadFolder $SendMailFrom $SendMailTo $SMTP
    }
       
 
} #End Function 
