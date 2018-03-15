INSERT INTO #Description VALUES('Create SP for end hearing by plugin')
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
		   lu.Name AS Response
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

IF OBJECT_ID('[dbo].[m136_be_GetHearingsToEnded]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetHearingsToEnded] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetHearingsToEnded] 
AS
BEGIN
	SELECT *
	FROM dbo.m136_Hearings
	WHERE IsActive = 1
		  AND DueDate < GETDATE()
END
GO

IF OBJECT_ID('[dbo].[m136_be_EditDocumentHearing]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_EditDocumentHearing] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_EditDocumentHearing] 
	@HearingId			INT,
	@IsPublic			BIT,
	@DueDate			DATETIME,
	@EmployeesAdd AS [dbo].[Item] READONLY,
	@EmployeesDelete AS [dbo].[Item] READONLY
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
	UPDATE dbo.m136_Hearings
		SET IsPublic = @IsPublic, DueDate = @DueDate
	WHERE Id = @HearingId
	DELETE FROM [dbo].[m136_HearingMembers]
	WHERE HearingsId = @HearingId
		  AND EmployeeId IN (SELECT Id FROM @EmployeesDelete)
	INSERT INTO [dbo].[m136_HearingMembers](HearingsId, EmployeeId, HasRead)
	SELECT @HearingId, Id, 0
	FROM @EmployeesAdd
COMMIT TRANSACTION;    
END TRY
BEGIN CATCH
    ROLLBACK
    DECLARE @ErrorMessage nvarchar(MAX), @ErrorNumber int, @ErrorSeverity int, @ErrorState int, @ErrorLine int
    SELECT @ErrorMessage = N'Error %d, Line %d, Message: ' + ERROR_MESSAGE(), @ErrorNumber = ERROR_NUMBER(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(), @ErrorLine = ERROR_LINE();
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber,@ErrorLine);
END CATCH
END
GO