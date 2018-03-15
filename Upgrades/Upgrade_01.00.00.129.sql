INSERT INTO #Description VALUES('Create procedure  [dbo].[m136_be_GetDocumentsByDocumentIds]')
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentsByDocumentIds]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentsByDocumentIds]  AS SELECT 1')
GO

-- =============================================
-- Author:		SI.MANH.NGUYEN
-- Create date: Nov 16, 2015
-- Description:	Get doucments by list documentid
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetDocumentsByDocumentIds] 
	@DocumentIds AS [dbo].[Item] READONLY
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
			h.iLevel,
			te.strEmail AS strCreatedByEmail,
			d.strAuthor,
			d.UrlOrFileName,
			d.UrlOrFileProperties,
			d.[File],
			d.iCompareToVersion	,
			d.iInternetDoc		
	FROM	@DocumentIds d1
	JOIN	m136_tblDocument d ON d.iDocumentId = d1.Id
	JOIN    dbo.m136_tblHandbook h ON h.iHandbookId = d.iHandbookId
	LEFT JOIN dbo.tblEmployee te ON d.iCreatedbyId = te.iEmployeeId 
	WHERE d.iLatestVersion = 1
END
GO

IF OBJECT_ID('[dbo].[m136_be_ArchiveDocument]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_ArchiveDocument]  AS SELECT 1')
GO

-- =============================================
-- Author:		SI.NGUYEN.MANH
-- Create date: NOV 16, 2015
-- Description:	Update Archive document
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_ArchiveDocument] 
	@DocumentIds AS [dbo].[Item] READONLY,
	@UserId INT,
	@Description varchar(2000)
AS
BEGIN
	IF @Description IS NOT NULL
		BEGIN	      
			UPDATE dbo.m136_tblDocument
			SET iApproved = 4,
				iApprovedById = @UserId,
				dtmApproved = getdate(),
				strApprovedBy = dbo.fnOrgGetUserName(@UserId, '', 0),
				strDescription = @Description + ' ' + strDescription
			WHERE iEntityId IN(
					SELECT iEntityId 
					FROM @DocumentIds AS doc
					JOIN	m136_tblDocument d ON d.iDocumentId = doc.Id AND d.iLatestVersion = 1
				  )
		END
	ELSE
		BEGIN
			UPDATE dbo.m136_tblDocument
			SET iApproved = 4,
				iApprovedById = @UserId,
				dtmApproved = getdate(),
				strApprovedBy = dbo.fnOrgGetUserName(@UserId, '', 0)
			WHERE iEntityId IN(
					SELECT iEntityId 
					FROM @DocumentIds AS doc
					JOIN	m136_tblDocument d ON d.iDocumentId = doc.Id AND d.iLatestVersion = 1
				  )
		END
		
	DECLARE @iDocumentId INT
	DECLARE curDocumentId CURSOR FOR 
		SELECT Id
		FROM @DocumentIds;
	OPEN curDocumentId; 
	FETCH NEXT FROM curDocumentId INTO @iDocumentId;
	WHILE @@FETCH_STATUS = 0
    BEGIN
		EXEC dbo.m136_SetVersionFlags @iDocumentId
		FETCH NEXT FROM curDocumentId INTO @iDocumentId;
	END
	CLOSE curDocumentId;
	DEALLOCATE curDocumentId;
END
GO
