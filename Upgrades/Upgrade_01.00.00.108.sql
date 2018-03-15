INSERT INTO #Description VALUES('Create stored procedures for document management.')
GO

IF OBJECT_ID('[dbo].[fn136_be_GetChildCount]', 'FN') IS NULL
    EXEC ('CREATE FUNCTION [dbo].[fn136_be_GetChildCount] () RETURNS INT AS BEGIN RETURN 1 END;')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: OCT 05. 2015
-- Description:	Get number of documents and folders of a folder
-- =============================================
ALTER FUNCTION [dbo].[fn136_be_GetChildCount] 
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
		SELECT @ReturnVal = COUNT(iHandbookId) FROM m136_tblHandbook WHERE iParentHandbookId = @iHandbookId 
			AND iDeleted = 0 
			AND (dbo.fnSecurityGetPermission(136, 461, 1, iHandbookId) & 0x11) > 0;
    END
    ELSE
    BEGIN
		SET @ReturnVal = 
		      (SELECT COUNT(d.iDocumentId) 
					FROM m136_tblDocument d WHERE d.iHandbookId = @iHandbookId
						AND d.iLatestVersion = 1
						AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, @iHandbookId) & 1) = 1 )
			+ (SELECT COUNT(d.iDocumentId) 
					FROM m136_tblDocument d INNER JOIN m136_relVirtualRelation v ON v.iHandbookId = @iHandbookId
						AND d.iDocumentId = v.iDocumentId
						AND d.iLatestVersion = 1
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


IF OBJECT_ID('[dbo].[m136_be_InsertRelatedDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_InsertRelatedDocument] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: OCT 05, 2015
-- Description:	Insert related document
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_InsertRelatedDocument] 
	@iEntityId				INT,
	@iItemId				INT,
	@iProcessRelationTypeId INT,
	@iRelationTypeId		INT,
	@iPlacementId			INT
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @Sort INT

	SELECT @Sort = ISNULL(MAX(iSort) + 1, 1)
	FROM dbo.m136_relInfo
	WHERE iEntityId = @iEntityId
		AND iRelationTypeId = @iRelationTypeId
	    

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
		@iProcessRelationTypeId,
		@iRelationTypeId,
		@Sort,
		@iPlacementId)
END
GO


IF OBJECT_ID('[dbo].[m136_be_UpdateRelatedDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateRelatedDocument] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: OCT 06, 2015
-- Description:	Update related document
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateRelatedDocument] 
	@iEntityId				INT,
	@iItemId				INT,
	@iRelationTypeId		INT,
	@iProcessRelationTypeId INT
AS
BEGIN
	SET NOCOUNT ON;

    UPDATE [dbo].m136_relInfo
        SET iProcessRelationTypeId = @iProcessRelationTypeId
        WHERE iEntityId = @iEntityId
            AND iRelationTypeId = @iRelationTypeId                    
            AND iItemId = @iItemId;
END
GO


IF OBJECT_ID('[dbo].[m136_be_DeleteRelatedInfo]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteRelatedInfo] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: OCT 06, 2015
-- Description:	Delete related information that includes attachment, document, images.
--              For types not document we have to delete tblBlob as well.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_DeleteRelatedInfo]
	@iEntityId			INT,
	@iItemIds			dbo.Item READONLY,
	@iRelationTypeId	INT
AS
BEGIN
	SET NOCOUNT ON;

    DELETE dbo.m136_relInfo
        WHERE iEntityId = @iEntityId
        AND iRelationTypeId = @iRelationTypeId
        AND iItemId IN (SELECT Id FROM @iItemIds);

    IF (@iRelationTypeId <> 136)
    BEGIN
		DELETE dbo.m136_tblBlob
			WHERE iItemId IN (SELECT Id FROM @iItemIds);
    END
END
GO


IF OBJECT_ID('[dbo].[m136_be_GetDocumentFieldsAndRelates]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentFieldsAndRelates] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetDocumentFieldsAndRelates]
	@iEntityId INT
AS
BEGIN
	DECLARE @DocumentTypeId INT, @IsProcess BIT;
	
	SELECT	@DocumentTypeId = d.iDocumentTypeId,
			@IsProcess = t.bIsProcess
	FROM m136_tblDocument d
		JOIN m136_tblDocumentType t 
			ON d.iDocumentTypeId = t.iDocumentTypeId
	WHERE	d.iEntityId = @iEntityId;
	
	-- Get related attachment of document view.
	SELECT r.iItemId,
		   b.strName,
		   r.iPlacementId,
		   r.iProcessrelationTypeId,
		   b.strExtension,
		   b.strDescription 
	FROM m136_relInfo r 
		 JOIN m136_tblBlob b 
			ON r.iItemId = b.iItemId
	WHERE r.iEntityId = @iEntityId 
		  AND r.iRelationTypeId = 20;
		  
	-- Get related Document of document view.
	IF @IsProcess = 1
		BEGIN
			SELECT d.strName, 
				   d.iDocumentId,
				   r.iPlacementId,
				   d.iHandbookId,
				   h.strName AS strFolderName,
				   r.iProcessRelationTypeId,
				   d.iDocumentTypeId
			FROM m136_relInfo r
				JOIN m136_tblDocument d 
					ON	r.iItemId = d.iDocumentId 
						AND d.iLatestVersion = 1
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
			WHERE	r.iEntityId = @iEntityId 
					AND r.iRelationTypeId = 136
			ORDER BY r.iSort;
		END
	ELSE
		BEGIN
			SELECT d.strName, 
				   d.iDocumentId,
				   r.iPlacementId,
				   r.iProcessRelationTypeId,
				   d.iDocumentTypeId
			FROM m136_relInfo r
				JOIN m136_tblDocument d 
					ON	r.iItemId = d.iDocumentId 
						AND d.iLatestVersion = 1
			WHERE	r.iEntityId = @iEntityId 
					AND r.iRelationTypeId = 136
			ORDER BY r.iSort;
		END
		
	--Get Related Image	of document view.	
	SELECT	r.iItemId,
			r.iPlacementId,
			r.iScaleDirId,
			r.iSize,
			r.iVJustifyId, 
			r.iHJustifyId,
			r.iWidth, 
			r.iHeight,
			r.strCaption,
			r.strURL, 
			r.iNewWindow
	FROM  m136_relInfo r 
	WHERE iEntityId = @iEntityId 
		  AND (r.iRelationTypeId = 5 OR r.iRelationTypeId = 50)
		  AND r.iPlacementId > 0
	ORDER BY r.iRelationTypeId, 
			 r.iSort;
			 
	--Get fields content of document view.
	SELECT	mi.iInfoTypeId, 
			mi.strName strFieldName, 
			mi.strDescription strFieldDescription,
			InfoId = COALESCE (mit.iMetaInfoTextId, mid.iMetaInfoDateId, mii.iMetaInfoNumberId, mir.iMetaInfoRichTextId),
			NumberValue = mii.value, 
			DateValue = mid.value, 
			TextValue = mit.value, 
			RichTextValue = mir.value,                            
			mi.iMetaInfoTemplateRecordsId, 
			mi.iFieldProcessType, rdi.iMaximized
	FROM [dbo].m136_tblMetaInfoTemplateRecords mi
		 JOIN [dbo].m136_relDocumentTypeInfo rdi 
			ON rdi.iDocumentTypeId = @DocumentTypeId 
			   AND rdi.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoDate mid 
			ON mid.iEntityId = @iEntityId 
			   AND mid.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoNumber mii 
			ON mii.iEntityId = @iEntityId 
			   AND mii.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoText mit 
			ON mit.iEntityId = @iEntityId 
			   AND mit.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoRichText mir 
			ON mir.iEntityId = @iEntityId 
			   AND mir.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
	WHERE rdi.iDeleted = 0
	ORDER BY rdi.iSort;
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
	@ProcessRelationTypeId INT,
	@iPlacementId		INT
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
        @iPlacementId);
END
GO


IF OBJECT_ID('[dbo].[m136_be_UpdateRelatedDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateRelatedDocument] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: OCT 06, 2015
-- Description:	Update related document
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateRelatedDocument] 
	@iEntityId				INT,
	@iItemId				INT,
	@iRelationTypeId		INT,
	@iProcessRelationTypeId INT,
	@iPlacementId			INT
AS
BEGIN
	SET NOCOUNT ON;

    UPDATE [dbo].m136_relInfo
        SET iProcessRelationTypeId	= @iProcessRelationTypeId,
			iPlacementId			= @iPlacementId
        WHERE iEntityId = @iEntityId
            AND iRelationTypeId = @iRelationTypeId                    
            AND iItemId = @iItemId;
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
	@iProcessRelationTypeId INT,
	@iPlacementId			INT
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
		iProcessRelationTypeId	= @iProcessRelationTypeId,
		iPlacementId			= @iPlacementId
	WHERE iEntityId = @iEntityId
		AND iRelationTypeId = @iRelationTypeId                    
        AND iItemId = @iItemId;;
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
	@iSecurityId INT,
	@bShowDocumentsInTree BIT
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
				h.iHandbookId AS iParentHandbookId,
				0 AS iChildCount
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
				h.iHandbookId AS iParentHandbookId,
				0 AS iChildCount
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
				h.iParentHandbookId,
				[dbo].[fn136_be_GetChildCount] (@iSecurityId, h.iHandbookId, @bShowDocumentsInTree) AS iChildCount
		FROM	m136_tblHandbook as h
		WHERE	(h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
			AND h.iDeleted = 0
	ORDER BY d.iSort ASC, 
			 d.strName ASC;
END
GO