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
                )
            )
    )
    BEGIN
        SET @Result = 1;
    END
    RETURN @Result;
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
        dbo.CanUserAccessToActivityForNotification(@UserId, a.ActivityId) = 1
        AND
        (
            (a.StartDate <= @Today AND a.EndDate >= @Today)
            OR (a.EndDate < @Today AND EXISTS (SELECT 1 FROM [Calendar].[ActivityTasks] at WHERE at.ActivityId = a.ActivityId AND at.IsCompleted = 0))
        )
    ORDER BY
        a.StartDate, a.Name
END
GO