INSERT INTO #Description VALUES('Created SP for metadata permissions management')
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

IF OBJECT_ID('[dbo].[m147_be_UpdateMetadataRegisterPermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_UpdateMetadataRegisterPermissions] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JAN 06, 2016
-- Description:	Update deviation department permissions
-- =============================================
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