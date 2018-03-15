INSERT INTO #Description VALUES ('Modify procedure [Calendar].[SearchActivities]')
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
    WHERE (ResponibilityType IS NULL OR ResponibilityType = 0) AND
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