INSERT INTO #Description VALUES('Create some stored procedures to support feature Approve document')
GO

IF OBJECT_ID('[dbo].[fnDocumentCanBeApproved]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[fnDocumentCanBeApproved]() RETURNS BIT AS BEGIN RETURN 0; END')
GO

ALTER FUNCTION [dbo].[fnDocumentCanBeApproved]
(
	@EntityId INT = NULL
) RETURNS BIT
AS
BEGIN
	DECLARE @Result BIT;
    DECLARE @RequiredTemplateRecords TABLE(iMetaInfoTemplateRecordsId INT);
    
    DECLARE @NumberOfRequiredRecordsInDocumentTemplate INT;
    DECLARE @NumberOfValidNumberRecordsInDocument INT;
    DECLARE @NumberOfValidTextRecordsInDocument INT;
    DECLARE @NumberOfValidRichTextRecordsInDocument INT;
    DECLARE @NumberOfValidDateRecordsInDocument INT;

    IF @EntityId = NULL
    BEGIN
        SET @Result = 0;
    END
    ELSE
    BEGIN
		INSERT INTO
			@RequiredTemplateRecords
		SELECT
			dti.iMetaInfoTemplateRecordsId
		FROM
			m136_tblDocument d
				INNER JOIN m136_tblDocumentType dt
					ON d.iDocumentTypeId = dt.iDocumentTypeId
				INNER JOIN m136_relDocumentTypeInfo dti
					ON dt.iDocumentTypeId = dti.iDocumentTypeId
		WHERE
			d.iEntityId = @EntityId
            AND dti.iDeleted = 0
            AND dti.iMandatory = 1
    
        -- Select number of required fields in document template
        SELECT
			@NumberOfRequiredRecordsInDocumentTemplate = COUNT(*)
		FROM
			@RequiredTemplateRecords
            
        -- Select number of valid number fields in document
        SELECT
			@NumberOfValidNumberRecordsInDocument = COUNT(*)
		FROM
			m136_tblDocument d
				INNER JOIN m136_tblMetaInfoNumber mi
					ON d.iEntityId = mi.iEntityId
		WHERE
			d.iEntityId = 1
			AND mi.iMetaInfoTemplateRecordsId IN (SELECT iMetaInfoTemplateRecordsId FROM @RequiredTemplateRecords)
                    
        -- Select number of valid text fields in document
        SELECT
			@NumberOfValidTextRecordsInDocument = COUNT(*)
		FROM
			m136_tblDocument d
				INNER JOIN m136_tblMetaInfoText mi
					ON d.iEntityId = mi.iEntityId
		WHERE
			d.iEntityId = 1
			AND mi.iMetaInfoTemplateRecordsId IN (SELECT iMetaInfoTemplateRecordsId FROM @RequiredTemplateRecords)        
			
        -- Select number of valid rich text fields in document
        SELECT
			@NumberOfValidRichTextRecordsInDocument = COUNT(*)
		FROM
			m136_tblDocument d
				INNER JOIN m136_tblMetaInfoRichText mi
					ON d.iEntityId = mi.iEntityId
		WHERE
			d.iEntityId = 1
			AND mi.iMetaInfoTemplateRecordsId IN (SELECT iMetaInfoTemplateRecordsId FROM @RequiredTemplateRecords)
        
        -- Select number of valid date fields in document
        SELECT
			@NumberOfValidDateRecordsInDocument = COUNT(*)
		FROM
			m136_tblDocument d
				INNER JOIN m136_tblMetaInfoDate mi
					ON d.iEntityId = mi.iEntityId
		WHERE
			d.iEntityId = 1
			AND mi.iMetaInfoTemplateRecordsId IN (SELECT iMetaInfoTemplateRecordsId FROM @RequiredTemplateRecords)
            
        IF @NumberOfRequiredRecordsInDocumentTemplate = @NumberOfValidNumberRecordsInDocument + @NumberOfValidTextRecordsInDocument + @NumberOfValidRichTextRecordsInDocument + @NumberOfValidDateRecordsInDocument
        BEGIN
            SET @Result = 1;
        END
        ELSE
        BEGIN
            SET @Result = 0;
        END
    END
    
    RETURN @Result;
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentInformation]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentInformation] AS SELECT 1')
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
			d.iInternetDoc		
	FROM	m136_tblDocument d
	JOIN    dbo.m136_tblHandbook h ON h.iHandbookId = d.iHandbookId
	LEFT JOIN dbo.tblEmployee te ON d.iCreatedbyId = te.iEmployeeId 
	WHERE	d.iDocumentId = @DocumentId	AND 
			d.iLatestVersion = 1
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetUserWithApprovePermissionOnDocument]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetUserWithApprovePermissionOnDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetUserWithApprovePermissionOnDocument]
	@DocumentId INT
AS
BEGIN
	DECLARE @HandBookId INT;
	SELECT
		@HandBookId = iHandBookId
	FROM
		dbo.m136_tblDocument
	WHERE
		iDocumentId = @DocumentId

	SELECT
		e.iEmployeeId,
		strFirstName,
		strLastName,
		strEmail
	FROM
		dbo.tblEmployee AS e
	WHERE
		dbo.fnSecurityGetPermission(136, 462, e.iEmployeeId, @HandBookId) & 16 = 16
END
GO

IF OBJECT_ID('[dbo].[m136_be_ApproveDocument]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_ApproveDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_ApproveDocument]
	@UserId INT,
	@DocumentId INT,
	@TransferReadingReceipts BIT
AS
BEGIN
	UPDATE
		m136_tblDocument
	SET
		iDraft = 0
	WHERE
		iDocumentId = @DocumentId
	
	INSERT INTO
		m136_relSentEmpApproval
			(iEmployeeId, iEntityId, dtmSentToApproval)
		VALUES
			(@UserId, @DocumentId, GETDATE())

	DELETE FROM
		m136_tblCopyConfirms
	WHERE
		iEntityId = @DocumentId
	
	IF @TransferReadingReceipts = 1
	BEGIN
		INSERT INTO
			m136_tblCopyConfirms
				(iEntityId)
			VALUES
				(@DocumentId)
	END
END
GO