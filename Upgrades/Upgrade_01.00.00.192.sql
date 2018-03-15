INSERT INTO #Description VALUES('Created script for updating department information')
GO

IF OBJECT_ID('[dbo].[m136_be_GetDepartmentPostions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDepartmentPostions] AS SELECT 1')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: AUGUST 17, 2015
-- Description:	Get department positions
-- Modified date: FEB 03, 2016
-- Modified: order by strName
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetDepartmentPostions]
	@iDepartmentId INT
AS
BEGIN
	SET NOCOUNT ON;

    SELECT tp.* FROM dbo.tblPosition tp
		INNER JOIN dbo.relDepartmentPosition rdp ON rdp.iPositionId = tp.iPositionId
		WHERE rdp.iDepartmentId = @iDepartmentId
	ORDER BY tp.strName
END
GO