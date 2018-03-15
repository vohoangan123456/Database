INSERT INTO #Description VALUES ('modify activity')
GO

IF OBJECT_ID('[Calendar].[ActivitiesDeleteCompletely]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[ActivitiesDeleteCompletely] AS SELECT 1')
GO
ALTER PROCEDURE [Calendar].[ActivitiesDeleteCompletely] 
    @ActivityIds AS [dbo].[Item] READONLY
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
	
		DECLARE @RecurrencyIds TABLE(
			RecurrencyId INT
		);
		
		INSERT INTO @RecurrencyIds(RecurrencyId)
			SELECT RecurrenceId
			FROM [Calendar].[Activities]
			WHERE RecurrenceId IS NOT NULL
			AND EXISTS (SELECT * FROM @ActivityIds WHERE Id = ActivityId)
			
		DECLARE @DeletedActivityIds TABLE(
			Id INT
		);
		
		INSERT INTO @DeletedActivityIds(Id)
			SELECT Id
			FROM @ActivityIds
		
		INSERT INTO @DeletedActivityIds(Id)
			SELECT src.ActivityId
			FROM [Calendar].[Activities] src
			WHERE EXISTS (SELECT targ.* FROM @RecurrencyIds targ WHERE targ.RecurrencyId = src.RecurrenceId)
	
        DELETE FROM
            [Calendar].[ActivityResponsibles]
        WHERE
            ActivityId IN (SELECT Id FROM @DeletedActivityIds)
			
        DELETE FROM
            [Calendar].[ActivityTasks]
        WHERE
            ActivityId IN (SELECT Id FROM @DeletedActivityIds)
			
        DELETE FROM
            [Calendar].[ActivityDocuments]
        WHERE
            ActivityId IN (SELECT Id FROM @DeletedActivityIds)
			
        DELETE FROM
            tblAcl
        WHERE
            iApplicationId = 160
            AND iEntityId IN (SELECT Id FROM @DeletedActivityIds)
			
        DELETE FROM
            AnnualCycleActivities
        WHERE
            ActivityId IN (SELECT Id FROM @DeletedActivityIds)		
			
        DELETE FROM
            [Calendar].[Activities]
        WHERE
            ActivityId IN (SELECT Id FROM @DeletedActivityIds)
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK
    DECLARE @ErrorMessage nvarchar(MAX), @ErrorNumber int, @ErrorSeverity int, @ErrorState int, @ErrorLine int
    SELECT @ErrorMessage = N'Error %d, Line %d, Message: ' + ERROR_MESSAGE(), @ErrorNumber = ERROR_NUMBER(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(), @ErrorLine = ERROR_LINE();
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber,@ErrorLine);
END CATCH
END
GO

