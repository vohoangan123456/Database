
INSERT INTO #Description VALUES('Create functions [dbo].[fn136_GetParentPathExNew] for simple searching. m136_be_GetSecurityGroups for get roles permission')
GO

IF OBJECT_ID('[dbo].[fn136_GetParentPathExNew]', 'FN') IS NULL
    EXEC ('CREATE FUNCTION [dbo].[fn136_GetParentPathExNew] () RETURNS NVARCHAR(4000) AS BEGIN RETURN 1 END;')
GO
ALTER FUNCTION [dbo].[fn136_GetParentPathExNew](@chapterId INT)
RETURNS NVARCHAR(4000)
AS
BEGIN
	DECLARE @Path varchar(4000);
	
	WITH Parents AS
	(
		SELECT 
			iParentHandbookId,
			strName
		FROM 
			[dbo].[m136_tblHandbook] 
		WHERE
			iHandbookId = @chapterId
	
		UNION ALL
	
		SELECT 
			h.iParentHandbookId,
			h.strName
		FROM 
			[dbo].[m136_tblHandbook] h
			INNER JOIN Parents
				ON	h.iHandbookId = Parents.iParentHandbookId 
	)
	SELECT
		@Path = strName + COALESCE('/' + @Path, '')
	FROM
		Parents

	RETURN @Path
END
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
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT sg.iSecGroupId
		   ,sg.strName
		   ,sg.strDescription 
	FROM [dbo].[tblSecGroup] sg
	JOIN [dbo].[relEmployeeSecGroup] esg ON esg.iSecGroupId = sg.iSecGroupId
	WHERE esg.iEmployeeId = @UserId;
END
GO