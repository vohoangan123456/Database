INSERT INTO #Description VALUES ('Create new script for module Activity, Activity Task')
GO

-- Insert data for the module AnnualCycle
IF NOT EXISTS(SELECT 1 FROM tblApplication WHERE iApplicationId = 160)
BEGIN
    INSERT INTO
        tblApplication
            (iApplicationId, strName, strDescription, iMajorVersion, iMinorVersion, iBuildVersion, iActive, iHasAdmin, strAdminIconUrl, strAdminEntryPage)
        VALUES
            (160, 'AnnualCycle', 'Annual Cycle', 1, 0, 0, - 1, 0, '', '')
END
GO

IF NOT EXISTS(SELECT 1 FROM tblPermissionSet WHERE iPermissionSetId = 700)
BEGIN
    INSERT INTO
        tblPermissionSet
            (iPermissionSetId, iPermissionSetTypeId, strName, strDescription)
        VALUES
            (700, 2, 'AnnualCycle', 'AnnualCycle')
END
GO

IF NOT EXISTS(SELECT 1 FROM tblPermissionSet WHERE iPermissionSetId = 701)
BEGIN
    INSERT INTO
        tblPermissionSet
            (iPermissionSetId, iPermissionSetTypeId, strName, strDescription)
        VALUES
            (701, 2, 'AnnualCycleRole', 'AnnualCycleRole')
END
GO

IF NOT EXISTS(SELECT 1 FROM tblPermissionSet WHERE iPermissionSetId = 702)
BEGIN
    INSERT INTO
        tblPermissionSet
            (iPermissionSetId, iPermissionSetTypeId, strName, strDescription)
        VALUES
            (702, 2, 'AnnualCycleDepartment', 'AnnualCycleDepartment')
END
GO

IF NOT EXISTS(SELECT 1 FROM tblPermissionSet WHERE iPermissionSetId = 703)
BEGIN
    INSERT INTO
        tblPermissionSet
            (iPermissionSetId, iPermissionSetTypeId, strName, strDescription)
        VALUES
            (703, 2, 'AnnualCycleRole', 'AnnualCycleRole')
END
GO

-- Create schema Calendar

IF (NOT EXISTS (SELECT 1 FROM SYS.SCHEMAS WHERE name = 'Calendar'))
BEGIN
    EXEC('CREATE SCHEMA Calendar')
END
GO

-- Create types

IF  NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'ActivityTaskItems' AND ss.name = N'Calendar')
    CREATE TYPE [Calendar].[ActivityTaskItems] AS TABLE
    (
        ActivityId INT,
        Name NVARCHAR(250),
        Description NVARCHAR(MAX),
        CreatedBy INT,
        CreatedDate DATETIME,
        UpdatedBy INT,
        IsCompleted BIT
    )
GO

IF  NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'ActivityDocumentItems' AND ss.name = N'Calendar')
    CREATE TYPE [Calendar].[ActivityDocumentItems] AS TABLE
    (
        ActivityId INT,
        DocumentId INT
    )
GO

IF  NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'ActivityAccessItems' AND ss.name = N'Calendar')
    CREATE TYPE [Calendar].[ActivityAccessItems] AS TABLE
    (
        ActivityId INT,
        AccessTypeId INT,
        AccessId INT
    )
GO

-- Create tables

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES  WHERE TABLE_SCHEMA = 'Calendar' AND  TABLE_NAME = 'Activities'))
BEGIN
    CREATE TABLE [Calendar].[Activities]
    (
        ActivityId INT IDENTITY(1, 1) PRIMARY KEY,
        Name NVARCHAR(250) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        StartDate DATETIME NOT NULL,
        EndDate DATETIME NOT NULL,
        ResponsibleId INT NULL,
        CreatedBy INT NOT NULL,
        CreatedDate DATETIME NOT NULL,
        UpdatedBy INT NULL,
        UpdatedDate DATETIME NULL,
        IsPermissionControlled BIT NOT NULL
	)
END
GO

DECLARE @sql1 NVARCHAR(MAX)
SET @sql1 = dbo.fn136_GetSqlDropConstraintKey('[Calendar].[Activities]', 'FK_Activities_tblEmployee_ResponsibleId') 
IF @sql1 IS NOT NULL
BEGIN
    EXEC(@sql1)
END
GO

ALTER TABLE [Calendar].[Activities] ADD CONSTRAINT FK_Activities_tblEmployee_ResponsibleId FOREIGN KEY (ResponsibleId)
    REFERENCES tblEmployee (iEmployeeId)
GO

DECLARE @sql2 NVARCHAR(MAX)
SET @sql2 = dbo.fn136_GetSqlDropConstraintKey('[Calendar].[Activities]', 'FK_Activities_tblEmployee_CreatedBy') 
IF @sql2 IS NOT NULL
BEGIN
    EXEC(@sql2)
END
GO

ALTER TABLE [Calendar].[Activities] ADD CONSTRAINT FK_Activities_tblEmployee_CreatedBy FOREIGN KEY (CreatedBy)
    REFERENCES tblEmployee (iEmployeeId)
GO

DECLARE @sql3 NVARCHAR(MAX)
SET @sql3 = dbo.fn136_GetSqlDropConstraintKey('[Calendar].[Activities]', 'FK_Activities_tblEmployee_UpdatedBy') 
IF @sql3 IS NOT NULL
BEGIN
    EXEC(@sql3)
END
GO

ALTER TABLE [Calendar].[Activities] ADD CONSTRAINT FK_Activities_tblEmployee_UpdatedBy FOREIGN KEY (UpdatedBy)
    REFERENCES tblEmployee (iEmployeeId)
GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES  WHERE TABLE_SCHEMA = 'Calendar' AND  TABLE_NAME = 'ActivityTasks'))
BEGIN
    CREATE TABLE [Calendar].[ActivityTasks]
    (
        ActivityTaskId INT IDENTITY(1, 1) PRIMARY KEY,
        ActivityId INT NOT NULL,
        Name NVARCHAR(250) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        CreatedBy INT NOT NULL,
        CreatedDate DATETIME NOT NULL,
        UpdatedBy INT NULL,
        UpdatedDate DATETIME NULL,
        IsCompleted BIT NOT NULL
	)
END
GO

DECLARE @sql4 NVARCHAR(MAX)
SET @sql4 = dbo.fn136_GetSqlDropConstraintKey('[Calendar].[ActivityTasks]', 'FK_ActivityTasks_Activities') 
IF @sql4 IS NOT NULL
BEGIN
    EXEC(@sql4)
END
GO

ALTER TABLE [Calendar].[ActivityTasks] ADD CONSTRAINT FK_ActivityTasks_Activities FOREIGN KEY (ActivityId)
    REFERENCES [Calendar].[Activities] (ActivityId)
GO

DECLARE @sql5 NVARCHAR(MAX)
SET @sql5 = dbo.fn136_GetSqlDropConstraintKey('[Calendar].[ActivityTasks]', 'FK_ActivityTasks_tblEmployee_CreatedBy') 
IF @sql5 IS NOT NULL
BEGIN
    EXEC(@sql5)
END
GO

ALTER TABLE [Calendar].[ActivityTasks] ADD CONSTRAINT FK_ActivityTasks_tblEmployee_CreatedBy FOREIGN KEY (CreatedBy)
    REFERENCES tblEmployee (iEmployeeId)
GO

DECLARE @sql6 NVARCHAR(MAX)
SET @sql6 = dbo.fn136_GetSqlDropConstraintKey('[Calendar].[ActivityTasks]', 'FK_ActivityTasks_tblEmployee_UpdatedBy') 
IF @sql6 IS NOT NULL
BEGIN
    EXEC(@sql6)
END
GO

ALTER TABLE [Calendar].[ActivityTasks] ADD CONSTRAINT FK_ActivityTasks_tblEmployee_UpdatedBy FOREIGN KEY (UpdatedBy)
    REFERENCES tblEmployee (iEmployeeId)
GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'Calendar' AND  TABLE_NAME = 'ActivityDocuments'))
BEGIN
    CREATE TABLE [Calendar].[ActivityDocuments]
    (
        ActivityDocumentId INT IDENTITY(1, 1) PRIMARY KEY,
        ActivityId INT NOT NULL,
        DocumentId INT NOT NULL
	)
END
GO

DECLARE @sql7 NVARCHAR(MAX)
SET @sql7 = dbo.fn136_GetSqlDropConstraintKey('[Calendar].[ActivityDocuments]', 'FK_ActivityDocuments_Activities') 
IF @sql7 IS NOT NULL
BEGIN
    EXEC(@sql7)
END
GO

ALTER TABLE [Calendar].[ActivityDocuments] ADD CONSTRAINT FK_ActivityDocuments_Activities FOREIGN KEY (ActivityId)
    REFERENCES [Calendar].[Activities] (ActivityId)
GO

-- Create procedures

IF OBJECT_ID('[dbo].[IsUserLeader]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[IsUserLeader]  AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[IsUserLeader]
    @UserId INT
AS
BEGIN
    IF (EXISTS (SELECT 1 FROM DepartmentResponsibles WHERE EmployeeId = @UserId))
    BEGIN
        SELECT 1
    END
    ELSE
    BEGIN
        SELECT 0
    END
END
GO

IF OBJECT_ID('[Calendar].[GetActiveActivities]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[GetActiveActivities] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[GetActiveActivities] 
AS
BEGIN
    DECLARE @Today DATETIME = CONVERT(DATE, GETDATE());

	SELECT
        ActivityId,
        Name,
        StartDate,
        EndDate,
        ResponsibleId,
        CreatedBy,
        Description
    FROM
		Calendar.Activities
    WHERE
        StartDate <= @Today
        AND EndDate >= @Today
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
        IsCompleted
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

IF OBJECT_ID('[Calendar].[SearchActivities]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[SearchActivities] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[SearchActivities]
    @PersonId INT,
    @DepartmentId INT,
    @RoleId INT,
    @StartDate DATETIME,
    @EndDate DATETIME,
    @Name NVARCHAR(250),
    @Description NVARCHAR(MAX)
AS
BEGIN
    SELECT
        ActivityId,
        Name,
        StartDate,
        EndDate,
        ResponsibleId,
        CreatedBy,
        Description
    FROM
        Calendar.Activities
    WHERE
        (@PersonId IS NULL OR (EXISTS(SELECT 1 FROM tblAcl WHERE iApplicationId = 160 AND iEntityId = ActivityId AND iPermissionSetId = 701 AND iSecurityId = @PersonId)))
        AND (@DepartmentId IS NULL OR (EXISTS(SELECT 1 FROM tblAcl WHERE iApplicationId = 160 AND iEntityId = ActivityId AND iPermissionSetId = 702 AND iSecurityId = @DepartmentId)))
        AND (@RoleId IS NULL OR (EXISTS(SELECT 1 FROM tblAcl WHERE iApplicationId = 160 AND iEntityId = ActivityId AND iPermissionSetId = 703 AND iSecurityId = @RoleId)))
        AND (@StartDate IS NULL OR StartDate >= @StartDate)
        AND (@EndDate IS NULL OR EndDate <= @EndDate)
        AND (@Name IS NULL OR Name LIKE '%' + @Name + '%')
        AND (@Description IS NULL OR Description LIKE '%' + @Description + '%')
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
END CATCH
END
GO

IF OBJECT_ID('[Calendar].[IsUserCreatorOrResponsibleOfActivities]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[IsUserCreatorOrResponsibleOfActivities] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[IsUserCreatorOrResponsibleOfActivities] 
    @UserId INT,
    @ActivityIds AS [dbo].[Item] READONLY
AS
BEGIN
    IF EXISTS(SELECT 1 FROM [Calendar].[Activities] WHERE CreatedBy <> @UserId AND ResponsibleId <> @UserId AND ActivityId IN (SELECT Id FROM @ActivityIds))
    BEGIN
        SELECT 0
    END
    ELSE
    BEGIN
        SELECT 1
    END
    
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
END CATCH
END
GO

IF OBJECT_ID('[Calendar].[IsUserCreatorOfActivities]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[IsUserCreatorOfActivities] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[IsUserCreatorOfActivities] 
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
    ROLLBACK;
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
    ROLLBACK;
END CATCH
END
GO

IF OBJECT_ID('[dbo].[m136_be_IsDocumentTemplateExpired]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_IsDocumentTemplateExpired] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_IsDocumentTemplateExpired]
    @DocumentId INT
AS
BEGIN
    IF EXISTS (
                SELECT 1 
                FROM
                    m136_tblDocument d
                        INNER JOIN m136_tblDocumentType dt ON d.iDocumentTypeId = dt.iDocumentTypeId
                WHERE
                    d.iDocumentId = @DocumentId
                    AND d.iLatestVersion = 1
                    AND dt.Type = 0
                    AND
                    (
                        dt.iDeleted = 1
                        OR dt.bInactive = 1
                    )
            )        
    BEGIN
        SELECT 1
    END
    ELSE
    BEGIN
        SELECT 0
    END
END
GO