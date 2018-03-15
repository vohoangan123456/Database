INSERT INTO #Description VALUES('Create stored procedures for document management.')
GO

IF OBJECT_ID('[dbo].[m136_be_GetProcessRelationType]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetProcessRelationType] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetProcessRelationType] 
	@iRelationTypeId INT
AS
BEGIN
	SET NOCOUNT ON;

    SELECT mtprt.* FROM dbo.m136_tblProcessRelationType mtprt
		WHERE mtprt.iRelationTypeId = @iRelationTypeId OR @iRelationTypeId IS NULL;
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
	
	SET @NewEntityId = @MaxEntityId + 1;
	DECLARE @CurrentDate DATETIME = GETDATE();
	
	UPDATE dbo.m136_tblDocument
	SET
	    dbo.m136_tblDocument.iLatestVersion = 0
	WHERE iDocumentId = @iDocumentId;
	
	SET IDENTITY_INSERT dbo.m136_tblDocument ON;
	
	INSERT INTO	dbo.m136_tblDocument(iEntityId, iDocumentId, iVersion, 
		iDocumentTypeId, iHandbookId, strName, strDescription, iCreatedById, dtmCreated, 
		strAuthor, iApprovedById, dtmApproved, strApprovedBy, dtmPublish, dtmPublishUntil, 
		iStatus, iSort, iDeleted, iApproved, iDraft, iLevelType, strHash, [UrlOrFileName], 
		[UrlOrFileProperties], dtmAlter, strAlterer, iAlterId, iReadCount, iLatestVersion)
	SELECT	@NewEntityId, iDocumentId, (@MaxVersion + 1), iDocumentTypeId, 
		iHandbookId, strName, strDescription, @iCreatedById, @CurrentDate, d.strAuthor, 
		0, null, '', d.dtmPublish, d.dtmPublishUntil, 0, iSort, iDeleted, 0, 1, iLevelType, 
		d.strHash, [UrlOrFileName], [UrlOrFileProperties], @CurrentDate, 
		[dbo].fnOrgGetUserName(@iCreatedById, '', 0), @iCreatedById, iReadCount, 1
	FROM		dbo.m136_tblDocument d
	WHERE		iEntityId = @iEntityId; 
	
	SET IDENTITY_INSERT dbo.m136_tblDocument OFF;
	
	SELECT @NewEntityId;
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

IF OBJECT_ID('[dbo].[m136_be_UpdateRelatedInfo]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateRelatedInfo] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: 23 SEP, 2015
-- Description:	Update related information.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateRelatedInfo] 
	@iOldEntityId INT,
	@iEntityId INT,
	@EnforceStrictVersionPolicyOnAttachments BIT
AS
BEGIN
	SET NOCOUNT ON;
	
	-- For related internal attachments.
	DECLARE @iRelationTypeId INT = 20;
    DELETE FROM [dbo].[m136_relInfo] WHERE iEntityId = @iEntityId 
											AND iRelationTypeId = @iRelationTypeId;
    
    INSERT INTO dbo.m136_relInfo
    (
        iEntityId,
        iItemId,
        iPlacementId,
        iSort,
        iRelationTypeId,
        iNewWindow,
        iProcessRelationTypeId
    )
    SELECT @iEntityId, 
		mri.iItemId, 
		mri.iPlacementId, 
		mri.iSort, 
		@iRelationTypeId, 
		mri.iNewWindow, 
		mri.iProcessRelationTypeId 
    FROM dbo.m136_relInfo mri 
    WHERE mri.iEntityId = @iOldEntityId 
		AND mri.iRelationTypeId = @iRelationTypeId;
    
    UPDATE dbo.m136_tblBlob
    SET
        bInUse = 1
    WHERE iItemId IN (SELECT mri.iItemId FROM dbo.m136_relInfo mri 
		WHERE mri.iEntityId = @iEntityId AND mri.iRelationTypeId = @iRelationTypeId);
    
    
    --For related documents
    SET @iRelationTypeId = 136;
    DELETE FROM [dbo].[m136_relInfo] WHERE iEntityId = @iEntityId
											AND iRelationTypeId = @iRelationTypeId;
    
    INSERT INTO dbo.m136_relInfo
    (
        iEntityId,
        iItemId,
        iPlacementId,
        iSort,
        iRelationTypeId,
        iNewWindow,
        iProcessRelationTypeId
    )
    SELECT @iEntityId, 
		mri.iItemId, 
		mri.iPlacementId, 
		mri.iSort, 
		@iRelationTypeId, 
		mri.iNewWindow, 
		mri.iProcessRelationTypeId 
    FROM dbo.m136_relInfo mri	
    WHERE mri.iEntityId = @iOldEntityId 
		AND mri.iRelationTypeId = @iRelationTypeId;
    
    
    -- For images and internal images
    DELETE FROM [dbo].[m136_relInfo] WHERE iEntityId = @iEntityId
											AND (iRelationTypeId = 5 OR @iRelationTypeId = 50);
	INSERT INTO [dbo].m136_relInfo(
		iEntityId, 
		iItemId, 
		iRelationTypeId, 
		iSort, 
		iNewWindow, 
		iScaleDirId, 
		iSize, 
		iVJustifyId, 
		iHJustifyId, 
		strCaption, 
		strURL, 
		iWidth, 
		iHeight,
		iThumbWidth, 
		iThumbHeight)
	SELECT @iEntityId, 
		mri.iItemId, 
		(CASE WHEN @EnforceStrictVersionPolicyOnAttachments = 1 THEN 50
		ELSE 5 END), 
		mri.iSort, 
		mri.iNewWindow, 
		mri.iScaleDirId, 
		mri.iSize, 
		mri.iVJustifyId, 
		mri.iHJustifyId, 
		mri.strCaption,
		mri.strURL,
		mri.iWidth,
		mri.iHeight,
		mri.iThumbWidth,
		mri.iThumbHeight 
	FROM dbo.m136_relInfo mri
	WHERE mri.iEntityId = @iOldEntityId 
		AND ((mri.iRelationTypeId = 5 AND @EnforceStrictVersionPolicyOnAttachments = 0) 
		     OR (mri.iRelationTypeId = 50 AND @EnforceStrictVersionPolicyOnAttachments = 1));
		
	IF (@EnforceStrictVersionPolicyOnAttachments = 1)
	BEGIN
		-- For internal images 
		UPDATE dbo.m136_tblBlob
		SET
		    bInUse = 1
		WHERE iItemId IN (SELECT mri.iItemId FROM dbo.m136_relInfo mri 
		WHERE mri.iEntityId = @iEntityId AND mri.iRelationTypeId = 50);
	END
END
GO


IF OBJECT_ID('[dbo].[m136_be_UpdateContentFields]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateContentFields] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: SEP 23, 2015
-- Description:	Update document field contents
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateContentFields] 
	@iOldEntityId INT,
	@iNewEntityId INT,
	@iDocumentTypeId INT
AS
BEGIN
	SET NOCOUNT ON;

	DELETE FROM [dbo].m136_tblMetaInfoRichText WHERE iEntityId = @iNewEntityId;
	DELETE FROM [dbo].m136_tblMetaInfoText WHERE iEntityId = @iNewEntityId;
	DELETE FROM [dbo].m136_tblMetaInfoNumber WHERE iEntityId = @iNewEntityId;
	DELETE FROM [dbo].m136_tblMetaInfoDate WHERE iEntityId = @iNewEntityId;
	
	DECLARE @iMetaRecordId INT, 
		@iInfoTypeId INT, 
		@DefaultTextValue VARCHAR(7000), 
		@DefaultDateValue DATETIME, 
		@DefaultIntValue INT;
		
	DECLARE Fields CURSOR FOR 
		SELECT DISTINCT 
		    mi.iMetaInfoTemplateRecordsId, 
			mi.iInfoTypeId, 
			mi.DefaultTextValue, 
			mi.DefaultDateValue, 
			mi.DefaultIntValue
		FROM [dbo].m136_tblMetaInfoTemplateRecords mi 
		JOIN [dbo].m136_relDocumentTypeInfo r ON r.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId 
			AND r.iDocumentTypeId = @iDocumentTypeId;
			
	OPEN Fields; 
	FETCH NEXT FROM Fields INTO @iMetaRecordId, @iInfoTypeId, @DefaultTextValue, @DefaultDateValue, @DefaultIntValue;
	WHILE @@FETCH_STATUS = 0
    BEGIN
		IF (@iInfoTypeId = 1)
		BEGIN
			INSERT INTO [dbo].m136_tblMetaInfoNumber
			(
				iMetaInfoTemplateRecordsId, 
				iEntityId, 
				[value]
			) 
			SELECT @iMetaRecordId, 
				@iNewEntityId, 
				ISNULL([Value], @DefaultIntValue)
			FROM dbo.m136_tblMetaInfoNumber mtmin 
				WHERE mtmin.iEntityId = @iOldEntityId AND mtmin.iMetaInfoTemplateRecordsId = @iMetaRecordId;		
		END
		
		IF (@iInfoTypeId = 2 OR @iInfoTypeId = 3 OR @iInfoTypeId = 4)
		BEGIN
			INSERT INTO [dbo].m136_tblMetaInfoText
			(
				iMetaInfoTemplateRecordsId, 
				iEntityId, 
				[value]
			)
			SELECT @iMetaRecordId, 
				@iNewEntityId, 
				ISNULL([Value], @DefaultTextValue)
			FROM dbo.m136_tblMetaInfoText mtmit 
				WHERE mtmit.iEntityId = @iOldEntityId AND mtmit.iMetaInfoTemplateRecordsId = @iMetaRecordId; 	
		END
		
		IF (@iInfoTypeId = 5)
		BEGIN
			INSERT INTO [dbo].m136_tblMetaInfoDate
			(
				iMetaInfoTemplateRecordsId, 
				iEntityId, 
				[value]
			) 
			SELECT @iMetaRecordId, 
				@iNewEntityId, 
				ISNULL([Value], @DefaultDateValue) 
			FROM dbo.m136_tblMetaInfoDate mtmid 
				WHERE mtmid.iEntityId = @iOldEntityId AND mtmid.iMetaInfoTemplateRecordsId = @iMetaRecordId;	
		END
		
		IF (@iInfoTypeId = 6)
		BEGIN
			INSERT INTO [dbo].m136_tblMetaInfoRichText
			(
				iMetaInfoTemplateRecordsId, 
				iEntityId, 
				[value]
			) 
			SELECT @iMetaRecordId, 
				@iNewEntityId, 
				ISNULL([Value], @DefaultTextValue)
			FROM dbo.m136_tblMetaInfoRichText mtmirt 
				WHERE mtmirt.iEntityId = @iOldEntityId AND mtmirt.iMetaInfoTemplateRecordsId = @iMetaRecordId;		
		END
		FETCH NEXT FROM Fields INTO @iMetaRecordId, @iInfoTypeId, @DefaultTextValue, @DefaultDateValue, @DefaultIntValue;
    END
    
    CLOSE Fields;
	DEALLOCATE Fields;
END
GO


IF OBJECT_ID('[dbo].[m136_be_InsertRelatedAttachment]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_InsertRelatedAttachment] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: SEP 23, 2015
-- Description:	Insert related attachments 
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_InsertRelatedAttachment] 
	@iEntityId			INT,
	@RelationTypeId		INT,
	@iItemId			INT,
	@strName			VARCHAR(300),
	@strDescription		VARCHAR(800),
	@iSize				INT,
	@strFileName		VARCHAR(200),
	@strContentType		VARCHAR(100),
	@strExtension		VARCHAR(100),
	@imgContent			[varbinary],
	@ProcessRelationTypeId INT
AS
BEGIN
	SET NOCOUNT ON;

    DECLARE @Sort INT

    SELECT @Sort = ISNULL(MAX(iSort) + 1, 1)
    FROM dbo.m136_relInfo
    WHERE iEntityId = @iEntityId
        AND iRelationTypeId = @RelationTypeId;
        
	DECLARE @MaxId INT;
	SELECT @MaxId = MAX(mtb.iItemId) FROM dbo.m136_tblBlob mtb; 
	SET @iItemId = (@MaxId + 1);
	
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
	
    INSERT INTO [dbo].m136_relInfo
        (iEntityId,
        iItemId,	                
        iProcessRelationTypeId,
        iRelationTypeId,
        iSort,
        iPlacementId)
    VALUES
        (@iEntityId,
        @iItemId,	                
        @ProcessRelationTypeId,
        @RelationTypeId,
        @Sort,
        0);
END
GO


IF OBJECT_ID('[dbo].[m136_be_GetRelatedInfoById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetRelatedInfoById] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: SEP 25, 2015
-- Description:	Get related information that includes internal attachments, internal images, related documents.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetRelatedInfoById] 
	@iEntityId			INT,
	@iRelationTypeId	INT,
	@iItemId			INT
AS
BEGIN
	SET NOCOUNT ON;

    SET NOCOUNT ON;
	SELECT r.iEntityId AS EntityId, 
		r.iItemId AS ItemId, 
		ISNULL(b.strName, d.strName) AS strName,
		ISNULL(r.iScaleDirId,0) AS iScaleDirId,
		ISNULL(r.iVJustifyId,0) AS iVJustifyId, 
		ISNULL(r.iHJustifyId,0) AS iHJustifyId, 
		ISNULL(r.iSize,0) AS Size,
		ISNULL(r.strCaption,'') AS strCaption, 
		ISNULL(r.iSort,0) AS iSort, 
		ISNULL(r.strURL,'') AS strUrl,
		ISNULL(r.iWidth,0) AS iWidth, 
		ISNULL(r.iHeight,0) AS iHeight, 
		ISNULL(r.iNewWindow,0) AS iNewWindow,
		b.strContentType AS strContentType, 
		CASE WHEN b.strExtension = '' THEN 'ukjent'
			ELSE b.strExtension
		END AS strExtension,
		ISNULL(r.iThumbWidth, 0) AS iThumbWidth, 
		ISNULL(r.iThumbHeight,0) AS iThumbHeight,
		r.iRelationTypeId, 
		r.iProcessrelationTypeId,
		b.imgContent, 
		b.strFileName, 
		ISNULL(b.strDescription, d.strDescription) AS strDescription
	FROM (SELECT *
		FROM [dbo].m136_relInfo
		WHERE iEntityId = @iEntityId
			AND iRelationTypeId = @iRelationTypeId                            
			AND iItemId = @iItemId) r
	LEFT JOIN [dbo].m136_tblBlob b ON r.iItemId = b.iItemId
		AND r.iRelationTypeId IN (20, 50, 55)
	LEFT JOIN dbo.m136_tblDocument d ON r.iItemId = d.iDocumentId
		AND r.iRelationTypeId = 136
		AND d.iLatestVersion = 1;
END
GO


IF OBJECT_ID('[dbo].[m136_be_UpdateRelatedAttachments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateRelatedAttachments] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: SEP 25, 2015
-- Description:	Update related attachments.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateRelatedAttachments] 
	@iEntityId				INT,
	@strName				VARCHAR(300),
	@strDescription			VARCHAR(800),
	@iSize					INT,
	@strFileName			VARCHAR(200),
	@strContentType			VARCHAR(100),	
	@strExtension			VARCHAR(10),
	@imgContent				[binary],
	@iItemId				INT,
	@iRelationTypeId		INT,
	@iProcessRelationTypeId INT
AS
BEGIN
	SET NOCOUNT ON;
	UPDATE [dbo].m136_tblBlob
	SET strName			= @strName,
		strDescription	= @strDescription,
		iSize			= @iSize,
		strFileName		= @strFileName,
		strContentType	= @strContentType,
		strExtension	= @strExtension,
		imgContent		= @imgContent
    WHERE iItemId = @iItemId;

    UPDATE [dbo].m136_relInfo
    SET
		iProcessRelationTypeId = @iProcessRelationTypeId
	WHERE iEntityId = @iEntityId
		AND iRelationTypeId = @iRelationTypeId                    
        AND iItemId = @iItemId;;
END
GO

IF OBJECT_ID('[dbo].[fn136_GetChildCount]', 'FN') IS NULL
    EXEC ('CREATE FUNCTION [dbo].[fn136_GetChildCount] () RETURNS INT AS BEGIN RETURN 1 END;')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: SEP 28. 2015
-- Description:	Get number of documents and folders of a folder
-- =============================================
ALTER FUNCTION [dbo].[fn136_GetChildCount] 
(
	@iSecurityId INT,
	@iHandbookId INT,
	@bShowDocumentsInTree BIT
)
RETURNS INT
AS
BEGIN
	
	DECLARE @ReturnVal INT

	IF (@bShowDocumentsInTree = 0)
	BEGIN
		SELECT @ReturnVal = COUNT(iHandbookId) FROM m136_tblHandbook WHERE iParentHandbookId = @iHandbookId AND iDeleted = 0 
			AND (dbo.fnSecurityGetPermission(136, 461, 1, iHandbookId) & 0x11) > 0;
    END
    ELSE
    BEGIN
		SET @ReturnVal = 
		      (SELECT COUNT(d.iDocumentId) 
					FROM m136_tblDocument d WHERE d.iHandbookId = @iHandbookId
						AND d.iLatestApproved = 1
						AND d.iApproved = 1
						AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, @iHandbookId) & 1) = 1 )
			+ (SELECT COUNT(d.iDocumentId) 
					FROM m136_tblDocument d INNER JOIN m136_relVirtualRelation v ON v.iHandbookId = @iHandbookId
						AND d.iDocumentId = v.iDocumentId
						AND d.iLatestApproved = 1
						AND iApproved = 1
						AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, @iHandbookId) & 1) = 1 
				)
			+ (SELECT COUNT(iHandbookId) 
					FROM m136_tblHandbook WHERE iParentHandbookId = @iHandbookId 
						AND iDeleted = 0 
						AND (dbo.fnSecurityGetPermission(136, 461, @iSecurityId, iHandbookId) & 0x11) > 0);
    END
	
	RETURN @ReturnVal;
END
GO


IF OBJECT_ID('[dbo].[m136_GetChapterItems]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetChapterItems] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetChapterItems] 
	@iHandbookId INT = NULL,
	@iSecurityId INT,
	@bShowDocumentsInTree BIT
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
				h.iParentHandbookId,
				0 AS iChildCount
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
				h.iParentHandbookId,
				0 AS iChildCount
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
				h.iParentHandbookId,
				[dbo].[fn136_GetChildCount] (@iSecurityId, h.iHandbookId, @bShowDocumentsInTree) AS iChildCount
		FROM	m136_tblHandbook as h
		WHERE	(h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
			AND h.iDeleted = 0
	ORDER BY d.iSort ASC, 
			 d.strName ASC;
END
GO


IF OBJECT_ID('[dbo].[m136_ProcessFeedback]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_ProcessFeedback] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_ProcessFeedback] 
	@SecurityId INT,
	@EntityId INT,
	@FeedbackMessage VARCHAR(4000),
	@RecipientsForMailFeedback INT
AS
BEGIN
	--Insert feedback
	INSERT INTO m136_tblFeedback(iEntityId, iEmployeeId, dtmFeedback, strFeedback)
		VALUES(@EntityId, @SecurityId , GETDATE(), @FeedbackMessage);
		
	DECLARE @CreatedById INT, @ApprovedId INT, @FolderId INT, @DocumentName VARCHAR(200), @DocumentId INT, @Version INT
	DECLARE @FromEmailAdress varchar(100)
	DECLARE @ToEmailAdress TABLE (email varchar(100))
	
	--Get document Infomation
	SELECT	@DocumentId = d.iDocumentId, 
			@DocumentName = d.strName,
			@FolderId = d.iHandbookId,
			@Version = d.iVersion,
			@CreatedById = d.iCreatedbyId,
			@ApprovedId = d.iApprovedById
	FROM	m136_tblDocument d
	WHERE	d.iEntityId = @EntityId	AND 
			d.iDeleted = 0;
			
	--Get Email from
	SELECT @FromEmailAdress = isNull(strEmail, '') 
	FROM tblEmployee 
	WHERE iEmployeeId = @SecurityId;
		
	INSERT INTO @ToEmailAdress 
		SELECT  isNull(strEmail, '') 
			FROM tblEmployee 
			WHERE iEmployeeId = @CreatedById;
	
	--Get Email To
	IF (@RecipientsForMailFeedback = 1)
	BEGIN
		INSERT INTO @ToEmailAdress 
			SELECT  isNull(strEmail, '') 
				FROM tblEmployee 
				WHERE iEmployeeId = @ApprovedId;	
	END
	ELSE IF (@RecipientsForMailFeedback = 0)
	BEGIN
		-- Get email of user have permisson approved
		INSERT INTO @ToEmailAdress 
			SELECT DISTINCT e.strEmail
				FROM tblEmployee e 
				JOIN relEmployeeSecGroup s ON e.iEmployeeId = s.iEmployeeId
				JOIN tblACL a ON s.iSecGroupId = a.iSecurityId AND
				a.iEntityId = @FolderId AND a.iApplicationId = 136 AND
				a.iPermissionSetId = 462 AND (a.iBit & 0x10) = 0x10
				AND e.strEmail IS NOT NULL AND e.strEmail <> '';
	END
	
	--return data
	SELECT @DocumentId AS DocumentId, @DocumentName AS Name, @Version AS [Version], @FromEmailAdress AS FromEmailAdress
	SELECT DISTINCT email AS Email 
	FROM @ToEmailAdress;
END
GO