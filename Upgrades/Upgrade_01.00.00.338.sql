INSERT INTO #Description VALUES ('Create SP [dbo].[m136_ChapterContainsDocuments]')
GO

IF OBJECT_ID('[dbo].[m136_ChapterContainsDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_ChapterContainsDocuments] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_ChapterContainsDocuments]
	@ChapterId INT
AS
BEGIN
	IF EXISTS(SELECT 1  
			  FROM dbo.m136_tblDocument
			  WHERE iHandbookId = @ChapterId
					AND iDeleted = 0
			 )
		BEGIN
			SELECT 1
		END
	ELSE
		BEGIN
			SELECT 0
		END	
END

GO