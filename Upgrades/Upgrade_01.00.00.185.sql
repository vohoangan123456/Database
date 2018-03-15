INSERT INTO #Description VALUES('Create types, procedures to support for feature Tag metadata to Chapter, Document')
GO

IF  NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'LinkDocumentRegisterItemValues' AND ss.name = N'dbo')
    CREATE TYPE [dbo].[LinkDocumentRegisterItemValues] AS TABLE
    (
        RegisterItemId INT,
        DocumentId INT,
        RegisterItemValueId INT
    )
GO

IF OBJECT_ID('[dbo].[m136_GetInheritedMetadataOfChapter]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetInheritedMetadataOfChapter] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetInheritedMetadataOfChapter]
	@UserId INT,
	@HandbookId INT
AS
BEGIN
	SELECT
        distinct(ric.iRegisterItemId),
		r.iRegisterId,
		r.strName AS strRegisterName,
		ri.strName,
		h.strName AS strChapterName
	FROM
		m147_relRegisterItemCategory AS ric
			INNER JOIN m136_tblHandbook AS h ON ric.iCategoryId = h.iHandbookId
			INNER JOIN m147_tblRegisterItem ri ON ric.iRegisterItemId = ri.iRegisterItemId
			INNER JOIN m147_tblRegister r ON ri.iRegisterId = r.iRegisterId
	WHERE
		ric.iModuleId = 136
		AND ric.iInheritTypeId IN (1, 2, 3, 5)
		AND ric.iCategoryId IN (SELECT
									iHandbookId
								FROM
									dbo.m136_GetParentIdsInTbl(@HandbookId) AS m136_GetParentIdsInTbl_1)
		AND dbo.fnSecurityGetPermission(147, 571, @UserId, r.iRegisterId) & 0x01 = 0x01
	ORDER BY
		iRegisterId, iRegisterItemId, strChapterName
		
END
GO

IF OBJECT_ID('[dbo].[m136_GetMetadataOfChapter]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetMetadataOfChapter] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetMetadataOfChapter]
	@UserId INT,
	@HandbookId INT
AS
BEGIN
	SELECT
        DISTINCT(ric.iRegisterItemId),
		r.iRegisterId,
		r.strName AS strRegisterName,
		ri.strName AS strName,
		dbo.fnSecurityGetPermission(147, 571, @UserId, r.iRegisterId) AS iAccess
	FROM
		m147_relRegisterItemCategory ric
			INNER JOIN m147_tblRegisterItem ri ON ric.iRegisterItemId = ri.iRegisterItemId
			INNER JOIN m147_tblRegister r ON ri.iRegisterId = r.iRegisterId
	WHERE
		iModuleId = 136
		AND iCategoryId = @HandbookId
		AND ric.iInheritTypeId IN (1, 2, 3, 5)
		AND dbo.fnSecurityGetPermission(147, 571, @UserId, r.iRegisterId) & 0x01 = 0x01
	ORDER BY
		iRegisterId, iRegisterItemId
END
GO

IF OBJECT_ID('[dbo].[m147_GetMetaRegistersByUserId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_GetMetaRegistersByUserId] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m147_GetMetaRegistersByUserId]
    @UserId INT
AS
BEGIN
    SELECT
        iRegisterId,
        strName
    FROM
        m147_tblRegister
    WHERE
        (dbo.fnSecurityGetPermission(147, 571, @UserId, iRegisterId) & 0x02) = 0x02
        AND bObsolete = 0
        AND bKladd = 0
END
GO

IF OBJECT_ID('[dbo].[m147_GetRegisterItemsByTypeAllowMultipleNotInHandbook]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_GetRegisterItemsByTypeAllowMultipleNotInHandbook] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m147_GetRegisterItemsByTypeAllowMultipleNotInHandbook]
	@ChapterId INT,
    @TypeId INT,
    @AllowMultiple BIT
AS
BEGIN
    SELECT
        ri.iRegisterItemId,
        ri.iRegisterId,
        ri.strName
    FROM
        m147_tblRegisterItem ri
    WHERE
        eTypeId = @TypeId
        AND bAllowMultiple = @AllowMultiple
        AND (
			iRegisterItemId NOT IN (SELECT iRegisterItemId FROM m147_relRegisterItemCategory)
			OR NOT EXISTS (SELECT 1 FROM m147_relRegisterItemCategory
						  WHERE iRegisterItemId = ri.iRegisterItemId AND iCategoryId = @ChapterId))
END
GO

IF OBJECT_ID('[dbo].[m147_LinkHandbookToRegisterItem]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_LinkHandbookToRegisterItem] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m147_LinkHandbookToRegisterItem]
	@ChapterId INT,
    @RegisterItemId INT
AS
BEGIN
    INSERT INTO
        m147_relRegisterItemCategory
            (iRegisterItemId, iModuleId, iCategoryId, iInheritTypeId)
        VALUES
            (@RegisterItemId, 136, @ChapterId, 2)
END
GO

IF OBJECT_ID('[dbo].[m147_DeleteHandbookRegisterItem]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_DeleteHandbookRegisterItem] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m147_DeleteHandbookRegisterItem]
	@ChapterId INT,
    @RegisterItemIds AS [dbo].[Item] READONLY
AS
BEGIN
    DELETE
        FROM m147_relRegisterItemCategory
    WHERE
        iCategoryId = @ChapterId
        AND iRegisterItemId IN (SELECT Id FROM @RegisterItemIds)
END
GO

IF OBJECT_ID('[dbo].[m147_be_GetRegisterItemValuesForDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_GetRegisterItemValuesForDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m147_be_GetRegisterItemValuesForDocument]
    @UserId INT,
	@DocumentId INT
AS
BEGIN
    
    SELECT
        rri.iAutoId AS iRegisterItemItemId, rri.iItemId AS DocumentId, r.iRegisterId, r.strName AS strRegisterName,
        ri.iRegisterItemId, ri.strName AS strRegisterItemName, riv.iRegisterItemValueId,
        riv.RegisterValue
    FROM
        m147_tblRegister r
            INNER JOIN m147_tblRegisterItem ri ON r.iRegisterId = ri.iRegisterId
            INNER JOIN m147_relRegisterItemItem rri ON rri.iRegisterItemId = ri.iRegisterItemId
            INNER JOIN m147_tblRegisterItemValue riv ON rri.iRegisterItemValueId = riv.iRegisterItemValueId
                AND riv.iRegisterItemId = ri.iRegisterItemId
    WHERE
        rri.iItemId = @DocumentId
        AND dbo.fnSecurityGetPermission(147, 571, @UserId, r.iRegisterId) & 0x01 = 0x01
    
END
GO

IF OBJECT_ID('[dbo].[m147_be_GetRegisterRegisterItemForDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_GetRegisterRegisterItemForDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m147_be_GetRegisterRegisterItemForDocument]
    @UserId INT,
    @DocumentId INT
AS
BEGIN
    
    DECLARE @HandbookId INT;
    
    SET @HandbookId = (SELECT TOP 1 iHandbookId FROM m136_tblDocument WHERE iDocumentId = @DocumentId);
    
    SELECT
        r.strName + ' - ' + ri.strName AS strRegisterRegisterName,
        r.iRegisterId,
        ric.iRegisterItemId
    FROM
        m147_relRegisterItemCategory ric
            INNER JOIN m147_tblRegisterItem ri ON ric.iRegisterItemId = ri.iRegisterItemId
            INNER JOIN m147_tblRegister r ON ri.iRegisterId = r.iRegisterId
    WHERE
        ric.iModuleId = 136
        AND ric.iInheritTypeId IN (1, 2, 3, 5)
        AND ric.iCategoryId IN (SELECT iHandbookId
                                FROM dbo.m136_GetParentidsInTbl(@HandbookId))
        AND dbo.fnSecurityGetPermission(147, 571, @UserId, r.iRegisterId) & 0x01 = 0x01
    
    UNION
    
    SELECT
        r.strName + ' - ' + ri.strname,
        r.iRegisterId,
        ric.iRegisterItemId
    FROM
        m147_relRegisterItemCategory ric
            INNER JOIN m147_tblRegisterItem ri ON ric.iRegisterItemId = ri.iRegisterItemId
            INNER JOIN m147_tblRegister r ON ri.iRegisterId = r.iRegisterId
    WHERE
        iModuleId = 136
        AND iCategoryId = @HandbookId
        AND ric.iInheritTypeId IN (1, 2, 3, 5)
        AND dbo.fnSecurityGetPermission(147, 571, @UserId, r.iRegisterId) & 0x01 = 0x01
    
END
GO

IF OBJECT_ID('[dbo].[m147_be_GetDocumentRegisterItemValues]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_GetDocumentRegisterItemValues] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m147_be_GetDocumentRegisterItemValues]
    @DocumentId INT
AS
BEGIN
    
    SELECT
        riv.iRegisterItemValueId,
        riv.iRegisterItemId,
        riv.RegisterValue,
        CASE
            WHEN EXISTS (SELECT 1 
                         FROM m147_relRegisterItemItem
                         WHERE
                            iItemId = @DocumentId
                            AND iRegisterItemValueId = riv.iRegisterItemValueId
                            AND iRegisterItemId = riv.iRegisterItemId) THEN 1
            ELSE 0
        END AS IsTagged
    FROM
        m147_tblRegisterItemValue riv
    
END
GO

IF OBJECT_ID('[dbo].[m147_be_LinkDocumentToRegisterItemValues]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_LinkDocumentToRegisterItemValues] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m147_be_LinkDocumentToRegisterItemValues]
    @ItemValues AS [dbo].[LinkDocumentRegisterItemValues] READONLY
AS
BEGIN
    
BEGIN TRY
    BEGIN TRANSACTION;
        DELETE FROM
            m147_relRegisterItemItem
        WHERE
            iItemId IN (SELECT DocumentId FROM @ItemValues)
            
        INSERT INTO
            m147_relRegisterItemItem
                (iRegisterItemId, iModuleId, iCategoryId, iItemId, iRegisterItemValueId)
            SELECT
                RegisterItemId,
                136,
                0,
                DocumentId,
                RegisterItemValueId
            FROM
                @ItemValues
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK;
END CATCH
    
END
GO

IF OBJECT_ID('[dbo].[m147_be_UntagDocumentRegisterItemValues]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_UntagDocumentRegisterItemValues] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m147_be_UntagDocumentRegisterItemValues]
    @RegisterItemItemIds AS [dbo].[Item] READONLY
AS
BEGIN
    
    DELETE FROM
        m147_relRegisterItemItem
    WHERE
        iAutoId IN (SELECT Id FROM @RegisterItemItemIds)
    
END
GO