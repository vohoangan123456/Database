INSERT INTO #Description VALUES('Create stored procedures for Get reading confrim of ducument.')
GO

IF OBJECT_ID('[dbo].[m136_be_GetReadingConfirmation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetReadingConfirmation] AS SELECT 1')
GO
-- =============================================
-- Author:		Si.Manh.Nguyen
-- Create date: OCT 16. 2015
-- Description:	Get reading confrim of ducument
-- =============================================

ALTER PROCEDURE [dbo].[m136_be_GetReadingConfirmation]
 @EntityId int
AS
BEGIN
	SELECT	con.iEmployeeId,
			con.strEmployeeName, dep.strName as strDepartment, con.dtmConfirm
	FROM dbo.tblEmployee emp
		INNER JOIN dbo.tblDepartment dep 
			ON emp.iDepartmentId = dep.iDepartmentId 
		INNER JOIN m136_tblConfirmRead con 
			ON emp.iEmployeeId = con.iEmployeeId
	WHERE iEntityId= @EntityId
	ORDER BY strDepartment, strEmployeeName ASC
END

GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentFeedbacks]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentFeedbacks] AS SELECT 1')
GO
-- =============================================
-- Author:		Si.Manh.Nguyen
-- Create date: OCT 19. 2015
-- Description:	Get feedbacks of ducument 
-- =============================================

ALTER PROCEDURE [dbo].[m136_be_GetDocumentFeedbacks]
 @EntityId int
AS
BEGIN
	
	SELECT emp.iEmployeeId, emp.strFirstName, emp.strLastName, fe.dtmFeedback, fe.strFeedback 
	FROM dbo.m136_tblFeedback fe
	LEFT OUTER JOIN dbo.tblEmployee emp 
			ON fe.iEmployeeId=emp.iEmployeeId 
	WHERE fe.iEntityId= @EntityId 
	ORDER BY dtmFeedback DESC
END
GO
