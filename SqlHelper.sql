/***********************************************************************************************************************
--Sql object reference /dependency check Query
********************************************************************************************************************/
DECLARE @Search varchar(255)
SET @Search='rejectreason'
 
SELECT DISTINCT
    o.name AS Object_Name,o.type_desc
    FROM sys.sql_modules        m 
        INNER JOIN sys.objects  o ON m.object_id=o.object_id
    WHERE m.definition Like '%'+@Search+'%'
    ORDER BY 2,1  

-------------------------------------------------------------------------------------------------------

	select t.name,c.name from sys.tables t
	join sys.columns c
	on c.object_id = t.object_id
	where c.name like '%ReasonRollup%'

------------------------------------------------------------------------------------------------------


IF OBJECT_ID('tempdb..#TEMP2') IS NOT NULL DROP TABLE #TEMP2
CREATE TABLE #TEMP2  (SPNAMES1 VARCHAR(max), SPtype varchar(max))
INSERT INTO #TEMP2 
exec sp_depends Core_table –Table Name

DECLARE @TABLE table (SP text)

IF OBJECT_ID('tempdb..#TEMP') IS NOT NULL DROP TABLE #TEMP
CREATE TABLE #TEMP  (ID BIGINT Identity,SPNAMES VARCHAR(max))

INSERT INTO #TEMP (SPNAMES)
SELECT name FROM dbo.sysobjects WHERE (type = 'P') AND NAME IN (SELECT REPLACE(SPNAMES1,'dbo.','') FROM #TEMP2 )

DECLARE @SPNAMES varchar(max)
DECLARE @COUNT BIGINT
SELECT @COUNT=count(*) FROM #TEMP
DECLARE @i INT=1
WHILE (@COUNT>=@i)
BEGIN
SELECT @SPNAMES=SPNAMES FROM #TEMP WHERE ID=@i

INSERT INTO @TABLE
exec SP_helptext @SPNAMES
SET @i=@i+1
END
SELECT * from @TABLE
/********************************************************************************************************************/
---------------------------------------------------------------------------------------------------------

--- Specific Scorelist--------------
SELECT MemberGenKey,
ScoreListModelName.ScoreModelName.value('.','Varchar(50)') as ScoreModelName
FROM tablename X
CROSS APPLY X.ResponseXML.nodes('//ScoreList/Score/@ScoreModelName') AS ScoreListModelName(ScoreModelName)
WHERE CycleID=5279
and ScoreListModelName.ScoreModelName.value('.','Varchar(50)')='HIGH RISK PREGNANCY COMMERCIAL MODEL SCORE'


--- Specific Outreach--------------

SELECT top 10 MemberGenKey,RULEACTIONlIST.node.query('.') As RuleActionList,
RuleactionType.ActionType.value('.','Varchar(50)') as RuleactionType
FROM tablename X
CROSS APPLY X.ResponseXML.nodes('//RuleActionList') AS RULEACTIONlIST(node)
CROSS APPLY X.ResponseXML.nodes('//RuleActionList/RuleAction/@ActionType') AS RuleactionType(ActionType)
WHERE x.ProcessType='Authorization'
and RuleactionType.ActionType.value('.','Varchar(50)') like '%PersistOutreach%'

--- Specific Outreach--------------


SELECT MemberGenKey,RULEACTIONlIST.node.query('.') As RuleActionList ,ParticipationList.node.query('.') as ParticipationList,
ParticipationListEndDate.EndDate.value('.','DateTime') as ParticipationEnddt,CustinterventionList.node.query('.'),
RuleactionType.ActionType.value('.','Varchar(50)') as RuleactionType
FROM tablename X
CROSS APPLY X.ResponseXML.nodes('//RuleActionList') AS RULEACTIONlIST(node)
CROSS APPLY X.ResponseXML.nodes('//ParticipationList') AS ParticipationList(node)
CROSS APPLY X.ResponseXML.nodes('//ParticipationList/Participation/@EndDate') AS ParticipationListEndDate(EndDate)
CROSS APPLY X.ResponseXML.nodes('//CustomerInterventionList') AS CustinterventionList(node)
CROSS APPLY X.ResponseXML.nodes('//RuleActionList/RuleAction/@ActionType') AS RuleactionType(ActionType)
WHERE ProcessType='Assessment'
and InsTs>'2017-07-09 04:38:33.327'
and RuleactionType.ActionType.value('.','Varchar(50)') like '%PersistNotification%'
order by InsTs desc

------- Specific referral-----------------------------------------------------------------------------------

SELECT MemberGenKey,RULEACTIONlIST.node.query('.') As RuleActionList
,RuleactionType.ActionType.value('.','Varchar(50)') as RuleactionType
,ActionParamList.CaseType.value('.','Varchar(50)') as CaseType
FROM tablename X with(nolock)
CROSS APPLY X.ResponseXML.nodes('//RuleActionList') AS RULEACTIONlIST(node)
OUTER APPLY X.ResponseXML.nodes('//RuleActionList/RuleAction/@ActionType') AS RuleactionType(ActionType)
OUTER APPLY X.ResponseXML.nodes('//ActionParamList/ActionParam/@Value') AS ActionParamList(CaseType)
WHERE MemberGenKey IN (7732204611923,5153204412717,1123204447717,1172504244317)
AND InsTs>'2018-01-24'
and (ActionParamList.CaseType.value('.','Varchar(50)')='Senior Post Discharge' or ActionParamList.CaseType.value('.','Varchar(50)')is null)
order by MemberGenKey desc

------- Specific referral-----------------------------------------------------------------------------------



--usp_SHARED_PartDtl_List --Participation List
--CORE_CPBOM_PreComputed_CustInterventionList -- Custintervlist
SELECT MemberGenKey,RULEACTIONlIST.node.query('.') As RuleActionList ,ParticipationList.node.query('.') as ParticipationList,
ParticipationListEndDate.EndDate.value('.','DateTime') as ParticipationEnddt,CustinterventionList.node.query('.')
FROM tablename X
CROSS APPLY X.ResponseXML.nodes('//RuleActionList') AS RULEACTIONlIST(node)
CROSS APPLY X.ResponseXML.nodes('//ParticipationList') AS ParticipationList(node)
CROSS APPLY X.ResponseXML.nodes('//ParticipationList/Participation/@EndDate') AS ParticipationListEndDate(EndDate)
CROSS APPLY X.ResponseXML.nodes('//CustomerInterventionList') AS CustinterventionList(node)
WHERE CycleID=5178
and ParticipationListEndDate.EndDate.value('.','DateTime')>GETDATE()
 and MemberGenKey in (145489765436216)

 -------------------------------------------------------------------------------------------------------


 SELECT MemberGenKey,MemberDetail.BirthDate.value('.','Varchar(50)') as DOB
FROM tablename X
CROSS APPLY X.ResponseXML.nodes('//MemberDetail/@BirthDate') AS MemberDetail(BirthDate)
WHERE CycleID=8399
and MemberGenKey in (9501004675722,86004664522,3431004666543,1401004662822,7121004657443,6171004655522,5720104664422,5494004666543,521004621122,2292004663222)

-----------------------------------------------------------------------------------------------

SELECT MemberGenKey,RULEACTIONlIST.node.query('.') As RuleActionList ,ParticipationList.node.query('.') as ParticipationList,
ParticipationListEndDate.EndDate.value('.','DateTime') as EndDt,
CustomerInterventionList.node.query('.') as CustomerInterventionList
--,ParticipationList_EndDt.node.query('.') as Enddt
FROM tablename X
CROSS APPLY X.ResponseXML.nodes('//RuleActionList') AS RULEACTIONlIST(node)
CROSS APPLY X.ResponseXML.nodes('//ParticipationList') AS ParticipationList(node)
CROSS APPLY X.ResponseXML.nodes('//ParticipationList/Participation/@EndDate') AS ParticipationListEndDate(EndDate)
CROSS APPLY X.ResponseXML.nodes('//CustomerInterventionList') AS CustomerInterventionList(node)
WHERE CycleID=33236
and MemberGenKey in  (5404156717)


/***********************************************************************************************************************
--Delete Query
********************************************************************************************************************/
;WITH tblReferral_tmp(CycleID,ModelExecutionID,MbrPersGenKey,CreateDateTime,ScoreModelName,RowNum) --151963
	AS (
	SELECT CycleID,ModelExecutionID,MbrPersGenKey,CreateDateTime,ScoreModelName,
	ROW_NUMBER()OVER(PARTITION BY CycleID,ModelExecutionID,MbrPersGenKey,CreateDateTime,ScoreModelName
	ORDER BY CycleID,ModelExecutionID,MbrPersGenKey,CreateDateTime,ScoreModelName)AS RANK 
	FROM tablename WITH(NOLOCK) 
	where CreateDateTime >='2017-03-20' and CreateDateTime <= '2017-05-26'
     and  ScoreModelName in('NMPM PLUS MEDICARE RISK SCORE')	)
	
	
	DELETE from tblReferral_tmp
	WHERE RowNum <> 1 


	--cast(coalesce(nullif([CaseReason],''),'0') as INT) 

/***********************************************************************************************************************
-- Delete all SQL message in TargetQueue Queue
-- Note this should be run only if your working on that particular environment
********************************************************************************************************************/
declare @c uniqueidentifier
while(1=1)
begin
    select top 1 @c = conversation_handle from dbo.TargetQueue
    if (@@ROWCOUNT = 0)
    break
    end conversation @c with cleanup
end

/***********************************************************************************************************************

Last Executed Query

********************************************************************************************************************/

SELECT TOP 20
SUBSTRING (qt.text,(qs.statement_start_offset/2) + 1,
((CASE WHEN qs.statement_end_offset = -1
THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
ELSE qs.statement_end_offset
END - qs.statement_start_offset)/2) + 1) AS [Individual Query]
, qt.text AS [Parent Query]
, DB_NAME(qt.dbid) AS DatabaseName
, qp.query_plan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
WHERE OBJECT_NAME(qt.objectid) IN('adfsd','asdfasdf','asdf',
'asdfsd','abvcd','asdf')

ORDER BY qs.last_execution_time DESC 

/***********************************************************************************************************************

Columns to row for id Query

********************************************************************************************************************/

declare @MAXCOUNT varchar(max)=286551
declare @maxColumnCount int=0;
 declare @Query varchar(max)='';
 declare @DynamicColumnName nvarchar(MAX)='';
 declare @varname nvarchar(MAX)='';
 DECLARE @CURRENTDATE DATETIME = (SELECT CAST (GETDATE()-1 AS DATE))
DECLARE @DATE DATETIME = (SELECT CAST (GETDATE() AS DATE))



DECLARE @TotalRows TABLE( row_count int,name varchar(100))
 Delete from  @TotalRows
 INSERT INTO @TotalRows (row_count,name)
 SELECT (ROW_NUMBER() OVER(PARTITION BY SourceEMMECommID order by SourceEMMECommID Desc)) as row_no,VariableName
 FROM tablename WITH(NOLOCK) WHERE SourceEMMECommID=  @MAXCOUNT
 AND INS_TS>= @CURRENTDATE
 AND INS_TS< @DATE

-- Get the MAX value from @TotalRows table
 set @maxColumnCount= (select max(row_count) from @TotalRows)
 
-- loop to create Dynamic max/case and store it into local variable 
 DECLARE @cnt INT = 1;
 WHILE @cnt <= @maxColumnCount
 BEGIN
   set @varname=(select name from @TotalRows where row_count=@cnt)
   set @DynamicColumnName= @DynamicColumnName + ', Max(case when row_no= '+cast(@cnt as varchar)+' then VariableValue end )'+@varname+''
   SET @cnt = @cnt + 1;
END;


-- Create dynamic CTE and store it into local variable @query 
  set @Query='
     with CTE_tbl as
     (
       SELECT SourceEMMECommID,VariableName,VariableValue,
       ROW_NUMBER() OVER(PARTITION BY SourceEMMECommID order by SourceEMMECommID Desc) as row_no
       FROM tablename WITH(NOLOCK)
	  WHERE SourceEMMECommID='+@MAXCOUNT+'
      )
  select
     SourceEMMECommID
     '+@DynamicColumnName+'
     FROM CTE_tbl
     group By SourceEMMECommID'

-- Execute the Query
 --INSERT  INTO @RESULT
 execute (@Query)
 
/***********************************************************************************************************************

Columns to row for 

********************************************************************************************************************/

 declare @maxColumnCount int=0;
 declare @Query varchar(max)='';
 declare @DynamicColumnName nvarchar(MAX)='';
 declare @varname nvarchar(MAX)='';
 DECLARE @CURRENTDATE DATETIME = (SELECT CAST (GETDATE()-1 AS DATE))
DECLARE @DATE DATETIME = (SELECT CAST (GETDATE() AS DATE))

DECLARE @RESULT TABLE
(SourceEMMECommID varchar(max) NULL,
LetterheadCode varchar(max) NULL,
ProviderDueDate varchar(max) NULL,
ProviderDueTime  varchar(max) NULL,
ProviderMarketTimeZone varchar(max) NULL,
LetterRequestDate varchar(max) NULL,
SignatureFullName varchar(max) NULL,
SignatureReturnFaxNumber varchar(max) NULL,
SignaturePhoneNumber varchar(max) NULL,
ClaimMedicalContactName varchar(max) NULL,
ClaimHumanaAssociatePhoneNumber varchar(max) NULL,
ClaimMedicalRecordInformation varchar(max) NULL
)
 declare @maxSourceemmcomid int= (SELECT MAX(SourceEMMECommID) FROM Core_EMME_CommRec WITH(NOLOCK)
						    WHERE INS_TS>= @CURRENTDATE
						    AND INS_TS< @DATE);

 declare @MAXCOUNT varchar(max)= (SELECT MIN(SourceEMMECommID) FROM Core_EMME_CommRec WITH(NOLOCK)
						    WHERE INS_TS>= @CURRENTDATE
						    AND INS_TS< @DATE);

 SET @MAXCOUNT ='286552'
 WHILE @MAXCOUNT <= @maxSourceemmcomid
 BEGIN
-- table type variable that store all values of column row no
 DECLARE @TotalRows TABLE( row_count int,name varchar(100))
 Delete from  @TotalRows
 INSERT INTO @TotalRows (row_count,name)
 SELECT (ROW_NUMBER() OVER(PARTITION BY SourceEMMECommID order by SourceEMMECommID Desc)) as row_no,VariableName
 FROM tablename WITH(NOLOCK) WHERE SourceEMMECommID= @MAXCOUNT
 AND INS_TS>= @CURRENTDATE
 AND INS_TS< @DATE

-- Get the MAX value from @TotalRows table
 set @maxColumnCount= (select max(row_count) from @TotalRows)
 
-- loop to create Dynamic max/case and store it into local variable 
 DECLARE @cnt INT = 1;
 WHILE @cnt <= @maxColumnCount
 BEGIN
   set @varname=(select name from @TotalRows where row_count=@cnt)
   set @DynamicColumnName= @DynamicColumnName + ', Max(case when row_no= '+cast(@cnt as varchar)+' then VariableValue end )'+@varname+''
   SET @cnt = @cnt + 1;
END;


-- Create dynamic CTE and store it into local variable @query 
  set @Query='
     with CTE_tbl as
     (
       SELECT SourceEMMECommID,VariableName,VariableValue,
       ROW_NUMBER() OVER(PARTITION BY SourceEMMECommID order by SourceEMMECommID Desc) as row_no
       FROM tablename WITH(NOLOCK)
	  WHERE SourceEMMECommID='+@MAXCOUNT+'
      )
  select
     SourceEMMECommID
     '+@DynamicColumnName+'
     FROM CTE_tbl
     group By SourceEMMECommID'

-- Execute the Query
 --INSERT  INTO @RESULT
 execute (@Query)
 
 --SELECT * FROM @RESULT
 
 SET @MAXCOUNT = @MAXCOUNT + 1;
END;
