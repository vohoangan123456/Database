INSERT INTO #Description VALUES ('Create table m136_FormulaImages, procedures m136_be_AddFormulaImage, m136_GetFormulaImage')
GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES  WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'm136_FormulaImages'))
BEGIN
    CREATE TABLE [dbo].[m136_FormulaImages]
    (
        Id INT IDENTITY(1, 1) PRIMARY KEY,
        ImageContent IMAGE NOT NULL,
        DocumentId INT,
        DocumentVersion INT
	)
END
GO

IF OBJECT_ID('[dbo].[m136_AddFormulaImage]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_AddFormulaImage] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_AddFormulaImage]
	@ImageContent IMAGE,
    @DocumentId INT,
    @DocumentVersion INT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        INSERT INTO
            m136_FormulaImages
                (ImageContent, DocumentId, DocumentVersion)
            VALUES
                (@ImageContent, @DocumentId, @DocumentVersion)
    
        SELECT SCOPE_IDENTITY();
    COMMIT TRANSACTION;
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

IF OBJECT_ID('[dbo].[m136_GetFormulaImage]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetFormulaImage] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetFormulaImage] 
	@Id INT,
	@DocumentId INT,
	@DocumentVersion INT
AS
BEGIN
	SELECT 
        Id, 
		ImageContent AS imgContent
	FROM
        m136_FormulaImages
	WHERE
        Id = @Id
		AND DocumentId = @DocumentId 
		AND DocumentVersion = @DocumentVersion;
END
GO