INSERT INTO #Description VALUES('Create stored procedures for searching departments.')
GO

IF OBJECT_ID('[dbo].[m136_be_SearchDepartments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_SearchDepartments] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JULY 14, 2015
-- Description:	Search department by name.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_SearchDepartments]
	-- Add the parameters for the stored procedure here
	@strName VARCHAR(80)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT td.iDepartmentId, td.iDepartmentParentId, td.iLevel, td.strName, td.strDescription 
    FROM dbo.tblDepartment td
    WHERE td.strName LIKE '%' + @strName + '%';
END
GO