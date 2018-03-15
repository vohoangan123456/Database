INSERT INTO #Description VALUES ('Modify and add new SP for recursive department for folder')
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
        WHERE [NAME] = N'RecursiveDepartment' AND [OBJECT_ID] = OBJECT_ID(N'dbo.m136_tblHandbook'))
BEGIN
    ALTER TABLE dbo.m136_tblHandbook ADD RecursiveDepartment BIT NOT NULL DEFAULT 0
END
GO

IF OBJECT_ID('[dbo].[m136_be_InsertFolder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_InsertFolder] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_InsertFolder]
	@iUserId INT,
	@iParentHandbookId	INT,
    @strName			VARCHAR(100),
    @strDescription		VARCHAR(7000),
    @iDepartmentId		INT,
    @iLevelType			INT,
    @iViewTypeId		INT,
    @IncludeSubDepartments BIT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @iParentLevel INT = 0, @iMaxHandbookId INT = 0;
	SELECT @iParentLevel = h.iLevel FROM dbo.m136_tblHandbook h WHERE h.iHandbookId = @iParentHandbookId;
	SELECT @iMaxHandbookId = MAX(ihandbookid) FROM dbo.m136_tblHandbook;
	DECLARE @iNewHandbookId INT = ISNULL(@iMaxHandbookId, 0) + 1;
	SET IDENTITY_INSERT dbo.m136_tblHandbook ON;
    INSERT INTO dbo.m136_tblHandbook(
		iHandbookId,
		iParentHandbookId, 
		strName, 
		strDescription, 
		iDepartmentId, 
		iLevelType, 
		iViewTypeId, 
		dtmCreated, 
		iCreatedById, 
		iDeleted,
		iMin,
		iMax,
		iLevel,
		RecursiveDepartment) 
    VALUES(
		@iNewHandbookId,
		(CASE WHEN @iParentHandbookId = 0 THEN NULL ELSE @iParentHandbookId END), 
		@strName, 
		@strDescription, 
		@iDepartmentId, 
		@iLevelType, 
		(CASE WHEN @iViewTypeId = -1 THEN 1 WHEN @iViewTypeId = -2 THEN 3 END), 
		GETDATE(), 
		@iUserId, 
		0,
		0,
		0,
		(@iParentLevel + 1),
		@IncludeSubDepartments);
	SET IDENTITY_INSERT dbo.m136_tblHandbook OFF;
	DECLARE @iEntityId INT, @iApplicationId INT, @iSecurityId INT, @iPermisionSetId INT, @iGroupingId INT, @iBit INT
	DECLARE ACL CURSOR FOR 
		SELECT @iNewHandbookId
				, [iApplicationId]
				, iSecurityId
				, [iPermissionSetId]
				, [iGroupingId]
				, [iBit]
			FROM [dbo].[tblACL] 
			WHERE iEntityId = @iParentHandbookId 
				AND iApplicationId = 136
				AND (iPermissionSetId = 461 OR iPermissionSetId = 462);
	OPEN ACL; 
	FETCH NEXT FROM ACL INTO @iEntityId, @iApplicationId, @iSecurityId, @iPermisionSetId, @iGroupingId, @iBit;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF NOT EXISTS(SELECT * FROM dbo.tblACL WHERE iEntityId = @iEntityId 
			AND iApplicationId = @iApplicationId 
			AND iSecurityId = @iSecurityId 
			AND iPermissionSetId  = @iPermisionSetId)
		BEGIN
			INSERT INTO dbo.tblACL(iEntityId, iApplicationId, iSecurityId, iPermissionSetId, iGroupingId, iBit) VALUES (
			     @iEntityId
				, @iApplicationId
				, @iSecurityId
				, @iPermisionSetId
				, @iGroupingId
				, @iBit);
		END
		ELSE 
		BEGIN
			UPDATE dbo.tblACL
				SET iBit = @iBit,
					iGroupingId = @iGroupingId
			WHERE iEntityId = @iEntityId 
			AND iApplicationId = @iApplicationId 
			AND iSecurityId = @iSecurityId 
			AND iPermissionSetId  = @iPermisionSetId
		END
		FETCH NEXT FROM ACL INTO @iEntityId, @iApplicationId, @iSecurityId, @iPermisionSetId, @iGroupingId, @iBit;
	END
	CLOSE ACL;
	DEALLOCATE ACL;
    INSERT INTO dbo.CacheUpdate (ActionType, EntityId) VALUES (5, @iParentHandbookId);
	SELECT @iNewHandbookId;
END
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
        h.strName as FolderName,
		h.iParentHandbookId as ParentId,
		dbo.fn136_GetParentPathEx(@iHandbookId) as Path,
		h.iLevel as Level,
		h.iViewTypeId as ViewType,
		h.iLevelType as LevelType,
		h.iDepartmentId as DepartmentId,
		h.strDescription,
		[dbo].[fn136_be_GetChildCount] (@iSecurityId, h.iHandbookId, @bShowDocumentsInTree) AS iChildCount,
		RTRIM(ISNULL(e.strFirstName,'') + ' ' + ISNULL(e.strLastName,'')) AS FullNameCreatedBy,
		h.dtmCreated,
		h.RecursiveDepartment AS IncludeSubDepartments
    FROM
        m136_tblHandbook h
        LEFT JOIN dbo.tblEmployee e ON h.iCreatedById = e.iEmployeeId
	WHERE
        h.iHandbookId = @iHandbookId AND @iHandbookId IS NOT NULL;
        
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
        AND h.iHandbookId > 0
        AND h.iDeleted = 0
	ORDER BY IsDocument, iSort, d.strName;
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateFolderInformation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateFolderInformation] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_UpdateFolderInformation]
	 @FolderId INT,  
	 @ParentFolderId INT,  
	 @strName VARCHAR(100),  
	 @strDescription VARCHAR(700),  
	 @iDepartmentId INT,  
	 @iLevelType INT,  
	 @iViewType INT,  
	 @InheritNewParentPermissions BIT,  
	 @Recursive BIT,  
	 @OldParentFolderId INT,
	 @IncludeSubDepartments BIT
AS  
BEGIN  
    BEGIN TRY  
        BEGIN TRANSACTION;  
            SET NOCOUNT ON;  
            UPDATE [dbo].[m136_tblHandbook]   
            SET strName = @strName,  
                iParentHandbookId = (CASE WHEN @ParentFolderId = 0 THEN NULL ELSE @ParentFolderId END),  
                strDescription = @strDescription,  
                iDepartmentId = @iDepartmentId,  
                iLevelType = @iLevelType,  
                iViewTypeId = @iViewType,  
                iLevel = (CASE WHEN @ParentFolderId = 0 THEN 1 ELSE (SELECT  h.iLevel + 1 FROM dbo.m136_tblHandbook h WHERE h.iHandbookId = @ParentFolderId) END),
                RecursiveDepartment = @IncludeSubDepartments
            WHERE iHandbookId = @FolderId;  
            DECLARE @iHandbookId INT,  
                @iApplicationId INT,   
                @iSecurityId INT,   
                @iPermissionSetId INT,   
                @iGroupingId INT,   
                @iBit INT;  
            IF (@InheritNewParentPermissions = 1)  
            BEGIN  
                DECLARE @Permissions AS [dbo].[ACLDatatable];  
                INSERT INTO @Permissions  
                SELECT @FolderId   
                    , iApplicationId  
                    , iSecurityId  
                    , iPermissionSetId  
                    , iGroupingId  
                    , iBit  
                    , 1  
                FROM [dbo].[tblACL]   
                WHERE  
                    (  
                        (@ParentFolderId IS NULL AND iEntityId = 0)  
                        OR iEntityId = @ParentFolderId  
                    )  
                    AND iApplicationId = 136  
                    AND (iPermissionSetId = 461 OR iPermissionSetId = 462);  
                EXEC [dbo].[m136_be_UpdatePermissionsForFolder] @FolderId, @Recursive, @Permissions;  
                
            END  
            INSERT INTO CacheUpdate(ActionType, EntityId) VALUES (1, @FolderId);
        COMMIT TRANSACTION;  
    END TRY  
    BEGIN CATCH  
        ROLLBACK;  
    END CATCH  
END  
GO

IF OBJECT_ID('[dbo].[m136_GetChapterItems]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetChapterItems] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetChapterItems] 
	@iHandbookId INT = NULL,
	@iSecurityId INT,
	@bShowDocumentsInTree BIT
AS
SET NOCOUNT ON
BEGIN
    SELECT	
        h.iHandbookId AS Id,
        h.strName as FolderName,
        h.iParentHandbookId as ParentId,
        dbo.fn136_GetParentPathEx(@iHandbookId) as Path,
        h.iLevel as Level,
        h.iViewTypeId as ViewType,
        h.iLevelType as LevelType,
        h.iDepartmentId as DepartmentId,
        h.strDescription,
        RTRIM(ISNULL(e.strFirstName,'') + ' ' + ISNULL(e.strLastName,'')) AS FullNameCreatedBy,
		h.dtmCreated,
		h.RecursiveDepartment AS IncludeSubDepartments
    FROM
        m136_tblHandbook h
        LEFT JOIN dbo.tblEmployee e ON h.iCreatedById = e.iEmployeeId
    WHERE
        h.iHandbookId = @iHandbookId AND @iHandbookId IS NOT NULL;
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
        NULL as Path,
        [dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
        d.iApproved,
        d.iDraft,
        h.iParentHandbookId,
        0 AS iChildCount,
        1 AS IsDocument,
        d.iHandbookId AS VirtualHandbookId,
        d.iInternetDoc
    FROM
        m136_tblDocument d
            LEFT JOIN m136_tblHandbook h 
                ON h.iHandbookId = d.iHandbookId
    WHERE
        d.iHandbookId = @iHandbookId
        AND d.iLatestApproved = 1
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
        dbo.fn136_GetParentPathEx(h.iHandbookId) as Path,
        [dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
        d.iApproved,
        d.iDraft,
        h.iParentHandbookId,
        0 AS iChildCount,
        1 AS IsDocument,
        v.iHandbookId AS VirtualHandbookId,
        d.iInternetDoc
    FROM
        m136_relVirtualRelation v
            INNER JOIN m136_tblDocument d 
                ON d.iDocumentId = v.iDocumentId
            INNER JOIN m136_tblHandbook h
                ON d.iHandbookId = h.iHandbookId
    WHERE
        v.iHandbookId = @iHandbookId
        AND d.iLatestApproved = 1
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
        NULL as Path,
        0 as HasAttachment,
        NULL as iApproved,
        NULL as iDraft,
        h.iParentHandbookId,
        [dbo].[fn136_GetChildCount] (@iSecurityId, h.iHandbookId, @bShowDocumentsInTree) AS iChildCount,
        0 AS IsDocument,
        h.iHandbookId AS VirtualHandbookId,
        0 AS iInternetDoc
    FROM
        m136_tblHandbook as h
    WHERE
        (h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
        AND h.iDeleted = 0
	ORDER BY IsDocument, iSort, strName;
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetDepartmentsForFolders]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDepartmentsForFolders] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetDepartmentsForFolders]
	 @FolderIds  AS [dbo].[Item] READONLY
AS  
BEGIN

	 DECLARE @iHandbookId INT, @RecursiveDepartment BIT, @DepartmentId INT
	 DECLARE @ReturnTable TABLE(HandbookId INT, DepartmentId INT)
	 DECLARE cur CURSOR FOR SELECT
			 h.iHandbookId,
			 h.iDepartmentId,
			 h.RecursiveDepartment
			FROM dbo.m136_tblHandbook h
			WHERE h.iHandbookId IN (SELECT Id FROM @FolderIds)
				 AND h.iDepartmentId IS NOT NULL AND h.iDepartmentId <> 0
			
    OPEN cur;
    FETCH NEXT FROM cur INTO @iHandbookId, @DepartmentId, @RecursiveDepartment;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @RecursiveDepartment = 0 
        BEGIN
			INSERT INTO @ReturnTable
			VALUES(@iHandbookId, @DepartmentId)
        END
        ELSE
        BEGIN
			INSERT INTO @ReturnTable
			SELECT @iHandbookId, iDepartmentId
			FROM dbo.m136_GetDepartmentsRecursive(@DepartmentId)
        END
		FETCH NEXT FROM cur INTO @iHandbookId, @DepartmentId, @RecursiveDepartment;
    END
    CLOSE cur;
    DEALLOCATE cur;
    
    SELECT * FROM @ReturnTable
END  
GO


