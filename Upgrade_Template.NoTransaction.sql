IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#Description')) DROP TABLE #Description
GO
CREATE TABLE #Description ([Description] NVARCHAR(500))
GO
----------------------------------------
----------------------------------------

@SCRIPT_CONTENT@
GO

----------------------------------------
----------------------------------------

DECLARE @Description NVARCHAR(500)
SELECT @Description = [Description] FROM #Description
IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#Description')) DROP TABLE #Description

-- Marker script for bringing the database up to version
INSERT INTO [dbo].[SchemaChanges]
       ([MajorReleaseNumber]
       ,[MinorReleaseNumber]
       ,[BuildReleaseNumber]
       ,[RevisionReleaseNumber]
       ,[ScriptName]
       ,[Description])
VALUES
       ('@MAJOR@'
       ,'@MINOR@'
       ,'@BUILD@'
       ,'@REVISION@'
       ,'@SCRIPT_NAME@'
	   ,@Description)
GO