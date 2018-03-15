INSERT INTO #Description VALUES ('Modify Sp [dbo].[m136_GetWritersAndApproversForChapter]')
GO

IF OBJECT_ID('[dbo].[m136_GetWritersAndApproversForChapter]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetWritersAndApproversForChapter] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetWritersAndApproversForChapter]
	@iHandbookId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	SELECT DISTINCT e.iEmployeeId, e.strFirstName, e.strLastName, e.strEmail, e.strFirstName + ' ' + e.strLastName strName 
	FROM tblEmployee e 
	INNER JOIN relEmployeeSecGroup r ON e.iEmployeeId = r.iEmployeeId 
	INNER JOIN tblACL a ON r.iSecGroupId = a.iSecurityId 
						   AND a.iEntityId = @iHandbookId AND a.iApplicationId = 136 AND a.iPermissionSetid = 462
						   AND (a.iBit & 0x02) = 0x02
	ORDER BY strName
	
	SELECT DISTINCT e.iEmployeeId, e.strFirstName, e.strLastName, e.strEmail, e.strFirstName + ' ' + e.strLastName strName
	FROM tblEmployee e 
	INNER JOIN relEmployeeSecGroup r ON e.iEmployeeId = r.iEmployeeId 
	INNER JOIN tblACL a ON r.iSecGroupId = a.iSecurityId 
						   AND a.iEntityId = @iHandbookId AND a.iApplicationId = 136 AND a.iPermissionSetid = 462
						   AND (a.iBit & 0x10) = 0x10
	ORDER BY strName
END
GO
