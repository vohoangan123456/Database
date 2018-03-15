INSERT INTO #Description VALUES('Update SP [dbo].[m136_be_ReportHandbookUpdatedOverview]')
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
	 
	 INSERT INTO @resultTable(iEntityId, iDocId, iHandbookId, strName, iLevelType ,strDocName, iVersion, DocumentType  ) 
	 SELECT  d.iEntityId, d.iDocumentId, d.iHandbookId ,  h.strName , h.iLevelType, d.strName, d.iVersion, t.Type
	 FROM m136_tblDocument d
	 INNER JOIN dbo.m136_tblHandbook h ON h.iHandbookId = d.iHandbookId
	 INNER JOIN m136_tblDocumentType t ON t.iDocumentTypeId = d.iDocumentTypeId
	 WHERE d.iLatestApproved = 1 and d.dtmPublish >= @DateFrom and 
		d.dtmPublish < @DateTo  ;
	    
	 SELECT iMetaInfoTemplateRecordsId into #iMetaInfoTemplateRecordsIds 
	 FROM m136_tblMetaInfoTemplateRecords 
	 WHERE iMetaInfoTemplateRecordsId IN
		(SELECT iMetaInfoTemplateRecordsId 
		  FROM m136_relDocumentTypeInfo 
		  WHERE iDocumentTypeId IN (SELECT iDocumentTypeId FROM m136_tblDocument WHERE iEntityId in (SELECT r.iEntityId FROM @resultTable r)))
		 and strName like '%Målgruppe%'
	     
	 UPDATE r
	 SET r.strTargetGroup = m.value
	 FROM @resultTable r 
	 LEFT JOIN (SELECT Value,iEntityId 
					FROM m136_tblMetaInfoRichText 
					WHERE iMetaInfoTemplateRecordsId in (SELECT iMetaInfoTemplateRecordsId FROM #iMetaInfoTemplateRecordsIds)) as m
		ON m.iEntityId = r.iEntityId
	     
	 SELECT iMetaInfoTemplateRecordsId INTO #iMetaInfoTemplateRecordsIds2 
	 FROM m136_tblMetaInfoTemplateRecords 
	 WHERE iMetaInfoTemplateRecordsId IN 
		(SELECT iMetaInfoTemplateRecordsId 
			FROM m136_relDocumentTypeInfo 
			WHERE iDocumentTypeId in (SELECT iDocumentTypeId FROM m136_tblDocument WHERE iEntityId in (SELECT r.iEntityId FROM @resultTable r)))
		 and strName like '%Endringer fra%'
	 
	 UPDATE r
	 SET r.strChanges = m.value
	 FROM @resultTable r 
	 LEFT JOIN (SELECT Value,iEntityId 
					FROM m136_tblMetaInfoRichText 
					WHERE iMetaInfoTemplateRecordsId in (SELECT iMetaInfoTemplateRecordsId FROM #iMetaInfoTemplateRecordsIds2)) as m
		ON m.iEntityId = r.iEntityId
	 
	 SELECT DocumentType, strDocName AS Dokument, strName AS Mappe, iDocId AS DokId, iVersion AS Versjon, strChanges AS CustomField1, strTargetGroup AS CustomField2  
	 FROM @resultTable 
	 ORDER BY strName, iDocId
END
GO