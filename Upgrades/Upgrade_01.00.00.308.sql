INSERT INTO #Description VALUES ('Modify procedure GetUpcomingActivities')
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
        AND StartDate > @Today
    ORDER BY
        StartDate, Name
END
GO