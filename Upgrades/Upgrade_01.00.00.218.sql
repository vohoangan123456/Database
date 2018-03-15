INSERT INTO #Description VALUES('Update SP [dbo].[m136_be_ReportDocumentsPerFolder]')
GO

IF OBJECT_ID('[dbo].[m136_be_ReportDocumentsPerFolder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_ReportDocumentsPerFolder] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_ReportDocumentsPerFolder]
@iParentHandbookId INT = 0,
@iSecurityId INT = 0
AS
BEGIN
	DECLARE @iHandbookId INT
	DECLARE @strName NVARCHAR(200)
	DECLARE @folderType INT
	DECLARE @HandbookIdTable TABLE(iHandbookId INT)
	-- Do we have a specified root or do we assume we will list everything?
	IF ISNULL(@iParentHandbookId,0) = 0
		BEGIN
			INSERT INTO @HandbookIdTable
			SELECT iHandbookId FROM dbo.m136_tblHandbook WHERE iDeleted = 0 
		END
	ELSE
		BEGIN
			INSERT INTO @HandbookIdTable
			SELECT iHandbookId FROM dbo.m136_GetHandbookRecursive (@iParentHandbookId, @iSecurityId, 0)
		END 
	/* Declare some temporary tables */
	DECLARE @allApprovedDocuments TABLE(iEntityId INT, iHandbookId INT, iDocumentId INT, strName nvarchar(200), iVersion INT)
	/* Find all approved documents and latest version */
	INSERT INTO @allApprovedDocuments
	SELECT doc.iEntityId, doc.iHandbookId, doc.iDocumentId, doc.strName, doc.iVersion 
	FROM m136_tblDocument doc 
	WHERE doc.iLatestApproved = 1
		  AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, doc.iHandbookId) & 0x15) > 0
		  AND doc.iHandbookId IN (SELECT iHandbookId FROM @HandbookIdTable)
		  AND doc.iDeleted = 0
	ORDER BY doc.iDocumentId 
		/* Create temporary table to hold the end result */
	DECLARE @resultTable TABLE(iHandbookId INT, strName NVARCHAR(200), iLevel INT, TotalDocuments INT, Priority INT, Folders INT, folderType INT, iParentHandbookId INT)
	/* Populate result table with most data including number of valid and invalid documents */
	INSERT INTO @resultTable(iHandbookId, strName, iLevel, TotalDocuments, Priority, Folders, folderType, iParentHandbookId)
	SELECT s.iHandbookId, h.strName, h.iLevel, COUNT(s.iDocumentId), 0, 0, h.iLevelType, h.iParentHandbookId 
	FROM @allApprovedDocuments s join
	m136_tblHandbook h ON s.iHandbookId = h.iHandbookId 
	WHERE (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, s.iHandbookId) & 0x15) > 0
	GROUP BY s.iHandbookId, h.strName, h.iLevel, h.iLevelType, h.iParentHandbookId
	/* Populate table with all handbooks missing from the result set based on documents */
	INSERT INTO @resultTable (iHandbookId, strName, iLevel, TotalDocuments, Priority, Folders, folderType, iParentHandbookId)
	SELECT iHandbookId, strName, iLevel, 0, 0, 0, iLevelType, iParentHandbookId
	FROM m136_tblHandbook 
	WHERE (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 0x15) > 0 
		  AND iHandbookId NOT IN (SELECT iHandbookId FROM @resultTable)
	      AND iHandbookId IN (SELECT iHandbookId FROM @HandbookIdTable)
	/* Set priority - This is only a helper column for reports. We will insert an extra row for all items with 
	level one. This extra row will have priority 1 and the original row will get priority 2
	The row with priority 1 will contain a summary of all folders, valid documents, invalid documents etc recursively */
	UPDATE @resultTable SET Priority = CASE iLevel WHEN 1 THEN 2 ELSE iLevel END
	/* Helper table since we will add more rows to the @resultTable, this helper table is to avoid 
	problems with a cursor on the table we will be modifying */
	DECLARE @tmpResultTable TABLE(iHandbookId INT, strName NVARCHAR(200), folderType INT)
	/* Populate temp table with all handbooks */
	INSERT INTO @tmpResultTable(iHandbookId, strName) 
	SELECT iHandbookId, strName FROM @resultTable
	/* Update resultable with countings of folders */
	DECLARE cur CURSOR FOR
		SELECT iHandbookId FROM @tmpResultTable
	OPEN cur 
	FETCH NEXT FROM cur INTO @iHandbookId
	WHILE @@fetch_status=0
	BEGIN
		UPDATE @resultTable SET Folders = (SELECT COUNT(*) FROM m136_tblHandbook 
											WHERE iParentHandbookId = @iHandbookId AND iDeleted = 0 AND
											(dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 0x15) > 0)
		WHERE iHandbookId = @iHandbookId AND Priority > 1
	FETCH NEXT FROM cur INTO @iHandbookId
	END
	CLOSE cur 
	DEALLOCATE cur
	/* Remove all entries in this helper table and repopulate it with handbooks for level 1 only */
	DELETE FROM @tmpResultTable
	INSERT INTO @tmpResultTable(iHandbookId, strName, folderType) 
	SELECT iHandbookId, strName, folderType FROM @resultTable WHERE iLevel = 1
	-- Create summary columns - Update Priorty 1 records with recursive numbers
	DECLARE cur CURSOR FOR
		SELECT iHandbookId, strName, folderType FROM @tmpResultTable
	OPEN cur
	FETCH NEXT FROM cur INTO @iHandbookId, @strName, @folderType
	WHILE @@fetch_status=0
	BEGIN
		INSERT INTO @resultTable(iHandbookId, strName, iLevel,TotalDocuments, Priority, folderType)
			VALUES(@iHandbookId, @strName, 1, 0, 1, @folderType);
		WITH Children AS
		(
				SELECT 
					iHandbookId 
				FROM 
					@resultTable 
				WHERE
					iHandbookId = @iHandbookId 
			UNION ALL
				SELECT 
					h.iHandbookId 
				FROM 
					@resultTable h
					INNER JOIN Children 
						ON	iParentHandbookId = Children.iHandbookId 
		)
		SELECT 
			iHandbookId 
		INTO #Folders
		FROM 
			Children
		UPDATE @resultTable SET
			TotalDocuments = (SELECT SUM(TotalDocuments) FROM @resultTable WHERE iHandbookId in (select iHandbookId FROM #Folders)),
			Folders = (SELECT COUNT(*) FROM dbo.m136_tblHandbook 
						WHERE iHandbookId IN (select iHandbookId FROM #Folders)
					   ) - 1
		WHERE iHandbookId = @iHandbookId and Priority = 1
		DROP TABLE #Folders;
	FETCH NEXT FROM cur INTO @iHandbookId, @strName, @folderType
	END
	CLOSE cur
	DEALLOCATE cur
	-- Return the result
	SELECT * FROM @resultTable ORDER BY iHandbookId, Priority
END
GO