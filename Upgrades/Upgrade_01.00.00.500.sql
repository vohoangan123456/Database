INSERT INTO #Description VALUES ('Update SP for reading list function')
GO

IF OBJECT_ID('[dbo].[fnGetConfirmedOnDocument]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[fnGetConfirmedOnDocument]() RETURNS DATETIME AS BEGIN RETURN NULL; END')
GO

ALTER FUNCTION [dbo].[fnGetConfirmedOnDocument]
(
	@UserId INT,
    @EntityId INT,
    @ReadingReceiptsExpire BIT,
    @ReadingReceiptValidity SMALLINT
) RETURNS DATETIME
AS
BEGIN

	DECLARE @dtmConfirm DATETIME
	SELECT @dtmConfirm = dtmConfirm 
	FROM m136_tblConfirmRead 
	WHERE iEntityId = @EntityId AND iEmployeeId = @UserId AND  dtmConfirm = (SELECT MAX(dtmConfirm) FROM m136_tblConfirmRead WHERE iEntityId = @EntityId AND iEmployeeId = @UserId)
	
	IF @ReadingReceiptsExpire = 1 AND @ReadingReceiptValidity IS NOT NULL AND @ReadingReceiptValidity <> 0
	BEGIN
		DECLARE @DateCompare DATETIME = DATEADD(month, -@ReadingReceiptValidity ,GETDATE())
		IF @dtmConfirm IS NOT NULL
		BEGIN
			IF @dtmConfirm >= @DateCompare
				RETURN @dtmConfirm;
			ELSE
				RETURN NULL;
		END
    END
    
    Return @dtmConfirm;
END
GO

IF OBJECT_ID('[dbo].[GetReadingListDocumentsOfUser]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetReadingListDocumentsOfUser] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetReadingListDocumentsOfUser]
    @UserId INT,
    @ReadingListIds AS [dbo].[Item] READONLY
AS
BEGIN
    DECLARE @UserDepartmentId TABLE(Id INT);
    DECLARE @UserRoleId TABLE(Id INT);
    
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        tblEmployee
    WHERE
        iEmployeeId = @UserId
    
    INSERT INTO @UserRoleId(Id)
    SELECT
        iSecGroupId
    FROM
        relEmployeeSecGroup
    WHERE
        iEmployeeId = @UserId
    
    SELECT DISTINCT 
        rl.Name AS ReadingListName,
        d.iDocumentId AS DocumentId,
        d.strName DocumentName,
        d.iVersion DocumentVersion,
        [dbo].[fnGetConfirmedOnDocument](@UserId, d.iEntityId, rl.ReadingReceiptsExpire, rl.ReadingReceiptValidity)  AS ConfirmationDate
    FROM 
        ReadingList rl 
            INNER JOIN ReadingListReaders rlr ON rl.ReadingListId = rlr.ReadingListId 
            INNER JOIN ReadingListDocuments rld ON rl.ReadingListId = rld.ReadingListId 
            INNER JOIN m136_tblDocument d ON rld.DocumentId = d.iDocumentId 
    WHERE 
        rl.IsDeleted = 0 
        AND d.iLatestApproved = 1 
        AND ReaderTypeId IN (1,2,3) 
        AND 
        (
            (ReaderId = @UserId AND ReaderTypeId = 1)
            OR (
				ReaderTypeId = 2 AND ReaderId IN (SELECT Id FROM @UserDepartmentId) 
				 AND @UserId NOT IN (SELECT EmployeeId FROM dbo.ReadingListExclusions WHERE ReadingListId IN (SELECT Id FROM @ReadingListIds) AND DepartmentId IN (SELECT Id FROM @UserDepartmentId))
				)
            OR (ReaderTypeId = 3 AND ReaderId IN (SELECT Id FROM @UserRoleId))
        )
        AND rl.ReadingListId IN (SELECT Id FROM @ReadingListIds)
END
GO

IF OBJECT_ID('[dbo].[AreDocumentsInReadingListConfirmedByUser]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[AreDocumentsInReadingListConfirmedByUser]() RETURNS BIT AS BEGIN RETURN 0; END')
GO

ALTER FUNCTION [dbo].[AreDocumentsInReadingListConfirmedByUser]
(
    @UserId INT,
	@ReadingListId INT,
	@ReadingReceiptsExpire BIT,
    @ReadingReceiptValidity SMALLINT
)
RETURNS BIT
AS
BEGIN
    DECLARE @Result BIT;
    DECLARE @NumberOfDocuments INT;
    DECLARE @NumberOfConfirmedDocuments INT;
    
    
    SELECT
        @NumberOfDocuments = COUNT(1)
    FROM
        ReadingListDocuments
    WHERE
        ReadingListId = @ReadingListId
        
    IF @ReadingReceiptsExpire = 1 AND @ReadingReceiptValidity IS NOT NULL AND @ReadingReceiptValidity <> 0
	BEGIN    
		DECLARE @DateCompare DATETIME = DATEADD(month, -@ReadingReceiptValidity ,GETDATE())
		
		SELECT
			@NumberOfConfirmedDocuments = COUNT(1)
		FROM
			ReadingListDocuments rld
				INNER JOIN m136_tblDocument d ON rld.DocumentId = d.iDocumentId AND d.iLatestApproved = 1
				INNER JOIN m136_tblConfirmRead cr ON d.iEntityId = cr.iEntityId AND iEmployeeId = @UserId 
										AND  dtmConfirm = (SELECT MAX(dtmConfirm) FROM m136_tblConfirmRead WHERE iEntityId = d.iEntityId AND iEmployeeId = @UserId)
										AND cr.dtmConfirm >= @DateCompare
		WHERE
			ReadingListId = @ReadingListId
			AND cr.iEmployeeId = @UserId
			AND cr.dtmConfirm >= @DateCompare
    END 
    ELSE
    BEGIN
		SELECT
			@NumberOfConfirmedDocuments = COUNT(1)
		FROM
			ReadingListDocuments rld
				INNER JOIN m136_tblDocument d ON rld.DocumentId = d.iDocumentId AND d.iLatestApproved = 1
				INNER JOIN m136_tblConfirmRead cr ON d.iEntityId = cr.iEntityId AND iEmployeeId = @UserId 
										AND  dtmConfirm = (SELECT MAX(dtmConfirm) FROM m136_tblConfirmRead WHERE iEntityId = d.iEntityId AND iEmployeeId = @UserId)
		WHERE
			ReadingListId = @ReadingListId
			AND cr.iEmployeeId = @UserId
    END
    
    IF @NumberOfDocuments = @NumberOfConfirmedDocuments
    BEGIN
        SET @Result = 1;
    END
    ELSE
    BEGIN
        SET @Result = 0;
    END
    
    RETURN @Result;
END
GO

IF OBJECT_ID('[dbo].[GetNumberOfOkReadingListsForUsersOfDepartments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetNumberOfOkReadingListsForUsersOfDepartments] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetNumberOfOkReadingListsForUsersOfDepartments]
	@DepartmentId INT,
    @IncludeSubDepartments BIT,
    @ReadingListIds AS [dbo].[Item] READONLY
AS
BEGIN

    DECLARE @DepartmentIds TABLE
    (
        DepartmentId INT
    );
    
    INSERT INTO @DepartmentIds (DepartmentId) VALUES (@DepartmentId)
    
    IF @IncludeSubDepartments = 1
    BEGIN
        INSERT INTO @DepartmentIds (DepartmentId)
        SELECT iDepartmentId FROM m136_GetDepartmentsRecursive(@DepartmentId)
    END
    
    SELECT
        e.iEmployeeId AS UserId, 
        r.ReadingListId AS ReadingListId, 
        r.Name AS ReadingListName, 
        dbo.AreDocumentsInReadingListConfirmedByUser(e.iEmployeeId, r.ReadingListId, r.ReadingReceiptsExpire, r.ReadingReceiptValidity) AS IsOK
    FROM
        ReadingList r
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId
            INNER JOIN tblEmployee e ON e.iDepartmentId = rlr.ReaderId AND rlr.ReaderTypeId = 2 AND e.iEmployeeId NOT IN(SELECT EmployeeId FROM dbo.ReadingListExclusions WHERE ReadingListId = r.ReadingListId AND DepartmentId = e.iDepartmentId)
    WHERE
        r.IsDeleted = 0
        AND e.iDepartmentId IN (SELECT DepartmentId FROM @DepartmentIds)
        AND r.ReadingListId IN (SELECT Id FROM @ReadingListIds)
        
END
GO

IF OBJECT_ID('[dbo].[GetReadingListUsersOfDepartmentsForReport]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetReadingListUsersOfDepartmentsForReport] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetReadingListUsersOfDepartmentsForReport]
    @DepartmentId INT,
    @IncludeSubDepartments BIT,
    @ReadingListIds AS [dbo].[Item] READONLY
AS
BEGIN

    DECLARE @DepartmentIds TABLE
    (
        DepartmentId INT
    );
    
    INSERT INTO @DepartmentIds (DepartmentId) VALUES (@DepartmentId)
    
    IF @IncludeSubDepartments = 1
    BEGIN
        INSERT INTO @DepartmentIds (DepartmentId)
        SELECT iDepartmentId FROM m136_GetDepartmentsRecursive(@DepartmentId)
    END
    
    SELECT
        e.iEmployeeId AS UserId,
        e.strFirstName + ' ' + e.strLastName AS EmployeeName,
        d.strName AS DepartmentName,
        COUNT(DISTINCT r.ReadingListId) AS NumberOfReadingLists,
        COUNT(DISTINCT doc.iEntityId) AS NumberOfDocuments,
        COUNT(DISTINCT cr.iEntityId) AS NumberOfOKDocuments
    FROM
        ReadingList r
            INNER JOIN ReadingListDocuments rld ON r.ReadingListId = rld.ReadingListId
            INNER JOIN m136_tblDocument doc ON rld.DocumentId = doc.iDocumentId AND doc.iLatestApproved = 1
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 2 -- Department reader
            INNER JOIN tblDepartment d ON rlr.ReaderId = d.iDepartmentId
            INNER JOIN tblEmployee e ON e.iDepartmentId = d.iDepartmentId AND e.iEmployeeId NOT IN (
																		SELECT EmployeeId 
																		FROM dbo.ReadingListExclusions 
																		WHERE ReadingListId = r.ReadingListId AND DepartmentId = e.iDepartmentId)
            LEFT JOIN m136_tblConfirmRead cr ON 
				doc.iEntityId = cr.iEntityId AND cr.iEmployeeId = e.iEmployeeId
				AND  cr.dtmConfirm = (SELECT MAX(dtmConfirm) FROM m136_tblConfirmRead WHERE iEntityId = doc.iEntityId AND iEmployeeId = e.iEmployeeId)
				AND(r.ReadingReceiptsExpire = 0 OR r.ReadingReceiptValidity = 0 OR (r.ReadingReceiptsExpire = 1 AND cr.dtmConfirm >=  DATEADD(month, -r.ReadingReceiptValidity ,GETDATE()) ))
    WHERE
        r.IsDeleted = 0
        AND e.iDepartmentId IN (SELECT DepartmentId FROM @DepartmentIds)
        AND r.ReadingListId IN (SELECT Id FROM @ReadingListIds)
    GROUP BY e.iEmployeeId, d.strName, e.strFirstName + ' ' + e.strLastName
    
    EXEC GetNumberOfOkReadingListsForUsersOfDepartments @DepartmentId, @IncludeSubDepartments, @ReadingListIds
END
GO

IF OBJECT_ID('[dbo].[GetNumberOfOkReadingListsForLeaderOfDepartments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetNumberOfOkReadingListsForLeaderOfDepartments] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetNumberOfOkReadingListsForLeaderOfDepartments]
	@LeaderId INT,
    @ReadingListIds AS [dbo].[Item] READONLY
AS
BEGIN
    DECLARE @UserConfirmedDocumentsOnReadingLists TABLE
    (
        UserId INT,
        ReadingListId INT,
        ReadingListName NVARCHAR(100),
        IsOK BIT
    );
    
    -- Insert reading lists from person readers
    INSERT INTO @UserConfirmedDocumentsOnReadingLists
        (UserId, ReadingListId, ReadingListName, IsOK)
    SELECT
        e.iEmployeeId, rl.ReadingListId, rl.Name, dbo.AreDocumentsInReadingListConfirmedByUser(e.iEmployeeId, rl.ReadingListId, rl.ReadingReceiptsExpire, rl.ReadingReceiptValidity)
    FROM
        ReadingList rl
            INNER JOIN ReadingListReaders rlr ON rl.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 1 -- Person reader
            INNER JOIN tblEmployee e ON rlr.ReaderId = e.iEmployeeId
    WHERE
        rl.IsDeleted = 0
        AND (
            (@LeaderId IS NOT NULL AND e.iEmployeeId = @LeaderId)
            OR (@LeaderId IS NULL AND e.iEmployeeId IN (SELECT EmployeeId FROM DepartmentResponsibles WHERE ResponsibleTypeId = 1))
        )        
        AND rl.ReadingListId IN (SELECT Id FROM @ReadingListIds)
        
    -- Insert reading list from department readers
    INSERT INTO @UserConfirmedDocumentsOnReadingLists
        (UserId, ReadingListId, ReadingListName, IsOK)
    SELECT
        e.iEmployeeId, rl.ReadingListId, rl.Name, dbo.AreDocumentsInReadingListConfirmedByUser(e.iEmployeeId, rl.ReadingListId, rl.ReadingReceiptsExpire, rl.ReadingReceiptValidity)
    FROM
        ReadingList rl
            INNER JOIN ReadingListReaders rlr ON rl.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 2 -- Department reader
            INNER JOIN tblDepartment d ON d.iDepartmentId = rlr.ReaderId
            INNER JOIN tblEmployee e ON d.iDepartmentId = e.iDepartmentId
    WHERE
        rl.IsDeleted = 0
        AND (
            (@LeaderId IS NOT NULL AND e.iEmployeeId = @LeaderId)
            OR (@LeaderId IS NULL AND e.iEmployeeId IN (SELECT EmployeeId FROM DepartmentResponsibles WHERE ResponsibleTypeId = 1))
        )
        AND rl.ReadingListId IN (SELECT Id FROM @ReadingListIds)
        AND NOT EXISTS(SELECT 1 FROM @UserConfirmedDocumentsOnReadingLists WHERE UserId = e.iEmployeeId AND ReadingListId = rl.ReadingListId)
        AND NOT EXISTS (SELECT EmployeeId FROM dbo.ReadingListExclusions WHERE ReadingListId = rl.ReadingListId AND DepartmentId = d.iDepartmentId AND EmployeeId = e.iEmployeeId)
        
    -- Insert reading list documents from role readers
    INSERT INTO @UserConfirmedDocumentsOnReadingLists
        (UserId, ReadingListId, ReadingListName, IsOK)
    SELECT
        esg.iEmployeeId, rl.ReadingListId, rl.Name, dbo.AreDocumentsInReadingListConfirmedByUser(esg.iEmployeeId, rl.ReadingListId, rl.ReadingReceiptsExpire, rl.ReadingReceiptValidity)
    FROM 
        ReadingList rl
            INNER JOIN ReadingListReaders rlr ON rl.ReadingListId = rlr.ReadingListId AND ReaderTypeId = 3 -- Role reader
            INNER JOIN tblSecGroup sg ON rlr.ReaderId = sg.iSecGroupId
            INNER JOIN relEmployeeSecGroup esg ON sg.iSecGroupId = esg.iEmployeeId
    WHERE
        rl.IsDeleted = 0
        AND (
            (@LeaderId IS NOT NULL AND esg.iEmployeeId = @LeaderId)
            OR (@LeaderId IS NULL AND esg.iEmployeeId IN (SELECT EmployeeId FROM DepartmentResponsibles WHERE ResponsibleTypeId = 1))
        )
        AND rl.ReadingListId IN (SELECT Id FROM @ReadingListIds)
        AND NOT EXISTS(SELECT 1 FROM @UserConfirmedDocumentsOnReadingLists WHERE UserId = esg.iEmployeeId AND ReadingListId = rl.ReadingListId)
        
    SELECT DISTINCT
        UserId,
        ReadingListId,
        ReadingListName,
        IsOK
    FROM
        @UserConfirmedDocumentsOnReadingLists
END
GO


IF OBJECT_ID('[dbo].[NumberOfReadingListsAssociateWithUser]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[NumberOfReadingListsAssociateWithUser]() RETURNS BIT AS BEGIN RETURN 1 END;')
GO
ALTER FUNCTION [dbo].[NumberOfReadingListsAssociateWithUser]
(
	@UserId INT
)
RETURNS INT
AS
BEGIN
    DECLARE @Result INT;
	DECLARE @ReadingListIds TABLE (ReadingListId INT);
    
    INSERT INTO @ReadingListIds (ReadingListId)
    SELECT r.ReadingListId
    FROM
        ReadingList r
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 1 -- Person reader
            INNER JOIN tblEmployee e ON e.iEmployeeId = rlr.ReaderId
    WHERE
        r.IsDeleted = 0
        AND e.iEmployeeId = @UserId
    
    INSERT INTO @ReadingListIds (ReadingListId)
    SELECT r.ReadingListId
    FROM
        ReadingList r
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 2 -- Department reader
            INNER JOIN tblDepartment d ON d.iDepartmentId = rlr.ReaderId
            INNER JOIN tblEmployee e ON e.iDepartmentId = d.iDepartmentId 
									
    WHERE
        r.IsDeleted = 0
        AND e.iEmployeeId = @UserId
        AND NOT EXISTS (SELECT EmployeeId FROM dbo.ReadingListExclusions WHERE ReadingListId = r.ReadingListId AND DepartmentId = d.iDepartmentId AND EmployeeId = @UserId)
    
    INSERT INTO @ReadingListIds (ReadingListId)
    SELECT r.ReadingListId
    FROM
        ReadingList r
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 3 -- Role reader
            INNER JOIN tblSecGroup sg ON rlr.ReaderId = sg.iSecGroupId
            INNER JOIN relEmployeeSecGroup esg ON sg.iSecGroupId = esg.iSecGroupId
    WHERE
        r.IsDeleted = 0
        AND esg.iEmployeeId = @UserId
    
    SELECT @Result = COUNT(DISTINCT ReadingListId)
    FROM @ReadingListIds
    
    RETURN @Result;
END
GO

IF OBJECT_ID('[dbo].[NumberOfReadingListDocumentsAssociateWithUser]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[NumberOfReadingListDocumentsAssociateWithUser]() RETURNS BIT AS BEGIN RETURN 1 END;')
GO
ALTER FUNCTION [dbo].[NumberOfReadingListDocumentsAssociateWithUser]
(
	@UserId INT
)
RETURNS INT
AS
BEGIN
    DECLARE @Result INT;
	DECLARE @ReadingListDocumentIds TABLE (DocumentId INT);
    
    INSERT INTO @ReadingListDocumentIds (DocumentId)
    SELECT rld.DocumentId
    FROM
        ReadingList r
            INNER JOIN ReadingListDocuments rld ON r.ReadingListId = rld.ReadingListId
            INNER JOIN m136_tblDocument doc ON rld.DocumentId = doc.iDocumentId AND doc.iLatestApproved = 1
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 1 -- Person reader
            INNER JOIN tblEmployee e ON e.iEmployeeId = rlr.ReaderId
    WHERE
        r.IsDeleted = 0
        AND e.iEmployeeId = @UserId
    
    INSERT INTO @ReadingListDocumentIds (DocumentId)
    SELECT rld.DocumentId
    FROM
        ReadingList r
            INNER JOIN ReadingListDocuments rld ON r.ReadingListId = rld.ReadingListId
            INNER JOIN m136_tblDocument doc ON rld.DocumentId = doc.iDocumentId AND doc.iLatestApproved = 1
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 2 -- Department reader
            INNER JOIN tblDepartment d ON d.iDepartmentId = rlr.ReaderId
            INNER JOIN tblEmployee e ON e.iDepartmentId = d.iDepartmentId
    WHERE
        r.IsDeleted = 0
        AND e.iEmployeeId = @UserId
        AND NOT EXISTS (SELECT EmployeeId FROM dbo.ReadingListExclusions WHERE ReadingListId = r.ReadingListId AND DepartmentId = d.iDepartmentId AND EmployeeId = @UserId)
    
    INSERT INTO @ReadingListDocumentIds (DocumentId)
    SELECT rld.DocumentId
    FROM
        ReadingList r
            INNER JOIN ReadingListDocuments rld ON r.ReadingListId = rld.ReadingListId
            INNER JOIN m136_tblDocument doc ON rld.DocumentId = doc.iDocumentId AND doc.iLatestApproved = 1
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 3 -- Role reader
            INNER JOIN tblSecGroup sg ON rlr.ReaderId = sg.iSecGroupId
            INNER JOIN relEmployeeSecGroup esg ON sg.iSecGroupId = esg.iSecGroupId
    WHERE
        r.IsDeleted = 0
        AND esg.iEmployeeId = @UserId
    
    SELECT @Result = COUNT(DISTINCT DocumentId)
    FROM @ReadingListDocumentIds
    
    RETURN @Result;
END
GO

IF OBJECT_ID('[dbo].[NumberOfReadingListConfirmedDocumentsAssociateWithUser]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[NumberOfReadingListConfirmedDocumentsAssociateWithUser]() RETURNS BIT AS BEGIN RETURN 1 END;')
GO
ALTER FUNCTION [dbo].[NumberOfReadingListConfirmedDocumentsAssociateWithUser]
(
	@UserId INT
)
RETURNS INT
AS
BEGIN
    DECLARE @Result INT;
	DECLARE @ReadingListDocumentIds TABLE (DocumentId INT);
    
    INSERT INTO @ReadingListDocumentIds (DocumentId)
    SELECT rld.DocumentId
    FROM
        ReadingList r
            INNER JOIN ReadingListDocuments rld ON r.ReadingListId = rld.ReadingListId
            INNER JOIN m136_tblDocument doc ON rld.DocumentId = doc.iDocumentId AND doc.iLatestApproved = 1
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 1 -- Person reader
            INNER JOIN tblEmployee e ON e.iEmployeeId = rlr.ReaderId
            INNER JOIN m136_tblConfirmRead cr ON doc.iEntityId = cr.iEntityId AND cr.iEmployeeId = e.iEmployeeId
					AND  cr.dtmConfirm = (SELECT MAX(dtmConfirm) FROM m136_tblConfirmRead WHERE iEntityId = doc.iEntityId AND iEmployeeId = e.iEmployeeId)
					AND(r.ReadingReceiptsExpire = 0 OR r.ReadingReceiptValidity = 0 OR (r.ReadingReceiptsExpire = 1 AND cr.dtmConfirm >=  DATEADD(month, -r.ReadingReceiptValidity ,GETDATE()) ))
    WHERE
        r.IsDeleted = 0
        AND e.iEmployeeId = @UserId
    
    INSERT INTO @ReadingListDocumentIds (DocumentId)
    SELECT rld.DocumentId
    FROM
        ReadingList r
            INNER JOIN ReadingListDocuments rld ON r.ReadingListId = rld.ReadingListId
            INNER JOIN m136_tblDocument doc ON rld.DocumentId = doc.iDocumentId AND doc.iLatestApproved = 1
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 2 -- Department reader
            INNER JOIN tblDepartment d ON d.iDepartmentId = rlr.ReaderId
            INNER JOIN tblEmployee e ON e.iDepartmentId = d.iDepartmentId
            INNER JOIN m136_tblConfirmRead cr ON doc.iEntityId = cr.iEntityId AND cr.iEmployeeId = e.iEmployeeId
            AND  cr.dtmConfirm = (SELECT MAX(dtmConfirm) FROM m136_tblConfirmRead WHERE iEntityId = doc.iEntityId AND iEmployeeId = e.iEmployeeId)
					AND(r.ReadingReceiptsExpire = 0 OR r.ReadingReceiptValidity = 0 OR (r.ReadingReceiptsExpire = 1 AND cr.dtmConfirm >=  DATEADD(month, -r.ReadingReceiptValidity ,GETDATE()) ))
    WHERE
        r.IsDeleted = 0
        AND e.iEmployeeId = @UserId
        AND NOT EXISTS (SELECT EmployeeId FROM dbo.ReadingListExclusions WHERE ReadingListId = r.ReadingListId AND DepartmentId = d.iDepartmentId AND EmployeeId = @UserId)
        
    
    INSERT INTO @ReadingListDocumentIds (DocumentId)
    SELECT rld.DocumentId
    FROM
        ReadingList r
            INNER JOIN ReadingListDocuments rld ON r.ReadingListId = rld.ReadingListId
            INNER JOIN m136_tblDocument doc ON rld.DocumentId = doc.iDocumentId AND doc.iLatestApproved = 1
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 3 -- Role reader
            INNER JOIN tblSecGroup sg ON rlr.ReaderId = sg.iSecGroupId
            INNER JOIN relEmployeeSecGroup esg ON sg.iSecGroupId = esg.iSecGroupId
            INNER JOIN m136_tblConfirmRead cr ON doc.iEntityId = cr.iEntityId AND cr.iEmployeeId = esg.iEmployeeId
            AND  cr.dtmConfirm = (SELECT MAX(dtmConfirm) FROM m136_tblConfirmRead WHERE iEntityId = doc.iEntityId AND iEmployeeId = esg.iEmployeeId)
					AND(r.ReadingReceiptsExpire = 0 OR r.ReadingReceiptValidity = 0 OR (r.ReadingReceiptsExpire = 1 AND cr.dtmConfirm >=  DATEADD(month, -r.ReadingReceiptValidity ,GETDATE()) ))
    WHERE
        r.IsDeleted = 0
        AND esg.iEmployeeId = @UserId
    
    SELECT @Result = COUNT(DISTINCT DocumentId)
    FROM @ReadingListDocumentIds
    
    RETURN @Result;
END
GO

IF OBJECT_ID('[dbo].[GetReadingListLeaderOfDepartmentsForReport]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetReadingListLeaderOfDepartmentsForReport] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetReadingListLeaderOfDepartmentsForReport]
    @LeaderId INT,
    @ReadingListIds AS [dbo].[Item] READONLY
AS
BEGIN
    DECLARE @LeaderReadingLists TABLE
    (
        LeaderId INT,
        EmployeeName VARCHAR(100),
        DepartmentName VARCHAR(80),
        ReadingListId INT
    );
    
    -- Insert reading list documents from person readers
    INSERT INTO @LeaderReadingLists
        (LeaderId, EmployeeName, DepartmentName, ReadingListId)
    SELECT
        e.iEmployeeId, e.strFirstName + ' ' + e.strLastName, d.strName, r.ReadingListId
    FROM
        ReadingList r
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 1 -- Person reader
            INNER JOIN tblEmployee e ON rlr.ReaderId = e.iEmployeeId
            INNER JOIN tblDepartment d ON d.iDepartmentId = e.iDepartmentId
    WHERE
        r.IsDeleted = 0
        AND (
            (@LeaderId IS NOT NULL AND e.iEmployeeId = @LeaderId)
            OR (@LeaderId IS NULL AND e.iEmployeeId IN (SELECT EmployeeId FROM DepartmentResponsibles WHERE ResponsibleTypeId = 1))
        )
        AND r.ReadingListId IN (SELECT Id FROM @ReadingListIds)
    
    -- Insert reading list documents from department readers
    INSERT INTO @LeaderReadingLists
        (LeaderId, EmployeeName, DepartmentName, ReadingListId)
    SELECT
        e.iEmployeeId, e.strFirstName + ' ' + e.strLastName, d.strName, r.ReadingListId
    FROM
        ReadingList r
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 2 -- Department reader
            INNER JOIN tblDepartment d ON d.iDepartmentId = rlr.ReaderId
            INNER JOIN tblEmployee e ON d.iDepartmentId = e.iDepartmentId
    WHERE
        r.IsDeleted = 0
        AND (
            (@LeaderId IS NOT NULL AND e.iEmployeeId = @LeaderId)
            OR (@LeaderId IS NULL AND e.iEmployeeId IN (SELECT EmployeeId FROM DepartmentResponsibles WHERE ResponsibleTypeId = 1))
        )
        AND r.ReadingListId IN (SELECT Id FROM @ReadingListIds)
        AND NOT EXISTS (SELECT 1 FROM @LeaderReadingLists lrl WHERE lrl.LeaderId = e.iEmployeeId AND lrl.ReadingListId = r.ReadingListId)
        AND NOT EXISTS (SELECT EmployeeId FROM dbo.ReadingListExclusions WHERE ReadingListId = r.ReadingListId AND DepartmentId = d.iDepartmentId AND EmployeeId = e.iEmployeeId)
        
    -- INSERT reading list documents from role readers
    INSERT INTO @LeaderReadingLists
        (LeaderId, EmployeeName, DepartmentName, ReadingListId)
    SELECT
        e.iEmployeeId, e.strFirstName + ' ' + e.strLastName, d.strName, r.ReadingListId
    FROM
        ReadingList r
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 3 -- Role reader
            INNER JOIN tblSecGroup sg ON rlr.ReaderId = sg.iSecGroupId
            INNER JOIN relEmployeeSecGroup esg ON sg.iSecGroupId = esg.iEmployeeId
            INNER JOIN tblEmployee e ON e.iEmployeeId = esg.iEmployeeId
            INNER JOIN tblDepartment d ON d.iDepartmentId = e.iDepartmentId
    WHERE
        r.IsDeleted = 0
        AND (
            (@LeaderId IS NOT NULL AND e.iEmployeeId = @LeaderId)
            OR (@LeaderId IS NULL AND e.iEmployeeId IN (SELECT EmployeeId FROM DepartmentResponsibles WHERE ResponsibleTypeId = 1))
        )
        AND r.ReadingListId IN (SELECT Id FROM @ReadingListIds)
        AND NOT EXISTS (SELECT 1 FROM @LeaderReadingLists lrl WHERE lrl.LeaderId = e.iEmployeeId AND lrl.ReadingListId = r.ReadingListId)
        
    SELECT
        DISTINCT LeaderId AS UserId,
        EmployeeName,
        DepartmentName,
        dbo.NumberOfReadingListsAssociateWithUser(LeaderId) AS NumberOfReadingLists,
        dbo.NumberOfReadingListDocumentsAssociateWithUser(LeaderId) AS NumberOfDocuments,
        dbo.NumberOfReadingListConfirmedDocumentsAssociateWithUser(LeaderId) AS NumberOfOKDocuments
    FROM
        @LeaderReadingLists
    
    EXEC GetNumberOfOkReadingListsForLeaderOfDepartments @LeaderId, @ReadingListIds
END
GO

IF OBJECT_ID('[dbo].[GetNumberOfOkReadingListsForUsersOfRole]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetNumberOfOkReadingListsForUsersOfRole] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetNumberOfOkReadingListsForUsersOfRole]
	@RoleId INT,
    @ReadingListIds AS [dbo].[Item] READONLY
AS
BEGIN
    SELECT
        e.iEmployeeId AS UserId, 
        r.ReadingListId AS ReadingListId, 
        r.Name AS ReadingListName, 
        dbo.AreDocumentsInReadingListConfirmedByUser(e.iEmployeeId, r.ReadingListId, r.ReadingReceiptsExpire, r.ReadingReceiptValidity) AS IsOK
    FROM
        ReadingList r
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId
            INNER JOIN tblSecGroup sg ON rlr.ReaderId = sg.iSecGroupId AND rlr.ReaderTypeId = 3 --Role reader
            INNER JOIN relEmployeeSecGroup esg ON sg.iSecGroupId = esg.iSecGroupId
            INNER JOIN tblEmployee e ON esg.iEmployeeId = e.iEmployeeId
    WHERE
        r.IsDeleted = 0
        AND sg.iSecGroupId = @RoleId
        AND r.ReadingListId IN (SELECT Id FROM @ReadingListIds)
END
GO

IF OBJECT_ID('[dbo].[GetReadingListUserRoleForReport]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetReadingListUserRoleForReport] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetReadingListUserRoleForReport]
    @RoleId INT,
    @ReadingListIds AS [dbo].[Item] READONLY
AS
BEGIN
    SELECT
        e.iEmployeeId AS UserId,
        e.strFirstName + ' ' + e.strLastName AS EmployeeName,
        d.strName AS DepartmentName,
        COUNT(DISTINCT r.ReadingListId) AS NumberOfReadingLists,
        COUNT(DISTINCT doc.iEntityId) AS NumberOfDocuments,
        COUNT(DISTINCT cr.iEntityId) AS NumberOfOKDocuments
    FROM
        ReadingList r
            INNER JOIN ReadingListDocuments rld ON r.ReadingListId = rld.ReadingListId
            INNER JOIN m136_tblDocument doc ON rld.DocumentId = doc.iDocumentId AND doc.iLatestApproved = 1
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 3
            INNER JOIN tblSecGroup sg ON rlr.ReaderId = sg.iSecGroupId 
            INNER JOIN relEmployeeSecGroup esg ON sg.iSecGroupId = esg.iSecGroupId
            INNER JOIN tblEmployee e ON esg.iEmployeeId = e.iEmployeeId
            INNER JOIN tblDepartment d ON e.iDepartmentId = d.iDepartmentId
            LEFT JOIN m136_tblConfirmRead cr ON doc.iEntityId = cr.iEntityId AND cr.iEmployeeId = e.iEmployeeId
					AND  cr.dtmConfirm = (SELECT MAX(dtmConfirm) FROM m136_tblConfirmRead WHERE iEntityId = doc.iEntityId AND iEmployeeId = e.iEmployeeId)
					AND(r.ReadingReceiptsExpire = 0 OR r.ReadingReceiptValidity = 0 OR (r.ReadingReceiptsExpire = 1 AND cr.dtmConfirm >=  DATEADD(month, -r.ReadingReceiptValidity ,GETDATE()) ))
    WHERE
        r.IsDeleted = 0
        AND sg.iSecgroupId = @RoleId
        AND r.ReadingListId IN (SELECT Id FROM @ReadingListIds)
    GROUP BY e.iEmployeeId, d.strName, e.strFirstName + ' ' + e.strLastName
    
    EXEC GetNumberOfOkReadingListsForUsersOfRole @RoleId, @ReadingListIds
END
GO