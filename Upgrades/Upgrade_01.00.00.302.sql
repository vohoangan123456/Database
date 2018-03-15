INSERT INTO #Description VALUES ('Apply permission controll to some existing procedures')
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
        FROM Calendar.Activities
        WHERE
            ActivityId = @ActivityId
            AND 
            (
                IsPermissionControlled = 0
                OR
                (
                    CreatedBy = @UserId
                    OR ResponsibleId = @UserId
                    OR EXISTS(SELECT 1 FROM tblAcl WHERE iApplicationId = 160 AND iPermissionSetId = 701 AND iEntityId = ActivityId AND iSecurityId = @UserId)
                    OR EXISTS(SELECT 1 FROM tblAcl 
                              WHERE iApplicationId = 160 AND iPermissionSetId = 702 AND iEntityId = ActivityId 
                                    AND iSecurityId IN (SELECT Id FROM @UserDepartmentId))
                    OR EXISTS(SELECT 1 FROM tblAcl 
                              WHERE iApplicationId = 160 AND iPermissionSetId = 703 AND iEntityId = ActivityId 
                                    AND iSecurityId IN (SELECT Id FROM @UserRoleId))
                )
            )
    )
    BEGIN
        SET @Result = 1;
    END
    
    RETURN @Result;
END
GO

IF OBJECT_ID('[Calendar].[be_GetActiveActivities]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[be_GetActiveActivities] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[be_GetActiveActivities]
    @UserId INT
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
        dbo.CanUserAccessToActivity(@UserId, ActivityId) = 1
        AND
        (
            StartDate <= @Today
            AND EndDate >= @Today
        )
END
GO

IF OBJECT_ID('[Calendar].[SearchActivities]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[SearchActivities] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[SearchActivities]
    @UserId INT,
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
        dbo.CanUserAccessToActivity(@UserId, ActivityId) = 1
        AND
        (
            (
                @PersonId IS NULL 
                OR dbo.CanUserAccessToActivity(@PersonId, ActivityId) = 1
            )
            AND 
            (
                @DepartmentId IS NULL 
                OR (EXISTS(SELECT 1 FROM tblAcl WHERE iApplicationId = 160 AND iEntityId = ActivityId AND iPermissionSetId = 702 AND iSecurityId = @DepartmentId))
            )
            AND 
            (
                @RoleId IS NULL 
                OR (EXISTS(SELECT 1 FROM tblAcl WHERE iApplicationId = 160 AND iEntityId = ActivityId AND iPermissionSetId = 703 AND iSecurityId = @RoleId))
            )
            AND (@StartDate IS NULL OR StartDate >= @StartDate)
            AND (@EndDate IS NULL OR EndDate <= @EndDate)
            AND (@Name IS NULL OR Name LIKE '%' + @Name + '%')
            AND (@Description IS NULL OR Description LIKE '%' + @Description + '%')
        )
END
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
        dbo.CanUserAccessToActivity(@UserId, a.ActivityId) = 1
        AND
        (
            (a.StartDate <= @Today AND a.EndDate >= @Today)
            OR (a.EndDate < @Today AND EXISTS (SELECT 1 FROM [Calendar].[ActivityTasks] at WHERE at.ActivityId = a.ActivityId AND at.IsCompleted = 0))
        )
    ORDER BY
        a.StartDate, a.Name
END
GO

IF OBJECT_ID('[Calendar].[GetUpcomingActivities]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[GetUpcomingActivities] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[GetUpcomingActivities]
    @UserId INT,
    @UpcomingEventsCount INT
AS
BEGIN
    DECLARE @Today DATETIME = CONVERT(DATE, GETDATE());
    
    SELECT TOP (@UpcomingEventsCount)
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
        dbo.CanUserAccessToActivity(@UserId, ActivityId) = 1
        AND StartDate >= @Today
    ORDER BY
        StartDate, Name
END
GO

IF OBJECT_ID('[Calendar].[GetUserActivitiesInYear]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [Calendar].[GetUserActivitiesInYear] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[GetUserActivitiesInYear]
    @UserId INT,
    @Year INT
AS
BEGIN
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
            Year(StartDate) = @Year
            OR Year(EndDate) = @Year
        )
    ORDER BY a.StartDate, a.Name
END
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
            (Year(StartDate) = @Year AND Month(StartDate) = @Month)
            OR (Year(EndDate) = @Year ANd Month(EndDate) = @Month)
        )
    ORDER BY a.StartDate, a.Name
END
GO