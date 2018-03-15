INSERT INTO #Description VALUES('Create SP for Document action hearing - active')
GO

IF OBJECT_ID('[dbo].[m136_be_CreateDocumentHearing]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_CreateDocumentHearing] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_CreateDocumentHearing] 
	@EntityId			INT,
	@IsPublic			BIT,
	@CreateBy		    INT,
	@DueDate			DATETIME,
	@Employees AS [dbo].[Item] READONLY
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
	SET NOCOUNT ON;
	DECLARE @HearingId INT;
	INSERT INTO dbo.m136_Hearings(EntityId,IsPublic,CreatedDate,CreatedBy,DueDate,IsActive)
	VALUES(@EntityId, @IsPublic, GETDATE(), @CreateBy, @DueDate, 1)
	SET @HearingId = SCOPE_IDENTITY();
	INSERT INTO [dbo].[m136_HearingMembers](HearingsId, EmployeeId, HasRead)
	SELECT @HearingId, Id, 0
	FROM @Employees
	UPDATE dbo.m136_tblDocument 
		SET iApproved = 3, iStatus = 1
	WHERE iEntityId = @EntityId
	SELECT @HearingId
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
	
	SELECT *
	FROM dbo.m136_Hearings
	WHERE Id = @HearingId
	
	SELECT m.Id, m.HearingsId, m.EmployeeId, m.HasRead, m.HearingResponse,
		   e.strFirstName AS FirstName, e.strLastName AS LastName, e.strEmail AS Email, 
		   CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END HasComment, c.Comment
	FROM dbo.m136_HearingMembers m
	LEFT JOIN dbo.m136_HearingComments c ON m.EmployeeId = c.CreatedBy
	LEFT JOIN dbo.tblEmployee e ON m.EmployeeId = e.iEmployeeId
	WHERE m.HearingsId = @HearingId
END
GO

IF OBJECT_ID('[dbo].[m136_be_EndHearingDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_EndHearingDocument] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_EndHearingDocument] 
	@EntityId INT
AS
BEGIN
	DECLARE @HearingId AS INT
	SELECT @HearingId = Id
	FROM dbo.m136_Hearings
	WHERE EntityId = @EntityId
	
	UPDATE dbo.m136_Hearings 
	SET IsActive = 0
	WHERE Id = @HearingId
	
	UPDATE dbo.m136_tblDocument
	SET iApproved = 0, iStatus = 0
	WHERE iEntityId = @EntityId
END
