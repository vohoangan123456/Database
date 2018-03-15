INSERT INTO #Description VALUES('Modify stored procedures related to refactor notify message.')
GO

IF OBJECT_ID('[dbo].[m136_be_GetSecurityGroups]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetSecurityGroups] AS SELECT 1')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JUNE 29, 2015
-- Description:	Get security groups
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetSecurityGroups] 
	@UserId INT
AS
BEGIN
	SET NOCOUNT ON;
    SELECT sg.iSecGroupId
		   ,sg.strName
		   ,sg.strDescription 
	FROM [dbo].[tblSecGroup] sg
	JOIN [dbo].[relEmployeeSecGroup] esg ON esg.iSecGroupId = sg.iSecGroupId
	WHERE esg.iEmployeeId = @UserId OR @UserId IS NULL;
END
GO