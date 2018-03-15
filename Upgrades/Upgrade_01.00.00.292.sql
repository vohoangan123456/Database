INSERT INTO #Description VALUES ('Create procedure m136_be_ChangePrintOrientation')
GO

IF OBJECT_ID('[dbo].[m136_be_ChangePrintOrientation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_ChangePrintOrientation] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_ChangePrintOrientation]
	@DocumentId AS INT,
	@Orientation AS INT
AS
BEGIN

    UPDATE m136_tblDocument
    SET iOrientation = @Orientation
    WHERE
        iDocumentId = @DocumentId
        AND iLatestVersion = 1
        
END
GO