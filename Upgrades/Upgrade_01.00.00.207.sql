INSERT INTO #Description VALUES('Modify procedure m147_be_LinkDocumentToRegisterItemValues')
GO

IF OBJECT_ID('[dbo].[m147_be_LinkDocumentToRegisterItemValues]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_LinkDocumentToRegisterItemValues] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m147_be_LinkDocumentToRegisterItemValues]
    @ItemValues AS [dbo].[LinkDocumentRegisterItemValues] READONLY
AS
BEGIN
    
BEGIN TRY
    BEGIN TRANSACTION;
        DELETE FROM
            m147_relRegisterItemItem
        WHERE
            iItemId IN (SELECT DocumentId FROM @ItemValues)
            AND iRegisterItemValueId IN (SELECT RegisterItemValueId FROM @ItemValues)
            
        INSERT INTO
            m147_relRegisterItemItem
                (iRegisterItemId, iModuleId, iCategoryId, iItemId, iRegisterItemValueId)
            SELECT
                RegisterItemId,
                136,
                0,
                DocumentId,
                RegisterItemValueId
            FROM
                @ItemValues
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK;
END CATCH
    
END
GO