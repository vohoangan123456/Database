INSERT INTO #Description VALUES('Created script getting folders recursive')
GO

IF OBJECT_ID('[dbo].[m136_be_GetFoldersRecursive]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetFoldersRecursive] AS SELECT 1')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JAN 27, 2015
-- Description:	GET FOLDERS RECURSIVE
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetFoldersRecursive] 
	@iHandbookId INT,
	@iSecurityId INT,
	@bCheckSecurity BIT
AS
BEGIN
	SET NOCOUNT ON;
	SELECT h.iHandbookId as Id,
			h.iHandbookId,
			h.strName,
			-1 as iDocumentTypeId,
			NULL as Version,
			iLevelType as LevelType,
			NULL as dtmApproved,
			NULL as strApprovedBy,
			NULL as Responsible,
			h.iDepartmentId as DepartmentId,
			0 as Virtual,
			h.iSort,
			NULL as ParentFolderName,
			dbo.fn136_GetParentPathEx(h.iHandbookId) as [Path],
			0 as HasAttachment,
			NULL as iApproved,
			NULL as iDraft,
			h.iParentHandbookId,
			[dbo].[fn136_GetChildCount] (@iSecurityId, h.iHandbookId, 1) AS iChildCount,
            0 AS IsDocument
	FROM	m136_tblHandbook h WHERE h.iHandbookId IN (SELECT  iHandbookId  FROM 
		[dbo].[m136_GetHandbookRecursive](@iHandbookId, @iSecurityId, @bCheckSecurity));
END
GO