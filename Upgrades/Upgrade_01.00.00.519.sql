INSERT INTO #Description VALUES ('Modify procedure [dbo].[m136_be_LinkDocumentAttachment]')
GO

IF OBJECT_ID('[dbo].[m136_be_LinkDocumentAttachment]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_LinkDocumentAttachment] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_LinkDocumentAttachment]
	@iEntityId				INT,
	@iItemId				INT,
	@iRelationTypeId		INT,
	@iPlacementId			INT,
	@iProcessRelationTypeId	INT,
	@strName				VARCHAR(300),
	@strDescription			VARCHAR(800)
AS
BEGIN
	SET NOCOUNT ON;

    DECLARE @Sort INT;

    SELECT @Sort = ISNULL(MAX(iSort) + 1, 1)
    FROM dbo.m136_relInfo
    WHERE iEntityId = @iEntityId
        AND iRelationTypeId = @iRelationTypeId;

	INSERT INTO [dbo].m136_relInfo
        (iEntityId,
        iItemId,	                
        iProcessRelationTypeId,
        iRelationTypeId,
        iSort,
        iPlacementId)
    VALUES
        (@iEntityId,
        @iItemId,	                
        @iProcessRelationTypeId,
        @iRelationTypeId,
        @Sort,
        @iPlacementId);
        
    UPDATE [dbo].m136_tblBlob
    SET strName = @strName,
        strDescription = @strDescription
	WHERE iItemId = @iItemId
END
GO

