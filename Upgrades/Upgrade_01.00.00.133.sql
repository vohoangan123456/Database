INSERT INTO #Description VALUES('Create some stored procedure to support feature delete single & multiple documents')
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentInformationByEntityIds]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentInformationByEntityIds] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetDocumentInformationByEntityIds] 
	@EntityIds AS [dbo].[Item] READONLY
AS
BEGIN
	SELECT
		d.iEntityId, 
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
		d.iReadCount
	FROM
		m136_tblDocument d
			JOIN dbo.m136_tblHandbook h ON h.iHandbookId = d.iHandbookId
	WHERE
		d.iEntityId IN (SELECT Id FROM @EntityIds)
END
GO

IF OBJECT_ID('[dbo].[m136_be_DeleteSingleDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteSingleDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_DeleteSingleDocument]
	@UserId INT,
	@DocumentId INT
AS
BEGIN
	DECLARE @FullName NVARCHAR(100);
	
	SELECT
		@FullName = strFirstName + ' ' + strLastName
	FROM
		tblEmployee
	WHERE
		iEmployeeId = @UserId

	UPDATE
		m136_tblDocument
	SET
		iDeleted = 1,
		iAlterId = @UserId,
		strAlterer = @FullName
	WHERE
		iDocumentId = @DocumentId
END
GO

IF OBJECT_ID('[dbo].[m136_be_DeleteMultipleDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteMultipleDocuments] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_DeleteMultipleDocuments]
	@UserId AS INT,
	@DocumentIds AS [dbo].[Item] READONLY
AS
BEGIN
	DECLARE @FullName NVARCHAR(100);
	
	SELECT
		@FullName = strFirstName + ' ' + strLastName
	FROM
		tblEmployee
	WHERE
		iEmployeeId = @UserId

	UPDATE
		m136_tblDocument
	SET
		iDeleted = 1,
		iAlterId = @UserId,
		strAlterer = @FullName
	WHERE
		iDocumentId IN (SELECT Id FROM @DocumentIds)
END
GO