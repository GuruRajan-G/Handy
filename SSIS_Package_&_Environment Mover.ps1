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
}

TRY
{

################################
########## PARAMETERS ##########
################################ 

$DownloadFolder = "U:\MyIspacs\" # Mandatory
$SsisServer=@("ABCDEF116","ABCDEF115") #Specify SSIS servers
GUI
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
    Write-Host ""
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
Write-Host "Finished, total downloads" $ProjectCount
}

function DeployProdPackage($TargetServerName,$ProjectName,$ProjectFilePath)
{
# Load the IntegrationServices assembly

$SsisNamespace = "Microsoft.SqlServer.Management.IntegrationServices"
$loadStatus =[System.Reflection.Assembly]::LoadWithPartialName($SsisNamespace) | Out-Null;

#$loadStatus = [System.Reflection.Assembly]::Load("Microsoft.SQLServer.Management.IntegrationServices, "+"Version=12.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91, processorArchitecture=MSIL")

# Create a connection to the server
$sqlConnectionString = `
    "Data Source=" + $TargetServerName + ";Initial Catalog=master;Integrated Security=SSPI;"
$sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString

# Create the Integration Services object
$integrationServices = New-Object $SSISNamespace".IntegrationServices" $sqlConnection

# Get the Integration Services catalog
$catalog = $integrationServices.Catalogs["SSISDB"]
# Create the target folder


$folder = $catalog.Folders

$folder

#$folder.DeployProject(
#$folder.Create()

<#
$folder = New-Object $SSISNamespace".CatalogFolder"

$folder ="/SSISDB/Atlas/PDW_CoreGroupEligibility"
#>

Write-Host "Deploying " $ProjectName " project ..."

# Read the project file and deploy it
[byte[]] $projectFile = [System.IO.File]::ReadAllBytes($ProjectFilePath)
$folder.DeployProject($ProjectName, $projectFile)


Write-Host "Deployment Done."
}

function DeployEnvironmentVariable ($SSISServername,$SelectedFolder,$ProjectDropdownvalue,$VariableName,$VariableType,$VariableValue)
{ 
 Write-Host "`nEntered into Deploying process for the ServerName- '$SSISServername' ,Project- '$ProjectDropdownvalue', VariableName- '$VariableName' ,VariableType - '$VariableType' ,VariableValue-'$VariableValue'`n"

$query=@"

            USE [SSISDB]
            
            declare @ErrorMessage varchar(200),
            @ErrorSeverity int,
            @ErrorState int,
            @SSISServername nvarchar(128)='$SSISServername',
            @ProjectName nvarchar(128)='$ProjectDropdownvalue',
            @VariableName nvarchar(128)='$VariableName',
            @VariableType nvarchar(128)='$VariableType',
            @VariableValue nvarchar(4000)='$VariableValue'

            --SELECT @SSISServername AS SSISServername,@ProjectName as ProjectName,@VariableName as VariableName,@VariableType as VariableType,@VariableValue as VariableValue
            
            /*Begin Script*/
            Begin Try
            
            
            declare @servername nvarchar(50)
            select @servername=@@servername
            if(@servername!=@SSISServername)
            RAISERROR('Please execute the script on the right server',16,1)
            ELSE
            BEGIN
                      
            IF NOT EXISTS( select p.project_id as projID from catalog.projects  P  
            			join catalog.folders F on F.folder_id=P.folder_id
            			 WHERE P.name=@ProjectName and F.name='$SelectedFolder')
            BEGIN
            RAISERROR('The SSIS project is not present on the server . Please turn the project before turning the environment variables',16,1)
            END
            ELSE
            BEGIN
            /*Declare Variables*/
             DECLARE @boolValue as bit
             DECLARE @DateValue as DateTime
             DECLARE @Value as Int
             DECLARE @floatValue as Int
             DECLARE @StringValue as nvarchar(4000)
            
             /*Check if environment exists,if not create it*/
            IF NOT EXISTS(SELECT env.name FROM catalog.environments env INNER JOIN catalog.folders fold ON env.folder_id = fold.folder_id 
            			WHERE env.name = @ProjectName AND fold.name = '$SelectedFolder')
            BEGIN
            EXEC [SSISDB].[catalog].[Create_environment] @folder_name = '$SelectedFolder',@environment_description= N'', @environment_name = @ProjectName;
            END
             
            /*Create environment reference*/
            IF NOT EXISTS( select E.environment_id as environment_id from catalog.projects  P  
            			join catalog.folders F on F.folder_id=P.folder_id
            			join catalog.environments e on e.folder_id=P.folder_id
            								    AND E.name=P.name
            			 WHERE P.name=@ProjectName and F.name='$SelectedFolder')
             BEGIN
             DECLARE @reference_id bigint; 
             EXECUTE [catalog].[create_environment_reference]  '$SelectedFolder',@ProjectName,@ProjectName,'R',null,@reference_id=@reference_id OUTPUT
             END
            
            IF NOT EXISTS(SELECT TOP 1 1 FROM  catalog.environments ENV WITH(NOLOCK) 
            JOIN catalog.environment_variables EVAR WITH(NOLOCK) ON EVAR.environment_id=ENV.environment_id
            WHERE ENV.NAME=@ProjectName
            AND EVAR.name= @VariableName)
            
            BEGIN 
            
            SET @StringValue = @VariableValue          
            EXECUTE [catalog].[create_environment_variable]  '$SelectedFolder',@ProjectName,@VariableName ,@VariableType ,False ,@StringValue,'';
            
            
            END
            
            ELSE
            
            BEGIN
            
            SET @StringValue = @VariableValue
            /*update existing env variable value*/
             EXECUTE [catalog].[set_environment_variable_Value]  '$SelectedFolder',@ProjectName,@VariableName,@StringValue
            
            END
            
            /*update existing env variable description*/
            IF NOT EXISTS(SELECT TOP 1 1 FROM  catalog.environments ENV WITH(NOLOCK) 
            			 JOIN catalog.environment_variables EVAR WITH(NOLOCK) ON EVAR.environment_id=ENV.environment_id
            			 WHERE ENV.NAME=@ProjectName
            			 AND EVAR.name=@VariableName)
            BEGIN
            
             EXECUTE [catalog].[set_environment_variable_property]  '$SelectedFolder',@ProjectName,@VariableName ,'description',@VariableName 
            
            END
            ELSE
            BEGIN
            
            /*update existing env variable protection*/
             EXECUTE [catalog].[set_environment_variable_protection] '$SelectedFolder',@ProjectName,@VariableName,False
            END
            
            
            /*set paramter to env variable*/
             EXECUTE  [catalog].[set_object_parameter_value] 20,'$SelectedFolder',@ProjectName,@VariableName,@VariableName,@ProjectName,'R'
            
            
            END;
            END;
            END TRY
            BEGIN CATCH
             SELECT
             @ErrorMessage = ERROR_MESSAGE(),
             @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
            RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
            END CATCH
            /*End of Script*/
            /*****************************************************************************************************************************************************************/

"@

$result =Invoke-Sqlcmd -Query $query -Serverinstance $SSISServername

Write-Host "`nDeploying process Completed for the ServerName- '$SSISServername' ,Project- '$ProjectDropdownvalue', VariableName- '$VariableName' ,VariableType - '$VariableType' ,VariableValue-'$VariableValue'`n"
} 

function Get-ProcessInfo ($SelectedSsisServer,$SelectedFolder,$ProjectDropdownvalue)
{ 
    $array = New-Object System.Collections.ArrayList 
    
     $ServerInstance="atlssisdbtest"
    $CompleteProjectquery="SELECT DISTINCT EVAR.name,EVAR.type,EVAR.value FROM catalog.environments ENV WITH(NOLOCK) 
                           JOIN catalog.environment_variables EVAR WITH(NOLOCK) ON EVAR.environment_id=ENV.environment_id
                           JOIN catalog.folders CF WITH(NOLOCK) ON CF.folder_id=ENV.folder_id
                           WHERE ENV.NAME='$ProjectDropdownvalue'
                           AND CF.name='$SelectedFolder'"

    $Projects=Invoke-Sqlcmd -Query $CompleteProjectquery -ErrorAction Stop -ServerInstance $SelectedSsisServer -Database "SSISDB"  -QueryTimeout 0
    $Script:procInfo = $Projects | Select Name,type,value | sort -Property Name 
    $array.AddRange($procInfo) 
    $dataGrid1.DataSource = $array 
    $form1.refresh() 
} 
 
#Generated Form Function 
function GenerateForm ($SelectedSsisServer,$SelectedFolder,$SelecteddestinationServer ,$ProjectDropdownvalue)
{ 
#region Import the Assemblies 
[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null 
[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null 
#endregion 
 
#region Generated Form Objects 
$form1 = New-Object System.Windows.Forms.Form 
$label1 = New-Object System.Windows.Forms.Label 
$button3 = New-Object System.Windows.Forms.Button 
$button2 = New-Object System.Windows.Forms.Button 
$button1 = New-Object System.Windows.Forms.Button 
$Deployebutton = New-Object System.Windows.Forms.Button 
$dataGrid1 = New-Object System.Windows.Forms.DataGrid 
$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState 
#endregion Generated Form Objects 
 
#---------------------------------------------- 
#Generated Event Script Blocks 
#---------------------------------------------- 
#Provide Custom Code for events specified in PrimalForms. 
$button3_OnClick=  
{ 
    $Form1.Close() 
} 
 
$button1_OnClick=  
{ 
    Get-ProcessInfo $SelectedSsisServer $SelectedFolder $ProjectDropdownvalue
} 
 
$button2_OnClick=  
{ 
    $selectedRow = $dataGrid1.CurrentRowIndex 

              
     foreach ($svc in $Script:procInfo) 
     { 
      DeployEnvironmentVariable $SelecteddestinationServer $SelectedFolder $ProjectDropdownvalue $svc.name $svc.type $svc.value
     }

    
} 
 
$OnLoadForm_UpdateGrid= 
{ 
    Get-ProcessInfo $SelectedSsisServer $SelectedFolder $ProjectDropdownvalue
} 
 
#---------------------------------------------- 
#region Generated Form Code 
$form1.Text = "Production Environment Variables" 
$form1.Name = "form1" 
$form1.DataBindings.DefaultDataSourceUpdateMode = 0 
$System_Drawing_Size = New-Object System.Drawing.Size 
$System_Drawing_Size.Width = 517 
$System_Drawing_Size.Height = 414 
$form1.ClientSize = $System_Drawing_Size 
 
$label1.TabIndex = 4 
$System_Drawing_Size = New-Object System.Drawing.Size 
$System_Drawing_Size.Width = 155 
$System_Drawing_Size.Height = 23 
$label1.Size = $System_Drawing_Size 
#$label1.Text = "Prod Env Variables" 
$label1.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",9.75,2,3,0) 
$label1.ForeColor = [System.Drawing.Color]::FromArgb(255,0,102,204) 
 
$System_Drawing_Point = New-Object System.Drawing.Point 
$System_Drawing_Point.X = 13 
$System_Drawing_Point.Y = 13 
$label1.Location = $System_Drawing_Point 
$label1.DataBindings.DefaultDataSourceUpdateMode = 0 
$label1.Name = "label1" 
 
$form1.Controls.Add($label1) 

$button3.TabIndex = 3 
$button3.Name = "button3" 
$System_Drawing_Size = New-Object System.Drawing.Size 
$System_Drawing_Size.Width = 75 
$System_Drawing_Size.Height = 23 
$button3.Size = $System_Drawing_Size 
$button3.UseVisualStyleBackColor = $True 
 
$button3.Text = "Close" 
 
$System_Drawing_Point = New-Object System.Drawing.Point 
$System_Drawing_Point.X = 429 
$System_Drawing_Point.Y = 378 
$button3.Location = $System_Drawing_Point 
$button3.DataBindings.DefaultDataSourceUpdateMode = 0 
$button3.add_Click($button3_OnClick) 
 
$form1.Controls.Add($button3) 



    
 
$button2.TabIndex = 2 
$button2.Name = "button2" 
$System_Drawing_Size = New-Object System.Drawing.Size 
$System_Drawing_Size.Width = 75 
$System_Drawing_Size.Height = 23 
$button2.Size = $System_Drawing_Size 
$button2.UseVisualStyleBackColor = $True  
$button2.Text = "Deploy"  
$System_Drawing_Point = New-Object System.Drawing.Point 
$System_Drawing_Point.X = 230 
$System_Drawing_Point.Y = 378 
$button2.Location = $System_Drawing_Point 
$button2.DataBindings.DefaultDataSourceUpdateMode = 0 
$button2.add_Click($button2_OnClick) 
$button2.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $button2
$form1.Controls.Add($button2) 
 
$button1.TabIndex = 1 
$button1.Name = "button1" 
$System_Drawing_Size = New-Object System.Drawing.Size 
$System_Drawing_Size.Width = 75 
$System_Drawing_Size.Height = 23 
$button1.Size = $System_Drawing_Size 
$button1.UseVisualStyleBackColor = $True 
 
$button1.Text = "Refresh" 
 
$System_Drawing_Point = New-Object System.Drawing.Point 
$System_Drawing_Point.X = 13 
$System_Drawing_Point.Y = 379 
$button1.Location = $System_Drawing_Point 
$button1.DataBindings.DefaultDataSourceUpdateMode = 0 
$button1.add_Click($button1_OnClick) 
 
$form1.Controls.Add($button1) 
 
$System_Drawing_Size = New-Object System.Drawing.Size 
$System_Drawing_Size.Width = 592 
$System_Drawing_Size.Height = 308 
$dataGrid1.Size = $System_Drawing_Size 
$dataGrid1.DataBindings.DefaultDataSourceUpdateMode = 0 
$dataGrid1.HeaderForeColor = [System.Drawing.Color]::FromArgb(255,0,0,0) 
$dataGrid1.Name = "dataGrid1" 
$dataGrid1.DataMember = "" 
$dataGrid1.TabIndex = 0 
$System_Drawing_Point = New-Object System.Drawing.Point 
$System_Drawing_Point.X = 13 
$System_Drawing_Point.Y = 48 
$dataGrid1.Location = $System_Drawing_Point 
 
$form1.Controls.Add($dataGrid1) 
 
#endregion Generated Form Code 
 
#Save the initial state of the form 
$InitialFormWindowState = $form1.WindowState 
 
#Add Form event 
$form1.add_Load($OnLoadForm_UpdateGrid) 
 
#Show the Form 
$form1.ShowDialog()| Out-Null 
 
} #End Function 

function GUI()
{
   [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
   [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
    
    # Set the size of your form
    $Form = New-Object System.Windows.Forms.Form
    $Form.width = 1000
    $Form.height = 600
    $Form.Text = ”SSIS Environment Deployer”
 
    # Set the font of the text to be used within the form
    $Font = New-Object System.Drawing.Font("Times New Roman",12)
    $Form.Font = $Font
 
    $SourceDropDown = new-object System.Windows.Forms.ComboBox
    $SourceDropDown.Location = new-object System.Drawing.Size(130,20)
    $SourceDropDown.Size = new-object System.Drawing.Size(280,40)
    $SourceDropDown.Text ="Select Source"

 
    $DesitinationDropDown = new-object System.Windows.Forms.ComboBox
    $DesitinationDropDown.Location = new-object System.Drawing.Size(130,60)
    $DesitinationDropDown.Size = new-object System.Drawing.Size(280,40)
    $DesitinationDropDown.Text ="Select Destination"

    $FolderDropdown = New-Object System.Windows.Forms.ComboBox
    $FolderDropdown.Location = new-object System.Drawing.Size(130,100)
    $FolderDropdown.Size = new-object System.Drawing.Size(280,40)
    $FolderDropdown.Text ="Select Folder"


    $ProjectDropdown = New-Object System.Windows.Forms.ComboBox
    $ProjectDropdown.Location = new-object System.Drawing.Size(130,140)
    $ProjectDropdown.Size = new-object System.Drawing.Size(280,40)
    $ProjectDropdown.Text ="Select Project"

    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Point(75,180)
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Text = 'Deploy'
    $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $OKButton
    $form.Controls.Add($OKButton)
    
    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Point(150,180)
    $CancelButton.Size = New-Object System.Drawing.Size(75,23)
    $CancelButton.Text = 'Cancel'
    $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $CancelButton
    $form.Controls.Add($CancelButton)   


    $Label = New-Object System.Windows.Forms.Label
    $Label.Location = New-Object System.Drawing.Point(150,200)
    $Label.Text = "Deployment Completed."


    $dataGrid1 =new-object System.Windows.Forms.DataGrid
$dataGrid1.Location = New-Object System.Drawing.Point(200,180)
$dataGrid1.DataBindings.DefaultDataSourceUpdateMode = 0 
$dataGrid1.HeaderForeColor = [System.Drawing.Color]::FromArgb(255,0,0,0) 
$dataGrid1.Name = "dataGrid1" 
$dataGrid1.DataMember = "" 
$dataGrid1.TabIndex = 0 

   
    ForEach ($Server in $SsisServer) {
        [void] $SourceDropDown.Items.Add($Server)
                }
 
    $Form.Controls.Add($SourceDropDown)

    $SourceDropDown.Add_SelectedIndexChanged({populate_projects $SourceDropDown.SelectedItem})  
   
    $ProjectDropdown.Add_SelectedIndexChanged({populateenvironment $SourceDropDown.SelectedItem $FolderDropdown.SelectedItem $DesitinationDropDown.SelectedItem $ProjectDropdown.SelectedItem})     
    
    
 
    $Form.Add_Shown({$Form.Activate()})
    
    $result = $Form.ShowDialog()

     if ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
       

        $Powerobj = [SSISPackageMover]::New()
        $Powerobj.Source = $SourceDropDown.SelectedItem
        $Powerobj.Destination=$DesitinationDropDown.SelectedItem
        $Powerobj.Name=$ProjectDropdown.SelectedItem
        $Powerobj.FolderName=$FolderDropdown.SelectedItem

        #DownloadProdPackage($SsisServer,$FolderName,$ProjectName,$DownloadFolder(Mandatory),$CreateSubfolders(Mandatory),$UnzipIspac(Mandatory))

         if($Powerobj.Source.ToString() -ne "" -and $Powerobj.Name.ToString() -ne "" -and $Powerobj.Destination.ToString()-ne "" ){
        
         DownloadProdPackage $Powerobj.Source.ToString() "CGX" $Powerobj.Name.ToString() $DownloadFolder $true $false
        
         $File=$DownloadFolder+$Powerobj.FolderName.ToString()+"\"+$Powerobj.Name.ToString()+".ispac"
        
        write-host "Download completed"
        
        #DeployProdPackage($TargetServerName,$ProjectName,$ProjectFilePath)
        
         DeployProdPackage  $Powerobj.Destination.ToString()  $Powerobj.Name.ToString()  $File
        
         
        #Deletion process -Delete all ispac created for the run
        
        Write-Host "`nDeletion process - Started`n"-ForegroundColor Yellow
        
        Remove-Item $File
        
        Write-Host "Deletion process - Completed"-ForegroundColor Yellow

        $Form.Controls.Add($Label)

 }


    }
 

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

      ForEach ($Server in $SsisServer)         
        {
        [void] $DesitinationDropDown.Items.Add($Server)
        }
        
     $Form.Controls.Add($DesitinationDropDown)

    }

 function populateenvironment($SelectedSsisServer,$SelectedFolder,$SelecteddestinationServer,$ProjectDropdownvalue)
 { 
#$form1.Controls.Add($dataGrid1) 
GenerateForm $SelectedSsisServer $SelectedFolder $SelecteddestinationServer $ProjectDropdownvalue
 }

