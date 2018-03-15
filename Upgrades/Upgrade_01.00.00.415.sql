INSERT INTO #Description VALUES ('Modify SP [dbo].[m136_GetChapterItemsAndTagsForMobile]')
GO

IF OBJECT_ID('[dbo].[m136_GetChapterItemsAndTagsForMobile]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetChapterItemsAndTagsForMobile] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetChapterItemsAndTagsForMobile]
	@ChapterId INT = NULL,
	@PageSize INT,
	@PageIndex INT,
	@SecurityId INT,
	@RegisterItemId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	SELECT *, ROW_NUMBER() OVER (ORDER BY iSort ASC, Name ASC) AS rowNumber
	INTO #ReturnRecords
	FROM
	(
			SELECT	d.iEntityId,
					d.iDocumentId as Id,
					d.strName as Name,
					d.iDocumentTypeId AS DocumentTypeId,					
					d.iLevelType as LevelType,
					null as DepartmentId,
					0 as Virtual,
					d.iSort,
					NULL as ParentFolderName,
					dbo.fn136_GetParentPathEx(d.iHandbookId) as Path,
					0 as ViewType
			FROM	m136_tblDocument d
			WHERE	d.iHandbookId = @ChapterId
				AND d.iLatestApproved = 1
				AND (dbo.fnSecurityGetPermission(136, 462, @SecurityId, d.iHandbookId)&1)=1
		UNION
			SELECT	d.iEntityId,
					v.iDocumentId as Id,
					d.strName as Name,
					d.iDocumentTypeId AS DocumentTypeId,
					d.iLevelType as LevelType,
					null as DepartmentId,
					1 as Virtual,
					v.iSort,
					h.strName as ParentFolderName,
					dbo.fn136_GetParentPathEx(h.iHandbookId) as Path,
					0 as ViewType
			FROM	m136_relVirtualRelation v
				INNER JOIN m136_tblDocument d 
					ON d.iDocumentId = v.iDocumentId
				INNER JOIN m136_tblHandbook h
					ON d.iHandbookId = h.iHandbookId
			WHERE	v.iHandbookId = @ChapterId
				AND d.iLatestApproved = 1
				AND (dbo.fnSecurityGetPermission(136, 462, @SecurityId, d.iHandbookId)&1)=1
		UNION
			SELECT	0 as iEntityId,
					h.iHandbookId as Id,
					h.strName as Name,
					-1 as DocumentTypeId,
					iLevelType as LevelType,
					h.iDepartmentId as DepartmentId,
					0 as Virtual,
					-2147483648 + h.iMin as iSort,
					NULL as ParentFolderName,
					dbo.fn136_GetParentPathEx(h.iHandbookId) as Path,
					ISNULL(iViewTypeId, -1) as ViewType
			FROM	m136_tblHandbook as h
			WHERE	(h.iParentHandbookId = @ChapterId OR (h.iParentHandbookId IS NULL AND @ChapterId IS NULL))
				AND h.iDeleted = 0
				AND (dbo.fnSecurityGetPermission(136, 461, @SecurityId, h.iHandbookId) & 0x11) > 0
		)OneTable
	

	IF(@PageSize = 0)
		BEGIN
			SELECT * FROM #ReturnRecords
			SELECT COUNT(1) FROM #ReturnRecords
		END
	ELSE
		BEGIN
			SELECT * FROM #ReturnRecords
			WHERE RowNumber BETWEEN @PageSize * @PageIndex + 1 AND @PageSize * (@PageIndex + 1)
			SELECT COUNT(1) FROM #ReturnRecords
		END
		
	IF @ChapterId IS NOT NULL
	BEGIN
		DECLARE @ViewType INT	
		SELECT	0 as iEntityId,
					h.iHandbookId as Id,
					h.strName as Name,
					-1 as DocumentTypeId,
					iLevelType as LevelType,
					h.iDepartmentId as DepartmentId,
					0 as Virtual,
					-2147483648 + h.iMin as iSort,
					NULL as ParentFolderName,
					dbo.fn136_GetParentPathEx(h.iHandbookId) as Path,
					ISNULL(iViewTypeId, -1) as ViewType
		INTO #Information
		FROM	m136_tblHandbook as h
		WHERE	h.iHandbookId = @ChapterId
			AND h.iDeleted = 0
			AND (dbo.fnSecurityGetPermission(136, 461, @SecurityId, @ChapterId) & 0x11) > 0
		IF @RegisterItemId IS NULL
		BEGIN		
			SELECT @ViewType = ViewType
			FROM #Information
			IF @ViewType > 10
				BEGIN
					SET @ViewType = @ViewType - 10
				END
			SET @RegisterItemId = @ViewType
		END
		
		SELECT *
		FROM #Information
		
		SELECT
			DISTINCT rel.iRegisterItemId AS RegisterItemId,
			reg.strName + ': ' + regitem.strName AS Name,
			@ChapterId AS ChapterId,
			val.iRegisterItemValueId AS RegisterItemValueId,
			val.RegisterValue,
			val.iSort
		FROM m147_relRegisterItemItem rel
			LEFT OUTER JOIN m147_tblRegisterItem regitem ON rel.iRegisterItemId = regitem.iRegisterItemId
			LEFT OUTER JOIN m147_tblRegister reg ON regitem.iRegisterId = reg.iRegisterId
			LEFT OUTER JOIN dbo.m147_tblRegisterItemValue val ON rel.iRegisterItemValueId = val.iRegisterItemValueId
		WHERE
			rel.iModuleId = 136
			AND rel.iRegisterItemId > 0
			AND iItemId IN (SELECT iDocumentId FROM m136_tbldocument d WHERE iHandbookid = @ChapterId AND d.iDeleted = 0 AND d.iLatestApproved = 1
			AND d.dtmPublish <= GETDATE())
		ORDER BY
			Name ASC, iSort, RegisterValue
		
		SELECT
			DISTINCT rel.iRegisterItemId AS RegisterItemId,
			reg.strName + ': ' + regitem.strName AS Name,
			@ChapterId AS ChapterId,
			val.iRegisterItemValueId AS RegisterItemValueId,
			val.RegisterValue,
			val.iSort
		FROM m147_relRegisterItemItem rel
			LEFT OUTER JOIN m147_tblRegisterItem regitem ON rel.iRegisterItemId = regitem.iRegisterItemId
			LEFT OUTER JOIN m147_tblRegister reg ON regitem.iRegisterId = reg.iRegisterId
			LEFT OUTER JOIN dbo.m147_tblRegisterItemValue val ON rel.iRegisterItemValueId = val.iRegisterItemValueId
		WHERE
			rel.iModuleId = 136
			AND rel.iRegisterItemId = @RegisterItemId
			AND iItemId IN (SELECT iDocumentId FROM m136_tbldocument d WHERE iHandbookid = @ChapterId AND d.iDeleted = 0 AND d.iLatestApproved = 1
			AND d.dtmPublish <= GETDATE())
		ORDER BY
			Name ASC , iSort, RegisterValue	
			
		DROP TABLE #Information
	END
	
	DROP TABLE #ReturnRecords
END
GO