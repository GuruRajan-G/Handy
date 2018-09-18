/*****************************************************************************************************************************************************************/
/*Server: LOUSISWTS366*/
/*Folder: Atlas*/
/*SSIS Environment: PDW_CoreGroupEligibility*/
/*Script to turn SSIS Environment Variables*/
/*****************************************************************************************************************************************************************/
USE [SSISDB]

declare @ErrorMessage varchar(200),
@ErrorSeverity int,
@ErrorState int,
@SSISServername varchar(max)='$(SSISServername)',
@ProjectName varchar(max)='$(ProjectDropdownvalue)',
@FolderName varchar(max)='$(FolderName)',
@VariableName varchar(max)='$(VariableName)',
@VariableType varchar(max)='$(VariableType)',
@VariableValue varchar(max)='$(VariableValue)'

/*Begin Script*/
Begin Try


declare @servername nvarchar(50)
select @servername=@@servername
if(@servername!=@SSISServername)
RAISERROR('Please execute the script on the right server',16,1)
ELSE
BEGIN

--SELECT @testingvalue AS rESULT

IF NOT EXISTS( select p.project_id as projID from catalog.projects  P  
			join catalog.folders F on F.folder_id=P.folder_id
			 WHERE P.name=@ProjectName and F.name=@FolderName)
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
			WHERE env.name = @ProjectName AND fold.name = @FolderName)
BEGIN
EXEC [SSISDB].[catalog].[Create_environment] @folder_name =@FolderName,@environment_description= N'', @environment_name = @ProjectName;
END
 
/*Create environment reference*/
IF NOT EXISTS( select E.environment_id as environment_id from catalog.projects  P  
			join catalog.folders F on F.folder_id=P.folder_id
			join catalog.environments e on e.folder_id=P.folder_id
								    AND E.name=P.name
			 WHERE P.name=@ProjectName and F.name=@FolderName)
 BEGIN
 DECLARE @reference_id bigint; 
 EXECUTE [catalog].[create_environment_reference]  @FolderName,@ProjectName,@ProjectName,'R',null,@reference_id=@reference_id OUTPUT
 END

IF NOT EXISTS(SELECT TOP 1 1 FROM  catalog.environments ENV WITH(NOLOCK) 
JOIN catalog.environment_variables EVAR WITH(NOLOCK) ON EVAR.environment_id=ENV.environment_id
WHERE ENV.NAME=@ProjectName
AND EVAR.name= @VariableName)

BEGIN 

SET @StringValue = @VariableValue

--SET @StringValue = N'Data Source=Sqlserver;User ID=Prod;Password=PROD;Initial Catalog=PROD;Provider=SQLNCLI11.1;Auto Translate=False;'
 EXECUTE [catalog].[create_environment_variable]  @FolderName,@ProjectName,@VariableName ,@VariableType ,False ,@StringValue,'';


END

ELSE

BEGIN

SET @StringValue = @VariableValue
/*update existing env variable value*/
 EXECUTE [catalog].[set_environment_variable_Value]  @FolderName,@ProjectName,@VariableName,@StringValue

END

/*update existing env variable description*/
IF NOT EXISTS(SELECT TOP 1 1 FROM  catalog.environments ENV WITH(NOLOCK) 
			 JOIN catalog.environment_variables EVAR WITH(NOLOCK) ON EVAR.environment_id=ENV.environment_id
			 WHERE ENV.NAME=@ProjectName
			 AND EVAR.name=@VariableName)
BEGIN

 EXECUTE [catalog].[set_environment_variable_property]  @FolderName,@ProjectName,@VariableName ,'description',@VariableName 

END
ELSE
BEGIN

/*update existing env variable protection*/
 EXECUTE [catalog].[set_environment_variable_protection] @FolderName,@ProjectName,@VariableName,False
END


/*set paramter to env variable*/
 EXECUTE  [catalog].[set_object_parameter_value] 20,@FolderName,@ProjectName,@VariableName,@VariableName,@ProjectName,'R'


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

