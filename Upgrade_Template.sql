SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id = OBJECT_ID('tempdb..#tmpErrors')) DROP TABLE #tmpErrors
GO
CREATE TABLE #tmpErrors (Error INT)
GO
SET XACT_ABORT ON
GO
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO
BEGIN TRANSACTION
GO

----------------------------------------
IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id = OBJECT_ID('tempdb..#Description')) DROP TABLE #Description
GO
CREATE TABLE #Description ([Description] NVARCHAR(500))
GO
----------------------------------------
----------------------------------------

@SCRIPT_CONTENT@
GO

----------------------------------------
----------------------------------------

IF @@TRANCOUNT = 0
	PRINT 'The database update failed'
ELSE
BEGIN
	IF @@ERROR <> 0 OR EXISTS (SELECT 1 FROM #tmpErrors)
	BEGIN
		ROLLBACK TRANSACTION
		PRINT 'The database update failed'
	END
	ELSE
	BEGIN
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

		COMMIT TRANSACTION
			   
		PRINT '----- Script action: ' + @Description + ' -----'
		PRINT '----- The database update succeeded -----'   
	END
END
GO

DROP TABLE #tmpErrors