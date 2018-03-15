INSERT INTO #Description VALUES ('Init tables, store of Annual Cycle - Recurrence')
GO

--Calendar.luRecurringOrdinals
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Calendar.luRecurringOrdinals') AND type in (N'U'))
BEGIN
	CREATE TABLE Calendar.luRecurringOrdinals(
		Id TINYINT NOT NULL,
		Name NVARCHAR(100) NOT NULL
	);
	ALTER TABLE Calendar.luRecurringOrdinals ADD CONSTRAINT PK_CalendarluRecurringOrdinals_Id PRIMARY KEY (Id);

	INSERT INTO Calendar.luRecurringOrdinals(Id, Name) VALUES(1, 'First');
	INSERT INTO Calendar.luRecurringOrdinals(Id, Name) VALUES(2, 'Second');
	INSERT INTO Calendar.luRecurringOrdinals(Id, Name) VALUES(3, 'Third');
	INSERT INTO Calendar.luRecurringOrdinals(Id, Name) VALUES(4, 'Fourth');
	INSERT INTO Calendar.luRecurringOrdinals(Id, Name) VALUES(5, 'Last');
END
GO

--Calendar.luRecurringDays
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Calendar.luRecurringDays') AND type in (N'U'))
BEGIN
	CREATE TABLE Calendar.luRecurringDays(
		Id TINYINT NOT NULL,
		Name NVARCHAR(100) NOT NULL
	);
	ALTER TABLE Calendar.luRecurringDays ADD CONSTRAINT PK_CalendarluRecurringDays_Id PRIMARY KEY (Id);

	INSERT INTO Calendar.luRecurringDays(Id, Name) VALUES(1, 'Monday');
	INSERT INTO Calendar.luRecurringDays(Id, Name) VALUES(2, 'Tuesday');
	INSERT INTO Calendar.luRecurringDays(Id, Name) VALUES(3, 'Wednesday');
	INSERT INTO Calendar.luRecurringDays(Id, Name) VALUES(4, 'Thursday');
	INSERT INTO Calendar.luRecurringDays(Id, Name) VALUES(5, 'Friday');
	INSERT INTO Calendar.luRecurringDays(Id, Name) VALUES(6, 'Saturday');
	INSERT INTO Calendar.luRecurringDays(Id, Name) VALUES(7, 'Sunday');
END
GO

--Calendar.luRecurringMonthsIF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Calendar.luRecurringMonths') AND type in (N'U'))
BEGIN	CREATE TABLE Calendar.luRecurringMonths(
		Id TINYINT NOT NULL,
		Name NVARCHAR(100) NOT NULL
	);
	ALTER TABLE Calendar.luRecurringMonths ADD CONSTRAINT PK_CalendarluRecurringMonths_Id PRIMARY KEY (Id);

	INSERT INTO Calendar.luRecurringMonths(Id, Name) VALUES(1, 'January');
	INSERT INTO Calendar.luRecurringMonths(Id, Name) VALUES(2, 'February');
	INSERT INTO Calendar.luRecurringMonths(Id, Name) VALUES(3, 'March');
	INSERT INTO Calendar.luRecurringMonths(Id, Name) VALUES(4, 'April');
	INSERT INTO Calendar.luRecurringMonths(Id, Name) VALUES(5, 'May');
	INSERT INTO Calendar.luRecurringMonths(Id, Name) VALUES(6, 'June');
	INSERT INTO Calendar.luRecurringMonths(Id, Name) VALUES(7, 'July');
	INSERT INTO Calendar.luRecurringMonths(Id, Name) VALUES(8, 'August');
	INSERT INTO Calendar.luRecurringMonths(Id, Name) VALUES(9, 'September');
	INSERT INTO Calendar.luRecurringMonths(Id, Name) VALUES(10, 'October');
	INSERT INTO Calendar.luRecurringMonths(Id, Name) VALUES(11, 'November');
	INSERT INTO Calendar.luRecurringMonths(Id, Name) VALUES(12, 'December');
	INSERT INTO Calendar.luRecurringMonths(Id, Name) VALUES(13, 'Monthly');
END
GO


--Calendar.RecurrenceIF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Calendar.Recurrence') AND type in (N'U'))
BEGIN	CREATE TABLE Calendar.Recurrence(
		Id INT IDENTITY(1,1),
		RecurringEndDate DATETIME NULL,
		RecurringOrdinalId TINYINT NULL,
		RecurringDayId TINYINT NULL,
		RecurringMonthsId TINYINT NULL,
		RecurringMonthperiod TINYINT NULL
	);
	ALTER TABLE Calendar.Recurrence ADD CONSTRAINT PK_CalendarRecurrence_Id PRIMARY KEY (Id);
END
GO

--Calendar.Activities
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Calendar.Activities') AND type in (N'U'))
BEGIN
	
	IF NOT EXISTS (SELECT * FROM   sys.columns WHERE  object_id = OBJECT_ID(N'[Calendar].[Activities]') AND name = 'IsRecurring')
	ALTER TABLE Calendar.Activities ADD IsRecurring BIT NOT NULL DEFAULT 0;
	
	IF NOT EXISTS (SELECT * FROM   sys.columns WHERE  object_id = OBJECT_ID(N'[Calendar].[Activities]') AND name = 'RecurrenceId')
	BEGIN
		ALTER TABLE Calendar.Activities ADD RecurrenceId INT NULL;
		ALTER TABLE Calendar.Activities WITH NOCHECK ADD CONSTRAINT FK_Activities_Recurrence FOREIGN KEY (RecurrenceId) REFERENCES Calendar.Recurrence(Id);
	END
END
GO

IF TYPE_ID(N'Calendar.RelatedActivityType') IS NULL
CREATE TYPE [Calendar].[RelatedActivityType] AS TABLE(
	[StartDate] DATETIME,
	[EndDate] DATETIME
)
GO


--get activity detail by activity Id
IF (OBJECT_ID('[Calendar].[GetActivityDetailsById]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [Calendar].[GetActivityDetailsById] AS SELECT 1'
GO	
ALTER PROCEDURE [Calendar].[GetActivityDetailsById]
    @ActivityId INT
AS
BEGIN
    SELECT
        a.ActivityId,
        a.Name,
        a.[Description],
        a.StartDate,
        a.EndDate,
        a.CategoryId,
        a.CreatedBy,
        a.CreatedDate,
        a.ResponsibleId,
        a.IsPermissionControlled,
		a.IsRecurring,
		a.RecurrenceId,
		r.RecurringEndDate,
		r.RecurringOrdinalId,
		r.RecurringDayId,
		r.RecurringMonthsId,
		r.RecurringMonthperiod
    FROM
        [Calendar].[Activities] a
		LEFT JOIN [Calendar].[Recurrence] r ON a.RecurrenceId = r.Id AND a.RecurrenceId IS NOT NULL
    WHERE
        ActivityId = @ActivityId
	--
    SELECT
        ActivityResponsibleId,
        ActivityId,
        ResponsibleTypeId,
        ResponsibleId,
        CASE
            WHEN ResponsibleTypeId = 701 THEN (SELECT strFirstName + ' ' + strLastName FROM tblEmployee WHERE iEmployeeId = ResponsibleId)
            WHEN ResponsibleTypeId = 702 THEN (SELECT strName FROM tblDepartment WHERE iDepartmentId = ResponsibleId)
            WHEN ResponsibleTypeId = 703 THEN (SELECT strName FROM tblSecGroup WHERE iSecGroupId = ResponsibleId)
        END AS ResponsibleName
    FROM
        [Calendar].[ActivityResponsibles]
    WHERE
        ActivityId = @ActivityId
	--
    SELECT
        ActivityTaskId,
        ActivityId,
        Name,
        Description,
        CreatedBy,
        CreatedDate,
        IsCompleted,
        CompletedDate
    FROM
        [Calendar].[ActivityTasks]
    WHERE
        ActivityId = @ActivityId
	--
    SELECT
        ad.ActivityDocumentId,
        ad.ActivityId,
        ad.DocumentId,
        d.strName AS DocumentName,
        dbo.fn136_GetParentPathEx(d.iHandbookId) AS DocumentPath
    FROM
        [Calendar].[ActivityDocuments] ad
            INNER JOIN [dbo].[m136_tblDocument] d ON ad.DocumentId = d.iDocumentId
    WHERE
        ad.ActivityId = @ActivityId
        AND iLatestVersion = 1
	--
    SELECT
        iEntityId AS ActivityId,
        iPermissionSetId AS AccessTypeId,
        iSecurityId AS AccessId,
        CASE
            WHEN iPermissionSetId = 701 THEN (SELECT strFirstName + ' ' + strLastName FROM tblEmployee WHERE iEmployeeId = iSecurityId)
            WHEN iPermissionSetId = 702 THEN (SELECT strName FROM tblDepartment WHERE iDepartmentId = iSecurityId)
            WHEN iPermissionSetId = 703 THEN (SELECT strName FROM tblSecGroup WHERE iSecGroupId = iSecurityId)
        END AS AccessName
    FROM
        tblAcl
    WHERE
        iEntityId = @ActivityId
        AND iApplicationId = 160
END
GO





--[Calendar].[DeleteRecurringActivitiesInFuture]
IF (OBJECT_ID('[Calendar].[DeleteRecurringActivitiesInFuture]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [Calendar].[DeleteRecurringActivitiesInFuture] AS SELECT 1'
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

		DELETE [Calendar].[Activities]
		WHERE EXISTS ( SELECT * FROM @FutureActivities WHERE Id = ActivityId)
	END

END
GO



--[Calendar].[CreateRecurringActivities]
IF (OBJECT_ID('[Calendar].[CreateRecurringActivities]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [Calendar].[CreateRecurringActivities] AS SELECT 1'
GO	
ALTER PROCEDURE [Calendar].[CreateRecurringActivities]
    @ActivityId INT,
	@IsRecurring BIT,
	@RecurrenceId INT = NULL,
	@RecurringEndDate DATETIME = NULL,
	@RecurringOrdinalId INT = NULL,
	@RecurringDayId INT = NULL,
	@RecurringMonthsId INT = NULL,
	@RecurringMonthperiod INT = NULL,
	@RecurringActivities [Calendar].[RelatedActivityType] Readonly 
AS
BEGIN
	DECLARE @CurrentIsRecurring BIT;
	DECLARE @CurrentRecurrenceId BIT;

	SELECT @CurrentIsRecurring = IsRecurring,
		@CurrentRecurrenceId = RecurrenceId
	FROM [Calendar].[Activities]
	WHERE ActivityId = @ActivityId

	IF @CurrentIsRecurring = 1
	BEGIN
		EXEC [Calendar].[DeleteRecurringActivitiesInFuture] @ActivityId
	END

	IF @IsRecurring = 1
	BEGIN
		--We have to do:
		--1. Insert new recurrence record
		--2. Update new recurrence id for activity
		--3. Insert related activities
		--4. Clone activity documents for related activities
		--5. Clone activity ActivityResponsibles
		--6. Clone activity Tasks
		--7. Clone activity Accesses

		--1
		INSERT INTO [Calendar].[Recurrence](RecurringEndDate, RecurringOrdinalId, RecurringDayId, RecurringMonthsId, RecurringMonthperiod)
		VALUES(@RecurringEndDate, @RecurringOrdinalId, @RecurringDayId, @RecurringMonthsId, @RecurringMonthperiod);
		DECLARE @NewRecurrentId INT;
		SELECT @NewRecurrentId = SCOPE_IDENTITY();
			
		--2
		UPDATE [Calendar].[Activities]
		SET IsRecurring = @IsRecurring, RecurrenceId = @NewRecurrentId
		WHERE ActivityId = @ActivityId

		--3
		DECLARE @CreatedDate DATETIME;
		SET @CreatedDate = GETUTCDATE();

		INSERT INTO [Calendar].[Activities]
		(Name, [Description], StartDate, EndDate, ResponsibleId, CreatedBy, CreatedDate, UpdatedBy, UpdatedDate, IsPermissionControlled, CategoryId, IsRecurring, RecurrenceId)
		SELECT 
			oa.Name,
			oa.Description,
			ra.StartDate,
			ra.EndDate,
			oa.ResponsibleId,
			oa.CreatedBy,
			@CreatedDate,
			null,
			null,
			oa.IsPermissionControlled,
			oa.CategoryId,
			1,
			@NewRecurrentId
		FROM @RecurringActivities ra CROSS JOIN [Calendar].[Activities] oa WHERE oa.ActivityId = @ActivityId

		DECLARE @NewRelatedActivityIds TABLE(
			Id INT
		);

		INSERT INTO @NewRelatedActivityIds
		SELECT ActivityId 
		FROM [Calendar].[Activities]
		WHERE RecurrenceId = @NewRecurrentId AND ActivityId != @ActivityId

		--4
		INSERT INTO [Calendar].[ActivityDocuments]
		(ActivityId, DocumentId)
		SELECT ra.Id, od.DocumentId
		FROM @NewRelatedActivityIds ra CROSS JOIN [Calendar].[ActivityDocuments] od WHERE od.ActivityId = @ActivityId

		--5
		INSERT INTO [Calendar].[ActivityResponsibles]
		(ActivityId, ResponsibleTypeId, ResponsibleId)
		SELECT ra.Id, ar.ResponsibleTypeId, ar.ResponsibleId
		FROM @NewRelatedActivityIds ra CROSS JOIN [Calendar].[ActivityResponsibles] ar WHERE ar.ActivityId = @ActivityId

		--6
		INSERT INTO [Calendar].[ActivityTasks]
		(ActivityId, Name, [Description], CreatedBy, CreatedDate, UpdatedBy, UpdatedDate, IsCompleted, CompletedDate)
		SELECT ra.Id, ata.Name, ata.[Description], ata.CreatedBy, @CreatedDate, null, null, 0, null
		FROM @NewRelatedActivityIds ra CROSS JOIN [Calendar].[ActivityTasks] ata WHERE ata.ActivityId = @ActivityId

		--7
		INSERT INTO tblAcl
			(iEntityId, iApplicationId, iSecurityId, iPermissionSetId, iGroupingId, iBit)
			SELECT
				ra.Id,
				acl.iApplicationId,
				acl.iSecurityId,
				acl.iPermissionSetId,
				acl.iGroupingId,
				acl.iBit
			FROM
				@NewRelatedActivityIds ra CROSS JOIN tblAcl acl WHERE acl.iEntityId = @ActivityId AND acl.iApplicationId = 160
	END
END
GO




--[Calendar].[UpdateRecurringActivitiesResponsible]
IF (OBJECT_ID('[Calendar].[UpdateRecurringActivitiesResponsible]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [Calendar].[UpdateRecurringActivitiesResponsible] AS SELECT 1'
GO	
ALTER PROCEDURE [Calendar].[UpdateRecurringActivitiesResponsible]
    @ActivityId INT
AS
BEGIN
	DECLARE @RecurrenceId INT;
	DECLARE @ResponsibleId INT;
	DECLARE @IsRecurring BIT;

	SELECT @RecurrenceId = RecurrenceId,
		@ResponsibleId = ResponsibleId,
		@IsRecurring = IsRecurring
	FROM [Calendar].[Activities]
	WHERE ActivityId = @ActivityId

	IF @RecurrenceId IS NOT NULL AND  @IsRecurring = 1
	BEGIN
		DECLARE @RelatedActivities TABLE(
			Id INT
		);
		INSERT INTO @RelatedActivities
		SELECT ActivityId AS Id
		FROM [Calendar].[Activities]
		WHERE RecurrenceId = @RecurrenceId

		-- update main responsibleID
		UPDATE [Calendar].[Activities]
		SET ResponsibleId = @ResponsibleId
		WHERE EXISTS ( SELECT * FROM @RelatedActivities WHERE Id = ActivityId)
	END
END
GO



--[Calendar].[UpdateRecurringActivitiesCoResponsibles]
IF (OBJECT_ID('[Calendar].[UpdateRecurringActivitiesCoResponsibles]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [Calendar].[UpdateRecurringActivitiesCoResponsibles] AS SELECT 1'
GO	
ALTER PROCEDURE [Calendar].[UpdateRecurringActivitiesCoResponsibles]
    @ActivityId INT
AS
BEGIN
	DECLARE @RecurrenceId INT;
	DECLARE @ResponsibleId INT;
	DECLARE @IsRecurring BIT;

	SELECT @RecurrenceId = RecurrenceId,
		@ResponsibleId = ResponsibleId,
		@IsRecurring = IsRecurring
	FROM [Calendar].[Activities]
	WHERE ActivityId = @ActivityId

	IF @RecurrenceId IS NOT NULL AND  @IsRecurring = 1
	BEGIN
		DECLARE @RelatedActivities TABLE(
			Id INT
		);
		INSERT INTO @RelatedActivities
		SELECT ActivityId AS Id
		FROM [Calendar].[Activities]
		WHERE RecurrenceId = @RecurrenceId

		-- Re-insert activity responsibles

		DECLARE @ActivityResponsibles TABLE(
			ResponsibleTypeId INT,
			ResponsibleId INT
		);

		INSERT INTO @ActivityResponsibles
		(ResponsibleTypeId, ResponsibleId)
		SELECT ResponsibleTypeId, ResponsibleId
		FROM [Calendar].[ActivityResponsibles]
		WHERE ActivityId = @ActivityId

		DELETE FROM
			Calendar.ActivityResponsibles
		WHERE EXISTS ( SELECT * FROM @RelatedActivities WHERE Id = ActivityId)

		INSERT INTO [Calendar].[ActivityResponsibles]
			(ActivityId, ResponsibleTypeId, ResponsibleId)
			SELECT
				pa.Id,
				ar.ResponsibleTypeId,
				ar.ResponsibleId
			FROM @RelatedActivities pa CROSS JOIN @ActivityResponsibles ar
	END
END
GO



--[Calendar].[UpdateRecurringActivitiesAccesses]
IF (OBJECT_ID('[Calendar].[UpdateRecurringActivitiesAccesses]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [Calendar].[UpdateRecurringActivitiesAccesses] AS SELECT 1'
GO	
ALTER PROCEDURE [Calendar].[UpdateRecurringActivitiesAccesses]
    @ActivityId INT
AS
BEGIN
	DECLARE @RecurrenceId INT;
	DECLARE @ResponsibleId INT;
	DECLARE @IsRecurring BIT;

	SELECT @RecurrenceId = RecurrenceId,
		@ResponsibleId = ResponsibleId,
		@IsRecurring = IsRecurring
	FROM [Calendar].[Activities]
	WHERE ActivityId = @ActivityId

	IF @RecurrenceId IS NOT NULL AND  @IsRecurring = 1
	BEGIN
		DECLARE @RelatedActivities TABLE(
			Id INT
		);
		INSERT INTO @RelatedActivities
		SELECT ActivityId AS Id
		FROM [Calendar].[Activities]
		WHERE RecurrenceId = @RecurrenceId

		-- Re-insert activity accesses

		DECLARE @ActivityAccesses TABLE(
			AccessTypeId INT,
			AccessId INT 
		);

		INSERT INTO @ActivityAccesses
		(AccessTypeId, AccessId)
		SELECT
			iPermissionSetId AS AccessTypeId,
			iSecurityId AS AccessId
		FROM
			tblAcl
		WHERE
			iEntityId = @ActivityId
			AND iApplicationId = 160			

		DELETE FROM
			tblAcl
		WHERE iApplicationId = 160
			AND EXISTS (SELECT * FROM @RelatedActivities WHERE Id = iEntityId)

		INSERT INTO tblAcl
			(iEntityId, iApplicationId, iSecurityId, iPermissionSetId, iGroupingId, iBit)
			SELECT
				pa.Id,
				160,
				aa.AccessId,
				aa.AccessTypeId,
				0,
				0
			FROM
				@RelatedActivities pa CROSS JOIN @ActivityAccesses aa

	END
END
GO