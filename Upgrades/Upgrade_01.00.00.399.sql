INSERT INTO #Description VALUES ('Modify SP for hearing update')
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
    WHERE [name] = N'Reason' AND [object_id] = OBJECT_ID(N'dbo.m136_HearingMembers'))
BEGIN
	ALTER TABLE dbo.m136_HearingMembers  
    ADD Reason NVARCHAR(250) NULL
END
GO


IF OBJECT_ID('[dbo].[m136_be_UpdateHearingResponseForMember]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateHearingResponseForMember]  AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_UpdateHearingResponseForMember]
	@UserId AS INT,
	@HearingsId AS INT,
	@HearingResponse AS INT,
	@Reason AS NVARCHAR(250)
AS
BEGIN
	UPDATE dbo.m136_HearingMembers
	SET HearingResponse = @HearingResponse,
		Reason = @Reason
	WHERE EmployeeId = @UserId
		  AND HearingsId = @HearingsId
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
		   CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END HasComment, c.Comment,
		   d.iDepartmentId AS DepartmentId, d.strName AS DepartmentName,
		   lu.Name AS Response, m.Reason,
		   (SELECT COUNT(Id) FROM dbo.m136_HearingComments WHERE CreatedBy = m.EmployeeId AND HearingsId = @HearingId) AS CountComment
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

IF OBJECT_ID('[dbo].[m136_be_GetHearingComment]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetHearingComment]  AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetHearingComment] 
	@UserId AS INT,
	@HearingsId AS INT
AS
BEGIN
	DECLARE @EntityId INT, @CreatedDate DATETIME
	SELECT @EntityId = EntityId, @CreatedDate = CreatedDate
	FROM dbo.m136_Hearings 
	WHERE Id = @HearingsId
	
	SELECT h.*, e.strFirstName, e.strLastName
	FROM dbo.m136_HearingComments h
	LEFT JOIN dbo.tblEmployee e ON e.iEmployeeId = h.CreatedBy 
	WHERE HearingsId = @HearingsId
		  AND (h.IsDraft = 0 OR (h.IsDraft = 1 AND h.CreatedBy = @UserId))
	ORDER BY h.IsDraft, h.Published, h.CreatedDate
	
	SELECT h.*, e.strFirstName, e.strLastName
	FROM dbo.m136_HearingComments h
	LEFT JOIN dbo.tblEmployee e ON e.iEmployeeId = h.CreatedBy 
	WHERE h.IsDraft = 0
		  AND h.HearingsId IN (SELECT Id FROM dbo.m136_Hearings WHERE EntityId = @EntityId AND Id <> @HearingsId AND CreatedDate < @CreatedDate)
	ORDER BY h.Published, h.CreatedDate
	
END
GO