INSERT INTO #Description VALUES ('Modify Sp [dbo].[m136_be_GetDocumentSendToHearings] ')
GO

IF OBJECT_ID('[dbo].[IsCommentsForHearingDocument]', 'fn') IS NULL
    EXEC ('CREATE FUNCTION [dbo].[IsCommentsForHearingDocument]() RETURNS BIT AS BEGIN RETURN 0; END')
GO

ALTER FUNCTION [dbo].[IsCommentsForHearingDocument] 
(
	@EmployeeId INT,
	@HearingsId INT
)  
RETURNS BIT
AS  
BEGIN 
	 IF (SELECT COUNT(Id) FROM dbo.m136_HearingComments WHERE CreatedBy = @EmployeeId AND HearingsId = @HearingsId) > 0
		RETURN 1
	 
	 RETURN 0
END
GO

IF OBJECT_ID('[dbo].[CountHearingComments]', 'fn') IS NULL
    EXEC ('CREATE FUNCTION [dbo].[CountHearingComments]() RETURNS Int AS BEGIN RETURN 1 END;')
GO

ALTER FUNCTION [dbo].[CountHearingComments]
(
	@EmployeeId INT,
	@HearingId INT
)
RETURNS INT
AS
BEGIN
	DECLARE @result INT;
	SELECT @result=COUNT(Id) FROM dbo.m136_HearingComments WHERE CreatedBy = @EmployeeId AND HearingsId = @HearingId AND IsDraft = 0
	Return @result;
END
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
		   [dbo].[IsCommentsForHearingDocument](m.EmployeeId, m.HearingsId) HasComment,
		   d.iDepartmentId AS DepartmentId, d.strName AS DepartmentName,
		   lu.Name AS Response, m.Reason,
		   [dbo].[CountHearingComments](m.EmployeeId, @HearingId) CountComment
	FROM dbo.m136_HearingMembers m
	LEFT JOIN dbo.tblEmployee e ON m.EmployeeId = e.iEmployeeId
	LEFT JOIN dbo.tblDepartment d ON e.iDepartmentId = d.iDepartmentId
	LEFT JOIN dbo.m136_luHearingResponses lu ON m.HearingResponse = lu.Id
	WHERE m.HearingsId = @HearingId
	
	SELECT m.Id, m.HearingsId, m.EmployeeId, m.HasRead, m.HearingResponse,
		   e.strFirstName AS FirstName, e.strLastName AS LastName, e.strEmail AS Email, 
		   [dbo].[IsCommentsForHearingDocument](m.EmployeeId, m.HearingsId) HasComment,
		   d.iDepartmentId AS DepartmentId, d.strName AS DepartmentName,
		   lu.Name AS Response, m.Reason,
		   [dbo].[CountHearingComments](m.EmployeeId, m.HearingsId) AS CountComment
	FROM (SELECT * FROM dbo.m136_HearingMembers 
		  WHERE HearingsId IN (SELECT Id FROM dbo.m136_Hearings WHERE EntityId = @EntityId AND Id <> @HearingId)) m
	LEFT JOIN dbo.tblEmployee e ON m.EmployeeId = e.iEmployeeId
	LEFT JOIN dbo.tblDepartment d ON e.iDepartmentId = d.iDepartmentId
	LEFT JOIN dbo.m136_luHearingResponses lu ON m.HearingResponse = lu.Id
END
GO