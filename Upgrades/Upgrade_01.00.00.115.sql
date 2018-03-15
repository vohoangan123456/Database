INSERT INTO #Description VALUES('Create stored procedures for sorting document types.')
GO

IF OBJECT_ID('[dbo].[m136_be_SortingDocumentTypes]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_SortingDocumentTypes] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: OCT 23, 2015
-- Description:	Sorting document types.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_SortingDocumentTypes] 
	@DocumentTypes AS [dbo].[Item] READONLY
AS
BEGIN
	SET NOCOUNT ON;
	
	UPDATE dt
	SET
	    dt.iSort = dt1.Value
	FROM dbo.m136_tblDocumentType dt
	INNER JOIN @DocumentTypes dt1 ON dt1.Id = dt.iDocumentTypeId
END
GO


IF OBJECT_ID('[dbo].[m136_be_ResetSortingDocumentTypes]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_ResetSortingDocumentTypes] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: OCT 23, 2015
-- Description:	Reset order of document types
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_ResetSortingDocumentTypes]
	
AS
BEGIN
	SET NOCOUNT ON;

    UPDATE dbo.m136_tblDocumentType
    SET dbo.m136_tblDocumentType.iSort = 0 -- int
        WHERE dbo.m136_tblDocumentType.iDeleted = 0
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
	DECLARE @iCount INT;
	SELECT @iCount = COUNT(*) FROM dbo.m136_tblDocumentType mtdt WHERE mtdt.iDeleted = 0;
	
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
		, case when (dt.iSort IS NULL OR dt.iSort = 0) THEN @iCount
		ELSE dt.iSort END AS iSort
		, dt.strIcon
	FROM [dbo].[m136_tblDocumentType] dt 
	WHERE dt.iDeleted = 0
		ORDER BY iSort ASC, LOWER(LTRIM(strName)) COLLATE SQL_Latin1_General_CP1_CI_AS ASC; --Latin1_General_CS_AS
END
GO