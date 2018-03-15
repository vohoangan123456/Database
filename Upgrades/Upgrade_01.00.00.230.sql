INSERT INTO #Description VALUES('Update SPs with checking NULL identifier')
GO

IF OBJECT_ID('[dbo].[m136_be_CreateDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_CreateDocument] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_CreateDocument] 
	@HandbookId			INT,
	@TemplateId			INT,
	@DocumentType		INT,
	@CreatorId			INT,
	@AllowOffline		BIT,
	@Title				NVARCHAR(MAX),
	@Publish			DATETIME,
	@PublishUntil		DATETIME
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
		dtmPublishUntil) 
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
		@PublishUntil);
	SET IDENTITY_INSERT dbo.m136_tblDocument OFF;
	SELECT @iNewDocumentId;
END
GO



IF OBJECT_ID('[dbo].[m136_be_InsertImage]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_InsertImage] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_InsertImage] 
	@RelationTypeId	INT,
	@strName VARCHAR(300),
	@strDescription VARCHAR(800),
	@iSize INT,
	@strFileName VARCHAR(200),
	@strContentType VARCHAR(100),
	@strExtension VARCHAR(100),
	@ImgContent [image],
    @JsonImageContent NVARCHAR(MAX),
	@iHeight INT,
	@iWidth INT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @MaxId INT, @iItemId INT;
	SELECT @MaxId = MAX(mtb.iItemId) FROM dbo.m136_tblBlob mtb; 
	SET @iItemId = (ISNULL(@MaxId, 0) + 1);
	SET IDENTITY_INSERT dbo.m136_tblBlob ON;
    INSERT INTO
        [dbo].m136_tblBlob
            (iItemId, iInformationTypeId, strName, strDescription, iSize, strFileName, strContentType, strExtension, imgContent, JsonImageContent, bInUse, dtmRegistered, iWidth, iHeight)
        VALUES
            (@iItemId, @RelationTypeId, @strName, @strDescription, @iSize, @strFileName, @strContentType, @strExtension, @ImgContent, @JsonImageContent, 1, GETDATE(), @iWidth, @iHeight);
	SET IDENTITY_INSERT dbo.m136_tblBlob OFF;
	SELECT @iItemId;
END
GO



IF OBJECT_ID('[dbo].[m136_be_CreateDepartment]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_CreateDepartment] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_CreateDepartment] 
	@iDepartmentId INT,
	@strName VARCHAR(80),
	@bCompanyId BIT,
	@iDepartmentParentId INT,
	@iTargetId INT,
	@strDescription VARCHAR(4000),
	@strOrgNo VARCHAR(50),
	@strPhone VARCHAR(20),
	@strFax VARCHAR(20),
	@strEmail VARCHAR(150),
	@strURL VARCHAR(200),
	@iCountryId INT,
	@strVisitAddress1 VARCHAR(150),
	@strVisitAddress2 VARCHAR(150),
	@strVisitAddress3 VARCHAR(150),
	@strAddress1 VARCHAR(150),
	@strAddress2 VARCHAR(150),
	@strAddress3 VARCHAR(150)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @iMaxDepartmentId INT;
	SELECT @iMaxDepartmentId = MAX(dpt.iDepartmentId) FROM dbo.tblDepartment dpt;
	DECLARE @NewDerparmentId INT = ISNULL(@iMaxDepartmentId,0) + 1, @iParentLevel INT = 0, @bParentCompany BIT, @iParentCompanyId INT, @iNewCompanyId INT;
	
	SELECT @iParentLevel = dpt.iLevel, @bParentCompany = dpt.bCompany, @iParentCompanyId = dpt.iCompanyId 
		FROM dbo.tblDepartment dpt WHERE dpt.iDepartmentId = @iDepartmentParentId;
	
	IF (@bParentCompany = 1)
	BEGIN
		SET @iNewCompanyId = @iDepartmentParentId;
	END
	ELSE
	BEGIN
		SET @iNewCompanyId = @iParentCompanyId;
	END
	
	SET IDENTITY_INSERT dbo.tblDepartment ON;
	INSERT INTO dbo.tblDepartment
	(
       iDepartmentId,
       iDepartmentParentId,
       iCompanyId,
       iMin,
       iMax,
       iLevel,
       strName,
       strDescription,
       strContactInfo,
       bCompany,
       strPhone,
       strFax,
       strEmail,
       strURL,
       iCountryId,
       strOrgNo,
       strVisitAddress1,
       strVisitAddress2,
       strVisitAddress3,
       strAddress1,
       strAddress2,
       strAddress3,
       strFileURL,
       iChildCount,
       ADIdentifier
   )
   VALUES
   (
       @NewDerparmentId,-- iDepartmentId - int
       @iDepartmentParentId, -- iDepartmentParentId - int
       @iNewCompanyId, -- iCompanyId - int
       0, -- iMin - int
       0, -- iMax - int
       (@iParentLevel + 1), -- iLevel - int
       @strName, -- strName - varchar
       @strDescription, -- strDescription - varchar
       '', -- strContactInfo - varchar
       @bCompanyId, -- bCompany - bit
       @strPhone, -- strPhone - varchar
       @strFax, -- strFax - varchar
       @strEmail, -- strEmail - varchar
       @strURL, -- strURL - varchar
       @iCountryId, -- iCountryId - int
       @strOrgNo, -- strOrgNo - varchar
       @strVisitAddress1, -- strVisitAddress1 - varchar
       @strVisitAddress2, -- strVisitAddress2 - varchar
       @strVisitAddress3, -- strVisitAddress3 - varchar
       @strAddress1, -- strAddress1 - varchar
       @strAddress2, -- strAddress2 - varchar
       @strAddress3, -- strAddress3 - varchar
       '', -- strFileURL - varchar
       0, -- iChildCount - int
       '00000000-0000-0000-0000-000000000000' -- ADIdentifier - uniqueidentifier
   );
   
   SELECT @NewDerparmentId;
END
GO



IF OBJECT_ID('[dbo].[m136_be_CreateEmployee]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_CreateEmployee] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_CreateEmployee]
	@strEmployeeNo		VARCHAR(20),
	@iDepartmentId		INT,
	@strExpDep			VARCHAR(20),
	@strFirstName		VARCHAR(50),
	@strLastName		VARCHAR(50),
	@strTitle			VARCHAR(200),
	@strAddress			VARCHAR(150),
	@iCountryId			INT,
	@strPhoneHome		VARCHAR(30),
	@strPhoneInternal	VARCHAR(30),
	@strPhoneWork		VARCHAR(30),
	@strPhoneMobile		VARCHAR(30),
	@strBeeper			VARCHAR(20),
	@strCallNumber		VARCHAR(20),
	@strFax				VARCHAR(30),
	@strEmail			VARCHAR(100),
	@strLoginName		VARCHAR(100),
	@strLoginDomain		VARCHAR(200),
	@strPassword		VARCHAR(32),
	@strComment			VARCHAR(400)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @iMaxEmployeeId INT;
	SELECT @iMaxEmployeeId = MAX(te.iEmployeeId) FROM dbo.tblEmployee te;
	DECLARE @NewEmployeeId INT = ISNULL(@iMaxEmployeeId,0) + 1, @iParentCompanyId INT;
	SELECT @iParentCompanyId = dpt.iCompanyId FROM dbo.tblDepartment dpt WHERE dpt.iDepartmentId = @iDepartmentId;
	
	SET IDENTITY_INSERT dbo.tblEmployee ON;
    INSERT INTO dbo.tblEmployee
    (
        iEmployeeId,
        strEmployeeNo,
        iDepartmentId,
        strExpDep,
        dtmEmployed,
        strFirstName,
        strLastName,
        strTitle,
        strAddress1,
        strAddress2,
        strAddress3,
        iCountryId,
        strPhoneHome,
        strPhoneInternal,
        strPhoneWork,
        strPhoneMobile,
        strBeeper,
        strCallNumber,
        strFax,
        strEmail,
        strLoginName,
        strLoginDomain,
        strPassword,
        iCompanyId,
        bWizard,
        strComment,
        iImageId,
        bEmailConfirmed,
        strMailPassword,
        ADIdentifier,
        LastLogin,
        PreviousLogin
    )
    VALUES
    (
        @NewEmployeeId, -- iEmployeeId - int
        @strEmployeeNo, -- strEmployeeNo - varchar
        @iDepartmentId, -- iDepartmentId - int
        @strExpDep, -- strExpDep - varchar
        GETDATE(), -- dtmEmployed - smalldatetime
        @strFirstName, -- strFirstName - varchar
        @strLastName, -- strLastName - varchar
        @strTitle, -- strTitle - varchar
        @strAddress, -- strAddress1 - varchar
        '', -- strAddress2 - varchar
        '', -- strAddress3 - varchar
        @iCountryId, -- iCountryId - int
        @strPhoneHome, -- strPhoneHome - varchar
        @strPhoneInternal, -- strPhoneInternal - varchar
        @strPhoneWork, -- strPhoneWork - varchar
        @strPhoneMobile, -- strPhoneMobile - varchar
        @strBeeper, -- strBeeper - varchar
        @strCallNumber, -- strCallNumber - varchar
        @strFax, -- strFax - varchar
        @strEmail, -- strEmail - varchar
        @strLoginName, -- strLoginName - varchar
        @strLoginDomain, -- strLoginDomain - varchar
        @strPassword, -- strPassword - varchar
        @iParentCompanyId, -- iCompanyId - int
        0, -- bWizard - bit
        ISNULL(@strComment, ''), -- strComment - varchar
        0, -- iImageId - int
        0, -- bEmailConfirmed - bit
        '', -- strMailPassword - varchar
        '00000000-0000-0000-0000-000000000000', -- ADIdentifier - uniqueidentifier
        NULL, -- LastLogin - datetime
        NULL -- PreviousLogin - datetime
    );
	
    SET IDENTITY_INSERT dbo.tblEmployee OFF;
	
	SELECT @NewEmployeeId;
END
GO



IF OBJECT_ID('[dbo].[m136_be_CreateNewDocumentVersion]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_CreateNewDocumentVersion] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_CreateNewDocumentVersion]
    @iCreatedById    INT,
    @iEntityId       INT,
    @iDocumentId     INT
AS
BEGIN
	DECLARE @NewEntityId INT, @iExistEntityId INT;
	DECLARE @MaxEntityId INT, @MaxVersion INT;
	SELECT @MaxEntityId = MAX(mtd.iEntityId) FROM dbo.m136_tblDocument mtd;
	SELECT @MaxVersion = MAX(mtd.iVersion) FROM dbo.m136_tblDocument mtd WHERE mtd.iDocumentId = @iDocumentId;
	SET @NewEntityId = ISNULL(@MaxEntityId, 0) + 1;
	DECLARE @CurrentDate DATETIME = GETDATE();
	UPDATE dbo.m136_tblDocument
	SET
	    dbo.m136_tblDocument.iLatestVersion = 0
	WHERE iDocumentId = @iDocumentId;
	SET IDENTITY_INSERT dbo.m136_tblDocument ON;
	INSERT INTO	dbo.m136_tblDocument( [iEntityId],[iDocumentId],[iVersion],[iDocumentTypeId],[iHandbookId],[strName],[strDescription],[iCreatedbyId],[dtmCreated],[strAuthor]
								  ,[iAlterId],[dtmAlter],[strAlterer],[iApprovedById],[dtmApproved],[strApprovedBy],[dtmPublish],[dtmPublishUntil],[iStatus],[iSort]
								  ,[iDeleted],[iApproved],[iDraft],[iLevelType],[strHash],[iReadCount],[iCompareToVersion],[File],[UrlOrFileName],[UrlOrFileProperties]
								  ,[iLatestVersion],[iInternetDoc],[strNameReversed],[strDescriptionReversed]
								  )
	SELECT						   @NewEntityId,[iDocumentId],(ISNULL(@MaxVersion, 0) + 1),[iDocumentTypeId],[iHandbookId],[strName],[strDescription],@iCreatedById,@CurrentDate,[strAuthor]
								  ,@iCreatedById,@CurrentDate,[dbo].fnOrgGetUserName(@iCreatedById, '', 0),0,null,'',[dtmPublish],[dtmPublishUntil],0,[iSort]
								  ,[iDeleted],0,1,[iLevelType],[strHash],0,[iCompareToVersion],[File],[UrlOrFileName],[UrlOrFileProperties]
								  ,1,[iInternetDoc],[strNameReversed],[strDescriptionReversed]
	FROM		dbo.m136_tblDocument d
	WHERE		iEntityId = @iEntityId; 								  
	SET IDENTITY_INSERT dbo.m136_tblDocument OFF;
	SELECT @NewEntityId;
END
GO



IF OBJECT_ID('[dbo].[m136_be_CreateNewDocumentVersionWithDocumetTypeId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_CreateNewDocumentVersionWithDocumetTypeId] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_CreateNewDocumentVersionWithDocumetTypeId]
    @iCreatedById    INT,
    @iEntityId       INT,
    @iDocumentId     INT,
    @iDocumentTypeId INT
AS
BEGIN
	DECLARE @NewEntityId INT, @iExistEntityId INT;
	DECLARE @MaxEntityId INT, @MaxVersion INT;
	SELECT @MaxEntityId = MAX(mtd.iEntityId) FROM dbo.m136_tblDocument mtd;
	SELECT @MaxVersion = MAX(mtd.iVersion) FROM dbo.m136_tblDocument mtd WHERE mtd.iDocumentId = @iDocumentId;
	SET @NewEntityId = ISNULL(@MaxEntityId, 0) + 1;
	DECLARE @CurrentDate DATETIME = GETDATE();
	UPDATE dbo.m136_tblDocument
	SET
	    dbo.m136_tblDocument.iLatestVersion = 0
	WHERE iDocumentId = @iDocumentId;
	SET IDENTITY_INSERT dbo.m136_tblDocument ON;
	INSERT INTO	dbo.m136_tblDocument( [iEntityId],[iDocumentId],[iVersion],[iDocumentTypeId],[iHandbookId],[strName],[strDescription],[iCreatedbyId],[dtmCreated],[strAuthor]
								  ,[iAlterId],[dtmAlter],[strAlterer],[iApprovedById],[dtmApproved],[strApprovedBy],[dtmPublish],[dtmPublishUntil],[iStatus],[iSort]
								  ,[iDeleted],[iApproved],[iDraft],[iLevelType],[strHash],[iReadCount],[iCompareToVersion],[File],[UrlOrFileName],[UrlOrFileProperties]
								  ,[iLatestVersion],[iInternetDoc],[strNameReversed],[strDescriptionReversed]
								  )
	SELECT						   @NewEntityId,[iDocumentId],(ISNULL(@MaxVersion, 0) + 1),@iDocumentTypeId,[iHandbookId],[strName],[strDescription],@iCreatedById,@CurrentDate,[strAuthor]
								  ,@iCreatedById,@CurrentDate,[dbo].fnOrgGetUserName(@iCreatedById, '', 0),0,null,'',[dtmPublish],[dtmPublishUntil],0,[iSort]
								  ,[iDeleted],0,1,[iLevelType],[strHash],0,[iCompareToVersion],[File],[UrlOrFileName],[UrlOrFileProperties]
								  ,1,[iInternetDoc],[strNameReversed],[strDescriptionReversed]
	FROM		dbo.m136_tblDocument d
	WHERE		iEntityId = @iEntityId; 								  
	SET IDENTITY_INSERT dbo.m136_tblDocument OFF;
	RETURN @NewEntityId;
END
GO


IF OBJECT_ID('[dbo].[m136_be_InsertDocumentField]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_InsertDocumentField] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_InsertDocumentField]
	-- Add the parameters for the stored procedure here
	@strName VARCHAR(100),
	@strDescription VARCHAR(4000),
	@iInfoTypeId INT,
	@iFlag INT,
	@iFieldProcessType INT,
	@DefaultIntValue INT,
	@DefaultTextValue VARCHAR(7000),
	@DefaultDateValue DATETIME
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @iMaxDocumentFieldTypeId INT;
	SELECT @iMaxDocumentFieldTypeId = MAX(mtmitr.iMetaInfoTemplateRecordsId) FROM [dbo].[m136_tblMetaInfoTemplateRecords] mtmitr;
	DECLARE @NewDocumentFieldTypeId INT = (ISNULL(@iMaxDocumentFieldTypeId, 0) + 1);
	SET IDENTITY_INSERT dbo.m136_tblMetaInfoTemplateRecords ON;
	
    INSERT INTO dbo.m136_tblMetaInfoTemplateRecords
    (
        iMetaInfoTemplateRecordsId, -- this column value is auto-generated
        strName,
        strDescription,
        iInfoTypeId,
        DefaultIntValue,
        DefaultTextValue,
        DefaultDateValue,
        iFlag,
        iDeleted,
        iFieldProcessType
    )
    VALUES
    (
        @NewDocumentFieldTypeId, -- iMetaInfoTemplateRecordsId - int
        @strName, -- strName - varchar
        @strDescription, -- strDescription - varchar
        @iInfoTypeId, -- iInfoTypeId - int
        @DefaultIntValue, -- DefaultIntValue - int
        @DefaultTextValue, -- DefaultTextValue - varchar
        @DefaultDateValue, -- DefaultDateValue - datetime
        @iFlag, -- iFlag - int
        0, -- iDeleted - int
        @iFieldProcessType -- iFieldProcessType - int
    )
    
    SET IDENTITY_INSERT dbo.m136_tblMetaInfoTemplateRecords OFF;
	
	SELECT @NewDocumentFieldTypeId;
END
GO



IF OBJECT_ID('[dbo].[m136_be_InsertDocumentTemplate]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_InsertDocumentTemplate] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_InsertDocumentTemplate]
	-- Add the parameters for the stored procedure here
	@strName VARCHAR(100),
	@strDescription VARCHAR(4000),
	@bIsProcess BIT,
	@bInactive BIT,
	@ViewMode INT,
	@Type INT,
	@HideFieldNumbering BIT,
	@HideFieldName BIT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @iMaxDocumentTypeId INT, @iMaxiSort INT;
	
	SELECT @iMaxDocumentTypeId = MAX(dt.iDocumentTypeId), @iMaxiSort = MAX(iSort) FROM [dbo].[m136_tblDocumentType] dt;
	DECLARE @NewDocumentTypeId INT = (ISNULL(@iMaxDocumentTypeId, 0) + 1);
	SET IDENTITY_INSERT dbo.m136_tblDocumentType ON;
	
    INSERT INTO  dbo.m136_tblDocumentType
    (
        iDocumentTypeId, -- this column value is auto-generated
        strName,
        strDescription,
        iDeleted,
        strIcon,
        bIsProcess,
        bInactive,
        ViewMode,
        [Type],
        HideFieldNumbering,
        HideFieldName,
        iSort
    )
    VALUES
    (
        @NewDocumentTypeId,
        @strName, 
        @strDescription, 
        0, 
        '', 
        @bIsProcess, 
        @bInactive, 
        @ViewMode, 
        @Type, 
        @HideFieldNumbering, 
        @HideFieldName, 
        (ISNULL(@iMaxiSort, 0) + 1) 
    );
    
    SET IDENTITY_INSERT dbo.m136_tblDocumentType OFF;
    
    SELECT @NewDocumentTypeId;
    
END
GO



IF OBJECT_ID('[dbo].[m136_be_InsertFolder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_InsertFolder] AS SELECT 1')
GO
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
	SELECT @iParentLevel = h.iLevel FROM dbo.m136_tblHandbook h WHERE h.iHandbookId = @iParentHandbookId;
	SELECT @iMaxHandbookId = MAX(ihandbookid) FROM dbo.m136_tblHandbook;
	DECLARE @iNewHandbookId INT = ISNULL(@iMaxHandbookId, 0) + 1;
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
	SET IDENTITY_INSERT dbo.m136_tblHandbook OFF;
	DECLARE @iEntityId INT, @iApplicationId INT, @iSecurityId INT, @iPermisionSetId INT, @iGroupingId INT, @iBit INT
	DECLARE ACL CURSOR FOR 
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
	OPEN ACL; 
	FETCH NEXT FROM ACL INTO @iEntityId, @iApplicationId, @iSecurityId, @iPermisionSetId, @iGroupingId, @iBit;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF NOT EXISTS(SELECT * FROM dbo.tblACL WHERE iEntityId = @iEntityId 
			AND iApplicationId = @iApplicationId 
			AND iSecurityId = @iSecurityId 
			AND iPermissionSetId  = @iPermisionSetId)
		BEGIN
			INSERT INTO dbo.tblACL VALUES (
			     @iEntityId
				, @iApplicationId
				, @iSecurityId
				, @iPermisionSetId
				, @iGroupingId
				, @iBit);
		END
		ELSE 
		BEGIN
			UPDATE dbo.tblACL
				SET iBit = @iBit,
					iGroupingId = @iGroupingId
			WHERE iEntityId = @iEntityId 
			AND iApplicationId = @iApplicationId 
			AND iSecurityId = @iSecurityId 
			AND iPermissionSetId  = @iPermisionSetId
		END
		FETCH NEXT FROM ACL INTO @iEntityId, @iApplicationId, @iSecurityId, @iPermisionSetId, @iGroupingId, @iBit;
	END
	CLOSE ACL;
	DEALLOCATE ACL;
	SELECT @iNewHandbookId;
END
GO


IF OBJECT_ID('[dbo].[m136_be_InsertRelatedAttachment]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_InsertRelatedAttachment] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_InsertRelatedAttachment] 
	@RelationTypeId		INT,
	@iItemId			INT,
	@strName			VARCHAR(300),
	@strDescription		VARCHAR(800),
	@iSize				INT,
	@strFileName		VARCHAR(200),
	@strContentType		VARCHAR(100),
	@strExtension		VARCHAR(100),
	@imgContent			[image]
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @MaxId INT;
	SELECT @MaxId = MAX(mtb.iItemId) FROM dbo.m136_tblBlob mtb; 
	SET @iItemId = (ISNULL(@MaxId, 0) + 1);
	
	SET IDENTITY_INSERT dbo.m136_tblBlob ON;
    INSERT INTO [dbo].m136_tblBlob
        (iItemId,
        iInformationTypeId,
        strName,
        strDescription,
        iSize,
        strFileName,
        strContentType,
        strExtension,
        imgContent,
        bInUse,
        dtmRegistered,
        iWidth,
        iHeight)
    VALUES
        (@iItemId,
        @RelationTypeId,
        @strName,
        @strDescription,
        @iSize,
        @strFileName,
        @strContentType,
        @strExtension,
        @imgContent,
        1,
        GETDATE(),
        0,
        0);
	SET IDENTITY_INSERT dbo.m136_tblBlob OFF;
	SELECT @iItemId;
END
GO


IF OBJECT_ID('[dbo].[m136_be_InsertSecurityGroup]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_InsertSecurityGroup] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_InsertSecurityGroup]
	@strName VARCHAR(50),
	@strDescription VARCHAR(1000)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @iMaxSecGroupId INT;
	SELECT @iMaxSecGroupId = MAX(tsg.iSecGroupId) FROM  dbo.tblSecGroup tsg;
	DECLARE @NewSecGroupId INT = (ISNULL(@iMaxSecGroupId, 0) + 1);
	
	INSERT INTO dbo.tblSecGroup
	(
	    iSecGroupId,
	    strName,
	    strDescription
	)
	VALUES
	(
	    @NewSecGroupId, -- iSecGroupId - int
	    @strName, -- strName - varchar
	    @strDescription -- strDescription - varchar
	);
	
	SELECT @NewSecGroupId;
END
GO



IF OBJECT_ID('[dbo].[m136_be_UpdateDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateDocument] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_UpdateDocument] 
	@iEntityId				INT,
	@strName				VARCHAR(200),
	@RelatedAttachments		AS [dbo].[RelatedInfoTable] READONLY,
	@RelatedDocuments		AS [dbo].[RelatedInfoTable] READONLY,
	@FieldContents			AS [dbo].[FieldContent] READONLY,
	@File					[image],
	@UrlOrFileName			NVARCHAR(4000),
	@UrlOrFileProperties	NVARCHAR(4000),
	@strDescription			NVARCHAR(2000),
	@strAuthor				VARCHAR(200),
	@dtmPublish				DATETIME,
	@dtmPublishUntil		DATETIME,
	@iCompareToVersion		INT,
	@iInternetDoc			INT,
	@iHandbookId			INT
AS
BEGIN
	SET NOCOUNT ON;
	UPDATE dbo.m136_tblDocument
	SET [strName]				= @strName,
		[File]					= @File,
		[UrlOrFileName]			= @UrlOrFileName,
		[UrlOrFileProperties]	= @UrlOrFileProperties,
		[strDescription]		= @strDescription,
		[strAuthor]				= @strAuthor,
		[dtmPublish]			= @dtmPublish,
		[dtmPublishUntil]		= @dtmPublishUntil,
		[iCompareToVersion]		= @iCompareToVersion,
		[iInternetDoc]			= @iInternetDoc,
		[iHandbookId]			= @iHandbookId
	WHERE iEntityId = @iEntityId;   
	UPDATE r
		SET r.iSort = rd.iSort,
		r.iPlacementId = rd.iPlacementId,
		r.iProcessRelationTypeId = rd.iProcessRelationTypeId
	FROM dbo.m136_relInfo r INNER JOIN @RelatedDocuments rd 
		ON r.iItemId = rd.iItemId
	WHERE r.iEntityId = @iEntityId
		AND r.iRelationTypeId = 136; -- HandbookRelationTypes.Document = 136  
    UPDATE r
		SET r.iSort = rd.iSort,
		r.iPlacementId = rd.iPlacementId,
		r.iProcessRelationTypeId = rd.iProcessRelationTypeId
	FROM dbo.m136_relInfo r INNER JOIN @RelatedAttachments rd 
		ON r.iItemId = rd.iItemId
	WHERE r.iEntityId = @iEntityId
		AND r.iRelationTypeId IN (2, 20); -- 2: attachment, 20: related attachment
	DECLARE @iDocumentTypeId INT, 
		@iMetaInfoTemplateRecordsId INT,
		@iInfoTypeId INT,
		@RichText [nvarchar](MAX),
		@Text VARCHAR(8000),
		@Number INT,
		@Date DATETIME;
	SELECT @iDocumentTypeId = d.iDocumentTypeId FROM dbo.m136_tblDocument d
	WHERE d.iEntityId = @iEntityId;
	DECLARE FieldContens CURSOR FOR 
		SELECT [iMetaInfoTemplateRecordsId], [iInfoTypeId], [RichText], [Text], [Number], [Date]
		FROM @FieldContents;
	OPEN FieldContens; 
	FETCH NEXT FROM FieldContens INTO @iMetaInfoTemplateRecordsId, @iInfoTypeId, @RichText, @Text, @Number, @Date;
	WHILE @@FETCH_STATUS = 0
    BEGIN
		IF (@iInfoTypeId = 1)
		BEGIN
			IF EXISTS(SELECT * FROM dbo.m136_tblMetaInfoNumber mtmin
				INNER JOIN dbo.m136_relDocumentTypeInfo mrdti ON mrdti.iMetaInfoTemplateRecordsId = mtmin.iMetaInfoTemplateRecordsId
				WHERE mtmin.iEntityId = @iEntityId AND mrdti.iDocumentTypeId = @iDocumentTypeId
				AND mtmin.iMetaInfoTemplateRecordsId = @iMetaInfoTemplateRecordsId)
			BEGIN
     			UPDATE mtmin 
				SET
					mtmin.[value] = ISNULL(@Number, 0)
				FROM dbo.m136_tblMetaInfoNumber mtmin
				INNER JOIN dbo.m136_relDocumentTypeInfo mrdti ON mrdti.iMetaInfoTemplateRecordsId = mtmin.iMetaInfoTemplateRecordsId
				AND mrdti.iDocumentTypeId = @iDocumentTypeId
				AND mtmin.iEntityId = @iEntityId
				AND mtmin.iMetaInfoTemplateRecordsId = @iMetaInfoTemplateRecordsId;
            END
            ELSE
            BEGIN
				DECLARE @iMaxiMetaInfoNumberId INT;
				SELECT @iMaxiMetaInfoNumberId = MAX(mtmin.iMetaInfoNumberId) FROM dbo.m136_tblMetaInfoNumber mtmin;
				SET IDENTITY_INSERT dbo.m136_tblMetaInfoNumber ON;
				INSERT INTO dbo.m136_tblMetaInfoNumber
				(
				    iMetaInfoNumberId,
				    iMetaInfoTemplateRecordsId,
				    iEntityId,
				    [value]
				)
				VALUES
				(
				    (ISNULL(@iMaxiMetaInfoNumberId, 0) + 1),
				    @iMetaInfoTemplateRecordsId,
				    @iEntityId,
				    ISNULL(@Number, 0)
				)
				SET IDENTITY_INSERT dbo.m136_tblMetaInfoNumber OFF;
            END
		END
		IF (@iInfoTypeId = 2 OR @iInfoTypeId = 3 OR @iInfoTypeId = 4)
		BEGIN
			IF EXISTS(SELECT * FROM dbo.m136_tblMetaInfoText mtmit
				INNER JOIN dbo.m136_relDocumentTypeInfo mrdti ON mrdti.iMetaInfoTemplateRecordsId = mtmit.iMetaInfoTemplateRecordsId
				WHERE mtmit.iEntityId = @iEntityId AND mrdti.iDocumentTypeId = @iDocumentTypeId
				AND mtmit.iMetaInfoTemplateRecordsId = @iMetaInfoTemplateRecordsId)
			BEGIN
     			UPDATE mtmit 
				SET
					mtmit.[value] = ISNULL(@Text, '')
				FROM dbo.m136_tblMetaInfoText mtmit
				INNER JOIN dbo.m136_relDocumentTypeInfo mrdti ON mrdti.iMetaInfoTemplateRecordsId = mtmit.iMetaInfoTemplateRecordsId
				AND mrdti.iDocumentTypeId = @iDocumentTypeId
				AND mtmit.iMetaInfoTemplateRecordsId = @iMetaInfoTemplateRecordsId
				AND mtmit.iEntityId = @iEntityId;
            END
            ELSE
            BEGIN
				DECLARE @iMaxiMetaInfoTextId INT;
				SELECT @iMaxiMetaInfoTextId = MAX(mtmit.iMetaInfoTextId) FROM dbo.m136_tblMetaInfoText mtmit;
				SET IDENTITY_INSERT dbo.m136_tblMetaInfoText ON;
				INSERT INTO dbo.m136_tblMetaInfoText
				(
				    iMetaInfoTextId,
				    iMetaInfoTemplateRecordsId,
				    iEntityId,
				    [value]
				)
				VALUES
				(
				    (ISNULL(@iMaxiMetaInfoTextId, 0) + 1),
				    @iMetaInfoTemplateRecordsId, 
				    @iEntityId, 
				    ISNULL(@Text, '')
				)
				SET IDENTITY_INSERT dbo.m136_tblMetaInfoText OFF;
            END
		END
		IF (@iInfoTypeId = 5)
		BEGIN
			IF EXISTS(SELECT * FROM dbo.m136_tblMetaInfoDate mtmid
				INNER JOIN dbo.m136_relDocumentTypeInfo mrdti ON mrdti.iMetaInfoTemplateRecordsId = mtmid.iMetaInfoTemplateRecordsId
				WHERE mtmid.iEntityId = @iEntityId AND mrdti.iDocumentTypeId = @iDocumentTypeId
				AND mtmid.iMetaInfoTemplateRecordsId = @iMetaInfoTemplateRecordsId)
			BEGIN
     			UPDATE mid 
				SET
					mid.[value] = @Date
				FROM dbo.m136_tblMetaInfoDate mid
				INNER JOIN dbo.m136_relDocumentTypeInfo mrdti ON mrdti.iMetaInfoTemplateRecordsId = mid.iMetaInfoTemplateRecordsId
				AND mrdti.iDocumentTypeId = @iDocumentTypeId
				AND mid.iMetaInfoTemplateRecordsId = @iMetaInfoTemplateRecordsId
				AND mid.iEntityId = @iEntityId;	
            END
            ELSE
            BEGIN
				DECLARE @iMaxiMetaInfoDateId INT;
				SELECT @iMaxiMetaInfoDateId = MAX(mtmit.iMetaInfoDateId) FROM dbo.m136_tblMetaInfoDate mtmit;
				SET IDENTITY_INSERT dbo.m136_tblMetaInfoDate ON;
				INSERT INTO dbo.m136_tblMetaInfoDate
				(
				    iMetaInfoDateId,
				    iMetaInfoTemplateRecordsId,
				    iEntityId,
				    [value]
				)
				VALUES
				(
				    (@iMaxiMetaInfoDateId + 1),
				    @iMetaInfoTemplateRecordsId,
				    @iEntityId,
				    ISNULL(@Date, GETDATE())
				)
				SET IDENTITY_INSERT dbo.m136_tblMetaInfoDate OFF;
            END
		END
		IF (@iInfoTypeId = 6)
		BEGIN
			IF EXISTS(SELECT * FROM dbo.m136_tblMetaInfoRichText mtmirt
				INNER JOIN dbo.m136_relDocumentTypeInfo mrdti ON mrdti.iMetaInfoTemplateRecordsId = mtmirt.iMetaInfoTemplateRecordsId
				WHERE mtmirt.iEntityId = @iEntityId AND mrdti.iDocumentTypeId = @iDocumentTypeId
				AND mtmirt.iMetaInfoTemplateRecordsId = @iMetaInfoTemplateRecordsId)
			BEGIN
     			UPDATE mtmirt 
				SET
					mtmirt.[value] = ISNULL(@RichText, '')
				FROM dbo.m136_tblMetaInfoRichText mtmirt
				INNER JOIN dbo.m136_relDocumentTypeInfo mrdti ON mrdti.iMetaInfoTemplateRecordsId = mtmirt.iMetaInfoTemplateRecordsId
				AND mrdti.iDocumentTypeId = @iDocumentTypeId
				AND mtmirt.iMetaInfoTemplateRecordsId = @iMetaInfoTemplateRecordsId
				AND mtmirt.iEntityId = @iEntityId;	
            END
            ELSE
            BEGIN
				DECLARE @iMaxiMetaInfoRichTextId INT;
				SELECT @iMaxiMetaInfoRichTextId = MAX(mtmirt.iMetaInfoRichTextId) FROM dbo.m136_tblMetaInfoRichText mtmirt;
				SET IDENTITY_INSERT dbo.m136_tblMetaInfoRichText ON;
				INSERT INTO dbo.m136_tblMetaInfoRichText
				(
				    iMetaInfoRichTextId,
				    iMetaInfoTemplateRecordsId,
				    iEntityId,
				    [value]
				)
				VALUES
				(
				    (ISNULL(@iMaxiMetaInfoRichTextId, 0) + 1),
				    @iMetaInfoTemplateRecordsId,
				    @iEntityId,
				    ISNULL(@RichText, '')
				)
				SET IDENTITY_INSERT dbo.m136_tblMetaInfoRichText OFF;
            END
		END
		FETCH NEXT FROM FieldContens INTO @iMetaInfoTemplateRecordsId, @iInfoTypeId, @RichText, @Text, @Number, @Date;
    END
    CLOSE FieldContens;
	DEALLOCATE FieldContens;	
END
GO


IF OBJECT_ID('[dbo].[m123_be_AddNewsRelatedAttachment]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m123_be_AddNewsRelatedAttachment] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m123_be_AddNewsRelatedAttachment]
    @RelationTypeId INT,
    @Name VARCHAR(300),
    @Description VARCHAR(800),
    @Size INT,
    @FileName VARCHAR(200),
    @ContentType VARCHAR(100),
    @Extension VARCHAR(100),
    @ImgContent [image]
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @MaxId INT;
    DECLARE @ItemId INT;
    SELECT @MaxId = MAX(iItemId) FROM dbo.m136_tblBlob;
    SET @ItemId = ISNULL(@MaxId, 0) + 1;
    SET IDENTITY_INSERT dbo.m136_tblBlob ON;
    INSERT INTO
        m136_tblBlob
            (iItemId, iInformationTypeId, strName, strDescription, iSize, strFileName, strContentType, strExtension, imgContent, bInUse, dtmRegistered, iWidth, iHeight)
        VALUES
            (@ItemId, @RelationTypeId, @Name, @Description, @Size, @FileName, @ContentType, @Extension, @ImgContent, 1, GETDATE(), 0, 0);
    SET IDENTITY_INSERT dbo.m136_tblBlob OFF;
	SELECT @ItemId;
END
GO


IF OBJECT_ID('[dbo].[m136_be_AddEventLog]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_AddEventLog] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_AddEventLog]
	@DocumentId INT,
    @Version INT,
    @Description VARCHAR(MAX),
    @EmployeeId INT,
    @LoginName VARCHAR(100),
    @FirstName VARCHAR(50),
    @LastName VARCHAR(50),
    @EventTime DATETIME,
    @EventType INT
AS
BEGIN
	SET NOCOUNT ON;
	SET IDENTITY_INSERT dbo.tblEventlog ON;
	DECLARE @MaxId INT;
	SELECT @MaxId = MAX(te.Id) FROM dbo.tblEventlog te;
	
	INSERT INTO dbo.tblEventlog
	(
	    Id,
	    DocumentId,
	    [Version],
	    EmployeeId,
	    LoginName,
	    FirstName,
	    LastName,
	    EventTime,
	    EventType,
	    [Description]
	)
	VALUES
	(
	    (ISNULL(@MaxId, 0) + 1),
	    @DocumentId,
	    @Version,
	    @EmployeeId,
	    @LoginName, 
	    @FirstName, 
	    @LastName, 
	    @EventTime,
	    @EventType,
	    @Description
	)
	
	SET IDENTITY_INSERT dbo.tblEventlog OFF;
END
GO