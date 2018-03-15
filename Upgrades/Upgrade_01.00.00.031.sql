INSERT INTO #Description VALUES('repalce stored
[dbo].[m136_NormalSearch]
with stored
[dbo].[m136_SearchDocuments ]
add fulltext index search for tblDocument and tblTextIndex
add stored procedure m136_SearchDocumentsById
add stored
[dbo].[m136_SearchDocumentsById]')
GO

IF NOT EXISTS(SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID(N'[dbo].[m136x_tblTextIndex]'))
	BEGIN
		DECLARE @indexKey NVARCHAR(200);
		DECLARE @sqlString NVARCHAR(MAX);
		
		SET @indexKey = (SELECT CONSTRAINT_NAME 
						 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
						 WHERE TABLE_NAME = 'm136x_tblTextIndex' AND CONSTRAINT_TYPE = 'PRIMARY KEY')
		SET @sqlString = N'CREATE FULLTEXT INDEX ON [dbo].[m136x_tblTextIndex](totalvalue) KEY INDEX ' 
						 + @indexKey 
						 + N' ON Handbook WITH CHANGE_TRACKING AUTO;';
		
		EXEC(@sqlString)
	END
GO

IF TYPE_ID(N'SearchTermTable') IS NULL
	EXEC ('CREATE TYPE SearchTermTable AS TABLE([Term] VARCHAR(900) NULL)')
GO

IF OBJECT_ID('[dbo].[m136_NormalSearch]', 'p') IS NOT NULL
    DROP PROCEDURE [dbo].[m136_NormalSearch]
GO
IF OBJECT_ID('[dbo].[m136_SearchDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_SearchDocuments] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_SearchDocuments]
	@keyword VARCHAR(900),
	@searchInContent BIT,
	@iSecurityId INT,
	@searchTermTable AS [dbo].[SearchTermTable] READONLY
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
			WHERE			iLatestApproved = 1
				AND			doc.iEntityId in (SELECT	iEntityId
											  FROM		m136_tblDocument d 
												INNER JOIN @searchTermTable st
													ON	d.strName LIKE '%' + st.Term + '%'
											  WHERE		d.iLatestApproved = 1)
				AND			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, handbook.iHandbookId) = 1
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
				LEFT JOIN	m136x_tblTextIndex textIndex 
					ON textIndex.iEntityId = doc.iEntityId
			WHERE			iLatestApproved = 1
				AND			(doc.iEntityId in (SELECT	iEntityId
											  FROM		m136_tblDocument d 
												INNER JOIN @searchTermTable st
													ON	d.strName LIKE '%' + st.Term + '%'
											  WHERE		d.iLatestApproved = 1)
					OR		CONTAINS(totalvalue,@keyword))
				AND			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, handbook.iHandbookId) = 1
				
		END
END
GO

IF OBJECT_ID('[dbo].[m136_SearchDocumentsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_SearchDocumentsById] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_SearchDocumentsById]
	@iSecurityId INT,
	@iDocumentId VARCHAR(100)
AS
SET NOCOUNT ON
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
	WHERE			iLatestApproved = 1
		AND			Doc.iDocumentId LIKE '%' + @iDocumentId + '%'
		AND			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, handbook.iHandbookId) = 1
END
GO