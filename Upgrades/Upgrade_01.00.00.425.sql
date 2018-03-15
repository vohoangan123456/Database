INSERT INTO #Description VALUES ('Create system user who is used in QMSService')
GO

IF NOT EXISTS(SELECT * FROM [dbo].[tblEmployee] WHERE [iEmployeeId] = -2)
BEGIN
	SET IDENTITY_INSERT [dbo].[tblEmployee] ON
	INSERT [dbo].[tblEmployee] ([iEmployeeId], [strEmployeeNo], [iDepartmentId], [strExpDep], 
	[dtmEmployed], [strFirstName], [strLastName], [strTitle], [strAddress1], [strAddress2], [strAddress3], 
	[iCountryId], [strPhoneHome], [strPhoneInternal], [strPhoneWork], [strPhoneMobile], [strBeeper], 
	[strCallNumber], [strFax], [strEmail], [strLoginName], [strLoginDomain], [strPassword], [iCompanyId], 
	[bWizard], [strComment], [iImageId], [bEmailConfirmed], [strMailPassword], [ADIdentifier], [LastLogin], [PreviousLogin]) 
	VALUES (-2, N'', 0, N'', 
	CAST(0x8D3F0000 AS SmallDateTime), N'System', N'User', N'', N'', N'', N'', 
	0, N'', N'', N'', N'', N'', 
	N'', N'', N'atle.solberg@netpower.no', N'system', N'', N'E47052A624B382FF88B4A135A12CBAE4', 4, 
	0, N'', 0, 0, N'', N'00000000-0000-0000-0000-000000000000', CAST(0x0000A56700A107C9 AS DateTime), CAST(0x0000A56700A0DA70 AS DateTime))
	SET IDENTITY_INSERT [dbo].[tblEmployee] OFF
END
GO

IF OBJECT_ID('[dbo].[m136_be_EndHearingDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_EndHearingDocument] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_EndHearingDocument] 
	@EntityId INT,
	@ShouldUpdateDueDate bit
AS
BEGIN
	BEGIN TRY
        BEGIN TRANSACTION;
        
		DECLARE @HearingId AS INT;
		
		SELECT @HearingId = Id
		FROM dbo.m136_Hearings
		WHERE EntityId = @EntityId
			  AND IsActive = 1;

		IF (@ShouldUpdateDueDate = 1)			  
		BEGIN
			UPDATE dbo.m136_Hearings 
			SET IsActive = 0,
			DueDate = GETDATE()
			WHERE Id = @HearingId;
		END
		ELSE
		BEGIN
			UPDATE dbo.m136_Hearings 
			SET IsActive = 0
			WHERE Id = @HearingId;
		END		
		
		UPDATE dbo.m136_tblDocument
		SET iApproved = 0, iStatus = 0
		WHERE iEntityId = @EntityId;
		
		COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
			ROLLBACK
		DECLARE @ErrorMessage nvarchar(MAX), @ErrorNumber int, @ErrorSeverity int, @ErrorState int, @ErrorLine int
		SELECT @ErrorMessage = N'Error %d, Line %d, Message: '+ERROR_MESSAGE(),@ErrorNumber = ERROR_NUMBER(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(),@ErrorLine = ERROR_LINE();
		RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber,@ErrorLine);
    END CATCH
END