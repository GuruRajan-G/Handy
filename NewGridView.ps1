cls
Add-Type -AssemblyName "System.Drawing"
Add-Type -AssemblyName "System.Windows.Forms" 

$formRDP = New-Object System.Windows.Forms.Form
$labelLoading = New-Object System.Windows.Forms.Label
$dgvServers = New-Object System.Windows.Forms.DataGridView 



# formRDP
$formRDP.Name = "formRDP"
$formRDP.Text = "RDP servers"
$formRDP.ClientSize = '454, 330'

$formRDP.Controls.Add($dgvServers)
$formRDP.Controls.Add($labelLoading)

# labelLoading
$labelLoading.Name = "labelLoading"
$labelLoading.Text = "Loading..."
$labelLoading.Location = '26, 26'
$labelLoading.Size = '100, 23'
$labelLoading.Font = "Microsoft Sans Serif, 12pt, style=Bold" 


$dgvServers.Location = '13, 13'
 
    
   
   

# dgvServers
$dgvServers.Name = "dgvServers"
$dgvServers.Location = '13, 13'
$dgvServers.Size = '429, 800'


$dgvServers.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

$dgvServers.AllowUserToAddRows = $False
$dgvServers.AllowUserToDeleteRows = $False 
$dgvServers.ReadOnly = $True 

#$dgvServers.Dock = [System.Windows.Forms.DockStyle]::Fill
 $dgvServers.ColumnHeadersHeightSizeMode = [System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode]::AutoSize
 	
 # Enable wrap mode on the cells and make the grid autosize the rows when the columns wrap
 $dgvServers.defaultCellStyle.wrapMode= [System.Windows.Forms.DataGridViewTriState]::True
 $dgvServers.AutoSizeRowsMode = [System.Windows.Forms.DataGridViewAutoSizeRowsMode]::AllCells
 	
 $dgvServers.SelectionMode = 'FullRowSelect'
 $dgvServers.Visible = $False



# RDP form OnShown event handler
$formRDP_Shown = 
{
$formRDP.ClientSize = '900, 900'

$formRDP.Refresh()

$SearchQuery="SELECT * FROM dbo.Package"

Write-Host $SearchQuery

$Search_Result=Invoke-Sqlcmd -Query $SearchQuery -ErrorAction Stop -ServerInstance "(LocalDB)\V11.0" -Database "tempdb"  -QueryTimeout 0

$Script:ServerData = $Search_Result | Select PackageName,TaskName,DFTTaskValue,EsqlTQuery | sort -Property PackageName 



$Script:ServerGridData = New-Object System.Collections.ArrayList
$Script:ServerGridData.AddRange( $Script:ServerData )
$dgvServers.DataSource = $Script:ServerGridData


$dgvServers.Visible = $True
$dgvServers.AutoResizeColumns( "AllCells" )

$OKButton.Location = '550, 850'
$OKButton.Size = New-Object System.Drawing.Size(75, 23)    
    $OKButton.Text = 'Deploy'
    $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $formRDP.AcceptButton = $OKButton
    $formRDP.Controls.Add($OKButton)


}

# Add event handlers to form
$formRDP.add_Shown( $formRDP_Shown )


# Show the Form
$formRDP.ShowDialog() | Out-Null
