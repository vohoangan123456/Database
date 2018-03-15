INSERT INTO #Description VALUES ('Modify SP for annual cycle')
GO

IF OBJECT_ID('[Calendar].[AnnualCycleInsert]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[AnnualCycleInsert] AS SELECT 1')
GO
ALTER PROCEDURE [Calendar].[AnnualCycleInsert]
(
	@Name NVARCHAR(100) ,
	@Description NVARCHAR(4000) ,
	@Partitioning TINYINT,
	@Year INT,
	@ViewType TINYINT,
	@CreatedBy INT = NULL
)
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	BEGIN TRAN
		BEGIN TRY
			--function body
			INSERT INTO Calendar.AnnualCycles
			(Name, [Description], Partitioning, [Year], ViewType, IsInactive, IsDeleted, CreatedBy, CreatedDate)
			VALUES 
			(@Name, @Description, @Partitioning, @Year, @ViewType, 1, 0, @CreatedBy, GETUTCDATE())
			--function body
			IF @@TRANCOUNT > 0
			COMMIT TRAN;
		END TRY
		BEGIN CATCH	
			DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE(), 
				@ErrorSeverity INT = ERROR_SEVERITY(), 
				@ErrorState INT = ERROR_STATE();
			IF @@TRANCOUNT > 0
				ROLLBACK TRAN
			RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
		END CATCH
	SELECT SCOPE_IDENTITY();	
END	
 GO
 
IF OBJECT_ID('[Calendar].[GetUpcomingActivitiesForPlugin]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[GetUpcomingActivitiesForPlugin] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[GetUpcomingActivitiesForPlugin]
 @Day INT
AS
BEGIN

    DECLARE @StartDate DATE = DATEADD(dd, @Day, DATEDIFF(dd, 0, GETDATE()));
    SELECT
        a.ActivityId,
        a.Name,
        a.Description,
        a.StartDate,
        a.EndDate,
        a.ResponsibleId,
        a.CreatedBy
    FROM
        Calendar.Activities a
    WHERE
        DATEADD(dd, 0, DATEDIFF(dd, 0, a.StartDate)) = @StartDate
        
END
GO

IF OBJECT_ID('[Calendar].[DeleteRecurringActivitiesInFuture]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[DeleteRecurringActivitiesInFuture] AS SELECT 1')
GO
ALTER PROCEDURE [Calendar].[DeleteRecurringActivitiesInFuture]
    @ActivityId INT
AS
BEGIN
	
	DECLARE @EndDate DateTime;
	DECLARE @RecurrenceId INT;
	DECLARE @ResponsibleId INT;

	SELECT @RecurrenceId = RecurrenceId,
		@EndDate = EndDate,
		@ResponsibleId = ResponsibleId
	FROM [Calendar].[Activities]
	WHERE ActivityId = @ActivityId

	UPDATE [Calendar].[Activities]
	SET IsRecurring = 0, RecurrenceId = NULL
	WHERE ActivityId = @ActivityId

	IF @RecurrenceId IS NOT NULL
	BEGIN
		DECLARE @FutureActivities TABLE(
			Id INT
		);

		INSERT INTO @FutureActivities
		SELECT ActivityId AS Id
		FROM [Calendar].[Activities]
		WHERE RecurrenceId = @RecurrenceId AND EndDate >= @EndDate AND ActivityId != @ActivityId;

		--DELETE FUTURE ACTIVITIES
		DELETE [Calendar].[ActivityDocuments]
		WHERE EXISTS ( SELECT * FROM @FutureActivities WHERE Id = ActivityId)

		DELETE [Calendar].[ActivityResponsibles]
		WHERE EXISTS ( SELECT * FROM @FutureActivities WHERE Id = ActivityId)

		DELETE [Calendar].[ActivityTasks]
		WHERE EXISTS ( SELECT * FROM @FutureActivities WHERE Id = ActivityId)

		DELETE tblAcl
		WHERE EXISTS ( SELECT * FROM @FutureActivities WHERE Id = iEntityId) AND iApplicationId = 160

		DELETE Calendar.AnnualCycleActivities
		WHERE EXISTS ( SELECT * FROM @FutureActivities WHERE Id = ActivityId)
		
		DELETE [Calendar].[Activities]
		WHERE EXISTS ( SELECT * FROM @FutureActivities WHERE Id = ActivityId)
		
	END

END
GO

