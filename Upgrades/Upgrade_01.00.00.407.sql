INSERT INTO #Description VALUES ('Modify SP [dbo].[m136_be_DeleteDocumentFields] and [dbo].[m136_be_DeleteDocumentTemplates]')
GO

IF OBJECT_ID('[dbo].[m136_be_DeleteDocumentFields]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteDocumentFields] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_DeleteDocumentFields]
	-- Add the parameters for the stored procedure here
	@FieldIds AS [dbo].[Item] READONLY
AS
BEGIN
    DECLARE @Id INT;
	DECLARE cur CURSOR FOR SELECT Id FROM @FieldIds
	OPEN cur
	FETCH NEXT FROM cur INTO @Id
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF EXISTS(SELECT 1 FROM m136_relDocumentTypeInfo WHERE iMetaInfoTemplateRecordsId = @Id)
			BEGIN
				UPDATE dbo.m136_tblMetaInfoTemplateRecords
					SET iDeleted = 1
				WHERE iMetaInfoTemplateRecordsId = @Id;
			END
		ELSE
			BEGIN
				DELETE FROM m136_tblMetaInfoTemplateRecords 
				WHERE iMetaInfoTemplateRecordsId = @Id
			END
		
		FETCH NEXT FROM cur INTO @Id;
	END
	CLOSE cur;
	DEALLOCATE cur;
END
GO


IF OBJECT_ID('[dbo].[m136_be_DeleteDocumentTemplates]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteDocumentTemplates] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_DeleteDocumentTemplates]
	-- Add the parameters for the stored procedure here
	@DocumentTypeIds AS [dbo].[Item] READONLY
AS
BEGIN
	DECLARE @Id INT;
	DECLARE cur CURSOR FOR SELECT Id FROM @DocumentTypeIds
	OPEN cur
	FETCH NEXT FROM cur INTO @Id
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF EXISTS(SELECT 1 FROM m136_tblDocument WHERE iDocumentTypeId = @Id)
			BEGIN
				UPDATE dbo.m136_tblDocumentType
				SET iDeleted = 1
				WHERE iDocumentTypeId = @Id;
			END
		ELSE
			BEGIN
				DELETE FROM m136_relDocumentTypeInfo WHERE iDocumentTypeId = @Id
				
				DELETE FROM m136_tblDocumentType WHERE iDocumentTypeId = @Id
			END
		FETCH NEXT FROM cur INTO @Id;
	END
	CLOSE cur;
	DEALLOCATE cur;
END
GO