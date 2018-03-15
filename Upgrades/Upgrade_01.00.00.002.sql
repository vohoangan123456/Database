
IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id = OBJECT_ID('tempdb..#Description')) DROP TABLE #Description
GO
CREATE TABLE #Description ([Description] NVARCHAR(500))
GO

INSERT INTO #Description VALUES('Create stored procedure to get chapter items,
 read access,
 document information,
 list of document approved within x days, 
 approved subscription,
 most view document,
 my favourite,
 recent documents')
GO

----------------------------------------
----------------------------------------
		
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetRelatedAttachments]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetRelatedAttachments]
GO

CREATE  PROCEDURE [dbo].[m136_GetRelatedAttachments]
	@iEntityId int,
	@iSecurityId int,
	@RelationTypes int
AS
BEGIN

	IF @RelationTypes = 2
		BEGIN
			SELECT r.iItemId, dbo.fnArchiveGetFileName(@iSecurityId, r.iItemId, '') strName
				  ,r.iPlacementId,r.iProcessrelationTypeId,isnull(b.strExtension,'ukjent') AS strExtension
				FROM m136_relInfo r 
				LEFT JOIN tblBlob b ON r.iItemId=b.iItemId 
				WHERE iEntityId = @iEntityId AND r.iRelationTypeId = 2 
		END
	ELSE IF @RelationTypes = 20
		BEGIN
			SELECT r.iItemId,b.strName
				FROM m136_relInfo r JOIN m136_tblBlob b ON r.iItemId = b.iItemId
				WHERE r.iEntityId = @iEntityId AND r.iRelationTypeId = 20 
		END
	ELSE IF @RelationTypes = 50
		BEGIN
			SELECT r.iItemId,dbo.fnArchiveGetImageName(@iSecurityId, r.iItemId, '') AS strName
					,ISNULL(r.iPlacementId,0) AS iPlacementId,r.iProcessrelationTypeId
					,ISNULL(r.iScaleDirId,0) AS iScaleDirId
					,ISNULL(r.iVJustifyId,0) AS iVJustifyId ,ISNULL(r.iHJustifyId,0) AS iHJustifyId
					,ISNULL(r.iSize,0) AS iSize, ISNULL(r.strCaption,'') AS strCaption
					,ISNULL(r.iSort,0) AS iSort, ISNULL(r.strURL,'') AS strURL,ISNULL(r.iWidth,0) AS iWidth
					,ISNULL(r.iHeight,0) AS iHeight, ISNULL(r.iNewWindow,0) AS iNewWindow
					,ISNULL(r.iThumbWidth,0) AS iThumbWidth, ISNULL(r.iThumbHeight,0) AS iThumbHeight, r.iRelationTypeId
				FROM m136_relInfo r 
				JOIN m136_tblBlob b on r.iItemId = b.iItemId 
				WHERE r.iEntityId = @iEntityId AND r.iRelationTypeId = 50 
		END
	ELSE IF @RelationTypes = 5
		BEGIN
			SELECT r.iItemId, r.iScaleDirId, r.iPlacementId, r.iVJustifyId, 
					r.iHJustifyId, r.iSize, r.strCaption, r.iSort, r.strURL, 
					r.iWidth, r.iHeight, r.iNewWindow,
					dbo.fnArchiveGetImageName(@iSecurityId, r.iItemId, '') strName,
					r.iThumbWidth, r.iThumbHeight, r.iRelationTypeId
				FROM m136_relInfo r 
				WHERE iEntityId = @iEntityId AND r.iRelationTypeId = 5 
		END				
END

GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetRelatedDocuments]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetRelatedDocuments]
GO

CREATE PROCEDURE [dbo].[m136_GetRelatedDocuments]
	@iEntityId int,
	@ExtendRelatedDoc bit = 1
AS
BEGIN
	SELECT  d.strName, d.iDocumentId
	FROM m136_relInfo r
	JOIN m136_tblDocument d 
		ON r.iItemId = d.iDocumentId 
		AND d.iVersion = (SELECT ISNULL(MAX(iVersion), 0)
			FROM m136_tblDocument
			WHERE iDocumentId = r.iItemId
				AND (@ExtendRelatedDoc = 0 OR (@ExtendRelatedDoc = 1 AND iApproved in (1,4)))
				AND iDeleted = 0)
		AND ((@ExtendRelatedDoc = 0 AND d.iApproved <> 4) OR (@ExtendRelatedDoc = 1 AND d.iApproved = 1))
	JOIN m136_tblDocumentType dtype on d.iDocumentTypeId=dtype.iDocumentTypeId
	WHERE r.iEntityId = @iEntityId AND r.iRelationTypeId = 136
	order by r.iSort
END

GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetDocumentFieldContents]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetDocumentFieldContents]
GO

CREATE PROCEDURE [dbo].[m136_GetDocumentFieldContents]
	@DocumentTypeId int,
	@iEntityId int
AS
BEGIN
	SELECT	mi.iInfoTypeId, mi.strName strFieldName, mi.strDescription strFieldDescription,
            InfoId = COALESCE (mit.iMetaInfoTextId, mid.iMetaInfoDateId, mii.iMetaInfoNumberId, mir.iMetaInfoRichTextId),
            NumberValue = mii.value, DateValue = mid.value, TextValue = mit.value, RichTextValue = mir.value,                            
            mi.iMetaInfoTemplateRecordsId, mi.iFieldProcessType, rdi.iMaximized
    FROM		[dbo].m136_tblMetaInfoTemplateRecords mi
                JOIN [dbo].m136_relDocumentTypeInfo rdi ON rdi.iDocumentTypeId = @DocumentTypeId AND rdi.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
                LEFT JOIN [dbo].m136_tblMetaInfoDate mid ON mid.iEntityId = @iEntityId AND mid.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
                LEFT JOIN [dbo].m136_tblMetaInfoNumber mii ON mii.iEntityId = @iEntityId AND mii.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
                LEFT JOIN [dbo].m136_tblMetaInfoText mit ON mit.iEntityId = @iEntityId AND mit.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
                LEFT JOIN [dbo].m136_tblMetaInfoRichText mir ON mir.iEntityId = @iEntityId AND mir.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
    WHERE rdi.iDeleted = 0
    ORDER BY	rdi.iSort
END

GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetFieldContentsCompareToVersion]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetFieldContentsCompareToVersion]
GO

CREATE PROCEDURE [dbo].[m136_GetFieldContentsCompareToVersion]
	@documentEntityId int 
AS 
BEGIN

	DECLARE @EntityIdcompareToVersion int = null	
	DECLARE @DocumetTypeIdcompareToVersion int = null	
	DECLARE @documentId int
	DECLARE @currentVersion INT

	SELECT @EntityIdcompareToVersion = iCompareToVersion, @DocumetTypeIdcompareToVersion = iDocumentTypeId, @currentVersion = iVersion, @documentId = iDocumentId 
	FROM dbo.m136_tblDocument WHERE iEntityId = @documentEntityId
	
	IF @EntityIdcompareToVersion IS NULL AND EXISTS(SELECT * FROM dbo.m136_tblDocument WHERE iDocumentId = @documentId AND iVersion < @currentVersion AND iDeleted = 0 AND iApproved = 1)
	BEGIN
		SELECT TOP 1 @EntityIdcompareToVersion = iEntityId , @DocumetTypeIdcompareToVersion = iDocumentTypeId 
		FROM dbo.m136_tblDocument 
		WHERE iDocumentId = @documentId AND iVersion < @currentVersion AND iDeleted = 0 AND iApproved = 1
		ORDER BY iVersion DESC
	END

	IF @EntityIdcompareToVersion IS NOT NULL
	BEGIN
		exec dbo.m136_GetDocumentFieldContents @DocumetTypeIdcompareToVersion , @EntityIdcompareToVersion
	END
END

GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_InsertOrUpdateDocAccessLog]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_InsertOrUpdateDocAccessLog]
GO
-- =============================================
-- Author:		Atle Solberg
-- Create date: 22.11.2013
-- Description:	Insert Or Update Document Access Log
-- =============================================
CREATE procedure [dbo].[m136_InsertOrUpdateDocAccessLog]
	-- Add the parameters for the stored procedure here
	@iSecurityId int,
	@iDocumentId int,
	@dtmAccessed smalldatetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF EXISTS (SELECT * FROM [dbo].[m136_tblDocAccessLog]
				 WHERE iSecurityId = @iSecurityId AND iDocumentId = @iDocumentId)

        UPDATE [dbo].[m136_tblDocAccessLog]
        SET iAccessedCount = iAccessedCount + 1, dtmAccessed = @dtmAccessed
        WHERE iSecurityId = @iSecurityId AND iDocumentId = @iDocumentId

    ELSE    

        INSERT INTO [dbo].[m136_tblDocAccessLog]
        (
			iSecurityId, iDocumentId, dtmAccessed, iAccessedCount
		)
        VALUES
        (
			@iSecurityId, @iDocumentId, @dtmAccessed, 1
		)
END

GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_IncreaseReadCountDocument]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_IncreaseReadCountDocument]
GO


CREATE procedure [dbo].[m136_IncreaseReadCountDocument]
	-- Add the parameters for the stored procedure here
	@iSecurityId int,
	@iDocumentId int,
	@iEntityId int,
	@dtmAccessed smalldatetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	UPDATE dbo.m136_tblDocument set iReadCount=iReadcount+1 where iEntityId= @iEntityId
	
	exec [dbo].[m136_InsertOrUpdateDocAccessLog] @iSecurityId , @iDocumentId, @dtmAccessed
END

GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetChapterItems]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetChapterItems]
GO

CREATE PROCEDURE [dbo].[m136_GetChapterItems] 
 -- Add the parameters for the stored procedure here
 @iHandbookId int = NULL
AS
BEGIN
 -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.
 SET NOCOUNT ON;
  SELECT strName as FolderName,
    iParentHandbookId as ParentId,
    dbo.fn136_GetParentPathEx(@iHandbookId) as Path,
    iLevelType as [Level],
    iViewTypeId as ViewType
  FROM m136_tblHandbook
  WHERE iHandbookId = @iHandbookId AND @iHandbookId IS NOT NULL
  SELECT d.iDocumentId as Id,
    d.strName,
    dt.iDocumentTypeId as TemplateId,
    dt.Type as DocumentType,
    d.iVersion as Version,
    d.dtmApproved,
    d.strApprovedBy,
    e.strFirstName + ' ' + e.strLastName as Responsible, -- TODO - function??
    null as DepartmentId,
    0 as Virtual,
    d.iSort,
    NULL as ParentFolderName,
    NULL as Path
  FROM m136_tblDocument d
   INNER JOIN m136_tblDocumentType dt 
    ON d.iDocumentTypeId = dt.iDocumentTypeId
   INNER JOIN tblEmployee e
    ON d.iCreatedbyId = e.iEmployeeId
  WHERE d.iHandbookId = @iHandbookId
   AND d.iLatestApproved = 1
   AND d.iDeleted = 0
 UNION
  SELECT v.iDocumentId as Id,
      d.strName,
      dt.iDocumentTypeId as TemplateId,
      dt.Type as DocumentType,
      d.iVersion as Version,
      d.dtmApproved,
      d.strApprovedBy,
      e.strFirstName + ' ' + e.strLastName as Responsible, -- TODO - function??
      null as DepartmentId,
      1 as Virtual,
      v.iSort,
      h.strName as ParentFolderName,
      dbo.fn136_GetParentPathEx(h.iHandbookId) as Path
  FROM m136_relVirtualRelation v
   INNER JOIN m136_tblDocument d 
    ON d.iDocumentId = v.iDocumentId
   INNER JOIN m136_tblDocumentType dt 
    ON d.iDocumentTypeId = dt.iDocumentTypeId
   INNER JOIN m136_tblHandbook h
    ON d.iHandbookId = h.iHandbookId
   INNER JOIN tblEmployee e
    ON d.iCreatedbyId = e.iEmployeeId
  WHERE v.iHandbookId = @iHandbookId
    AND d.iDeleted = 0
    AND d.iLatestApproved = 1
 UNION
  SELECT h.iHandbookId as Id,
    h.strName,
    NULL as TemplateId,
    -1 as DocumentType,
    NULL as Version,
    NULL as dtmApproved,
    NULL as strApprovedBy,
    NULL as Responsible,
    h.iDepartmentId as DepartmentId,
    0 as Virtual,
    -2147483648 + h.iMin as iSort, -- Little trick with putting all the folders on top of documents sorted by iMin TODO - there can be a better way with the constant more importantly
    NULL as ParentFolderName,
    NULL as Path
  FROM m136_tblHandbook as h
  WHERE (h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
    AND h.iDeleted = 0
 ORDER BY d.iSort ASC, 
    d.strName ASC 
END