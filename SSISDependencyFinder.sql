/********
1) Return information about packages stored on your hard drive
2) Returna  list of GUIDs that are duplicated throughout your packages

Jamie Thomson
2009-11-06

See notes at bottom for more info
********/
sp_configure 'show advanced options', 1;
reconfigure;
GO
sp_configure 'xp_cmdshell', 1;
reconfigure;
GO

USE [tempdb]
GO

IF EXISTS(SELECT 1
          FROM   sys.objects
          WHERE  name = 'Package')
  DROP TABLE dbo.Package

GO

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

GO

DECLARE	@Path	VARCHAR(2000); 
SET @Path = 'U:\Clinical IT Development\branches\Cgx\Clinical DM\V1.1809\SSIS Packages\CDM_PRJ_Auth_Rearch\*.dtsx'; --Must be of form [drive letter]\...\*.dtsx

DECLARE @id NVARCHAR(MAX)
SELECT @id = 'Auth_Line_Date'

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

--INSERT INTO   #T3 (PackageName,PackagePath,TaskXML,TaskName,TaskType,DFTTaskValue,EsqlTQuery)
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
 INSERT INTO Package (PackageName,PackagePath,TaskXML,TaskName,TaskType,DFTTaskValue,EsqlTQuery)

 SELECT * FROM #T2 WHERE EsqlTQuery is null and   DFTTaskValue IS NOT  NULL and TaskType!='Microsoft.SqlServer.Dts.Tasks.ExecuteSQLTask.ExecuteSQLTask, Microsoft.SqlServer.SQLTask, Version=11.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91'
 UNION ALL
 SELECT * FROM #T3
 
   -- ty WHERE  ty.EsqlTQuery is null
 --WHERE DFTTaskValue LIKE '%'+@id+'%'
 --OR EsqlTQuery LIKE '%'+@id+'%'


 SELECT * FROM Package WHERE DFTTaskValue LIKE '%Auth_Line_Multi_Details%' OR EsqlTQuery LIKE '%Auth_Line_Multi_Details%'


 /**************vALIDATEION**********************************************************************************************

 SELECT B.*  FROM #T2 a
 inner join  #T3 b on a.PackageName=b.PackageName
 and a.TaskName=b.TaskName
 and a.TaskType=b.TaskType

 ;WITH XMLNAMESPACES('www.microsoft.com/SqlServer/Dts' AS p1,
                    'www.microsoft.com/sqlserver/dts/tasks/sqltask' AS p2 )
 SELECT  CAST(NULL AS nvarchar(MAX)) AS DFTTaskValue,Props.Prop.value('./@p2:SqlStatementSource', 'nvarchar(max)')  AS EsqlTQuery
 FROM #T2 ty
 CROSS APPLY  ty.TaskXML.nodes('/p1:Executable/p1:ObjectData/p2:SqlTaskData') Props(Prop)
 WHERE  EsqlTQuery is null and   DFTTaskValue IS NOT  NULL and
 TaskType='Microsoft.SqlServer.Dts.Tasks.ExecuteSQLTask.ExecuteSQLTask, Microsoft.SqlServer.SQLTask, Version=11.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91'
 --and TaskName='ESQLT - Truncate Auth_Line_Multi_Details_stg table'
 ********************************************************************************************************************/

 
