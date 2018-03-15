INSERT INTO #Description VALUES ('Document Management - See feedbacks updated 2')
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentFeedbacks]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentFeedbacks] AS SELECT 1')
GO
-- =============================================
-- Author:		Si.Manh.Nguyen
-- Create date: OCT 19. 2015
-- Update date: DEC 8.2017 - Thi.Nguyen
-- Description:	Get feedbacks of ducument 
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetDocumentFeedbacks]
 @EntityId int,
 @IsLatestApproved bit
AS
BEGIN
	DECLARE @iDocumentId INT;
	IF @IsLatestApproved = 1
	BEGIN
		SELECT @iDocumentId = iDocumentId FROM dbo.m136_tblDocument WHERE iEntityId = @EntityId
		SELECT @EntityId = iEntityId FROM dbo.m136_tblDocument WHERE iDocumentId = @iDocumentId AND iLatestApproved = 1
	END
	SELECT emp.iEmployeeId, emp.strFirstName, emp.strLastName, fe.dtmFeedback, fe.strFeedback, @EntityId AS iEntityId
		FROM dbo.m136_tblFeedback fe
		LEFT OUTER JOIN dbo.tblEmployee emp 
				ON fe.iEmployeeId=emp.iEmployeeId 
		WHERE fe.iEntityId= @EntityId 
		ORDER BY dtmFeedback DESC
END

GO
