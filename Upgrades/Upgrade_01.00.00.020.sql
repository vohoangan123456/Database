INSERT INTO #Description VALUES('Add stored m136_GetApprovedDocumentsByHandbookIdRecursive for getting all documents - includes sub folders.')
GO

IF OBJECT_ID('[dbo].[fnHandbookHasReadContentsAccess]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[fnHandbookHasReadContentsAccess]() RETURNS BIT AS BEGIN RETURN 0; END')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: DEC 09, 2014
-- Description:	Check the permission read content of handbook
-- =============================================
ALTER FUNCTION [dbo].[fnHandbookHasReadContentsAccess]
(
	@iSecurityId INT,
	@iHandbookId INT
)
RETURNS BIT
AS
BEGIN
	IF (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, @iHandbookId) & 1 = 1) RETURN 1;
	RETURN 0;
END
GO

IF OBJECT_ID('[dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive] AS SELECT 1 a')
GO

-- =============================================
-- Author:  EM.LAM.VAN.MAI
-- Created date: DEC 05, 2014
-- Description: Get approved documents by handbookId and all documents of sub chapters.
-- =============================================
ALTER PROCEDURE [dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive] 
	-- Add the parameters for the stored procedure here
	@iHandbookId INT = 0,
	@iSecurityId INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- INTerfering with SELECT statements.
	SET NOCOUNT ON;
	
    DECLARE @min INT, @max INT;
    SELECT @min = iMin, 
		   @max = iMax FROM m136_tblHandbook WHERE iHandbookId = @iHandbookId;

	WITH Children AS
	(
		SELECT iHandbookId FROM [dbo].[m136_tblHandbook] 
			WHERE iHandbookId = @iHandbookId AND iDeleted = 0
		UNION ALL
		SELECT h.iHandbookId FROM [dbo].[m136_tblHandbook] h
			INNER JOIN Children ON iParentHandbookId = Children.iHandbookId AND h.iDeleted = 0
	)
	SELECT iHandbookId INTO #Children FROM Children WHERE [dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, @iHandbookId) = 1;

    SELECT * FROM (
        SELECT distinct 
            d.iDocumentId AS Id, 
            h.iHandbookId,
            d.strName, 
            d.iDocumentTypeId AS TemplateId, 
            ISNULL(t.Type, 0) AS DocumentType,
            d.iVersion AS [Version],
            h.iLevelType AS LevelType,
            d.dtmApproved,
            d.strApprovedBy,
            dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
            NULL AS DepartmentId,
            0 AS Virtual,
            d.iSort,
			h.strName AS ParentFolderName,
        dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path]
		FROM 
			m136_tblDocument d
            JOIN m136_tblDocumentType t ON d.iDocumentTypeId = t.iDocumentTypeId
            JOIN m136_tblHandbook h ON d.iHandbookId=h.iHandbookId
        WHERE
			d.iDeleted = 0
			AND d.iLatestApproved = 1
			AND d.iHandbookId IN (SELECT iHandbookId FROM #Children)
    UNION       
        SELECT 
            d.iDocumentId AS Id, 
            h.iHandbookId,
            d.strName, 
            d.iDocumentTypeId AS TemplateId,
            ISNULL(t.Type, 0) AS DocumentType,
            d.iVersion AS [Version],
            h.iLevelType AS LevelType,
            d.dtmApproved,
            d.strApprovedBy,
            dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
            NULL AS DepartmentId,
            1 AS Virtual,
            d.iSort,
			h.strName AS ParentFolderName,
        dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path]
		FROM 
			m136_tblDocument d
            JOIN m136_tblDocumentType t ON d.iDocumentTypeId = t.iDocumentTypeId
            JOIN m136_tblHandbook h ON d.iHandbookId=h.iHandbookId
			JOIN m136_relVirtualRelation virt ON virt.iDocumentId = d.iDocumentId
        WHERE
			d.iDeleted = 0
			AND d.iLatestApproved = 1
			AND d.iHandbookId IN (SELECT iHandbookId FROM #Children)
	) 
	r ORDER BY r.iSort, r.strName;
	
	DROP TABLE #Children;
END
GO