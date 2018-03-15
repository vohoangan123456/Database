INSERT INTO #Description VALUES('Modify stored procedure for admin role permissions management.')
GO

IF OBJECT_ID('[dbo].[m136_GetChapterItems]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetChapterItems] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetChapterItems]
	@iHandbookId INT = NULL
AS
SET NOCOUNT ON
BEGIN
		SELECT	strName as FolderName,
				iParentHandbookId as ParentId,
				dbo.fn136_GetParentPathEx(@iHandbookId) as Path,
				iLevel as Level,
				iViewTypeId as ViewType,
				iLevelType as LevelType,
				iDepartmentId as DepartmentId,
				strDescription
		FROM	m136_tblHandbook
		WHERE	iHandbookId = @iHandbookId AND @iHandbookId IS NOT NULL;
		SELECT	d.iDocumentId as Id,
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
				h.iParentHandbookId
		FROM	m136_tblDocument d
		LEFT JOIN m136_tblHandbook h 
			ON h.iHandbookId = d.iHandbookId
		WHERE	d.iHandbookId = @iHandbookId
			AND d.iLatestApproved = 1
	UNION
		SELECT	v.iDocumentId as Id,
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
				h.iParentHandbookId
		FROM	m136_relVirtualRelation v
			INNER JOIN m136_tblDocument d 
				ON d.iDocumentId = v.iDocumentId
			INNER JOIN m136_tblHandbook h
				ON d.iHandbookId = h.iHandbookId
		WHERE	v.iHandbookId = @iHandbookId
			AND d.iLatestApproved = 1
	UNION
		SELECT	h.iHandbookId as Id,
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
				-2147483648 + h.iMin as iSort, -- Little trick with putting all the folders on top of documents sorted by iMin TODO - there can be a better way with the constant more importantly
				NULL as ParentFolderName,
				NULL as Path,
				0 as HasAttachment,
				NULL as iApproved,
				NULL as iDraft,
				h.iParentHandbookId
		FROM	m136_tblHandbook as h
		WHERE	(h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
			AND h.iDeleted = 0
	ORDER BY d.iSort ASC, 
			 d.strName ASC;
END
GO


IF OBJECT_ID('[dbo].[m136_be_GetChapterItems]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetChapterItems] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: AUGUST 05, 2015
-- Description:	Get chapter items including folders and documents
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetChapterItems]
	@iHandbookId INT = NULL,
	@iSecurityId INT
AS
BEGIN
	SET NOCOUNT ON;
    SELECT	strName as FolderName,
				iParentHandbookId as ParentId,
				dbo.fn136_GetParentPathEx(@iHandbookId) as Path,
				iLevel as Level,
				iViewTypeId as ViewType,
				iLevelType as LevelType,
				iDepartmentId as DepartmentId,
				strDescription
		FROM	m136_tblHandbook
		WHERE	iHandbookId = @iHandbookId AND @iHandbookId IS NOT NULL;
		
		SELECT	d.iDocumentId as Id,
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
				d.dtmPublish,
				d.dtmPublishUntil,
				dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) as iAccess,
				d.iCreatedbyId,
				dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
				h.iParentHandbookId
		FROM	m136_tblDocument d
		LEFT JOIN m136_tblHandbook h 
			ON h.iHandbookId = d.iHandbookId
		WHERE	d.iHandbookId = @iHandbookId
			AND d.iLatestVersion = 1
	UNION
		SELECT	v.iDocumentId as Id,
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
				d.dtmPublish,
				d.dtmPublishUntil,
				dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) as iAccess,
				d.iCreatedbyId,
				dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
				h.iParentHandbookId
		FROM	m136_relVirtualRelation v
			INNER JOIN m136_tblDocument d 
				ON d.iDocumentId = v.iDocumentId
			INNER JOIN m136_tblHandbook h
				ON d.iHandbookId = h.iHandbookId
		WHERE	v.iHandbookId = @iHandbookId
			AND d.iLatestVersion = 1
	UNION
		SELECT	h.iHandbookId as Id,
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
				-2147483648 + h.iMin as iSort, -- Little trick with putting all the folders on top of documents sorted by iMin TODO - there can be a better way with the constant more importantly
				NULL as ParentFolderName,
				NULL as Path,
				0 as HasAttachment,
				NULL as iApproved,
				NULL as iDraft,
				NULL as dtmPublish,
				NULL as dtmPublishUntil,
				dbo.fnSecurityGetPermission(136, 462, @iSecurityId, h.iHandbookId) as iAccess,
				h.iCreatedbyId,
				NULL as iVersionStatus,
				h.iParentHandbookId
		FROM	m136_tblHandbook as h
		WHERE	(h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
			AND h.iDeleted = 0
	ORDER BY d.iSort ASC, 
			 d.strName ASC;
END
GO

IF NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'ACLDatatable' AND ss.name = N'dbo')
	CREATE TYPE [dbo].[ACLDatatable] AS TABLE(
		[iEntityId] [int] NOT NULL,
		[iApplicationId] [int] NOT NULL,
		[iSecurityId] [int] NOT NULL,
		[iPermissionSetId] [int] NOT NULL,
		[iGroupingId] [int] NOT NULL,
		[iBit] [int] NOT NULL,
		[bRecursive] [bit] NOT NULL
	)
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateDepartmentPermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateDepartmentPermissions] AS SELECT 1')
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateDepartmentPermissions]
	@iDepartmentId INT,
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
	DELETE [dbo].[tblACL] WHERE iEntityId = @iDepartmentId 
		AND iApplicationId = @ApplicationId
		AND iPermissionSetId = @PermissionSetId 
		AND iSecurityId NOT IN (SELECT iSecurityId 
		FROM @Permissions);
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateDepartmentPermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateDepartmentPermissions] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_UpdateDepartmentPermissions]
	@iDepartmentId INT,
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
	DELETE [dbo].[tblACL] WHERE iEntityId = @iDepartmentId 
		AND iApplicationId = @ApplicationId
		AND iPermissionSetId = @PermissionSetId 
		AND iSecurityId NOT IN (SELECT iSecurityId 
		FROM @Permissions);
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
	@Permissions AS [dbo].[ACLDatatable] READONLY
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


IF OBJECT_ID('[dbo].[m136_be_UpdateFolderRolePermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateFolderRolePermissions] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: AUGUST 03, 2015
-- Description:	Update folder role permissions.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateFolderRolePermissions]
	@Permissions AS [dbo].[ACLDatatable] READONLY
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
			DECLARE @iHandbookId INT;
 			DECLARE RecursivePermissionSet CURSOR FOR 
			SELECT iHandbookId 
				, @iAppicationId
				, @iSecurityId
				, @iPermissionSetId
				, @iGroupingId
				, @iBit
			FROM dbo.m136_GetHandbookRecursive (@iEntityId, @iSecurityId, 0);
			
			OPEN RecursivePermissionSet; 
			FETCH NEXT FROM RecursivePermissionSet INTO @iHandbookId, @iAppicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit;
			WHILE @@FETCH_STATUS = 0
			BEGIN
				IF EXISTS(SELECT * FROM [dbo].[tblACL] 
					WHERE iEntityId = @iHandbookId 
						AND iApplicationId = @iAppicationId 
						AND iSecurityId = @iSecurityId 
						AND iPermissionSetId = @iPermissionSetId)
				BEGIN
					UPDATE [dbo].[tblACL]
					SET iBit = @iBit
					WHERE iEntityId = @iHandbookId 
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
					VALUES (@iHandbookId
						, @iAppicationId
						, @iSecurityId
						, @iPermissionSetId
						, 0
						, @iBit);
				END
			
				FETCH NEXT FROM RecursivePermissionSet INTO @iHandbookId, @iAppicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit;
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

IF  EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'SecurityDatatable' AND ss.name = N'dbo')
	DROP TYPE [dbo].[SecurityDatatable]
GO


IF OBJECT_ID('[dbo].[m136_be_UpdateFolderPermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateFolderPermissions] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JUNE 30, 2015
-- Last updated: SEP 07, 2015
-- Description:	Update folder permissions.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateFolderPermissions] 
	@Permissions AS [dbo].[ACLDatatable] READONLY
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
			DECLARE @iHandbookId INT;
 			DECLARE RecursivePermissionSet CURSOR FOR 
			SELECT iHandbookId 
				, @iAppicationId
				, @iSecurityId
				, @iPermissionSetId
				, @iGroupingId
				, @iBit
			FROM dbo.m136_GetHandbookRecursive (@iEntityId, @iSecurityId, 0);
			
			OPEN RecursivePermissionSet; 
			FETCH NEXT FROM RecursivePermissionSet INTO @iHandbookId, @iAppicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit;
			WHILE @@FETCH_STATUS = 0
			BEGIN
				IF EXISTS(SELECT * FROM [dbo].[tblACL] 
					WHERE iEntityId = @iHandbookId 
						AND iApplicationId = @iAppicationId 
						AND iSecurityId = @iSecurityId 
						AND iPermissionSetId = @iPermissionSetId)
				BEGIN
					UPDATE [dbo].[tblACL]
					SET iBit = @iBit
					WHERE iEntityId = @iHandbookId 
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
					VALUES (@iHandbookId
						, @iAppicationId
						, @iSecurityId
						, @iPermissionSetId
						, 0
						, @iBit);
				END
			
				FETCH NEXT FROM RecursivePermissionSet INTO @iHandbookId, @iAppicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit;
			END
			CLOSE RecursivePermissionSet;
			DEALLOCATE RecursivePermissionSet;
			DELETE [dbo].[tblACL] WHERE iEntityId = @iHandbookId 
				AND iApplicationId = @iAppicationId 
				AND iSecurityId NOT IN (SELECT iSecurityId 
				FROM @Permissions);
        END
        
		FETCH NEXT FROM PermissionSet INTO @iEntityId, @iAppicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit, @bRecursive;
	END
	CLOSE PermissionSet;
	DEALLOCATE PermissionSet;
	DELETE [dbo].[tblACL] WHERE iEntityId = @iEntityId 
		AND iApplicationId = @iAppicationId 
		AND iSecurityId NOT IN (SELECT iSecurityId 
		FROM @Permissions);
END
GO