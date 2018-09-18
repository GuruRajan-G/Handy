cls
$env:PSModulePath = $env:PSModulePath + ";C:\Program Files\Microsoft SQL Server\110\Tools\PowerShell\Modules"
$env:PSModulePath = $env:PSModulePath + ";C:\Program Files\WindowsPowerShell\Modules;"

Push-Location
Import-Module "sqlps" –DisableNameChecking
Pop-Location


$SourceServer   = "Sql Server Name"
$SourceDatabase = "Database Name"
$SourceUserID   = "Userid"
$SourcePass     = "Password" 



$DestinationServer = "Sql Server Name"
$DestinationDBName = "Database Name"
$DestinationUserID = "Userid"
$DestinationPass ="Password" 

$BATCH_FilePath = "\\DEV\DEvOps\New folder"
$TableName ="tablename"



$Query = "select * from dbo.tablename" 


##Extract the data from Source
bcp $Query queryout $BATCH_FilePath\$TableName.csv -b 10000 -t0x07 -r0x0a  -q -E -c -S $SourceServer -U $SourceUserID -P $SourcePass #-d $SourceDatabase #-e $BATCH_FilePath\$DestinationTableName.error



##Load the data into Destination
bcp $DestinationDBName.DBO.tablename in $Batch_FilePath\$tableName.CSV -b 50000 -e  $Batch_FilePath\$tableName.error -c -t0x07 -r0x0a -q -S $DestinationServer -U $DestinationUserID -P $DestinationPass 
