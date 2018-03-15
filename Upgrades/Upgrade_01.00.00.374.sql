INSERT INTO #Description VALUES ('Add SP [dbo].[m136_GetRecentlyApprovedDocumentsForFolder]')
GO

IF OBJECT_ID('[dbo].[m136_GetRecentlyApprovedDocumentsForFolder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetRecentlyApprovedDocumentsForFolder] AS SELECT 1')
GO


ALTER PROCEDURE [dbo].[m136_GetRecentlyApprovedDocumentsForFolder] 
	@iDaysLimit INT,
	@maxCount INT,
	@FolderId INT,
	@IncludeSubFolder BIT,
	@UserId INT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @Now DATETIME = GETDATE();
	IF @IncludeSubFolder = 0
	BEGIN
		SELECT TOP (@maxCount)
			d.iDocumentId as Id,
			d.iHandbookId,
			d.strName,
			d.iDocumentTypeId,
			d.iVersion as [Version],
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			h.strName as ParentFolderName,
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
			h.iLevelType AS LevelType,
			h.iDepartmentId As DepartmentId,
			d.iInternetDoc
		FROM
			m136_tblDocument d
			INNER JOIN m136_tblHandbook h 
				ON d.iHandbookId = h.iHandbookId
   		WHERE 
			d.iLatestApproved = 1
			AND d.iReceiptsCopied = 0
			AND DATEDIFF(d, ISNULL(d.dtmApproved, CONVERT(DATETIME, '01.01.1970', 104)), @Now) <  @iDaysLimit
			AND h.iHandbookId = @FolderId
		ORDER BY
			d.dtmApproved DESC
	END
	ELSE
	BEGIN
		DECLARE @AvailableHandbooks TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
		INSERT INTO @AvailableHandbooks 
			SELECT iHandbookId FROM [dbo].[m136_GetHandbookRecursive] (@FolderId, @UserId, 1);
			
		SELECT TOP (@maxCount)
			d.iDocumentId as Id,
			d.iHandbookId,
			d.strName,
			d.iDocumentTypeId,
			d.iVersion as [Version],
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			h.strName as ParentFolderName,
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
			h.iLevelType AS LevelType,
			h.iDepartmentId As DepartmentId,
			d.iInternetDoc
		FROM
			m136_tblDocument d
			INNER JOIN m136_tblHandbook h 
				ON d.iHandbookId = h.iHandbookId
   		WHERE 
			d.iLatestApproved = 1
			AND d.iReceiptsCopied = 0
			AND DATEDIFF(d, ISNULL(d.dtmApproved, CONVERT(DATETIME, '01.01.1970', 104)), @Now) <  @iDaysLimit
			AND h.iHandbookId IN ( SELECT iHandbookId FROM @AvailableHandbooks)
		ORDER BY
			d.dtmApproved DESC
	END
END
GO