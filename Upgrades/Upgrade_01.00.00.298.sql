INSERT INTO #Description VALUES ('Create procedures GetActivitiesInYear, GetActivitiesInMonthOfYear')
GO

IF OBJECT_ID('[Calendar].[GetActivitiesInYear]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [Calendar].[GetActivitiesInYear]  AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[GetActivitiesInYear]
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
        Year(StartDate) = @Year
        OR Year(EndDate) = @Year
    ORDER BY a.StartDate, a.Name
END
GO

IF OBJECT_ID('[Calendar].[GetActivitiesInMonthOfYear]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [Calendar].[GetActivitiesInMonthOfYear]  AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[GetActivitiesInMonthOfYear]
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
        (Year(StartDate) = @Year AND Month(StartDate) = @Month)
        OR (Year(EndDate) = @Year ANd Month(EndDate) = @Month)
    ORDER BY a.StartDate, a.Name
END
GO