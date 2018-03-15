INSERT INTO #Description VALUES ('Fixed querying folder recursively.')
GO

IF OBJECT_ID('[dbo].[fn136_GetParentPathExNew]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[fn136_GetParentPathExNew]() RETURNS NVARCHAR(4000) AS BEGIN RETURN 0; END')
GO

ALTER FUNCTION [dbo].[fn136_GetParentPathExNew](@chapterId INT)
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
		Parents

	RETURN @Path
END
GO