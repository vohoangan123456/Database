INSERT INTO #Description VALUES ('Send to approval - File/URL document')
GO

IF OBJECT_ID('[dbo].[m136_be_IsMandatoryContentOfDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_IsMandatoryContentOfDocument] AS SELECT 1')
GO
/*
@Resul: 0 missing mandatory field
		1 missing File
		2 missing URL
		10 SUCCESS
*/
ALTER PROCEDURE [dbo].[m136_be_IsMandatoryContentOfDocument] 
	@DocumentId INT 
AS
BEGIN
	DECLARE @EntityId INT
	DECLARE @Type INT
	DECLARE @Result INT = 10
	DECLARE @UrlOrFileName NVARCHAR(4000)
	
	SELECT @EntityId =  d.iEntityId, @Type = t.Type, @UrlOrFileName = UrlOrFileName
	FROM dbo.m136_tblDocument d
		LEFT JOIN dbo.m136_tblDocumentType t ON d.iDocumentTypeId = t.iDocumentTypeId
	WHERE d.iDocumentId = @DocumentId
		  AND d.iLatestVersion = 1
	IF @Type = 0
	BEGIN
		IF dbo.fnDocumentCanBeApproved(@EntityId) = 0
			SET @Result = 0
	END
	ELSE IF @Type IN (1,2)
	BEGIN
		IF @UrlOrFileName IS NULL OR @UrlOrFileName = ''
			SET @Result = @Type
	END
	SELECT @Result;  
END