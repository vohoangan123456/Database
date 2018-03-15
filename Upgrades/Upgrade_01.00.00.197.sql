INSERT INTO #Description VALUES('Update Store Insert folder.')
GO

IF OBJECT_ID('[dbo].[m136_be_InsertFolder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_InsertFolder] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_InsertFolder]
	@iUserId INT,
	@iParentHandbookId	INT,
    @strName			VARCHAR(100),
    @strDescription		VARCHAR(7000),
    @iDepartmentId		INT,
    @iLevelType			INT,
    @iViewTypeId		INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @iParentLevel INT = 0, @iMaxHandbookId INT = 0;
	SELECT @iParentLevel = h.iLevel FROM dbo.m136_tblHandbook h WHERE h.iHandbookId = @iParentHandbookId;
	SELECT @iMaxHandbookId = MAX(ihandbookid) FROM dbo.m136_tblHandbook;
	DECLARE @iNewHandbookId INT = ISNULL(@iMaxHandbookId, 0) + 1;
	SET IDENTITY_INSERT dbo.m136_tblHandbook ON;
    INSERT INTO dbo.m136_tblHandbook(
		iHandbookId,
		iParentHandbookId, 
		strName, 
		strDescription, 
		iDepartmentId, 
		iLevelType, 
		iViewTypeId, 
		dtmCreated, 
		iCreatedById, 
		iDeleted,
		iMin,
		iMax,
		iLevel) 
    VALUES(
		@iNewHandbookId,
		(CASE WHEN @iParentHandbookId = 0 THEN NULL ELSE @iParentHandbookId END), 
		@strName, 
		@strDescription, 
		@iDepartmentId, 
		@iLevelType, 
		(CASE WHEN @iViewTypeId = -1 THEN 1 WHEN @iViewTypeId = -2 THEN 3 END), 
		GETDATE(), 
		@iUserId, 
		0,
		0,
		0,
		(@iParentLevel + 1));
	SET IDENTITY_INSERT dbo.m136_tblHandbook OFF;
	DECLARE @iEntityId INT, @iApplicationId INT, @iSecurityId INT, @iPermisionSetId INT, @iGroupingId INT, @iBit INT
	DECLARE ACL CURSOR FOR 
		SELECT @iNewHandbookId
				, [iApplicationId]
				, iSecurityId
				, [iPermissionSetId]
				, [iGroupingId]
				, [iBit]
			FROM [dbo].[tblACL] 
			WHERE iEntityId = @iParentHandbookId 
				AND iApplicationId = 136
				AND (iPermissionSetId = 461 OR iPermissionSetId = 462);
	OPEN ACL; 
	FETCH NEXT FROM ACL INTO @iEntityId, @iApplicationId, @iSecurityId, @iPermisionSetId, @iGroupingId, @iBit;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF NOT EXISTS(SELECT * FROM dbo.tblACL WHERE iEntityId = @iEntityId 
			AND iApplicationId = @iApplicationId 
			AND iSecurityId = @iSecurityId 
			AND iPermissionSetId  = @iPermisionSetId)
		BEGIN
			INSERT INTO dbo.tblACL VALUES (
			     @iEntityId
				, @iApplicationId
				, @iSecurityId
				, @iPermisionSetId
				, @iGroupingId
				, @iBit);
		END
		ELSE 
		BEGIN
			UPDATE dbo.tblACL
				SET iBit = @iBit,
					iGroupingId = @iGroupingId
			WHERE iEntityId = @iEntityId 
			AND iApplicationId = @iApplicationId 
			AND iSecurityId = @iSecurityId 
			AND iPermissionSetId  = @iPermisionSetId
		END
		FETCH NEXT FROM ACL INTO @iEntityId, @iApplicationId, @iSecurityId, @iPermisionSetId, @iGroupingId, @iBit;
	END
	CLOSE ACL;
	DEALLOCATE ACL;
	SELECT @iNewHandbookId;
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateFolderInformation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateFolderInformation] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_UpdateFolderInformation]
	@FolderId INT,
	@ParentFolderId INT,
	@strName VARCHAR(100),
	@strDescription VARCHAR(700),
	@iDepartmentId INT,
	@iLevelType INT,
	@iViewType INT,
	@InheritNewParentPermissions BIT,
	@Recursive BIT,
	@OldParentFolderId INT
AS
BEGIN
	SET NOCOUNT ON;
    UPDATE [dbo].[m136_tblHandbook] 
    SET strName = @strName,
		iParentHandbookId = (CASE WHEN @ParentFolderId = 0 THEN NULL ELSE @ParentFolderId END),
		strDescription = @strDescription,
		iDepartmentId = @iDepartmentId,
		iLevelType = @iLevelType,
		iViewTypeId = (CASE WHEN @iViewType = -1 THEN 1 WHEN @iViewType = -2 THEN 3 END),
		iLevel = (CASE WHEN @ParentFolderId = 0 THEN 1 ELSE (SELECT  h.iLevel + 1 FROM dbo.m136_tblHandbook h WHERE h.iHandbookId = @ParentFolderId) END)
	WHERE iHandbookId = @FolderId;
	DECLARE @iHandbookId INT,
		@iApplicationId INT, 
		@iSecurityId INT, 
		@iPermissionSetId INT, 
		@iGroupingId INT, 
		@iBit INT;
	IF (@InheritNewParentPermissions = 1)
	BEGIN
		IF (@Recursive = 1)
		BEGIN
			DECLARE @SubFoldersPermission AS [dbo].[ACLDatatable];
			INSERT INTO @SubFoldersPermission 
			SELECT @FolderId 
				, iApplicationId
				, iSecurityId
				, iPermissionSetId
				, iGroupingId
				, iBit
				, 1
			FROM [dbo].[tblACL] WHERE iEntityId = @ParentFolderId
				AND iApplicationId = 136
				AND (iPermissionSetId = 461 OR iPermissionSetId = 462);
			EXEC [dbo].[m136_be_UpdateFolderPermissions] @SubFoldersPermission;
		END --END IF (@Recursive = 1)----------------------------------------------------------------------------------
		ELSE
		BEGIN
			DECLARE @NewParentFolderPermissions AS [dbo].[ACLDatatable];
			INSERT INTO @NewParentFolderPermissions SELECT @FolderId
					, [iApplicationId]
					, iSecurityId
					, [iPermissionSetId]
					, [iGroupingId]
					, [iBit]
					, 0
				FROM [dbo].[tblACL] 
				WHERE iEntityId = @ParentFolderId 
					AND iApplicationId = 136
					AND (iPermissionSetId = 461 OR iPermissionSetId = 462);
			DECLARE ACL CURSOR FOR 
			SELECT iEntityId
					, [iApplicationId]
					, iSecurityId
					, [iPermissionSetId]
					, [iGroupingId]
					, [iBit]
				FROM @NewParentFolderPermissions;
			OPEN ACL; 
			FETCH NEXT FROM ACL INTO @iHandbookId, @iApplicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit;
			WHILE @@FETCH_STATUS = 0
			BEGIN
				IF NOT EXISTS(SELECT * FROM dbo.tblACL WHERE iEntityId = @iHandbookId 
					AND iApplicationId = @iApplicationId 
					AND iSecurityId = @iSecurityId 
					AND iPermissionSetId  = @iPermissionSetId)
				BEGIN
					INSERT INTO dbo.tblACL VALUES (
						 @iHandbookId
						, @iApplicationId
						, @iSecurityId
						, @iPermissionSetId
						, @iGroupingId
						, @iBit);
				END
				ELSE 
				BEGIN
					UPDATE dbo.tblACL
						SET iBit = @iBit,
							iGroupingId = @iGroupingId
					WHERE iEntityId = @iHandbookId 
					AND iApplicationId = @iApplicationId 
					AND iSecurityId = @iSecurityId 
					AND iPermissionSetId  = @iPermissionSetId
				END
				FETCH NEXT FROM ACL INTO @iHandbookId, @iApplicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit;
			END
			CLOSE ACL;
			DEALLOCATE ACL;
			DELETE [dbo].[tblACL] WHERE iEntityId = @FolderId 
				AND iApplicationId = @iApplicationId 
				AND iSecurityId NOT IN (SELECT iSecurityId 
				FROM @NewParentFolderPermissions);
		END
	END
END
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
					   ) 
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