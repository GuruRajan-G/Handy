--select UniqueIDEMMEOutreach,DataHierarchy.ToString() as DataHierarchyString,DataHierarchy,GroupName,PropertyName,PropertyValue from EMMEJSONRequestHier


--truncate table EMMEJSONRequestHier


--sp_depends EMMEJSONRequestHier

--SELECT * FROM [udfEMMEJSONRequestHierGetAllChildrenByUnique] (2,'EmmeRequest','Parent')


-- SELECT E.DataHierarchy
--    FROM EMMEJSONRequestHier E
--    WHERE E.UniqueIDEMMEOutreach = '2'
--    AND E.GroupName='EmmeRequest'
--    AND E.PropertyName='PARENT'



--    select UniqueIDEMMEOutreach,DataHierarchy.ToString() as DataHierarchyString,DataHierarchy,GroupName,PropertyName,PropertyValue from EMMEJSONRequestHier

     SELECT e.UniqueIDEMMEOutreach    AS UniqueIDEMMEOutreach
            , E.GroupName      AS GroupName
            , E.PropertyName       AS PropertyName
            , E.PropertyValue         AS PropertyValue
            , E.DataHierarchy.ToString()       AS ChildHierarchy
            , E.DataHierarchy.GetLevel()    AS Level
    FROM EMMEJSONRequestHier E
    WHERE E.DataHierarchy.GetAncestor(1) = (SELECT E.DataHierarchy FROM EMMEJSONRequestHier E WHERE E.UniqueIDEMMEOutreach = '1'
								    AND E.GroupName='EmmeRequest' AND E.PropertyName='PARENT')

    SELECT e.UniqueIDEMMEOutreach    AS UniqueIDEMMEOutreach
            , E.GroupName      AS GroupName
            , E.PropertyName       AS PropertyName
            , E.PropertyValue         AS PropertyValue
            , E.DataHierarchy.ToString()       AS ChildHierarchy
            , E.DataHierarchy.GetLevel()    AS Level
    FROM EMMEJSONRequestHier E
    WHERE E.DataHierarchy.GetAncestor(1) IN (SELECT E.DataHierarchy FROM EMMEJSONRequestHier E WHERE E.UniqueIDEMMEOutreach = '1'
								    AND E.GroupName='EmmeFulfillmentRequestList' AND E.PropertyName='PARENT')

    SELECT e.UniqueIDEMMEOutreach    AS UniqueIDEMMEOutreach
            , E.GroupName      AS GroupName
            , E.PropertyName       AS PropertyName
            , E.PropertyValue         AS PropertyValue
            , E.DataHierarchy.ToString()       AS ChildHierarchy
            , E.DataHierarchy.GetLevel()    AS Level
    FROM EMMEJSONRequestHier E
    WHERE E.DataHierarchy.GetAncestor(1) IN (SELECT E.DataHierarchy FROM EMMEJSONRequestHier E WHERE E.UniqueIDEMMEOutreach = '1'
								    AND E.GroupName='Recipient' AND E.PropertyName='PARENT')

  --Recipient Childrens------------------------------------------------------------------------------------------------
   
   Declare @tem table
   (
   hierarchy hierarchyid
   )

   insert into @tem
   SELECT E.DataHierarchy FROM EMMEJSONRequestHier E
   WHERE E.DataHierarchy.GetAncestor(1) IN (SELECT E.DataHierarchy FROM EMMEJSONRequestHier E WHERE E.UniqueIDEMMEOutreach = '1'
								    AND E.GroupName='Recipient' AND E.PropertyName='PARENT')

   
   WHILE EXISTS ( SELECT 1 FROM @tem)
   BEGIN
	   DECLARE @hier hierarchyid

	   SELECT @hier =(SELECT TOP 1 hierarchy from @tem )

	  SELECT e.UniqueIDEMMEOutreach    AS UniqueIDEMMEOutreach
			 , E.GroupName      AS GroupName
			 , E.PropertyName       AS PropertyName
			 , E.PropertyValue         AS PropertyValue
			 , E.DataHierarchy.ToString()       AS ChildHierarchy
			 , E.DataHierarchy.GetLevel()    AS Level
	   FROM EMMEJSONRequestHier E
	   WHERE E.DataHierarchy.GetAncestor(1) = @hier

	   DELETE TOP (1) from  @tem
END
--Recipient Childrens------------------------------------------------------------------------------------------------

--VariableData
   
    SELECT e.UniqueIDEMMEOutreach    AS UniqueIDEMMEOutreach
            , E.GroupName      AS GroupName
            , E.PropertyName       AS PropertyName
            , E.PropertyValue         AS PropertyValue
            , E.DataHierarchy.ToString()       AS ChildHierarchy
            , E.DataHierarchy.GetLevel()    AS Level
    FROM EMMEJSONRequestHier E
    WHERE E.DataHierarchy.GetAncestor(1) IN (SELECT E.DataHierarchy FROM EMMEJSONRequestHier E WHERE E.UniqueIDEMMEOutreach = '1'
								    AND E.GroupName='VariableData' AND E.PropertyName='PARENT')

 --VariableData Childrens------------------------------------------------------------------------------------------------
   
   Declare @tem table
   (
   hierarchy hierarchyid
   )

   insert into @tem
   SELECT E.DataHierarchy FROM EMMEJSONRequestHier E
   WHERE E.DataHierarchy.GetAncestor(1) IN (SELECT E.DataHierarchy FROM EMMEJSONRequestHier E WHERE E.UniqueIDEMMEOutreach = '1'
								    AND E.GroupName='VariableData' AND E.PropertyName='PARENT')

   
   WHILE EXISTS ( SELECT 1 FROM @tem)
   BEGIN
	   DECLARE @hier hierarchyid

	   SELECT @hier =(SELECT TOP 1 hierarchy from @tem )

	  SELECT e.UniqueIDEMMEOutreach    AS UniqueIDEMMEOutreach
			 , E.GroupName      AS GroupName
			 , E.PropertyName       AS PropertyName
			 , E.PropertyValue         AS PropertyValue
			 , E.DataHierarchy.ToString()       AS ChildHierarchy
			 , E.DataHierarchy.GetLevel()    AS Level
	   FROM EMMEJSONRequestHier E
	   WHERE E.DataHierarchy.GetAncestor(1) = @hier

	   DELETE TOP (1) from  @tem
END
--VariableData Childrens------------------------------------------------------------------------------------------------
 
 --Claim
   
    SELECT e.UniqueIDEMMEOutreach    AS UniqueIDEMMEOutreach
            , E.GroupName      AS GroupName
            , E.PropertyName       AS PropertyName
            , E.PropertyValue         AS PropertyValue
            , E.DataHierarchy.ToString()       AS ChildHierarchy
            , E.DataHierarchy.GetLevel()    AS Level
    FROM EMMEJSONRequestHier E
    WHERE E.DataHierarchy.GetAncestor(1) IN (SELECT E.DataHierarchy FROM EMMEJSONRequestHier E WHERE E.UniqueIDEMMEOutreach = '1'
								    AND E.GroupName='Claim' AND E.PropertyName='PARENT')

 --Claim Childrens------------------------------------------------------------------------------------------------
   
   Declare @tem table
   (
   hierarchy hierarchyid
   )

   insert into @tem
   SELECT E.DataHierarchy FROM EMMEJSONRequestHier E
   WHERE E.DataHierarchy.GetAncestor(1) IN (SELECT E.DataHierarchy FROM EMMEJSONRequestHier E WHERE E.UniqueIDEMMEOutreach = '1'
								    AND E.GroupName='Claim' AND E.PropertyName='PARENT')

   
   WHILE EXISTS ( SELECT 1 FROM @tem)
   BEGIN
	   DECLARE @hier hierarchyid

	   SELECT @hier =(SELECT TOP 1 hierarchy from @tem )

	  SELECT e.UniqueIDEMMEOutreach    AS UniqueIDEMMEOutreach
			 , E.GroupName      AS GroupName
			 , E.PropertyName       AS PropertyName
			 , E.PropertyValue         AS PropertyValue
			 , E.DataHierarchy.ToString()       AS ChildHierarchy
			 , E.DataHierarchy.GetLevel()    AS Level
	   FROM EMMEJSONRequestHier E
	   WHERE E.DataHierarchy.GetAncestor(1) = @hier

	   DELETE TOP (1) from  @tem
END
--Claim Childrens------------------------------------------------------------------------------------------------

--ClaimMedical
   
    SELECT e.UniqueIDEMMEOutreach    AS UniqueIDEMMEOutreach
            , E.GroupName      AS GroupName
            , E.PropertyName       AS PropertyName
            , E.PropertyValue         AS PropertyValue
            , E.DataHierarchy.ToString()       AS ChildHierarchy
            , E.DataHierarchy.GetLevel()    AS Level
    FROM EMMEJSONRequestHier E
    WHERE E.DataHierarchy.GetAncestor(1) IN (SELECT E.DataHierarchy FROM EMMEJSONRequestHier E WHERE E.UniqueIDEMMEOutreach = '1'
								    AND E.GroupName='ClaimMedicalRecordList' AND E.PropertyName='PARENT')

 --ClaimMedicalRecordList Childrens------------------------------------------------------------------------------------------------
   
   Declare @tem table
   (
   hierarchy hierarchyid
   )

   insert into @tem
   SELECT E.DataHierarchy FROM EMMEJSONRequestHier E
   WHERE E.DataHierarchy.GetAncestor(1) IN (SELECT E.DataHierarchy FROM EMMEJSONRequestHier E WHERE E.UniqueIDEMMEOutreach = '1'
								    AND E.GroupName='ClaimMedicalRecordList' AND E.PropertyName='PARENT')

   
   WHILE EXISTS ( SELECT 1 FROM @tem)
   BEGIN
	   DECLARE @hier hierarchyid

	   SELECT @hier =(SELECT TOP 1 hierarchy from @tem )

	  SELECT e.UniqueIDEMMEOutreach    AS UniqueIDEMMEOutreach
			 , E.GroupName      AS GroupName
			 , E.PropertyName       AS PropertyName
			 , E.PropertyValue         AS PropertyValue
			 , E.DataHierarchy.ToString()       AS ChildHierarchy
			 , E.DataHierarchy.GetLevel()    AS Level
	   FROM EMMEJSONRequestHier E
	   WHERE E.DataHierarchy.GetAncestor(1) = @hier

	   DELETE TOP (1) from  @tem
END
--ClaimMedicalRecordList Childrens------------------------------------------------------------------------------------------------

--ClaimMedicalRecordProcedureCodeList
   
    SELECT e.UniqueIDEMMEOutreach    AS UniqueIDEMMEOutreach
            , E.GroupName      AS GroupName
            , E.PropertyName       AS PropertyName
            , E.PropertyValue         AS PropertyValue
            , E.DataHierarchy.ToString()       AS ChildHierarchy
            , E.DataHierarchy.GetLevel()    AS Level
    FROM EMMEJSONRequestHier E
    WHERE E.DataHierarchy.GetAncestor(1) IN (SELECT E.DataHierarchy FROM EMMEJSONRequestHier E WHERE E.UniqueIDEMMEOutreach = '1'
								    AND E.GroupName='ClaimMedicalRecordProcedureCodeList' AND E.PropertyName='PARENT')

 --ClaimMedicalRecordProcedureCodeList Childrens------------------------------------------------------------------------------------------------
   
   Declare @tem table
   (
   hierarchy hierarchyid
   )

   insert into @tem
   SELECT E.DataHierarchy FROM EMMEJSONRequestHier E
   WHERE E.DataHierarchy.GetAncestor(1) IN (SELECT E.DataHierarchy FROM EMMEJSONRequestHier E WHERE E.UniqueIDEMMEOutreach = '1'
								    AND E.GroupName='ClaimMedicalRecordProcedureCodeList' AND E.PropertyName='PARENT')

   
   WHILE EXISTS ( SELECT 1 FROM @tem)
   BEGIN
	   DECLARE @hier hierarchyid

	   SELECT @hier =(SELECT TOP 1 hierarchy from @tem )

	  SELECT e.UniqueIDEMMEOutreach    AS UniqueIDEMMEOutreach
			 , E.GroupName      AS GroupName
			 , E.PropertyName       AS PropertyName
			 , E.PropertyValue         AS PropertyValue
			 , E.DataHierarchy.ToString()       AS ChildHierarchy
			 , E.DataHierarchy.GetLevel()    AS Level
	   FROM EMMEJSONRequestHier E
	   WHERE E.DataHierarchy.GetAncestor(1) = @hier

	   DELETE TOP (1) from  @tem
END
--ClaimMedicalRecordProcedureCodeList Childrens------------------------------------------------------------------------------------------------
