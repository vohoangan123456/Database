INSERT INTO #Description VALUES ('Update SP [dbo].[m136_be_GetParentsIncludeSelf]')
GO

IF OBJECT_ID('[dbo].[m136_be_GetParentsIncludeSelf]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetParentsIncludeSelf] AS SELECT 1')
GO
ALTER  PROCEDURE [dbo].[m136_be_GetParentsIncludeSelf]
	@iItemId INT,
	@isFolder BIT,
	@isBackend BIT
AS
BEGIN
	DECLARE @idTable table(iHandbookId int not null)
	DECLARE @seedId int;
	IF(@isFolder = 1)
		BEGIN
			SET @seedId = @iItemId;
			INSERT INTO @idTable 
			VALUES (@iItemId)
		END 
	ELSE
		BEGIN
			SELECT 
				@seedId = doc.iHandbookId
			FROM
				m136_tblDocument doc
			WHERE
				doc.iDocumentId = @iItemId
				AND ((@isBackend = 1 AND doc.iLatestVersion = 1) OR (@isBackend = 0 AND doc.iLatestApproved = 1))
			INSERT INTO @idTable
			VALUES(@seedId) 
		END
	INSERT INTO 
		@idTable 
	SELECT
		*
	FROM
		[dbo].[m136_GetParentIdsInTbl](@seedId)
	SELECT
		hb.iParentHandbookId AS [iHandbookId],
		hb.strName,
		hb.iHandbookId AS Id,
		hb.iLevelType AS [LevelType],
		-1 AS [iDocumentTypeId],
		NULL AS [Version],
		NULL AS [dtmApproved],
		NULL AS [dtmPublishUntil],
		hb.iDepartmentId AS DepartmentId
	FROM
		m136_tblHandbook hb
	WHERE
		hb.iHandbookId IN (SELECT * FROM @idTable)
END
GO
