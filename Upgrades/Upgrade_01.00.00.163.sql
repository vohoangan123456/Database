INSERT INTO #Description VALUES('Drop procedure m136_be_GetAuthorEmailOfDocument, modify procedures m136_be_GetDocumentInformation, fnDocumentCanBeApproved, m136_be_UserCanApproveDocument, m136_be_ApproveDocument')
GO

IF OBJECT_ID('[dbo].[m136_be_GetAuthorEmailOfDocument]', 'p') IS NOT NULL
	EXEC ('DROP PROCEDURE [dbo].[m136_be_GetAuthorEmailOfDocument]')
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
            dbo.fnDocumentCanBeApproved(d.iEntityId) AS bCanBeApproved,
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
			d.iEntityId = @EntityId
			AND mi.iMetaInfoTemplateRecordsId IN (SELECT iMetaInfoTemplateRecordsId FROM @RequiredTemplateRecords)
			AND mi.[value] IS NOT NULL
        -- Select number of valid text fields in document
        SELECT
			@NumberOfValidTextRecordsInDocument = COUNT(*)
		FROM
			m136_tblDocument d
				INNER JOIN m136_tblMetaInfoText mi
					ON d.iEntityId = mi.iEntityId
		WHERE
			d.iEntityId = @EntityId
			AND mi.iMetaInfoTemplateRecordsId IN (SELECT iMetaInfoTemplateRecordsId FROM @RequiredTemplateRecords)   
			AND mi.[value] <> ''     
        -- Select number of valid rich text fields in document
        SELECT
			@NumberOfValidRichTextRecordsInDocument = COUNT(*)
		FROM
			m136_tblDocument d
				INNER JOIN m136_tblMetaInfoRichText mi
					ON d.iEntityId = mi.iEntityId
		WHERE
			d.iEntityId = @EntityId
			AND mi.iMetaInfoTemplateRecordsId IN (SELECT iMetaInfoTemplateRecordsId FROM @RequiredTemplateRecords)
			AND cast(mi.[value] as nvarchar(max)) <> ''
        -- Select number of valid date fields in document
        SELECT
			@NumberOfValidDateRecordsInDocument = COUNT(*)
		FROM
			m136_tblDocument d
				INNER JOIN m136_tblMetaInfoDate mi
					ON d.iEntityId = mi.iEntityId
		WHERE
			d.iEntityId = @EntityId
			AND mi.iMetaInfoTemplateRecordsId IN (SELECT iMetaInfoTemplateRecordsId FROM @RequiredTemplateRecords)
			AND mi.[value] IS NOT NULL
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

IF OBJECT_ID('[dbo].[m136_be_UserCanApproveDocument]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_UserCanApproveDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_UserCanApproveDocument]
	@UserId INT,
	@DocumentId INT,
    @IsInternetDocumentMode INT,
    @IsInternetDocument BIT
AS
BEGIN
	DECLARE @Result BIT = 0;
	DECLARE @HandBookId INT;
	
    IF @IsInternetDocument IS NULL
    BEGIN
        SELECT
            @HandBookId = iHandBookId,
            @IsInternetDocument = iInternetDoc
        FROM
            dbo.m136_tblDocument
        WHERE
            iDocumentId = @DocumentId
            AND iLatestVersion = 1
    END
    ELSE
    BEGIN
        SELECT
		@HandBookId = iHandBookId
	FROM
		dbo.m136_tblDocument
	WHERE
		iDocumentId = @DocumentId
        AND iLatestVersion = 1
    END

	SELECT
		@Result = 1
	FROM
		dbo.tblEmployee AS e
	WHERE
		e.iEmployeeId = @UserId
		AND 
			(((@IsInternetDocumentMode = 0 OR @IsInternetDocument = 0) AND dbo.fnSecurityGetPermission(136, 462, e.iEmployeeId, @HandBookId) & 16 = 16)
			OR (@IsInternetDocumentMode = 1 AND @IsInternetDocument = 1 AND dbo.fnSecurityGetPermission(136, 460, e.iEmployeeId, 0) & 16 = 16))
    
	SELECT @Result
END
GO

IF OBJECT_ID('[dbo].[m136_be_ApproveDocument]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_ApproveDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_ApproveDocument]
    @UserId INT,
    @EntityId INT,
    @TransferReadingReceipts BIT,
    @PublishFrom DATETIME,
    @PublishUntil DATETIME,
    @IsInternetDocument BIT
AS
BEGIN
    DECLARE @DocumentId INT;
    DECLARE @FullName NVARCHAR(100);
    
    SELECT
        @DocumentId = iDocumentId
    FROM
        m136_tblDocument
    WHERE
        iEntityId = @EntityId
    
    SELECT
        @FullName = strFirstName + ' ' + strLastName
    FROM
        tblEmployee
    WHERE
        iEmployeeId = @UserId
    
    IF @TransferReadingReceipts = 1
    BEGIN
		EXEC m136_doCopyConfirms @DocumentId
    END
    ELSE
    BEGIN
		EXEC m136_SetCopyConfirms @DocumentId, 0
    END

	UPDATE
        m136_tblDocument
    SET
        iApproved = 1,
        iApprovedById = @UserId,
        dtmApproved = GETDATE(),
        strApprovedBy = @FullName,
        dtmPublish = @PublishFrom,
        dtmPublishUntil = @PublishUntil,
        iInternetDoc = @isInternetDocument
    WHERE
		iDocumentId = @DocumentId
        AND iLatestVersion = 1
	
	EXEC m136_insertEntityIntoTextIndex @EntityId
		
	EXEC dbo.m136_SetVersionFlags @DocumentId
	
END
GO