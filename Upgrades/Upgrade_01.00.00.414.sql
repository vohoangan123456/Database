INSERT INTO #Description VALUES ('Change permisions for notification activities')
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[CanUserAccessToActivityForNotification]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
  DROP FUNCTION [dbo].[CanUserAccessToActivityForNotification]

GO 

Create FUNCTION [dbo].[CanUserAccessToActivityForNotification]
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
    IF EXISTS
    (
        SELECT 1
        FROM Calendar.Activities a
        WHERE
            a.ActivityId = @ActivityId
            AND 
            (
				--TODO : what is this using for?
                --a.IsPermissionControlled = 0
                --OR
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
                )
            )
    )
    BEGIN
        SET @Result = 1;
    END
    RETURN @Result;
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
        dbo.CanUserAccessToActivityForNotification(@UserId, a.ActivityId) = 1
        AND
        (
            Year(StartDate) = @Year
            OR Year(EndDate) = @Year
        )
    ORDER BY a.StartDate, a.Name
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
        dbo.CanUserAccessToActivityForNotification(@UserId, a.ActivityId) = 1
        AND
        (
            EndDate >= @FirstDateOfMonth
            OR (StartDate >= @FirstDateOfMonth AND StartDate < @FirstDateOfNextMonth)
        )
    ORDER BY a.StartDate, a.Name
END
GO