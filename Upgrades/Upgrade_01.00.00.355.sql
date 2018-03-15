INSERT INTO #Description VALUES ('Create script for m147 module')
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m147_tblSynonym]') AND type in (N'U'))
	CREATE TABLE [dbo].[m147_tblSynonym](
		[iSynonymId] [int] NOT NULL,
		[iRegisterItemValueId] [int] NOT NULL,
		[strSynonym] [varchar](50) NOT NULL,
	 CONSTRAINT [PK_m147_tblSynonym] PRIMARY KEY CLUSTERED 
	(
		[iSynonymId] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m147_tblRegisterItemValue]') AND type in (N'U')) 
	CREATE TABLE [dbo].[m147_tblRegisterItemValue](
		[iRegisterItemValueId] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
		[iRegisterItemValueParentId] [int] NULL,
		[iRegisterItemId] [int] NULL,
		[RegisterValue] [varchar](200) NOT NULL,
		[iSort] [int] NOT NULL,
	 CONSTRAINT [PK_m147_tblRegisterItemValue] PRIMARY KEY CLUSTERED 
	(
		[iRegisterItemValueId] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY] 
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m147_tblRegisterItem]') AND type in (N'U'))
	CREATE TABLE [dbo].[m147_tblRegisterItem](
		[iRegisterItemId] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
		[iRegisterItemParentId] [int] NULL,
		[iRegisterId] [int] NOT NULL,
		[strName] [varchar](200) NOT NULL,
		[strDescription] [varchar](1000) NOT NULL,
		[eTypeId] [int] NOT NULL,
		[bMandatory] [bit] NOT NULL,
		[bAllowMultiple] [bit] NOT NULL,
	 CONSTRAINT [PK_m147_tblRegisterItem] PRIMARY KEY CLUSTERED 
	(
		[iRegisterItemId] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

IF OBJECT_ID('[dbo].[m147_spGetRegisterItem]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_spGetRegisterItem] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_spGetRegisterItem]
(
@iSecurityId int,
@iRegisterItemId int
)
AS
BEGIN
	SELECT * 
	FROM m147_tblRegisterItem 
	WHERE iRegisterItemId = @iRegisterItemId 
	AND (dbo.fnSecurityGetPermission(147, 571, @iSecurityId, iRegisterId) & 1) = 1
END
GO

IF OBJECT_ID('[dbo].[m147_GetRegisterItems]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_GetRegisterItems] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_GetRegisterItems]
(
	@SecurityId INT,
	@RegisterId INT
)
AS
	SELECT RegisterItemId = a.iRegisterItemId, 
		Name = a.strName
	FROM m147_tblRegisterItem a 
	WHERE a.iRegisterId = @RegisterId 
		AND (dbo.fnSecurityGetPermission(147, 571, @SecurityId, a.iRegisterId) & 1) = 1
	ORDER BY Name
GO

IF OBJECT_ID('[dbo].[m147_be_GetRegisterItemValues]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_GetRegisterItemValues] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_be_GetRegisterItemValues]
(
	@SecurityId INT,
	@RegisterItemId INT
)
AS
BEGIN
	DECLARE @iAccess INT
	DECLARE @iRegisterId INT
	DECLARE @iRegItemId INT
	SELECT @iRegisterId = iRegisterId 
	FROM m147_tblRegisterItem 
	WHERE iRegisterItemId = @RegisterItemId
	SELECT @iAccess = dbo.fnSecurityGetPermission(147, 571, @SecurityId, @iRegisterId)
	SELECT a.*
	FROM m147_tblRegisterItemValue a 
	WHERE a.iRegisterItemId = @RegisterItemId
		  AND ((@iAccess & 1) = 1 or (@iAccess & 16) = 16) 
	ORDER BY a.iSort, a.RegisterValue
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m147_tblRegister]') AND type in (N'U'))
	CREATE TABLE [dbo].[m147_tblRegister](
		[iRegisterId] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
		[strName] [varchar](300) NOT NULL,
		[bObsolete] [bit] NOT NULL,
		[bKladd] [bit] NOT NULL,
	 CONSTRAINT [PK_m147_tblRegister] PRIMARY KEY CLUSTERED 
	(
		[iRegisterId] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
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
			SELECT * 
			FROM m147_tblRegister a 
			WHERE a.iRegisterId = @iRegisterId
				  AND (dbo.fnSecurityGetPermission(147, 571, @iSecurityId, @iRegisterId) & 1) = 1
		END
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

IF OBJECT_ID('[dbo].[m147_be_GetActiveRegisters]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_GetActiveRegisters] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_be_GetActiveRegisters]
(
	@iSecurityId INT
)
AS
BEGIN
	SELECT * 
	FROM m147_tblRegister 
	WHERE (dbo.fnSecurityGetPermission(147, 571, @iSecurityId, iRegisterId) & 1) = 1
		   AND bObsolete = 0 AND bKladd = 0
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m147_tblInheritType]') AND type in (N'U'))
	CREATE TABLE [dbo].[m147_tblInheritType](
		[iInheritTypeId] [int] NOT NULL,
		[strName] [varchar](50) NOT NULL,
		[strDescription] [varchar](500) NOT NULL,
	 CONSTRAINT [PK_m147_tblInheritType] PRIMARY KEY CLUSTERED 
	(
		[iInheritTypeId] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m147_tblEtype]') AND type in (N'U'))
	CREATE TABLE [dbo].[m147_tblEtype](
		[eTypeId] [int] NOT NULL,
		[strName] [varchar](50) NOT NULL,
		[strDescription] [varchar](500) NOT NULL,
	 CONSTRAINT [PK_m147_tblEtype] PRIMARY KEY CLUSTERED 
	(
		[eTypeId] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

IF NOT EXISTS(SELECT * FROM [dbo].[m147_tblEtype] WHERE eTypeId = 1)
	BEGIN
		INSERT INTO [dbo].[m147_tblEtype](eTypeId,strName, strDescription)VALUES(1, 'Uten data','')			
	END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[m147_tblEtype] WHERE eTypeId = 2)
	BEGIN
		INSERT INTO [dbo].[m147_tblEtype](eTypeId,strName, strDescription)VALUES(2, 'Tall','')			
	END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[m147_tblEtype] WHERE eTypeId = 3)
	BEGIN
		INSERT INTO [dbo].[m147_tblEtype](eTypeId,strName, strDescription)VALUES(3, 'Hierarki','')			
	END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[m147_tblEtype] WHERE eTypeId = 4)
	BEGIN
		INSERT INTO [dbo].[m147_tblEtype](eTypeId,strName, strDescription)VALUES(4, 'Dato','')			
	END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[m147_tblEtype] WHERE eTypeId = 5)
	BEGIN
		INSERT INTO [dbo].[m147_tblEtype](eTypeId,strName, strDescription)VALUES(5, 'Tekst','')			
	END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[m147_tblEtype] WHERE eTypeId = 6)
	BEGIN
		INSERT INTO [dbo].[m147_tblEtype](eTypeId,strName, strDescription)VALUES(6, 'Liste','')			
	END
GO

IF OBJECT_ID('[dbo].[m147_spGetRegisterItems]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_spGetRegisterItems] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_spGetRegisterItems]
(
	@iSecurityId int,
	@iRegisterId int
)
AS
BEGIN
	SELECT a.*, b.strName AS strEtype 
	FROM m147_tblRegisterItem a 
	INNER JOIN m147_tblEtype b ON a.eTypeId = b.eTypeId
	WHERE a.iRegisterId = @iRegisterId 
	AND (dbo.fnSecurityGetPermission(147, 571, @iSecurityId, a.iRegisterId) & 1) = 1
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m147_relRegisterItemCategory]') AND type in (N'U'))
	CREATE TABLE [dbo].[m147_relRegisterItemCategory](
		[iAutoId] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
		[iRegisterItemId] [int] NOT NULL,
		[iModuleId] [int] NOT NULL,
		[iCategoryId] [int] NOT NULL,
		[ValueDate] [datetime] NULL,
		[ValueTall] [bigint] NULL,
		[ValueText] [varchar](200) NULL,
		[iRegisterItemValueId] [int] NULL,
		[DefaultDateValue] [datetime] NULL,
		[DefaultTallValue] [bigint] NULL,
		[DefaultTextValue] [varchar](200) NULL,
		[DefaultRegisterValueId] [int] NULL,
		[iInheritTypeId] [int] NOT NULL,
	 CONSTRAINT [PK_m147_relRegisterItemCategory] PRIMARY KEY CLUSTERED 
	(
		[iAutoId] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m147_relRegisterItemItem]') AND type in (N'U'))
	CREATE TABLE [dbo].[m147_relRegisterItemItem](
		[iAutoId] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
		[iRegisterItemId] [int] NOT NULL,
		[iModuleId] [int] NOT NULL,
		[iCategoryId] [int] NOT NULL,
		[iItemId] [int] NOT NULL,
		[ValueDate] [datetime] NULL,
		[ValueTall] [bigint] NULL,
		[ValueText] [varchar](200) NULL,
		[iRegisterItemValueId] [int] NULL,
	 CONSTRAINT [PK_m147_relRegisterItemItem] PRIMARY KEY CLUSTERED 
	(
		[iAutoId] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
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
		END
END
GO

IF OBJECT_ID('[dbo].[m147_be_DeleteRegisters]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_DeleteRegisters] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_be_DeleteRegisters]
(
	@SecurityId INT,
	@RegisterIds  AS [dbo].[Item] READONLY
)
AS
BEGIN
	DECLARE @Id INT;
	DECLARE RegisterSet CURSOR FOR 
		SELECT Id
		FROM @RegisterIds;
	OPEN RegisterSet; 
	FETCH NEXT FROM RegisterSet INTO @Id;
	WHILE @@FETCH_STATUS = 0
    BEGIN
		EXEC [dbo].[m147_spDeleteRegister] @SecurityId, @Id
		FETCH NEXT FROM RegisterSet INTO @Id;
	END
	CLOSE RegisterSet;
	DEALLOCATE RegisterSet;
END
GO

IF OBJECT_ID('[dbo].[m147_spDeleteRegisterItem]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_spDeleteRegisterItem] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_spDeleteRegisterItem]
(
	@iSecurityId INT,
	@iRegisterItemId INT
)
AS
BEGIN
	BEGIN TRY
	BEGIN TRANSACTION 
		DECLARE @iAccess INT
		DECLARE @iRegisterId INT
		SELECT @iRegisterId = iRegisterId 
		FROM m147_tblRegisterItem 
		WHERE iRegisterItemId = @iRegisterItemId
		SELECT @iAccess = dbo.fnSecurityGetPermission(147, 571, @iSecurityId, @iRegisterId)
		IF (@iAccess & 8) = 8 or (@iAccess & 16) = 16
			BEGIN
				DELETE FROM m147_relRegisterItemCategory 
					   WHERE iRegisterItemId = @iRegisterItemId
				DELETE FROM m147_relRegisterItemItem 
					   WHERE iRegisterItemId = @iRegisterItemId
				DELETE FROM m147_tblSynonym 
					   WHERE iRegisterItemValueId IN (SELECT DISTINCT iRegisterItemValueId 
													  FROM m147_tblRegisterItemValue 
													  WHERE iRegisterItemId = @iRegisterItemId)
				DELETE FROM m147_tblRegisterItemValue 
					   WHERE iRegisterItemId = @iRegisterItemId
				DELETE FROM m147_tblRegisterItem 
					   WHERE iRegisterItemId = @iRegisterItemId
			END
	COMMIT
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

IF OBJECT_ID('[dbo].[m147_be_DeleteRegisterItems]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_DeleteRegisterItems] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_be_DeleteRegisterItems]
(
	@SecurityId INT,
	@RegisterItemIds  AS [dbo].[Item] READONLY
)
AS
BEGIN
	DECLARE @Id INT;
	DECLARE RegisterItemSet CURSOR FOR 
		SELECT Id
		FROM @RegisterItemIds;
	OPEN RegisterItemSet; 
	FETCH NEXT FROM RegisterItemSet INTO @Id;
	WHILE @@FETCH_STATUS = 0
    BEGIN
		EXEC [dbo].[m147_spDeleteRegisterItem] @SecurityId, @Id
		FETCH NEXT FROM RegisterItemSet INTO @Id;
	END
	CLOSE RegisterItemSet;
	DEALLOCATE RegisterItemSet;
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

IF OBJECT_ID('[dbo].[m147_be_UntagDocumentRegisterItemValues]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_UntagDocumentRegisterItemValues] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_be_UntagDocumentRegisterItemValues]
    @RegisterItemItemIds AS [dbo].[Item] READONLY
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        DELETE FROM
            m147_relRegisterItemItem
        WHERE
            iAutoId IN (SELECT Id FROM @RegisterItemItemIds)
        INSERT INTO CacheUpdate (ActionType, EntityId) VALUES (4, 0)
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK;
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
    ROLLBACK;
END CATCH
END
GO

IF OBJECT_ID('[dbo].[m147_be_GetRegisters]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_GetRegisters] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JAN 05, 2015
-- Description:	GET REGISTERS
-- =============================================
ALTER PROCEDURE [dbo].[m147_be_GetRegisters]
	@iRegisterId INT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SELECT * FROM [dbo].[m147_tblRegister] WHERE (iRegisterId = @iRegisterId OR @iRegisterId IS NULL) AND bObsolete = 0;
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
    BEGIN TRY
		BEGIN TRANSACTION 
            INSERT INTO
                m147_relRegisterItemCategory
                    (iRegisterItemId, iModuleId, iCategoryId, iInheritTypeId)
                VALUES
                    (@RegisterItemId, 136, @ChapterId, 2)
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

IF OBJECT_ID('[dbo].[m147_spGetEtype]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_spGetEtype] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_spGetEtype]
(
	@eTypeId int = 0
)
AS
BEGIN
	IF @eTypeId = 0
		SELECT * FROM m147_tblEtype
	ELSE
		SELECT * FROM m147_tblEtype WHERE eTypeId = @eTypeId
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
            DELETE
                FROM m147_relRegisterItemItem
            WHERE
                iItemId IN (SELECT iDocumentId FROM m136_tblDocument WHERE iHandbookId = @ChapterId)
                AND iRegisterItemId IN (SELECT Id FROM @RegisterItemIds)
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

IF OBJECT_ID('[dbo].[m147_be_UpdateRegisterItemValue]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_UpdateRegisterItemValue] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_be_UpdateRegisterItemValue]
	@RegisterItemId INT,
	@RegisterItemValue AS [dbo].[Items] READONLY
AS
BEGIN
	BEGIN TRY
	BEGIN TRANSACTION 
		SET NOCOUNT ON;
		DELETE dbo.m147_tblRegisterItemValue WHERE iRegisterItemId = @RegisterItemId 
			AND iRegisterItemValueId NOT IN (SELECT Id 
			FROM @RegisterItemValue);
		DECLARE @iRegisterItemValueId INT, @RegisterValue VARCHAR(200);
		DECLARE @iSort INT = 1;
		DECLARE RegisterItemValueSet CURSOR FOR 
			SELECT Id, Value
			FROM @RegisterItemValue;
		OPEN RegisterItemValueSet; 
		FETCH NEXT FROM RegisterItemValueSet INTO @iRegisterItemValueId, @RegisterValue;
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @iRegisterItemValueId IS NOT NULL AND @iRegisterItemValueId <> 0
			BEGIN
				UPDATE dbo.m147_tblRegisterItemValue
				SET RegisterValue = @RegisterValue, iSort = @iSort
				WHERE iRegisterItemValueId = @iRegisterItemValueId 
			END
			ELSE
			BEGIN
				INSERT INTO dbo.m147_tblRegisterItemValue (iRegisterItemId
					, RegisterValue, iSort) 
				VALUES (@RegisterItemId
					, @RegisterValue, @iSort);
			END
			SET @iSort = @iSort + 1;
			FETCH NEXT FROM RegisterItemValueSet INTO @iRegisterItemValueId, @RegisterValue;
		END
		CLOSE RegisterItemValueSet;
		DEALLOCATE RegisterItemValueSet;
	COMMIT
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

IF OBJECT_ID('[dbo].[m147_be_UpdateRegisterItem]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_UpdateRegisterItem] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_be_UpdateRegisterItem]
(
@iRegisterItemId INT,
@strName VARCHAR(200),
@strDescription VARCHAR(1000),
@eTypeId INT,
@bMandatory BIT,
@bAllowMultiple BIT
)
AS
BEGIN
	UPDATE m147_tblRegisterItem 
	SET strName = @strName
		, strDescription = @strDescription, eTypeId = @eTypeId, bMandatory = @bMandatory
		, bAllowMultiple = @bAllowMultiple 
	WHERE iRegisterItemId = @iRegisterItemId
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
	@Obsolete BIT
)
AS
BEGIN
		UPDATE m147_tblRegister 
		SET strName = @Name, bObsolete = @Obsolete, bKladd = @Draft 
		WHERE iRegisterId = @RegisterId
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
    ORDER BY iSort
END
GO

IF OBJECT_ID('[dbo].[m147_be_AddRegisterItem]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_AddRegisterItem] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_be_AddRegisterItem]
(
@iRegisterId INT,
@strName VARCHAR(200),
@strDescription VARCHAR(1000),
@eTypeId INT,
@bMandatory BIT,
@bAllowMultiple BIT,
@iRegisterItemParentId INT = null
)
AS
BEGIN
	INSERT INTO m147_tblRegisterItem (iRegisterId, iRegisterItemParentId, strName, strDescription, eTypeId, bMandatory, bAllowMultiple)
				VALUES (@iRegisterId, @iRegisterItemParentId, @strName, @strDescription, @eTypeId, @bMandatory, @bAllowMultiple)
	SELECT cast(@@identity AS INT) AS nyid
END
GO

IF OBJECT_ID('[dbo].[m147_be_AddMetaRegister]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_AddMetaRegister] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_be_AddMetaRegister]
(
	@Name varchar(300),
	@Draft bit,
	@Obsolete bit
)
AS
BEGIN
		INSERT INTO m147_tblRegister (strName, bObsolete, bKladd) VALUES (@Name, @Obsolete, @Draft)
		SELECT cast(@@identity AS int) AS nyid
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

IF OBJECT_ID('[dbo].[m147_be_UpdateMetadataRegisterPermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_UpdateMetadataRegisterPermissions] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_be_UpdateMetadataRegisterPermissions]
	@Permissions AS [dbo].[ACLDatatable] READONLY,
	@iRoleId INT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @iEntityId INT, @iAppicationId INT, @iSecurityId INT, @iPermissionSetId INT, @iGroupingId INT, @iBit INT, @bRecursive BIT;
	DECLARE PermissionSet CURSOR FOR 
		SELECT iEntityId 
			, iApplicationId
			, iSecurityId
			, iPermissionSetId
			, iGroupingId
			, iBit 
			, bRecursive
		FROM @Permissions;
	OPEN PermissionSet; 
	FETCH NEXT FROM PermissionSet INTO @iEntityId, @iAppicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit, @bRecursive;
	WHILE @@FETCH_STATUS = 0
    BEGIN
		IF EXISTS(SELECT * FROM [dbo].[tblACL] 
			WHERE iEntityId = @iEntityId 
				AND iApplicationId = @iAppicationId 
				AND iSecurityId = @iSecurityId 
				AND iPermissionSetId = @iPermissionSetId)
		BEGIN
			UPDATE [dbo].[tblACL]
			SET iBit = @iBit
			WHERE iEntityId = @iEntityId 
				AND iApplicationId = @iAppicationId 
				AND iSecurityId = @iSecurityId 
				AND iPermissionSetId = @iPermissionSetId;
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[tblACL] (iEntityId
				, iApplicationId
				, iSecurityId
				, iPermissionSetId
				, iGroupingId
				, iBit) 
			VALUES (@iEntityId
				, @iAppicationId
				, @iSecurityId
				, @iPermissionSetId
				, 0
				, @iBit);
		END
		IF (@bRecursive = 1)
		BEGIN
			DECLARE @iDepartmentId INT;
 			DECLARE RecursivePermissionSet CURSOR FOR 
			SELECT iDepartmentId 
				, @iAppicationId
				, @iSecurityId
				, @iPermissionSetId
				, @iGroupingId
				, @iBit
			FROM [dbo].[m136_GetDepartmentsRecursive](@iEntityId);
			OPEN RecursivePermissionSet; 
			FETCH NEXT FROM RecursivePermissionSet INTO @iDepartmentId, @iAppicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit;
			WHILE @@FETCH_STATUS = 0
			BEGIN
				IF EXISTS(SELECT * FROM [dbo].[tblACL] 
					WHERE iEntityId = @iDepartmentId 
						AND iApplicationId = @iAppicationId 
						AND iSecurityId = @iSecurityId 
						AND iPermissionSetId = @iPermissionSetId)
				BEGIN
					UPDATE [dbo].[tblACL]
					SET iBit = @iBit
					WHERE iEntityId = @iDepartmentId 
						AND iApplicationId = @iAppicationId 
						AND iSecurityId = @iSecurityId 
						AND iPermissionSetId = @iPermissionSetId;
				END
				ELSE
				BEGIN
					INSERT INTO [dbo].[tblACL] (iEntityId
						, iApplicationId
						, iSecurityId
						, iPermissionSetId
						, iGroupingId
						, iBit) 
					VALUES (@iDepartmentId
						, @iAppicationId
						, @iSecurityId
						, @iPermissionSetId
						, 0
						, @iBit);
				END
				FETCH NEXT FROM RecursivePermissionSet INTO @iDepartmentId, @iAppicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit;
			END
			CLOSE RecursivePermissionSet;
			DEALLOCATE RecursivePermissionSet;
        END
		FETCH NEXT FROM PermissionSet INTO @iEntityId, @iAppicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit, @bRecursive;
	END
	CLOSE PermissionSet;
	DEALLOCATE PermissionSet;
END
GO

IF NOT EXISTS(
    SELECT *
    FROM sys.columns 
    WHERE Name = N'iSort'
      AND Object_ID = Object_ID(N'dbo.m147_tblRegisterItemValue'))
BEGIN
    ALTER TABLE dbo.m147_tblRegisterItemValue ADD iSort INT NOT NULL   DEFAULT(0);
END
GO



