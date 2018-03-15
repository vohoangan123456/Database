INSERT INTO #Description VALUES('Fix department path.')
GO

IF OBJECT_ID('[dbo].[fn136_GetDepartmentPath]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[fn136_GetDepartmentPath]() RETURNS NVARCHAR(4000) AS BEGIN RETURN 0; END')
GO
ALTER FUNCTION [dbo].[fn136_GetDepartmentPath](@DepartmentId INT)
RETURNS NVARCHAR(4000)
AS
BEGIN
	DECLARE @Path varchar(4000);
	
	WITH Parents AS
	(
		SELECT 
			td.iDepartmentParentId,
			strName
		FROM 
			[dbo].[tblDepartment] td 
		WHERE
			td.iDepartmentId = @DepartmentId
		UNION ALL
		SELECT 
			d.iDepartmentParentId,
			d.strName
		FROM 
			[dbo].[tblDepartment] d
			INNER JOIN Parents
				ON	d.iDepartmentId = Parents.iDepartmentParentId 
			WHERE (d.iLevel <> 0)
	)
	SELECT
		@Path = strName + COALESCE('/' + @Path, '')
	FROM
		Parents;

	IF (@DepartmentId IS NOT NULL AND @DepartmentId <> 0)
	BEGIN
		SET @Path = COALESCE(@Path, '');
	END
	
	RETURN @Path;
END
GO