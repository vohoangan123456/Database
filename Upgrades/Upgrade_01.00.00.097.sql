INSERT INTO #Description VALUES('Alter procefures for getting document templates and theirs fields.')
GO

IF OBJECT_ID('[dbo].[m136_be_GetDepartments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDepartments] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JUNE 24, 2015
-- Description:	Get all departments. 
--				Because the list of department does not long, so we will get all and paging on client if any.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetDepartments]
	@iDepartmentId INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    SELECT	dpt.iDepartmentId, 
			dpt.strName, 
			dpt.strDescription,
			dpt.iDepartmentParentId, 
			dpt.iLevel 
		FROM dbo.tblDepartment dpt
		WHERE ((@iDepartmentID IS NULL AND (dpt.iDepartmentParentId IS NULL OR dpt.iDepartmentParentId = 0)) 
			OR dpt.iDepartmentParentId = @iDepartmentID);
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetPermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetPermissions] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JULY 27, 2015
-- Description:	Get permissions
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetPermissions]
	@iPermissionSetId AS [dbo].[Item] READONLY,
	@iSecurityId INT
AS
BEGIN
	SET NOCOUNT ON;

	SELECT ta.iEntityId, ta.iSecurityId, ta.iPermissionSetId AS iAccessRights, ta.iBit FROM dbo.tblACL ta 
	WHERE ta.iApplicationId = 136 
		AND ta.iPermissionSetId IN (SELECT Id FROM @iPermissionSetId) 
		AND ta.iSecurityId = @iSecurityId;
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetTemplateMetaInfo]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetTemplateMetaInfo] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetTemplateMetaInfo] 
	@TemplateId INT
AS
BEGIN
	SELECT  dti.iDocumentTypeInfoId,
		mir.iMetaInfoTemplateRecordsId, 
		mir.strName,	
		mir.strDescription, 
		mir.iInfoTypeId,
		mir.iFlag,
		it.strName AS infoTypeName, 
		it.strDescription AS infoTypeDescription,
		dti.iDeleted,
		dti.iShowOnPDA,
		dti.iMandatory, 
		dti.iMaximized
	FROM [m136_tblMetaInfoTemplateRecords] mir
		INNER JOIN [m136_relDocumentTypeInfo] dti 
			ON dti.iDocumentTypeId = @TemplateId AND dti.iMetaInfoTemplateRecordsId = mir.iMetaInfoTemplateRecordsId
		LEFT JOIN [m136_tblInfoType] it 
			ON mir.iInfoTypeId = it.iInfoTypeId
	ORDER BY dti.iSort, it.strName;	
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentTypeById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentTypeById] AS SELECT 1')
GO
-- =============================================
-- Author:		em.lam.van.mai
-- Create date: July 09, 2015
-- Description:	Get a specified document type by Id
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetDocumentTypeById]
	@DocumentTypeId INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    SELECT  
        [iDocumentTypeId],
        [strName],
        [strDescription],
        [iDeleted],
        [Type],
        [HideFieldNumbering],
        [HideFieldName],
        [bIsProcess],
        [bInactive],
        [ViewMode],
        [strIcon],
        [iSort]                            
    FROM 
        [dbo].[m136_tblDocumentType] dt
    WHERE 
        [iDocumentTypeId] = @DocumentTypeId
END
GO

IF  NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'DocumentTypeInfoTable' AND ss.name = N'dbo')
	CREATE TYPE [dbo].[DocumentTypeInfoTable] AS TABLE(
	[iEntityId] [int] NOT NULL,
	[iDocumentTypeId] [int] NOT NULL,
	[iMetaInfoTemplateRecordsId] [int] NOT NULL,
	[iSort] [int] NOT NULL,
	[iDeleted] [int] NOT NULL,
	[iShowOnPDA] [int] NOT NULL,
	[iMandatory] [int] NOT NULL,
	[iMaximized] [int] NOT NULL
)
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateDocumentTemplateInfo]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateDocumentTemplateInfo] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JULY 31, 2015
-- Description:	Update document template information
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateDocumentTemplateInfo]
	@MetaInfo AS [dbo].[DocumentTypeInfoTable] READONLY
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @iEntityId INT, 
		@iDocumentTypeId INT, 
		@iMetaInfoTemplateRecordsId INT, 
		@iSort INT, 
		@iDeleted INT, 
		@iShowOnPDA INT,
		@iMandatory INT,
		@iMaximized INT;
	
	DECLARE Metainfo CURSOR FOR 
		SELECT iEntityId 
			, iDocumentTypeId
			, iMetaInfoTemplateRecordsId
			, iSort
			, iDeleted
			, iShowOnPDA
			, iMandatory
			, iMaximized
		FROM @MetaInfo;
		
	OPEN Metainfo; 
	FETCH NEXT FROM Metainfo INTO @iEntityId, @iDocumentTypeId, @iMetaInfoTemplateRecordsId, @iSort, @iDeleted, @iShowOnPDA, @iMandatory, @iMaximized;
	WHILE @@FETCH_STATUS = 0
    BEGIN
		IF EXISTS(SELECT * FROM  dbo.m136_relDocumentTypeInfo mrdti WHERE mrdti.iDocumentTypeInfoId = @iEntityId 
			OR (mrdti.iDocumentTypeId = @iDocumentTypeId AND mrdti.iMetaInfoTemplateRecordsId = @iMetaInfoTemplateRecordsId))
		BEGIN
			UPDATE dbo.m136_relDocumentTypeInfo
			SET
			    dbo.m136_relDocumentTypeInfo.iSort = @iSort,
			    dbo.m136_relDocumentTypeInfo.iDeleted = @iDeleted,
			    dbo.m136_relDocumentTypeInfo.iShowOnPDA = @iShowOnPDA,
			    dbo.m136_relDocumentTypeInfo.iMandatory = @iMandatory,
			    dbo.m136_relDocumentTypeInfo.iMaximized = @iMaximized
			WHERE (iDocumentTypeInfoId = @iEntityId) 
				OR (iDocumentTypeId = @iDocumentTypeId AND iMetaInfoTemplateRecordsId = @iMetaInfoTemplateRecordsId)
		END
		ELSE
		BEGIN
			DECLARE @NewDocumentTypeInfoId INT;
			SELECT @NewDocumentTypeInfoId = MAX(iDocumentTypeInfoId) FROM dbo.m136_relDocumentTypeInfo mrdti;
			
			SET IDENTITY_INSERT dbo.m136_relDocumentTypeInfo ON;
			INSERT INTO dbo.m136_relDocumentTypeInfo
			(
			    iDocumentTypeInfoId,
			    iDocumentTypeId,
			    iMetaInfoTemplateRecordsId,
			    iSort,
			    iDeleted,
			    iShowOnPDA,
			    iMandatory,
			    iMaximized
			)
			VALUES
			(
			    (@NewDocumentTypeInfoId + 1),
			    @iDocumentTypeId,
			    @iMetaInfoTemplateRecordsId,
			    @iSort,
			    @iDeleted,
			    @iShowOnPDA,
			    @iMandatory,
			    @iMaximized
			);
		END
		FETCH NEXT FROM Metainfo INTO @iEntityId, @iDocumentTypeId, @iMetaInfoTemplateRecordsId, @iSort, @iDeleted, @iShowOnPDA, @iMandatory, @iMaximized;
	END
	CLOSE Metainfo;
	DEALLOCATE Metainfo;
	
	DELETE [dbo].[m136_relDocumentTypeInfo] WHERE iDocumentTypeInfoId = @iDocumentTypeId
		AND iMetaInfoTemplateRecordsId NOT IN (SELECT iMetaInfoTemplateRecordsId 
		FROM @MetaInfo WHERE [@MetaInfo].iDocumentTypeId = @iDocumentTypeId);
END
GO

IF OBJECT_ID('[dbo].[m136_be_SearchFolders]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_SearchFolders] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_SearchFolders]
	@iUserId INT,
	@strName VARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON;

    SELECT iHandbookId AS Id
		, strName
		, iParentHandbookId AS iHandbookId
		, iLevel
		, iViewTypeId
		, iLevelType AS LevelType
		, iDepartmentId AS DepartmentId
		, [dbo].[fn136_GetParentPathExNew](iHandbookId) AS [Path]
		, -1 AS iDocumentTypeId
    FROM [dbo].[m136_tblHandbook]
    WHERE strName LIKE '%' + @strName + '%'
		AND [dbo].[fnHandbookHasReadContentsAccess](@iUserId, iHandbookId) = 1;
END
GO