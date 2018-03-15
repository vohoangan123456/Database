INSERT INTO #Description VALUES('Modify existing procedures m136_be_GetDocumentInformation, m136_LockDocument. Create new procedures m136_HasLockDocumentWithId, m136_UnlockDocumentByAdmin')
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
            CASE WHEN EXISTS(SELECT 1 FROM m136_tblDocumentLock WHERE iEntityId = d.iEntityId) THEN 1 ELSE 0 END AS bIsLocked,
            dbo.fnOrgGetUserName((SELECT TOP 1 iEmployeeId FROM m136_tblDocumentLock WHERE iEntityId = d.iEntityId), '', 0) strLockedBy
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
        
        SELECT SCOPE_IDENTITY();
                
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK
END CATCH
END
GO

IF OBJECT_ID('[dbo].[m136_UnlockDocumentByAdmin]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_UnlockDocumentByAdmin] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_UnlockDocumentByAdmin]
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
            
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK
END CATCH
END
GO

IF OBJECT_ID('[dbo].[m136_HasLockDocumentWithId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_HasLockDocumentWithId] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_HasLockDocumentWithId]
	@LockId INT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
    
        DECLARE @HasLock INT = 0;
        
        IF EXISTS (SELECT 1 FROM m136_tblDocumentLock WHERE iLockId = @LockId)
        BEGIN
            SET @HasLock = 1
        END
        
        SELECT @HasLock
            
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK
END CATCH
END
GO