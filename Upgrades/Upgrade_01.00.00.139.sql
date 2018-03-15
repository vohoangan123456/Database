INSERT INTO #Description VALUES('Add procedure m136_be_ChangeDocumentType')
GO

IF OBJECT_ID('[dbo].[m136_be_ChangeDocumentType]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_ChangeDocumentType] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_ChangeDocumentType]
	@UserId AS INT,
	@DocumentId AS INT,
	@DocumentTypeId AS INT
AS
BEGIN
	DECLARE @EntityIdOfLatestDocument INT;
	DECLARE @NewVersionNumber INT;
	
	SET @EntityIdOfLatestDocument = (SELECT MAX(iEntityId) FROM m136_tblDocument WHERE iDocumentId = @DocumentId);
	SET @NewVersionNumber = (SELECT iVersion FROM m136_tblDocument WHERE iEntityId = @EntityIdOfLatestDocument) + 1;

	UPDATE
		m136_tblDocument
	SET
		iLatestVersion = 0,
		iLatestApproved = 0
	WHERE
		iDocumentId = @DocumentId;
	
	INSERT INTO m136_tblDocument(
		iDocumentId,
		iVersion,
		iDocumentTypeId,
		iHandbookId,
		strName,
		strDescription,
		iCreatedById,
		dtmCreated,
		strAuthor,
		iAlterId,
		dtmAlter,
		iApprovedById,
		strApprovedBy,
		dtmPublish,
		dtmPublishUntil,
		iStatus,
		iSort,
		iDeleted,
		iApproved,
		iDraft,
		iLevelType,
		strHash,
		iReadCount,
		[File],
		UrlOrFileName,
		UrlOrFileProperties,
		iLatestVersion,
		iLatestApproved,
		iInternetDoc,
		strNameReversed,
		strDescriptionReversed)
	SELECT
		iDocumentId,
		@NewVersionNumber,
		@DocumentTypeId,
		iHandbookId,
		strName,
		strDescription,
		@UserId,
		GETDATE(),
		[dbo].[fnOrgGetUserName] (@UserId, 'System', 0),
		@UserId,
		GETDATE(),
		iApprovedById,
		strApprovedBy,
		GETDATE(),
		dtmPublishUntil,
		iStatus,
		iSort,
		iDeleted,
		iApproved,
		iDraft,
		iLevelType,
		strHash,
		iReadCount,
		null,
		null,
		null,
		1,
		1,
		iInternetDoc,
		strNameReversed,
		strDescriptionReversed
	FROM
		m136_tblDocument
	WHERE
		iEntityId = @EntityIdOfLatestDocument
END
GO