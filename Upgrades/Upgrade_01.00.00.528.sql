INSERT INTO #Description VALUES ('Modify procedure [m136_spReportDocumentsPerFolderPerStatus] ')
GO

IF OBJECT_ID('[dbo].[m136_spReportDocumentsPerFolderPerStatus]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_spReportDocumentsPerFolderPerStatus] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_spReportDocumentsPerFolderPerStatus]
@iParentHandbookId INT = 0,
@iSecurityId INT = 0
AS
BEGIN
/* 
	This stored procedure creates a result set which returns the count of documents with various status.
	Important to note: Rows with iLevel = 1 contains the accumelated sum of documents recursivly for all sub folders beneath this folder 
	And extra row is added to the result set for all iLevel = 1 rows. This row is manipulated so I get iPriority = 2 in the result set.
	All other rows gets iPriority = iLevel. This is so you can separate the two rows, i.e that is the accumulated row from the regular row 
	of the rot level item. In addition the result set will be sorted on iMin, iPriority.
	So the result set will equal the menu listing of the items.
*/
DECLARE @iHandbookId INT
DECLARE @strName NVARCHAR(200)
DECLARE @folderType INT
DECLARE @iSort INT
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
DECLARE @allDocumentsWithStatus TABLE
(
	iEntityId INT, 
	iHandbookId INT, 
	iDocumentId INT, 
	strName NVARCHAR(200), 
	iVersion INT, 
	iApproved INT, 
	iDraft INT, 
	iStatus INT,
	iLatestVersion INT,
	iLatestApproved INT
);
DECLARE @allApprovedDocuments TABLE
(
	iDocumentId INT, 
	iVersion INT
);

/* Find all approved documents and latest version */
INSERT INTO @allApprovedDocuments(iDocumentId, iVersion)
SELECT doc.iDocumentId, doc.iVersion 
FROM m136_tblDocument doc 
JOIN (
	SELECT iDocumentId, MAX(iVersion) AS iVersion 
	FROM m136_tblDocument 
	WHERE iApproved IN (1,4) 
		AND iHandbookId IN (SELECT iHandbookId FROM @HandbookIdTable)
		AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 0x15) > 0
	GROUP BY iDocumentId
) result
ON (doc.iDocumentId = result.iDocumentId AND doc.iVersion = result.iVersion)
WHERE doc.iApproved = 1
ORDER BY doc.iDocumentId 

/* Populate temporary table with status for each document */
INSERT INTO @allDocumentsWithStatus(iEntityId, iHandbookId, iDocumentId, strName, iVersion, iApproved, iDraft, iStatus, iLatestVersion, iLatestApproved)
SELECT d.iEntityId,
	d.iHandbookId, 
	d.iDocumentId, 
	d.strName, 
	d.iVersion, 
	d.iApproved, 
	d.iDraft, 
	dbo.m136_fnGetVersionStatus(
		d.iEntityId, 
		d.iDocumentId, 
		d.iVersion, 
		d.dtmPublish, 
		d.dtmPublishUntil, 
		getDate(), 
		d.iDraft, 
		d.iApproved
	) AS iVersionStatus,
	d.iLatestVersion,
	d.iLatestApproved
FROM m136_tblDocument d 
JOIN @allApprovedDocuments t 
	ON (t.iDocumentId = d.iDocumentId 
		AND t.iVersion = d.iVersion)
WHERE d.iDeleted = 0 
	AND d.iHandbookId IN (SELECT iHandbookId FROM @HandbookIdTable)
	AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) & 0x15) > 0
	
/* Create temporary table to hold the end result */
DECLARE @resultTable TABLE
(
	iHandbookId INT, 
	strName NVARCHAR(200), 
	iLevel INT, 
	ValidDocuments INT, 
	InvalidDocuments INT, 
	InvalidDocumentsUnderRevision INT, 
	InProgressDocuments INT,
	TotalDocuments INT, 
	Priority INT, 
	Folders INT, 
	folderType INT, 
	iParentHandbookId INT, 
	iSort INT
);

/* Populate result table with most data including number of valid and invalid documents */
INSERT INTO @resultTable(iHandbookId, strName, iLevel, TotalDocuments, Priority, Folders, ValidDocuments, InvalidDocuments, InvalidDocumentsUnderRevision, InProgressDocuments, folderType,iParentHandbookId, iSort )
SELECT s.iHandbookId, 
	h.strName, 
	h.iLevel, 
	0, 
	0, 
	0, 
	SUM(dbo.m136_fnIsDocumentValid(s.iStatus))  AS ValidDocuments, 
	SUM(dbo.m136_fnIsDocumentInvalid(s.iStatus, s.iDraft, s.iApproved, s.iDocumentId, s.iVersion)) AS InvalidDocuments,
	SUM(dbo.m136_fnIsDocumentInvalidAndUnderRevision(s.iStatus, s.iDraft, s.iApproved, s.iDocumentId, s.iVersion)) AS InvalidDocumentsUnderRevision,
	SUM(dbo.m136_fnIsDocumentInProgress(s.iVersion, s.iLatestVersion, s.iLatestApproved)) AS InProgressDocuments,
	h.iLevelType, 
	h.iParentHandbookId, 
	h.iSort
FROM @allDocumentsWithStatus s 
JOIN m136_tblHandbook h 
	ON s.iHandbookId = h.iHandbookId 
WHERE (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, s.iHandbookId) & 0x15) > 0
GROUP BY s.iHandbookId, 
		h.strName, 
		h.iLevel,  
		h.iLevelType, 
		h.iParentHandbookId, 
		h.iSort

--update previous handbook number of inprogress document
UPDATE e
SET e.InProgressDocuments = d.NumberOfDocuments	
FROM @resultTable e
JOIN (
	SELECT SUM(dbo.m136_fnIsDocumentInProgress(d.iVersion, d.iLatestVersion, d.iLatestApproved)) AS NumberOfDocuments,
		d.iHandbookId
	FROM m136_tblDocument d
	WHERE d.iDeleted = 0
	GROUP BY d.iHandbookId
)d ON d.iHandbookId = e.iHandbookId


-- find all document inprocess
INSERT INTO @resultTable(iHandbookId, strName, iLevel, TotalDocuments, Priority, Folders, ValidDocuments, InvalidDocuments, InvalidDocumentsUnderRevision, InProgressDocuments, folderType, iParentHandbookId, iSort)
SELECT d.iHandbookId,
	h.strName,
	h.iLevel, 
	0, 
	0, 
	0,
	0,
	0,
	0,
	SUM(dbo.m136_fnIsDocumentInProgress(d.iVersion, d.iLatestVersion, d.iLatestApproved)) AS InProgressDocuments,
	h.iLevelType, 
	h.iParentHandbookId, 
	h.iSort
FROM m136_tblDocument d
JOIN m136_tblHandbook h 
	ON d.iHandbookId = h.iHandbookId
WHERE d.iHandbookId NOT IN (SELECT iHandbookId FROM @resultTable)
	AND d.iHandbookId IN (SELECT iHandbookId FROM @HandbookIdTable)
	AND d.iDeleted = 0
GROUP BY d.iHandbookId, 
		h.strName, 
		h.iLevel,  
		h.iLevelType, 
		h.iParentHandbookId, 
		h.iSort
			
/* Populate table with all handbooks missing from the result set based on documents */
INSERT INTO @resultTable (iHandbookId, strName, iLevel, TotalDocuments, Priority, ValidDocuments, InvalidDocuments, InvalidDocumentsUnderRevision, InProgressDocuments, Folders, folderType,iParentHandbookId, iSort )
SELECT iHandbookId, 
	strName, 
	iLevel, 
	0, 
	0, 
	0, 
	0,
	0, 
	0,
	0, 
	iLevelType, 
	iParentHandbookId, 
	iSort
FROM m136_tblHandbook 
WHERE (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 0x15) > 0 
	AND iHandbookId NOT IN (SELECT iHandbookId FROM @resultTable)
	AND iHandbookId IN (SELECT iHandbookId FROM @HandbookIdTable)
	AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 0x15) > 0
	
/* Set priority - This is only a helper column for reports. We will insert an extra row for all items with 
level one. This extra row will have priority 1 and the original row will get priority 2
The row with priority 1 will contain a summary of all folders, valid documents, invalid documents etc recursively */
UPDATE @resultTable SET Priority = CASE iLevel WHEN 1 THEN 2 ELSE iLevel END

/* Helper table since we will add more rows to the @resultTable, this helper table is to avoid 
problems with a cursor on the table we will be modifying */
DECLARE @tmpResultTable TABLE
(
	iHandbookId INT, 
	strName NVARCHAR(200), 
	folderType INT, 
	iSort INT
)

/* Populate temp table with all handbooks */
INSERT INTO @tmpResultTable(iHandbookId, strName,iSort) 
SELECT iHandbookId, strName, iSort 
FROM @resultTable

/* Update resultable with countings of folders */
DECLARE cur CURSOR FOR
	SELECT iHandbookId FROM @tmpResultTable
OPEN cur 
FETCH NEXT FROM cur INTO @iHandbookId
WHILE @@fetch_status=0
BEGIN
	UPDATE @resultTable 
	SET Folders = (SELECT count(*) 
					FROM m136_tblHandbook 
					WHERE iParentHandbookId = @iHandbookId 
						AND iDeleted = 0 
						AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, @iHandbookId) & 0x15) > 0)
	WHERE iHandbookId = @iHandbookId 
		AND Priority > 1
FETCH NEXT FROM cur INTO @iHandbookId
END
CLOSE cur 
DEALLOCATE cur

/* Remove all entries in this helper table and repopulate it with handbooks for level 1 only */
DELETE FROM @tmpResultTable
INSERT INTO @tmpResultTable(iHandbookId, strName, folderType, iSort) 
SELECT iHandbookId, strName, folderType, iSort 
FROM @resultTable 
WHERE iParentHandbookId IS NULL

IF NOT EXISTS(SELECT 1 FROM @tmpResultTable)
BEGIN
	INSERT INTO @tmpResultTable(iHandbookId, strName, folderType, iSort) 
	SELECT iHandbookId, strName, folderType, iSort 
	FROM @resultTable 
	WHERE Priority = (SELECT MIN(Priority) FROM @resultTable)
END

-- Create summary columns - Update Priorty 1 records with recursive numbers
DECLARE cur CURSOR FOR
	SELECT iHandbookId, strName, folderType, iSort FROM @tmpResultTable
OPEN cur
FETCH NEXT FROM cur INTO @iHandbookId, @strName, @folderType, @iSort
WHILE @@fetch_status=0
BEGIN
	INSERT INTO @resultTable(iHandbookId, strName, iLevel, ValidDocuments, InvalidDocuments, InvalidDocumentsUnderRevision, InProgressDocuments, TotalDocuments, Priority, folderType, iSort)
	VALUES(@iHandbookId, @strName, 1, 0, 0, 0, 0, 0, 1, @folderType, @iSort);
	WITH Children AS
		(
			SELECT iHandbookId 
			FROM @resultTable 
			WHERE iHandbookId = @iHandbookId 
		UNION ALL
			SELECT h.iHandbookId 
			FROM @resultTable h
			INNER JOIN Children 
				ON iParentHandbookId = Children.iHandbookId 
		)
		SELECT iHandbookId 
		INTO #Folders
		FROM Children
		
	UPDATE @resultTable 
	SET 
		ValidDocuments = (SELECT SUM(ValidDocuments) 
							FROM @resultTable 
							WHERE iHandbookId IN (SELECT iHandbookId FROM #Folders)),
		InvalidDocuments = (SELECT SUM(InvalidDocuments) 
							FROM @resultTable 
							WHERE iHandbookId IN (SELECT iHandbookId FROM #Folders)),
		InvalidDocumentsUnderRevision = (SELECT SUM(InvalidDocumentsUnderRevision) 
											FROM @resultTable 
											WHERE iHandbookId IN (SELECT iHandbookId FROM #Folders)),
		InProgressDocuments = (SELECT SUM(InProgressDocuments) 
											FROM @resultTable 
											WHERE iHandbookId IN (SELECT iHandbookId FROM #Folders)),
		Folders = (SELECT COUNT(*) 
					FROM m136_tblHandbook 
					WHERE iDeleted = 0 
						AND iHandbookId IN (SELECT iHandbookId FROM #Folders) 
						AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 0x15) > 0)
	WHERE iHandbookId = @iHandbookId AND Priority = 1
DROP TABLE #Folders;
FETCH NEXT FROM cur INTO @iHandbookId, @strName, @folderType, @iSort
END
CLOSE cur
DEALLOCATE cur

-- Update the total column with final values
UPDATE @resultTable 
SET TotalDocuments = ValidDocuments + InvalidDocuments + InvalidDocumentsUnderRevision

-- Return the result
SELECT * FROM @resultTable WHERE iHandbookId > 0 ORDER BY iSort, strName
END
GO