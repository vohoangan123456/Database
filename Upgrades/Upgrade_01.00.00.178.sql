INSERT INTO #Description VALUES('Created SP for getting deviation department permissions')
GO

IF NOT EXISTS (SELECT * FROM dbo.tblPermissionBit tpb WHERE tpb.iPermissionSetId = 570 AND iBitNumber = 1)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (1, 570, N'Administrere metadata', N'Administrere metadata')
END
GO
IF NOT EXISTS (SELECT * FROM dbo.tblPermissionBit tpb WHERE tpb.iPermissionSetId = 571 AND iBitNumber = 1)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (1, 571, N'L', N'Les')
END
GO
IF NOT EXISTS (SELECT * FROM dbo.tblPermissionBit tpb WHERE tpb.iPermissionSetId = 571 AND iBitNumber = 2)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (2, 571, N'S', N'Skriv')
END
GO
IF NOT EXISTS (SELECT * FROM dbo.tblPermissionBit tpb WHERE tpb.iPermissionSetId = 571 AND iBitNumber = 4)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (4, 571, N'E', N'Endre')
END
GO
IF NOT EXISTS (SELECT * FROM dbo.tblPermissionBit tpb WHERE tpb.iPermissionSetId = 571 AND iBitNumber = 8)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (8, 571, N'SL', N'Slette')
END
GO
IF NOT EXISTS (SELECT * FROM dbo.tblPermissionBit tpb WHERE tpb.iPermissionSetId = 571 AND iBitNumber = 16)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (16, 571, N'A', N'Admin')
END
GO

IF NOT EXISTS (SELECT * FROM dbo.tblPermissionBit tpb WHERE tpb.iPermissionSetId = 610 AND iBitNumber = 1)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (1, 610, N'Melde inn', N'Melde inn')
END
GO
IF NOT EXISTS (SELECT * FROM dbo.tblPermissionBit tpb WHERE tpb.iPermissionSetId = 610 AND iBitNumber = 2)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (2, 610, N'Behandle', N'Behandle')
END
GO
IF NOT EXISTS (SELECT * FROM dbo.tblPermissionBit tpb WHERE tpb.iPermissionSetId = 610 AND iBitNumber = 4)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (4, 610, N'Administrere', N'Administrere')
END
GO
IF NOT EXISTS (SELECT * FROM dbo.tblPermissionBit tpb WHERE tpb.iPermissionSetId = 611 AND iBitNumber = 1)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (1, 611, N'L', N'Les')
END
GO
IF NOT EXISTS (SELECT * FROM dbo.tblPermissionBit tpb WHERE tpb.iPermissionSetId = 611 AND iBitNumber = 2)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (2, 611, N'B', N'Behandle')
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateDeviationDepartmentPermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateDeviationDepartmentPermissions] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: DEC 31, 2015
-- Description:	Update deviation department permissions
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateDeviationDepartmentPermissions]
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