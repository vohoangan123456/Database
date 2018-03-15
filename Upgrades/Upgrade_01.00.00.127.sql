INSERT INTO #Description VALUES('Modified m136_be_InsertFolder to make sure folder permissions be created')
GO

IF OBJECT_ID('[dbo].[m136_be_InsertFolder]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_InsertFolder]')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JUNE 26, 2015
-- Description:	Insert new folder
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_InsertFolder]
	@iUserId INT,
	@iParentHandbookId	INT,
    @strName			VARCHAR(100),
    @strDescription		VARCHAR(7000),
    @iDepartmentId		INT,
    @iLevelType			INT,
    @iViewTypeId		INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @iParentLevel INT = 0, @iMaxHandbookId INT = 0;
	
	SELECT @iParentLevel = h.iLevel FROM dbo.m136_tblHandbook h WHERE h.iParentHandbookId = @iParentHandbookId;
	
	SELECT @iMaxHandbookId = MAX(ihandbookid) FROM dbo.m136_tblHandbook;
	
	DECLARE @iNewHandbookId INT = @iMaxHandbookId + 1;
	
	SET IDENTITY_INSERT dbo.m136_tblHandbook ON;
	
    INSERT INTO dbo.m136_tblHandbook(
		iHandbookId,
		iParentHandbookId, 
		strName, 
		strDescription, 
		iDepartmentId, 
		iLevelType, 
		iViewTypeId, 
		dtmCreated, 
		iCreatedById, 
		iDeleted,
		iMin,
		iMax,
		iLevel) 
    VALUES(
		@iNewHandbookId,
		(CASE WHEN @iParentHandbookId = 0 THEN NULL ELSE @iParentHandbookId END), 
		@strName, 
		@strDescription, 
		@iDepartmentId, 
		@iLevelType, 
		(CASE WHEN @iViewTypeId = -1 THEN 1 WHEN @iViewTypeId = -2 THEN 3 END), 
		GETDATE(), 
		@iUserId, 
		0,
		0,
		0,
		(@iParentLevel + 1));

	SET IDENTITY_INSERT dbo.m136_tblHandbook OFF;
	
	DECLARE @iEntityId INT, @iApplicationId INT, @iSecurityId INT, @iPermisionSetId INT, @iGroupingId INT, @iBit INT
	
	DECLARE ACL CURSOR FOR 
		SELECT @iNewHandbookId
				, [iApplicationId]
				, iSecurityId
				, [iPermissionSetId]
				, [iGroupingId]
				, [iBit]
			FROM [dbo].[tblACL] 
			WHERE iEntityId = @iParentHandbookId 
				AND iApplicationId = 136
				AND (iPermissionSetId = 461 OR iPermissionSetId = 462);
	
	OPEN ACL; 
	FETCH NEXT FROM ACL INTO @iEntityId, @iApplicationId, @iSecurityId, @iPermisionSetId, @iGroupingId, @iBit;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF NOT EXISTS(SELECT COUNT(1) FROM dbo.tblACL WHERE iEntityId = @iEntityId 
			AND iApplicationId = @iApplicationId 
			AND iSecurityId = @iSecurityId 
			AND iPermissionSetId  = @iPermisionSetId)
		BEGIN
			INSERT INTO dbo.tblACL VALUES (
			     @iEntityId
				, @iApplicationId
				, @iSecurityId
				, @iPermisionSetId
				, @iGroupingId
				, @iBit);
		END
		ELSE 
		BEGIN
			UPDATE dbo.tblACL
				SET iBit = @iBit,
					iGroupingId = @iGroupingId
			WHERE iEntityId = @iEntityId 
			AND iApplicationId = @iApplicationId 
			AND iSecurityId = @iSecurityId 
			AND iPermissionSetId  = @iPermisionSetId
		END
		FETCH NEXT FROM ACL INTO @iEntityId, @iApplicationId, @iSecurityId, @iPermisionSetId, @iGroupingId, @iBit;
	END
	CLOSE ACL;
	DEALLOCATE ACL;
				
	SELECT @iNewHandbookId;
END
GO

IF  NOT EXISTS (SELECT * FROM sys.objects 
WHERE object_id = OBJECT_ID(N'[dbo].[Log]') AND type in (N'U'))
BEGIN
	CREATE TABLE [dbo].[Log](
		[Id] [bigint] IDENTITY(1,1) NOT NULL,
		[Date] [datetime] NOT NULL,
		[Thread] [nvarchar](max) NOT NULL,
		[Level] [nvarchar](max) NOT NULL,
		[Logger] [nvarchar](max) NOT NULL,
		[Message] [nvarchar](max) NOT NULL,
		[CustomerReferenceId] [uniqueidentifier] NULL,
	 CONSTRAINT [PK_Log] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]

END
GO
