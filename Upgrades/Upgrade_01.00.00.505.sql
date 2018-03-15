INSERT INTO #Description VALUES ('Get my reading lists')
GO

IF (OBJECT_ID('[dbo].[be_GetMyReadingLists]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [dbo].[be_GetMyReadingLists] AS SELECT 1'
GO	
ALTER PROCEDURE [dbo].[be_GetMyReadingLists]
@UserId INT
AS
BEGIN
    SELECT
        rl.ReadingListId,
        rl.Name,
        rl.Description,
        rl.IsInactive,
		rl.CreatedDate,
		rl.CreatedBy,
		ISNULL(e.strFirstName, '') + ' ' + ISNULL(e.strLastName, '') AS CreatedByName,
		ISNULL(e2.strFirstName, '') + ' ' + ISNULL(e2.strLastName, '') AS UpdatedByName,		
		rl.UpdatedDate,
		rl.UpdatedBy,
		d.strName AS DepartmentName,
		rl.ReadingReceiptsExpire,
		rl.ReadingReceiptValidity
    FROM
        ReadingList rl
		LEFT JOIN tblEmployee e ON rl.CreatedBy = e.iEmployeeId
		LEFT JOIN tblEmployee e2 ON rl.UpdatedBy = e2.iEmployeeId
		LEFT JOIN dbo.tblDepartment d ON e2.iDepartmentId = d.iDepartmentId
    WHERE
        IsDeleted = 0 AND (rl.CreatedBy = @UserId OR rl.UpdatedBy = @UserId)
    ORDER BY Name
END
GO