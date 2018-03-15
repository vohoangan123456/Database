INSERT INTO #Description VALUES('CREATE SP [m136_be_GetApplicationPermissionsByUserId]')
GO

IF OBJECT_ID('[m136_be_GetApplicationPermissionsByUserId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [m136_be_GetApplicationPermissionsByUserId] AS SELECT 1')
GO
-- =============================================
-- Author:		SI.NGUYEN.MANH
-- Create date: DEC 23, 2015
-- Description:	Get Application Permission by UserId
-- =============================================
ALTER PROCEDURE [m136_be_GetApplicationPermissionsByUserId]
	@iApplicationId INT,
	@iPermissionSetId AS [dbo].[Item] READONLY,
	@iUserId INT,
	@iFolderId INT
AS
BEGIN
	SET NOCOUNT ON;
	SELECT ta.iEntityId, ta.iSecurityId, ta.iPermissionSetId AS iAccessRights, ta.iBit FROM dbo.tblACL ta 
	WHERE ta.iApplicationId = @iApplicationId 
		AND ta.iPermissionSetId IN (SELECT Id FROM @iPermissionSetId) 
		AND ta.iSecurityId IN (SELECT resg.iSecGroupId FROM dbo.relEmployeeSecGroup resg WHERE resg.iEmployeeId = @iUserId)
		AND (ta.iEntityId = @iFolderId OR @iFolderId IS NULL);
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetMetaRegisterPermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetMetaRegisterPermissions] AS SELECT 1')
GO
-- =============================================
-- Author:		SI.MANH.NGUYEN
-- Create date: DEC 25, 2015
-- Description:	Get permissions for a specified metadata register.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetMetaRegisterPermissions]
	@RegisterId INT
AS
BEGIN
	SET NOCOUNT ON;
	SELECT iEntityId
		, iPermissionSetId AS iAccessRights
		,[iBit]
		,iSecurityId AS iGroupingId,
		sg.strName AS strGroupName
	FROM [dbo].[tblACL] acl
		LEFT JOIN [dbo].[tblSecGroup] sg ON acl.iSecurityId = sg.iSecGroupId
	WHERE iEntityId = @RegisterId
		AND iApplicationId = 147 -- metaRegister
		AND (iPermissionSetId = 571);
END
GO

IF OBJECT_ID('[dbo].[m147_be_AddMetaRegister]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_AddMetaRegister] AS SELECT 1')
GO
-- =============================================
-- Author:		SI.MANH.NGUYEN
-- Create date: DEC 28, 2015
-- Description:	add meta register
-- =============================================
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

IF OBJECT_ID('[dbo].[m136_be_UpdateItemPermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateItemPermissions] AS SELECT 1')
GO

-- =============================================
-- Author:		SI.MANH.NGUYEN
-- Create date: DEC 28, 2015
-- Description:	Update or Add permission meta register
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateItemPermissions]
	@ItemId INT,
	@ApplicationId INT,
	@PermissionSetId INT,
	@Permissions AS [dbo].[ACLDatatable] READONLY
AS
BEGIN
	SET NOCOUNT ON;
    DECLARE @iEntityId INT, @iApplicationId INT, @iSecurityId INT, @iPermissionSetId INT, @iGroupingId INT, @iBit INT;
	DECLARE PermissionSet CURSOR FOR 
		SELECT iEntityId 
			, iApplicationId
			, iSecurityId
			, iPermissionSetId
			, iGroupingId
			, iBit 
		FROM @Permissions;
	OPEN PermissionSet; 
	FETCH NEXT FROM PermissionSet INTO @iEntityId, @iApplicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit;
	WHILE @@FETCH_STATUS = 0
    BEGIN
		IF EXISTS(SELECT * FROM [dbo].[tblACL] 
			WHERE iEntityId = @iEntityId 
				AND iApplicationId = @iApplicationId 
				AND iSecurityId = @iSecurityId 
				AND iPermissionSetId = @iPermissionSetId)
		BEGIN
			UPDATE [dbo].[tblACL]
			SET iBit = @iBit
			WHERE iEntityId = @iEntityId 
				AND iApplicationId = @iApplicationId 
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
				, @iApplicationId
				, @iSecurityId
				, @iPermissionSetId
				, 0
				, @iBit);
		END
		FETCH NEXT FROM PermissionSet INTO @iEntityId, @iApplicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit;
	END
	CLOSE PermissionSet;
	DEALLOCATE PermissionSet;
	
	DELETE [dbo].[tblACL] WHERE iEntityId = @ItemId 
		AND iApplicationId = @ApplicationId
		AND iPermissionSetId = @PermissionSetId 
		AND iSecurityId NOT IN (SELECT iSecurityId 
		FROM @Permissions);
END
GO

IF OBJECT_ID('[dbo].[m147_be_UpdateMetaRegister]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_UpdateMetaRegister] AS SELECT 1')
GO

-- =============================================
-- Author:		SI.MANH.NGUYEN
-- Create date: DEC 28, 2015
-- Description:	Update meta register
-- =============================================
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
	ORDER BY a.RegisterValue
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

IF  NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'Items' AND ss.name = N'dbo')
	CREATE TYPE [dbo].[Items] AS TABLE(
		[Id] [int] NOT NULL,
		[Value] VARCHAR(MAX) NULL
	)
GO

IF OBJECT_ID('[dbo].[m147_be_UpdateRegisterItemValue]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_UpdateRegisterItemValue] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m147_be_UpdateRegisterItemValue]
	@RegisterItemId INT,
	@RegisterItemValue AS [dbo].[Items] READONLY
AS
BEGIN
	SET NOCOUNT ON;
	
	DELETE dbo.m147_tblRegisterItemValue WHERE iRegisterItemId = @RegisterItemId 
		AND iRegisterItemValueId NOT IN (SELECT Id 
		FROM @RegisterItemValue);
	
    DECLARE @iRegisterItemValueId INT, @RegisterValue VARCHAR(200);
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
			SET RegisterValue = @RegisterValue
			WHERE iRegisterItemValueId = @iRegisterItemValueId 
		END
		ELSE
		BEGIN
			INSERT INTO dbo.m147_tblRegisterItemValue (iRegisterItemId
				, RegisterValue) 
			VALUES (@RegisterItemId
				, @RegisterValue);
		END
		FETCH NEXT FROM RegisterItemValueSet INTO @iRegisterItemValueId, @RegisterValue;
	END
	CLOSE RegisterItemValueSet;
	DEALLOCATE RegisterItemValueSet;
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