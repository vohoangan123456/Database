INSERT INTO #Description VALUES ('Create new table, new procedures, modify existing procedures to support for co-responsibles')
GO

-- Create table ActivityResponsibles and its foreign keys
IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES  WHERE TABLE_SCHEMA = 'Calendar' AND  TABLE_NAME = 'ActivityResponsibles'))
BEGIN
    CREATE TABLE [Calendar].[ActivityResponsibles]
    (
        ActivityResponsibleId INT IDENTITY(1, 1) PRIMARY KEY,
        ActivityId INT NOT NULL,
        ResponsibleTypeId INT NOT NULL,
        ResponsibleId INT NOT NULL
	)
END
GO

DECLARE @sql1 NVARCHAR(MAX)
SET @sql1 = dbo.fn136_GetSqlDropConstraintKey('[Calendar].[ActivityResponsibles]', 'FK_ActivityResponsibles_Activities') 
IF @sql1 IS NOT NULL
BEGIN
    EXEC(@sql1)
END
GO

ALTER TABLE [Calendar].[ActivityResponsibles] ADD CONSTRAINT FK_ActivityResponsibles_Activities FOREIGN KEY (ActivityId)
    REFERENCES [Calendar].[Activities] (ActivityId)
GO

DECLARE @sql2 NVARCHAR(MAX)
SET @sql2 = dbo.fn136_GetSqlDropConstraintKey('[Calendar].[ActivityResponsibles]', 'FK_ActivityResponsibles_PermissionSet') 
IF @sql2 IS NOT NULL
BEGIN
    EXEC(@sql2)
END
GO

ALTER TABLE [Calendar].[ActivityResponsibles] ADD CONSTRAINT FK_ActivityResponsibles_PermissionSet FOREIGN KEY (ResponsibleTypeId)
    REFERENCES [dbo].[tblPermissionSet] (iPermissionSetId)
GO

-- Create types
IF  NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'ActivityResponsibleItems' AND ss.name = N'Calendar')
    CREATE TYPE [Calendar].[ActivityResponsibleItems] AS TABLE
    (
        ActivityId INT,
        ResponsibleTypeId INT,
        ResponsibleId INT
    )
GO

-- Modify procedures
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

IF OBJECT_ID('[Calendar].[UpdateActivity]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[UpdateActivity] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[UpdateActivity] 
    @ActivityId INT,
    @Name NVARCHAR(250),
    @Description NVARCHAR(MAX),
    @StartDate DATETIME,
    @EndDate DATETIME,
    @ResponsibleId INT,
    @UpdatedBy INT,
    @IsPermissionControlled BIT,
    @ActivityTasks AS Calendar.ActivityTaskItems READONLY,
    @ActivityDocuments AS Calendar.ActivityDocumentItems READONLY,
    @ActivityResponsibles AS Calendar.ActivityResponsibleItems READONLY,
    @ActivityAccesses AS Calendar.ActivityAccessItems READONLY
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
            ResponsibleId = @ResponsibleId,
            UpdatedBy = @UpdatedBy,
            UpdatedDate = @Now,
            IsPermissionControlled = @IsPermissionControlled
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
            (ActivityId, ResponsibleTypeId, ResponsibleId)
            SELECT
                ActivityId,
                ResponsibleTypeId,
                ResponsibleId
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

IF OBJECT_ID('[Calendar].[ActivityGetUserResponsibles]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[ActivityGetUserResponsibles] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[ActivityGetUserResponsibles]
    @ActivityIds AS [dbo].[Item] READONLY
AS
BEGIN
    DECLARE @ActivityResponsibleIds TABLE (ActivityId INT NOT NULL, ResponsibleId INT NOT NULL);
    
    INSERT INTO @ActivityResponsibleIds
        SELECT
            ActivityId,
            ResponsibleId
        FROM
            Calendar.Activities
        WHERE
            ActivityId IN (SELECT Id FROM @ActivityIds)
            AND ResponsibleId IS NOT NULL
        
    INSERT INTO @ActivityResponsibleIds
        SELECT
            ActivityId,
            ResponsibleId
        FROM
            Calendar.ActivityResponsibles
        WHERE
            ActivityId IN (SELECT Id FROM @ActivityIds)
            AND ResponsibleTypeId = 701 -- Responsible person
            
    INSERT INTO @ActivityResponsibleIds
        SELECT
            ActivityId,
            iEmployeeId
        FROM
            Calendar.ActivityResponsibles ar
                INNER JOIN tblEmployee e 
                    ON ar.ResponsibleTypeId = 702 -- Responsible department
                    AND ar.ResponsibleId = e.iDepartmentId
        WHERE
            ActivityId IN (SELECT Id FROM @ActivityIds)
        
    INSERT INTO @ActivityResponsibleIds
        SELECT
            ActivityId,
            iEmployeeId
        FROM
            Calendar.ActivityResponsibles ar
                INNER JOIN relEmployeeSecGroup esg
                    ON ar.ResponsibleTypeId = 703 -- Responsible role
                    AND ar.ResponsibleId = esg.iSecGroupId
        WHERE
            ActivityId IN (SELECT Id FROM @ActivityIds)
    
    SELECT
        DISTINCT ar.ActivityId, ar.ResponsibleId, e.strEmail AS ResponsibleEmail
    FROM
        @ActivityResponsibleIds ar
            INNER JOIN tblEmployee e
                ON ar.ResponsibleId = e.iEmployeeId
END
GO

IF OBJECT_ID('[dbo].[CanUserAccessToActivity]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[CanUserAccessToActivity]() RETURNS BIT AS BEGIN RETURN 0; END')
GO

ALTER FUNCTION [dbo].[CanUserAccessToActivity]
(
	@UserId INT,
	@ActivityId INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @Result BIT = 0;
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
        
    IF EXISTS
    (
        SELECT 1
        FROM Calendar.Activities a
        WHERE
            a.ActivityId = @ActivityId
            AND 
            (
                a.IsPermissionControlled = 0
                OR
                (
                    CreatedBy = @UserId             -- Check creator permission
                    OR ResponsibleId = @UserId      -- Check main responsible permission
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
                    OR EXISTS(                      -- Check read permission
                        SELECT 1
                        FROM
                            tblAcl acl
                        WHERE
                            acl.iApplicationId = 160
                            AND acl.iEntityId = a.ActivityId
                            AND
                            (
                                (acl.iPermissionSetId = 701 AND acl.iSecurityId = @UserId)
                                OR (acl.iPermissionSetId = 702 AND acl.iSecurityId IN (SELECT Id FROM @UserDepartmentId))
                                OR (acl.iPermissionSetId = 703 AND acl.iSecurityId IN (SELECT Id FROM @UserRoleId))
                            )
                    )
                )
            )
    )
    BEGIN
        SET @Result = 1;
    END
    
    RETURN @Result;
END
GO

IF OBJECT_ID('[Calendar].[SearchActivities]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[SearchActivities] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[SearchActivities]
    @UserId INT,
    @Keyword NVARCHAR(MAX),
    @PersonId INT,
    @DepartmentId INT,
    @RoleId INT,
    @ResponsibleId INT,
    @StartDate DATETIME,
    @EndDate DATETIME,
    @Name NVARCHAR(250),
    @Description NVARCHAR(MAX)
AS
BEGIN
    -- This procedure is used in Activities Management view and Search Activities View
    -- Activities Management View allows users to search activities by Name & Description
    -- Search Activities View allows users to search activities by Keyword
    
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
        a.StartDate,
        a.EndDate,
        a.ResponsibleId,
        a.CreatedBy,
        a.Description
    FROM
        Calendar.Activities a
    WHERE
        dbo.CanUserAccessToActivity(@UserId, a.ActivityId) = 1
        AND
        (
            (
                @Keyword IS NULL
                OR a.Name LIKE '%' + @Keyword + '%'
                OR a.Description LIKE '%' + @Keyword + '%'
            )
            AND
            (
                @PersonId IS NULL 
                OR dbo.CanUserAccessToActivity(@PersonId, a.ActivityId) = 1
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
                @RoleId IS NULL 
                OR (EXISTS(
                    SELECT 1 
                    FROM tblAcl acl
                    WHERE acl.iApplicationId = 160 
                        AND acl.iEntityId = a.ActivityId AND acl.iPermissionSetId = 703 AND acl.iSecurityId = @RoleId))
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
            AND (@StartDate IS NULL OR StartDate >= @StartDate)
            AND (@EndDate IS NULL OR EndDate <= @EndDate)
            AND (@Name IS NULL OR Name LIKE '%' + @Name + '%')
            AND (@Description IS NULL OR Description LIKE '%' + @Description + '%')
        )
    ORDER BY StartDate, Name
END
GO

IF OBJECT_ID('[Calendar].[ActivityIsCreatorOrResponsible]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[ActivityIsCreatorOrResponsible] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[ActivityIsCreatorOrResponsible] 
    @UserId INT,
    @ActivityIds AS [dbo].[Item] READONLY
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

    IF EXISTS(
        SELECT 1 
        FROM [Calendar].[Activities] 
        WHERE CreatedBy <> @UserId 
            AND ResponsibleId <> @UserId AND ActivityId IN (SELECT Id FROM @ActivityIds))
    BEGIN
        SELECT 0
    END
    ELSE
    BEGIN
        IF EXISTS
        (
            SELECT 1
            FROM
                Calendar.ActivityResponsibles ar
            WHERE
                ar.ActivityId IN (SELECT Id FROM @ActivityIds)
                AND
                (
                    (ar.ResponsibleTypeId = 701 AND ar.ResponsibleId <> @UserId)
                    OR (ar.ResponsibleTypeId = 702 AND ar.ResponsibleId NOT IN (SELECT Id FROM @UserDepartmentId))
                    OR (ar.ResponsibleTypeId = 703 AND ar.ResponsibleId NOT IN (SELECT Id FROM @UserRoleId))
                )
        )
        BEGIN
            SELECT 0
        END
        ELSE
        BEGIN
            SELECT 1
        END
    END
    
END
GO

IF OBJECT_ID('[Calendar].[GetActivitiesWithUncompletedTasks]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[GetActivitiesWithUncompletedTasks] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[GetActivitiesWithUncompletedTasks] 
AS
BEGIN
    DECLARE @Today DATE = CONVERT(DATE, GETDATE());
    
    SELECT
        a.ActivityId,
        a.Name,
        a.Description,
        a.StartDate,
        a.EndDate,
        a.ResponsibleId
    FROM
        Calendar.Activities a
    WHERE
        a.EndDate = @Today
        AND EXISTS(
            SELECT 1
            FROM Calendar.ActivityTasks at
            WHERE
                a.ActivityId = at.ActivityId
                AND at.IsCompleted = 0)
END
GO

IF OBJECT_ID('[Calendar].[IsUserCreatorOfActivities]', 'p') IS NOT NULL
	EXEC ('DROP PROCEDURE [Calendar].[IsUserCreatorOfActivities]')
GO

IF OBJECT_ID('[Calendar].[ActivityIsCreator]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[ActivityIsCreator] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[ActivityIsCreator] 
    @UserId INT,
    @ActivityIds AS [dbo].[Item] READONLY
AS
BEGIN
    IF EXISTS(SELECT 1 FROM [Calendar].[Activities] WHERE CreatedBy <> @UserId AND ActivityId IN (SELECT Id FROM @ActivityIds))
    BEGIN
        SELECT 0
    END
    ELSE
    BEGIN
        SELECT 1
    END
    
END
GO