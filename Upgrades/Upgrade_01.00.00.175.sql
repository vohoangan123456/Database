INSERT INTO #Description VALUES('Created SP for getting module permissions')
GO

IF NOT EXISTS (SELECT * FROM dbo.tblPermissionSet tps WHERE tps.iPermissionSetId = 570)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (570, 2, N'Modulrettigheter', N'Modulrettigheter')
END
GO

IF NOT EXISTS (SELECT * FROM dbo.tblPermissionSet tps WHERE tps.iPermissionSetId = 571)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (571, 3, N'Registerrettigheter', N'Registerrettigheter')
END
GO

IF NOT EXISTS (SELECT * FROM dbo.tblPermissionSet tps WHERE tps.iPermissionSetId = 610)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (610, 2, N'eDeviation object privileges', N'eDeviation object privileges')
END
GO

IF NOT EXISTS (SELECT * FROM dbo.tblPermissionSet tps WHERE tps.iPermissionSetId = 611)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (611, 3, N'eDeviation object privileges', N'eDeviation object privileges')
END
GO

IF NOT EXISTS(SELECT * FROM dbo.tblApplication ta WHERE ta.iApplicationId = 147)
BEGIN
	INSERT [dbo].[tblApplication] ([iApplicationId], [strName], [strDescription], [iMajorVersion], [iMinorVersion], [iBuildVersion], [iActive], [iHasAdmin], [strAdminIconURL], [strAdminEntryPage]) VALUES (147, N'Metadata', N'Metadatamodul', 1, 0, 0, 0, 0, N'', N'')
END
GO

IF NOT EXISTS(SELECT * FROM dbo.tblApplication ta WHERE ta.iApplicationId = 151)
BEGIN
	INSERT [dbo].[tblApplication] ([iApplicationId], [strName], [strDescription], [iMajorVersion], [iMinorVersion], [iBuildVersion], [iActive], [iHasAdmin], [strAdminIconURL], [strAdminEntryPage]) VALUES (151, N'eDeviation', N'eDeviation', 1, 0, 0, -1, 0, N'', N'')
END
GO



IF OBJECT_ID('[dbo].[m136_be_GetModulePermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetModulePermissions] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: DEC 21, 2015
-- Description:	Get module permissions
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetModulePermissions]
	@iPermissionSetId AS [dbo].[Item] READONLY,
	@iApplicationSetId AS [dbo].[Item] READONLY,
	@iSecurityId INT
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT ta.iEntityId, ta.iSecurityId, ta.iPermissionSetId AS iAccessRights, ta.iBit FROM dbo.tblACL ta 
	WHERE ta.iApplicationId IN (SELECT Id FROM @iApplicationSetId) 
		AND ta.iPermissionSetId IN (SELECT Id FROM @iPermissionSetId) 
		AND ta.iSecurityId = @iSecurityId;
END
GO



IF OBJECT_ID('[dbo].[m136_be_UpdateModulePermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateModulePermissions] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: DEC 21, 2015
-- Description:	Update module permissions
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateModulePermissions] 
	@iRoleId INT,
	@Permissions AS [dbo].[ACLDatatable] READONLY
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @iEntityId INT, @iAppicationId INT, @iSecurityId INT, @iPermissionSetId INT, @iGroupingId INT, @iBit INT, @bRecursive BIT;
	DECLARE PermissionSet CURSOR FOR 
		SELECT iEntityId 
			, iApplicationId
			, @iRoleId
			, iPermissionSetId
			, iGroupingId
			, iBit 
			, bRecursive
		FROM @Permissions;
		
	OPEN PermissionSet; 
	FETCH NEXT FROM PermissionSet INTO @iEntityId, @iAppicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit, @bRecursive;
	WHILE @@FETCH_STATUS = 0
    BEGIN
		IF NOT EXISTS(SELECT * FROM dbo.tblACL ta WHERE ta.iEntityId = 0 
			AND ta.iSecurityId = @iSecurityId 
			AND ta.iApplicationId = @iAppicationId 
			AND ta.iPermissionSetId = @iPermissionSetId)
		BEGIN
			INSERT INTO dbo.tblACL(
				iEntityId,
				iApplicationId,
				iSecurityId,
				iPermissionSetId,
				iGroupingId,
				iBit
			) 
			VALUES(
				0, 
				@iAppicationId,
				@iSecurityId,
				@iPermissionSetId,
				0,
				@iBit
			);				
		END
		ELSE
		BEGIN
			UPDATE dbo.tblACL
			SET
			    iEntityId = 0,
			    iApplicationId = @iAppicationId,
			    iSecurityId = @iSecurityId,
			    iPermissionSetId = @iPermissionSetId,
			    iGroupingId = 0,
			    iBit = @iBit
			WHERE dbo.tblACL.iEntityId = 0
			AND iApplicationId = @iAppicationId
			AND iSecurityId = @iSecurityId
			AND iPermissionSetId = @iPermissionSetId
		END
		FETCH NEXT FROM PermissionSet INTO @iEntityId, @iAppicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit, @bRecursive;
    END
    CLOSE PermissionSet;
	DEALLOCATE PermissionSet;
END
GO