INSERT INTO #Description VALUES('Modify stored procedure m136_GetMetadataGroupsRecursive and m136_GetDocumentMetatags for extracting a function that get handbook recursive.')
GO

IF OBJECT_ID('[dbo].[m136_GetHandbookRecursive]', 'IF') IS NULL
    EXEC ('CREATE FUNCTION [dbo].[m136_GetHandbookRecursive] () RETURNS TABLE AS RETURN (SELECT 0 AS [id]);')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: Feb 05, 2015
-- Description:	Get all handbookId of sub folders.
-- =============================================
ALTER FUNCTION [dbo].[m136_GetHandbookRecursive]
(	
	@iHandbookId INT,
	@iSecurityId INT,
	@bCheckSecurity BIT
)
RETURNS TABLE
AS
RETURN 
(
    WITH Children AS
	(
			SELECT 
				iHandbookId 
			FROM 
				[dbo].[m136_tblHandbook] 
			WHERE
				iHandbookId = @iHandbookId 
				AND iDeleted = 0
				
		UNION ALL
		
			SELECT 
				h.iHandbookId 
			FROM 
				[dbo].[m136_tblHandbook] h
				INNER JOIN Children 
					ON	iParentHandbookId = Children.iHandbookId 
						AND h.iDeleted = 0
	)
	SELECT 
		iHandbookId 
	FROM 
		Children
	WHERE 
		(@bCheckSecurity = 0 OR [dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1)
)
GO


IF OBJECT_ID('[dbo].[m136_GetMetadataGroupsRecursive]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetMetadataGroupsRecursive] AS SELECT 1')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: Feb 03, 2015
-- Description:	Create stored procedure for getting metadata-group recursive.
-- =============================================
ALTER PROCEDURE [dbo].[m136_GetMetadataGroupsRecursive]
(	
	@iSecurityId INT,
	@iHandbookId INT
) AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @AvailableHandbooks TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	
	INSERT INTO @AvailableHandbooks	
		SELECT iHandbookId FROM [dbo].[m136_GetHandbookRecursive](@iHandbookId, @iSecurityId, 1);
		
	SELECT DISTINCT 
		rel.iRegisterItemId,
		regitem.strName AS strTagName,
		reg.strName AS strRegisterName
	FROM m147_relRegisterItemItem rel
		LEFT OUTER JOIN m147_tblRegisterItem regitem ON rel.iRegisterItemId = regitem.iRegisterItemId
		LEFT OUTER JOIN m147_tblRegister reg ON regitem.iRegisterId = reg.iRegisterId
	WHERE
		rel.iModuleId = 136
		AND rel.iRegisterItemId > 0
		AND iItemId IN 
			(SELECT iDocumentId FROM m136_tbldocument d WHERE iHandbookId IN 
				(SELECT iHandbookId FROM @AvailableHandbooks))
	ORDER BY
		strRegisterName ASC,
		strTagName ASC
END
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
		
	SELECT * FROM (
		SELECT
			d.iDocumentId AS DocumentId,
			dbo.m136_fnGetItemValue(dt.iAutoId) AS MetatagValue
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
			dbo.m136_fnGetItemValue(dt.iAutoId) AS MetatagValue
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
	ORDER BY r.MetatagValue
END
GO
