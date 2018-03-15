INSERT INTO #Description VALUES ('Update SP add description for hearing table')
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
        WHERE [NAME] = N'Description' AND [OBJECT_ID] = OBJECT_ID(N'dbo.m136_Hearings'))
BEGIN
    ALTER TABLE dbo.m136_Hearings ADD Description NVARCHAR(MAX)
END
GO

IF OBJECT_ID('[dbo].[m136_be_CreateDocumentHearing]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_CreateDocumentHearing] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_CreateDocumentHearing] 
	@EntityId			INT,
	@IsPublic			BIT,
	@CreateBy		    INT,
	@DueDate			DATETIME,
	@Employees AS [dbo].[Item] READONLY,
	@AllowForwarding BIT,
	@Notify BIT,
	@Description NVARCHAR(MAX)
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
	SET NOCOUNT ON;
	DECLARE @HearingId INT;
	INSERT INTO dbo.m136_Hearings(EntityId,IsPublic,CreatedDate,CreatedBy,DueDate,IsActive,AllowForwarding,Notify,Description)
	VALUES(@EntityId, @IsPublic, GETDATE(), @CreateBy, @DueDate, 1,@AllowForwarding, @Notify,@Description)
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

IF OBJECT_ID('[dbo].[m136_be_EditDocumentHearing]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_EditDocumentHearing] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_EditDocumentHearing] 
	@HearingId			INT,
	@IsPublic			BIT,
	@DueDate			DATETIME,
	@EmployeesAdd AS [dbo].[Item] READONLY,
	@EmployeesDelete AS [dbo].[Item] READONLY,
	@AllowForwarding BIT,
	@Notify BIT,
	@Description NVARCHAR(MAX)
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
	UPDATE dbo.m136_Hearings
		SET IsPublic = @IsPublic, DueDate = @DueDate,
		    AllowForwarding = @AllowForwarding,
			Notify = @Notify,
			Description = @Description
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
