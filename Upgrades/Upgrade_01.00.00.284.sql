INSERT INTO #Description VALUES ('Modify procedure m136_be_IsDocumentTemplateExpired')
GO

IF OBJECT_ID('[dbo].[m136_be_IsDocumentTemplateExpired]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_IsDocumentTemplateExpired] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_IsDocumentTemplateExpired]
    @DocumentId INT
AS
BEGIN
    IF EXISTS (
                SELECT 1 
                FROM
                    m136_tblDocument d
                        INNER JOIN m136_tblDocumentType dt ON d.iDocumentTypeId = dt.iDocumentTypeId
                WHERE
                    d.iDocumentId = @DocumentId
                    AND d.iLatestVersion = 1
                    AND
                    (
                        dt.Type = 0
                        OR dt.iDeleted = 1
                        OR dt.bInactive = 1
                    )
            )        
    BEGIN
        SELECT 1
    END
    ELSE
    BEGIN
        SELECT 0
    END
END
GO