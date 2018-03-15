INSERT INTO #Description VALUES('Create stored procedures for document template management.')
GO

IF OBJECT_ID('[dbo].[m136_be_InsertDocumentTemplate]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_InsertDocumentTemplate] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JULY 15, 2015
-- Description:	Create new document template
-- =============================================
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
    
    SELECT @NewDocumentTypeId;
    
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentTypes]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentTypes] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetDocumentTypes]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT dt.iDocumentTypeId
		, dt.strName
		, dt.strDescription
		, dt.iDeleted
		, dt.bIsProcess
		, dt.bInactive
		, dt.ViewMode
		, dt.[Type]
		, dt.HideFieldName
		, dt.HideFieldNumbering
		, dt.iSort 
		, dt.strIcon
	FROM [dbo].[m136_tblDocumentType] dt 
	WHERE dt.iDeleted = 0
		ORDER BY iSort DESC, strName ASC;
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
	
END
GO

IF  NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'Item' AND ss.name = N'dbo')
	CREATE TYPE [dbo].[Item] AS TABLE(
		[Id] [int] NOT NULL,
		[Value] [int] NULL
	)
GO

IF OBJECT_ID('[dbo].[m136_be_DeleteDocumentTemplates]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteDocumentTemplates] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JULY 16, 2015
-- Description:	Delete document templates by ids
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_DeleteDocumentTemplates]
	-- Add the parameters for the stored procedure here
	@DocumentTypeIds AS [dbo].[Item] READONLY
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
	UPDATE dbo.m136_tblDocumentType
	SET
	    dbo.m136_tblDocumentType.iDeleted = 1
	    WHERE dbo.m136_tblDocumentType.iDocumentTypeId IN (SELECT Id FROM @DocumentTypeIds);
END
GO