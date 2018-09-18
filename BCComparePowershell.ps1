cls
$BATCH_FilePath = "\\SharedFolder\PowershellAutomation"


WRITE-HOST "`nGenerate BC Script - Started"

#region FOR DataReportLayout

Add-Content $BATCH_FilePath\BCDataReportScript.txt "data-report layout:interleaved options:line-numbers &
output-to:`"%3`" &
output-options:html-color `"%1`" `"%2`" "

#endregion


#region FOR textReportLayout

Add-Content $BATCH_FilePath\BCTextReportScript.txt "text-report layout:side-by-side options:line-numbers &
output-to:`"%3`" &
output-options:html-color `"%1`" `"%2`" "
WRITE-HOST "`nGenerate BC Script $BCScript - Completedd"

#endregion


$BCScript= "@"+$BATCH_FilePath+"\BCDataReportScript.txt"
$BCScript= "@"+$BATCH_FilePath+"\BCTextReportScript.txt"
$arg1 = $BCScript
$arg2 = "C:\SharedFolder\BEYOND COMPARE TESTING\B.txt"
$arg3 = "C:\SharedFolder\BEYOND COMPARE TESTING\A.txt"
$arg4 ="C:\SharedFolder\BEYOND COMPARE TESTING\Result.html" 

$allArgs = @($arg1, $arg2, $arg3,$arg4)
& "C:\Program Files (x86)\Beyond Compare 3\BComp.exe" $allArgs 
