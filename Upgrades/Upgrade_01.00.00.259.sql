INSERT INTO #Description VALUES('Implement verifying document links')
GO

IF OBJECT_ID('[dbo].[m136_be_ChangeDocumentLink]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_ChangeDocumentLink] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_ChangeDocumentLink] 
	@iEntityId INT,
	@FieldId INT,
	@FieldContentId INT,
	@OldUrl [nvarchar](max),
	@NewUrl [nvarchar](max)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @iDocumentTypeId INT;
	SELECT @iDocumentTypeId = mtd.iDocumentTypeId 
	FROM dbo.m136_tblDocument mtd WHERE mtd.iEntityId = @iEntityId;

    UPDATE mir SET mir.[value] = CAST(REPLACE(CAST(value as nvarchar(max)), @OldUrl, @NewUrl) as ntext)
    FROM dbo.m136_tblMetaInfoRichText mir
    JOIN dbo.m136_relDocumentTypeInfo rdti ON rdti.iMetaInfoTemplateRecordsId = mir.iMetaInfoTemplateRecordsId
    WHERE mir.iMetaInfoRichTextId = @FieldContentId
    AND mir.iMetaInfoTemplateRecordsId = @FieldId
    AND rdti.iDocumentTypeId = @iDocumentTypeId;    
END
GO