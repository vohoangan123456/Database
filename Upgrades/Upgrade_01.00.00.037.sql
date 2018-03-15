INSERT INTO #Description VALUES('add stored procedure [dbo].[m136_AuthenticateDomainUser]')
GO

IF OBJECT_ID('[dbo].[m136_AuthenticateDomainUser]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_AuthenticateDomainUser] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_AuthenticateDomainUser]
	@LoginName varchar(100),
	@Domain varchar(100)
AS
BEGIN
	SELECT
		[iEmployeeId], 
		[strFirstName], 
		[strLastName]
	FROM
		[dbo].[tblEmployee]
	WHERE
			strLoginName = @LoginName
		AND ',' + strLoginDomain + ',' LIKE '%,' + @Domain + ',%' -- A trick to support the multiple domains in the field (domain1,domain2)
END

GO