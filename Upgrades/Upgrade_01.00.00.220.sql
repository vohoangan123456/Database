INSERT INTO #Description VALUES('Update SP for report Update Folder statistics ')
GO

IF OBJECT_ID('[dbo].[m136_spReportFolderDocumentTypes]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_spReportFolderDocumentTypes] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_spReportFolderDocumentTypes]
	@HandbookId AS INT,
	@SecurityId AS INT	
AS
BEGIN
	DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	DELETE FROM @AvailableChildren
	
	INSERT INTO @AvailableChildren(iHandbookId)
	SELECT 
		iHandbookId 
	FROM 
		[dbo].[m136_GetHandbookRecursive](@HandbookId, @SecurityId, 1);

	DECLARE @docTypeTable TABLE(DocTypeCount INT,  DocType VARCHAR(100),DocTypeId INT) 
	INSERT INTO @docTypeTable (DocTypeCount ,DocType,DocTypeId) 
		(SELECT COUNT(d.idocumenttypeid) AS Count,
				dt.strName AS DocType, dt.iDocumentTypeId AS DocTypeId
			FROM m136_tblDocument d
			JOIN @AvailableChildren ac ON d.iHandbookId = ac.iHandbookId
			INNER JOIN m136_tblDocumentType dt ON dt.idocumenttypeid = d.idocumenttypeid
				WHERE  d.iLatestApproved = 1 and d.dtmPublish < GETDATE() 
		 GROUP BY d.idocumenttypeid, dt.strName, dt.iDocumentTypeId)

	SELECT DocTypeId, DocType, DocTypeCount FROM @docTypeTable		
END
GO

IF OBJECT_ID('[dbo].[m136_spReportHandbookDocumentTypes]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_spReportHandbookDocumentTypes] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_spReportHandbookDocumentTypes]
	@SecurityId AS INT	
AS
BEGIN

	DECLARE @docTypeTable TABLE(DocTypeCount INT,  DocType VARCHAR(100),DocTypeId INT) 
	INSERT INTO @docTypeTable (DocTypeCount ,DocType,DocTypeId) 
		(SELECT COUNT(d.idocumenttypeid) AS Count,
				 dt.strName AS DocType, dt.iDocumentTypeId AS DocTypeId
			FROM m136_tblDocument d
				INNER JOIN m136_tblDocumentType dt on dt.idocumenttypeid = d.idocumenttypeid
			WHERE  d.iLatestApproved = 1 and d.dtmPublish < GETDATE() 
		GROUP BY d.idocumenttypeid, dt.strName, dt.iDocumentTypeId)

	SELECT DocTypeId, DocType, DocTypeCount FROM @docTypeTable	
	
END
GO