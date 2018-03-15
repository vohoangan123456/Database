INSERT INTO #Description VALUES('Create procedure m136_be_UpdateTimeStampForEventLog, modify procedure m136_be_AddEventLog')
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateTimeStampForEventLog]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateTimeStampForEventLog] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_UpdateTimeStampForEventLog]
	@Id INT,
    @EventTime DATETIME
AS
BEGIN
	UPDATE tblEventLog
    SET EventTime = @EventTime
    WHERE Id = @Id
END
GO

IF OBJECT_ID('[dbo].[m136_be_AddEventLog]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_AddEventLog] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_AddEventLog]
	@DocumentId INT,
    @Version INT,
    @Description VARCHAR(MAX),
    @EmployeeId INT,
    @LoginName VARCHAR(100),
    @FirstName VARCHAR(50),
    @LastName VARCHAR(50),
    @EventTime DATETIME,
    @EventType INT
AS
BEGIN
	SET NOCOUNT ON;
	SET IDENTITY_INSERT dbo.tblEventlog ON;
	DECLARE @MaxId INT;
    DECLARE @EventLogId INT;
	SELECT @MaxId = MAX(te.Id) FROM dbo.tblEventlog te;
    SET @EventLogId = ISNULL(@MaxId, 0) + 1;
	
	INSERT INTO dbo.tblEventlog
        (Id, DocumentId, [Version], EmployeeId, LoginName, FirstName, LastName, EventTime, EventType, [Description])
	VALUES
        (@EventLogId, @DocumentId, @Version, @EmployeeId, @LoginName,  @FirstName, @LastName, @EventTime, @EventType, @Description)
	
	SET IDENTITY_INSERT dbo.tblEventlog OFF;
    SELECT @EventLogId
END
GO