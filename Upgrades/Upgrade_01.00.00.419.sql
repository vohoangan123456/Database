INSERT INTO #Description VALUES ('Modify SP [dbo].[m136_GetFileDocument]')
GO

IF OBJECT_ID('[dbo].[m136_GetFileDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetFileDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetFileDocument]
	@SecurityId INT = NULL,
	@EntityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	SELECT	
			d.UrlOrFileName,
			d.UrlOrFileProperties,
			d.[File]
	FROM	
			m136_tblDocument d
	WHERE	
				d.iEntityId = @EntityId
			AND [dbo].[fnHandbookHasReadContentsAccess](@SecurityId, d.iHandbookId) = 1
END
GO