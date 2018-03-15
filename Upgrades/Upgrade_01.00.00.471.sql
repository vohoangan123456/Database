INSERT INTO #Description VALUES ('Document Management - See feedbacks updated')
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentFeedbacks]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentFeedbacks] AS SELECT 1')
GO
-- =============================================
-- Author:		Si.Manh.Nguyen
-- Create date: OCT 19. 2015
-- Update date: DEC 5.2017 - Thi.Nguyen
-- Description:	Get feedbacks of ducument 
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetDocumentFeedbacks]
 @EntityId int,
 @IsLatestApproved bit
AS
BEGIN
	DECLARE @iVersions INT;
	DECLARE @iLatestApproved INT;
	DECLARE @iDocumentId INT;
	DECLARE @iPREV_EntityId INT;
	IF @IsLatestApproved = 1
	BEGIN
		SELECT @EntityId = iEntityId FROM dbo.m136_tblDocument WHERE iDocumentId = @iDocumentId AND iLatestApproved = 1
	END
	SELECT emp.iEmployeeId, emp.strFirstName, emp.strLastName, fe.dtmFeedback, fe.strFeedback 
		FROM dbo.m136_tblFeedback fe
		LEFT OUTER JOIN dbo.tblEmployee emp 
				ON fe.iEmployeeId=emp.iEmployeeId 
		WHERE fe.iEntityId= @EntityId 
		ORDER BY dtmFeedback DESC
END