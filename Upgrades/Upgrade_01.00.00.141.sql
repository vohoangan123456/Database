INSERT INTO #Description VALUES('Modified stored procedures for getting iDeleted')
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentInformationByEntityId]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentInformationByEntityId]  AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetDocumentInformationByEntityId] 
	@EntityId INT = NULL
AS
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
			h.iLevelType,
			d.dtmPublish,
			d.dtmPublishUntil,
			d.iReadCount,
			d.iDeleted
	FROM	m136_tblDocument d
	JOIN    dbo.m136_tblHandbook h ON h.iHandbookId = d.iHandbookId
	WHERE	d.iEntityId = @EntityId
END
GO 

IF OBJECT_ID('[dbo].[m136_be_GetDocumentInformation]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentInformation]  AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetDocumentInformation]
	@DocumentId INT = NULL
AS
BEGIN
	DECLARE @iVersions INT;
	SELECT @iVersions = COUNT(1) FROM dbo.m136_tblDocument mtd WHERE mtd.iDocumentId = @DocumentId;
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
            dbo.fnDocumentCanBeApproved(@DocumentId) AS bCanBeApproved,
			d.iDraft,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) strCreatedBy, 
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
			h.iLevelType,
			d.dtmPublish,
			d.dtmPublishUntil,
			d.iReadCount,
			h.iLevel,
			te.strEmail AS strCreatedByEmail,
			d.strAuthor,
			@iVersions AS iVersionsCount,
			d.UrlOrFileName,
			d.UrlOrFileProperties,
			d.[File],
			d.iCompareToVersion	,
			d.iInternetDoc,
			d.iDeleted		
	FROM	m136_tblDocument d
	JOIN    dbo.m136_tblHandbook h ON h.iHandbookId = d.iHandbookId
	LEFT JOIN dbo.tblEmployee te ON d.iCreatedbyId = te.iEmployeeId 
	WHERE	d.iDocumentId = @DocumentId	AND 
			d.iLatestVersion = 1
END
GO

IF OBJECT_ID('[dbo].[m136_be_InsertImage]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_InsertImage]  AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: NOV 24, 2015
-- Description:	Insert Image for editor
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_InsertImage] 
	@RelationTypeId		INT,
	@strName			VARCHAR(300),
	@strDescription		VARCHAR(800),
	@iSize				INT,
	@strFileName		VARCHAR(200),
	@strContentType		VARCHAR(100),
	@strExtension		VARCHAR(100),
	@imgContent			[image],
	@iHeight			INT,
	@iWidth				INT
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @MaxId INT, @iItemId INT;
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
        @iWidth,
        @iHeight);
        
	SET IDENTITY_INSERT dbo.m136_tblBlob OFF;
	SELECT @iItemId;
END
GO