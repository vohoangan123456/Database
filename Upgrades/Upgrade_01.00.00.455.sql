INSERT INTO #Description VALUES ('Create a page for showing log message')
GO

IF OBJECT_ID('[dbo].[GetLog]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetLog] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[GetLog]
AS
BEGIN
    SELECT
        Id,
        [Date],
        Thread,
        [Level],
        Logger,
        [Message],
        CustomerReferenceId
    FROM [dbo].[Log]
END

GO

IF OBJECT_ID('[dbo].[GetLogDetailsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetLogDetailsById] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[GetLogDetailsById]
	@Id INT
AS
BEGIN
	SELECT
		Id,
        [Date],
        Thread,
        [Level],
        Logger,
        [Message],
        CustomerReferenceId
	FROM 
		dbo.[Log]
	WHERE Id = @Id
END