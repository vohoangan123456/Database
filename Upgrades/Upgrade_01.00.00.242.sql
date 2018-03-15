INSERT INTO #Description VALUES('Create table m136_FlowChart and some procedures to support load images from db4')
GO

IF OBJECT_ID('[dbo].[m136_be_InsertFlowChartImage]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_InsertFlowChartImage] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_InsertFlowChartImage]
	@Name VARCHAR(300),
	@Description VARCHAR(800),
	@ContentType VARCHAR(100),
	@Extension VARCHAR(10),
	@ImageContent IMAGE,
	@JsonContent NVARCHAR(MAX),
    @DocumentId INT,
    @DocumentVersion INT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        INSERT INTO
        m136_FlowChart
            (Name, Description, ContentType, Extension, ImageContent, JsonContent, DocumentId, DocumentVersion)
        VALUES
            (@Name, @Description, @ContentType, @Extension, @ImageContent, @JsonContent, @DocumentId, @DocumentVersion)
    
        SELECT SCOPE_IDENTITY();
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK
END CATCH
END
GO