INSERT INTO #Description VALUES('Create stored procedure m136_GetMetadataGroups for getting metadata group.')
GO

IF OBJECT_ID('[dbo].[m136_GetMetadataGroups]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetMetadataGroups] AS SELECT 1')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: Feb 03, 2015
-- Description:	Create stored procedure for getting metadata-group.
-- =============================================
ALTER PROCEDURE [dbo].[m136_GetMetadataGroups]
(
	@iHandbookId INT
) AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT
		DISTINCT rel.iRegisterItemId,
		regitem.strName AS strTagName,
		reg.strName AS strRegisterName
	FROM m147_relRegisterItemItem rel
		LEFT OUTER JOIN m147_tblRegisterItem regitem ON rel.iRegisterItemId = regitem.iRegisterItemId
		LEFT OUTER JOIN m147_tblRegister reg ON regitem.iRegisterId = reg.iRegisterId
	WHERE
		rel.iModuleId = 136
		AND rel.iRegisterItemId > 0
		AND iItemId IN (SELECT iDocumentId FROM m136_tbldocument d WHERE iHandbookid = @iHandbookId AND d.iDeleted = 0)
	ORDER BY
		strRegisterName ASC,
		strTagName ASC
END
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

    DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
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
	INSERT INTO @AvailableChildren(iHandbookId)
		SELECT 
			iHandbookId 
		FROM 
			Children
		WHERE 
			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1;
			
	SELECT
		DISTINCT rel.iRegisterItemId,
		regitem.strName AS strTagName,
		reg.strName AS strRegisterName
	FROM m147_relRegisterItemItem rel
		LEFT OUTER JOIN m147_tblRegisterItem regitem ON rel.iRegisterItemId = regitem.iRegisterItemId
		LEFT OUTER JOIN m147_tblRegister reg ON regitem.iRegisterId = reg.iRegisterId
	WHERE
		rel.iModuleId = 136
		AND rel.iRegisterItemId > 0
		AND iItemId IN (SELECT iDocumentId FROM m136_tbldocument d WHERE iHandbookId IN (SELECT iHandbookId FROM @AvailableChildren))
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
	@iSecurityId int = 0,
	@iHandbookId int = 0,
	@iRegisterItemId int = 0,
	@bRecursive BIT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
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
					AND @bRecursive = 1
	)
	INSERT INTO @AvailableChildren(iHandbookId)
		SELECT 
			iHandbookId 
		FROM 
			Children
		WHERE 
			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1;
	
	SELECT * FROM (
		SELECT
			d.iDocumentId AS Id, 
			d.strName, 
			d.iDocumentTypeId,
			dbo.m147_fnGetItemValue(dt.iAutoId) AS MetatagValue,
			ISNULL(dt.iAutoId, -1) AS MetatagId,
            d.iVersion,
            NULL AS LevelType,
            d.dtmApproved,
            d.strApprovedBy,
            dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			NULL AS DepartmentId,
			0 AS Virtual,
			d.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(h.iHandbookId) as Path,         
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment			
		FROM 
			m136_tblDocument d
            JOIN m136_tblDocumentType t on d.iDocumentTypeId = t.iDocumentTypeId
            JOIN m136_tblHandbook h on d.iHandbookId = h.iHandbookId
			LEFT OUTER JOIN m147_relRegisterItemItem dt ON d.iDocumentId = dt.iItemId AND (dt.iRegisterItemId = @iRegisterItemId AND dt.iModuleId = 136)
		WHERE d.iLatestApproved = 1
			AND d.iHandbookId in (SELECT iHandbookId FROM @AvailableChildren)
	UNION
		SELECT 
			virt.iDocumentId AS Id, 
			d.strName, 
			d.iDocumentTypeId,
			dbo.m147_fnGetItemValue(dt.iAutoId) AS MetatagValue,
			ISNULL(dt.iAutoId, -1) AS MetatagId,
			d.iVersion,
			NULL AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			NULL AS DepartmentId,
			1 AS Virtual,
			virt.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(h.iHandbookId) as Path, 
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment
		FROM 
			m136_relVirtualRelation virt
			JOIN m136_tblDocument d on virt.iDocumentId = d.iDocumentId
			JOIN m136_tblHandbook h on d.iHandbookId = h.iHandbookId
			LEFT OUTER JOIN m147_relRegisterItemItem dt ON d.iDocumentId = dt.iItemId AND (dt.iRegisterItemId = @iRegisterItemId AND dt.iModuleId = 136) 					
		WHERE 	
			d.iLatestApproved = 1
			AND d.iHandbookId in (SELECT iHandbookId FROM @AvailableChildren)
	) r
	ORDER BY r.iSort, r.strName
END

