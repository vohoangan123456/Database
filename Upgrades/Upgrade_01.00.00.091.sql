INSERT INTO #Description VALUES('Create stored procedures for document types management.')
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentTypes]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentTypes] AS SELECT 1')
GO
-- =============================================
-- Author:			em.lam.van.mai
-- Create date: July 09, 2015
-- Description:	Get all document types 
-- =============================================
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
	WHERE 
		EXISTS (
				SELECT 
					[iDocumentTypeId]
				FROM
					[dbo].[m136_tblDocument]
				WHERE
					[iDocumentTypeId] = dt.iDocumentTypeId
				);
END
GO


IF OBJECT_ID('[dbo].[m136_be_GetDocumentTypeById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentTypeById] AS SELECT 1')
GO
-- =============================================
-- Author:		em.lam.van.mai
-- Create date: July 09, 2015
-- Description:	Get a specified document type by Id
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetDocumentTypeById]
	@DocumentTypeId INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT  
        [iDocumentTypeId],
        [strName],
        [strDescription],
        [Type],
        [HideFieldNumbering],
        [HideFieldName],
        [bIsProcess],
        [bInactive],
        [ViewMode],
        [strIcon],
        [iSort]                            
    FROM 
        [dbo].[m136_tblDocumentType] dt
    WHERE 
        [iDocumentTypeId] = @DocumentTypeId
END
GO