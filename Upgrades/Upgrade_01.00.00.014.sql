INSERT INTO #Description VALUES('edit stored procedure 
[dbo].[m136_AddHandbookToFavorites],
[dbo].[m136_RemoveHandbookOffFavorites],
[dbo].[m136_AddDocumentToFavorites],
[dbo].[m136_RemoveDocumentOffFavorites],
[dbo].[m136_GetChapterItems],
[dbo].[m136_GetDocumentInformation]')
GO

IF OBJECT_ID('[dbo].[m136_AddHandbookToFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_AddHandbookToFavorites] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_AddHandbookToFavorites]
	@HandbookId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	INSERT INTO [dbo].[m136_tblSubscribe] ([iEmployeeId], [iHandbookId], [iEmail], [iFrontpage], [iPDA], [iSort]) 
	VALUES (@iSecurityId, @HandbookId,0,1,0,0)
END
GO

IF OBJECT_ID('[dbo].[m136_RemoveHandbookOffFavorites]', 'p') IS NOT NULL
    DROP PROCEDURE [dbo].[m136_RemoveHandbookOffFavorites];
GO
IF OBJECT_ID('[dbo].[m136_RemoveHandbookFromFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_RemoveHandbookFromFavorites] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_RemoveHandbookFromFavorites]
	@HandbookId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	DELETE FROM [dbo].[m136_tblSubscribe]
	WHERE [iEmployeeId] = @iSecurityId
	AND [iHandbookId] = @HandbookId
END
GO

IF OBJECT_ID('[dbo].[m136_AddDocumentToFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_AddDocumentToFavorites] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_AddDocumentToFavorites]
	@DocumentId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	INSERT INTO [dbo].[m136_tblSubscriberDocument] ([iEmployeeId], [iDocumentId], [iSort]) 
	VALUES (@iSecurityId, @DocumentId, 0)
END
GO

IF OBJECT_ID('[dbo].[m136_RemoveDocumentOffFavorites]', 'p') IS NOT NULL
    DROP PROCEDURE [dbo].[m136_RemoveDocumentOffFavorites];
GO
IF OBJECT_ID('[dbo].[m136_RemoveDocumentFromFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_RemoveDocumentFromFavorites] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_RemoveDocumentFromFavorites]
	@DocumentId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	DELETE FROM [dbo].[m136_tblSubscriberDocument]
	WHERE [iEmployeeId] = @iSecurityId
	AND [iDocumentId] = @DocumentId
END
GO

IF OBJECT_ID('[dbo].[m136_GetChapterItems]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetChapterItems] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetChapterItems]
	@iHandbookId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	SELECT	strName as FolderName,
				iParentHandbookId as ParentId,
				dbo.fn136_GetParentPathEx(@iHandbookId) as Path,
				iLevel as Level,
				iViewTypeId as ViewType
		FROM m136_tblHandbook
		WHERE iHandbookId = @iHandbookId AND @iHandbookId IS NOT NULL
		SELECT	d.iDocumentId as Id,
				d.strName,
				dt.iDocumentTypeId as TemplateId,
				dt.Type as DocumentType,
				d.iVersion as Version,
				NULL as LevelType,
				d.dtmApproved,
				d.strApprovedBy,
				dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
				null as DepartmentId,
				0 as Virtual,
				d.iSort,
				NULL as ParentFolderName,
				NULL as Path
		FROM	m136_tblDocument d
			INNER JOIN m136_tblDocumentType dt 
				ON d.iDocumentTypeId = dt.iDocumentTypeId
		WHERE	d.iHandbookId = @iHandbookId
			AND d.iLatestApproved = 1
			AND d.iDeleted = 0
	UNION
		SELECT v.iDocumentId as Id,
			   d.strName,
			   dt.iDocumentTypeId as TemplateId,
			   dt.Type as DocumentType,
			   d.iVersion as Version,
			   NULL as LevelType,
			   d.dtmApproved,
			   d.strApprovedBy,
			   dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			   null as DepartmentId,
			   1 as Virtual,
			   v.iSort,
			   h.strName as ParentFolderName,
			   dbo.fn136_GetParentPathEx(h.iHandbookId) as Path
		FROM m136_relVirtualRelation v
			INNER JOIN m136_tblDocument d 
				ON d.iDocumentId = v.iDocumentId
			INNER JOIN m136_tblDocumentType dt 
				ON d.iDocumentTypeId = dt.iDocumentTypeId
			INNER JOIN m136_tblHandbook h
				ON d.iHandbookId = h.iHandbookId
		WHERE	v.iHandbookId = @iHandbookId
				AND d.iDeleted = 0
				AND d.iLatestApproved = 1
	UNION
		SELECT	h.iHandbookId as Id,
				h.strName,
				NULL as TemplateId,
				-1 as DocumentType,
				NULL as Version,
				iLevelType as LevelType,
				NULL as dtmApproved,
				NULL as strApprovedBy,
				NULL as Responsible,
				h.iDepartmentId as DepartmentId,
				0 as Virtual,
				-2147483648 + h.iMin as iSort, -- Little trick with putting all the folders on top of documents sorted by iMin TODO - there can be a better way with the constant more importantly
				NULL as ParentFolderName,
				NULL as Path
		FROM m136_tblHandbook as h
		WHERE	(h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
				AND h.iDeleted = 0
	ORDER BY d.iSort ASC, 
			 d.strName ASC
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
			d.strApprovedBy, 
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) strCreatedBy, 
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path
	FROM m136_tblDocument d
	WHERE	d.iDocumentId = @DocumentId	AND 
			d.iApproved = 1				AND
			d.iLatestApproved = 1		AND
			d.iDeleted = 0
END
GO