INSERT INTO #Description VALUES ('Update Annual Cycle, Activity Table')
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
        WHERE [NAME] = N'IsSchoolYear' AND [OBJECT_ID] = OBJECT_ID(N'Calendar.AnnualCycles'))
ALTER TABLE Calendar.AnnualCycles
ADD IsSchoolYear BIT
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
        WHERE [NAME] = N'ResponsibleId' AND [OBJECT_ID] = OBJECT_ID(N'Calendar.ActivityTasks'))
ALTER TABLE Calendar.ActivityTasks
ADD ResponsibleId INT
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
        WHERE [NAME] = N'ResponibilityType' AND [OBJECT_ID] = OBJECT_ID(N'Calendar.ActivityResponsibles'))
ALTER TABLE Calendar.ActivityResponsibles
ADD ResponibilityType BIT
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
        WHERE [NAME] = N'Period' AND [OBJECT_ID] = OBJECT_ID(N'Calendar.Activities'))
ALTER TABLE Calendar.Activities
ADD Period TINYINT NOT NULL DEFAULT 0
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
        WHERE [NAME] = N'FixedDate' AND [OBJECT_ID] = OBJECT_ID(N'Calendar.Recurrence'))
ALTER TABLE Calendar.Recurrence
ADD FixedDate BIT NOT NULL DEFAULT 0
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
        WHERE [NAME] = N'FixedDateType' AND [OBJECT_ID] = OBJECT_ID(N'Calendar.Recurrence'))
ALTER TABLE Calendar.Recurrence
ADD FixedDateType TINYINT NOT NULL DEFAULT 0
GO


ALTER PROCEDURE [Calendar].[AnnualCycleInsert]
(
	@Name NVARCHAR(100) ,
	@Description NVARCHAR(4000) ,
	@Partitioning TINYINT,
	@Year INT,
	@ViewType TINYINT,
	@CreatedBy INT = NULL,
	@IsSchoolYear BIT = 0	
)
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	BEGIN TRAN
		BEGIN TRY
			--function body
			INSERT INTO Calendar.AnnualCycles
			(Name, [Description], Partitioning, [Year], ViewType, IsInactive, IsDeleted, CreatedBy, CreatedDate, IsSchoolYear)
			VALUES 
			(@Name, @Description, @Partitioning, @Year, @ViewType, 1, 0, @CreatedBy, GETUTCDATE(), @IsSchoolYear)
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



 ALTER PROCEDURE [Calendar].[AnnualCycleUpdate]
(
	@AnnualCycleId INT,
	@Name NVARCHAR(100) ,
	@Description NVARCHAR(4000) ,
	@Partitioning TINYINT,
	@Year INT,
	@ViewType TINYINT,
	@IsInactive BIT,
	@Activities [Calendar].[AnnualCycleActivityType] READONLY,
	@Readers [Calendar].[AnnualCycleReaderType] READONLY,
	@Exclusions [Calendar].[AnnualCycleExclusionType] READONLY,
	@UserId INT,
	@IsSchoolYear BIT = 0
)
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	BEGIN TRAN
		BEGIN TRY
			DECLARE @CanUserEditAnnualCycle BIT;
			SET @CanUserEditAnnualCycle = [dbo].[CanUserEditAnnualCycle](@UserId, @AnnualCycleId);		
			--function body
			IF EXISTS (SELECT * FROM Calendar.AnnualCycles WHERE AnnualCycleId = @AnnualCycleId AND @CanUserEditAnnualCycle = 1)
			BEGIN
				UPDATE Calendar.AnnualCycles
				SET 
				Name = @Name,
				[Description] = @Description,
				Partitioning = @Partitioning,
				[Year] = @Year,
				ViewType = @ViewType,
				IsInactive = @IsInactive,
				UpdatedBy = @UserId,
				UpdatedDate = GETUTCDATE(),
				IsSchoolYear = @IsSchoolYear
				WHERE AnnualCycleId = @AnnualCycleId
				DELETE FROM [Calendar].[AnnualCycleActivities] WHERE AnnualCycleId = @AnnualCycleId
				DELETE FROM [Calendar].[AnnualCycleReaders] WHERE AnnualCycleId = @AnnualCycleId
				DELETE FROM [Calendar].[AnnualCycleExclusions] WHERE AnnualCycleId = @AnnualCycleId
				INSERT [Calendar].[AnnualCycleActivities]
				(AnnualCycleId, ActivityId)
				SELECT @AnnualCycleId, ActivityId
				FROM @Activities
				INSERT  [Calendar].[AnnualCycleReaders]
				(AnnualCycleId, ReaderTypeId, ReaderId)
				SELECT @AnnualCycleId, ReaderTypeId, ReaderId
				FROM @Readers
				INSERT [Calendar].[AnnualCycleExclusions]
				(AnnualCycleId, DepartmentId, EmployeeId)
				SELECT @AnnualCycleId, DepartmentId, EmployeeId
				FROM @Exclusions
			END
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
	SELECT 1;	
END	
GO


 ALTER PROCEDURE [Calendar].[AnnualCycleGetPaged]
(
	@PageIndex int,
	@PageSize int,
	@Keyword nvarchar(200),
	@UserId INT,
	@IsBackend BIT = 0,
	@OnlyMine BIT = 0
)
AS
BEGIN
	DECLARE @TempTable TABLE(
		AnnualCycleId INT ,
		Name NVARCHAR(100) ,
		[Description] NVARCHAR(4000) ,
		Partitioning TINYINT,
		[Year] INT,
		ViewType TINYINT,
		IsInactive BIT,
		IsDeleted BIT,
		CreatedDate DATETIME,
		CreatedBy INT,
		CreatedByName NVARCHAR(500),
		UpdatedByName  NVARCHAR(500),
		UpdatedDate DATETIME,
		UpdatedBy INT,
		IsSchoolYear BIT,
		[Rownumber] [int]
	);
	DECLARE @SortExpression nvarchar;
	SET @SortExpression = '';
	DECLARE @UserDepartmentOId INT;
	SELECT @UserDepartmentOId = iDepartmentId
	FROM dbo.tblEmployee
	WHERE iEmployeeId = @UserId
	DECLARE @RoleIds TABLE(
		iSecGroupId INT
	);
	INSERT INTO @RoleIds
	SELECT iSecGroupId 
	FROM dbo.relEmployeeSecGroup
	WHERE iEmployeeId = @UserId
	GROUP BY iSecGroupId;
	INSERT INTO @TempTable
				   SELECT ac.AnnualCycleId,
						ac.Name,
						ac.[Description],               
						ac.Partitioning,
						ac.[Year],
						ac.ViewType,
						ac.IsInactive,    
						ac.IsDeleted,
						ac.CreatedDate,
						ac.CreatedBy,
						ISNULL(e.strFirstName, '') + ' ' + ISNULL(e.strLastName, '') AS CreatedByName,
						ISNULL(e2.strFirstName, '') + ' ' + ISNULL(e2.strLastName, '') AS UpdatedByName,		
						ac.UpdatedDate,
						ac.UpdatedBy, 
						ac.IsSchoolYear,                        
						ROW_NUMBER() OVER (ORDER BY 
								CASE WHEN @SortExpression='' THEN ac.AnnualCycleId END DESC																																											      
							) AS rownumber
					FROM Calendar.AnnualCycles ac
					LEFT JOIN tblEmployee e ON ac.CreatedBy = e.iEmployeeId
					LEFT JOIN tblEmployee e2 ON ac.UpdatedBy = e2.iEmployeeId
					WHERE  (@Keyword IS NULL OR (@Keyword IS NOT NULL AND ac.Name LIKE '%'+@Keyword+'%')) 
					AND	(@OnlyMine = 0 OR (@OnlyMine = 1 AND ac.CreatedBy = @UserId)) 
					AND ac.IsDeleted = 0
					AND (@IsBackend = 1 OR ac.IsInactive = 0)
					AND NOT EXISTS (SELECT ace.* FROM Calendar.AnnualCycleExclusions ace WHERE ac.AnnualCycleId = ace.AnnualCycleId AND ace.EmployeeId = @UserId)
					AND (
						ac.CreatedBy = @UserId OR 
						NOT EXISTS (SELECT acr.* FROM Calendar.AnnualCycleReaders acr WHERE ac.AnnualCycleId = acr.AnnualCycleId) OR					
						EXISTS(
							SELECT acr.* 
							FROM Calendar.AnnualCycleReaders acr 
							WHERE ac.AnnualCycleId = acr.AnnualCycleId AND
								(
									(acr.ReaderTypeId = 1 AND acr.ReaderId = @UserId)
									OR
									(acr.ReaderTypeId = 2 AND acr.ReaderId = @UserDepartmentOId)
									OR
									(acr.ReaderTypeId = 3 AND EXISTS (SELECT r.* FROM @RoleIds r WHERE r.iSecGroupId = acr.ReaderId))
								)
							)
						)				
				SELECT * FROM @TempTable WHERE (@PageSize=0 OR rownumber BETWEEN @PageSize*@PageIndex+1 AND @PageSize*(@PageIndex+1)) ORDER BY rownumber
				--count total rows           
				SELECT COUNT(*)          
				FROM  @TempTable
END
GO



IF (OBJECT_ID('[Calendar.be_GetUsersForTask]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [Calendar.be_GetUsersForTask] AS SELECT 1'
GO	

ALTER PROCEDURE [Calendar.be_GetUsersForTask]
(
	@ActivityId INT
)
AS
BEGIN
	DECLARE @ResponsibleTable TABLE(
		ResponsibleId INT
	)

	DECLARE @DepartmentResponsible INT;

	SELECT @DepartmentResponsible = ResponsibleId
	FROM Calendar.ActivityResponsibles 
	WHERE ActivityId = @ActivityId AND ResponsibleTypeId = 702 --Deparment


	INSERT INTO @ResponsibleTable
		SELECT ResponsibleId 
		FROM Calendar.ActivityResponsibles 
		WHERE ActivityId = @ActivityId AND ResponsibleTypeId = 701 --Person

	INSERT INTO @ResponsibleTable
		SELECT es.iEmployeeId
		FROM relEmployeeSecGroup es
		INNER JOIN Calendar.ActivityResponsibles ar
		ON es.iSecGroupId = ar.ResponsibleId
		WHERE ActivityId = @ActivityId AND ResponsibleTypeId = 703 --Role

	IF @DepartmentResponsible IS NOT NULL
	BEGIN

		INSERT INTO @ResponsibleTable
		SELECT e.iEmployeeId
		FROM [dbo].[tblEmployee] e 
		INNER JOIN 
		(
			SELECT iDepartmentId 
			FROM m136_GetDepartmentsRecursive(@DepartmentResponsible)		
		)
		AS d
		ON e.iDepartmentId = d.iDepartmentId
	END
		
	SELECT DISTINCT
		ud.[iEmployeeId], 
		CASE
				WHEN rd.strName IS NULL OR rd.strName = '' THEN ud.FullNameAndDepartmentName
				ELSE ud.FullNameAndDepartmentName + ' / ' + rd.strName
			END AS FullNameAndDepartmentName,
		ud.strFirstName,
		ud.strLastName
	FROM                                               
		(
			SELECT  e.[iEmployeeId], e.[iDepartmentId], e.[strFirstName], e.[strLastName], e.[LastLogin], e.[strLoginName], e.[strEmail],
			e.[strFirstName] + ' ' + e.[strLastName] + ' - ' + d.strName AS FullNameAndDepartmentName
			FROM [dbo].[tblEmployee] e 
			LEFT JOIN  dbo.tblDepartment d ON e.iDepartmentId = d.iDepartmentId
		)AS ud 
		LEFT JOIN 
		(
			SELECT r.iDepartmentId, r.iEmployeeId, d.strName
			FROM dbo.relEmployeeDepartment r
			INNER JOIN dbo.tblDepartment d ON r.iDepartmentId = d.iDepartmentId
		) AS rd
		ON ud.iEmployeeId = rd.iEmployeeId
		INNER JOIN @ResponsibleTable rt
		ON ud.[iEmployeeId] = rt.ResponsibleId
	ORDER BY FullNameAndDepartmentName
END
GO



ALTER PROCEDURE [Calendar].[CreateActivityTask] 
    @ActivityId INT,
    @Name NVARCHAR(250),
    @Description NVARCHAR(MAX),
    @CreatedBy INT,
    @IsCompleted BIT,
    @ResponsibleId INT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        DEClARE @ActivityTaskId INT;
        DECLARE @CompletedDate DATE = NULL;
        IF @IsCompleted = 1
        BEGIN
            SET @CompletedDate = CONVERT(DATE, GETDATE());
        END
        INSERT INTO
            [Calendar].[ActivityTasks]
                (ActivityId, Name, Description, CreatedBy, CreatedDate, IsCompleted, CompletedDate, ResponsibleId)
            VALUES
                (@ActivityId, @Name, @Description, @CreatedBy, GETDATE(), @IsCompleted, @CompletedDate, @ResponsibleId)
        SET @ActivityTaskId = SCOPE_IDENTITY()
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
            ActivityTaskId = @ActivityTaskId
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




ALTER PROCEDURE [Calendar].[UpdateActivityTask] 
    @ActivityTaskId INT,
    @Name NVARCHAR(250),
    @Description NVARCHAR(MAX),
    @UpdatedBy INT,
    @IsCompleted BIT,
    @ResponsibleId INT    
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        DECLARE @CompletedDate DATE = NULL;
        IF @IsCompleted = 1
        BEGIN
            SET @CompletedDate = CONVERT(DATE, GETDATE());
        END
        UPDATE
            [Calendar].[ActivityTasks]
        SET
            Name = @Name,
            Description = @Description,
            UpdatedBy = @UpdatedBy,
            UpdatedDate = GETDATE(),
            IsCompleted = @IsCompleted,
            CompletedDate = @CompletedDate,
            ResponsibleId = @ResponsibleId
        WHERE
            ActivityTaskId = @ActivityTaskId
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
                ActivityTaskId = @ActivityTaskId
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





ALTER PROCEDURE [Calendar].[GetActivityDetailsById]
    @ActivityId INT,
    @UserId INT
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
		r.RecurringMonthperiod,
		a.Period,
		r.FixedDate AS RecurringFixedDate,
		r.FixedDateType AS RecurringFixedDateType
    FROM
        [Calendar].[Activities] a
		LEFT JOIN [Calendar].[Recurrence] r ON a.RecurrenceId = r.Id AND a.RecurrenceId IS NOT NULL
    WHERE
        ActivityId = @ActivityId
	-----------------------------
    SELECT
        ActivityResponsibleId,
        ActivityId,
        ResponsibleTypeId,
        ResponsibleId,
        ISNULL(ResponibilityType, 0) AS ResponibilityType,
        CASE
            WHEN ResponsibleTypeId = 701 THEN (SELECT strFirstName + ' ' + strLastName FROM tblEmployee WHERE iEmployeeId = ResponsibleId)
            WHEN ResponsibleTypeId = 702 THEN (SELECT strName FROM tblDepartment WHERE iDepartmentId = ResponsibleId)
            WHEN ResponsibleTypeId = 703 THEN (SELECT strName FROM tblSecGroup WHERE iSecGroupId = ResponsibleId)
        END AS ResponsibleName
    FROM
        [Calendar].[ActivityResponsibles]
    WHERE
        ActivityId = @ActivityId
	-------------------------------
	
	DECLARE @ResponsibleTable TABLE(
		ResponsibleId INT,
		ResponibilityType BIT
		
	);
	DECLARE @DepartmentResponsible INT;
	DECLARE @DepartmentResponibilityType BIT;

	SELECT @DepartmentResponsible = ResponsibleId,
		@DepartmentResponibilityType = ResponibilityType
	FROM Calendar.ActivityResponsibles 
	WHERE ActivityId = @ActivityId AND ResponsibleTypeId = 702 --Deparment


	INSERT INTO @ResponsibleTable
		SELECT ResponsibleId ,
		ResponibilityType
		FROM Calendar.ActivityResponsibles 
		WHERE ActivityId = @ActivityId AND ResponsibleTypeId = 701 --Person

	INSERT INTO @ResponsibleTable
		SELECT es.iEmployeeId,
		ar.ResponibilityType
		FROM relEmployeeSecGroup es
		INNER JOIN Calendar.ActivityResponsibles ar
		ON es.iSecGroupId = ar.ResponsibleId
		WHERE ActivityId = @ActivityId AND ResponsibleTypeId = 703 --Role	
		
	IF @DepartmentResponsible IS NOT NULL
	BEGIN

		INSERT INTO @ResponsibleTable
		SELECT e.iEmployeeId As ResponsibleId,
		@DepartmentResponibilityType AS ResponibilityType
		FROM [dbo].[tblEmployee] e 
		INNER JOIN 
		(
			SELECT iDepartmentId 
			FROM m136_GetDepartmentsRecursive(@DepartmentResponsible)		
		)
		AS d
		ON e.iDepartmentId = d.iDepartmentId
	END	
	
    SELECT
        at.ActivityTaskId,
        at.ActivityId,
        at.Name,
        at.Description,
        at.CreatedBy,
        at.CreatedDate,
        at.IsCompleted,
        at.CompletedDate,
        at.ResponsibleId,
        e.[strFirstName] + ' ' + e.[strLastName] AS ResponsibleName
    FROM
        [Calendar].[ActivityTasks] at
        LEFT JOIN [dbo].[tblEmployee] e
        ON at.ResponsibleId = e.[iEmployeeId]
    WHERE
        at.ActivityId = @ActivityId 
        AND
        (
			at.CreatedBy = @UserId
			OR
			at.ResponsibleId = 0 
			OR 
			EXISTS (
						SELECT * 
						FROM @ResponsibleTable rt 
						WHERE rt.ResponsibleId = @UserId 
						AND (
								rt.ResponibilityType = 0
								OR
								rt.ResponibilityType IS NULL
								OR
								(
									rt.ResponibilityType = 1 AND rt.ResponsibleId = at.ResponsibleId									
								)
							) 
					)
		)
	---------------------------
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


ALTER PROCEDURE [Calendar].[CreateActivityForAdminLeader] 
    @Name NVARCHAR(250),
    @Description NVARCHAR(MAX),
    @StartDate DATETIME,
    @EndDate DATETIME,
    @CategoryId INT,
    @ResponsibleId INT,
    @CreatedBy INT,
    @IsPermissionControlled BIT,
    @Period TINYINT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        INSERT INTO 
            [Calendar].[Activities]
                (Name, Description, StartDate, EndDate, CategoryId, ResponsibleId, CreatedBy, CreatedDate, IsPermissionControlled, Period)
            VALUES
                (@Name, @Description, @StartDate, @EndDate, @CategoryId, @ResponsibleId, @CreatedBy, GETDATE(), @IsPermissionControlled, @Period)
        SELECT SCOPE_IDENTITY()
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



ALTER PROCEDURE [Calendar].[CreateActivityForNormalUser] 
    @Name NVARCHAR(250),
    @Description NVARCHAR(MAX),
    @StartDate DATETIME,
    @EndDate DATETIME,
    @CategoryId INT,
    @CreatedBy INT,
    @Period TINYINT    
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        INSERT INTO 
            [Calendar].[Activities]
                (Name, Description, StartDate, EndDate, CategoryId, ResponsibleId, CreatedBy, CreatedDate, IsPermissionControlled, Period)
            VALUES
                (@Name, @Description, @StartDate, @EndDate, @CategoryId, @CreatedBy, @CreatedBy, GETDATE(), 1, @Period)
        SELECT SCOPE_IDENTITY()
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


DROP PROCEDURE [Calendar].[UpdateActivity]
GO

DROP TYPE [Calendar].[ActivityResponsibleItems]
GO

CREATE TYPE [Calendar].[ActivityResponsibleItems] AS TABLE(
	[ActivityId] [int] NULL,
	[ResponsibleTypeId] [int] NULL,
	[ResponsibleId] [int] NULL,
	ResponibilityType BIT NULL
)
GO

CREATE PROCEDURE [Calendar].[UpdateActivity] 
    @ActivityId INT,
    @Name NVARCHAR(250),
    @Description NVARCHAR(MAX),
    @StartDate DATETIME,
    @EndDate DATETIME,
    @CategoryId INT,
    @ResponsibleId INT,
    @UpdatedBy INT,
    @IsPermissionControlled BIT,
	@AnnualCycleId INT = NULL,
    @ActivityTasks AS Calendar.ActivityTaskItems READONLY,
    @ActivityDocuments AS Calendar.ActivityDocumentItems READONLY,
    @ActivityResponsibles AS Calendar.ActivityResponsibleItems READONLY,
    @ActivityAccesses AS Calendar.ActivityAccessItems READONLY,
    @Period TINYINT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        DECLARE @Now DATETIME = GETDATE();
        UPDATE
            [Calendar].[Activities]
        SET
            Name = @Name,
            Description = @Description,
            StartDate = @StartDate,
            EndDate = @EndDate,
            CategoryId = @CategoryId,
            ResponsibleId = @ResponsibleId,
            UpdatedBy = @UpdatedBy,
            UpdatedDate = @Now,
            IsPermissionControlled = @IsPermissionControlled,
            Period = @Period
        WHERE
            ActivityId = @ActivityId
        -- Re-insert activity tasks
        DELETE FROM
            [Calendar].[ActivityTasks]
        WHERE
            ActivityId = @ActivityId
        INSERT INTO [Calendar].[ActivityTasks]
            (ActivityId, Name, Description, CreatedBy, CreatedDate, UpdatedBy, UpdatedDate, IsCompleted)
            SELECT
                ActivityId,
                Name,
                Description,
                CreatedBy,
                CreatedDate,
                @UpdatedBy,
                @Now,
                IsCompleted
            FROM
                @ActivityTasks
        -- Re-insert activity documents
        DELETE FROM
            [Calendar].[ActivityDocuments]
        WHERE
            ActivityId = @ActivityId
        INSERT INTO [Calendar].[ActivityDocuments]
            (ActivityId, DocumentId)
            SELECT
                ActivityId,
                DocumentId
            FROM
                @ActivityDocuments
        -- Re-insert activity responsibles
        DELETE FROM
            Calendar.ActivityResponsibles
        WHERE
            ActivityId = @ActivityId
            
        INSERT INTO Calendar.ActivityResponsibles
            (ActivityId, ResponsibleTypeId, ResponsibleId, ResponibilityType)
            SELECT
                ActivityId,
                ResponsibleTypeId,
                ResponsibleId,
                ResponibilityType
            FROM
                @ActivityResponsibles
        -- Re-insert activity accesses
        DELETE FROM
            tblAcl
        WHERE
            iEntityId = @ActivityId
            AND iApplicationId = 160
        INSERT INTO tblAcl
            (iEntityId, iApplicationId, iSecurityId, iPermissionSetId, iGroupingId, iBit)
            SELECT
                ActivityId,
                160,
                AccessId,
                AccessTypeId,
                0,
                0
            FROM
                @ActivityAccesses
		-- INSERT AnnualCycleActivities IF NOT EXISTS
		IF @AnnualCycleId IS NOT NULL AND NOT EXISTS( SELECT * FROM Calendar.AnnualCycleActivities WHERE AnnualCycleId = @AnnualCycleId AND ActivityId = @ActivityId)
		BEGIN
			INSERT INTO Calendar.AnnualCycleActivities(AnnualCycleId, ActivityId) VALUES(@AnnualCycleId, @ActivityId)
		END
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




ALTER PROCEDURE [Calendar].[AnnualCycleGetById]
(
	@AnnualCycleId INT,
	@UserId INT,
	@IsBackend BIT = 0	
)
AS
BEGIN
	DECLARE @CanUserEditAnnualCycle BIT;
	SET @CanUserEditAnnualCycle = [dbo].[CanUserEditAnnualCycle](@UserId, @AnnualCycleId);
	DECLARE @UserDepartmentOId INT;
	SELECT @UserDepartmentOId = iDepartmentId
	FROM dbo.tblEmployee
	WHERE iEmployeeId = @UserId
	DECLARE @RoleIds TABLE(
		iSecGroupId INT
	);
	INSERT INTO @RoleIds
	SELECT iSecGroupId 
	FROM dbo.relEmployeeSecGroup
	WHERE iEmployeeId = @UserId
	GROUP BY iSecGroupId;	
	SELECT ac.*,
		CASE
			WHEN @CanUserEditAnnualCycle = 1 THEN 0
			ELSE 1
		END AS [ReadOnly],
		ISNULL(e.strFirstName, '') + ' ' + ISNULL(e.strLastName, '') AS CreatedByName,
		ISNULL(e2.strFirstName, '') + ' ' + ISNULL(e2.strLastName, '') AS UpdatedByName  
	FROM Calendar.AnnualCycles ac
		LEFT JOIN tblEmployee e ON ac.CreatedBy = e.iEmployeeId
		LEFT JOIN tblEmployee e2 ON ac.UpdatedBy = e2.iEmployeeId
	WHERE ac.AnnualCycleId = @AnnualCycleId
	AND ac.IsDeleted = 0 AND (@IsBackend = 1 OR ac.IsInactive = 0)
	AND NOT EXISTS (SELECT ace.* FROM Calendar.AnnualCycleExclusions ace WHERE ac.AnnualCycleId = ace.AnnualCycleId AND ace.EmployeeId = @UserId)
	AND (
		ac.CreatedBy = @UserId OR 
		NOT EXISTS (SELECT acr.* FROM Calendar.AnnualCycleReaders acr WHERE ac.AnnualCycleId = acr.AnnualCycleId) OR
		EXISTS(
			SELECT acr.* 
			FROM Calendar.AnnualCycleReaders acr 
			WHERE ac.AnnualCycleId = acr.AnnualCycleId AND 
				(
					(acr.ReaderTypeId = 1 AND acr.ReaderId = @UserId)
					OR
					(acr.ReaderTypeId = 2 AND acr.ReaderId = @UserDepartmentOId)
					OR
					(acr.ReaderTypeId = 3 AND EXISTS (SELECT r.* FROM @RoleIds r WHERE r.iSecGroupId = acr.ReaderId))
				)
			)
		)		
		
---activity
	SELECT 
	a.ActivityId,
	a.Name,
	a.[Description],
	a.StartDate,
	a.EndDate,
	a.CategoryId,
	ac.Name AS CategoryName,
	e.strFirstName + ' ' + e.strLastName AS ResponsibleName,
	a.CreatedBy
	FROM Calendar.Activities a
	INNER JOIN Calendar.AnnualCycleActivities aca ON aca.ActivityId = a.ActivityId
	LEFT JOIN Calendar.ActivityCategories ac ON a.CategoryId = ac.CategoryId
	LEFT JOIN tblEmployee e ON a.ResponsibleId = e.iEmployeeId
	WHERE aca.AnnualCycleId = @AnnualCycleId
	ORDER BY a.StartDate ASC
	
---reader
	SELECT DISTINCT
		acr.AnnualCycleViewerId,
		acr.AnnualCycleId,
		acr.ReaderTypeId,
		acr.ReaderId,
		CASE
			WHEN acr.ReaderTypeId = 1 THEN e.strFirstName + ' ' + e.strLastName
			WHEN acr.ReaderTypeId = 2 THEN d.strName
			WHEN acr.ReaderTypeId = 3 THEN s.strName
		END AS ReaderName
	FROM
		Calendar.AnnualCycleReaders acr
		LEFT JOIN tblEmployee e on acr.ReaderId = e.iEmployeeId AND acr.ReaderTypeId = 1
		LEFT JOIN tblDepartment d on acr.ReaderId = d.iDepartmentId AND acr.ReaderTypeId = 2
		LEFT JOIN tblSecGroup s on acr.ReaderId = s.iSecGroupId AND acr.ReaderTypeId = 3		
	WHERE
		acr.AnnualCycleId = @AnnualCycleId
		
---exclusion
	SELECT
		rle.AnnualCycleExclusionId,
		rle.AnnualCycleId,
		rle.DepartmentId,
		d.strName AS DepartmentName,
		rle.EmployeeId,
		e.strFirstName + ' ' + e.strLastName AS EmployeeName
	FROM
		Calendar.AnnualCycleExclusions rle
			INNER JOIN tblDepartment d ON rle.DepartmentId = d.iDepartmentId
			INNER JOIN tblEmployee e ON rle.EmployeeId = e.iEmployeeId
	WHERE
		rle.AnnualCycleId = @AnnualCycleId
-----responsibles

    SELECT DISTINCT
        acr.ActivityId,
        CASE
			WHEN acr.ResponsibleTypeId = 701 THEN e.strFirstName + ' ' + e.strLastName
			WHEN acr.ResponsibleTypeId = 702 THEN d.strName
			WHEN acr.ResponsibleTypeId = 703 THEN s.strName
        END AS ResponsibleName
    FROM
        [Calendar].[ActivityResponsibles] acr   
		LEFT JOIN tblEmployee e on acr.ResponsibleId = e.iEmployeeId AND acr.ResponsibleTypeId = 701
		LEFT JOIN tblDepartment d on acr.ResponsibleId = d.iDepartmentId AND acr.ResponsibleTypeId = 702
		LEFT JOIN tblSecGroup s on acr.ResponsibleId = s.iSecGroupId AND acr.ResponsibleTypeId = 703
	WHERE (acr.ResponibilityType = 0 OR acr.ResponibilityType IS NULL) AND acr.ActivityId IN (SELECT aca.ActivityId FROM Calendar.AnnualCycleActivities aca WHERE aca.AnnualCycleId = @AnnualCycleId)
    ORDER BY ResponsibleName
END
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
	@RecurringFixedDate BIT = NULL,
	@RecurringFixedDateType TINYINT = NULL,
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
		INSERT INTO [Calendar].[Recurrence](RecurringEndDate, RecurringOrdinalId, RecurringDayId, RecurringMonthsId, RecurringMonthperiod, FixedDate, FixedDateType)
		VALUES(@RecurringEndDate, @RecurringOrdinalId, @RecurringDayId, @RecurringMonthsId, @RecurringMonthperiod, ISNULL(@RecurringFixedDate, 0), ISNULL(@RecurringFixedDateType, 0));
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
		(Name, [Description], StartDate, EndDate, ResponsibleId, CreatedBy, CreatedDate, UpdatedBy, UpdatedDate, IsPermissionControlled, CategoryId, IsRecurring, RecurrenceId, Period)
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
			@NewRecurrentId,
			oa.Period
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
		(ActivityId, ResponsibleTypeId, ResponsibleId, ResponibilityType)
		SELECT ra.Id, ar.ResponsibleTypeId, ar.ResponsibleId, ar.ResponibilityType
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
			ResponsibleId INT,
			ResponibilityType BIT
		);
		INSERT INTO @ActivityResponsibles
		(ResponsibleTypeId, ResponsibleId, ResponibilityType)
		SELECT ResponsibleTypeId, ResponsibleId, ResponibilityType
		FROM [Calendar].[ActivityResponsibles]
		WHERE ActivityId = @ActivityId
		
		DELETE FROM
			Calendar.ActivityResponsibles
		WHERE EXISTS ( SELECT * FROM @RelatedActivities WHERE Id = ActivityId)
		INSERT INTO [Calendar].[ActivityResponsibles]
			(ActivityId, ResponsibleTypeId, ResponsibleId, ResponibilityType)
			SELECT
				pa.Id,
				ar.ResponsibleTypeId,
				ar.ResponsibleId,
				ar.ResponibilityType
			FROM @RelatedActivities pa CROSS JOIN @ActivityResponsibles ar
	END
END
GO
