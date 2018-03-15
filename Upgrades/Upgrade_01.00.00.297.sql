INSERT INTO #Description VALUES ('Modify procedurs IsUserLeader, CreateActivityForAdminLeader CreateActivityForNormalUser, UpdateActivity, DeleteActivities, CreateActivityTask, UpdateActivityTask')
GO

IF OBJECT_ID('[dbo].[IsUserLeader]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[IsUserLeader]  AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[IsUserLeader]
    @UserId INT
AS
BEGIN
    IF (EXISTS (SELECT 1 FROM DepartmentResponsibles WHERE EmployeeId = @UserId ANd ResponsibleTypeId = 1))
    BEGIN
        SELECT 1
    END
    ELSE
    BEGIN
        SELECT 0
    END
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
    @ResponsibleId INT,
    @CreatedBy INT,
    @IsPermissionControlled BIT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        INSERT INTO 
            [Calendar].[Activities]
                (Name, Description, StartDate, EndDate, ResponsibleId, CreatedBy, CreatedDate, IsPermissionControlled)
            VALUES
                (@Name, @Description, @StartDate, @EndDate, @ResponsibleId, @CreatedBy, GETDATE(), @IsPermissionControlled)
        
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
    @CreatedBy INT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        INSERT INTO 
            [Calendar].[Activities]
                (Name, Description, StartDate, EndDate, ResponsibleId, CreatedBy, CreatedDate, IsPermissionControlled)
            VALUES
                (@Name, @Description, @StartDate, @EndDate, null, @CreatedBy, GETDATE(), 0)
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
    @ResponsibleId INT,
    @UpdatedBy INT,
    @IsPermissionControlled BIT,
    @ActivityTasks AS Calendar.ActivityTaskItems READONLY,
    @ActivityDocuments AS Calendar.ActivityDocumentItems READONLY,
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

IF OBJECT_ID('[Calendar].[DeleteActivities]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[DeleteActivities] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[DeleteActivities] 
    @ActivityIds AS [dbo].[Item] READONLY
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        
        DELETE FROM
            [Calendar].[ActivityTasks]
        WHERE
            ActivityId IN (SELECT Id FROM @ActivityIds)
            
        DELETE FROM
            [Calendar].[ActivityDocuments]
        WHERE
            ActivityId IN (SELECT Id FROM @ActivityIds)
            
        DELETE FROM
            tblAcl
        WHERE
            iApplicationId = 160
            AND iEntityId IN (SELECT Id FROM @ActivityIds)
            
        DELETE FROM
            [Calendar].[Activities]
        WHERE
            ActivityId IN (SELECT Id FROM @ActivityIds)
        
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
        INSERT INTO
            [Calendar].[ActivityTasks]
                (ActivityId, Name, Description, CreatedBy, CreatedDate, IsCompleted)
            VALUES
                (@ActivityId, @Name, @Description, @CreatedBy, GETDATE(), @IsCompleted)
                
        SET @ActivityTaskId = SCOPE_IDENTITY()
        
        SELECT
            ActivityTaskId,
            ActivityId,
            Name,
            Description,
            CreatedBy,
            CreatedDate,
            IsCompleted
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
        UPDATE
            [Calendar].[ActivityTasks]
        SET
            Name = @Name,
            Description = @Description,
            UpdatedBy = @UpdatedBy,
            UpdatedDate = GETDATE(),
            IsCompleted = @IsCompleted
        WHERE
            ActivityTaskId = @ActivityTaskId
            
        SELECT
                ActivityTaskId,
                ActivityId,
                Name,
                Description,
                CreatedBy,
                CreatedDate,
                IsCompleted
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