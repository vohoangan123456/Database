INSERT INTO #Description VALUES('Update m136_GetChapterReadAccess to not contain HandbookTest')
GO

IF OBJECT_ID('[dbo].[m136_GetChapterReadAccess]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetChapterReadAccess] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetChapterReadAccess] 
	-- Add the parameters for the stored procedure here
	@SecurityId int
AS
BEGIN
	SELECT	[iEntityId] AS ChapterId,
			Sum(CASE iPermissionSetId
				 WHEN 461 THEN 1
				 WHEN 462 THEN 2
				 END) as AccessRights
	FROM [dbo].[tblACL]
	WHERE	iSecurityId = @SecurityId 
		AND iApplicationId = 136
		AND (iBit & 1) = 1 
		AND (iPermissionSetId = 461 OR iPermissionSetId = 462)
	GROUP BY iEntityId
END