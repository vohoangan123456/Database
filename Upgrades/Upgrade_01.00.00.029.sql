INSERT INTO #Description VALUES('create stored
[dbo].[m136_NormalSearch]')
GO

IF OBJECT_ID('[dbo].[m136_NormalSearch]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_NormalSearch] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_NormalSearch]
	@keyword NVARCHAR(MAX) = NULL,
	@searchInContent BIT,
	@iSecurityId INT,
	@iDocumentId INT
AS
SET NOCOUNT ON
BEGIN
	IF(@searchInContent = 0)
		BEGIN
			SELECT DISTINCT	doc.iDocumentId AS Id,
							doc.iHandbookId,
							doc.strName,
							doc.iDocumentTypeId,
							doc.iVersion AS [Version],
							handbook.iLevelType AS LevelType,
							doc.dtmApproved,
							doc.strApprovedBy,
							dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) as Responsible,
							NULL AS DepartmentId,
							0 AS Virtual,
							doc.iSort,
							dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path],
							handbook.strName AS ParentFolderName,
							[dbo].[fnHasDocumentAttachment](doc.iEntityId) as HasAttachment 
			FROM			m136_tblDocument doc
				INNER JOIN	m136_tblHandbook handbook 
					ON handbook.iHandbookId = doc.iHandbookId
			WHERE			doc.iDeleted=0
				AND			iDraft=0
				AND			iApproved=1
				AND			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, handbook.iHandbookId) = 1
				AND			iLatestApproved = 1
				AND			(Doc.strName LIKE '%' + @keyword + '%'
					OR		Doc.iDocumentId = @iDocumentId)
		END
	ELSE
		BEGIN
			SELECT DISTINCT	doc.iDocumentId AS Id,
							doc.iHandbookId,
							doc.strName,
							doc.iDocumentTypeId,
							doc.iVersion AS [Version],
							handbook.iLevelType AS LevelType,
							doc.dtmApproved,
							doc.strApprovedBy,
							dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) as Responsible,
							NULL AS DepartmentId,
							0 AS Virtual,
							doc.iSort,
							dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path],
							handbook.strName AS ParentFolderName,
							[dbo].[fnHasDocumentAttachment](doc.iEntityId) as HasAttachment
			FROM			m136_tblDocument doc
				INNER JOIN	m136_tblHandbook handbook 
					ON handbook.iHandbookId = doc.iHandbookId
				LEFT JOIN	m136_tblMetaInfoRichText RichTextInfo 
					ON RichTextInfo.iEntityId = doc.iEntityId
				LEFT JOIN	m136_tblMetaInfoText TextInfo 
					ON TextInfo.iEntityId = doc.iEntityId
			WHERE			doc.iDeleted=0
				AND			iDraft=0
				AND			iApproved=1
				AND			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, handbook.iHandbookId) = 1
				AND			iLatestApproved = 1
				AND			(RichTextInfo.value LIKE '%' + @keyword + '%'
					OR		TextInfo.value LIKE '%' + @keyword + '%'
					OR		Doc.strName LIKE '%' + @keyword + '%'
					OR		Doc.iDocumentId = @iDocumentId)
		END
END
GO