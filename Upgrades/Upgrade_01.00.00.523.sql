INSERT INTO #Description VALUES ('Modify [GetActivityDetailsById]')
GO

IF OBJECT_ID('[Calendar].[GetActivityDetailsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[GetActivityDetailsById] AS SELECT 1')
GO
ALTER PROCEDURE [Calendar].[GetActivityDetailsById]
    @ActivityId INT,
    @UserId INT
AS
BEGIN
	DECLARE @CanUserEdit BIT;
	SET @CanUserEdit = [dbo].[CanUserEditActivity](@UserId, @ActivityId);
    SELECT
        a.ActivityId,
        a.Name,
        a.[Description],
        a.StartDate,
        a.EndDate,
        a.CategoryId,
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
		r.FixedDateType AS RecurringFixedDateType,
		a.CreatedBy,
		a.CreatedDate,	
		a.UpdatedBy,
		a.UpdatedDate,
		ISNULL(e.strFirstName, '') + ' ' + ISNULL(e.strLastName, '') AS CreatedByName,
		ISNULL(e2.strFirstName, '') + ' ' + ISNULL(e2.strLastName, '') AS UpdatedByName,			
		CASE
			WHEN @CanUserEdit = 1 THEN 0
			ELSE 1
		END AS [ReadOnly]		
    FROM
        [Calendar].[Activities] a
		LEFT JOIN [Calendar].[Recurrence] r ON a.RecurrenceId = r.Id AND a.RecurrenceId IS NOT NULL
		LEFT JOIN tblEmployee e ON a.CreatedBy = e.iEmployeeId
		LEFT JOIN tblEmployee e2 ON a.UpdatedBy = e2.iEmployeeId		
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
			at.ResponsibleId IS NULL
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

IF OBJECT_ID('Calendar.UpdateActivity', 'p') IS NOT NULL
DROP PROC Calendar.UpdateActivity
GO

IF TYPE_ID('[Calendar].[ActivityTaskItems]') IS NOT NULL
DROP TYPE [Calendar].[ActivityTaskItems]
GO


CREATE TYPE [Calendar].[ActivityTaskItems] AS TABLE(
	[ActivityId] [int] NULL,
	[Name] [nvarchar](250) NULL,
	[Description] [nvarchar](max) NULL,
	[CreatedBy] [int] NULL,
	[CreatedDate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
	[IsCompleted] [bit] NULL,
	ResponsibleId INT
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
            (ActivityId, Name, Description, CreatedBy, CreatedDate, UpdatedBy, UpdatedDate, IsCompleted, ResponsibleId)
            SELECT
                ActivityId,
                Name,
                Description,
                CreatedBy,
                CreatedDate,
                @UpdatedBy,
                @Now,
                IsCompleted,
                ResponsibleId
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

IF OBJECT_ID('[Calendar].[UpdateActivityTask]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[UpdateActivityTask] AS SELECT 1')
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
                CompletedDate,
                ResponsibleId
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


IF NOT EXISTS(SELECT * FROM Calendar.luAnnualCyclePartitionings WHERE Name = 'SchoolYear' AND Id = 4)
INSERT INTO Calendar.luAnnualCyclePartitionings VALUES(4, 'SchoolYear')
GO


IF OBJECT_ID('[Calendar].[SearchActivities]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[SearchActivities] AS SELECT 1')
GO
ALTER PROCEDURE [Calendar].[SearchActivities]
    @UserId INT,
    @Keyword NVARCHAR(MAX),
    @CategoryId INT,
    @ResponsibleId INT,
    @RoleId INT,
    @DepartmentId INT,
    @PersonId INT,
    @StartDate DATETIME,
    @EndDate DATETIME,
    @AnnualCycleId INT,
    @MainResponsibleId INT = null
AS
BEGIN
    DECLARE @UserCanEdit BIT;		
	SET @UserCanEdit = 0;
    -- This procedure is used in Activities Management view and Search Activities View
    -- Activities Management View allows users to search activities by Name & Description
    -- Search Activities View allows users to search activities by Keyword
    DECLARE @UserDepartmentId TABLE(Id INT);
    DECLARE @UserRoleId TABLE(Id INT);
    DECLARE @Activities TABLE
    (
        ActivityId INT, 
        Name NVARCHAR(250), 
        StartDate DATETIME, 
        EndDate DATETIME, 
        ResponsibleId INT, 
        ResponsibleName NVARCHAR(250), 
        CreatedBy INT,
        CreatorName NVARCHAR(250), 
        Description NVARCHAR(MAX), 
        IsPermissionControlled BIT, 
        CategoryId INT, 
        CategoryName NVARCHAR(150),
        Period INT,
        [ReadOnly] BIT
    );
    ----
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        tblEmployee
    WHERE
        iEmployeeId = @UserId
    ----
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        relEmployeeDepartment
    WHERE iEmployeeId = @UserId
    -----
    INSERT INTO @UserRoleId(Id)
    SELECT
        iSecGroupId
    FROM
        relEmployeeSecGroup
    WHERE
        iEmployeeId = @UserId
    -----    
   	IF EXISTS ( 
            SELECT 1
            FROM
                tblAcl acl
            WHERE
                acl.iApplicationId = 160
                AND iBit > 0
                AND (acl.iPermissionSetId = 700 AND acl.iSecurityId IN (SELECT Id FROM @UserRoleId))
           )
    BEGIN
		SET @UserCanEdit = 1;
	END 
    -----
    INSERT INTO @Activities
        (ActivityId, Name, StartDate, EndDate, ResponsibleId, ResponsibleName, CreatedBy, CreatorName, Description, IsPermissionControlled, CategoryId, CategoryName, Period, [ReadOnly])
    SELECT
        a.ActivityId,
        a.Name,
        a.StartDate,
        a.EndDate,
        a.ResponsibleId,
        e.strFirstName + ' ' + e.strLastName AS ResponsibleName,
        a.CreatedBy,
        e2.strFirstName + ' ' + e2.strLastName AS CreatorName,
        a.Description,
        a.IsPermissionControlled,
        ac.CategoryId,
        ac.Name AS CategoryName,
        a.Period,
		CASE
			WHEN  @UserCanEdit = 1 THEN 0
			WHEN  @UserCanEdit = 0 AND @UserId = a.CreatedBy THEN 0
			WHEN  @UserCanEdit = 0 AND a.CreatedBy IS NULL THEN 0							
			WHEN  @UserCanEdit = 0 AND @UserId <> a.CreatedBy THEN 1
		END AS [ReadOnly]         
    FROM
        Calendar.Activities a
            LEFT JOIN Calendar.ActivityCategories ac ON a.CategoryId = ac.CategoryId
            LEFT JOIN tblEmployee e ON a.ResponsibleId = e.iEmployeeId
            LEFT JOIN tblEmployee e2 ON a.CreatedBy = e2.iEmployeeId
    WHERE
        dbo.CanUserAccessToActivity(@UserId, a.ActivityId) = 1
        AND
        (
            @Keyword IS NULL
            OR a.Name LIKE '%' + @Keyword + '%'
            OR a.Description LIKE '%' + @Keyword + '%'
        )
        AND
        (
            @CategoryId IS NULL -- Get activities with and without category
            OR (@CategoryId = 0 AND a.CategoryId IS NULL) -- Get activities without category
            OR a.CategoryId = @CategoryId -- Get activities with specific category
        )
        AND
        (
            @ResponsibleId IS NULL
            OR a.ResponsibleId = @ResponsibleId
            OR EXISTS(                      -- Check co-responsible permission
                    SELECT 1
                    FROM
                        Calendar.ActivityResponsibles ar
                    WHERE
                        ar.ActivityId = a.ActivityId
                        AND
                        (
                            (ar.ResponsibleTypeId = 701 AND ar.ResponsibleId = @UserId)
                            OR (ar.ResponsibleTypeId = 702 AND ar.ResponsibleId IN (SELECT Id FROM @UserDepartmentId))
                            OR (ar.ResponsibleTypeId = 703 AND ar.ResponsibleId IN (SELECT Id FROM @UserRoleId))
                        )
            )
        )
        AND 
        (
            @RoleId IS NULL 
            OR (EXISTS(
                SELECT 1 
                FROM tblAcl acl
                WHERE acl.iApplicationId = 160 
                    AND acl.iEntityId = a.ActivityId AND acl.iPermissionSetId = 703 AND acl.iSecurityId = @RoleId))
        )
        AND 
        (
            @DepartmentId IS NULL 
            OR (EXISTS(
                SELECT 1 
                FROM tblAcl acl 
                WHERE iApplicationId = 160 
                    AND acl.iEntityId = a.ActivityId AND acl.iPermissionSetId = 702 AND acl.iSecurityId = @DepartmentId))
        )
        AND
        (
            @PersonId IS NULL 
            OR dbo.CanUserAccessToActivity(@PersonId, a.ActivityId) = 1
        )
        AND
        (
            @AnnualCycleId IS NULL
            OR (@AnnualCycleId IS NOT NULL AND EXISTS( SELECT targ.* FROM Calendar.AnnualCycleActivities targ WHERE targ.AnnualCycleId = @AnnualCycleId AND targ.ActivityId = a.ActivityId))
        )            
        AND (@StartDate IS NULL OR StartDate >= @StartDate)
        AND (@EndDate IS NULL OR EndDate <= @EndDate)
        AND
        (
			@MainResponsibleId IS NULL
			OR
			(EXISTS (SELECT m.* FROM [dbo].[ActivityMainResponsibles]() m WHERE m.UserId = @MainResponsibleId AND m.ActivityId = a.ActivityId))
        )
    ORDER BY StartDate, Name
    -----
    SELECT
        ActivityId, 
        Name, 
        StartDate, 
        EndDate, 
        ResponsibleId, 
        ResponsibleName, 
        CreatedBy,
        CreatorName,         
        Description, 
        IsPermissionControlled, 
        CategoryId, 
        CategoryName,
        Period,
        [ReadOnly]
    FROM @Activities
    -----
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
        ActivityId IN (SELECT ActivityId FROM @Activities)
    ORDER BY ResponsibleTypeId, ResponsibleName
    -----
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
        iEntityId IN (SELECT ActivityId FROM @Activities)
        AND iApplicationId = 160
    ORDER BY AccessTypeId, AccessName
END
GO