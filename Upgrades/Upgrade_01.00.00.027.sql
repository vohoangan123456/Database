INSERT INTO #Description VALUES('Modify function [dbo].[fnHasDocumentAttachment]: only check iRelationTypeId = 20.')
GO

IF OBJECT_ID('[dbo].[fnHasDocumentAttachment]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[fnHasDocumentAttachment]() RETURNS BIT AS BEGIN RETURN 0; END')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: DEC 11, 2014
-- Description:	Check a document has attachment
-- =============================================
ALTER FUNCTION [dbo].[fnHasDocumentAttachment]
(
	@iEntityId	INT
)
RETURNS BIT
AS
BEGIN
	IF EXISTS (SELECT 1 FROM dbo.m136_relInfo r WHERE r.iEntityId = @iEntityId AND r.iRelationTypeId = 20) RETURN 1;
	RETURN 0;
END
GO