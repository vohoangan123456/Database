
INSERT INTO #Description VALUES('Modified stored procedures for folder permission.')
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
	@UserId INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    SELECT sg.iSecGroupId
		   ,sg.strName
		   ,sg.strDescription 
	FROM [dbo].[tblSecGroup] sg
	--JOIN [dbo].[relEmployeeSecGroup] esg ON esg.iSecGroupId = sg.iSecGroupId
	--WHERE esg.iEmployeeId = @UserId;
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
		/*AND iSecurityId IN (SELECT [iSecGroupId]
			FROM [dbo].[relEmployeeSecGroup]
				WHERE iEmployeeId = @iSecurityId)*/
		AND iApplicationId = 136 -- Handbook module
		AND (iPermissionSetId = 461 OR iPermissionSetId = 462) -- 461: group permission for folder rights, 462: group permissions for document rights
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateFolderInformation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateFolderInformation] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JULY 01, 2015
-- Description:	Update folder information
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateFolderInformation]
	@FolderId INT,
	@ParentFolderId INT,
	@strName VARCHAR(100),
	@strDescription VARCHAR(700),
	@iDepartmentId INT,
	@iLevelType INT,
	@iViewType INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    UPDATE [dbo].[m136_tblHandbook] 
    SET strName = @strName,
		iParentHandbookId = (CASE WHEN @ParentFolderId = 0 THEN NULL ELSE @ParentFolderId END),
		strDescription = @strDescription,
		iDepartmentId = @iDepartmentId,
		iLevelType = @iLevelType,
		iViewTypeId = (CASE WHEN @iViewType = -1 THEN 1 WHEN @iViewType = -2 THEN 3 END)
	WHERE iHandbookId = @FolderId;
END
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
		(@iParentLevel + 1));

	INSERT INTO dbo.tblACL
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
						
	/*DECLARE @iRoleId INT;
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
	DEALLOCATE Roles;*/
	
	SELECT @iNewHandbookId;
END
GO