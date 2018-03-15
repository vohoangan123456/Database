INSERT INTO #Description VALUES ('Modify - [dbo].[m136_be_GetDocumentTypeById]')
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
        [iDeleted],
        [Type],
        [HideFieldNumbering],
        [HideFieldName],
        [bIsProcess],
        [bInactive],
        [ViewMode],
        [strIcon],
        [iSort],
        [iDeleted]
    FROM 
        [dbo].[m136_tblDocumentType] dt
    WHERE 
        [iDocumentTypeId] = @DocumentTypeId
END
GO
