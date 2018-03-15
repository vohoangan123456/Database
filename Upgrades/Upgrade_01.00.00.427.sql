INSERT INTO #Description VALUES ('Modify SP [dbo].[m136_be_GetDocumentSendToHearings]')
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentSendToHearings]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentSendToHearings] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetDocumentSendToHearings]
	@EntityId INT
AS
BEGIN

	DECLARE @HearingId AS INT
	SELECT @HearingId = Id
	FROM dbo.m136_Hearings
	WHERE EntityId = @EntityId
		  AND Id = (SELECT MAX(Id) FROM dbo.m136_Hearings WHERE EntityId = @EntityId)
	
	SELECT *
	FROM dbo.m136_Hearings
	WHERE Id = @HearingId
	
	SELECT m.Id, m.HearingsId, m.EmployeeId, m.HasRead, m.HearingResponse,
		   e.strFirstName AS FirstName, e.strLastName AS LastName, e.strEmail AS Email, 
		   CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END HasComment, c.Comment,
		   d.iDepartmentId AS DepartmentId, d.strName AS DepartmentName,
		   lu.Name AS Response, m.Reason,
		   (SELECT COUNT(Id) FROM dbo.m136_HearingComments WHERE CreatedBy = m.EmployeeId AND HearingsId = @HearingId AND IsDraft = 0) AS CountComment
	FROM dbo.m136_HearingMembers m
	LEFT JOIN dbo.m136_HearingComments c 
		ON m.EmployeeId = c.CreatedBy AND c.HearingsId = @HearingId 
			AND c.Id = (SELECT MAX(Id) FROM dbo.m136_HearingComments c1 WHERE c1.CreatedBy = m.EmployeeId AND c1.HearingsId = @HearingId)
	LEFT JOIN dbo.tblEmployee e ON m.EmployeeId = e.iEmployeeId
	LEFT JOIN dbo.tblDepartment d ON e.iDepartmentId = d.iDepartmentId
	LEFT JOIN dbo.m136_luHearingResponses lu ON m.HearingResponse = lu.Id
	WHERE m.HearingsId = @HearingId
END
GO
