INSERT INTO #Description VALUES('Create stored procedures for document fields management.')
GO

IF OBJECT_ID('[dbo].[m136_be_GetFields]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetFields] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetFields]
	-- Add the parameters for the stored procedure here
	@iFieldId INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT [iMetaInfoTemplateRecordsId]
		, mitr.[strName]
		, mitr.[strDescription]
		, mitr.[iInfoTypeId]
		, mitr.[DefaultIntValue]
		, mitr.[DefaultTextValue]
		, mitr.[DefaultDateValue]
		, mitr.[iFlag]
		, mitr.[iDeleted]
		, mitr.iFieldProcessType	
		, mtit.strName AS TypeName
	FROM [dbo].[m136_tblMetaInfoTemplateRecords] mitr
	JOIN dbo.m136_tblInfoType mtit ON mtit.iInfoTypeId = mitr.iInfoTypeId
	WHERE mitr.iDeleted = 0
		AND (@iFieldId IS NULL OR mitr.iMetaInfoTemplateRecordsId = @iFieldId);
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetFieldTypes]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetFieldTypes] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetFieldTypes]
	-- Add the parameters for the stored procedure here
	@iFieldTypeId INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT mtit.iInfoTypeId, mtit.strName, mtit.strDescription 
	FROM dbo.m136_tblInfoType mtit
	WHERE mtit.iInfoTypeId = @iFieldTypeId OR @iFieldTypeId IS NULL;
END
GO

IF OBJECT_ID('[dbo].[m136_be_InsertDocumentField]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_InsertDocumentField] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JULY 20, 3015
-- Description:	Create new document field 
-- =============================================
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
END
GO

IF OBJECT_ID('[dbo].[m136_be_DeleteDocumentFields]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteDocumentFields] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JULY 20, 2015
-- Description:	Delete document fields
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_DeleteDocumentFields]
	-- Add the parameters for the stored procedure here
	@FieldIds AS [dbo].[Item] READONLY
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    UPDATE dbo.m136_tblMetaInfoTemplateRecords
    SET
        iDeleted = 1
	    WHERE iMetaInfoTemplateRecordsId IN (SELECT Id FROM @FieldIds);
END
GO