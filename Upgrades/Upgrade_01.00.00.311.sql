INSERT INTO #Description VALUES ('Modify procedure Calendar.SearchActivities')
GO

IF OBJECT_ID('[Calendar].[SearchActivities]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[SearchActivities] AS SELECT 1')
GO

ALTER PROCEDURE [Calendar].[SearchActivities]
    @UserId INT,
    @Keyword NVARCHAR(MAX),
    @PersonId INT,
    @DepartmentId INT,
    @RoleId INT,
    @ResponsibleId INT,
    @StartDate DATETIME,
    @EndDate DATETIME,
    @Name NVARCHAR(250),
    @Description NVARCHAR(MAX)
AS
BEGIN
    -- This procedure is used in Activities Management view and Search Activities View
    -- Activities Management View allows users to search activities by Name & Description
    -- Search Activities View allows users to search activities by Keyword
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
                @Keyword IS NULL
                OR Name LIKE '%' + @Keyword + '%'
                OR Description LIKE '%' + @Keyword + '%'
            )
            AND
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
            AND
            (
                @ResponsibleId IS NULL
                OR ResponsibleId = @ResponsibleId
            )
            AND (@StartDate IS NULL OR StartDate >= @StartDate)
            AND (@EndDate IS NULL OR EndDate <= @EndDate)
            AND (@Name IS NULL OR Name LIKE '%' + @Name + '%')
            AND (@Description IS NULL OR Description LIKE '%' + @Description + '%')
        )
    ORDER BY StartDate, Name
END
GO