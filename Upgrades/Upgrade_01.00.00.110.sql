INSERT INTO #Description VALUES('Create stored procedures for related attachments management.')
GO

IF OBJECT_ID('[dbo].[m136_be_InsertRelatedAttachment]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_InsertRelatedAttachment] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: SEP 23, 2015
-- Description:	Insert related attachments 
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_InsertRelatedAttachment] 
	@RelationTypeId		INT,
	@iItemId			INT,
	@strName			VARCHAR(300),
	@strDescription		VARCHAR(800),
	@iSize				INT,
	@strFileName		VARCHAR(200),
	@strContentType		VARCHAR(100),
	@strExtension		VARCHAR(100),
	@imgContent			[varbinary]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @MaxId INT;

	SELECT @MaxId = MAX(mtb.iItemId) FROM dbo.m136_tblBlob mtb; 

	SET @iItemId = (@MaxId + 1);

	SET IDENTITY_INSERT dbo.m136_tblBlob ON;

    INSERT INTO [dbo].m136_tblBlob
        (iItemId,
        iInformationTypeId,
        strName,
        strDescription,
        iSize,
        strFileName,
        strContentType,
        strExtension,
        imgContent,
        bInUse,
        dtmRegistered,
        iWidth,
        iHeight)
    VALUES
        (@iItemId,
        @RelationTypeId,
        @strName,
        @strDescription,
        @iSize,
        @strFileName,
        @strContentType,
        @strExtension,
        @imgContent,
        1,
        GETDATE(),
        0,
        0);

	SET IDENTITY_INSERT dbo.m136_tblBlob OFF;
	
	SELECT @iItemId;
END
GO

IF OBJECT_ID('[dbo].[m136_be_LinkDocumentAttachment]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_LinkDocumentAttachment] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: OCT 18, 2015
-- Description:	Link an attachment to a document. 
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_LinkDocumentAttachment]
	@iEntityId				INT,
	@iItemId				INT,
	@iRelationTypeId		INT,
	@iPlacementId			INT,
	@iProcessRelationTypeId	INT
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
END
GO

IF OBJECT_ID('[dbo].[m136_be_DeleteAttachment]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteAttachment] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: OCT 18, 2015
-- Description:	Delete attachment.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_DeleteAttachment] 
	@iItemId	INT
AS
BEGIN
	SET NOCOUNT ON;

    DELETE dbo.m136_tblBlob
			WHERE iItemId = @iItemId;
END
GO

IF OBJECT_ID('[dbo].[m136_be_DeleteRelatedInfo]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteRelatedInfo] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: OCT 06, 2015
-- Description:	Delete related information that includes attachment, document, images.
--              For types not document we have to delete tblBlob as well.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_DeleteRelatedInfo]
	@iEntityId			INT,
	@iItemIds			dbo.Item READONLY,
	@iRelationTypeId	INT
AS
BEGIN
	SET NOCOUNT ON;

    DELETE dbo.m136_relInfo
        WHERE iEntityId = @iEntityId
        AND iRelationTypeId = @iRelationTypeId
        AND iItemId IN (SELECT Id FROM @iItemIds);

    IF (@iRelationTypeId <> 136)
    BEGIN
		IF NOT EXISTS(SELECT COUNT(1) FROM dbo.m136_tblBlob 
			WHERE iItemId IN (SELECT iItemId FROM dbo.m136_relInfo WHERE iRelationTypeId <> 136))
		BEGIN
			DELETE dbo.m136_tblBlob
				WHERE iItemId IN (SELECT Id FROM @iItemIds);
		END
    END
END
GO