INSERT INTO #Description VALUES ('Add column CompletedDate to table ActivityTasks, modify procedures GetActivityDetailsById, CreateActivityTask, UpdateActivityTask, GetActiveActivitiesForNotification, GetUserActivitiesInYear, GetUserActivitiesInMonthOfYear')

IF NOT EXISTS(SELECT * FROM SYS.COLUMNS
              WHERE NAME = N'CompletedDate' AND OBJECT_ID = OBJECT_ID(N'[Calendar].[ActivityTasks]'))
BEGIN
    ALTER TABLE [Calendar].[ActivityTasks]
        ADD CompletedDate DATE NULL
END
GO

IF OBJECT_ID('[Calendar].[GetActivityDetailsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[GetActivityDetailsById] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[GetActivityDetailsById]
    @ActivityId INT
AS
BEGIN
    SELECT
        ActivityId,
        Name,
        Description,
        StartDate,
        EndDate,
        CreatedBy,
        CreatedDate,
        ResponsibleId,
        IsPermissionControlled
    FROM
        [Calendar].[Activities]
    WHERE
        ActivityId = @ActivityId
    
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

IF OBJECT_ID('[Calendar].[CreateActivityTask]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[CreateActivityTask] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[CreateActivityTask] 
    @ActivityId INT,
    @Name NVARCHAR(250),
    @Description NVARCHAR(MAX),
    @CreatedBy INT,
    @IsCompleted BIT
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
                (ActivityId, Name, Description, CreatedBy, CreatedDate, IsCompleted, CompletedDate)
            VALUES
                (@ActivityId, @Name, @Description, @CreatedBy, GETDATE(), @IsCompleted, @CompletedDate)
                
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

IF OBJECT_ID('[Calendar].[UpdateActivityTask]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[UpdateActivityTask] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[UpdateActivityTask] 
    @ActivityTaskId INT,
    @Name NVARCHAR(250),
    @Description NVARCHAR(MAX),
    @UpdatedBy INT,
    @IsCompleted BIT
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
            CompletedDate = @CompletedDate
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

IF OBJECT_ID('[Calendar].[GetActiveActivitiesForNotification]', 'p') IS NOT NULL
    EXEC ('DROP PROCEDURE [Calendar].[GetActiveActivitiesForNotification]')
GO

IF OBJECT_ID('[Calendar].[GetActiveActivitiesForNotification]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[GetActiveActivitiesForNotification] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[GetActiveActivitiesForNotification]
    @UserId INT,
    @MaxItems INT
AS
BEGIN
    DECLARE @Today DATETIME = CONVERT(DATE, GETDATE());
    DECLARE @UserDepartmentId TABLE(Id INT);
    DECLARE @UserRoleId TABLE(Id INT);
    
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        tblEmployee
    WHERE
        iEmployeeId = @UserId
    
    INSERT INTO @UserRoleId(Id)
    SELECT
        iSecGroupId
    FROM
        relEmployeeSecGroup
    WHERE
        iEmployeeId = @UserId

	SELECT TOP (@MaxItems)
        a.ActivityId,
        a.Name,
        a.StartDate,
        a.EndDate,
        a.ResponsibleId,
        a.CreatedBy,
        a.Description,
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM [Calendar].[Activities] activity INNER JOIN [Calendar].[ActivityTasks] task ON activity.ActivityId = task.ActivityId
                WHERE activity.ActivityId = a.ActivityId AND task.IsCompleted = 0 ) THEN 0
            ELSE 1
        END AS IsCompleted
    FROM
		Calendar.Activities a
    WHERE
        (
            a.CreatedBy = @UserId
            OR a.ResponsibleId = @UserId
            OR EXISTS(SELECT 1 FROM tblAcl WHERE iApplicationId = 160 AND iPermissionSetId = 701 AND iEntityId = a.ActivityId AND iSecurityId = @UserId)
            OR EXISTS(SELECT 1 FROM tblAcl 
                      WHERE iApplicationId = 160 AND iPermissionSetId = 702 AND iEntityId = a.ActivityId 
                            AND iSecurityId IN (SELECT Id FROM @UserDepartmentId))
            OR EXISTS(SELECT 1 FROM tblAcl 
                      WHERE iApplicationId = 160 AND iPermissionSetId = 703 AND iEntityId = a.ActivityId 
                            AND iSecurityId IN (SELECT Id FROM @UserRoleId))
        )
        AND
        (
            (a.StartDate <= @Today AND a.EndDate >= @Today)
            OR (a.EndDate < @Today AND EXISTS (SELECT 1 FROM [Calendar].[ActivityTasks] at WHERE at.ActivityId = a.ActivityId AND at.IsCompleted = 0))
        )
    ORDER BY
        a.StartDate, a.Name
END
GO

IF OBJECT_ID('[Calendar].[GetActivitiesInYear]', 'p') IS NULL
	EXEC ('DROP PROCEDURE [Calendar].[GetActivitiesInYear]')
GO

IF OBJECT_ID('[Calendar].[GetUserActivitiesInYear]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [Calendar].[GetUserActivitiesInYear] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[GetUserActivitiesInYear]
    @UserId INT,
    @Year INT
AS
BEGIN
    DECLARE @UserDepartmentId TABLE(Id INT);
    DECLARE @UserRoleId TABLE(Id INT);
    
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        tblEmployee
    WHERE
        iEmployeeId = @UserId
    
    INSERT INTO @UserRoleId(Id)
    SELECT
        iSecGroupId
    FROM
        relEmployeeSecGroup
    WHERE
        iEmployeeId = @UserId

    SELECT
        a.ActivityId,
        a.Name,
        a.Description,
        a.StartDate,
        a.EndDate,
        a.ResponsibleId,
        e1.strFirstName + ' ' + e1.strLastName AS ResponsibleName,
        a.CreatedBy,
        e2.strFirstName + ' ' + e2.strLastName AS CreatorName,
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM [Calendar].[Activities] activity INNER JOIN [Calendar].[ActivityTasks] task ON activity.ActivityId = task.ActivityId
                WHERE activity.ActivityId = a.ActivityId AND task.IsCompleted = 0 ) THEN 0
            ELSE 1
        END AS IsCompleted
    FROM
        [Calendar].[Activities] a
            LEFT JOIN tblEmployee e1 ON a.ResponsibleId = e1.iEmployeeId
            INNER JOIN tblEmployee e2 ON a.CreatedBy = e2.iEmployeeId
    WHERE
        (
            a.CreatedBy = @UserId
            OR a.ResponsibleId = @UserId
            OR EXISTS(SELECT 1 FROM tblAcl WHERE iApplicationId = 160 AND iPermissionSetId = 701 AND iEntityId = a.ActivityId AND iSecurityId = @UserId)
            OR EXISTS(SELECT 1 FROM tblAcl 
                      WHERE iApplicationId = 160 AND iPermissionSetId = 702 AND iEntityId = a.ActivityId 
                            AND iSecurityId IN (SELECT Id FROM @UserDepartmentId))
            OR EXISTS(SELECT 1 FROM tblAcl 
                      WHERE iApplicationId = 160 AND iPermissionSetId = 703 AND iEntityId = a.ActivityId 
                            AND iSecurityId IN (SELECT Id FROM @UserRoleId))
        )
        AND
        (
            Year(StartDate) = @Year
            OR Year(EndDate) = @Year
        )
    ORDER BY a.StartDate, a.Name
END
GO

IF OBJECT_ID('[Calendar].[GetActivitiesInMonthOfYear]', 'p') IS NULL
	EXEC ('DROP PROCEDURE [Calendar].[GetActivitiesInMonthOfYear]')
GO

IF OBJECT_ID('[Calendar].[GetUserActivitiesInMonthOfYear]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [Calendar].[GetUserActivitiesInMonthOfYear]  AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[GetUserActivitiesInMonthOfYear]
    @UserId INT,
    @Year INT,
    @Month INT
AS
BEGIN
    DECLARE @UserDepartmentId TABLE(Id INT);
    DECLARE @UserRoleId TABLE(Id INT);
    
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        tblEmployee
    WHERE
        iEmployeeId = @UserId
    
    INSERT INTO @UserRoleId(Id)
    SELECT
        iSecGroupId
    FROM
        relEmployeeSecGroup
    WHERE
        iEmployeeId = @UserId

    SELECT
        a.ActivityId,
        a.Name,
        a.Description,
        a.StartDate,
        a.EndDate,
        a.ResponsibleId,
        e1.strFirstName + ' ' + e1.strLastName AS ResponsibleName,
        a.CreatedBy,
        e2.strFirstName + ' ' + e2.strLastName AS CreatorName,
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM [Calendar].[Activities] activity INNER JOIN [Calendar].[ActivityTasks] task ON activity.ActivityId = task.ActivityId
                WHERE activity.ActivityId = a.ActivityId AND task.IsCompleted = 0 ) THEN 0
            ELSE 1
        END AS IsCompleted
    FROM
        [Calendar].[Activities] a
            LEFT JOIN tblEmployee e1 ON a.ResponsibleId = e1.iEmployeeId
            INNER JOIN tblEmployee e2 ON a.CreatedBy = e2.iEmployeeId
    WHERE
        (
            a.CreatedBy = @UserId
            OR a.ResponsibleId = @UserId
            OR EXISTS(SELECT 1 FROM tblAcl WHERE iApplicationId = 160 AND iPermissionSetId = 701 AND iEntityId = a.ActivityId AND iSecurityId = @UserId)
            OR EXISTS(SELECT 1 FROM tblAcl 
                      WHERE iApplicationId = 160 AND iPermissionSetId = 702 AND iEntityId = a.ActivityId 
                            AND iSecurityId IN (SELECT Id FROM @UserDepartmentId))
            OR EXISTS(SELECT 1 FROM tblAcl 
                      WHERE iApplicationId = 160 AND iPermissionSetId = 703 AND iEntityId = a.ActivityId 
                            AND iSecurityId IN (SELECT Id FROM @UserRoleId))
        )
        ANd
        (
            (Year(StartDate) = @Year AND Month(StartDate) = @Month)
            OR (Year(EndDate) = @Year ANd Month(EndDate) = @Month)
        )
    ORDER BY a.StartDate, a.Name
END
GO