INSERT INTO #Description VALUES('Modified stored procedure m136_GetDocumentMetatags for reorder metatag value, unclassified group shoud be bottom.')
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentMetatags]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentMetatags] AS SELECT 1')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: Feb 04, 2014
-- Description:	Get List Of Approved Documents By MetatagId
-- =============================================
ALTER PROCEDURE [dbo].[m136_GetDocumentMetatags]
	-- Add the parameters for the stored procedure here
	@iHandbookId int = 0,
	@iRegisterItemId int = 0,
	@bRecursive BIT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @AvailableHandbooks TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	
	IF (@bRecursive = 1)
	BEGIN
		INSERT INTO @AvailableHandbooks 
			SELECT iHandbookId FROM [dbo].[m136_GetHandbookRecursive] (@iHandbookId, NULL, 0);
	END
	ELSE
	BEGIN
		INSERT INTO @AvailableHandbooks SELECT @iHandbookId
	END
	
	SELECT DocumentId, MetatagValue FROM (
		SELECT
			d.iDocumentId AS DocumentId,
			dbo.m136_fnGetItemValue(dt.iAutoId) AS MetatagValue,
			d.iSort
		FROM 
			m136_tblDocument d
            JOIN m136_tblHandbook h on d.iHandbookId = h.iHandbookId
			LEFT OUTER JOIN m147_relRegisterItemItem dt ON d.iDocumentId = dt.iItemId 
				AND (dt.iRegisterItemId = @iRegisterItemId AND dt.iModuleId = 136)
		WHERE d.iLatestApproved = 1
			AND d.iHandbookId in (SELECT iHandbookId FROM @AvailableHandbooks)
	UNION
		SELECT 
			virt.iDocumentId AS DocumentId,
			dbo.m136_fnGetItemValue(dt.iAutoId) AS MetatagValue,
			d.iSort
		FROM 
			m136_relVirtualRelation virt
			JOIN m136_tblDocument d on virt.iDocumentId = d.iDocumentId
			JOIN m136_tblHandbook h on d.iHandbookId = h.iHandbookId
			LEFT OUTER JOIN m147_relRegisterItemItem dt ON d.iDocumentId = dt.iItemId 
				AND (dt.iRegisterItemId = @iRegisterItemId AND dt.iModuleId = 136) 					
		WHERE 	
			d.iLatestApproved = 1
			AND d.iHandbookId in (SELECT iHandbookId FROM @AvailableHandbooks)
	) r
	ORDER BY r.MetatagValue DESC, r.iSort
END
GO