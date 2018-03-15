INSERT INTO #Description VALUES ('Create SP [dbo].[m136_GetUserEmailSubscriptionsForFoldersAndDocuments]')
GO

IF OBJECT_ID('[dbo].[m136_GetUserEmailSubscriptionsForFoldersAndDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetUserEmailSubscriptionsForFoldersAndDocuments] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetUserEmailSubscriptionsForFoldersAndDocuments]
	@iSecurityId INT
AS
SET NOCOUNT ON
BEGIN

	DECLARE @iUserDepId INT;
	SELECT @iUserDepId = iDepartmentId FROM tblEmployee WHERE iEmployeeId = @iSecurityId;
	
	SELECT
		h.iHandbookId,	
		h.strName,
		h.iLevelType,
		h.iDepartmentId as DepartmentId,
		sb.iEmail RecursiveFolder,
		sb.iEmailFolder OnlyFolder,
		CASE
			WHEN @iUserDepId = h.iDepartmentId THEN 1
			ELSE 0
		END AS isDepartment
	FROM	
		m136_tblHandbook h
		INNER JOIN m136_tblSubscribe sb
			ON h.iHandbookId = sb.iHandbookId AND sb.iEmployeeId = @iSecurityId
	WHERE
		h.iDeleted = 0
		AND sb.iEmployeeId = @iSecurityId
		AND (sb.iEmail = 1 OR sb.iEmailFolder = 1)
	ORDER BY
		sb.iEmail,
		h.strName
		
	SELECT
		d.iHandbookId,
		d.strName,
		d.iDocumentId, 
		d.iDocumentTypeId,
		sb.iSort
	FROM	
		dbo.m136_tblDocument d
		INNER JOIN dbo.m136_tblSubscriberDocument sb
			ON d.iDocumentId = sb.iDocumentId AND sb.iEmployeeId = @iSecurityId
				AND d.iLatestApproved = 1
	WHERE
		d.iDeleted = 0
		AND d.iLatestApproved = 1
		AND sb.iEmployeeId = @iSecurityId
		AND (sb.iEmail = 1)
	
END
GO