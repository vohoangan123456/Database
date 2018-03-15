INSERT INTO #Description VALUES ('Document management view - created field update')
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentInformation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentInformation] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetDocumentInformation]
	@DocumentId INT = NULL,
    @LockRenewPeriod INT
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
            CASE
                WHEN rel.iEmployeeId IS NOT NULL THEN dbo.fnOrgGetUserName(rel.iEmployeeId, '', 0)
                ELSE d.strApprovedBy
            END AS strApprovedBy,
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
			d.iDeleted,
			d.iCreatedbyId,
			rel.iEmployeeId AS empApproveOnBehalfId,
			CASE WHEN rel.iEmployeeId IS NOT NULL THEN  dbo.fnOrgGetUserName(rel.iEmployeeId, '', 0) ELSE '' END AS strEmpApproveOnBehalf,
            CASE WHEN EXISTS(
                SELECT 1 FROM m136_tblDocumentLock 
                WHERE iEntityId = d.iEntityId 
                    AND (DATEDIFF(minute, dtmLocked, GETDATE()) < @LockRenewPeriod)) THEN 1 
            ELSE 0 END AS bIsLocked,
            dbo.fnOrgGetUserName(
                (SELECT TOP 1 iEmployeeId 
                    FROM m136_tblDocumentLock 
                    WHERE iEntityId = d.iEntityId
                        AND (DATEDIFF(minute, dtmLocked, GETDATE()) < @LockRenewPeriod)
                ), '', 0) strLockedBy,
            iOrientation,
            CASE WHEN EXISTS (SELECT 1 FROM m136_tblCopyConfirms WHERE iEntityId = d.iEntityId) THEN 1 ELSE 0 END AS IsCopyReadingReceiptFromResponsible,
			KeyWords,
			TitleAndKeyword,
			d.dtmCreated
	FROM	m136_tblDocument d
        JOIN dbo.m136_tblHandbook h ON h.iHandbookId = d.iHandbookId
        LEFT JOIN dbo.tblEmployee te ON d.iCreatedbyId = te.iEmployeeId
        LEFT JOIN dbo.m136_relSentEmpApproval rel 
            ON d.iEntityId = rel.iEntityId 
            AND rel.dtmSentToApproval = (SELECT MAX(dtmSentToApproval) FROM dbo.m136_relSentEmpApproval WHERE iEntityId = d.iEntityId)
	WHERE	d.iDocumentId = @DocumentId	AND 
			d.iLatestVersion = 1
END

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
			d.iLatestVersion,
            d.iOrientation,
            d.iInternetDoc,
            d.KeyWords,
            d.dtmCreated
	FROM	m136_tblDocument d
	WHERE	d.iDocumentId = @DocumentId	AND 
			d.iLatestApproved = 1
END
