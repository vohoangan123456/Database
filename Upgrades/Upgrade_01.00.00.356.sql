INSERT INTO #Description VALUES ('Modified SP m136_be_GetChapterItems and m136_be_GetSecurityGroups')
GO

IF OBJECT_ID('[dbo].[m136_be_GetChapterItems]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetChapterItems] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetChapterItems]
	@iHandbookId INT = NULL,
	@iSecurityId INT,
	@bShowDocumentsInTree BIT
AS
BEGIN
	SET NOCOUNT ON;
    SELECT
        strName as FolderName,
		iParentHandbookId as ParentId,
		dbo.fn136_GetParentPathEx(@iHandbookId) as Path,
		iLevel as Level,
		iViewTypeId as ViewType,
		iLevelType as LevelType,
		iDepartmentId as DepartmentId,
		strDescription,
		[dbo].[fn136_be_GetChildCount] (@iSecurityId, iHandbookId, @bShowDocumentsInTree) AS iChildCount
    FROM
        m136_tblHandbook
	WHERE
        iHandbookId = @iHandbookId AND @iHandbookId IS NOT NULL;
        
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
        NULL as ParentFolderName,
        dbo.fn136_GetParentPathEx(d.iHandbookId) as Path,
        [dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
        d.iApproved,
        dbo.fnDocumentCanBeApproved(d.iEntityId) AS bCanBeApproved,
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
        d.iReadCount AS ReadCount
    FROM
        m136_tblDocument d
            LEFT JOIN m136_tblHandbook h 
                ON h.iHandbookId = d.iHandbookId
    WHERE
        d.iHandbookId = @iHandbookId
        AND d.iLatestVersion = 1 AND d.iDeleted = 0
        
	UNION
    
    SELECT
        v.iDocumentId as Id,
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
        v.iSort,
        h.strName as ParentFolderName,
        dbo.fn136_GetParentPathEx(d.iHandbookId) as Path,
        [dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
        d.iApproved,
        dbo.fnDocumentCanBeApproved(d.iEntityId) AS bCanBeApproved,
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
        v.iHandbookId AS VirtualHandbookId,
        d.iReadCount AS ReadCount
    FROM
        m136_relVirtualRelation v
            INNER JOIN m136_tblDocument d 
                ON d.iDocumentId = v.iDocumentId
            INNER JOIN m136_tblHandbook h
                ON d.iHandbookId = h.iHandbookId
    WHERE
        v.iHandbookId = @iHandbookId
        AND d.iLatestVersion = 1 AND d.iDeleted = 0 and d.iApproved != 4
        
	UNION
    
    SELECT	
        h.iHandbookId as Id,
        -1 as iEntityId,
        h.iHandbookId,
        h.strName,
        -1 as iDocumentTypeId,
        NULL as Version,
        iLevelType as LevelType,
        NULL as dtmApproved,
        NULL as strApprovedBy,
        NULL as Responsible,
        h.iDepartmentId as DepartmentId,
        0 as Virtual,
        h.iSort,
        NULL as ParentFolderName,
        dbo.fn136_GetParentPathEx(h.iHandbookId) as Path,
        0 as HasAttachment,
        NULL as iApproved,
        NULL AS bCanBeApproved,
        NULL as iDraft,
        NULL as dtmPublish,
        NULL as dtmPublishUntil,
        dbo.fnSecurityGetPermission(136, 462, @iSecurityId, h.iHandbookId) as iAccess,
        h.iCreatedbyId,
        0 as iInternetDoc,
        NULL as iVersionStatus,
        h.iParentHandbookId,
        [dbo].[fn136_be_GetChildCount] (@iSecurityId, h.iHandbookId, @bShowDocumentsInTree) AS iChildCount,
        h.iDeleted,
        NULL AS dtmCreated,
        NULL AS dtmAlter,
        0 AS IsDocument,
        h.iHandbookId AS VirtualHandbookId,
        0 AS ReadCount
    FROM
        m136_tblHandbook as h
    WHERE
        (h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
        AND h.iDeleted = 0
	ORDER BY IsDocument, iSort, d.strName;
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetSecurityGroups]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetSecurityGroups]  AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JUNE 29, 2015
-- Description:	Get security groups
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetSecurityGroups]
	@UserId INT
AS
BEGIN
	SET NOCOUNT ON;
    SELECT DISTINCT sg.iSecGroupId
		   ,sg.strName
		   ,sg.strDescription 
	FROM [dbo].[tblSecGroup] sg
	LEFT JOIN [dbo].[relEmployeeSecGroup] esg ON esg.iSecGroupId = sg.iSecGroupId
	WHERE esg.iEmployeeId = @UserId OR @UserId IS NULL
	ORDER BY sg.strName;
END
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
			AND d.iApproved != 4
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

IF OBJECT_ID('[dbo].[m136_be_VerifyDeleteFolderPermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_VerifyDeleteFolderPermissions] AS SELECT 1')
GO
-- =============================================
-- Author:		SI.NGUYEN.MANH
-- Create date: OCT 27, 2015
-- Description:	Count number Folder and document recursive
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_VerifyDeleteFolderPermissions]
	@HandbookId INT = 0,
	@SecurityId INT = 0,
	@DeleteFolderPermission INT,
	@DeleteDocumentPermission INT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @returnPermission BIT = 1;
	
	DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	
		INSERT INTO @AvailableChildren(iHandbookId)
		SELECT 
			iHandbookId 
		FROM 
			[dbo].[m136_GetHandbookRecursive](@HandbookId, @SecurityId, 1);
	   
	   DECLARE @CountFolderRecursive AS INT
	   DECLARE @CountFolder AS INT
	   DECLARE @CountDocument AS INT
	   
	   SELECT @CountFolderRecursive = Count(iHandbookId)
	   FROM @AvailableChildren
	   
	   SELECT 
			@CountFolder = Count(iHandbookId)
		FROM 
			[dbo].[m136_GetHandbookRecursive](@HandbookId, @SecurityId, 1)
		where dbo.[fnSecurityGetPermission]( 136, 461, @SecurityId, iHandbookId) & @DeleteFolderPermission  = @DeleteFolderPermission
		
		SELECT 
			@CountDocument = Count(iHandbookId)
		FROM 
			[dbo].[m136_GetHandbookRecursive](@HandbookId, @SecurityId, 1)
		where dbo.[fnSecurityGetPermission]( 136, 462, @SecurityId, iHandbookId) & @DeleteDocumentPermission  = @DeleteDocumentPermission
		
		
		DECLARE @NumberSubFolder AS INT
		DECLARE @NumberDocument AS INT
		
		SELECT  @NumberDocument = COUNT(*)
		FROM (	
				SELECT DISTINCT 
					d.iDocumentId AS Id
				FROM 
					m136_tblDocument d
						JOIN m136_tblHandbook h 
							ON d.iHandbookId = h.iHandbookId
						JOIN @AvailableChildren ac
							ON d.iHandbookId = ac.iHandbookId
				WHERE
					d.iLatestVersion = 1
					AND d.iDeleted = 0
			UNION       
				SELECT 
					d.iDocumentId AS Id
				FROM 
					m136_relVirtualRelation virt 
						JOIN m136_tblDocument d
							ON virt.iDocumentId = d.iDocumentId AND d.iApproved != 4
						JOIN m136_tblHandbook h 
							ON d.iHandbookId = h.iHandbookId
						JOIN @AvailableChildren ac
							ON virt.iHandbookId = ac.iHandbookId
				WHERE
					d.iLatestVersion = 1
					AND d.iDeleted = 0) AS Document
					
		SELECT 
			@NumberSubFolder = COUNT(iHandbookId)
		FROM 
			[dbo].[m136_GetHandbookRecursive](@HandbookId, @SecurityId, 1)
		WHERE iHandbookId != @HandbookId
		
		IF @CountFolderRecursive = 0 OR @CountFolder != @CountFolderRecursive
			SET @returnPermission = 0;
			
		IF @NumberDocument <> 0 AND (@CountFolderRecursive = 0 OR @CountDocument != @CountFolderRecursive)
			SET @returnPermission = 0;
		
		SELECT @returnPermission
		
		SELECT @NumberDocument
		
		SELECT @NumberSubFolder
		
END
GO



