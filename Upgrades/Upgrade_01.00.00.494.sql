INSERT INTO #Description VALUES ('Update Get CreatedBy for FlowChart')
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
    @IsTemplate BIT,
    @DocumentId INT,
    @DocumentVersion INT,
    @CreatedBy INT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        IF @IsTemplate = 1
        BEGIN
            UPDATE m136_FlowChart
            SET Deleted = 1
            WHERE  IsTemplate = 1 AND Description = @Description
        END
        INSERT INTO
        m136_FlowChart
            (Name, Description, ContentType, Extension, ImageContent, JsonContent, IsTemplate, DocumentId, DocumentVersion, CreatedBy)
        VALUES
            (@Name, @Description, @ContentType, @Extension, @ImageContent, @JsonContent, @IsTemplate, @DocumentId, @DocumentVersion, @CreatedBy)
        SELECT SCOPE_IDENTITY();
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK
END CATCH
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetFlowChartTemplates]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetFlowChartTemplates] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetFlowChartTemplates]
	@Identity nvarchar(50),
	@Userid INT
AS
BEGIN
    SELECT
        Id, Name, Description, CASE WHEN CreatedBy = @Userid THEN 1 ELSE 0 END AS IsCreator
    FROM
        m136_FlowChart
    WHERE
        Name LIKE '%' + @Identity + '%'
        AND IsTemplate = 1 
        AND (Deleted IS NULL OR Deleted = 0)
END
GO
