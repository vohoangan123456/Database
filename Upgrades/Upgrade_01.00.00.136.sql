INSERT INTO #Description VALUES('Modify stored procedures related to refactoring feature delete documents.')
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentInformationByEntityIds]', 'p') IS NOT NULL
    EXEC ('DROP PROCEDURE [dbo].[m136_be_GetDocumentInformationByEntityIds]')
GO

IF OBJECT_ID('[dbo].[m136_be_DeleteSingleDocument]', 'p') IS NOT NULL
    EXEC ('DROP PROCEDURE [dbo].[m136_be_DeleteSingleDocument]')
GO

IF OBJECT_ID('[dbo].[m136_be_DeleteMultipleDocument]', 'p') IS NOT NULL
    EXEC ('DROP PROCEDURE [dbo].[m136_be_DeleteMultipleDocument]')
GO

IF OBJECT_ID('[dbo].[m136_be_DeleteDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteDocuments] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_DeleteDocuments]
	@UserId AS INT,
	@DocumentIds AS [dbo].[Item] READONLY
AS
BEGIN
	DECLARE @FullName NVARCHAR(100);
	DECLARE @DocumentId INT;
	DECLARE CurDocumentId CURSOR FOR
		SELECT Id From @DocumentIds;
		
	SELECT
		@FullName = strFirstName + ' ' + strLastName
	FROM
		tblEmployee
	WHERE
		iEmployeeId = @UserId

	UPDATE
		m136_tblDocument
	SET
		iDeleted = 1,
		iAlterId = @UserId,
		strAlterer = @FullName
	WHERE
		iDocumentId IN (SELECT Id FROM @DocumentIds)
		
	DELETE
		FROM m136_relVirtualRelation
	WHERE
		iDocumentId IN (SELECT Id FROM @DocumentIds)
	
	OPEN CurDocumentId;
	FETCH NEXT FROM CurDocumentId INTO @DocumentId;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC m136_SetVersionFlags @DocumentId;
		FETCH NEXT FROM CurDocumentId INTO @DocumentId;
	END
	CLOSE CurDocumentId;
	DEALLOCATE CurDocumentId;
END
GO