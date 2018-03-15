INSERT INTO #Description VALUES ('Fixed get child count. Replace hardcode 1 by @iSecurityId')
GO


IF OBJECT_ID('[dbo].[fn136_GetChildCount]', 'FN') IS NULL
    EXEC ('CREATE FUNCTION [dbo].[fn136_GetChildCount] () RETURNS INT AS BEGIN RETURN 1 END;')
GO
ALTER FUNCTION [dbo].[fn136_GetChildCount] 
(
	@iSecurityId INT,
	@iHandbookId INT,
	@bShowDocumentsInTree BIT
)
RETURNS INT
AS
BEGIN
	
	DECLARE @ReturnVal INT

	IF (@bShowDocumentsInTree = 0)
	BEGIN
		SELECT @ReturnVal = COUNT(iHandbookId) FROM m136_tblHandbook WHERE iParentHandbookId = @iHandbookId AND iDeleted = 0 
			AND (dbo.fnSecurityGetPermission(136, 461, @iSecurityId, iHandbookId) & 0x11) > 0;
    END
    ELSE
    BEGIN
		SET @ReturnVal = 
		      (SELECT COUNT(d.iDocumentId) 
					FROM m136_tblDocument d WHERE d.iHandbookId = @iHandbookId
						AND d.iLatestApproved = 1
						AND d.iApproved = 1
						AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, @iHandbookId) & 1) = 1 )
			+ (SELECT COUNT(d.iDocumentId) 
					FROM m136_tblDocument d INNER JOIN m136_relVirtualRelation v ON v.iHandbookId = @iHandbookId
						AND d.iDocumentId = v.iDocumentId
						AND d.iLatestApproved = 1
						AND iApproved = 1
						AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, @iHandbookId) & 1) = 1 
				)
			+ (SELECT COUNT(iHandbookId) 
					FROM m136_tblHandbook WHERE iParentHandbookId = @iHandbookId 
						AND iDeleted = 0 
						AND (dbo.fnSecurityGetPermission(136, 461, @iSecurityId, iHandbookId) & 0x11) > 0);
    END
	
	RETURN @ReturnVal;
END
GO



IF OBJECT_ID('[dbo].[fn136_be_GetChildCount]', 'FN') IS NULL
    EXEC ('CREATE FUNCTION [dbo].[fn136_be_GetChildCount] () RETURNS INT AS BEGIN RETURN 1 END;')
GO
ALTER FUNCTION [dbo].[fn136_be_GetChildCount] 
(
	@iSecurityId INT,
	@iHandbookId INT,
	@bShowDocumentsInTree BIT
)
RETURNS INT
AS
BEGIN
	
	DECLARE @ReturnVal INT = 0;

	IF (@bShowDocumentsInTree = 0)
	BEGIN
		SELECT @ReturnVal = COUNT(iHandbookId) FROM m136_tblHandbook WHERE iParentHandbookId = @iHandbookId 
			AND iDeleted = 0 
			AND (dbo.fnSecurityGetPermission(136, 461, @iSecurityId, iHandbookId) & 0x11) > 0;
    END
    ELSE
    BEGIN
		SET @ReturnVal = 
		      (SELECT COUNT(d.iDocumentId) 
					FROM m136_tblDocument d WHERE d.iHandbookId = @iHandbookId
						AND d.iLatestVersion = 1
						AND d.iDeleted = 0 
						AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, @iHandbookId) & 1) = 1 )
			+ (SELECT COUNT(d.iDocumentId) 
					FROM m136_tblDocument d INNER JOIN m136_relVirtualRelation v ON v.iHandbookId = @iHandbookId
						AND d.iDocumentId = v.iDocumentId
						AND d.iLatestVersion = 1
						AND d.iDeleted = 0
						AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, @iHandbookId) & 1) = 1 
				)
			+ (SELECT COUNT(iHandbookId) 
					FROM m136_tblHandbook WHERE iParentHandbookId = @iHandbookId 
						AND iDeleted = 0 
						AND (dbo.fnSecurityGetPermission(136, 461, @iSecurityId, iHandbookId) & 0x11) > 0);
    END
	
	RETURN @ReturnVal;
END
GO
