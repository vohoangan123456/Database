INSERT INTO #Description VALUES ('Modify procedure GetUserActivitiesInMonthOfYear')
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

 DECLARE @MonthStart DATETIME 
 DECLARE @MonthEnd DATETIME
 
 SET @MonthStart = CAST(CONVERT(VARCHAR, @Year) + '-' + CONVERT(VARCHAR, @Month) + '-' + CONVERT(VARCHAR, 1) AS DATETIME)
 SET @MonthEnd = DateAdd(MONTH, 1, @MonthStart)

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
            (@MonthStart > StartDate AND @MonthStart < EndDate)
            OR (@MonthEnd > StartDate AND @MonthEnd < EndDate)
        )
    ORDER BY a.StartDate, a.Name
END