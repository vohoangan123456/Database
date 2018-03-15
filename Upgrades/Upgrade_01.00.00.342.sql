INSERT INTO #Description VALUES ('Create table, type and modify procedures to support for Activity Categories')
GO

IF  NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'ActivityCategorySortOrder' AND ss.name = N'Calendar')
	CREATE TYPE [Calendar].[ActivityCategorySortOrder] AS TABLE(
		[CategoryId] [int] NOT NULL,
		[SortOrder] [int] NOT NULL
	)
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Calendar].[ActivityCategories]') AND type in (N'U'))
	CREATE TABLE [Calendar].[ActivityCategories]
    (
		CategoryId INT IDENTITY(1, 1) PRIMARY KEY,
        Name NVARCHAR(150) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        SortOrder INT NOT NULL DEFAULT 0,
        IsDeleted BIT NOT NULL DEFAULT 0
    )
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
        WHERE [name] = N'CategoryId' AND [object_id] = OBJECT_ID(N'Calendar.Activities'))
BEGIN
	ALTER TABLE [Calendar].[Activities]	 
    ADD [CategoryId] [int] NULL
END
GO

ALTER TABLE [Calendar].[Activities] 
    ADD CONSTRAINT FK_Activities_ActivityCategories FOREIGN KEY (CategoryId)
    REFERENCES [Calendar].[ActivityCategories] (CategoryId)
GO

IF OBJECT_ID('[Calendar].[GetUndeletedActivityCategories]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[GetUndeletedActivityCategories] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[GetUndeletedActivityCategories]
AS
BEGIN
    SELECT
        CategoryId,
        Name,
        Description
    FROM
        Calendar.ActivityCategories
    WHERE
        IsDeleted = 0
    ORDER BY SortOrder, Name
END
GO

IF OBJECT_ID('[Calendar].[CreateActivityCategory]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[CreateActivityCategory] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[CreateActivityCategory]
    @Name NVARCHAR(100),
    @Description NVARCHAR(400)
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        INSERT INTO
            Calendar.ActivityCategories
                (Name, Description)
            VALUES
                (@Name, @Description);
            
        SELECT SCOPE_IDENTITY()
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK
END CATCH
END
GO

IF OBJECT_ID('[Calendar].[UpdateActivityCategory]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[UpdateActivityCategory] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[UpdateActivityCategory]
    @CategoryId INT,
    @Name NVARCHAR(100),
    @Description NVARCHAR(400)
AS
BEGIN
    UPDATE
        Calendar.ActivityCategories
    SET
        Name = @Name,
        Description = @Description
    WHERE
        CategoryId = @CategoryId
END
GO

IF OBJECT_ID('[Calendar].[DeleteActivityCategories]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[DeleteActivityCategories] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[DeleteActivityCategories]
    @CategoryIds AS [dbo].[Item] READONLY
AS
BEGIN


BEGIN TRY
    BEGIN TRANSACTION;
        UPDATE
            Calendar.Activities
        SET
            CategoryId = NULL
        WHERE
            CategoryId IN (SELECT Id FROM @CategoryIds)
        
        UPDATE
            Calendar.ActivityCategories
        SET
            IsDeleted = 1
        WHERE
            CategoryId IN (SELECT Id FROM @CategoryIds)
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

IF OBJECT_ID('[Calendar].[UpdateActivityCategorySortOrder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[UpdateActivityCategorySortOrder] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[UpdateActivityCategorySortOrder] 
	@ActivityCategorySortOrder AS [Calendar].[ActivityCategorySortOrder] READONLY
AS
BEGIN
    UPDATE
        ac
    SET
        ac.SortOrder = acso.SortOrder
    FROM
        Calendar.ActivityCategories ac
            INNER JOIN @ActivityCategorySortOrder acso
                ON ac.CategoryId = acso.CategoryId
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
        CategoryId,
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

IF OBJECT_ID('[Calendar].[CreateActivityForAdminLeader]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[CreateActivityForAdminLeader] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[CreateActivityForAdminLeader] 
    @Name NVARCHAR(250),
    @Description NVARCHAR(MAX),
    @StartDate DATETIME,
    @EndDate DATETIME,
    @CategoryId INT,
    @ResponsibleId INT,
    @CreatedBy INT,
    @IsPermissionControlled BIT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        INSERT INTO 
            [Calendar].[Activities]
                (Name, Description, StartDate, EndDate, CategoryId, ResponsibleId, CreatedBy, CreatedDate, IsPermissionControlled)
            VALUES
                (@Name, @Description, @StartDate, @EndDate, @CategoryId, @ResponsibleId, @CreatedBy, GETDATE(), @IsPermissionControlled)
        
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

IF OBJECT_ID('[Calendar].[CreateActivityForNormalUser]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[CreateActivityForNormalUser] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[CreateActivityForNormalUser] 
    @Name NVARCHAR(250),
    @Description NVARCHAR(MAX),
    @StartDate DATETIME,
    @EndDate DATETIME,
    @CategoryId INT,
    @CreatedBy INT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        INSERT INTO 
            [Calendar].[Activities]
                (Name, Description, StartDate, EndDate, CategoryId, ResponsibleId, CreatedBy, CreatedDate, IsPermissionControlled)
            VALUES
                (@Name, @Description, @StartDate, @EndDate, @CategoryId, null, @CreatedBy, GETDATE(), 0)
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

IF OBJECT_ID('[Calendar].[UpdateActivity]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[UpdateActivity] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[UpdateActivity] 
    @ActivityId INT,
    @Name NVARCHAR(250),
    @Description NVARCHAR(MAX),
    @StartDate DATETIME,
    @EndDate DATETIME,
    @CategoryId INT,
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
            CategoryId = @CategoryId,
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
    @EndDate DATETIME
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
        a.Description,
        ac.CategoryId,
        ac.Name AS CategoryName
    FROM
        Calendar.Activities a
            LEFT JOIN Calendar.ActivityCategories ac ON a.CategoryId = ac.CategoryId
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
            AND (@StartDate IS NULL OR StartDate >= @StartDate)
            AND (@EndDate IS NULL OR EndDate <= @EndDate)
        )
    ORDER BY StartDate, Name
END
GO