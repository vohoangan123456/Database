
INSERT INTO #Description VALUES('Create stored procedures create folder page.')
GO

IF OBJECT_ID('[dbo].[m136_be_GetDepartments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDepartments] AS SELECT 1')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JUNE 24, 2015
-- Description:	Get all departments. 
--				Because the list of department does not long, so we will get all and paging on client if any.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetDepartments]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT	dpt.iDepartmentId, 
			dpt.strName, 
			dpt.strDescription 
		FROM dbo.tblDepartment dpt;
END
GO

IF OBJECT_ID('[dbo].[m136_be_InsertFolder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_InsertFolder] AS SELECT 1')
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
		@iParentHandbookId, 
		@strName, 
		@strDescription, 
		@iDepartmentId, 
		@iLevelType, 
		@iViewTypeId, 
		GETDATE(), 
		@iUserId, 
		0,
		0,
		0,
		(@iParentLevel + 1));
		
	INSERT INTO dbo.tblACL
		SELECT @iNewHandbookId
			,[iApplicationId]
			,[iSecurityId]
			,[iPermissionSetId]
			,[iGroupingId]
			,[iBit]
		FROM [Vestre_viken_handbok].[dbo].[tblACL] 
		WHERE iEntityId = 0 
			AND iApplicationId = 136
			AND (iBit & 1) = 1 
			AND (iPermissionSetId = 461 OR iPermissionSetId = 462);
	
	SELECT @iNewHandbookId;
END
GO