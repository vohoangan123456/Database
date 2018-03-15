INSERT INTO #Description VALUES ('Modify procedure m136_InsertReadingConfirmation')
GO

IF OBJECT_ID('[dbo].[m136_InsertReadingConfirmation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_InsertReadingConfirmation] AS SELECT 1 a')
GO

ALTER PROCEDURE [dbo].[m136_InsertReadingConfirmation]
	@EntityId INT,
	@EmployeeId INT
AS
BEGIN
	
	DECLARE @Now DATETIME = GETDATE()
	
	IF EXISTS (SELECT 1 FROM m136_tblConfirmRead WHERE iEntityId = @EntityId AND iEmployeeId = @EmployeeId AND CAST(dtmConfirm as date) = CAST(@Now as date))
	BEGIN
		UPDATE m136_tblConfirmRead
		SET dtmConfirm = @Now
		WHERE iEntityId = @EntityId AND iEmployeeId = @EmployeeId AND CAST(dtmConfirm as date) = CAST(@Now as date)
	END
	ELSE
	BEGIN
		INSERT INTO m136_tblConfirmRead(iEntityId, iEmployeeId, dtmConfirm, strEmployeeName)
		VALUES(@EntityId, @EmployeeId , @Now, [dbo].[fnOrgGetUserName](@EmployeeId,'No Name',0))
	END

END
GO

