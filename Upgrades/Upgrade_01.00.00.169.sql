INSERT INTO #Description VALUES('Modify procedure m136_be_RestoreDocuments')
GO

IF OBJECT_ID('[dbo].[m136_be_RestoreDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_RestoreDocuments] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_RestoreDocuments] 
	@UserId INT,
	@DocumentIds AS Item READONLY
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
		iDeleted = 0,
        iAlterId = @UserId,
        strAlterer = @FullName
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