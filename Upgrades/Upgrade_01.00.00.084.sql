
INSERT INTO #Description VALUES('Create stored procedures edit folder page.')
GO

IF OBJECT_ID('[dbo].[m136_be_InsertFolder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_InsertFolder] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JUNE 26, 2015
-- Description:	Insert new folder
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_InsertFolder]
	@iUserId INT,
	@iParentHandbookId	INT,
    @strName			VARCHAR(100),
    @strDescription		VARCHAR(7000),
    @iDepartmentId		INT,
    @iLevelType			INT,
    @iViewTypeId		INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @iParentLevel INT = 0, @iMaxHandbookId INT = 0;
	SELECT @iParentLevel = h.iLevel FROM dbo.m136_tblHandbook h WHERE h.iParentHandbookId = @iParentHandbookId;
	SELECT @iMaxHandbookId = MAX(ihandbookid) FROM dbo.m136_tblHandbook;
	
	DECLARE @iNewHandbookId INT = @iMaxHandbookId + 1;
	
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
		iLevel) 
    VALUES(
		@iNewHandbookId,
		@iParentHandbookId, 
		@strName, 
		@strDescription, 
		@iDepartmentId, 
		@iLevelType, 
		(CASE WHEN @iViewTypeId = -1 THEN 1 WHEN @iViewTypeId = -2 THEN 2 END), 
		GETDATE(), 
		@iUserId, 
		0,
		0,
		0,
		(@iParentLevel + 1));
		
		
	DECLARE @iRoleId INT;
	DECLARE Roles CURSOR FOR 
		SELECT [iSecGroupId]
			FROM [dbo].[relEmployeeSecGroup]
			WHERE iEmployeeId = @iUserId;

	OPEN Roles; 
	
	FETCH NEXT FROM Roles INTO @iRoleId;
	
	WHILE @@FETCH_STATUS = 0
    BEGIN
		INSERT INTO dbo.tblACL
			SELECT @iNewHandbookId
				, [iApplicationId]
				, @iRoleId
				, [iPermissionSetId]
				, [iGroupingId]
				, [iBit]
			FROM [dbo].[tblACL] 
			WHERE iEntityId = @iParentHandbookId 
				AND iApplicationId = 136
				AND (iPermissionSetId = 461 OR iPermissionSetId = 462)
				AND iSecurityId = @iRoleId;
				
		FETCH NEXT FROM Roles INTO @iRoleId;
	END
	CLOSE Roles;
	DEALLOCATE Roles;
			
	SELECT @iNewHandbookId;
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetFolderPermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetFolderPermissions] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JUNE 29, 2015
-- Description:	Get folder permissions
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetFolderPermissions] 
	@iFolderId INT,
	@iSecurityId INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT iEntityId
		, iPermissionSetId AS iAccessRights
		,[iBit]
		,iSecurityId AS iGroupingId,
		sg.strName AS strGroupName
	FROM [dbo].[tblACL] acl
		LEFT JOIN [dbo].[tblSecGroup] sg ON acl.iSecurityId = sg.iSecGroupId
	WHERE iEntityId = @iFolderId
		AND iSecurityId IN (SELECT [iSecGroupId]
			FROM [dbo].[relEmployeeSecGroup]
				WHERE iEmployeeId = @iSecurityId)
		AND iApplicationId = 136 -- Handbook module
		AND (iPermissionSetId = 461 OR iPermissionSetId = 462) -- 461: group permission for folder rights, 462: group permissions for document rights
END
GO

IF NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'SecurityDatatable' AND ss.name = N'dbo')
	CREATE TYPE [dbo].[SecurityDatatable] AS TABLE(
		[iEntityId] [int] NOT NULL,
		[iApplicationId] [int] NOT NULL,
		[iSecurityId] [int] NOT NULL,
		[iPermissionSetId] [int] NOT NULL,
		[iGroupingId] [int] NOT NULL,
		[iBit] [int] NOT NULL
	)
GO

IF OBJECT_ID('[dbo].[m136_be_GetSecurityGroups]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetSecurityGroups] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JUNE 29, 2015
-- Description:	Get security groups
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetSecurityGroups] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT sg.iSecGroupId
		   ,sg.strName
		   ,sg.strDescription 
	FROM [dbo].[tblSecGroup] sg;
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateFolderPermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateFolderPermissions] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JUNE 30, 2015
-- Description:	Update folder permissions.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateFolderPermissions] 
	-- Add the parameters for the stored procedure here
	@Permissions AS [dbo].[SecurityDatatable] READONLY
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @iEntityId INT, @iAppicationId INT, @iSecurityId INT, @iPermissionSetId INT, @iGroupingId INT, @iBit INT;
	DECLARE PermissionSet CURSOR FOR 
		SELECT iEntityId 
			, iApplicationId
			, iSecurityId
			, iPermissionSetId
			, iGroupingId
			, iBit 
		FROM @Permissions;

	OPEN PermissionSet; 
	
	FETCH NEXT FROM PermissionSet INTO @iEntityId, @iAppicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit;
	
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
		FETCH NEXT FROM PermissionSet INTO @iEntityId, @iAppicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit;
	END
	CLOSE PermissionSet;
	DEALLOCATE PermissionSet;
	
	DELETE [dbo].[tblACL] WHERE iEntityId = @iEntityId 
		AND iApplicationId = @iAppicationId 
		AND iSecurityId NOT IN (SELECT iSecurityId 
		FROM @Permissions);
END
GO