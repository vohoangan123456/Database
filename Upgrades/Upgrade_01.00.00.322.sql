INSERT INTO #Description VALUES ('Create table ReadingListExclusions, modify procedures m136_be_GetChapterItems, m136_GetChapterItems, be_GetReadingListDetailsById, be_UpdateReadingList')
GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES  WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'ReadingListExclusions'))
BEGIN
    CREATE TABLE [dbo].[ReadingListExclusions]
    (
        ReadingListExclusionId INT IDENTITY(1, 1) PRIMARY KEY,
        ReadingListId INT NOT NULL,
        DepartmentId INT NOT NULL,
        EmployeeId INT NOT NULL
	)
END
GO

DECLARE @sql1 NVARCHAR(MAX)
SET @sql1 = dbo.fn136_GetSqlDropConstraintKey('ReadingListExclusions', 'FK_ReadingListExclusions_ReadingList') 
IF @sql1 IS NOT NULL
BEGIN
    EXEC(@sql1)
END
GO

ALTER TABLE [dbo].[ReadingListExclusions] ADD CONSTRAINT FK_ReadingListExclusions_ReadingList FOREIGN KEY (ReadingListId)
    REFERENCES [dbo].[ReadingList] (ReadingListId)
GO

DECLARE @sql2 NVARCHAR(MAX)
SET @sql2 = dbo.fn136_GetSqlDropConstraintKey('ReadingListExclusions', 'FK_ReadingListExclusions_Department') 
IF @sql2 IS NOT NULL
BEGIN
    EXEC(@sql2)
END
GO

ALTER TABLE [dbo].[ReadingListExclusions] ADD CONSTRAINT FK_ReadingListExclusions_Department FOREIGN KEY (DepartmentId)
    REFERENCES [dbo].[tblDepartment] (iDepartmentId)
GO

DECLARE @sql3 NVARCHAR(MAX)
SET @sql3 = dbo.fn136_GetSqlDropConstraintKey('ReadingListExclusions', 'FK_ReadingListExclusions_Employee') 
IF @sql3 IS NOT NULL
BEGIN
    EXEC(@sql3)
END
GO

ALTER TABLE [dbo].[ReadingListExclusions] ADD CONSTRAINT FK_ReadingListExclusions_Employee FOREIGN KEY (EmployeeId)
    REFERENCES [dbo].[tblEmployee] (iEmployeeId)
GO

IF  NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'ReadingListExclusionsItems' AND ss.name = N'dbo')
    CREATE TYPE [dbo].[ReadingListExclusionsItems] AS TABLE
    (
        ReadingListId INT,
        DepartmentId SMALLINT,
        EmployeeId INT
    )
GO

-- Modify procedures

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
        AND d.iLatestVersion = 1 AND d.iDeleted = 0
        
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
        AND h.iDeleted = 0
	ORDER BY IsDocument, iSort, d.strName;
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
        d.iHandbookId AS VirtualHandbookId
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
        v.iHandbookId AS VirtualHandbookId
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
        h.iHandbookId AS VirtualHandbookId
    FROM
        m136_tblHandbook as h
    WHERE
        (h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
        AND h.iDeleted = 0
	ORDER BY IsDocument, iSort, strName;
END
GO

IF OBJECT_ID('[dbo].[be_GetReadingListDetailsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[be_GetReadingListDetailsById] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[be_GetReadingListDetailsById]
    @Id INT
AS
BEGIN
    SELECT
        ReadingListId,
        Name,
        Description,
        IsInactive
    FROM
        ReadingList
    WHERE
        ReadingListId = @Id
        
    SELECT
        rld.ReadingListDocumentId,
        rld.ReadingListId,
        rld.DocumentId,
        d.strName AS DocumentName,
        dbo.fn136_GetParentPathEx(d.iHandbookId) AS DocumentPath
    FROM
        ReadingListDocuments rld
            JOIN m136_tblDocument d ON rld.DocumentId = d.iDocumentId
    WHERE
        d.iLatestVersion = 1
        AND ReadingListId = @Id
    
    SELECT
        ReadingListReaderId,
        ReadingListId,
        ReaderTypeId,
        CASE
            WHEN ReaderTypeId = 1 THEN (SELECT strFirstName + ' ' + strLastName FROM tblEmployee WHERE iEmployeeId = ReaderId)
            WHEN ReaderTypeId = 2 THEN (SELECT strName FROM tblDepartment WHERE iDepartmentId = ReaderId)
            WHEN ReaderTypeId = 3 THEN (SELECT strName FROM tblSecGroup WHERE iSecGroupId = ReaderId)
        END AS ReaderName,
        ReaderId
    FROM
        ReadingListReaders
    WHERE
        ReadingListId = @Id
        
    SELECT
        ReadingListExclusionId,
        ReadingListId,
        DepartmentId,
        d.strName AS DepartmentName,
        EmployeeId,
        e.strFirstName + ' ' + e.strLastName AS EmployeeName
    FROM
        ReadingListExclusions rle
            INNER JOIN tblDepartment d ON rle.DepartmentId = d.iDepartmentId
            INNER JOIN tblEmployee e ON rle.EmployeeId = e.iEmployeeId
END
GO

IF OBJECT_ID('[dbo].[be_UpdateReadingList]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[be_UpdateReadingList] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[be_UpdateReadingList]
    @ReadingListId INT,
    @Name NVARCHAR(100),
    @IsInactive BIT,
    @Description NVARCHAR(4000),
    @Documents AS dbo.ReadingListDocumentItems READONLY,
    @Readers AS dbo.ReadingListReaderItems READONLY,
    @Exclusions AS dbo.ReadingListExclusionsItems READONLY
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        -- Update Reading List
        UPDATE
            ReadingList
        SET
            Name = @Name,
            IsInActive = @IsInactive,
            Description = @Description
        WHERE
            ReadingListId = @ReadingListId
            
        -- Delete and re-insert Reading List Documents
        DELETE FROM
            ReadingListDocuments
        WHERE
            ReadingListId = @ReadingListId
        
        INSERT INTO
            ReadingListDocuments
                (ReadingListId, DocumentId)
            SELECT
                @ReadingListId,
                DocumentId
            FROM
                @Documents
                
        -- Delete and re-insert Reading List Readers
        DELETE FROM
            ReadingListReaders
        WHERE
            ReadingListId = @ReadingListId
        
        INSERT INTO
            ReadingListReaders
                (ReadingListId, ReaderTypeId, ReaderId)
            SELECT
                @ReadingListId,
                ReaderTypeId,
                ReaderId
            FROM
                @Readers
        -- Delete and re-insert Reading List Exclusions
        DELETE FROM
            ReadingListExclusions
        WHERE
            ReadingListId = @ReadingListId
        
        INSERT INTO
            ReadingListExclusions
                (ReadingListId, DepartmentId, EmployeeId)
            SELECT
                @ReadingListId,
                DepartmentId,
                EmployeeId
            FROM
                @Exclusions
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    Rollback
END CATCH
END
GO