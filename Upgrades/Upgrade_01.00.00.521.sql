INSERT INTO #Description VALUES ('Modify procedure for clear cache frontend when update document template')
GO

IF OBJECT_ID('[dbo].[m136_be_InsertDocumentTemplate]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_InsertDocumentTemplate] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_InsertDocumentTemplate]
	-- Add the parameters for the stored procedure here
	@strName VARCHAR(100),
	@strDescription VARCHAR(4000),
	@bIsProcess BIT,
	@bInactive BIT,
	@ViewMode INT,
	@Type INT,
	@HideFieldNumbering BIT,
	@HideFieldName BIT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @iMaxDocumentTypeId INT, @iMaxiSort INT;
	
	SELECT @iMaxDocumentTypeId = MAX(dt.iDocumentTypeId), @iMaxiSort = MAX(iSort) FROM [dbo].[m136_tblDocumentType] dt;
	DECLARE @NewDocumentTypeId INT = (ISNULL(@iMaxDocumentTypeId, 0) + 1);
	SET IDENTITY_INSERT dbo.m136_tblDocumentType ON;
	
    INSERT INTO  dbo.m136_tblDocumentType
    (
        iDocumentTypeId, -- this column value is auto-generated
        strName,
        strDescription,
        iDeleted,
        strIcon,
        bIsProcess,
        bInactive,
        ViewMode,
        [Type],
        HideFieldNumbering,
        HideFieldName,
        iSort
    )
    VALUES
    (
        @NewDocumentTypeId,
        @strName, 
        @strDescription, 
        0, 
        '', 
        @bIsProcess, 
        @bInactive, 
        @ViewMode, 
        @Type, 
        @HideFieldNumbering, 
        @HideFieldName, 
        (ISNULL(@iMaxiSort, 0) + 1) 
    );
    
    SET IDENTITY_INSERT dbo.m136_tblDocumentType OFF;
    
    INSERT INTO CacheUpdate (ActionType, EntityId) VALUES (12, 0)
    
    SELECT @NewDocumentTypeId;
    
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateDocumentTemplate]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateDocumentTemplate] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JULY 16, 2015
-- Description:	Update document template
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateDocumentTemplate]
	-- Add the parameters for the stored procedure here
	@iDocumentTypeId INT,
	@strName VARCHAR(100),
	@strDescription VARCHAR(4000),
	@bIsProcess BIT,
	@bInactive BIT,
	@ViewMode INT,
	@Type INT,
	@HideFieldNumbering BIT,
	@HideFieldName BIT,
	@iSort INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    UPDATE dbo.m136_tblDocumentType
    SET
        strName			= @strName,
        strDescription	= @strDescription,
        bIsProcess		= @bIsProcess,
        bInactive		= @bInactive,
        ViewMode		= @ViewMode,
        [Type]			= @Type,
        HideFieldNumbering = @HideFieldNumbering,
        HideFieldName	= @HideFieldName,
        iSort			= @iSort
    WHERE dbo.m136_tblDocumentType.iDocumentTypeId = @iDocumentTypeId;
    
	INSERT INTO CacheUpdate (ActionType, EntityId) VALUES (12, 0)
		
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
	
	INSERT INTO CacheUpdate (ActionType, EntityId) VALUES (12, 0)
	
END
GO

IF OBJECT_ID('[dbo].[m136_be_InsertDocumentField]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_InsertDocumentField] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_InsertDocumentField]
	-- Add the parameters for the stored procedure here
	@strName VARCHAR(100),
	@strDescription VARCHAR(4000),
	@iInfoTypeId INT,
	@iFlag INT,
	@iFieldProcessType INT,
	@DefaultIntValue INT,
	@DefaultTextValue VARCHAR(7000),
	@DefaultDateValue DATETIME
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @iMaxDocumentFieldTypeId INT;
	SELECT @iMaxDocumentFieldTypeId = MAX(mtmitr.iMetaInfoTemplateRecordsId) FROM [dbo].[m136_tblMetaInfoTemplateRecords] mtmitr;
	DECLARE @NewDocumentFieldTypeId INT = (ISNULL(@iMaxDocumentFieldTypeId, 0) + 1);
	SET IDENTITY_INSERT dbo.m136_tblMetaInfoTemplateRecords ON;
	
    INSERT INTO dbo.m136_tblMetaInfoTemplateRecords
    (
        iMetaInfoTemplateRecordsId, -- this column value is auto-generated
        strName,
        strDescription,
        iInfoTypeId,
        DefaultIntValue,
        DefaultTextValue,
        DefaultDateValue,
        iFlag,
        iDeleted,
        iFieldProcessType
    )
    VALUES
    (
        @NewDocumentFieldTypeId, -- iMetaInfoTemplateRecordsId - int
        @strName, -- strName - varchar
        @strDescription, -- strDescription - varchar
        @iInfoTypeId, -- iInfoTypeId - int
        @DefaultIntValue, -- DefaultIntValue - int
        @DefaultTextValue, -- DefaultTextValue - varchar
        @DefaultDateValue, -- DefaultDateValue - datetime
        @iFlag, -- iFlag - int
        0, -- iDeleted - int
        @iFieldProcessType -- iFieldProcessType - int
    )
    
    SET IDENTITY_INSERT dbo.m136_tblMetaInfoTemplateRecords OFF;
    
	INSERT INTO CacheUpdate (ActionType, EntityId) VALUES (12, 0)
	
	SELECT @NewDocumentFieldTypeId;
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateDocumentField]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateDocumentField] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JULY 20, 2015
-- Description:	Update document field
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateDocumentField]
	-- Add the parameters for the stored procedure here
	@iFieldId INT,
	@strName VARCHAR(100),
	@strDescription VARCHAR(4000),
	@iInfoTypeId INT,
	@DefaultIntValue INT,
	@DefaultTextValue VARCHAR(7000),
	@DefaultDateValue DATETIME,
	@iFlag INT,
	@iFieldProcessType INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	UPDATE dbo.m136_tblMetaInfoTemplateRecords
	SET
	    strName = @strName, -- varchar
	    strDescription = @strDescription, -- varchar
	    iInfoTypeId = @iInfoTypeId, -- int
	    DefaultIntValue = @DefaultIntValue, -- int
	    DefaultTextValue = @DefaultTextValue, -- varchar
	    DefaultDateValue = @DefaultDateValue, -- datetime
	    iFlag = @iFlag, -- int
	    iFieldProcessType = @iFieldProcessType -- int
	WHERE iMetaInfoTemplateRecordsId = @iFieldId;
	
	INSERT INTO CacheUpdate (ActionType, EntityId) VALUES (12, 0)
END
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
	
	INSERT INTO CacheUpdate (ActionType, EntityId) VALUES (12, 0)
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateDocumentTemplateInfo]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateDocumentTemplateInfo] AS SELECT 1')
GO

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
		@iMaximized INT,
        @iPublish INT;
        
	DECLARE Metainfo CURSOR FOR 
		SELECT iEntityId 
			, iDocumentTypeId
			, iMetaInfoTemplateRecordsId
			, iSort
			, iDeleted
			, iShowOnPDA
			, iMandatory
			, iMaximized
            , iPublish
		FROM @MetaInfo;
	OPEN Metainfo; 
	FETCH NEXT FROM Metainfo INTO @iEntityId, @_iDocumentTypeId, @iMetaInfoTemplateRecordsId, @iSort, @iDeleted, @iShowOnPDA, @iMandatory, @iMaximized, @iPublish;
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
			    dbo.m136_relDocumentTypeInfo.iMaximized = @iMaximized,
                dbo.m136_relDocumentTypeInfo.iPublish = @iPublish
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
			    iMaximized,
                iPublish
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
			    @iMaximized,
                @iPublish
			);
		END
		FETCH NEXT FROM Metainfo INTO @iEntityId, @iDocumentTypeId, @iMetaInfoTemplateRecordsId, @iSort, @iDeleted, @iShowOnPDA, @iMandatory, @iMaximized, @iPublish;
	END
	CLOSE Metainfo;
	DEALLOCATE Metainfo;
	DELETE [dbo].[m136_relDocumentTypeInfo] WHERE iDocumentTypeId = @iDocumentTypeId
		AND iMetaInfoTemplateRecordsId NOT IN (SELECT iMetaInfoTemplateRecordsId 
		FROM @MetaInfo WHERE [@MetaInfo].iDocumentTypeId = @iDocumentTypeId);
	
	INSERT INTO CacheUpdate (ActionType, EntityId) VALUES (12, 0)
END
GO