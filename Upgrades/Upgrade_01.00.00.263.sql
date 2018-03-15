INSERT INTO #Description VALUES('Create SP for Copy Document')
GO

IF OBJECT_ID('[dbo].[m136_be_CopyDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_CopyDocument] AS SELECT 1')
GO
-- =============================================
-- Author:		SI.MANH.NGUYEN
-- Create date: April 14, 2016
-- Description:	Copy Document
-- Modified: add transaction
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_CopyDocument] 
	@DocumentId AS INT,
	@DocumentName AS VARCHAR(200),
	@FolderId AS INT,
	@UserId AS INT
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION 
			DECLARE @iDocumentId INT

			DECLARE @NewEntityId INT
			DECLARE @OldEntityId INT
			DECLARE @DocumentTypeId INT
			
			SELECT @OldEntityId = iEntityId,
				   @DocumentTypeId = iDocumentTypeId
			FROM dbo.m136_tblDocument
			WHERE iDocumentId = @DocumentId 
				  AND iLatestVersion = 1
			
			DECLARE @MaxEntityId INT;
			SELECT @MaxEntityId = MAX(mtd.iEntityId) FROM dbo.m136_tblDocument mtd;
			SET @NewEntityId = ISNULL(@MaxEntityId,0) + 1;
			DECLARE @CurrentDate DATETIME = GETDATE();
			
			SET NOCOUNT ON;
			DECLARE @iMaxDocumentId INT = 0, @iMaxEntityId INT = 0, @Sort INT, @LevelType INT;
			SELECT @LevelType = iLevelType FROM dbo.m136_tblHandbook WHERE iHandbookId = @FolderId
			SELECT @iMaxDocumentId = MAX(iDocumentId) FROM dbo.m136_tblDocument;
			DECLARE @iNewDocumentId INT = ISNULL(@iMaxDocumentId,0) + 1;
			
			SELECT @Sort = ISNULL(MAX(iSort) + 1, 0) FROM (SELECT 0 iSort
					FROM dbo.m136_tblDocument d
					WHERE d.iHandbookId = @FolderId AND d.iDeleted = 0
					AND d.iLatestVersion = 1
				UNION all
					SELECT 1 iSort
					FROM dbo.m136_tblDocument d
					WHERE d.iLatestVersion = 1) Temp
					
			SET IDENTITY_INSERT dbo.m136_tblDocument ON;
			INSERT INTO	dbo.m136_tblDocument( [iEntityId],[iDocumentId],[iVersion],[iDocumentTypeId],[iHandbookId],[strName],[strDescription],[iCreatedbyId],[dtmCreated],[strAuthor]
								  ,[iAlterId],[dtmAlter],[strAlterer],[iApprovedById],[dtmApproved],[strApprovedBy],[dtmPublish],[dtmPublishUntil],[iStatus],[iSort]
								  ,[iDeleted],[iApproved],[iDraft],[iLevelType],[strHash],[iReadCount],[iCompareToVersion],[File],[UrlOrFileName],[UrlOrFileProperties]
								  ,[iLatestVersion],[iInternetDoc],[strNameReversed],[strDescriptionReversed]
								  )
			SELECT				  @NewEntityId,@iNewDocumentId, 0 ,[iDocumentTypeId],@FolderId,@DocumentName,[strDescription],@UserId,@CurrentDate,[strAuthor]
								  ,@UserId,@CurrentDate,[dbo].fnOrgGetUserName(@UserId, '', 0),0,null,'',[dtmPublish],[dtmPublishUntil],0,@Sort
								  ,0,0,1,@LevelType,[strHash],0,0,[File],[UrlOrFileName],[UrlOrFileProperties]
								  ,1,[iInternetDoc],[strNameReversed],[strDescriptionReversed]
			FROM		dbo.m136_tblDocument d
			WHERE		iEntityId = @OldEntityId; 
			SET IDENTITY_INSERT dbo.m136_tblDocument OFF;
			
			EXEC [dbo].[m136_be_UpdateRelatedInfo] @OldEntityId, @NewEntityId, 1
			EXEC [dbo].[m136_be_UpdateContentFields] @OldEntityId, @NewEntityId, @DocumentTypeId
			
			EXEC dbo.m136_SetVersionFlags @iNewDocumentId
			
			SELECT @iNewDocumentId
		COMMIT
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK
		DECLARE @ErrorMessage nvarchar(MAX), @ErrorNumber int, @ErrorSeverity int, @ErrorState int, @ErrorLine int
		SELECT @ErrorMessage = N'Error %d, Line %d, Message: '+ERROR_MESSAGE(),@ErrorNumber = ERROR_NUMBER(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(),@ErrorLine = ERROR_LINE();
		RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber,@ErrorLine);
	END CATCH
END
GO