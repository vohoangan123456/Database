INSERT INTO #Description VALUES ('Modify SP [dbo].[m136_be_GetDocumentsByHandbookIdRecursive] to get internet document')
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentsByHandbookIdRecursive]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentsByHandbookIdRecursive] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetDocumentsByHandbookIdRecursive] 
	@iHandbookId INT = 0,
	@iSecurityId INT = 0
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	INSERT INTO @AvailableChildren(iHandbookId)
		SELECT 
			iHandbookId 
		FROM 
			[dbo].[m136_GetHandbookRecursive](@iHandbookId, @iSecurityId, 1);
		SELECT DISTINCT 
			d.iDocumentId AS Id, 
			d.iEntityId,
			h.iHandbookId,
			d.strName, 
			d.iDocumentTypeId, 
			d.iVersion AS [Version],
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			h.iDepartmentId AS DepartmentId,
			0 AS Virtual,
			d.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
			d.iApproved,
			d.iDraft,
			d.dtmPublish,
			d.dtmPublishUntil,
			dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) as iAccess,
			d.iCreatedbyId,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
			h.iHandbookId AS iParentHandbookId,
			0 AS iChildCount,
			d.iDeleted,
			d.dtmCreated,
			d.dtmAlter,
			h.iHandbookId AS VirtualHandbookId,
			d.iReadCount AS ReadCount,
			d.iInternetDoc
		FROM 
			m136_tblDocument d
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
				JOIN @AvailableChildren ac
					ON d.iHandbookId = ac.iHandbookId
		WHERE
			d.iLatestVersion = 1
	UNION       
		SELECT 
			d.iDocumentId AS Id, 
			d.iEntityId,
			h.iHandbookId,
			d.strName, 
			d.iDocumentTypeId,
			d.iVersion AS [Version],
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			h.iDepartmentId AS DepartmentId,
			1 AS Virtual,
			virt.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
			d.iApproved,
			d.iDraft,
			d.dtmPublish,
			d.dtmPublishUntil,
			dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) as iAccess,
			d.iCreatedbyId,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
			h.iHandbookId AS iParentHandbookId,
			0 AS iChildCount,
			d.iDeleted,
			d.dtmCreated,
			d.dtmAlter,
			virt.iHandbookId AS VirtualHandbookId,
			d.iReadCount AS ReadCount,
			d.iInternetDoc			
		FROM 
			m136_relVirtualRelation virt 
				JOIN m136_tblDocument d
					ON virt.iDocumentId = d.iDocumentId
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
				JOIN @AvailableChildren ac
					ON virt.iHandbookId = ac.iHandbookId
		WHERE
			d.iLatestVersion = 1
	ORDER BY 
		iSort, 
		strName
END
GO

IF OBJECT_ID('[dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive] 
	@iHandbookId INT = 0,
	@iSecurityId INT = 0
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	INSERT INTO @AvailableChildren(iHandbookId)
		SELECT 
			iHandbookId 
		FROM 
			[dbo].[m136_GetHandbookRecursive](@iHandbookId, @iSecurityId, 1);
		SELECT DISTINCT 
			d.iDocumentId AS Id, 
			h.iHandbookId,
			d.strName, 
			d.iDocumentTypeId, 
			d.iVersion AS [Version],
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			h.iDepartmentId AS DepartmentId,
			0 AS Virtual,
			d.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
			d.iApproved,
			d.iDraft,
			d.dtmPublish,
			d.dtmPublishUntil,
			d.iHandbookId AS VirtualHandbookId,
			d.iInternetDoc
		FROM 
			m136_tblDocument d
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
				JOIN @AvailableChildren ac
					ON d.iHandbookId = ac.iHandbookId
		WHERE
			d.iLatestApproved = 1
	UNION       
		SELECT 
			d.iDocumentId AS Id, 
			h.iHandbookId,
			d.strName, 
			d.iDocumentTypeId,
			d.iVersion AS [Version],
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			h.iDepartmentId AS DepartmentId,
			1 AS Virtual,
			virt.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(virt.iHandbookId) AS [Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
			d.iApproved,
			d.iDraft,
			d.dtmPublish,
			d.dtmPublishUntil,
			virt.iHandbookId AS VirtualHandbookId,
			d.iInternetDoc
		FROM 
			m136_relVirtualRelation virt 
				JOIN m136_tblDocument d
					ON virt.iDocumentId = d.iDocumentId
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
				JOIN @AvailableChildren ac
					ON virt.iHandbookId = ac.iHandbookId
		WHERE
			d.iLatestApproved = 1
	ORDER BY 
		iSort, 
		strName
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
			dbo.m136_fnGetItemValue(dt.iAutoId) AS MetatagValue,
			d.iInternetDoc
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
			dbo.m136_fnGetItemValue(dt.iAutoId) AS MetatagValue,
			d.iInternetDoc
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

IF OBJECT_ID('[dbo].[m136_GetDocumentAwaitingHearings]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentAwaitingHearings] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetDocumentAwaitingHearings]
	@UserId INT = NULL
AS
BEGIN
	SELECT	d.iDocumentId as Id,
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
			he.DueDate,
			he.IsPublic
	FROM	dbo.m136_Hearings he
	JOIN    dbo.m136_HearingMembers m ON he.Id = m.HearingsId AND m.EmployeeId = @UserId
	JOIN	m136_tblDocument d ON he.EntityId = d.iEntityId
	JOIN    dbo.m136_tblHandbook h ON h.iHandbookId = d.iHandbookId
	LEFT JOIN dbo.tblEmployee te ON d.iCreatedbyId = te.iEmployeeId
	WHERE	he.IsActive = 1 AND m.HearingResponse IS NULL
			
END
GO