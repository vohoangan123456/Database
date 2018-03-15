INSERT INTO #Description VALUES ('Create SP for add metadata for module')
GO

IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[m147_RegisterApplications]') AND type in (N'U'))
	CREATE TABLE [m147_RegisterApplications](
	[Id] [INT] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[RegisterId] [INT] NOT NULL,
	[ApplicationId] [INT] NOT NULL,
 CONSTRAINT [PK_m147_RegisterApplications] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

INSERT INTO [m147_RegisterApplications](RegisterId , ApplicationId)
SELECT iRegisterId, 136
FROM dbo.m147_tblRegister
WHERE iRegisterId NOT IN (SELECT RegisterId FROM m147_RegisterApplications)
GO

IF OBJECT_ID('[dbo].[m147_be_AddMetaRegister]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_AddMetaRegister] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_be_AddMetaRegister]
(
	@Name varchar(300),
	@Draft bit,
	@Obsolete bit,
	@Modules dbo.Item READONLY
)
AS
BEGIN
		DECLARE @Id INT
		INSERT INTO m147_tblRegister (strName, bObsolete, bKladd) VALUES (@Name, @Obsolete, @Draft)
		SELECT @Id = cast(@@identity AS int)
		
		INSERT INTO dbo.m147_RegisterApplications (RegisterId,ApplicationId)
		SELECT @Id, Value
		FROM @Modules
		
		SELECT @Id AS nyid
END
GO

IF OBJECT_ID('[dbo].[m147_spGetRegister]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_spGetRegister] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_spGetRegister]
(
	@iSecurityId INT,
	@iRegisterId INT = 0
)
AS
BEGIN
	IF @iRegisterId = 0
		BEGIN
			SELECT * 
			FROM m147_tblRegister 
			WHERE (dbo.fnSecurityGetPermission(147, 571, @iSecurityId, iRegisterId) & 1) = 1
		END
	ELSE
		BEGIN
			SELECT a.* , 
			CASE WHEN EXISTS (SELECT Id FROM dbo.m147_RegisterApplications WHERE RegisterId = @iRegisterId AND ApplicationId = 136) then 1 else 0 end as Ehandbook,
			CASE WHEN EXISTS (SELECT Id FROM dbo.m147_RegisterApplications WHERE RegisterId = @iRegisterId AND ApplicationId = 151) then 1 else 0 end as Deviation,
			CASE WHEN EXISTS (SELECT Id FROM dbo.m147_RegisterApplications WHERE RegisterId = @iRegisterId AND ApplicationId = 170) then 1 else 0 end as Risk
			FROM m147_tblRegister a 
			WHERE a.iRegisterId = @iRegisterId
				  AND (dbo.fnSecurityGetPermission(147, 571, @iSecurityId, @iRegisterId) & 1) = 1
		END
END
GO

IF OBJECT_ID('[dbo].[m147_be_UpdateMetaRegister]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_UpdateMetaRegister] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_be_UpdateMetaRegister]
(
	@RegisterId INT,
	@Name VARCHAR(300),
	@Draft BIT,
	@Obsolete BIT,
	@Modules dbo.Item READONLY
)
AS
BEGIN
		UPDATE m147_tblRegister 
		SET strName = @Name, bObsolete = @Obsolete, bKladd = @Draft 
		WHERE iRegisterId = @RegisterId
		
		DELETE dbo.m147_RegisterApplications 
		WHERE RegisterId = @RegisterId
		
		INSERT INTO dbo.m147_RegisterApplications (RegisterId,ApplicationId)
		SELECT @RegisterId, Value
		FROM @Modules
END
GO

IF OBJECT_ID('[dbo].[m147_spDeleteRegister]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_spDeleteRegister] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_spDeleteRegister]
(
	@iSecurityId INT,
	@iRegisterId INT
)
AS
BEGIN
	DECLARE @iAccess INT
	SELECT @iAccess = dbo.fnSecurityGetPermission(147, 571, @iSecurityId, @iRegisterId)
	IF (@iAccess & 8) = 8 or (@iAccess & 16) = 16
		BEGIN
			DELETE FROM m147_tblSynonym 
				   WHERE iRegisterItemValueId in (SELECT DISTINCT iRegisterItemValueId 
												  FROM m147_tblRegisterItemValue 
												  WHERE iRegisterItemId in (SELECT DISTINCT iRegisterItemId 
																			FROM m147_tblRegisterItem 
																			WHERE iRegisterId = @iRegisterId))
			DELETE FROM m147_relRegisterItemCategory 
				   WHERE iRegisterItemId in (SELECT DISTINCT iRegisterItemId 
											 FROM m147_tblRegisterItem 
											 WHERE iRegisterId = @iRegisterId)
			DELETE FROM m147_relRegisterItemItem 
				   WHERE iRegisterItemId in (SELECT DISTINCT iRegisterItemId 
											 FROM m147_tblRegisterItem 
											 WHERE iRegisterId = @iRegisterId)
			DELETE FROM m147_tblRegisterItemValue 
				   WHERE iRegisterItemId in (SELECT DISTINCT iRegisterItemId 
											 FROM m147_tblRegisterItem 
											 WHERE iRegisterId = @iRegisterId)
			DELETE FROM m147_tblRegisterItem 
				   WHERE iRegisterId = @iRegisterId
			DELETE FROM m147_tblRegister 
				   WHERE iRegisterId = @iRegisterId
			
			DELETE dbo.m147_RegisterApplications
					WHERE RegisterId = @iRegisterId
		END
END
GO

IF OBJECT_ID('[dbo].[m147_GetMetaRegistersByUserId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_GetMetaRegistersByUserId] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_GetMetaRegistersByUserId]
    @UserId INT,
    @Module INT
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
        AND iRegisterId IN (SELECT RegisterId From dbo.m147_RegisterApplications WHERE ApplicationId = @Module)
END
GO

IF OBJECT_ID('[dbo].[m147_GetRegisterItemsByTypeAllowMultipleNotInModule]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_GetRegisterItemsByTypeAllowMultipleNotInModule] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_GetRegisterItemsByTypeAllowMultipleNotInModule]
	@Id INT,
    @TypeId INT,
    @AllowMultiple BIT, 
	@Module INT
AS
BEGIN
    SELECT
        ri.iRegisterItemId,
        ri.iRegisterId,
        ri.strName
    FROM
        m147_tblRegisterItem ri
        JOIN dbo.m147_RegisterApplications a ON a.RegisterId = ri.iRegisterId AND a.ApplicationId = @Module
    WHERE
        eTypeId = @TypeId
        AND bAllowMultiple = @AllowMultiple
        AND (
			iRegisterItemId NOT IN (SELECT iRegisterItemId FROM m147_relRegisterItemCategory WHERE iModuleId = @Module)
			OR NOT EXISTS (SELECT 1 FROM m147_relRegisterItemCategory
						  WHERE iRegisterItemId = ri.iRegisterItemId AND iCategoryId = @Id AND iModuleId = @Module))
END
GO

IF OBJECT_ID('[dbo].[m147_be_GetRegisterItemValuesForModule]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_GetRegisterItemValuesForModule] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_be_GetRegisterItemValuesForModule]
    @UserId INT,
	@Id INT,
	@Module INT
AS
BEGIN
    SELECT
        rri.iAutoId AS iRegisterItemItemId, rri.iItemId AS DocumentId, r.iRegisterId, r.strName AS strRegisterName,
        ri.iRegisterItemId, ri.strName AS strRegisterItemName, riv.iRegisterItemValueId,
        riv.RegisterValue
    FROM
        m147_tblRegister r
			INNER JOIN dbo.m147_RegisterApplications a ON a.RegisterId = r.iRegisterId AND a.ApplicationId = @Module
            INNER JOIN m147_tblRegisterItem ri ON r.iRegisterId = ri.iRegisterId
            INNER JOIN m147_relRegisterItemItem rri ON rri.iRegisterItemId = ri.iRegisterItemId
            INNER JOIN m147_tblRegisterItemValue riv ON rri.iRegisterItemValueId = riv.iRegisterItemValueId
                AND riv.iRegisterItemId = ri.iRegisterItemId
    WHERE
        rri.iItemId = @Id
        AND dbo.fnSecurityGetPermission(147, 571, @UserId, r.iRegisterId) & 0x01 = 0x01
END
GO

IF OBJECT_ID('[dbo].[m147_be_GetRegisterItemValuesByModule]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_GetRegisterItemValuesByModule] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_be_GetRegisterItemValuesByModule]
    @Id INT,
    @Module INT
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
                            iItemId = @Id
                            AND iRegisterItemValueId = riv.iRegisterItemValueId
                            AND iRegisterItemId = riv.iRegisterItemId
                            AND iModuleId = @Module) THEN 1
            ELSE 0
        END AS IsTagged
    FROM
        m147_tblRegisterItemValue riv
        JOIN dbo.m147_tblRegisterItem item ON item.iRegisterItemId = riv.iRegisterItemId
        JOIN dbo.m147_RegisterApplications a ON a.RegisterId = item.iRegisterId AND a.ApplicationId = @Module
    ORDER BY iSort
END
GO

IF OBJECT_ID('[dbo].[m147_GetRegisterAndRegisterItems]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_GetRegisterAndRegisterItems] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m147_GetRegisterAndRegisterItems]
(
	@iSecurityId INT,
	@Module INT
)
AS
BEGIN

	SELECT a.iRegisterItemId,a.iRegisterItemParentId, a.iRegisterId,
		r.strName + ' : ' + a.strName AS strName, a.strDescription, a.eTypeId, a.bMandatory, a.bAllowMultiple,
		b.strName AS strEtype 
	FROM dbo.m147_tblRegister r
	INNER JOIN m147_tblRegisterItem a ON r.iRegisterId = a.iRegisterId
	INNER JOIN m147_tblEtype b ON a.eTypeId = b.eTypeId
	INNER JOIN dbo.m147_RegisterApplications ap ON ap.RegisterId = r.iRegisterId AND ap.ApplicationId = @Module
	WHERE a.iRegisterItemId IS NOT NULL
	 AND (dbo.fnSecurityGetPermission(147, 571, @iSecurityId, a.iRegisterId) & 1) = 1
	 
END
GO

IF OBJECT_ID('[dbo].[m136_be_EndHearingDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_EndHearingDocument] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_EndHearingDocument] 
	@EntityId INT
AS
BEGIN
	DECLARE @HearingId AS INT
	SELECT @HearingId = Id
	FROM dbo.m136_Hearings
	WHERE EntityId = @EntityId
		  AND IsActive = 1
	
	UPDATE dbo.m136_Hearings 
	SET IsActive = 0
	WHERE Id = @HearingId
	
	UPDATE dbo.m136_tblDocument
	SET iApproved = 0, iStatus = 0
	WHERE iEntityId = @EntityId
END
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentData]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentData] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetDocumentData]
(
	@SecurityId INT,
	@DocumentId INT
)
AS
BEGIN
	DECLARE @EntityId INT,
		@DocumentTypeId INT
	DECLARE @Document TABLE
	(
		EntityId INT NOT NULL,
		DocumentId INT NULL,
		[Version] INT NOT NULL,
		DocumentTypeId INT NOT NULL,
		HandbookId INT NOT NULL,
		Name VARCHAR(200) NOT NULL,
		[Description] VARCHAR(2000) NOT NULL,
		CreatedbyId INT NOT NULL,
		CreatedDate DATETIME NOT NULL,
		Author VARCHAR(200) NOT NULL,
		ApprovedById INT NOT NULL,
		ApprovedDate DATETIME NULL,
		ApprovedBy VARCHAR(200) NOT NULL,
		Sort int,
		UrlOrFileName NVARCHAR(4000) NULL,
		Type INT NULL,
		LevelType int
	)
	INSERT INTO @Document
	EXEC [dbo].[m136_GetLatestDocumentById] @SecurityId, @DocumentId
	SELECT @EntityId = EntityId,
		@DocumentTypeId = DocumentTypeId
	FROM @Document
	--Get Document Content

	DECLARE @DocumentContent TABLE
	(
		InfoTypeId INT NOT NULL,
		FieldName varchar(100) NOT NULL,
		FieldDescription varchar(4000) NOT NULL,
		InfoId INT NOT NULL,
		NumberValue INT NULL,
		DateValue datetime NULL,
		TextValue VARCHAR(8000) NULL,
		RichTextValue ntext NOT NULL,
		FieldId int NOT NULL,
		FieldProcessType int NOT NULL,
		Maximized INT NOT NULL
	)

	INSERT INTO @DocumentContent
	SELECT	InfoTypeId = mi.iInfoTypeId, 
			FieldName = mi.strName, 
			FieldDescription = mi.strDescription,
			InfoId = COALESCE (mit.iMetaInfoTextId, mid.iMetaInfoDateId, mii.iMetaInfoNumberId, mir.iMetaInfoRichTextId),
			NumberValue = mii.value, 
			DateValue = mid.value, 
			TextValue = mit.value, 
			RichTextValue = mir.value,                            
			FieldId = mi.iMetaInfoTemplateRecordsId, 
			FieldProcessType = mi.iFieldProcessType, 
			Maximized = rdi.iMaximized
	FROM [dbo].m136_tblMetaInfoTemplateRecords mi
		 JOIN [dbo].m136_relDocumentTypeInfo rdi 
			ON rdi.iDocumentTypeId = @DocumentTypeId 
			   AND rdi.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoDate mid 
			ON mid.iEntityId = @EntityId 
			   AND mid.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoNumber mii 
			ON mii.iEntityId = @EntityId 
			   AND mii.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoText mit 
			ON mit.iEntityId = @EntityId 
			   AND mit.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoRichText mir 
			ON mir.iEntityId = @EntityId 
			   AND mir.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
	WHERE rdi.iDeleted = 0 
	ORDER BY rdi.iSort

	DELETE FROM @DocumentContent WHERE InfoTypeId = 1 AND NumberValue is NULL
	DELETE FROM @DocumentContent WHERE InfoTypeId in (2,3,4) AND (TextValue is NULL OR DATALENGTH(TextValue)=0)
	DELETE FROM @DocumentContent WHERE InfoTypeId = 5 AND DateValue is NULL
	DELETE FROM @DocumentContent WHERE InfoTypeId = 6 AND DATALENGTH(RichTextValue)=0

	SELECT	InfoTypeId, FieldName, FieldDescription, InfoId, NumberValue, 
			DateValue, TextValue, RichTextValue, FieldId, FieldProcessType, Maximized 
	FROM @DocumentContent

	--Get Document Attachment
	SELECT ItemId = r.iItemId,
		   Name = b.strName,
		   FieldId = r.iPlacementId
	FROM m136_relInfo r 
		 JOIN m136_tblBlob b 
			ON r.iItemId = b.iItemId
	WHERE r.iEntityId = @EntityId 
		  AND r.iRelationTypeId IN (20, 2, 50)
	--Get Document Related
	SELECT Name = d.strName, 
		   DocumentId = d.iDocumentId,
		   FieldId = r.iPlacementId,
		   LevelType = d.iLevelType
	FROM m136_relInfo r
		JOIN m136_tblDocument d 
			ON	r.iItemId = d.iDocumentId 
				AND d.iLatestApproved = 1
	WHERE	r.iEntityId = @EntityId 
			AND r.iRelationTypeId = 136
	ORDER BY r.iSort
	--Get Document Info
	SELECT * FROM @Document
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
    BEGIN TRY
		BEGIN TRANSACTION 
            DELETE
                FROM m147_relRegisterItemCategory
            WHERE
                iCategoryId = @ChapterId
                AND iRegisterItemId IN (SELECT Id FROM @RegisterItemIds)
				AND iModuleId = 136
            DELETE
                FROM m147_relRegisterItemItem
            WHERE
                iItemId IN (SELECT iDocumentId FROM m136_tblDocument WHERE iHandbookId = @ChapterId)
                AND iRegisterItemId IN (SELECT Id FROM @RegisterItemIds)
				AND iModuleId = 136
            INSERT INTO CacheUpdate (ActionType, EntityId) VALUES (4, 0)
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK
		DECLARE @ErrorMessage nvarchar(MAX), @ErrorNumber int, @ErrorSeverity int, @ErrorState int, @ErrorLine int
		SELECT @ErrorMessage = N'Error %d, Line %d, Message: '+ERROR_MESSAGE(),@ErrorNumber = ERROR_NUMBER(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(),@ErrorLine = ERROR_LINE();
		RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber,@ErrorLine);
	END CATCH
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
            AND iRegisterItemValueId IN (SELECT RegisterItemValueId FROM @ItemValues)
			AND iModuleId = 136
			
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
        INSERT INTO CacheUpdate (ActionType, EntityId) VALUES (4, 0)
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
   IF @@TRANCOUNT > 0
			ROLLBACK
		DECLARE @ErrorMessage nvarchar(MAX), @ErrorNumber int, @ErrorSeverity int, @ErrorState int, @ErrorLine int
		SELECT @ErrorMessage = N'Error %d, Line %d, Message: '+ERROR_MESSAGE(),@ErrorNumber = ERROR_NUMBER(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(),@ErrorLine = ERROR_LINE();
		RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber,@ErrorLine);
END CATCH
END
GO

IF OBJECT_ID('[dbo].[m147_be_UntagRegisterItemValuesForModule]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_UntagRegisterItemValuesForModule] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_be_UntagRegisterItemValuesForModule]
    @RegisterItemItemIds AS [dbo].[Item] READONLY,
    @Module INT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        DELETE FROM
            m147_relRegisterItemItem
        WHERE
            iAutoId IN (SELECT Id FROM @RegisterItemItemIds)
            AND iModuleId =@Module
            
        INSERT INTO CacheUpdate (ActionType, EntityId) VALUES (4, 0)
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
			ROLLBACK
		DECLARE @ErrorMessage nvarchar(MAX), @ErrorNumber int, @ErrorSeverity int, @ErrorState int, @ErrorLine int
		SELECT @ErrorMessage = N'Error %d, Line %d, Message: '+ERROR_MESSAGE(),@ErrorNumber = ERROR_NUMBER(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(),@ErrorLine = ERROR_LINE();
		RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber,@ErrorLine);
END CATCH
END
GO

IF OBJECT_ID('[dbo].[m147_GetMetadataByModule]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_GetMetadataByModule] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m147_GetMetadataByModule]
	@UserId INT,
	@Id INT,
	@Module INT
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
		iModuleId = @Module
		AND iCategoryId = @Id
		AND ric.iInheritTypeId IN (1, 2, 3, 5)
		AND dbo.fnSecurityGetPermission(147, 571, @UserId, r.iRegisterId) & 0x01 = 0x01
	ORDER BY
		iRegisterId, iRegisterItemId
END
GO



