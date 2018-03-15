INSERT INTO #Description VALUES('Add stored m136_GetApprovedDocumentsByHandbookIdRecursive for getting all documents - includes sub folders.')
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
		   @max = iMax 
		FROM m136_tblHandbook WHERE iHandbookId = @iHandbookId;

    DECLARE @tmp TABLE(handbookId INT NOT NULL PRIMARY KEY);
    INSERT INTO @tmp(handbookId)
        SELECT iHandbookId FROM m136_tblHandbook WHERE iDeleted = 0 AND ((iMin > @min AND iMax < @max) OR iHandbookId = @iHandbookId);

	
	DECLARE @HandbookPermissions TABLE(iHandbookId INT NOT NULL PRIMARY KEY)
    
	INSERT INTO @HandbookPermissions
		SELECT handbookId FROM @tmp 
		WHERE (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, handbookId) & 1) = 1;
		
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
			d.iApproved = 1
			AND d.iDraft = 0
			AND d.iDeleted = 0
			AND d.iLatestApproved = 1
			AND d.iHandbookId in (select iHandbookId from @HandbookPermissions)
			AND 
			(
				(@iHandbookId = 0 OR d.iHandbookId = @iHandbookId)
				OR 
				(
					@iHandbookId > 0
					AND
					d.iHandbookId IN (SELECT handbookId FROM @tmp)
				)
			)
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
			LEFT JOIN @tmp tmp ON tmp.handbookId = virt.iHandbookId
        WHERE
			@iHandbookId > 0
			AND d.iApproved = 1
			AND d.iDraft = 0
			AND d.iDeleted = 0
			AND d.iLatestApproved = 1
			AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) & 1) = 1
	) 
	r ORDER BY r.iSort, r.strName
END
GO