INSERT INTO #Description VALUES ('Modify procedures SearchActivities, GetActivityDetailsById, ActivityGetUserResponsibles, GetUserActivitiesInMonthOfYear')
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

IF OBJECT_ID('[Calendar].[ActivityGetUserResponsibles]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[ActivityGetUserResponsibles] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[ActivityGetUserResponsibles]
    @ActivityIds AS [dbo].[Item] READONLY
AS
BEGIN
    DECLARE @ActivityResponsibleIds TABLE (ActivityId INT NOT NULL, ResponsibleId INT NOT NULL, ResponsibleTypeId INT NOT NULL);
    
    INSERT INTO @ActivityResponsibleIds
        SELECT
            ActivityId,
            ResponsibleId,
            701 -- Main responsible is person
        FROM
            Calendar.Activities
        WHERE
            ActivityId IN (SELECT Id FROM @ActivityIds)
            AND ResponsibleId IS NOT NULL
        
    INSERT INTO @ActivityResponsibleIds
        SELECT
            ActivityId,
            ResponsibleId,
            ResponsibleTypeId
        FROM
            Calendar.ActivityResponsibles
        WHERE
            ActivityId IN (SELECT Id FROM @ActivityIds)
            AND ResponsibleTypeId = 701 -- Responsible person
            
    INSERT INTO @ActivityResponsibleIds
        SELECT
            ActivityId,
            iEmployeeId,
            ar.ResponsibleTypeId
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
            iEmployeeId,
            ar.ResponsibleTypeId
        FROM
            Calendar.ActivityResponsibles ar
                INNER JOIN relEmployeeSecGroup esg
                    ON ar.ResponsibleTypeId = 703 -- Responsible role
                    AND ar.ResponsibleId = esg.iSecGroupId
        WHERE
            ActivityId IN (SELECT Id FROM @ActivityIds)
    
    SELECT DISTINCT 
        ar.ActivityId, 
        ar.ResponsibleId, 
        ar.ResponsibleTypeId,
        e.strFirstName + ' ' + strLastName AS ResponsibleName, 
        e.strEmail AS ResponsibleEmail
    FROM
        @ActivityResponsibleIds ar
            INNER JOIN tblEmployee e
                ON ar.ResponsibleId = e.iEmployeeId
END
GO

IF OBJECT_ID('[Calendar].[GetUserActivitiesInMonthOfYear]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[GetUserActivitiesInMonthOfYear] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[GetUserActivitiesInMonthOfYear]
    @UserId INT,
    @Year INT,
    @Month INT
AS
BEGIN
    DECLARE @FirstDateOfMonth DATETIME;
    DECLARE @FirstDateOfNextMonth DATETIME;
    
    SET @FirstDateOfMonth = CAST(CONVERT(VARCHAR, @Year) + '-' + CONVERT(VARCHAR, @Month) + '-' + CONVERT(VARCHAR, 1) AS DATETIME)
    IF(@Month < 12)
    BEGIN
        SET @FirstDateOfNextMonth = CAST(CONVERT(VARCHAR, @Year) + '-' + CONVERT(VARCHAR, @Month + 1) + '-' + CONVERT(VARCHAR, 1) AS DATETIME)
    END
    ELSE
    BEGIN
        SET @FirstDateOfNextMonth = CAST(CONVERT(VARCHAR, @Year + 1) + '-' + CONVERT(VARCHAR, 1) + '-' + CONVERT(VARCHAR, 1) AS DATETIME)
    END
    
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
        dbo.CanUserAccessToActivity(@UserId, a.ActivityId) = 1
        AND
        (
            EndDate >= @FirstDateOfMonth
            OR (StartDate >= @FirstDateOfMonth AND StartDate < @FirstDateOfNextMonth)
        )
    ORDER BY a.StartDate, a.Name
END
GO