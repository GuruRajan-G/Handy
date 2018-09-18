cls

# declaration not necessary, but good practice
[string] $Server= "Specify sql server"
[string] $Database = "Specify SQL Database"
[string] $UserSqlQuery= $("Select Getdate()")



# executes a query and populates the $datatable with the data
function ExecuteSqlQuery ($Server, $Database, $SQLQuery) {
    $Datatable = New-Object System.Data.DataTable
    
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = "server='$Server';database='$Database';trusted_connection=true;"
    $Connection.Open()
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $Command.CommandText = $SQLQuery
    $Reader = $Command.ExecuteReader()
    $Datatable.Load($Reader)
    $Connection.Close()
    
    return $Datatable
}


function GenericSqlQuery ($Server, $Database, $SQLQuery) {
    $Datatable = New-Object System.Data.DataTable
    
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = "server='$Server';database='$Database';trusted_connection=true;"
    $Connection.Open()
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $Command.CommandText = $SQLQuery

    $DataAdapter = new-object System.Data.SqlClient.SqlDataAdapter $Command
    $Dataset = new-object System.Data.Dataset
    $DataAdapter.Fill($Dataset)
    $Connection.Close()
    
    return $Dataset.Tables[0]
}

try{

$resultsDataTable = New-Object System.Data.DataTable
$resultsDataTable = ExecuteSqlQuery $Server $Database $UserSqlQuery 
$resultsDataTable 
#validate we got data
Write-Host ("The table contains: " + $resultsDataTable.Rows.Count + " rows")
}
catch
{$ErrorMessage = $_.Exception.Message
Write-Host $ErrorMessage
}
