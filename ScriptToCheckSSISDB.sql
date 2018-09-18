/*************************************************************************************************************************************************************************************************
PURPOSE: Show the execution breakdown for a specific execution (operation_id)
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO
-- Filter data by execution id (use NULL for no filter)
DECLARE @operation_id AS bigint = 713580;
WITH 
ctePRE AS 
(
	SELECT * FROM catalog.event_messages em  
	WHERE em.event_name IN ('OnPreExecute') and operation_id = @operation_id
	
), 
ctePOST AS 
(
	SELECT * FROM catalog.event_messages em 
	WHERE em.event_name IN ('OnPostExecute') and operation_id = @operation_id
)
SELECT
	b.operation_id,
	e2.status,
	status_desc = CASE e2.status 
						WHEN 1 THEN 'Created'
						WHEN 2 THEN 'Running'
						WHEN 3 THEN 'Cancelled'
						WHEN 4 THEN 'Failed'
						WHEN 5 THEN 'Pending'
						WHEN 6 THEN 'Ended Unexpectedly'
						WHEN 7 THEN 'Succeeded'
						WHEN 8 THEN 'Stopping'
						WHEN 9 THEN 'Completed'
					END,
	b.event_message_id,
	--b.package_path,
	b.execution_path,
	b.message_source_name,
	pre_message_time = b.message_time,
	post_message_time = e.message_time,
	DATEDIFF(mi, b.message_time, COALESCE(e.message_time, SYSDATETIMEOFFSET()))
FROM
	ctePRE b
LEFT OUTER JOIN
	ctePOST e ON b.operation_id = e.operation_id AND b.package_name = e.package_name AND b.message_source_id = e.message_source_id and b.execution_path = e.execution_path
INNER JOIN
	[catalog].executions e2 ON b.operation_id = e2.execution_id
WHERE
	b.package_path = '\Package'
AND
--	b.message_source_name = @source_name
	b.operation_id = @operation_id
ORDER BY
	b.event_message_id desc;

/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show the latest Object version for the Projects
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO
IF Object_id('SSISDB..#T') IS NOT NULL
  BEGIN
      DROP TABLE #T
  END
 SELECT t.object_id,t.object_version_lsn,t.object_name,t.created_time,t.created_by 
INTO #T
FROM
(
select object_id,object_version_lsn,object_name,created_time,created_by from catalog.object_versions where object_name='ProjectName' 
UNION ALL
select object_id,object_version_lsn,object_name,created_time,created_by from catalog.object_versions where object_name='ProjectName' 
UNION ALL
select object_id,object_version_lsn,object_name,created_time,created_by from catalog.object_versions where object_name='ProjectName' ) t

 SELECT  * FROM #T ORDER BY created_time DESC

/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show all package-events for executionid
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO
DECLARE @executionId BIGINT = 1172280;

SELECT 
	message_time,
	[message],
	package_name,
	package_path,
	subcomponent_name,
	execution_path
FROM 
	[catalog].event_messages
WHERE
	operation_id = @executionId
/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show all package-details-execution-values for executionid
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO
DECLARE @executionId BIGINT = 1172280;

SELECT 
	OBJECT_TYPE,
	OBJECT_TYPE_DESC = 
		CASE OBJECT_TYPE 
			WHEN 20 THEN 'PROJECT'
			WHEN 30 THEN 'PACKAGE'
			WHEN 50 THEN 'SYSTEM'
			ELSE 'UNKNOWN'
		END,
	PARAMETER_DATA_TYPE,
	PARAMETER_NAME,
	PARAMETER_VALUE = CAST(PARAMETER_VALUE AS NVARCHAR(MAX)),
	SENSITIVE,
	[REQUIRED], 
	VALUE_SET,
	RUNTIME_OVERRIDE
FROM 
	[CATALOG].[EXECUTION_PARAMETER_VALUES] 
WHERE 
	[EXECUTION_ID] = @executionId
/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show package performance
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO
/*1. Get the List of Execution for the Package using the below query*/ 

declare @foldername nvarchar(260)
declare @projectname nvarchar(260)
declare @packagename nvarchar(260)
 
set @foldername = 'CGX'
set @projectname = 'CDM_PRJ_MemberSummary'
set @packagename = 'CDM_PKG_GEN_Dim_Member_DLY.dtsx'
 
DECLARE @ExecIds table(execution_id bigint);
insert into @ExecIds
 
SELECT execution_id
FROM catalog.executions
WHERE folder_name = @foldername 
     AND project_name = @projectname 
     AND package_name = @packagename 
     AND status = 7;

/*2. Get the duration for the above listed executionid

SELECT es.execution_id, e.executable_name, ES.execution_duration
FROM catalog.executable_statistics es, catalog.executables e
WHERE 
es.executable_id = e.executable_id AND
es.execution_id = e.execution_id AND
es.execution_id in (select * from @ExecIds)
ORDER BY e.executable_name,es.execution_duration DESC;

uncomment only if you want the see the ids and exectuion time*/

/*3. we can identify all the “slower than usual” tasks for the Execution id */

With AverageExecDudration As (
    select executable_name, avg(es.execution_duration) as avg_duration,STDEV(es.execution_duration) as stddev
    from catalog.executable_statistics es, catalog.executables e
    where 
    es.executable_id = e.executable_id AND
    es.execution_id = e.execution_id AND
    es.execution_id in (select * from @ExecIds)
    group by e.executable_name
)
select es.execution_id, e.executable_name, ES.execution_duration, AvgDuration.avg_duration, AvgDuration.stddev
from catalog.executable_statistics es, catalog.executables e, 
    AverageExecDudration AvgDuration
where 
es.executable_id = e.executable_id AND
es.execution_id = e.execution_id AND
es.execution_id in (select * from @ExecIds) AND
e.executable_name = AvgDuration.executable_name AND
es.execution_duration > (AvgDuration.avg_duration + AvgDuration.stddev)
order by es.execution_duration desc

/* uncommnet and specify the id for the component and validate time spent in each phase of the data flow task

declare @probExec bigint
set @probExec = 734772
 
-- Identify the component’s total and active time
select package_name, task_name, subcomponent_name, execution_path,
    SUM(DATEDIFF(ms,start_time,end_time)) as active_time,
    DATEDIFF(ms,min(start_time), max(end_time)) as  total_time
from catalog.execution_component_phases
where execution_id = @probExec
group by package_name, task_name, subcomponent_name, execution_path
order by active_time desc
 
declare @component_name nvarchar(1024)
set @component_name = 'DFT Load DC Vendor'
 
-- See the breakdown of the component by phases
select package_name, task_name, subcomponent_name, execution_path,phase,
    SUM(DATEDIFF(ms,start_time,end_time)) as active_time,
    DATEDIFF(ms,min(start_time), max(end_time)) as  total_time
from catalog.execution_component_phases
where execution_id = @probExec AND subcomponent_name = @component_name
group by package_name, task_name, subcomponent_name, execution_path, phase
order by active_time desc

*/

select top 10 * from SSISDB.catalog.execution_component_phases
/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Catalog get_any_Parameter values
*************************************************************************************************************************************************************************************************/
USE [SSISDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [catalog].[get_any_parameter_values]
    @folder_name nvarchar(128),
    @project_name nvarchar(128),
    @package_name nvarchar(260),
    @reference_id  bigint = NULL
AS
/*********************************************************************************************
 *
 *	Purpose:	Retrieves the parameter values from a project and its corresponding 
 *				packages in the Integration Services catalog.
 *
 *	Parameters:	@folder_name	- The folder name of the SSIS project to lookup
 *				@project_name	- The name of the project to lookup
 *				@package_name	- Optional, if specified it will filter on the package name
 *									the package parameters for @package_name only. 
 *								  Specify NULL to retrieve parameters of all packages 
 *									within the project.
 *				@reference_id	- The unique identifier of an environment reference. 
 *									Optional, if specified it will return the values 
 *									referenced by the environment that has been mapped to
 *									the SSIS project/package parameter.
 *
 *	Usage:	
 *		-- Retrieve a list of parameters belonging to "Test SSIS Project" in the "DEV SSIS" folder
 *		-- including the corresponding packages, and resolve parameter values when mapped to 
 *		-- environment reference id = 2.
 *		EXEC [catalog].[get_any_parameter_values] 
 *			@folder_name = 'DEV SSIS', 
 *			@project_name = 'Test SSIS Project', 
 *			@package_name = NULL, 
 *			@reference_id = 2
 *
 *		-- Retrieve a list of parameters belonging to "Test SSIS Project" in the "DEV SSIS" folder
 *		-- including the corresponding packages, and their static parameter configuration.
 *		EXEC [catalog].[get_any_parameter_values] 
 *			@folder_name = 'DEV SSIS', 
 *			@project_name = 'Test SSIS Project', 
 *			@package_name = NULL, 
 *			@reference_id = NULL
 *
 *		-- Retrieve a list of parameters belonging to "Test SSIS Project" in the "DEV SSIS" folder
 *		-- as well as package parameters defined for "Master.dtsx", and their static parameter 
 *		-- configuration.
 *		EXEC [catalog].[get_any_parameter_values] 
 *			@folder_name = 'DEV SSIS', 
 *			@project_name = 'Test SSIS Project', 
 *			@package_name = 'Master.dtsx', 
 *			@reference_id = NULL
 *
 *	Author:		Julie Koesmarno (http://www.mssqlgirl.com)
 *
 *	History:
 *	20120527 - Draft (v0.1)	- Initial Draft copied from SSISDB.catalog.get_parameter_values
 *								of SQL Server 2012 RTM.
 *								Fix to properly allow NULL input on @package_name and return
 *								all parameters belonging to the project and its 
 *								corresponding paramters. Changes are marked with "edit:"
 *								For further info see: http://wp.me/p2mASP-6J
 *
 **********************************************************************************************/  

    SET NOCOUNT ON
    DECLARE @project_id bigint
    DECLARE @environment_id bigint
    DECLARE @version_id bigint
    DECLARE @result bit
    DECLARE @environment_found bit
    
    IF (@folder_name IS NULL OR @project_name IS NULL 
            --OR @package_name IS NULL )	-- edit: This is removed to allow NULL in @package_name to retrieve 
											-- all parameters at Project level and Package level.
		)
    BEGIN
        RAISERROR(27138, 16 , 1) WITH NOWAIT 
        RETURN 1 
    END
    
    
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
    
    
    
    DECLARE @tran_count INT = @@TRANCOUNT;
    DECLARE @savepoint_name NCHAR(32);
    IF @tran_count > 0
    BEGIN
        SET @savepoint_name = REPLACE(CONVERT(NCHAR(36), NEWID()), N'-', N'');
        SAVE TRANSACTION @savepoint_name;
    END
    ELSE
        BEGIN TRANSACTION;                                                                                      
    BEGIN TRY
    
        EXECUTE AS CALLER
            SELECT @project_id = projs.[project_id],
                   @version_id = projs.[object_version_lsn]
                FROM [catalog].[projects] projs INNER JOIN [catalog].[folders] fds
                ON projs.[folder_id] = fds.[folder_id] INNER JOIN [catalog].[packages] pkgs
                ON projs.[project_id] = pkgs.[project_id] 
                WHERE fds.[name] = @folder_name AND projs.[name] = @project_name
				--AND pkgs.[name] = @package_name									-- edit: this is the original filter and changed to below.
                AND ((pkgs.[name] = @package_name AND @package_name IS NOT NULL)	-- edit: add logic to ensure filtering @package_name 
					OR @package_name IS NULL)										--		 is applied only when it is specified.
        REVERT
        
        IF (@project_id IS NULL)
        BEGIN
            RAISERROR(27146, 16, 1) WITH NOWAIT
        END
        
        DECLARE @environment_name nvarchar(128)
        DECLARE @environment_folder_name nvarchar(128)
        DECLARE @reference_type char(1)
        
        
        DECLARE @result_set TABLE
        (
            [parameter_id] bigint,
            [object_type] smallint, 
            [parameter_data_type] nvarchar(128),
            [parameter_name] nvarchar(128),
            [parameter_value] sql_variant,
            [sensitive]  bit,
            [required]  bit,
            [value_set] bit
        );
        
        
        IF(@reference_id IS NOT NULL)
        BEGIN
            
            EXECUTE AS CALLER
                SELECT @environment_name = environment_name,
                       @environment_folder_name = environment_folder_name,
                       @reference_type = reference_type
                FROM [catalog].[environment_references]
                WHERE project_id = @project_id AND reference_id = @reference_id
            REVERT
            IF (@environment_name IS NULL)
            BEGIN
                RAISERROR(27208, 16, 1, @reference_id) WITH NOWAIT
            END                                                     
            
            
            SET @environment_found = 1
            IF (@reference_type = 'A')
            BEGIN
                SELECT @environment_id = envs.[environment_id]
                FROM [internal].[folders] fds INNER JOIN [internal].[environments] envs
                ON fds.[folder_id] = envs.[folder_id]
                WHERE envs.[environment_name] = @environment_name AND fds.[name] = @environment_folder_name
            END
            ELSE IF (@reference_type = 'R')
            BEGIN
                SELECT @environment_id = envs.[environment_id]
                FROM  [internal].[projects] projs INNER JOIN [internal].[environments] envs
                ON projs.[folder_id] = envs.[folder_id]
                WHERE envs.[environment_name] = @environment_name AND projs.[project_id] = @project_id
            END
            IF (@environment_id IS NULL)
            BEGIN
                SET @environment_found = 0
            END
            
            EXECUTE AS CALLER
                SET @result =  [internal].[check_permission]
                    (
                        3,
                        @environment_id,
                        1
                     )
            REVERT
            IF @result = 0
            BEGIN
                SET @environment_found = 0
            END
            
            IF @environment_found = 0
            BEGIN
                RAISERROR(27182 , 16 , 1, @environment_name) WITH NOWAIT
            END
            
            
            INSERT INTO @result_set 
            SELECT params.[parameter_id],
                   params.[object_type],  
                   params.[data_type],
                   params.[parameter_name],
                   NULL,
                   params.[sensitive],
                   params.[required],
                   params.[value_set]
            FROM [catalog].[object_parameters] params INNER JOIN
             ([internal].[environments] envs INNER JOIN [internal].[environment_variables] vars
            ON envs.[environment_id] = vars.[environment_id])
            ON vars.[name] = params.[referenced_variable_name] AND params.[value_type] = 'R'
            WHERE  params.[project_id] = @project_id
            AND (params.[object_type] = 20
            OR (-- params.[object_name] = @package_name									-- edit: this is the original filter and changed to below.
				((params.[object_name] = @package_name AND @package_name IS NOT NULL)	-- edit: add logic to ensure filtering @package_name 
									OR @package_name IS NULL)							--		 is applied when it is specified.
            AND params.[object_type] = 30))
            AND envs.[environment_id] = @environment_id
            AND params.[data_type] <> vars.[type]
                       
            
            DECLARE @pname  nvarchar(128)
            DECLARE @otype  smallint
            
            DECLARE result_cursor CURSOR LOCAL FOR
            SELECT [parameter_name], [object_type]
            FROM @result_set
            
            OPEN result_cursor
            FETCH NEXT FROM result_cursor
            INTO @pname, @otype
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                RAISERROR(27148, 10, 1, @pname) WITH NOWAIT
                FETCH NEXT FROM result_cursor
                INTO @pname, @otype
            END
            CLOSE result_cursor
            DEALLOCATE result_cursor
                 
        END
    
        INSERT INTO @result_set 
        SELECT [parameter_id],
               [object_type],  
               [parameter_data_type],
               [parameter_name],
               [default_value],
               [sensitive],
               [required],
               [value_set] 
        FROM [internal].[object_parameters] 
        WHERE [project_id] = @project_id 
        AND ([object_type] = 20 
        OR (-- [object_name] = @package_name 								-- edit: this is the original filter and changed to below.
			(([object_name] = @package_name AND @package_name IS NOT NULL)	-- edit: add logic to ensure filtering @package_name 
								OR @package_name IS NULL)					--		 is applied only when it is specified.
			AND [object_type] = 30))
        AND [value_type] = 'V' 
        AND [project_version_lsn] = @version_id       

        
        IF @environment_id IS NOT NULL
        BEGIN
            INSERT INTO @result_set 
            SELECT params.[parameter_id],
                   params.[object_type],  
                   params.[parameter_data_type],
                   params.[parameter_name],
                   vars.[value],
                   params.[sensitive],
                   params.[required],
                   params.[value_set]
            FROM [internal].[object_parameters] params 
            INNER JOIN [internal].[environment_variables] vars
                ON params.[referenced_variable_name] = vars.[name] 
            WHERE params.[project_id] = @project_id 
            AND (params.[object_type] = 20
            OR (--params.[object_name] = @package_name 									-- edit: this is the original filter and changed to below.
				((params.[object_name] = @package_name AND @package_name IS NOT NULL)	-- edit: add logic to ensure filtering @package_name 
									OR @package_name IS NULL)							--		 is applied only when it is specified.
            AND params.[object_type] = 30))
            AND params.[value_type] = 'R' 
            AND params.[parameter_data_type] = vars.[type]
            AND params.[project_version_lsn] = @version_id
            AND vars.[environment_id] = @environment_id
        END

        
        INSERT INTO @result_set 
        SELECT objParams.[parameter_id],
               objParams.[object_type],  
               objParams.[parameter_data_type],
               objParams.[parameter_name],
               NULL,
               objParams.[sensitive],
               objParams.[required],
               objParams.[value_set]
        FROM [internal].[object_parameters] objParams LEFT JOIN @result_set resultset
        ON objParams.[object_type] = resultset.[object_type]
        AND objParams.[parameter_name] = resultset.[parameter_name] COLLATE SQL_Latin1_General_CP1_CS_AS
        WHERE objParams.[project_id] = @project_id 
        AND -- objParams.[object_name] = @package_name 									-- edit: this is the original filter and changed to below.
			((objParams.[object_name] = @package_name AND @package_name IS NOT NULL)	-- edit: add logic to ensure filtering @package_name 
			OR @package_name IS NULL)													--		 is applied only when it is specified.
        AND objParams.[object_type] = 30
        AND objParams.[value_type] = 'R' 
        AND objParams.[project_version_lsn] = @version_id 
        AND resultset.[parameter_name] IS NULL
            
        INSERT INTO @result_set 
        SELECT objParams.[parameter_id],
               objParams.[object_type],  
               objParams.[parameter_data_type],
               objParams.[parameter_name],
               NULL,
               objParams.[sensitive],
               objParams.[required],
               objParams.[value_set]
        FROM [internal].[object_parameters] objParams LEFT JOIN @result_set resultset
        ON objParams.[object_type] = resultset.[object_type]
        AND objParams.[parameter_name] = resultset.[parameter_name] COLLATE SQL_Latin1_General_CP1_CS_AS
        WHERE objParams.[project_id] = @project_id 
        AND objParams.[object_name] = @project_name 
        AND objParams.[object_type] = 20
        AND objParams.[value_type] = 'R' 
        AND objParams.[project_version_lsn] = @version_id 
        AND resultset.[parameter_name] IS NULL
        
        SELECT [parameter_id] ,
            [object_type], 
            [parameter_data_type],
            [parameter_name],
            [parameter_value],
            [sensitive],
            [required],
            [value_set]
        FROM @result_set
        
    
        IF @tran_count = 0
            COMMIT TRANSACTION;                                                                                 
    END TRY
    
    BEGIN CATCH
        
        IF @tran_count = 0 
            ROLLBACK TRANSACTION;
        
        ELSE IF XACT_STATE() <> -1
            ROLLBACK TRANSACTION @savepoint_name;                                                                           
        
        IF (CURSOR_STATUS('local', 'result_cursor') = 1 
            OR CURSOR_STATUS('local', 'result_cursor') = 0)
        BEGIN
            CLOSE result_cursor
            DEALLOCATE result_cursor            
        END;             
        THROW;
    END CATCH
    
    RETURN 0      
    


GO
/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show the parameters values used for a specific execution
NOTES :	The first resultset shows the values set via "parameters", the second via the "set" option
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO
-- Filter data by execution id 
DECLARE @executionIdFilter BIGINT = (SELECT MAX(execution_id) FROM SSISDB.catalog.executions where project_name='PDW_CorePMRF')

SELECT * FROM [catalog].[execution_parameter_values] WHERE [execution_id] = @executionIdFilter and [value_set] = 1

SELECT * FROM [catalog].[execution_property_override_values] WHERE [execution_id] = @executionIdFilter
/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show the No.of.Rows return for the Package Last execution
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO

Declare @sSourceName varchar(100)='PDW_CoreGroupEligibility'

SELECT
operation_id ExecutionID,
source_name SourceName,
replace(package_name, '.dtsx', '') PackageName,
message Details
FROM
(
SELECT
o.object_name source_name,
em.*
FROM
SSISDB.catalog.event_messages em
INNER JOIN SSISDB.catalog.operations o on em.operation_id=o.operation_id
WHERE em.operation_id=(SELECT max(em1.operation_id) FROM SSISDB.catalog.operations o1 INNER JOIN SSISDB.catalog.event_messages em1 ON o1.operation_id=em1.operation_id 
                       WHERE o1.object_name=@sSourceName)
AND event_name NOT LIKE '%Validate%'
AND (message LIKE '% wrote %'
OR  (message_source_type=30 AND (message like '%Start%' OR message like '%Finished%')))
) Q
WHERE source_name=@sSourceName
ORDER BY message_time,event_message_id;
/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show the No.of.folders
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO
SELECT 
	f.folder_id, 
	f.[name], 
	[description] 
FROM [catalog].folders f
WHERE EXISTS (SELECT * FROM [catalog].projects p WHERE p.folder_id = f.folder_id)
ORDER BY	f.[name]
/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show the engine-info
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO
IF (SERVERPROPERTY('EDITION') = 'SQL Azure') 
BEGIN
	SELECT [server_name] = 'DEMO', [service_name] = 'DEMO'
END ELSE BEGIN
	EXEC('SELECT [server_name] = @@SERVERNAME, [service_name] = @@SERVICENAME')
END
/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show the engine-kpi
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO

DECLARE @hourspan INT = ?;
DECLARE @asOfDate DATETIME2 = NULLIF(?, 'NOW');
DECLARE @folderNamePattern NVARCHAR(100) = ?;
DECLARE @projectNamePattern NVARCHAR(100) = ?;

SET @asOfDate = ISNULL(@asOfDate, SYSDATETIME());

SELECT
	status_code = ISNULL(e.[status], 0),
	status_count = COUNT(*)
FROM
	[catalog].executions e
WHERE e.folder_name LIKE @folderNamePattern
AND 	e.project_name LIKE @projectNamePattern
AND	e.start_time >= DATEADD(HOUR, -@hourspan, @asOfDate)
GROUP BY 	e.[status]
WITH
	ROLLUP
/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show the engine-projects
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO
SELECT
	f.folder_id,
	f.name, 
	project_id, 
	p.folder_id, 
	p.name, 
	p.[description] 
FROM [catalog].projects p
INNER JOIN	[catalog].folders f ON p.folder_id = f.folder_id
ORDER BY	f.[name],p.[name]
/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show the execution-statistics
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO
DECLARE @hourspan INT = ?;
DECLARE @asOfDate DATETIME2 = NULLIF(?, 'NOW');
DECLARE @folderNamePattern NVARCHAR(100) = ?;
DECLARE @projectNamePattern NVARCHAR(100) = ?;
DECLARE @statusFilter INT = ?;

SET @asOfDate = ISNULL(@asOfDate, SYSDATETIME());

with numbers as 
(
	select
		n = row_number() over (order by a.object_id)
	from
		sys.all_columns a cross join sys.all_columns b
), calendar as
(
	select distinct 
		cast(dateadd(hour, n * -1, @asOfDate) as date) as calendar_date
	from
		numbers
	where n <= @hourspan
), executions as 
(
	select
		[created_date] = cast(e.created_time as date),
		*
	from
		[catalog].executions e
	where
		cast(e.created_time as date) is not null
	and e.folder_name like @folderNamePattern
	and e.project_name like @projectNamePattern
	and (e.[status] = @statusFilter or @statusFilter = 0)
)
select
	c.[calendar_date],
	created_packages = count(e.execution_id),
	executed_packages = sum(case when e.start_time is not null then 1 else 0 end),
	succeeded_packages = sum(case when e.[status] = 7 then 1 else 0 end),
	failed_packages = sum(case when e.[status] = 4 then 1 else 0 end)
from	calendar c 
left join executions e on e.created_date = c.calendar_date
group by	c.[calendar_date]
/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show the execution for Package-children
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO
DECLARE @executionIdFilter BIGINT = ?;

WITH 
ctePRE AS 
(
	SELECT * FROM catalog.event_messages em 
	WHERE em.event_name IN ('OnPreExecute')
	
), 
ctePOST AS 
(
	SELECT * FROM catalog.event_messages em 
	WHERE em.event_name IN ('OnPostExecute')
),
cteFINAL AS
(
	SELECT		
		rn = ROW_NUMBER() OVER (PARTITION BY b.event_message_id ORDER BY e.event_message_id),
		b.event_message_id,
		b.message_source_type,
		b.package_path,
		b.package_name,
		b.execution_path,
		b.message_source_name,
		pre_message_time = b.message_time,
		post_message_time = e.message_time
	FROM
		ctePRE b
	LEFT OUTER JOIN
		ctePOST e ON b.operation_id = e.operation_id AND b.package_name = e.package_name AND b.message_source_id = e.message_source_id AND e.event_message_id > b.event_message_id
	WHERE
		b.operation_id = @executionIdFilter
	AND
		b.package_path = '\Package'
)
SELECT
	event_message_id,
	message_source_type,
	package_name,
	package_path,
	execution_path,
	message_source_name,
	pre_message_time = format(pre_message_time, 'yyyy-MM-dd HH:mm:ss'),
	post_message_time = format(post_message_time, 'yyyy-MM-dd HH:mm:ss'),
	elapsed_time_min = datediff(mi, pre_message_time, post_message_time)
FROM
	cteFINAL
WHERE
	rn = 1
AND
	CHARINDEX('\', execution_path, 2) > 0
ORDER BY	event_message_id desc;

/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show the detailed execution overrides
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO
declare @executionId bigint = ?;

select 
	property_path,
	property_value = cast(property_value as nvarchar(max))
from 
	[catalog].[execution_property_override_values] 
where [execution_id] = @executionId
/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show the duplicate warninigs for an execution
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO
DECLARE @executionId BIGINT = ?;

SELECT 
	message_time,
	[message],
	package_name,
	package_path,
	subcomponent_name,
	execution_path
FROM [catalog].event_messages
WHERE operation_id = @executionId
AND	event_name = 'OnWarning'
AND	[message] LIKE '%duplicate%' 
/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show the errors for an execution
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO
DECLARE @executionId BIGINT = ?;

SELECT 
	message_time,
	[message],
	package_name,
	package_path,
	subcomponent_name,
	execution_path
FROM [catalog].event_messages
WHERE	operation_id = @executionId
AND	event_name = 'OnError'
/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show the memory allocation warnings for an execution
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO
DECLARE @executionId BIGINT = ?;

SELECT 
	message_time,
	[message],
	package_name,
	package_path,
	subcomponent_name,
	execution_path
FROM [catalog].event_messages
WHERE	operation_id = @executionId
AND	event_name = 'OnInformation' 
AND	[message] LIKE '%memory allocation%' 
/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show the  warnings for an execution
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO
DECLARE @executionId BIGINT = ?;

SELECT 
	message_time,
	[message],
	package_name,
	package_path,
	subcomponent_name,
	execution_path
FROM [catalog].event_messages
WHERE operation_id = @executionId
AND	event_name = 'OnWarning'
/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show the package executables for an execution
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO
declare @executionIdFilter bigint = ?;

select
	es.statistics_id,
	e.package_name,
	e.package_path,
	es.execution_path,
	e.executable_name,
	start_time = format(es.start_time, 'yyyy-MM-dd HH:mm:ss'),
	end_time = format(es.end_time, 'yyyy-MM-dd HH:mm:ss'),
	execution_duration_min = datediff(minute, es.start_time, es.end_time),
	execution_duration_sec = datediff(second, es.start_time, es.end_time),
	[status] = es.execution_result
from	[catalog].[executables] e 
inner join	[catalog].[executable_statistics] es on e.executable_id = es.executable_id and e.execution_id = es.execution_id
where	es.execution_id = @executionIdFilter
order by	es.start_time
/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show the package run history
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO
DECLARE @folderNamePattern NVARCHAR(100) = ?;
DECLARE @projectNamePattern NVARCHAR(100) = ?;
DECLARE @packageNamePattern NVARCHAR(100) = ?;

WITH cte AS 
(
	SELECT TOP (50)
		e.execution_id, 
		e.project_name,
		e.package_name,
		e.environment_name,
		e.project_lsn,
		e.status,
		e.start_time,
		e.end_time,
		elapsed_time_min = datediff(ss, e.start_time, e.end_time) / 60.,	
		avg_elapsed_time_min = avg(datediff(ss, e.start_time, e.end_time) / 60.) OVER (ORDER BY e.start_time ROWS BETWEEN 5 PRECEDING AND CURRENT ROW)
	FROM 	catalog.executions e
	WHERE 	e.status IN (2,7)
	AND		e.folder_name LIKE @folderNamePattern
	AND		e.package_name like @packageNamePattern
	AND		e.project_name LIKE @projectNamePattern
	ORDER BY e.execution_id DESC
)
SELECT
	execution_id, 
	project_name,
	package_name,
	environment_name,
	project_lsn,
	[status],
	start_time = format(start_time, 'yyyy-MM-dd HH:mm:ss'),
	end_time = format(CASE WHEN end_time IS NULL THEN dateadd(minute, cast(CEILING(avg_elapsed_time_min) AS int), start_time) ELSE end_time end, 'yyyy-MM-dd HH:mm:ss'),
	elapsed_time_min = format(CASE WHEN end_time IS NULL THEN avg_elapsed_time_min ELSE elapsed_time_min end, '#,0.00'),
	avg_elapsed_time_min = format(avg_elapsed_time_min, '#,0.00'),
	percent_complete = format(100 * (DATEDIFF(ss, start_time, SYSDATETIMEOFFSET()) / 60.) / avg_elapsed_time_min, '#,0.00'),
	has_expected_values = CASE WHEN end_time IS NULL THEN 1 ELSE 0 END
FROM cte
ORDER BY	execution_id DESC
/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show the package kpi
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO
DECLARE @hourspan INT = ?;
DECLARE @asOfDate DATETIME2 = NULLIF(?, 'NOW');
DECLARE @folderNamePattern NVARCHAR(100) = ?;
DECLARE @projectNamePattern NVARCHAR(100) = ?;
DECLARE @executionId BIGINT = ?;

SET @asOfDate = ISNULL(@asOfDate, SYSDATETIME());

WITH cteEID as
(
	SELECT execution_id FROM [catalog].executions e WHERE 
	e.folder_name LIKE @folderNamePattern AND
	e.project_name LIKE @projectNamePattern AND
	(@executionId = -1 AND e.start_time >= DATEADD(HOUR, -@hourspan, @asOfDate)) OR (e.execution_id = @executionId)
),
cteA AS(SELECT [events] = COUNT(*) FROM [catalog].event_messages em WHERE em.operation_id IN (SELECT c.execution_id FROM cteEID c)),
cteE AS(SELECT errors = COUNT(*) FROM [catalog].event_messages em WHERE em.operation_id IN (SELECT c.execution_id FROM cteEID c)  AND em.event_name = 'OnError'),
cteW AS(SELECT warnings = COUNT(*) FROM [catalog].event_messages em WHERE em.operation_id IN (SELECT c.execution_id FROM cteEID c) AND em.event_name = 'OnWarning' ),
cteDW AS(SELECT duplicate_warnings = COUNT(*) FROM [catalog].event_messages em WHERE em.operation_id IN (SELECT c.execution_id FROM cteEID c) AND em.event_name = 'OnWarning' AND [message] LIKE '%duplicate%'),
cteMW AS(SELECT memory_warnings = COUNT(*) FROM [catalog].event_messages em WHERE em.operation_id IN (SELECT c.execution_id FROM cteEID c) AND em.event_name = 'OnInformation' AND [message] LIKE '%memory allocation%')
SELECT * FROM	cteA, cteE, cteW, cteDW, cteMW
OPTION
	(RECOMPILE)
/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show the package list
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO
DECLARE @hourspan INT = ?;
DECLARE @asOfDate DATETIME2 = NULLIF(?, 'NOW');
DECLARE @folderNamePattern NVARCHAR(100) = ?;
DECLARE @projectNamePattern NVARCHAR(100) = ?;
DECLARE @statusFilter INT = ?;

SET @asOfDate = ISNULL(@asOfDate, SYSDATETIME());

with cteWE as
(
	select operation_id, event_name, event_count = count(*)
	from  [catalog].event_messages 
	where	event_name in ('OnError', 'OnWarning')
	group by	operation_id, event_name
),
cteKPI as
(
	select
		operation_id,
		[errors] = OnError,
		warnings = OnWarning
	from
		cteWE
	pivot
		(
			sum(event_count) for event_name in (OnError, OnWarning)
		) p
),
cteLoglevel as
(
	select
		execution_id,
		cast(parameter_value as int) as logging_level
	from
		[catalog].[execution_parameter_values]
	where
		parameter_name = 'LOGGING_LEVEL'
)
select top 15
	e.execution_id, 
	e.project_name,
	e.package_name,
	e.project_lsn,
	environment = isnull(e.environment_folder_name, '') + isnull('\' + e.environment_name,  ''), 
	e.status, 
	start_time = format(e.start_time, 'yyyy-MM-dd HH:mm:ss'),
	end_time = format(e.end_time, 'yyyy-MM-dd HH:mm:ss'),
	elapsed_time_min = format(datediff(ss, e.start_time, e.end_time) / 60., '#,0.00'),
	k.warnings,
	k.errors,
	l.logging_level
from 
	[catalog].executions e 
left outer join	cteKPI k on e.execution_id = k.operation_id
left outer join	cteLoglevel l on e.execution_id = l.execution_id
where e.folder_name like @folderNamePattern
and	e.project_name like @projectNamePattern
and	e.created_time >= dateadd(hour, -@hourspan, @asOfDate)
and	(e.[status] = @statusFilter or @statusFilter = 0)
order by 	e.execution_id desc
option
	(recompile)
;
/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show the package dataflow execution and no of rows
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO
-- Filter data by execution id (use NULL for no filter)
DECLARE @executionIdFilter BIGINT = 20143;
WITH 
ctePRE AS 
(
	SELECT * FROM catalog.event_messages em 
	WHERE em.event_name IN ('OnPreExecute')
	
), 
ctePOST AS 
(
	SELECT * FROM catalog.event_messages em 
	WHERE em.event_name IN ('OnPostExecute')
)
SELECT
	b.operation_id,
	b.event_message_id,
	b.package_path,
	b.message_source_name,
	pre_message_time = b.message_time,
	post_message_time = e.message_time,
	DATEDIFF(mi, b.message_time, e.message_time)
FROM
	ctePRE b
LEFT OUTER JOIN
	ctePOST e ON b.operation_id = e.operation_id AND b.package_name = e.package_name AND b.message_source_id = e.message_source_id AND b.event_message_id=e.event_message_id
WHERE	b.operation_id = @executionIdFilter
AND	b.package_path = '\Package'
ORDER BY	b.event_message_id desc;

WITH cte AS
(
	SELECT
		*,
		token_destination_name_start = CHARINDEX(': "', [message]) + 3,
		token_destination_name_end = CHARINDEX('" wrote', [message]),
		token_rows_start = LEN([message]) - CHARINDEX('e', REVERSE([message]), 1) + 3,
		token_rows_end = LEN([message]) - CHARINDEX('r', REVERSE([message]), 1)
	FROM
		[catalog].[event_messages] em
)
SELECT TOP 100
	event_message_id,
	package_name,
	message_source_name,
	message_time,
	destination_name = SUBSTRING([message], token_destination_name_start,  token_destination_name_end - token_destination_name_start),
	loaded_rows = SUBSTRING([message], token_rows_start, token_rows_end - token_rows_start),
	[message]
FROM 
	cte as c 
WHERE	c.operation_id = @executionIdFilter
AND 	subcomponent_name = 'SSIS.Pipeline' 
AND 	[message] like '%rows.%'
ORDER BY 	event_message_id DESC
/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show the Information/Warning/Error messages found in the log for a specific execution
NOTES:	The first resultset is the log, the second one shows the performance	
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO
-- Filter data by execution id (use NULL for no filter)
DECLARE @executionIdFilter BIGINT = NULL;

-- Show only Child Packages or everyhing
DECLARE @showOnlyChildPackages BIT = 0;

-- Show only message from a specific Message Source
DECLARE @messageSourceName NVARCHAR(MAX)= '%'

/*log info*/
SELECT * FROM catalog.event_messages em 
WHERE ((em.operation_id = @executionIdFilter) OR @executionIdFilter IS NULL) 
AND (em.event_name IN ('OnInformation', 'OnError', 'OnWarning'))
AND (package_path LIKE CASE WHEN @showOnlyChildPackages = 1 THEN '\Package' ELSE '%' END)
AND (em.message_source_name like @messageSourceName)
ORDER BY em.event_message_id;


/*Performance Breakdown*/
IF (OBJECT_ID('tempdb..#t') IS NOT NULL) DROP TABLE #t;

WITH 
ctePRE AS 
(
	SELECT * FROM catalog.event_messages em 
	WHERE em.event_name IN ('OnPreExecute')
	AND ((em.operation_id = @executionIdFilter) OR @executionIdFilter IS NULL)
	AND (em.message_source_name like @messageSourceName)
	
), 
ctePOST AS 
(
	SELECT * FROM catalog.event_messages em 
	WHERE em.event_name IN ('OnPostExecute')
	AND ((em.operation_id = @executionIdFilter) OR @executionIdFilter IS NULL)
	AND (em.message_source_name like @messageSourceName)
)
SELECT
	b.operation_id,
	from_event_message_id = b.event_message_id,
	to_event_message_id = e.event_message_id,
	b.package_path,
	b.execution_path,
	b.message_source_name,
	pre_message_time = b.message_time,
	post_message_time = e.message_time,
	elapsed_time_min = DATEDIFF(mi, b.message_time, COALESCE(e.message_time, SYSDATETIMEOFFSET()))
INTO
	#t
FROM
	ctePRE b
LEFT OUTER JOIN
	ctePOST e ON b.operation_id = e.operation_id AND b.package_name = e.package_name AND b.message_source_id = e.message_source_id AND b.[execution_path] = e.[execution_path]
INNER JOIN
	[catalog].executions e2 ON b.operation_id = e2.execution_id
WHERE
	e2.status IN (2,7)
OPTION
	(RECOMPILE)
;

SELECT * FROM #t 
WHERE package_path LIKE CASE WHEN @showOnlyChildPackages = 1 THEN '\Package' ELSE '%' END
ORDER BY  #t.pre_message_time DESC
/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show lookup usage for a specific package/execution	
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO
--Filter data by execution id (use NULL for no filter)
DECLARE @executionIdFilter BIGINT = 20143

-- Filter data by package name (use % for no filter)
DECLARE @packageNamePattern NVARCHAR(100) = '%%'
;WITH cte AS
(
	SELECT 
		em.[operation_id],
		em.[message],
		em.[package_name],
		em.[package_path],
		em.[execution_path],
		
		lookup_token_start = CHARINDEX(': The ', em.[message]) + 6,
		lookup_token_end = CHARINDEX('processed', em.[message]),

		cached_rows_token_start = CHARINDEX('processed', em.[message]) + 9,
		cached_rows_token_end = CHARINDEX('rows in the cache.', em.[message]),

		process_time_token_start = CHARINDEX('time was ', em.[message]) + 9,
		process_time_token_end = CHARINDEX('seconds.', em.[message]),	

		cached_bytes_token_start = CHARINDEX('cache used ', em.[message]) + 11,
		cached_bytes_token_end = CHARINDEX('bytes of ', em.[message])
		
	FROM 
		[SSISDB].[catalog].[event_messages] em
	WHERE 	em.[event_name] = 'OnInformation'
	AND		em.[package_name] like @packageNamePattern
	AND		em.[operation_id] = ISNULL(@executionIdFilter, em.[operation_id])
	AND		em.[message] LIKE '%The cache used %'
)
SELECT	
	em.[operation_id],
	em.[message],
	em.[package_name],
	em.[package_path],
	em.[execution_path],		
	[lookup] = SUBSTRING(em.[message], lookup_token_start, lookup_token_end - lookup_token_start)
	,cached_rows = SUBSTRING(em.[message], cached_rows_token_start , cached_rows_token_end - cached_rows_token_start)
	,process_time_secs = SUBSTRING(em.[message], process_time_token_start, process_time_token_end - process_time_token_start)
	,cached_bytes = SUBSTRING(em.[message], cached_bytes_token_start, cached_bytes_token_end - cached_bytes_token_start)
FROM
	cte em
OPTION
	(RECOMPILE)
/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show  package execution	history
NOTES : Also show Dataflow destination informations
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO
-- Filter data by message source name (use % for no filter)
DECLARE @sourceNameFilter AS nvarchar(max) = '%%';
IF (OBJECT_ID('tempdb..#t') IS NOT NULL) DROP TABLE #t;
WITH 
ctePRE AS 
(
	SELECT * FROM catalog.event_messages em 
	WHERE em.event_name IN ('OnPreExecute')
	
), 
ctePOST AS 
(
	SELECT * FROM catalog.event_messages em 
	WHERE em.event_name IN ('OnPostExecute')
)
SELECT
	b.operation_id,
	from_event_message_id = b.event_message_id,
	to_event_message_id = e.event_message_id,
	b.package_path,
	b.message_source_name,
	pre_message_time = b.message_time,
	post_message_time = e.message_time,
	elapsed_time_min = DATEDIFF(mi, b.message_time, COALESCE(e.message_time, SYSDATETIMEOFFSET()))
INTO
	#t
FROM
	ctePRE b
LEFT OUTER JOIN
	ctePOST e ON b.operation_id = e.operation_id AND b.package_name = e.package_name AND b.message_source_id = e.message_source_id
INNER JOIN
	[catalog].executions e2 ON b.operation_id = e2.execution_id
WHERE	b.package_path = '\Package'
AND	b.message_source_name LIKE @sourceNameFilter
AND	e2.status IN (2,7);

SELECT * FROM #t ORDER BY operation_id DESC;

-- Show DataFlow Destination Informations
WITH cte AS
(
	SELECT
		*,
		token_destination_name_start = CHARINDEX(': "', [message]) + 3,
		token_destination_name_end = CHARINDEX('" wrote', [message]),
		token_rows_start = LEN([message]) - CHARINDEX('e', REVERSE([message]), 1) + 3,
		token_rows_end = LEN([message]) - CHARINDEX('r', REVERSE([message]), 1)
	FROM
		[catalog].[event_messages] em
)
SELECT TOP 100
	c.operation_id,
	event_message_id,
	package_name,
	c.message_source_name,
	message_time,
	--destination_name = SUBSTRING([message], token_destination_name_start,  token_destination_name_end - token_destination_name_start),
	loaded_rows = SUBSTRING([message], token_rows_start, token_rows_end - token_rows_start),
	[message]
FROM 
	cte as c 
INNER JOIN	#t t ON c.operation_id = t.operation_id AND c.event_message_id BETWEEN t.from_event_message_id AND t.to_event_message_id
WHERE	subcomponent_name = 'SSIS.Pipeline' 
AND 	[message] like '%rows.%'
ORDER BY 	c.operation_id desc, message_time DESC
/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show  package execution	history Show the latest executed packages
:: NOTES
	For the *first* package in the list, also show
	. Performance of last 15 successful executions
	. Error messages
	. Duplicate lookup messages
	. Memory allocation warnings
	. Low virtual memory warnings
	
*************************************************************************************************************************************************************************************************/
USE SSISDB
GO
-- Filter data by project name (use % for no filter)
DECLARE @projectNamePattern NVARCHAR(100) = '%'

-- Filter data by package name (use % for no filter)
DECLARE @packageNamePattern NVARCHAR(100) = '%'

-- Filter data by execution id (use NULL for no filter)
DECLARE @executionIdFilter BIGINT = NULL
-- Show last 15 executions
SELECT TOP 15
	e.execution_id, 
	e.project_name,
	e.package_name,
	e.project_lsn,
	e.status, 
	status_desc = CASE e.status 
						WHEN 1 THEN 'Created'
						WHEN 2 THEN 'Running'
						WHEN 3 THEN 'Cancelled'
						WHEN 4 THEN 'Failed'
						WHEN 5 THEN 'Pending'
						WHEN 6 THEN 'Ended Unexpectedly'
						WHEN 7 THEN 'Succeeded'
						WHEN 8 THEN 'Stopping'
						WHEN 9 THEN 'Completed'
					END,
	e.start_time,
	e.end_time,
	elapsed_time_min = datediff(mi, e.start_time, e.end_time)
FROM 
	catalog.executions e 
WHERE 	e.project_name LIKE @projectNamePattern
AND	e.package_name LIKE @packageNamePattern
AND	e.execution_id = ISNULL(@executionIdFilter, e.execution_id)
ORDER BY 	e.execution_id DESC
OPTION
	(RECOMPILE)
;

-- Get detailed information for the first package in the list
DECLARE @executionId BIGINT, @packageName NVARCHAR(1000) 
SELECT 
	TOP 1 @executionId = e.execution_id, @packageName = e.package_name 
FROM 
	[catalog].executions e
WHERE 	e.project_name LIKE @projectNamePattern
AND	e.package_name LIKE @packageNamePattern
AND	e.execution_id = ISNULL(@executionIdFilter, e.execution_id)
ORDER BY 	e.execution_id DESC
OPTION
	(RECOMPILE);

-- Show successfull execution history
SELECT TOP 15
e.execution_id, 
	e.project_name,
	e.package_name,
	e.project_lsn,
	e.status, 
	status_desc = CASE e.status 
						WHEN 1 THEN 'Created'
						WHEN 2 THEN 'Running'
						WHEN 3 THEN 'Cancelled'
						WHEN 4 THEN 'Failed'
						WHEN 5 THEN 'Pending'
						WHEN 6 THEN 'Ended Unexpectedly'
						WHEN 7 THEN 'Succeeded'
						WHEN 8 THEN 'Stopping'
						WHEN 9 THEN 'Completed'
					END,
	e.start_time,
	e.end_time,
	elapsed_time_min = datediff(mi, e.start_time, e.end_time)
FROM 	catalog.executions e 
WHERE	e.status IN (2,7)
AND	e.package_name = @packageName
ORDER BY 	e.execution_id DESC;

-- Show error messages
SELECT 	* FROM 	catalog.event_messages em 
WHERE 	em.operation_id = @executionId
AND 	em.event_name = 'OnError'
ORDER BY 	em.event_message_id DESC;

-- Show warnings for duplicate lookups
SELECT 	* FROM 	catalog.event_messages em 
WHERE 	em.operation_id = @executionId
AND 	em.event_name = 'OnWarning' 
AND 	message LIKE '%duplicate%' 
ORDER BY 	em.event_message_id DESC;

-- Show warnings for memory allocations
SELECT 	* FROM 	catalog.event_messages em 
WHERE em.operation_id = @executionId
AND 	em.event_name = 'OnInformation' 
AND 	message LIKE '%memory allocation%' 
ORDER BY 	em.event_message_id DESC;

-- Show warnings for low virtual memory
SELECT 	* FROM 	catalog.event_messages em 
WHERE 	em.operation_id = @executionId
AND 	em.event_name = 'OnInformation' 
AND 	message LIKE '%low on virtual memory%' 
ORDER BY 	em.event_message_id DESC;
/*************************************************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************************************************
PURPOSE: 	Show  package execution	history Show the latest executed packages

*************************************************************************************************************************************************************************************************/
USE SSISDB
GO

Select name, created_time, last_deployed_time FROM [catalog].projects Order by last_deployed_time desc


--Package execution time

SELECT  [project_name] 'Project Name', [package_name] 'Package Name', 
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
 WHERE [Created_time] >= '2016-01-13'	--Filter by Date



 SELECT  [project_name] 'Project Name', [package_name] 'Package Name' ,
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
	DATEDIFF(mi, start_time, end_time) as 'Duration (Min)'
	FROM    [catalog].[executions] (NOLOCK)
 WHERE [Start_Time] >= '2016-01-13'	--Filter by Date
 GROUP by Project_name,Package_Name, Execution_id,Start_Time,End_Time,status



--*******************Pull the Execution Id & Packge Name from above query and use further for filter***************

--Get the list of parameter used in the package and its binded values
SELECT  epv.[parameter_name] 'Parameter Name',epv.[parameter_value] 'Parameter Value',epv.[value_set] 'Value Set', epv.[runtime_override] 'Runtime Overide'
FROM  [catalog].[execution_parameter_values] epv
WHERE  [execution_id] = 71752 


--Task execution sequence
SELECT --*
 package_name 'Pacakge Name', package_path 'Path inside the Package', executable_name 'Task Name'
FROM  [catalog].executables
Where execution_id = 71752
Order by executable_id 


--Task execution status, event name and description 
SELECT  Package_Name' Package Name', Message_Source_Name 'Source Name', Event_Name 'Event Name', Execution_Path 'Path', Message, *
FROM  [catalog].[event_messages] with (nolock)
Where package_name = 'CorePerson.dtsx'	
and message_time >= '2016-01-13'-- Package Name
	And Event_name = 'OnError'					-- Filter by Error Message
Order by event_message_id


SELECT  [project_name] 'Project Name', [package_name] 'Package Name', 
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
FROM [catalog].[executions] with (nolock)
Where project_name = 'PDW_CoreCustCov'	
and [Created_time] >= '2016-01-13'
/*************************************************************************************************************************************************************************************************/
