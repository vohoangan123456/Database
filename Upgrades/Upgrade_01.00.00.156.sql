INSERT INTO #Description VALUES('Modify m136_be_ChangeDocumentType')
GO

IF OBJECT_ID('[dbo].[m136_be_ChangeDocumentType]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_ChangeDocumentType] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_ChangeDocumentType]
	@UserId AS INT,
	@DocumentId AS INT,
	@DocumentTypeId AS INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
    
            DECLARE @OldEntityId INT;
            DECLARE @NewEntityId INT;
            
            SELECT
                @OldEntityId = iEntityId
            FROM
                dbo.m136_tblDocument
            WHERE
                iDocumentId = @DocumentId 
                AND iLatestVersion = 1
                AND iApproved = 1

            EXEC @NewEntityId = dbo.m136_be_CreateNewDocumentVersionWithDocumetTypeId @UserId, @OldEntityId, @DocumentId, @DocumentTypeId;
            
            EXEC [dbo].[m136_be_UpdateRelatedInfo] @OldEntityId, @NewEntityId, 1
    
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
			ROLLBACK
    END CATCH
END
GO