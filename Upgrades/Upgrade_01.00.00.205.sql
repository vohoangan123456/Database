INSERT INTO #Description VALUES('Implement change title document')
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentInformation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentInformation] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetDocumentInformation]
	@DocumentId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	SELECT	d.iEntityId, 
			d.iDocumentId, 
			d.iVersion, 
			d.iDocumentTypeId, 
			d.iHandbookId, 
			d.strName, 
			d.strDescription, 
			d.UrlOrFileName,
			d.strApprovedBy,
			d.iApproved,
			d.iDraft, 
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) strCreatedBy, 
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
			d.dtmPublish,
			d.dtmPublishUntil,
			d.iReadCount,
			d.strAuthor,
			d.strAlterer,
			d.dtmApproved,
			d.iLatestVersion
	FROM	m136_tblDocument d
	WHERE	d.iDocumentId = @DocumentId	AND 
			d.iLatestApproved = 1
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateDocumentTitle]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateDocumentTitle] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_UpdateDocumentTitle] 
	-- Add the parameters for the stored procedure here
	@iEntityId int = 0,
	@strTitle nvarchar(200)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	UPDATE [dbo].[m136_tblDocument]
        SET strName = @strTitle
        WHERE iEntityId = @iEntityId
    
    DECLARE @DocumentId INT
    SELECT @DocumentId = idocumentId
    FROM dbo.m136_tblDocument
    WHERE iEntityId = @iEntityId
    IF(@DocumentId IS NOT NULL)
    BEGIN
		INSERT INTO dbo.CacheUpdate (ActionType, EntityId)
		VALUES (11, @DocumentId);
	END
END
