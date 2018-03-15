INSERT INTO #Description VALUES('Init upgrade script for GastroHandbook App')
GO

--Add new tables
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_Apps]') AND type in (N'U'))
DROP TABLE [dbo].[m136_Apps]
GO

CREATE TABLE [dbo].[m136_Apps](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[AppName] [varchar](100) NOT NULL,
	[DefaultAppUserId] [int] NULL,
 CONSTRAINT [PK_m136_Apps] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_AppSessions]') AND type in (N'U'))
DROP TABLE [dbo].[m136_AppSessions]
GO

CREATE TABLE [dbo].[m136_AppSessions](
	[PhoneId] [varchar](200) NOT NULL,
	[SessionTime] [datetime] NOT NULL,
	[AppId] [int] NOT NULL,
	[UserId] [int] NOT NULL
) ON [PRIMARY]

GO

--Insert default record to table [dbo].[m136_Apps] 
INSERT INTO [dbo].[m136_Apps] VALUES('GastroHandbook', 3)
GO

--Procedure to check object exist
IF (OBJECT_ID('[dbo].[MakeSureObjectExists]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [dbo].[MakeSureObjectExists] AS SELECT 1'
GO
ALTER PROCEDURE [dbo].[MakeSureObjectExists]	
    @ObjectName sysname
    , @ObjectType varchar(5) = 'P' -- P: procedure, V: view
		-- FN: scalar-valued function, IF: inline table-valued function, TF: multi-statement table-valued function
    , @Permission varchar(255) = null
    , @RoleOrUser varchar(255) = null
AS
BEGIN	
	SET NOCOUNT ON;
	DECLARE @ObjectTypeStr varchar(50), @ObjectBody NVarChar(200), @Sql NVarChar(max);
	IF (@ObjectType = 'P')
		SELECT @ObjectTypeStr = 'PROCEDURE', @ObjectBody = 'AS SET NOCOUNT ON;';
	ELSE IF (@ObjectType = 'FN')
		SELECT @ObjectTypeStr = 'FUNCTION', @ObjectBody = '() RETURNS Int AS BEGIN RETURN 1 END;';
	ELSE IF (@ObjectType = 'IF')
		SELECT @ObjectTypeStr = 'FUNCTION', @ObjectBody = '() RETURNS TABLE AS RETURN (SELECT 0 AS [id]);';
	ELSE IF (@ObjectType = 'TF')
		SELECT @ObjectTypeStr = 'FUNCTION', @ObjectBody = '() RETURNS @Result TABLE([id] Int) AS BEGIN RETURN END;';
	ELSE IF (@ObjectType = 'V')
		SELECT @ObjectTypeStr = 'VIEW', @ObjectBody = 'AS SELECT 1 AS [ABC]';
	SELECT @Sql = 'IF (OBJECT_ID(N''' + @ObjectName + ''', ''' + @ObjectType + ''') IS NULL) '
		+ 'EXEC(''' + 'CREATE ' + @ObjectTypeStr + ' ' + @ObjectName + ' ' + @ObjectBody + ''')';
	PRINT @Sql;
	EXEC (@Sql);
	IF (@Permission IS NOT NULL AND @RoleOrUser IS NOT NULL)
	BEGIN
		SELECT @Sql = 'GRANT ' + @Permission + ' ON ' + @ObjectName + ' TO ' + @RoleOrUser;
		EXEC (@Sql);
		PRINT @Sql;
	END;
END
GO

--Add new procedure for GastroHandbook business

EXEC [dbo].[MakeSureObjectExists] '[dbo].[m147_GetRegisterItems]'
GO
ALTER PROCEDURE [dbo].[m147_GetRegisterItems]
(
	@SecurityId INT,
	@RegisterId INT
)
AS
	SELECT RegisterItemId = a.iRegisterItemId, 
		Name = a.strName
	FROM m147_tblRegisterItem a 
	WHERE a.iRegisterId = @RegisterId 
		AND (dbo.fnSecurityGetPermission(147, 571, @SecurityId, a.iRegisterId) & 1) = 1
	ORDER BY Name
GO

EXEC [dbo].[MakeSureObjectExists] '[dbo].[m136_GetListOfApprovedMetataggedDocuments]'
GO
ALTER PROCEDURE [dbo].[m136_GetListOfApprovedMetataggedDocuments] 
	-- Add the parameters for the stored procedure here
	@SecurityId int = 0,
	@RegsterItemId int = 0,
	@MetatagValue VARCHAR(200) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT *
	FROM ( 
		SELECT
			dbo.m147_fnGetItemValue(dt.iAutoId) AS MetatagValue,
			d.iDocumentId, 
			d.iEntityId,
			d.strName, 
			d.iHandbookId, 
			h.strName AS strChapterName,
			d.iVersion,
			d.iSort
		FROM 
			m136_tblDocument d
			JOIN m136_tblHandbook h ON d.iHandbookId=h.iHandbookId
			LEFT OUTER JOIN m147_relRegisterItemItem dt 
				ON d.iDocumentId = dt.iItemId AND (dt.iRegisterItemId = @RegsterItemId AND dt.iModuleId=136) 				
		WHERE d.iLatestApproved = 1
			AND d.dtmPublish <= GETDATE()
			AND dt.iAutoId IS NOT NULL
			AND (dbo.fnSecurityGetPermission(136, 462, @SecurityId, d.iHandbookId)&1)=1
		
	) AS [Data]
	WHERE @MetatagValue IS NULL OR MetatagValue = @MetatagValue
	ORDER BY iSort, strName
END
GO

EXEC [dbo].[MakeSureObjectExists] '[dbo].[m136_GetPagedListOfApprovedMetataggedDocuments]'
GO
ALTER PROCEDURE [dbo].[m136_GetPagedListOfApprovedMetataggedDocuments]
(
	@PageSize INT,
	@PageIndex INT,
	@SecurityId INT,
	@RegisterItemId INT
)
AS
BEGIN

	DECLARE @ApprovedMetataggedDocuments TABLE
	(
		MetatagValue VARCHAR(200) NOT NULL,
		DocumentId INT NOT NULL,
		EntityId INT NOT NULL,
		Name VARCHAR(200) NOT NULL,
		HandbookId INT NOT NULL,
		ChapterName VARCHAR(100) NOT NULL,
		[Version] INT NOT NULL,
		Sort INT NOT NULL
	)
	
	
	INSERT INTO @ApprovedMetataggedDocuments
		EXEC [dbo].[m136_GetListOfApprovedMetataggedDocuments] @SecurityId, @RegisterItemId
		
	SELECT MetatagValue,
		DocumentId,
		EntityId,
		Name,
		HandbookId,
		ChapterName,
		[Version],
		Sort
	FROM (		
		SELECT *,
			RowNumber = ROW_NUMBER() OVER (ORDER BY DocumentId)
		FROM @ApprovedMetataggedDocuments
	) AS [PagedList]
	WHERE (@PageSize=0 OR RowNumber BETWEEN @PageSize*@PageIndex+1 AND @PageSize*(@PageIndex+1))
	
	SELECT COUNT(DocumentId) FROM @ApprovedMetataggedDocuments
END
GO

EXEC [dbo].[MakeSureObjectExists] '[dbo].[fnSplit_Gastro]', 'TF'
GO

ALTER FUNCTION [dbo].[fnSplit_Gastro] 
    (   
    @DelimitedString    VARCHAR(8000),
    @Delimiter              VARCHAR(100) 
    )
RETURNS @tblArray TABLE
    (
    ElementID   INT IDENTITY(1,1),
    Element     VARCHAR(1000)
    )
AS
BEGIN

    -- Local Variable Declarations
    -- ---------------------------
    DECLARE @Index      SMALLINT,
                    @Start      SMALLINT,
                    @DelSize    SMALLINT

    SET @DelSize = LEN(@Delimiter)

    -- Loop through source string and add elements to destination table array
    -- ----------------------------------------------------------------------
    WHILE LEN(@DelimitedString) > 0
    BEGIN

        SET @Index = CHARINDEX(@Delimiter, @DelimitedString)

        IF @Index = 0
            BEGIN

                INSERT INTO
                    @tblArray 
                    (Element)
                VALUES
                    (LTRIM(RTRIM(@DelimitedString)))

                BREAK
            END
        ELSE
            BEGIN

                INSERT INTO
                    @tblArray 
                    (Element)
                VALUES
                    (LTRIM(RTRIM(SUBSTRING(@DelimitedString, 1,@Index - 1))))

                SET @Start = @Index + @DelSize
                SET @DelimitedString = SUBSTRING(@DelimitedString, @Start , LEN(@DelimitedString) - @Start + 1)

            END
    END

    RETURN
END
GO

EXEC [dbo].[MakeSureObjectExists] '[dbo].[m136_ValidateDocumentExistence]'
GO
ALTER PROCEDURE [dbo].[m136_ValidateDocumentExistence]
(
	@SecurityId INT,
	@DocumentIds VARCHAR(8000)
)
AS
BEGIN
 
	DECLARE @TblDocumentId TABLE    
	(
		Id  INT
	)

	INSERT INTO @TblDocumentId
	SELECT ELEMENT FROM [dbo].[fnSplit_Gastro](@DocumentIds,',')

	SELECT DocumentId =	s.iDocumentId, 
		[Version] = s.iVersion, 
		ApprovedDate = s.dtmApproved, 
		IsDeleted = s.iDeleted
	FROM @TblDocumentId t 
	INNER JOIN 
	(
		SELECT iDocumentId, iLatestVersion, iLatestApproved, iVersion, dtmApproved, iDeleted 
		FROM dbo.m136_tblDocument 
		WHERE iLatestApproved = 1
		AND (dbo.fnSecurityGetPermission(136, 462, @SecurityId, iHandbookId)&1)=1
		AND iDeleted = 0
		AND dtmPublish <= GETDATE()
	) s 
	ON s.iDocumentId = t.Id
 
END
GO


EXEC [dbo].[MakeSureObjectExists] '[dbo].[m136_SearchMetataggedDocuments]'
GO

ALTER PROCEDURE [dbo].[m136_SearchMetataggedDocuments]
	@strSearchString varchar(1024) = '',
	@likeSearchWords varchar(900) = '',
	@searchInContent BIT,
	@iSecurityId INT,
	@iRegisterId INT,
	@iRegsterItemId int = 0
AS
BEGIN
	
	SET NOCOUNT ON
	declare @searchHits table(iEntityId int not null PRIMARY KEY, RANK int not null)
		
	declare @KEYWORD table(strKeyWord varchar(900) not null)
	insert into @KEYWORD
	select distinct Value from fn_Split(@likeSearchWords, ',')
	
	DECLARE @KEYWORDCOUNT as INT
	SELECT @KEYWORDCOUNT = COUNT(*) FROM @Keyword

	insert into @searchHits
    select distinct doc.iEntityId
        ,1000 AS RANK
    FROM
        m136_tblDocument doc	
		INNER JOIN	m136_tblHandbook handbook ON handbook.iHandbookId = doc.iHandbookId				
		INNER JOIN m147_relRegisterItemItem dt ON doc.iDocumentId = dt.iItemId and (dt.iModuleId=136) 
    where
		iLatestApproved = 1
		AND			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, handbook.iHandbookId) = 1
		AND (
				(@iRegsterItemId > 0 AND dt.iRegisterItemId=@iRegsterItemId)
				OR 
				(@iRegsterItemId = 0 AND dt.iRegisterItemId in (select iRegisterItemId from m147_tblRegisterItem where iRegisterId = @iRegisterId))
			)
		AND
		(
		  (@KEYWORDCOUNT = 0 )
		  OR 
		  (doc.iEntityId in (SELECT iEntityId
					FROM 
						m136_tblDocument doc 
						INNER JOIN @Keyword k
					   ON doc.strName like '%' + k.strKeyWord + '%'					 
					 GROUP BY 
					  iEntityId
					 HAVING COUNT(iEntityId) = @KEYWORDCOUNT))
		)
		
	IF(@searchInContent = 1)
		BEGIN		
			insert into @searchHits
            select SearchHits.iEntityId
                ,RANK
            FROM
                m136_tblDocument doc 	
				INNER JOIN	m136_tblHandbook handbook ON handbook.iHandbookId = doc.iHandbookId		
				INNER JOIN m147_relRegisterItemItem dt ON doc.iDocumentId = dt.iItemId and (dt.iModuleId=136) 
                RIGHT JOIN 
                m136x_tblTextIndex SearchHits on doc.iEntityId=SearchHits.iEntityId 
                INNER JOIN CONTAINSTABLE (m136x_tblTextIndex, totalvalue, @strSearchString) AS KEY_TBL
                on SearchHits.iEntityId=KEY_TBL.[KEY]
            where
				iLatestApproved = 1
				AND			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, handbook.iHandbookId) = 1
				AND (
						(@iRegsterItemId > 0 AND dt.iRegisterItemId=@iRegsterItemId)
						OR 
						(@iRegsterItemId = 0 AND dt.iRegisterItemId in (select iRegisterItemId from m147_tblRegisterItem where iRegisterId = @iRegisterId))
					)
				AND doc.iEntityId not in (select iEntityId from @searchHits)
          END
                
	SELECT DISTINCT	SearchHits.Rank,
					doc.iDocumentId AS Id,
					doc.iHandbookId,
					doc.strName,
					doc.iDocumentTypeId,
					doc.iVersion AS [Version],
					handbook.iLevelType AS LevelType,
					doc.dtmApproved,
					doc.strApprovedBy,
					dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) as Responsible,
					NULL AS DepartmentId,
					0 AS Virtual,
					doc.iSort,
					dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path],
					handbook.strName AS ParentFolderName,
					[dbo].[fnHasDocumentAttachment](doc.iEntityId) as HasAttachment
	FROM			m136_tblDocument doc
		INNER JOIN	m136_tblHandbook handbook 
			ON handbook.iHandbookId = doc.iHandbookId		
		INNER JOIN	@searchHits SearchHits on SearchHits.iEntityId=doc.iEntityId
	
END
GO


EXEC [dbo].[MakeSureObjectExists] '[dbo].[m136_GetMetatagsByRegisterItemId]'
GO
ALTER PROCEDURE [dbo].[m136_GetMetatagsByRegisterItemId]
(
	@SecurityId INT,
	@RegisterItemId INT
)
AS
BEGIN
	
	SET NOCOUNT ON;
	
	SELECT MetatagValue
	FROM 
	(
		SELECT DISTINCT dbo.m147_fnGetItemValue(relItemItem.iAutoId) as MetatagValue
		FROM 
			m136_tblDocument doc
			LEFT OUTER JOIN m147_relRegisterItemItem relItemItem 
				ON doc.iDocumentId = relItemItem.iItemId AND (relItemItem.iRegisterItemId = @RegisterItemId AND relItemItem.iModuleId=136) 							
		WHERE doc.iLatestApproved = 1
			AND doc.dtmPublish <= GETDATE()
			AND relItemItem.iAutoId IS NOT NULL
			AND (dbo.fnSecurityGetPermission(136, 462, @SecurityId, doc.iHandbookId)&1)=1
	)AS [Data]
	ORDER BY MetatagValue
	
END
GO


EXEC [dbo].[MakeSureObjectExists] '[dbo].[m136_GetPagedDocumentsByRegisterItemIdAndMetatag]'
GO
ALTER PROCEDURE [dbo].[m136_GetPagedDocumentsByRegisterItemIdAndMetatag]
(
	@PageIndex INT,
	@PageSize INT,
	@SecurityId INT,
	@RegisterItemId INT,
	@MetatagValue VARCHAR(200) = NULL
)
AS
BEGIN
	
	DECLARE @ApprovedMetataggedDocuments TABLE
	(
		MetatagValue VARCHAR(200) NOT NULL,
		DocumentId INT NOT NULL,
		EntityId INT NOT NULL,
		Name VARCHAR(200) NOT NULL,
		HandbookId INT NOT NULL,
		ChapterName VARCHAR(100) NOT NULL,
		[Version] INT NOT NULL,
		Sort INT NOT NULL
	)
	
	INSERT INTO @ApprovedMetataggedDocuments
		EXEC [dbo].[m136_GetListOfApprovedMetataggedDocuments] @SecurityId, @RegisterItemId, @MetatagValue
		
	SELECT MetatagValue,
		DocumentId,
		EntityId,
		Name,
		HandbookId,
		ChapterName,
		[Version],
		Sort
	FROM (		
		SELECT *,
			RowNumber = ROW_NUMBER() OVER (ORDER BY Sort, Name)
		FROM @ApprovedMetataggedDocuments
	) AS [PagedList]
	WHERE (@PageSize=0 OR RowNumber BETWEEN @PageSize*@PageIndex+1 AND @PageSize*(@PageIndex+1))
	
	SELECT COUNT(EntityId) FROM @ApprovedMetataggedDocuments
END
GO

EXEC [dbo].[MakeSureObjectExists] '[dbo].[m136_GetLatestDocumentById]'
GO
ALTER PROCEDURE [dbo].[m136_GetLatestDocumentById]
(
	@SecurityId INT,
	@DocumentId INT
)
AS
BEGIN
	SELECT EntityId = iEntityId, 
		DocumentId = iDocumentId,
		[Version] = iVersion,
		DocumentTypeId = iDocumentTypeId,
		HandbookId = iHandbookId,
		Name = strName,
		[Description] = strDescription,
		CreatedbyId = iCreatedbyId,
		CreatedDate = dtmCreated,
		Author = strAuthor,
		ApprovedById = iApprovedById,
		ApprovedDate = dtmApproved,
		ApprovedBy = strApprovedBy
		
	FROM dbo.m136_tblDocument doc
	
	WHERE iDocumentId = @DocumentId
		AND iLatestApproved = 1
		AND (dbo.fnSecurityGetPermission(136, 462, @SecurityId, doc.iHandbookId)&1)=1
		AND iDeleted = 0
		AND doc.dtmPublish <= GETDATE()
END
GO

EXEC [dbo].[MakeSureObjectExists] '[dbo].[m136_GetDocumentData]'
GO
ALTER PROCEDURE [dbo].[m136_GetDocumentData]
(
	@SecurityId INT,
	@DocumentId INT
)
AS
BEGIN

	DECLARE @EntityId INT,
		@DocumentTypeId INT

	DECLARE @Document TABLE
	(
		EntityId INT NOT NULL,
		DocumentId INT NULL,
		[Version] INT NOT NULL,
		DocumentTypeId INT NOT NULL,
		HandbookId INT NOT NULL,
		Name VARCHAR(200) NOT NULL,
		[Description] VARCHAR(2000) NOT NULL,
		CreatedbyId INT NOT NULL,
		CreatedDate DATETIME NOT NULL,
		Author VARCHAR(200) NOT NULL,
		ApprovedById INT NOT NULL,
		ApprovedDate DATETIME NULL,
		ApprovedBy VARCHAR(200) NOT NULL
	)

	INSERT INTO @Document
	EXEC [dbo].[m136_GetLatestDocumentById] @SecurityId, @DocumentId
	
	SELECT @EntityId = EntityId,
		@DocumentTypeId = DocumentTypeId
	FROM @Document
	
	--Get Document Content
	SELECT	InfoTypeId = mi.iInfoTypeId, 
			FieldName = mi.strName, 
			FieldDescription = mi.strDescription,
			InfoId = COALESCE (mit.iMetaInfoTextId, mid.iMetaInfoDateId, mii.iMetaInfoNumberId, mir.iMetaInfoRichTextId),
			NumberValue = mii.value, 
			DateValue = mid.value, 
			TextValue = mit.value, 
			RichTextValue = mir.value,                            
			FieldId = mi.iMetaInfoTemplateRecordsId, 
			FieldProcessType = mi.iFieldProcessType, 
			Maximized = rdi.iMaximized
	FROM [dbo].m136_tblMetaInfoTemplateRecords mi
		 JOIN [dbo].m136_relDocumentTypeInfo rdi 
			ON rdi.iDocumentTypeId = @DocumentTypeId 
			   AND rdi.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoDate mid 
			ON mid.iEntityId = @EntityId 
			   AND mid.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoNumber mii 
			ON mii.iEntityId = @EntityId 
			   AND mii.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoText mit 
			ON mit.iEntityId = @EntityId 
			   AND mit.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoRichText mir 
			ON mir.iEntityId = @EntityId 
			   AND mir.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
	WHERE rdi.iDeleted = 0
	ORDER BY rdi.iSort
	
	--Get Document Attachment
	SELECT ItemId = r.iItemId,
		   Name = b.strName,
		   PlacementId = r.iPlacementId
	FROM m136_relInfo r 
		 JOIN m136_tblBlob b 
			ON r.iItemId = b.iItemId
	WHERE r.iEntityId = @EntityId 
		  AND r.iRelationTypeId = 20
	
	--Get Document Related
	SELECT Name = d.strName, 
		   DocumentId = d.iDocumentId,
		   PlacementId = r.iPlacementId
	FROM m136_relInfo r
		JOIN m136_tblDocument d 
			ON	r.iItemId = d.iDocumentId 
				AND d.iLatestApproved = 1
	WHERE	r.iEntityId = @EntityId 
			AND r.iRelationTypeId = 136
	ORDER BY r.iSort
	
	--Get Document Info
	SELECT * FROM @Document
	
END
GO


