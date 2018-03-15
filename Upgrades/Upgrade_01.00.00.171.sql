INSERT INTO #Description VALUES('Modify stored procedure for edit document template fields')
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateDocumentTemplateInfo]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateDocumentTemplateInfo] AS SELECT 1')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JULY 31, 2015
-- Description:	Update document template information
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateDocumentTemplateInfo]
	@iDocumentTypeId INT,
	@MetaInfo AS [dbo].[DocumentTypeInfoTable] READONLY
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @iEntityId INT, 
		@_iDocumentTypeId INT, 
		@iMetaInfoTemplateRecordsId INT, 
		@iSort INT, 
		@iDeleted INT, 
		@iShowOnPDA INT,
		@iMandatory INT,
		@iMaximized INT;
	DECLARE Metainfo CURSOR FOR 
		SELECT iEntityId 
			, iDocumentTypeId
			, iMetaInfoTemplateRecordsId
			, iSort
			, iDeleted
			, iShowOnPDA
			, iMandatory
			, iMaximized
		FROM @MetaInfo;
	OPEN Metainfo; 
	FETCH NEXT FROM Metainfo INTO @iEntityId, @_iDocumentTypeId, @iMetaInfoTemplateRecordsId, @iSort, @iDeleted, @iShowOnPDA, @iMandatory, @iMaximized;
	WHILE @@FETCH_STATUS = 0
    BEGIN
		IF EXISTS(SELECT * FROM  dbo.m136_relDocumentTypeInfo mrdti WHERE mrdti.iDocumentTypeInfoId = @iEntityId 
			OR (mrdti.iDocumentTypeId = @iDocumentTypeId AND mrdti.iMetaInfoTemplateRecordsId = @iMetaInfoTemplateRecordsId))
		BEGIN
			UPDATE dbo.m136_relDocumentTypeInfo
			SET
			    dbo.m136_relDocumentTypeInfo.iSort = @iSort,
			    dbo.m136_relDocumentTypeInfo.iDeleted = @iDeleted,
			    dbo.m136_relDocumentTypeInfo.iShowOnPDA = @iShowOnPDA,
			    dbo.m136_relDocumentTypeInfo.iMandatory = @iMandatory,
			    dbo.m136_relDocumentTypeInfo.iMaximized = @iMaximized
			WHERE (iDocumentTypeInfoId = @iEntityId) 
				OR (iDocumentTypeId = @iDocumentTypeId AND iMetaInfoTemplateRecordsId = @iMetaInfoTemplateRecordsId)
		END
		ELSE
		BEGIN
			DECLARE @NewDocumentTypeInfoId INT;
			SELECT @NewDocumentTypeInfoId = MAX(iDocumentTypeInfoId) FROM dbo.m136_relDocumentTypeInfo mrdti;
			SET IDENTITY_INSERT dbo.m136_relDocumentTypeInfo ON;
			INSERT INTO dbo.m136_relDocumentTypeInfo
			(
			    iDocumentTypeInfoId,
			    iDocumentTypeId,
			    iMetaInfoTemplateRecordsId,
			    iSort,
			    iDeleted,
			    iShowOnPDA,
			    iMandatory,
			    iMaximized
			)
			VALUES
			(
			    (ISNULL(@NewDocumentTypeInfoId, 0) + 1),
			    @iDocumentTypeId,
			    @iMetaInfoTemplateRecordsId,
			    @iSort,
			    @iDeleted,
			    @iShowOnPDA,
			    @iMandatory,
			    @iMaximized
			);
		END
		FETCH NEXT FROM Metainfo INTO @iEntityId, @iDocumentTypeId, @iMetaInfoTemplateRecordsId, @iSort, @iDeleted, @iShowOnPDA, @iMandatory, @iMaximized;
	END
	CLOSE Metainfo;
	DEALLOCATE Metainfo;
	DELETE [dbo].[m136_relDocumentTypeInfo] WHERE iDocumentTypeId = @iDocumentTypeId
		AND iMetaInfoTemplateRecordsId NOT IN (SELECT iMetaInfoTemplateRecordsId 
		FROM @MetaInfo WHERE [@MetaInfo].iDocumentTypeId = @iDocumentTypeId);
END
GO