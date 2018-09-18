use SSISDB
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
