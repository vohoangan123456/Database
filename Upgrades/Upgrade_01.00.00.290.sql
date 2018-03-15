INSERT INTO #Description VALUES ('Modify procedure be_GetActiveActivities, create procedures GetActiveActivities, GetUpcomingActivities')
GO

IF OBJECT_ID('[Calendar].[be_GetActiveActivities]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[be_GetActiveActivities] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[be_GetActiveActivities] 
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

IF OBJECT_ID('[Calendar].[GetActiveActivities]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[GetActiveActivities] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[GetActiveActivities]
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
        (a.StartDate <= @Today AND a.EndDate >= @Today)
        OR (a.EndDate < @Today AND EXISTS (SELECT 1 FROM [Calendar].[ActivityTasks] at WHERE at.ActivityId = a.ActivityId AND at.IsCompleted = 0))
    ORDER BY
        a.StartDate, a.Name
END
GO

IF OBJECT_ID('[Calendar].[GetUpcomingActivities]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[GetUpcomingActivities] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[GetUpcomingActivities] 
    @UpcomingEventsCount INT
AS
BEGIN
    DECLARE @Today DATETIME = CONVERT(DATE, GETDATE());
    DECLARE @UpcomingDay DATETIME = DATEADD(DAY, @UpcomingEventsCount, @Today);
    
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
        StartDate >= @Today
        AND StartDate <= @UpcomingDay
    ORDER BY
        StartDate, Name
    
END
GO