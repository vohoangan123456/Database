INSERT INTO #Description VALUES('Implmenet get Report update Document')
GO

IF OBJECT_ID('[dbo].[m136_be_ReportDocumentUpdatedOverview]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_ReportDocumentUpdatedOverview] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_ReportDocumentUpdatedOverview]
	@HandbookId AS INT,
	@SecurityId AS INT,
	@DateFrom DATETIME = null,
	@DateTo DATETIME = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result SETs from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @EntityId INT

	DECLARE @resultTable TABLE(iEntityId INT NOT NULL PRIMARY KEY, iDocId INT, iHandbookId INT, strName NVARCHAR(200), iLevelType INT, 
	strDocName NVARCHAR(200), iVersion INT, DocumentType INT, strChanges NVARCHAR(MAX), strTargetGroup NVARCHAR(MAX))
	
	DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
		
	INSERT INTO @AvailableChildren(iHandbookId)
	SELECT 
		iHandbookId 
	FROM 
		[dbo].[m136_GetHandbookRecursive](@HandbookId, @SecurityId, 1);
	
		
	INSERT INTO @resultTable(iEntityId, iDocId, iHandbookId , iVersion, strDocName  ) 
	SELECT  d.iEntityId, d.iDocumentId, d.iHandbookId ,  d.iVersion , d.strName 
			FROM m136_tblDocument d
				JOIN @AvailableChildren ac
					ON d.iHandbookId = ac.iHandbookId
				WHERE d.iApproved = 1 and d.dtmPublish >= @DateFrom and 
				d.dtmPublish < @DateTo		

	DELETE
	FROM @resultTable
	WHERE iEntityId NOT IN ( SELECT MAX(iEntityId)
							  FROM @resultTable
							  GROUP BY iDocId)
							
	DECLARE curDocumentId CURSOR FOR
	SELECT iEntityId FROM @resultTable

	OPEN curDocumentId
	FETCH NEXT FROM curDocumentId INTO @EntityId
	WHILE @@FETCH_STATUS =0
	BEGIN		
		DECLARE @HandbookName NVARCHAR(200) 
		DECLARE @LevelType INT
		DECLARE @Changes NVARCHAR(MAX)
		DECLARE @TargetGroup NVARCHAR(MAX)
		DECLARE @DocumentType INT

		SELECT @HandbookName = (SELECT strName FROM m136_tblHandbook WHERE iHandbookId = (SELECT iHandbookId FROM m136_tblDocument WHERE iEntityId = @EntityId)) 
		SELECT @LevelType = (SELECT iLevelType FROM m136_tblHandbook WHERE iHandbookId = (SELECT iHandbookId FROM m136_tblDocument WHERE iEntityId = @EntityId)) 
		   
		SELECT @DocumentType = (SELECT m136_tblDocumentType.Type FROM m136_tblDocumentType WHERE iDocumentTypeId = (SELECT iDocumentTypeId FROM m136_tblDocument WHERE iEntityId = @EntityId))
		
		UPDATE @resultTable 
		SET strName = @HandbookName, iLevelType = @LevelType, DocumentType = @DocumentType
		WHERE iEntityId = @EntityId;
		
		DECLARE @MetaInfoTemplateRecordsId int
	
		SELECT @MetaInfoTemplateRecordsId = 
			(SELECT iMetaInfoTemplateRecordsId FROM m136_tblMetaInfoTemplateRecords WHERE iMetaInfoTemplateRecordsId in 
				(SELECT iMetaInfoTemplateRecordsId FROM m136_relDocumentTypeInfo WHERE iDocumentTypeId = (SELECT iDocumentTypeId FROM m136_tblDocument WHERE iEntityId = @EntityId))
			  and strName like '%Målgruppe%')

		IF @MetaInfoTemplateRecordsId > 0
		BEGIN
			SELECT @TargetGroup = (SELECT Value FROM m136_tblMetaInfoRichText WHERE iEntityId = @EntityId and iMetaInfoTemplateRecordsId = @MetaInfoTemplateRecordsId)		
			UPDATE @resultTable 
			SET strTargetGroup = @TargetGroup
			WHERE iEntityId = @EntityId;  
		END

		SELECT @MetaInfoTemplateRecordsId = 
			(SELECT iMetaInfoTemplateRecordsId FROM m136_tblMetaInfoTemplateRecords WHERE iMetaInfoTemplateRecordsId in 
				(SELECT iMetaInfoTemplateRecordsId FROM m136_relDocumentTypeInfo WHERE iDocumentTypeId = (SELECT iDocumentTypeId FROM m136_tblDocument WHERE iEntityId = @EntityId))
			  and strName like '%Endringer fra%')

		IF @MetaInfoTemplateRecordsId > 0
		BEGIN
			SELECT @Changes = (SELECT Value FROM m136_tblMetaInfoRichText WHERE iEntityId = @EntityId and iMetaInfoTemplateRecordsId = @MetaInfoTemplateRecordsId)		
			UPDATE @resultTable 
			SET strChanges = @Changes
			WHERE iEntityId = @EntityId;
		END	

	FETCH NEXT FROM curDocumentId INTO @EntityId
	END
		CLOSE curDocumentId
		DEALLOCATE curDocumentId
    
	SELECT DocumentType, strDocName AS Dokument, strName AS Mappe, iDocId AS DokId, iVersion AS Versjon, strChanges AS CustomField1, strTargetGroup AS CustomField2  
	FROM @resultTable 
	ORDER BY strName, iDocId

END
GO

IF OBJECT_ID('[dbo].[m136_be_ReportHandbookUpdatedOverview]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_ReportHandbookUpdatedOverview] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_ReportHandbookUpdatedOverview]
	@SecurityId AS INT,
	@DateFrom datetime = null,
	@DateTo dateTime = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @EntityId INT

	DECLARE @resultTable TABLE(iEntityId INT NOT NULL PRIMARY KEY, iDocId INT, iHandbookId INT, strName NVARCHAR(200), iLevelType INT, 
	strDocName NVARCHAR(200), iVersion INT, DocumentType INT, strChanges NVARCHAR(MAX), strTargetGroup NVARCHAR(MAX))
	
		
	INSERT INTO @resultTable(iEntityId, iDocId, iHandbookId , iVersion, strDocName  ) 
	SELECT  d.iEntityId, d.iDocumentId, d.iHandbookId ,  d.iVersion , d.strName 
			FROM m136_tblDocument d
				WHERE d.iApproved = 1 and d.dtmPublish >= @DateFrom and 
				d.dtmPublish < @DateTo		

	DELETE
	FROM @resultTable
	WHERE iEntityId NOT IN( SELECT MAX(iEntityId)
							 FROM @resultTable
							 GROUP BY iDocId)
							
	DECLARE curDocumentId CURSOR FOR
	SELECT iEntityId FROM @resultTable

	OPEN curDocumentId
	FETCH NEXT FROM curDocumentId INTO @EntityId
	WHILE @@FETCH_STATUS =0
	BEGIN		
		DECLARE @HandbookName NVARCHAR(200) 
		DECLARE @LevelType INT
		DECLARE @Changes NVARCHAR(MAX)
		DECLARE @TargetGroup NVARCHAR(MAX)
		DECLARE @DocumentType INT

		SELECT @HandbookName = (SELECT strName FROM m136_tblHandbook WHERE iHandbookId = (SELECT iHandbookId FROM m136_tblDocument WHERE iEntityId = @EntityId)) 
		SELECT @LevelType = (SELECT iLevelType FROM m136_tblHandbook WHERE iHandbookId = (SELECT iHandbookId FROM m136_tblDocument WHERE iEntityId = @EntityId)) 
		   
		SELECT @DocumentType = (SELECT m136_tblDocumentType.Type FROM m136_tblDocumentType WHERE iDocumentTypeId = (SELECT iDocumentTypeId FROM m136_tblDocument WHERE iEntityId = @EntityId))
		
		UPDATE @resultTable 
		SET strName = @HandbookName, iLevelType = @LevelType, DocumentType = @DocumentType
		WHERE iEntityId = @EntityId;
		
		DECLARE @MetaInfoTemplateRecordsId INT
	
		SELECT @MetaInfoTemplateRecordsId = 
			(SELECT iMetaInfoTemplateRecordsId FROM m136_tblMetaInfoTemplateRecords WHERE iMetaInfoTemplateRecordsId in 
				(SELECT iMetaInfoTemplateRecordsId FROM m136_relDocumentTypeInfo WHERE iDocumentTypeId = (SELECT iDocumentTypeId FROM m136_tblDocument WHERE iEntityId = @EntityId))
			  and strName like '%Målgruppe%')

		IF @MetaInfoTemplateRecordsId > 0
		BEGIN
			SELECT @TargetGroup = (SELECT Value FROM m136_tblMetaInfoRichText WHERE iEntityId = @EntityId and iMetaInfoTemplateRecordsId = @MetaInfoTemplateRecordsId)		
			UPDATE @resultTable 
			SET strTargetGroup = @TargetGroup
			WHERE iEntityId = @EntityId;  
		END

		SELECT @MetaInfoTemplateRecordsId = 
			(SELECT iMetaInfoTemplateRecordsId FROM m136_tblMetaInfoTemplateRecords WHERE iMetaInfoTemplateRecordsId in 
				(SELECT iMetaInfoTemplateRecordsId FROM m136_relDocumentTypeInfo WHERE iDocumentTypeId = (SELECT iDocumentTypeId FROM m136_tblDocument WHERE iEntityId = @EntityId))
			  and strName like '%Endringer fra%')

		IF @MetaInfoTemplateRecordsId > 0
		BEGIN
			SELECT @Changes = (SELECT Value FROM m136_tblMetaInfoRichText WHERE iEntityId = @EntityId and iMetaInfoTemplateRecordsId = @MetaInfoTemplateRecordsId)		
			UPDATE @resultTable 
			SET strChanges = @Changes
			WHERE iEntityId = @EntityId;
		END	

	FETCH NEXT FROM curDocumentId INTO @EntityId
	END
		CLOSE curDocumentId
		DEALLOCATE curDocumentId
    
	SELECT DocumentType, strDocName AS Dokument, strName AS Mappe, iDocId AS DokId, iVersion AS Versjon, strChanges AS CustomField1, strTargetGroup AS CustomField2  
	FROM @resultTable 
	ORDER BY strName, iDocId

END
GO
