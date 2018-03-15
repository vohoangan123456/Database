INSERT INTO #Description VALUES('Fix get parent handbookIds. Check null for iParentId')
GO

IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetParentIdsInTbl]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	EXEC ('CREATE FUNCTION [dbo].[m136_GetParentIdsInTbl] () RETURNS TABLE AS RETURN (SELECT 0 AS [iHandbookId]);')
GO

ALTER  function [dbo].[m136_GetParentIdsInTbl]
(
@iChapterId INT
)
RETURNS @retTable TABLE(iHandbookId INT NOT NULL)
AS
BEGIN
	DECLARE @iParentId INT;
	SELECT @iParentId = ISNULL(iParentHandbookId,0) FROM dbo.m136_tblHandbook WHERE iHandbookId = @iChapterId
	IF (@iParentId <> 0 AND @iParentId IS NOT NULL)
	BEGIN
		INSERT INTO @retTable VALUES(@iParentId);
		INSERT INTO @retTable SELECT iHandbookId FROM dbo.m136_GetParentIdsInTbl(@iParentId);
	END
	RETURN;
END
GO