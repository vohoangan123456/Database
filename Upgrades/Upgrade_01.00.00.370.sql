INSERT INTO #Description VALUES ('Create procedure m136_be_GetDocumentTemplatesUseField')
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentTemplatesUseField]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentTemplatesUseField] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetDocumentTemplatesUseField]
	@FieldId INT
AS
BEGIN
    SELECT
        dt.iDocumentTypeId,
        dt.strName
    FROM
        m136_tblDocumentType dt
            INNER JOIN m136_relDocumentTypeInfo rdti ON dt.iDocumentTypeId = rdti.iDocumentTypeId
    WHERE
        (dt.bInactive IS NULL OR dt.bInactive = 0)
        AND rdti.iMetaInfoTemplateRecordsId = @FieldId
END
GO