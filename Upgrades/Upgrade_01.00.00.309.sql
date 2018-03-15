INSERT INTO #Description VALUES ('Add procedure m136_be_UpdateReadForHearingMember')
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateReadForHearingMember]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateReadForHearingMember] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_UpdateReadForHearingMember] 
	@HearingId INT,
	@EmployeeId INT
AS
BEGIN
	UPDATE dbo.m136_HearingMembers
	SET HasRead = 1
	WHERE HearingsId = @HearingId 
		AND EmployeeId = @EmployeeId
END
GO