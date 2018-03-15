INSERT INTO #Description VALUES ('create vaule default when dbo.m147_tblEtype table have not row')
GO

MERGE INTO dbo.m147_tblEtype AS Target
USING (VALUES (1, N'Uten data', ''), (2, N'Tall', ''), (3, N'Hierarki', ''),(4, N'Dato', ''), (5, N'Tekst', ''), (6, N'Liste', '') )
AS Source(eTypeId, strName, strDescription)
ON Target.eTypeId = Source.eTypeId
WHEN NOT MATCHED BY TARGET THEN
INSERT (eTypeId, strName, strDescription) VALUES (Source.eTypeId, Source.strName, Source.strDescription);
GO



IF OBJECT_ID('[dbo].[m136_be_GetDocumentMetatags]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentMetatags] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetDocumentMetatags]
	-- Add the parameters for the stored procedure here
	@iHandbookId int = 0,
	@iRegisterItemId int = 0,
	@bRecursive BIT = 0,
	@bIncludeLevel1 BIT = 0,
	@iSecurityId INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @AvailableHandbooks TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	IF (@bRecursive = 1)
	BEGIN
		INSERT INTO @AvailableHandbooks 
			SELECT iHandbookId FROM [dbo].[m136_GetHandbookRecursive] (@iHandbookId, NULL, 0);
	END
	ELSE
	BEGIN
		INSERT INTO @AvailableHandbooks SELECT @iHandbookId
	END
	IF (@bIncludeLevel1 = 1)
	BEGIN
		DECLARE @TmpHandbooks TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
		INSERT INTO @TmpHandbooks
		SELECT iHandbookId 
			FROM @AvailableHandbooks
		INSERT INTO @AvailableHandbooks 
			SELECT iHandbookId 
			FROM [dbo].[m136_tblHandbook] 
			WHERE iLevelType = 1 
				  AND iDeleted = 0
				  AND iHandbookId NOT IN (SELECT iHandbookId FROM @TmpHandbooks)
	END
	SELECT * 
	INTO #resultTable
	FROM (
		SELECT
			d.iDocumentId as Id,
			d.iEntityId,
			d.iHandbookId,
			d.strName,
			d.iDocumentTypeId,
			d.iVersion as Version,
			h.iLevelType as LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			h.iDepartmentId as DepartmentId,
			0 as Virtual,
			d.iSort,
			h.strName as ParentFolderName,
			dbo.fn136_GetParentPathEx(h.iHandbookId) as Path,
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
			d.iApproved,
			d.iDraft,
			d.dtmPublish,
			d.dtmPublishUntil,
			dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) as iAccess,
			d.iCreatedbyId,
            d.iInternetDoc,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
			h.iHandbookId AS iParentHandbookId,
			CAST(0 as INT) AS iChildCount,
			d.iDeleted,
			d.dtmCreated,
			d.dtmAlter,
			1 AS IsDocument,
			d.iHandbookId AS VirtualHandbookId,
			d.iReadCount AS ReadCount,
			dbo.m136_fnGetItemValue(dt.iAutoId) AS MetatagValue
		FROM 
			m136_tblDocument d
            JOIN m136_tblHandbook h on d.iHandbookId = h.iHandbookId
			JOIN m147_relRegisterItemItem dt ON d.iDocumentId = dt.iItemId 
				AND (dt.iRegisterItemId = @iRegisterItemId AND dt.iModuleId = 136)
		WHERE d.iLatestVersion = 1
			AND d.iHandbookId in (SELECT iHandbookId FROM @AvailableHandbooks)
	UNION
		SELECT 
			virt.iDocumentId as Id,
			d.iEntityId,
			d.iHandbookId,
			d.strName,
			d.iDocumentTypeId,
			d.iVersion as Version,
			h.iLevelType as LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			h.iDepartmentId as DepartmentId,
			1 as Virtual,
			virt.iSort,
			h.strName as ParentFolderName,
			dbo.fn136_GetParentPathEx(h.iHandbookId) as Path,
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
			d.iApproved,
			d.iDraft,
			d.dtmPublish,
			d.dtmPublishUntil,
			dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) as iAccess,
			d.iCreatedbyId,
            d.iInternetDoc,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
			h.iHandbookId AS iParentHandbookId,
			CAST(0 as INT) AS iChildCount,
			d.iDeleted,
			d.dtmCreated,
			d.dtmAlter,
			1 AS IsDocument,
			virt.iHandbookId AS VirtualHandbookId,
			d.iReadCount AS ReadCount,
			dbo.m136_fnGetItemValue(dt.iAutoId) AS MetatagValue
		FROM 
			m136_relVirtualRelation virt
			JOIN m136_tblDocument d on virt.iDocumentId = d.iDocumentId
			JOIN m136_tblHandbook h on d.iHandbookId = h.iHandbookId AND h.iHandbookId <> @iHandbookId
			JOIN m147_relRegisterItemItem dt ON d.iDocumentId = dt.iItemId 
				AND (dt.iRegisterItemId = @iRegisterItemId AND dt.iModuleId = 136) 					
		WHERE 	
			d.iLatestVersion = 1
			AND virt.iHandbookId in (SELECT iHandbookId FROM @AvailableHandbooks)
	) r
	ORDER BY r.MetatagValue DESC, r.iSort
	
	SELECT * FROM #resultTable WHERE #resultTable.MetatagValue IS NOT NULL;
	
	SELECT d.Id AS iDocumentId,
        r.iItemId,
		b.strName,
		r.iPlacementId,
		r.iProcessrelationTypeId,
		b.strExtension,
		b.strDescription,
		r.iSort 
	FROM m136_relInfo r 
		JOIN (SELECT DISTINCT iEntityId, Id FROM #resultTable) d ON r.iEntityId = d.iEntityId
		JOIN m136_tblBlob b ON r.iItemId = b.iItemId
	WHERE r.iRelationTypeId = 20
	ORDER BY r.iSort, b.strName;
END
GO




IF OBJECT_ID('[dbo].[m136_GetDocumentMetatags]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentMetatags] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetDocumentMetatags]
	@iHandbookId int = 0,
	@iRegisterItemId int = 0,
	@bRecursive BIT = 0,
	@bIncludeLevel1 BIT = 0
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @AvailableHandbooks TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	IF (@bRecursive = 1)
	BEGIN
		INSERT INTO @AvailableHandbooks 
			SELECT iHandbookId FROM [dbo].[m136_GetHandbookRecursive] (@iHandbookId, NULL, 0);
	END
	ELSE
	BEGIN
		INSERT INTO @AvailableHandbooks SELECT @iHandbookId
	END
	IF (@bIncludeLevel1 = 1)
	BEGIN
		DECLARE @TmpHandbooks TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
		INSERT INTO @TmpHandbooks
		SELECT iHandbookId 
			FROM @AvailableHandbooks
		INSERT INTO @AvailableHandbooks 
			SELECT iHandbookId 
			FROM [dbo].[m136_tblHandbook] 
			WHERE iLevelType = 1 
				  AND iDeleted = 0
				  AND iHandbookId NOT IN (SELECT iHandbookId FROM @TmpHandbooks)
	END
	SELECT * 
	INTO #resultTable
	FROM (
		SELECT
			d.iDocumentId as Id,
			d.iEntityId,
			d.iHandbookId,
			d.strName,
			d.iDocumentTypeId,
			d.iVersion as Version,
			h.iLevelType as LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			h.iDepartmentId as DepartmentId,
			0 as Virtual,
			d.iSort,
			h.strName as ParentFolderName,
			dbo.fn136_GetParentPathEx(h.iHandbookId) as Path,
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
			d.iApproved,
			d.iDraft,
			h.iParentHandbookId,
			0 AS iChildCount,
            1 AS IsDocument,
			d.iHandbookId AS VirtualHandbookId,
			dbo.m136_fnGetItemValue(dt.iAutoId) AS MetatagValue
		FROM 
			m136_tblDocument d
            JOIN m136_tblHandbook h on d.iHandbookId = h.iHandbookId
			JOIN m147_relRegisterItemItem dt ON d.iDocumentId = dt.iItemId 
				AND (dt.iRegisterItemId = @iRegisterItemId AND dt.iModuleId = 136)
		WHERE d.iLatestApproved = 1
			AND d.iHandbookId in (SELECT iHandbookId FROM @AvailableHandbooks)
	UNION
		SELECT 
			d.iDocumentId as Id,
			d.iEntityId,
			d.iHandbookId,
			d.strName,
			d.iDocumentTypeId,
			d.iVersion as Version,
			h.iLevelType as LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			h.iDepartmentId as DepartmentId,
			0 as Virtual,
			d.iSort,
			h.strName as ParentFolderName,
			dbo.fn136_GetParentPathEx(h.iHandbookId) as Path,
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
			d.iApproved,
			d.iDraft,
			h.iParentHandbookId,
			0 AS iChildCount,
            1 AS IsDocument,
			virt.iHandbookId AS VirtualHandbookId,
			dbo.m136_fnGetItemValue(dt.iAutoId) AS MetatagValue
		FROM 
			m136_relVirtualRelation virt
			JOIN m136_tblDocument d on virt.iDocumentId = d.iDocumentId
			JOIN m136_tblHandbook h on d.iHandbookId = h.iHandbookId AND h.iHandbookId <> @iHandbookId
			JOIN m147_relRegisterItemItem dt ON d.iDocumentId = dt.iItemId 
				AND (dt.iRegisterItemId = @iRegisterItemId AND dt.iModuleId = 136) 					
		WHERE 	
			d.iLatestApproved = 1
			AND virt.iHandbookId in (SELECT iHandbookId FROM @AvailableHandbooks)
	) r
	ORDER BY r.MetatagValue DESC, r.iSort
	SELECT * FROM #resultTable WHERE #resultTable.MetatagValue IS NOT NULL;
	SELECT d.Id AS iDocumentId,
        r.iItemId,
		b.strName,
		r.iPlacementId,
		r.iProcessrelationTypeId,
		b.strExtension,
		b.strDescription,
		r.iSort 
	FROM m136_relInfo r 
		JOIN (SELECT DISTINCT iEntityId, Id FROM #resultTable) d ON r.iEntityId = d.iEntityId
		JOIN m136_tblBlob b ON r.iItemId = b.iItemId
	WHERE r.iRelationTypeId = 20
	ORDER BY r.iSort, b.strName;
END
GO