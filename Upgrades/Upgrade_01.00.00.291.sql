INSERT INTO #Description VALUES ('Modify procedure [dbo].[m136_be_ReportMostReadDocuments]')
GO

IF OBJECT_ID('[dbo].[m136_be_ReportMostReadDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_ReportMostReadDocuments] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_ReportMostReadDocuments]
	@HandbookId AS INT = NULL,
	@IncludeSubFolders AS BIT = 0,
	@DocumentType AS INT = NULL,
	@NumberReturn AS INT,
	@SecurityId AS INT,
	@IsTotal As	BIT = 0
AS
BEGIN
	DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY, strName VARCHAR(100));
	IF @HandbookId IS NOT NULL
	BEGIN
		IF @IncludeSubFolders = 1
		BEGIN
			INSERT INTO @AvailableChildren(iHandbookId)
			SELECT 
				iHandbookId 
			FROM 
				[dbo].[m136_GetHandbookRecursive](@HandbookId, @SecurityId, 1);
		END
		ELSE
			INSERT INTO @AvailableChildren(iHandbookId) VALUES(@HandbookId);
	END
	ELSE
	BEGIN
		IF @IncludeSubFolders = 1
		BEGIN
			INSERT INTO @AvailableChildren(iHandbookId)
			SELECT 
				iHandbookId 
			FROM dbo.m136_tblHandbook
			WHERE iDeleted = 0
				  AND [dbo].[fnHandbookHasReadContentsAccess](@SecurityId, iHandbookId) = 1;
		END
		ELSE
			INSERT INTO @AvailableChildren(iHandbookId)
			SELECT 
				iHandbookId 
			FROM dbo.m136_tblHandbook
			WHERE iDeleted = 0
				  AND [dbo].[fnHandbookHasReadContentsAccess](@SecurityId, iHandbookId) = 1
				  AND iParentHandbookId IS NULL;
	END
	UPDATE ac 
	SET ac.strName = h.strName
	FROM @AvailableChildren	ac
	JOIN dbo.m136_tblHandbook h ON ac.iHandbookId = h.iHandbookId
	DECLARE @resultTable TABLE(DokId INT,Mappe NVARCHAR(200),Dokument NVARCHAR(200), Versjon INT, DocumentType INT, MostReadTotal INT, MostReadVersion INT)
	INSERT INTO @resultTable
	SELECT  d.iDocumentId AS DokId,
			h.strName AS Mappe,
			d.strName AS Dokument,
			d.iVersion AS Versjon,
			dt.Type AS DocumentType,
			0 AS MostReadTotal,
			d.iReadCount AS MostReadVersion
		FROM m136_tblDocument d
			JOIN @AvailableChildren h ON h.iHandbookId = d.iHandbookId 
			INNER JOIN m136_tblDocumentType dt ON dt.idocumenttypeid = d.idocumenttypeid
		WHERE  d.iLatestApproved = 1 
			   AND (@DocumentType IS NULL OR d.iDocumentTypeId = @DocumentType)
	UPDATE result
	SET MostReadTotal = d.iReadCount
	FROM @resultTable result 
	JOIN (SELECT SUM(iReadCount) AS iReadCount, iDocumentId FROM dbo.m136_tblDocument GROUP BY iDocumentId) d ON result.DokId = d.iDocumentId
	IF @IsTotal = 1
	BEGIN
		SELECT TOP(@NumberReturn) r.*
		FROM @resultTable r
		ORDER BY r.MostReadTotal DESC, r.MostReadVersion DESC
	END
	ELSE
	BEGIN
		SELECT TOP(@NumberReturn) r.*
		FROM @resultTable r
		ORDER BY r.MostReadVersion DESC, r.MostReadTotal DESC
	END
END
GO