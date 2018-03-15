INSERT INTO #Description VALUES('Create procedure  [dbo].[m136_be_ReopenDocument] ')
GO

IF OBJECT_ID('[dbo].[m136_be_ReopenDocument]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_ReopenDocument]  AS SELECT 1')
GO

-- =============================================
-- Author:		SI.MANH.NGUYEN
-- Create date: Nov 18, 2015
-- Description:	Reopon document after document is archived
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_ReopenDocument] 
	@DocumentIds AS [dbo].[Item] READONLY,
	@UserId INT
AS
BEGIN
	DECLARE @iDocumentId INT
	DECLARE @Description VARCHAR(2000)
	DECLARE @LogDescription VARCHAR(2000)
	DECLARE @NewEntityId INT
	DECLARE @OldEntityId INT
	DECLARE @Version INT
	DECLARE @DocumentTypeId INT
	
	DECLARE curDocumentId CURSOR FOR 
		SELECT Id
		FROM @DocumentIds;
	OPEN curDocumentId; 
	FETCH NEXT FROM curDocumentId INTO @iDocumentId;
	WHILE @@FETCH_STATUS = 0
    BEGIN
    
		SELECT @OldEntityId = iEntityId,
			   @Description = strDescription,
			   @Version = iVersion,
			   @DocumentTypeId = iDocumentTypeId
		FROM dbo.m136_tblDocument
		WHERE iDocumentId = @iDocumentId 
			  AND iLatestVersion = 1
			  
		SELECT @LogDescription = [Description]
		FROM dbo.tblEventlog
		WHERE DocumentId = @iDocumentId
			  AND [Version] = @Version
			  AND EventType = 11
			  AND Id = (SELECT MAX(Id) FROM dbo.tblEventlog WHERE DocumentId = @iDocumentId
						  AND [Version] = @Version
						  AND EventType = 11)
						  
		IF @LogDescription IS NOT NULL
		BEGIN
			IF (CHARINDEX(@LogDescription,@Description) = 1)
			BEGIN
				DECLARE @NewDescription VARCHAR(2000)
				SET @NewDescription = SUBSTRING(@Description,LEN(@LogDescription) + 1 ,LEN(@Description))
				
				UPDATE dbo.m136_tblDocument
				SET strDescription = @NewDescription
				WHERE iEntityId = @OldEntityId
			END
		END
		--Create new version
		IF @OldEntityId IS NOT NULL AND @iDocumentId IS NOT NULL
		BEGIN
			DECLARE @ResultSet table (SelectedValue int)
			
			INSERT INTO @ResultSet (SelectedValue)
			EXEC [dbo].[m136_be_CreateNewDocumentVersion] @UserId, @OldEntityId, @iDocumentId
			SELECT @NewEntityId = SelectedValue FROM @ResultSet
			
			IF @NewEntityId IS NOT NULL AND @NewEntityId != 0
			BEGIN
				EXEC [dbo].[m136_be_UpdateRelatedInfo] @OldEntityId, @NewEntityId, 1
				EXEC [dbo].[m136_be_UpdateContentFields] @OldEntityId, @NewEntityId, @DocumentTypeId	
			END
		END
		
		FETCH NEXT FROM curDocumentId INTO @iDocumentId;
	END
	CLOSE curDocumentId;
	DEALLOCATE curDocumentId;
END
GO

