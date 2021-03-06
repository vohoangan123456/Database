INSERT INTO #Description VALUES('Create procedures, modify existing procedures to support feature allow only one user can edit document at the same time')
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
            CASE WHEN EXISTS(SELECT 1 FROM m136_tblDocumentLock WHERE iEntityId = d.iEntityId) THEN 1 ELSE 0 END AS bIsLocked
	FROM	m136_tblDocument d
	JOIN    dbo.m136_tblHandbook h ON h.iHandbookId = d.iHandbookId
	LEFT JOIN dbo.tblEmployee te ON d.iCreatedbyId = te.iEmployeeId
	LEFT JOIN dbo.m136_relSentEmpApproval rel 
		ON d.iEntityId = rel.iEntityId 
		AND rel.dtmSentToApproval = (SELECT MAX(dtmSentToApproval) FROM dbo.m136_relSentEmpApproval WHERE iEntityId = d.iEntityId)
	WHERE	d.iDocumentId = @DocumentId	AND 
			d.iLatestVersion = 1
END
GO

IF OBJECT_ID('[dbo].[m136_LockDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_LockDocument] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_LockDocument]
    @UserId INT,
	@DocumentId INT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
    
        DECLARE @EntityId INT;
        
        SET @EntityId = (SELECT iEntityId FROM m136_tblDocument WHERE iDocumentId = @DocumentID AND iLatestVersion = 1);
        
        INSERT INTO
            m136_tblDocumentLock
                (iEntityId, iEmployeeId, dtmLocked)
            VALUES
                (@EntityId, @UserId, GETDATE())
                
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK
END CATCH
END
GO

IF OBJECT_ID('[dbo].[m136_UnlockDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_UnlockDocument] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_UnlockDocument]
    @UserId INT,
	@DocumentId INT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
    
        DECLARE @EntityId INT;
        
        SET @EntityId = (SELECT iEntityId FROM m136_tblDocument WHERE iDocumentId = @DocumentID AND iLatestVersion = 1);
        
        DELETE FROM
            m136_tblDocumentLock
        WHERE
            iEntityId = @EntityId
            AND iEmployeeId = @UserId
            
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK
END CATCH
END
GO