INSERT INTO #Description VALUES('Create stored procedure reject of a document')
GO

IF OBJECT_ID('[dbo].[m136_be_RejectDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_RejectDocument]  AS SELECT 1')
GO
-- =============================================
-- Author:		SI.NGUYEN.MANH
-- Create date: NOV 4, 2015
-- Description:	Update Reject document and get email of responsible
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_RejectDocument] 
	@EntityId INT,
	@UserId INT
AS
BEGIN
	DECLARE @DocumentId INT;
	
	SELECT @DocumentId = iDocumentId
		FROM dbo.m136_tblDocument
		WHERE iEntityId = @EntityId
		      AND iDeleted = 0
	
	UPDATE dbo.m136_tblDocument
	SET iApproved = 2,
		iDraft = 1,
		iApprovedById = @UserId,
		dtmApproved = getdate(),
		strApprovedBy = dbo.fnOrgGetUserName(@UserId, '', 0)
	WHERE iEntityId = @EntityId
		  AND iDeleted = 0
	
	EXEC dbo.m136_SetVersionFlags @DocumentId
	
	SELECT a.strEmail 
	FROM dbo.tblEmployee a 
		INNER JOIN dbo.m136_tblDocument b 
		ON a.iEmployeeId = b.iCreatedById 
	WHERE b.iEntityId = @EntityId
END
GO