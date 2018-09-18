sp_configure 'show advanced options', 1;
reconfigure;
GO
sp_configure 'xp_cmdshell', 1;
reconfigure;
GO

USE [tempdb]
GO


IF EXISTS (SELECT 1
           FROM   sys.objects
           WHERE  name = 'FK_Packages_PkgVariable')
  ALTER TABLE [dbo].[PkgVariable]
    DROP CONSTRAINT FK_Packages_PkgVariable

IF EXISTS (SELECT 1
           FROM   sys.objects
           WHERE  name = 'FK_Packages_PkgConfiguration')
  ALTER TABLE [dbo].[PkgConfiguration]
    DROP CONSTRAINT FK_Packages_PkgConfiguration

IF EXISTS (SELECT 1
           FROM   sys.objects
           WHERE  name = 'FK_Packages_PkgConnectionManager')
  ALTER TABLE [dbo].[PkgConnectionManager]
    DROP CONSTRAINT FK_Packages_PkgConnectionManager

IF EXISTS (SELECT 1
           FROM   sys.objects
           WHERE  name = 'FK_Packages_PkgLogProvider')
  ALTER TABLE [dbo].[PkgLogProvider]
    DROP CONSTRAINT FK_Packages_PkgLogProvider

IF EXISTS (SELECT 1
           FROM   sys.objects
           WHERE  name = 'FK_Packages_PkgEventHandler')
  ALTER TABLE [dbo].[PkgEventHandler]
    DROP CONSTRAINT FK_Packages_PkgEventHandler

IF EXISTS (SELECT 1
           FROM   sys.objects
           WHERE  name = 'FK_Packages_PkgTransformation')
  ALTER TABLE [dbo].[PkgTransformation]
    DROP CONSTRAINT FK_Packages_PkgTransformation

IF EXISTS (SELECT 1
           FROM   sys.objects
           WHERE  name = 'Pk_Package')
  ALTER TABLE dbo.Package
    DROP CONSTRAINT Pk_Package

IF EXISTS(SELECT 1
          FROM   sys.objects
          WHERE  name = 'Package')
  DROP TABLE dbo.Package

IF EXISTS(SELECT 1
          FROM   sys.objects
          WHERE  name = 'PkgConnectionManager')
  DROP TABLE dbo.PkgConnectionManager

IF EXISTS(SELECT 1
          FROM   sys.objects
          WHERE  name = 'PkgVariable')
  DROP TABLE dbo.PkgVariable

IF EXISTS(SELECT 1
          FROM   sys.objects
          WHERE  name = 'PkgConfiguration')
  DROP TABLE dbo.PkgConfiguration

IF EXISTS(SELECT 1
          FROM   sys.objects
          WHERE  name = 'PkgLogProvider')
  DROP TABLE dbo.PkgLogProvider

IF EXISTS(SELECT 1
          FROM   sys.objects
          WHERE  name = 'PkgEventHandler')
  DROP TABLE dbo.PkgEventHandler

GO

IF EXISTS(SELECT 1
          FROM   sys.objects
          WHERE  name = 'PkgTransformation')
  DROP TABLE dbo.PkgTransformation

GO

CREATE TABLE dbo.Package
  (
     PkgID                    INT IDENTITY(1, 1),
     PackageName              VARCHAR(1000),
     PackagePath              VARCHAR(1000),
     PackageFormatVersion     VARCHAR(1000),
     CreatorName              VARCHAR(1000),
     CreationDate             VARCHAR(1000),
     VersionMajor             INT,
     VersionMinore            INT,
     CreatorComputerName      VARCHAR(1000),
     ProtectionLevel          VARCHAR(1000),
     EnableConfig             INT,
     MaxConcurrentExecutables INT,
     LoadDateTime             DATETIME DEFAULT Getdate(),
     CONSTRAINT [Pk_Package] PRIMARY KEY CLUSTERED (PkgID)
  )

GO

CREATE TABLE dbo.PkgConnectionManager
  (
     ID                    INT IDENTITY(1, 1),
     ConnectionManagerName VARCHAR(1000),
	ConnectionManagerValue VARCHAR(1000),
     DelayValidation       INT,
     DTSID                 UNIQUEIDENTIFIER,
     DESCRIPTION           VARCHAR(1000),
     ConnectionType        VARCHAR(1000),
     PkgID                 INT
  )

GO

CREATE TABLE dbo.PkgVariable
  (
     ID                   INT IDENTITY(1, 1),
     VariableName         VARCHAR(1000),
     Expression           VARCHAR(MAX),
     EvaluateAsExpression INT,
     Namespace            VARCHAR(1000),
     ReadOnly             INT,
     RaiseChangedEvent    INT,
     IncludeInDebugDump   INT,
     DTSID                UNIQUEIDENTIFIER,
     DESCRIPTION          VARCHAR(1000),
     CreationName         VARCHAR(1000),
     PkgID                INT
  )

GO

CREATE TABLE Dbo.PkgConfiguration
  (
     ID                    INT IDENTITY(1, 1),
     ConfigurationName     VARCHAR(1000),
     ConfigurationType     VARCHAR(1000),
     ConfigurationString   VARCHAR(1000),
     ConfigurationVariable VARCHAR(1000),
     DTSID                 UNIQUEIDENTIFIER,
     DESCRIPTION           VARCHAR(1000),
     CreationName          VARCHAR(1000),
     PkgID                 INT
  )

GO

CREATE TABLE dbo.PkgLogProvider
  (
     ID              INT IDENTITY(1, 1),
     LogProviderName VARCHAR(1000),
     ConfigString    VARCHAR(1000),
     DelayValidation VARCHAR(1000),
     DTSID           UNIQUEIDENTIFIER,
     DESCRIPTION     VARCHAR(1000),
     CreationName    VARCHAR(1000),
     PkgID           INT
  )

GO

CREATE TABLE dbo.PkgEventHandler
  (
     ID                   INT IDENTITY(1, 1),
     EventName            VARCHAR(1000),
     ForceExecValue       VARCHAR(1000),
     ExecValue            VARCHAR(1000),
     ForceExecutionResult VARCHAR(1000),
     Disabled             VARCHAR(1000),
     FailPackageOnFailure VARCHAR(1000),
     FailParentOnFailure  VARCHAR(1000),
     MaxErrorCount        INT,
     ISOLevel             VARCHAR(1000),
     LocaleID             INT,
     TransactionOption    INT,
     DelayValidation      INT,
     DTSID                UNIQUEIDENTIFIER,
     DESCRIPTION          VARCHAR(1000),
     CreationName         VARCHAR(1000),
     PkgID                INT
  )

CREATE TABLE dbo.PkgTransformation
  (
     ID       INT IDENTITY(1, 1),
     TaskName VARCHAR(1000),
     TaskType nVARCHAR(max),
     PkgID    INT
  )

ALTER TABLE dbo.PkgVariable
  WITH NOCHECK ADD CONSTRAINT [FK_Packages_PkgVariable] FOREIGN KEY(PkgID) REFERENCES [dbo].[Package] (PkgID)

ALTER TABLE dbo.PkgConfiguration
  WITH NOCHECK ADD CONSTRAINT [FK_Packages_PkgConfiguration] FOREIGN KEY(PkgID) REFERENCES [dbo].[Package] (PkgID)

ALTER TABLE dbo.PkgConnectionManager
  WITH NOCHECK ADD CONSTRAINT [FK_Packages_PkgConnectionManager] FOREIGN KEY(PkgID) REFERENCES [dbo].[Package] (PkgID)

ALTER TABLE dbo.PkgLogProvider
  WITH NOCHECK ADD CONSTRAINT [FK_Packages_PkgLogProvider] FOREIGN KEY(PkgID) REFERENCES [dbo].[Package] (PkgID)

ALTER TABLE dbo.PkgEventHandler
  WITH NOCHECK ADD CONSTRAINT [FK_Packages_PkgEventHandler] FOREIGN KEY(PkgID) REFERENCES [dbo].[Package] (PkgID)

ALTER TABLE dbo.PkgTransformation
  WITH NOCHECK ADD CONSTRAINT [FK_Packages_PkgTransformation] FOREIGN KEY(PkgID) REFERENCES [dbo].[Package] (PkgID)

ALTER TABLE dbo.PkgVariable
  CHECK CONSTRAINT [FK_Packages_PkgVariable]

ALTER TABLE dbo.PkgConfiguration
  CHECK CONSTRAINT [FK_Packages_PkgConfiguration]

ALTER TABLE dbo.PkgConnectionManager
  CHECK CONSTRAINT [FK_Packages_PkgConnectionManager]

ALTER TABLE dbo.PkgLogProvider
  CHECK CONSTRAINT[FK_Packages_PkgLogProvider]

ALTER TABLE dbo.PkgEventHandler
  CHECK CONSTRAINT[FK_Packages_PkgEventHandler]

ALTER TABLE dbo.PkgTransformation
  CHECK CONSTRAINT[FK_Packages_PkgTransformation] 

-----------------------------------------------------------------------------------------------------------------------------------------------------

GO

DECLARE	@Path	VARCHAR(2000); 
SET @Path = 'U:\SSIS Packages\ProjectName\*.dtsx'; --Must be of form [drive letter]\...\*.dtsx

DECLARE @idSTRING VARCHAR(10)
SELECT @idSTRING = 'usp_UpdtAddGrps_SSIS_CheckThresholds'


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
OR		FullPath = 'The system cannot find the file specified.'; 

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





--======================================
--INSERT RECORD IN ALL THE TABLES
--======================================
--Insert into dbo.package
DECLARE @pkgID INT

INSERT INTO dbo.package
            (PackageName,
             PackagePath,
             PackageFormatVersion,
             CreatorName,
             CreationDate,
             VersionMajor,
             VersionMinore,
             CreatorComputerName,
             ProtectionLevel,
             EnableConfig)
/*Commented Code
--SELECT ObjectName AS PackageName,
--       @Path,
--       PackageFormatVersion,
--       CreatorName,
--       CreationDate,
--       VersionMajor,
--       VersionMinore,
--       CreatorComputerName,
--       ProtectionLevel,
--       EnableConfig
--FROM   (SELECT --Props.Prop.query('.') as PropXml
--       Props.Prop.value('declare namespace p1="www.microsoft.com/SqlServer/Dts";
--string(./@p1:Name)', 'nvarchar(max)')  AS PropName,
--       Props.Prop.value('.', 'nvarchar(max)') AS PropValue
--        FROM   (SELECT PackageXML AS pkgXML
--                FROM   pkgStats) t
--               CROSS APPLY pkgXML.nodes('declare namespace DTS="www.microsoft.com/SqlServer/Dts";
--/DTS:Executable/DTS:Property') Props(Prop)) D
--       PIVOT (Min(propValue)
--             FOR PropName IN (ObjectName,
--                              PackageFormatVersion,
--                              CreatorName,
--                              CreationDate,
--                              VersionMajor,
--                              VersionMinore,
--                              CreatorComputerName,
--                              ProtectionLevel,
--                              EnableConfig) ) AS PV
*********************************************************************/
SELECT distinct Props.Prop.value('declare namespace p1="www.microsoft.com/SqlServer/Dts";string(./@p1:ObjectName)', 'nvarchar(max)')  AS PackageName,
			 @Path,
			 Props.Prop.value('declare namespace p1="www.microsoft.com/SqlServer/Dts";string(./@p1:PackageFormatVersion)', 'nvarchar(max)')  AS PackageFormatVersion,
			 Props.Prop.value('declare namespace p1="www.microsoft.com/SqlServer/Dts";string(./@p1:CreatorName)', 'nvarchar(max)')  AS CreatorName,
			 Props.Prop.value('declare namespace p1="www.microsoft.com/SqlServer/Dts";string(./@p1:CreationDate)', 'nvarchar(max)')  AS CreationDate,
			 Props.Prop.value('declare namespace p1="www.microsoft.com/SqlServer/Dts";string(./@p1:VersionMajor)', 'nvarchar(max)')  AS VersionMajor,
			 Props.Prop.value('declare namespace p1="www.microsoft.com/SqlServer/Dts";string(./@p1:VersionMinore)', 'nvarchar(max)')  AS VersionMinore,
			 Props.Prop.value('declare namespace p1="www.microsoft.com/SqlServer/Dts";string(./@p1:CreatorComputerName)', 'nvarchar(max)')  AS CreatorComputerName,
			 Props.Prop.value('declare namespace p1="www.microsoft.com/SqlServer/Dts";string(./@p1:ProtectionLevel)', 'nvarchar(max)')  AS ProtectionLevel,
			 Props.Prop.value('declare namespace p1="www.microsoft.com/SqlServer/Dts";string(./@p1:EnableConfig)', 'nvarchar(max)')  AS EnableConfig	 

			   FROM   (SELECT PackageXML AS pkgXML
                FROM   pkgStats) t
               CROSS APPLY pkgXML.nodes('declare namespace DTS="www.microsoft.com/SqlServer/Dts";
/DTS:Executable') Props(Prop)

SET @PkgID=Scope_identity()

--print @pkgID
-----------------------------------------------------------------------------------------------------
--Connection Managers
IF Object_id('tempdb..#T') IS NOT NULL
  BEGIN
      DROP TABLE #T
  END

IF Object_id('tempdb..#TG') IS NOT NULL
  BEGIN
      DROP TABLE #TG
  END

/* Commented Olde piece code
SELECT Props.Prop.value('declare namespace p1="www.microsoft.com/SqlServer/Dts";
./@p1:ObjectName', 'nvarchar(max)')  AS PropName,
--string(./@p1:ObjectName)', 'nvarchar(max)')  AS PropName,
       Props.Prop.value('.', 'nvarchar(max)') AS PropValue
INTO   #T
FROM   (SELECT PackageXML AS pkgXML
        FROM   pkgStats) t
       CROSS APPLY pkgXML.nodes('declare namespace DTS="www.microsoft.com/SqlServer/Dts";
/DTS:Executable/DTS:ConnectionManagers/DTS:ConnectionManager') Props(Prop)
*/

SELECT distinct Props.Prop.value('declare namespace p1="www.microsoft.com/SqlServer/Dts";string(./@p1:ObjectName)', 'nvarchar(max)')  AS ObjectName,
			 Props.Prop.value('declare namespace p1="www.microsoft.com/SqlServer/Dts";string(./@p1:DelayValidation)', 'nvarchar(max)')  AS DelayValidation,
			 Props.Prop.value('declare namespace p1="www.microsoft.com/SqlServer/Dts";string(./@p1:DTSID)', 'nvarchar(max)')  AS DTSID,
			 Props.Prop.value('declare namespace p1="www.microsoft.com/SqlServer/Dts";string(./@p1:Description)', 'nvarchar(max)')  AS Description,
			 Props.Prop.value('declare namespace p1="www.microsoft.com/SqlServer/Dts";string(./@p1:CreationName)', 'nvarchar(max)')  AS CreationName,
			 Props.Prop.value('.', 'nvarchar(max)') AS PropValue
	  INTO   #T
FROM   (SELECT PackageXML AS pkgXML
        FROM   pkgStats) t
       CROSS APPLY pkgXML.nodes('declare namespace DTS="www.microsoft.com/SqlServer/Dts";
/DTS:Executable/DTS:ConnectionManagers/DTS:ConnectionManager') Props(Prop)

DECLARE @propName VARCHAR(300)
DECLARE @propValue VARCHAR(300)
DECLARE @id INT=0
DECLARE @cnt INT=0

/*  Commented Code/
CREATE TABLE #TG
  (
     ObjectName VARCHAR(300),
	DelayValidation VARCHAR(300),
	DTSID VARCHAR(300),
	Description VARCHAR(300),
	CreationName VARCHAR(300),
	propValue VARCHAR(300),
     id        INT
  )
DECLARE @propName VARCHAR(300)
DECLARE @ObjectName VARCHAR(300)
DECLARE @DelayValidation VARCHAR(300)
DECLARE @DTSID VARCHAR(300)
DECLARE @Description VARCHAR(300)
DECLARE @CreationName VARCHAR(300)
DECLARE @propValue VARCHAR(300)
DECLARE db_cursor CURSOR FOR
  SELECT ObjectName,
         DelayValidation,
	    DTSID,
	    Description,
	    CreationName,
	    PropValue
  FROM   #T
DECLARE @id INT=0
DECLARE @cnt INT=0

OPEN db_cursor

FETCH NEXT FROM db_cursor INTO @ObjectName,@DelayValidation,@DTSID, @Description,@CreationName,@propValue
WHILE @@FETCH_STATUS = 0		 
  BEGIN					
      INSERT INTO #TG		 
      VALUES     (@ObjectName,@DelayValidation,@DTSID, @Description,@CreationName,@propValue,@id)

      FETCH NEXT FROM db_cursor INTO @ObjectName,@DelayValidation,@DTSID, @Description,@CreationName,@propValue

      SET @cnt=@cnt + 1

      IF ( @cnt%5 = 0 )
        BEGIN
            SET @id=@id + 1
        END
  END

  INSERT INTO dbo.PkgConnectionManager
SELECT ObjectName,
       DelayValidation,
       DTSID,
       Description,
       CreationName,
       @PkgID
FROM   (SELECT *
        FROM   #T)d
       --PIVOT (Min(propValue)
       --      FOR PropName IN (ObjectName,
       --                       DelayValidation,
       --                       DTSID,
       --                       Description,
       --                       CreationName) ) AS PV

CLOSE db_cursor

DEALLOCATE db_cursor
/  Commented Code*/

INSERT INTO dbo.PkgConnectionManager
SELECT ObjectName,
	  PropValue,
       DelayValidation,
       DTSID,
       Description,
       CreationName,
       @PkgID
FROM   (SELECT *
        FROM   #T)d
     



-----------------------------------------------------------------------------
--Insert Tasks Information
INSERT INTO dbo.PkgTransformation
SELECT TaskName,
       TaskType,
       @pkgID
FROM   (SELECT Pkg.props.value('declare namespace p1="www.microsoft.com/SqlServer/Dts";
                             ./@p1:ObjectName', 'nvarchar(max)') AS TaskName,
               --Pkg.props.value('declare namespace p1="www.microsoft.com/SqlServer/Dts";
               --             ./@p1:ExecutableType', 'nvarchar(max)')                      AS TaskType
					   Pkg.Props.value('.', 'nvarchar(max)') AS TaskType
        FROM   (SELECT PackageXML AS pkgXML
                FROM   pkgStats) t
               CROSS APPLY pkgXML.nodes('declare namespace DTS="www.microsoft.com/SqlServer/Dts";
                            //DTS:Executable[@DTS:ExecutableType!=''STOCK:SEQUENCE''
                        and    @DTS:ExecutableType!=''STOCK:FORLOOP''
                        and    @DTS:ExecutableType!=''STOCK:FOREACHLOOP''
                        and not(contains(@DTS:ExecutableType,''.Package.''))]') Pkg(props)) D
		     --INNER JOIN DBO.Package PKG WITH(NOLOCK) ON PKG.PackageName=

------------------------------------------------------------------------------------------------
--Insert into dbo.PkgVariable
IF Object_id('tempdb..#T1') IS NOT NULL
  BEGIN
      DROP TABLE #T1
  END

IF Object_id('tempdb..#TG1') IS NOT NULL
  BEGIN
      DROP TABLE #TG1
  END

SELECT Props.Prop.value('declare namespace p1="www.microsoft.com/SqlServer/Dts";
string(./@p1:Name)', 'nvarchar(max)')  AS PropName,
       Props.Prop.value('.', 'nvarchar(max)') AS PropValue
INTO   #T1
FROM   (SELECT PackageXML AS pkgXML
        FROM   pkgStats) t
       CROSS APPLY pkgXML.nodes('declare namespace DTS="www.microsoft.com/SqlServer/Dts";
/DTS:Executable/DTS:Variable/DTS:Property') Props(Prop)

CREATE TABLE #TG1
  (
     PropName  NVARCHAR(MAX),
     propValue NVARCHAR(MAX),
     id        INT
  )

DECLARE db_cursor CURSOR FOR
  SELECT PropName,
         PropValue
  FROM   #T1

SET @id =0
SET @cnt=0

OPEN db_cursor

FETCH NEXT FROM db_cursor INTO @propName, @propValue

WHILE @@FETCH_STATUS = 0
  BEGIN
      INSERT INTO #TG1
      VALUES     (@propName,
                  @propValue,
                  @id)

      FETCH NEXT FROM db_cursor INTO @propName, @propValue

      SET @cnt=@cnt + 1

      IF ( @cnt%10 = 0 )
        BEGIN
            SET @id=@id + 1
        END
  END

INSERT INTO dbo.PkgVariable
SELECT ObjectName,
       Expression,
       EvaluateAsExpression,
       Namespace,
       ReadOnly,
       RaiseChangedEvent,
       IncludeInDebugDump,
       DTSID,
       Description,
       CreationName,
       @pkgID
FROM   (SELECT *
        FROM   #TG1)d
       PIVOT (Min(propValue)
             FOR PropName IN (Expression,
                              EvaluateAsExpression,
                              Namespace,
                              ReadOnly,
                              RaiseChangedEvent,
                              IncludeInDebugDump,
                              ObjectName,
                              DTSID,
                              Description,
                              CreationName) ) AS PV

--SELECT * From ##TP
CLOSE db_cursor

DEALLOCATE db_cursor

---------------------------------------------------------------------------------------------
--Insert configuration
IF Object_id('tempdb..#TC') IS NOT NULL
  BEGIN
      DROP TABLE #TC
  END

IF Object_id('tempdb..#TCG') IS NOT NULL
  BEGIN
      DROP TABLE #TCG
  END

SELECT Props.Prop.value('declare namespace p1="www.microsoft.com/SqlServer/Dts";
string(./@p1:Name)', 'nvarchar(max)')  AS PropName,
       Props.Prop.value('.', 'nvarchar(max)') AS PropValue
INTO   #TC
FROM   (SELECT PackageXML AS pkgXML
        FROM   pkgStats) t
       CROSS APPLY pkgXML.nodes('declare namespace DTS="www.microsoft.com/SqlServer/Dts";
/DTS:Executable/DTS:Configuration/DTS:Property') Props(Prop)

CREATE TABLE #TCG
  (
     PropName  NVARCHAR(MAX),
     propValue NVARCHAR(MAX),
     id        INT
  )

DECLARE db_cursor CURSOR FOR
  SELECT PropName,
         PropValue
  FROM   #TC

SET @id =0
SET @cnt=0

OPEN db_cursor

FETCH NEXT FROM db_cursor INTO @propName, @propValue

WHILE @@FETCH_STATUS = 0
  BEGIN
      INSERT INTO #TCG
      VALUES     (@propName,
                  @propValue,
                  @id)

      FETCH NEXT FROM db_cursor INTO @propName, @propValue

      SET @cnt=@cnt + 1

      IF ( @cnt%7 = 0 )
        BEGIN
            SET @id=@id + 1
        END
  END

INSERT INTO dbo.PkgConfiguration
SELECT ObjectName,
       ConfigurationType,
       ConfigurationString,
       ConfigurationVariable,
       DTSID,
       Description,
       CreationName,
       @pkgID
FROM   (SELECT *
        FROM   #TCG)d
       PIVOT (Min(propValue)
             FOR PropName IN (ConfigurationType,
                              ConfigurationString,
                              ConfigurationVariable,
                              ObjectName,
                              DTSID,
                              Description,
                              CreationName) ) AS PV

CLOSE db_cursor

DEALLOCATE db_cursor

--------------------------------------------------------------------------------------------------------------------------
--Insert EventHandler
IF Object_id('tempdb..#TE') IS NOT NULL
  BEGIN
      DROP TABLE #TE
  END

IF Object_id('tempdb..#TEG') IS NOT NULL
  BEGIN
      DROP TABLE #TEG
  END

SELECT Props.Prop.value('declare namespace p1="www.microsoft.com/SqlServer/Dts";
string(./@p1:Name)', 'nvarchar(max)')  AS PropName,
       Props.Prop.value('.', 'nvarchar(max)') AS PropValue
INTO   #TE
FROM   (SELECT PackageXML AS pkgXML
        FROM   pkgStats) t
       CROSS APPLY pkgXML.nodes('declare namespace DTS="www.microsoft.com/SqlServer/Dts";
/DTS:Executable/DTS:EventHandler/DTS:Property') Props(Prop)

CREATE TABLE #TEG
  (
     PropName  NVARCHAR(MAX),
     propValue NVARCHAR(MAX),
     id        INT
  )

DECLARE db_cursor CURSOR FOR
  SELECT PropName,
         PropValue
  FROM   #TE

SET @id =0
SET @cnt =0

OPEN db_cursor

FETCH NEXT FROM db_cursor INTO @propName, @propValue

WHILE @@FETCH_STATUS = 0
  BEGIN
      INSERT INTO #TEG
      VALUES     (@propName,
                  @propValue,
                  @id)

      FETCH NEXT FROM db_cursor INTO @propName, @propValue

      SET @cnt=@cnt + 1

      IF ( @cnt%16 = 0 )
        BEGIN
            SET @id=@id + 1
        END
  END

INSERT INTO dbo.PkgEventHandler
SELECT EventName,
       ForceExecValue,
       ExecValue,
       ForceExecutionResult,
       Disabled,
       FailPackageOnFailure,
       FailParentOnFailure,
       MaxErrorCount,
       ISOLevel,
       LocaleID,
       TransactionOption,
       DelayValidation,
       DTSID,
       Description,
       CreationName,
       @pkgID
FROM   (SELECT *
        FROM   #TEG)d
       PIVOT (Min(propValue)
             FOR PropName IN (EventName,
                              ForceExecValue,
                              ExecValue,
                              ForceExecutionResult,
                              Disabled,
                              FailPackageOnFailure,
                              FailParentOnFailure,
                              MaxErrorCount,
                              ISOLevel,
                              LocaleID,
                              TransactionOption,
                              DelayValidation,
                              DTSID,
                              Description,
                              CreationName) ) AS PV

CLOSE db_cursor

DEALLOCATE db_cursor

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Insert LogProvid
IF Object_id('tempdb..#TL') IS NOT NULL
  BEGIN
      DROP TABLE #TL
  END

IF Object_id('tempdb..#TLG') IS NOT NULL
  BEGIN
      DROP TABLE #TLG
  END

SELECT Props.Prop.value('declare namespace p1="www.microsoft.com/SqlServer/Dts";
string(./@p1:Name)', 'nvarchar(max)')  AS PropName,
       Props.Prop.value('.', 'nvarchar(max)') AS PropValue
INTO   #TL
FROM   (SELECT PackageXML AS pkgXML
        FROM   pkgStats) t
       CROSS APPLY pkgXML.nodes('declare namespace DTS="www.microsoft.com/SqlServer/Dts";
/DTS:Executable/DTS:LogProvider/DTS:Property') Props(Prop)

CREATE TABLE #TLG
  (
     PropName  NVARCHAR(MAX),
     propValue NVARCHAR(MAX),
     id        INT
  )

DECLARE db_cursor CURSOR FOR
  SELECT PropName,
         PropValue
  FROM   #TL

SET @id =0
SET @cnt =0

OPEN db_cursor

FETCH NEXT FROM db_cursor INTO @propName, @propValue

WHILE @@FETCH_STATUS = 0
  BEGIN
      INSERT INTO #TLG
      VALUES     (@propName,
                  @propValue,
                  @id)

      FETCH NEXT FROM db_cursor INTO @propName, @propValue

      SET @cnt=@cnt + 1

      IF ( @cnt%6 = 0 )
        BEGIN
            SET @id=@id + 1
        END
  END

INSERT INTO dbo.PkgLogProvider
SELECT ObjectName,
       ConfigString,
       DelayValidation,
       DTSID,
       Description,
       CreationName,
       @pkgID
FROM   (SELECT *
        FROM   #TLG)d
       PIVOT (Min(propValue)
             FOR PropName IN (ConfigString,
                              DelayValidation,
                              ObjectName,
                              DTSID,
                              Description,
                              CreationName) ) AS PV

CLOSE db_cursor

DEALLOCATE db_cursor


--SELECT * FROM dbo.package
--SELECT * FROM dbo.PkgConnectionManager
--SELECT * FROM dbo.PkgTransformation
--SELECT * FROM dbo.pkgVariable
--SELECT * From dbo.PkgConfiguration
--SELECT * FROM dbo.PkgEventHandler
--SELECT * FROM dbo.PkgLogProvider


SELECT * FROM dbo.PkgTransformation
SELECT * FROM dbo.package where PkgID=25
