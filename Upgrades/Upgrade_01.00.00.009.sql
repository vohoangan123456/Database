
INSERT INTO #Description VALUES('Checking last login for getting what new count')
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetDocumentsApprovedWithinXDaysCount]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetDocumentsApprovedWithinXDaysCount]
GO

CREATE PROCEDURE [dbo].[m136_GetDocumentsApprovedWithinXDaysCount] 
	-- Add the parameters for the stored procedure here
	@iApprovedWithinXDays int = 0,
	@iSecurityId int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @HandbookPermissions TABLE(iHandbookId INT NOT NULL PRIMARY KEY)
	INSERT INTO @HandbookPermissions
	SELECT iHandbookId FROM m136_tblHandbook 
		WHERE iDeleted = 0 AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 1) = 1
	SELECT COUNT(1)
	FROM 
		m136_tblDocument d
        JOIN m136_tblDocumentType t ON d.iDocumentTypeId = t.iDocumentTypeId
        JOIN m136_tblHandbook h ON d.iHandbookId = h.iHandbookId
        LEFT JOIN tblEmployee e ON e.iEmployeeId = d.iCreatedbyId 
    WHERE
		d.iDraft = 0
		AND d.iLatestApproved = 1
		AND d.iHandbookId in (SELECT iHandbookId FROM @HandbookPermissions)
        AND DATEDIFF(d, ISNULL(d.dtmApproved, CONVERT(DATETIME, '01.01.1970', 104)), GETDATE()) < @iApprovedWithinXDays 
        AND (d.dtmApproved > e.PreviousLogin)
END
GO
