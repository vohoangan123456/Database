INSERT INTO #Description VALUES ('Create SP [dbo].[GetUserByLoginName]')
GO

IF OBJECT_ID('[dbo].[GetUserByLoginName]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetUserByLoginName] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetUserByLoginName]
	@LoginName varchar(100)
AS
BEGIN
	SELECT e.*
	FROM
		[dbo].[tblEmployee] e
	WHERE 
		e.strLoginName = @LoginName;
END
