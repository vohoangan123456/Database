INSERT INTO #Description VALUES('Modified fn136_GetParentPathEx. Add one more check for folder which is belong to root folder.')
GO

IF OBJECT_ID('[dbo].[fn136_GetParentPathEx]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[fn136_GetParentPathEx]() RETURNS NVARCHAR(4000) AS BEGIN RETURN 0; END')
GO
ALTER FUNCTION [dbo].[fn136_GetParentPathEx](@chapterId INT)
RETURNS NVARCHAR(4000)
AS
BEGIN
	DECLARE @Path varchar(4000);
	WITH Parents AS
	(
		SELECT 
			iParentHandbookId,
			strName
		FROM 
			[dbo].[m136_tblHandbook] 
		WHERE
			iHandbookId = @chapterId
		UNION ALL
		SELECT 
			h.iParentHandbookId,
			h.strName
		FROM 
			[dbo].[m136_tblHandbook] h
			INNER JOIN Parents
				ON	(h.iHandbookId = Parents.iParentHandbookId AND (h.iHandbookId <> h.iParentHandbookId OR h.iParentHandbookId IS NULL)) 
	)
	SELECT
		@Path = strName + COALESCE('/' + @Path, '')
	FROM
		Parents --option(maxrecursion 0)
	RETURN @Path
END