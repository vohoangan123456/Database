INSERT INTO #Description VALUES ('Modify procedures GetUserDepartmentIds, SearchActivities, DeleteActivities')
GO

IF OBJECT_ID('[dbo].[GetUserDepartmentIds]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetUserDepartmentIds] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetUserDepartmentIds]
    @UserId INT
AS
BEGIN
    DECLARE @UserDepartmentIds TABLE(Id INT);
        
    INSERT INTO @UserDepartmentIds(Id)
    SELECT
        iDepartmentId
    FROM
        tblEmployee
    WHERE
        iEmployeeId = @UserId
        
    INSERT INTO @UserDepartmentIds(Id)
    SELECT
        iDepartmentId
    FROM
        relEmployeeDepartment
    WHERE iEmployeeId = @UserId
    
    SELECT Id FROM @UserDepartmentIds
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
    DECLARE @Activities TABLE
    (
        ActivityId INT, 
        Name NVARCHAR(250), 
        StartDate DATETIME, 
        EndDate DATETIME, 
        ResponsibleId INT, 
        ResponsibleName NVARCHAR(250), 
        CreatedBy INT, 
        Description NVARCHAR(MAX), 
        IsPermissionControlled BIT, 
        CategoryId INT, 
        CategoryName NVARCHAR(150)
    );
        
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        tblEmployee
    WHERE
        iEmployeeId = @UserId
        
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        relEmployeeDepartment
    WHERE iEmployeeId = @UserId
    
    INSERT INTO @UserRoleId(Id)
    SELECT
        iSecGroupId
    FROM
        relEmployeeSecGroup
    WHERE
        iEmployeeId = @UserId
    
    INSERT INTO @Activities
        (ActivityId, Name, StartDate, EndDate, ResponsibleId, ResponsibleName, CreatedBy, Description, IsPermissionControlled, CategoryId, CategoryName)
    SELECT
        a.ActivityId,
        a.Name,
        a.StartDate,
        a.EndDate,
        a.ResponsibleId,
        e.strFirstName + ' ' + e.strLastName AS ResponsibleName,
        a.CreatedBy,
        a.Description,
        a.IsPermissionControlled,
        ac.CategoryId,
        ac.Name AS CategoryName
    FROM
        Calendar.Activities a
            LEFT JOIN Calendar.ActivityCategories ac ON a.CategoryId = ac.CategoryId
            LEFT JOIN tblEmployee e ON a.ResponsibleId = e.iEmployeeId
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
    
    SELECT
        ActivityId, 
        Name, 
        StartDate, 
        EndDate, 
        ResponsibleId, 
        ResponsibleName, 
        CreatedBy, 
        Description, 
        IsPermissionControlled, 
        CategoryId, 
        CategoryName
    FROM @Activities
    
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
            [Calendar].[ActivityResponsibles]
        WHERE
            ActivityId IN (SELECT Id FROM @ActivityIds)
        
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