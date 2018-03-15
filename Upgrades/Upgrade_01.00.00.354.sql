INSERT INTO #Description VALUES ('Modify procedures m136_GetChapterItems, m136_GetLatestApprovedSubscriptions, GetUserReadingDocumentsList, m136_GetRecentlyApprovedDocuments')
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
        iHandbookId AS Id,
        strName as FolderName,
        iParentHandbookId as ParentId,
        dbo.fn136_GetParentPathEx(@iHandbookId) as Path,
        iLevel as Level,
        iViewTypeId as ViewType,
        iLevelType as LevelType,
        iDepartmentId as DepartmentId,
        strDescription
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

IF OBJECT_ID('[dbo].[m136_GetLatestApprovedSubscriptions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetLatestApprovedSubscriptions]  AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetLatestApprovedSubscriptions]
	@iSecurityId INT = 0,
	@iApprovedDocumentCount INT = 0,
	@TreatDepartmentFoldersAsFavorites INT = 0
AS
SET NOCOUNT ON
BEGIN
	DECLARE @iUserDepId INT;
	SELECT @iUserDepId = iDepartmentId FROM tblEmployee WHERE iEmployeeId = @iSecurityId;
	DECLARE @PreviousLogin Datetime;
	SELECT @PreviousLogin = PreviousLogin FROM tblEmployee WHERE iEmployeeId = @iSecurityId;
	-- get list of handbookId which is favorite and have read access
	DECLARE @FavoriteHandbooksWithReadContents TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	INSERT INTO @FavoriteHandbooksWithReadContents(iHandbookId)
	SELECT 
		iHandbookId 
	FROM 
		[dbo].[m136_fnGetAllFavoritesFoldersWithContentsAccessRecursively](@iSecurityId, @TreatDepartmentFoldersAsFavorites, @iUserDepId);
	-- get list of favorite document
	WITH Documents AS
	(
		SELECT
			iDocumentId
		FROM
			m136_relVirtualRelation
		WHERE iHandbookId IN (SELECT DISTINCT iHandbookId 
							  FROM @FavoriteHandbooksWithReadContents)
		UNION
		SELECT
			iDocumentId
		FROM
			m136_tblSubscriberDocument
		WHERE 
			iEmployeeId = @iSecurityId
	)
	SELECT DISTINCT 
		TOP(@iApprovedDocumentCount) 
		d.iDocumentId AS Id, 
		d.iEntityId, 
		d.strName, 
        dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) AS iAccess, 
		d.iHandbookId, 
        d.dtmApproved, 
		h.strName AS ParentFolderName, 
		d.iVersion AS [Version], 
        d.iDocumentTypeId,
        d.iInternetDoc,
		dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
        (e.strLastName + ' ' + e.strFirstName) AS strApprovedBy, 
        dbo.fnOrgGetUserName(d.iCreatedById, '', 0) AS Responsible, 
		[dbo].[fnHasDocumentAttachment](d.iEntityId) AS HasAttachment,
		h.iLevelType AS LevelType,
		h.iDepartmentId AS DepartmentId,
        CASE WHEN 
			d.dtmApproved > @PreviousLogin THEN 1
		ELSE 0
		END AS IsNew
	FROM  
		m136_tblDocument d
		JOIN m136_tblHandbook h ON d.iHandbookId = h.iHandbookId
		LEFT JOIN tblEmployee e ON e.iEmployeeId = d.iApprovedById
	WHERE 
		d.iLatestApproved = 1
        AND d.iReceiptsCopied = 0
		AND (		(d.iHandbookId IN (SELECT iHandbookId FROM @FavoriteHandbooksWithReadContents))
				OR	d.iDocumentId IN (SELECT iDocumentId FROM Documents))
	ORDER BY d.dtmApproved DESC
END
GO

IF OBJECT_ID('[dbo].[GetUserReadingDocumentsList]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetUserReadingDocumentsList] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetUserReadingDocumentsList]
    @UserId INT
AS
BEGIN
    DECLARE @UserDepartmentId TABLE(Id INT);
    DECLARE @UserRoleId TABLE(Id INT);
    DECLARE @UserReadingDocumentsList TABLE
    (
        iDocumentId INT,
        iHandbookId INT,
        strName NVARCHAR(200),
        iDocumentTypeId INT,
        Version INT,
        dtmApproved DATETIME,
        strApprovedBy VARCHAR(200),
        Responsible VARCHAR(100),
        ParentFolderName VARCHAR(100),
        Path NVARCHAR(MAX),
        HasAttachment BIT,
        iReadingListId INT,
        ReadingListName NVARCHAR(100),
        IsConfirmed BIT,
        iInternetDoc INT
    );
    
    -- Insert reading documents from person readers
    INSERT INTO @UserReadingDocumentsList
        (iDocumentId, iHandbookId, strName, iDocumentTypeId, Version, dtmApproved, strApprovedBy, Responsible, ParentFolderName, Path, HasAttachment, iReadingListId, ReadingListName, IsConfirmed, iInternetDoc)
    SELECT
        d.iDocumentId,
        d.iHandbookId,
        d.strName,
        d.iDocumentTypeId,
        d.iVersion AS Version,
        d.dtmApproved,
        d.strApprovedBy,
        dbo.fnOrgGetUserName(d.iCreatedById, '', 0) AS Responsible,
        h.strName AS ParentFolderName,
        dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path,
        dbo.fnHasDocumentAttachment(d.iEntityId) AS HasAttachment,
        rl.ReadingListId,
        rl.Name,
        dbo.fnUserHasConfirmedDocument(@UserId, d.iEntityId),
        d.iInternetDoc
    FROM
        m136_tblDocument d
            INNER JOIN m136_tblhandbook h
                ON d.iHandbookId = h.iHandbookId
            INNER JOIN ReadingListDocuments rld
                ON d.iDocumentId = rld.DocumentId
            INNER JOIN ReadingListReaders rlr
                ON rld.ReadingListId = rlr.ReadingListId
            INNER JOIN ReadingList rl
                ON rld.ReadingListId = rl.ReadingListId
    WHERE
        d.iLatestApproved = 1
        AND ReaderTypeId = 1
        AND ReaderId = @UserId
        
    -- Insert reading documents from department readers
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        tblEmployee
    WHERE
        iEmployeeId = @UserId
        
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        relEmployeeDepartment
    WHERE
        iEmployeeId = @UserId
        
    INSERT INTO @UserReadingDocumentsList
        (iDocumentId, iHandbookId, strName, iDocumentTypeId, Version, dtmApproved, strApprovedBy, Responsible, ParentFolderName, Path, HasAttachment, iReadingListId, ReadingListName, IsConfirmed, iInternetDoc)
    SELECT
        d.iDocumentId,
        d.iHandbookId,
        d.strName,
        d.iDocumentTypeId,
        d.iVersion AS Version,
        d.dtmApproved,
        d.strApprovedBy,
        dbo.fnOrgGetUserName(d.iCreatedById, '', 0) AS Responsible,
        h.strName AS ParentFolderName,
        dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path,
        dbo.fnHasDocumentAttachment(d.iEntityId) AS HasAttachment,
        rl.ReadingListId,
        rl.Name,
        dbo.fnUserHasConfirmedDocument(@UserId, d.iEntityId),
        d.iInternetDoc
    FROM
        m136_tblDocument d
            INNER JOIN m136_tblhandbook h
                ON d.iHandbookId = h.iHandbookId
            INNER JOIN ReadingListDocuments rld
                ON d.iDocumentId = rld.DocumentId
            INNER JOIN ReadingListReaders rlr
                ON rld.ReadingListId = rlr.ReadingListId
            INNER JOIN ReadingList rl
                ON rld.ReadingListId = rl.ReadingListId
    WHERE
        d.iLatestApproved = 1
        AND ReaderTypeId = 2
        AND ReaderId IN (SELECT Id FROM @UserDepartmentId)
    
    -- Insert reading documents from role readers
    INSERT INTO @UserRoleId (Id)
    SELECT
        iSecGroupId
    FROM
        relEmployeeSecGroup
    WHERE
        iEmployeeId = @UserId
        
    INSERT INTO @UserReadingDocumentsList
        (iDocumentId, iHandbookId, strName, iDocumentTypeId, Version, dtmApproved, strApprovedBy, Responsible, ParentFolderName, Path, HasAttachment, iReadingListId, ReadingListName, IsConfirmed, iInternetDoc)
    SELECT
        d.iDocumentId,
        d.iHandbookId,
        d.strName,
        d.iDocumentTypeId,
        d.iVersion AS Version,
        d.dtmApproved,
        d.strApprovedBy,
        dbo.fnOrgGetUserName(d.iCreatedById, '', 0) AS Responsible,
        h.strName AS ParentFolderName,
        dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path,
        dbo.fnHasDocumentAttachment(d.iEntityId) AS HasAttachment,
        rl.ReadingListId,
        rl.Name,
        dbo.fnUserHasConfirmedDocument(@UserId, d.iEntityId),
        d.iInternetDoc
    FROM
        m136_tblDocument d
            INNER JOIN m136_tblhandbook h
                ON d.iHandbookId = h.iHandbookId
            INNER JOIN ReadingListDocuments rld
                ON d.iDocumentId = rld.DocumentId
            INNER JOIN ReadingListReaders rlr
                ON rld.ReadingListId = rlr.ReadingListId
            INNER JOIN ReadingList rl
                ON rld.ReadingListId = rl.ReadingListId
    WHERE
        d.iLatestApproved = 1
        AND ReaderTypeId = 3
        AND ReaderId IN (SELECT Id FROM @UserRoleId)    
    
    -- get final reading documents
    
    SELECT
        DISTINCT(iDocumentId) AS Id,
        iHandbookId,
        strName,
        iDocumentTypeId,
        Version,
        dtmApproved,
        strApprovedBy,
        Responsible,
        ParentFolderName,
        Path,
        HasAttachment,
        iReadingListId,
        ReadingListName,
        IsConfirmed,
        iInternetDoc
    FROM
        @UserReadingDocumentsList
END
GO

IF OBJECT_ID('[dbo].[m136_GetRecentlyApprovedDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetRecentlyApprovedDocuments]  AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetRecentlyApprovedDocuments] 
	@iDaysLimit int,
	@maxCount int
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @Now DATETIME = GETDATE();
	SELECT TOP (@maxCount)
		d.iDocumentId as Id,
		d.iHandbookId,
		d.strName,
		d.iDocumentTypeId,
		d.iVersion as [Version],
		d.dtmApproved,
		d.strApprovedBy,
		dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
		h.strName as ParentFolderName,
		dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
		[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
		h.iLevelType AS LevelType,
		h.iDepartmentId As DepartmentId,
        d.iInternetDoc
	FROM
		m136_tblDocument d
        INNER JOIN m136_tblHandbook h 
			ON d.iHandbookId = h.iHandbookId
   	WHERE 
        d.iLatestApproved = 1
        AND d.iReceiptsCopied = 0
        AND DATEDIFF(d, ISNULL(d.dtmApproved, CONVERT(DATETIME, '01.01.1970', 104)), @Now) <  @iDaysLimit
	ORDER BY
		d.dtmApproved DESC
END
GO
