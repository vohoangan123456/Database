INSERT INTO #Description VALUES ('Fix SP related to internet document')
GO

IF EXISTS (SELECT * 
  FROM sys.foreign_keys 
   WHERE object_id = OBJECT_ID(N'dbo.FK__tblACL_iSecurityId__tblSecGroup_iSecGroupId')
   AND parent_object_id = OBJECT_ID(N'dbo.tblACL')
)
BEGIN 
	ALTER TABLE [dbo].[tblACL] DROP CONSTRAINT [FK__tblACL_iSecurityId__tblSecGroup_iSecGroupId]
END
GO

IF OBJECT_ID('[dbo].[m136_be_CreateDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_CreateDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_CreateDocument] 
	 @HandbookId   INT,
	 @TemplateId   INT,
	 @DocumentType  INT,
	 @CreatorId   INT,
	 @AllowOffline  BIT,
	 @Title    NVARCHAR(MAX),
	 @Publish   DATETIME,
	 @PublishUntil  DATETIME
AS
BEGIN
	 SET NOCOUNT ON;
	 DECLARE @iMaxDocumentId INT = 0, @iMaxEntityId INT = 0, @Sort INT, @LevelType INT;
	 SELECT @LevelType = iLevelType FROM dbo.m136_tblHandbook WHERE iHandbookId = @HandbookId
	 SELECT @iMaxDocumentId = MAX(iDocumentId) FROM dbo.m136_tblDocument;
	 DECLARE @iNewDocumentId INT = ISNULL(@iMaxDocumentId, 0) + 1;
	 SELECT @iMaxEntityId = MAX(iEntityId) FROM dbo.m136_tblDocument;
	 DECLARE @iNewEntityId INT = ISNULL(@iMaxEntityId, 0) + 1;
	 SELECT @Sort = ISNULL(MAX(iSort) + 1, 0) FROM (SELECT 0 iSort
	   FROM dbo.m136_tblDocument d
	   WHERE d.iHandbookId = @HandbookId AND d.iDeleted = 0
	   AND d.iLatestVersion = 1
	  UNION all
	   SELECT 1 iSort
	   FROM dbo.m136_tblDocument d
	   WHERE d.iLatestVersion = 1) Temp
	   
	 SET IDENTITY_INSERT dbo.m136_tblDocument ON;
	 
	 INSERT INTO dbo.m136_tblDocument(
	  iEntityId,
	  iDocumentId,
	  iVersion,
	  iDocumentTypeId,
	  iHandbookId,
	  strName,
	  strDescription,
	  iCreatedbyId,
	  dtmCreated,
	  strAuthor,
	  iAlterId,
	  dtmAlter,
	  strAlterer,
	  iApprovedById,
	  strApprovedBy,
	  iStatus,
	  iSort,
	  iDeleted,
	  iApproved,
	  iDraft,
	  iLevelType,
	  strHash,
	  iReadCount,
	  iLatestVersion,
	  iLatestApproved,
	  dtmPublish,
	  dtmPublishUntil,
	  iInternetDoc) 
		VALUES(
	  @iNewEntityId,
	  @iNewDocumentId,
	  0,
	  @TemplateId,
	  @HandbookId,
	  @Title,
	  '',
	  @CreatorId,
	  GETDATE(),
	  [dbo].[fnOrgGetUserName] (@CreatorId, 'System', 0),
	  @CreatorId,
	  GETDATE(),
	  [dbo].[fnOrgGetUserName] (@CreatorId, 'System', 0),
	  0,
	  '',
	  0,
	  @Sort,
	  0,
	  0,
	  1,
	  @LevelType,
	  '',
	  0,
	  1,
	  0,
	  @Publish,
	  @PublishUntil,
	  0);
	  
	 SET IDENTITY_INSERT dbo.m136_tblDocument OFF;
	 SELECT @iNewDocumentId;
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetUserWithApprovePermissionOnDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetUserWithApprovePermissionOnDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetUserWithApprovePermissionOnDocument]
	 @DocumentId INT,
	 @IsInternetDocumentMode BIT
AS
BEGIN
	 DECLARE @HandBookId INT;
	 DECLARE @IsInternetDocument BIT;
	 SELECT
	  @HandBookId = iHandBookId,
	  @IsInternetDocument = iInternetDoc
	 FROM
	  dbo.m136_tblDocument
	 WHERE
	  iDocumentId = @DocumentId
			AND iLatestVersion = 1
	
	 SET @IsInternetDocument = ISNULL(@IsInternetDocument,0);	
	 
	 SELECT
	  e.iEmployeeId,
	  strFirstName,
	  strLastName,
	  strEmail,
	  e.strFirstName + ' ' + e.strLastName + ' - ' + [dbo].[fnGetAllDepartmentName](e.iEmployeeId) AS FullNameAndDepartmentName
	 FROM
	  dbo.tblEmployee AS e
	 WHERE
			(@IsInternetDocument = 0 AND dbo.fnSecurityGetPermission(136, 462, e.iEmployeeId, @HandBookId) & 16 = 16)
			OR (@IsInternetDocument = 1 AND 
				((@IsInternetDocumentMode = 0 AND dbo.fnSecurityGetPermission(136, 462, e.iEmployeeId, @HandBookId) & 16 = 16)
				OR (@IsInternetDocumentMode = 1 AND dbo.fnSecurityGetPermission(136, 460, e.iEmployeeId, 0) & 16 = 16)))
END
GO