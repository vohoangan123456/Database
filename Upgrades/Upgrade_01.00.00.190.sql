INSERT INTO #Description VALUES('Create procedure m136_be_GetEmployeeDocumentConfirms')
GO

IF OBJECT_ID('[dbo].[m136_be_GetEmployeeDocumentConfirms]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetEmployeeDocumentConfirms] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetEmployeeDocumentConfirms] 
	@iDocumentId INT,
	@iSecurityId INT = 0,
	@iDepartmentId INT = 0,
    @includeSubDepartments BIT,
	@fromDate DATETIME = null,
	@toDate DATETIME = null
AS
BEGIN
	IF @toDate <> null
    BEGIN
        SET @toDate = DATEADD(day, 1, @toDate)
    END
    DECLARE @RecursiveDepartmentIdTable TABLE(iDepartmentId INT NULL);
    DECLARE @iDepIdTable TABLE(iDepartmentId INT NULL)

    IF @includeSubDepartments = 1
    BEGIN
		INSERT INTO @RecursiveDepartmentIdTable
		SELECT iDepartmentId FROM m136_GetDepartmentsRecursive(@iDepartmentId);
    END
    
    --Rettigheter
    DECLARE @modulePermission int
    SET @modulePermission = dbo.fnSecurityGetPermission(136, 460, @iSecurityId, 0)

    IF (@modulePermission & 6) > 0
    BEGIN
        INSERT INTO @iDepIdTable
            SELECT
                iDepartmentId 
            FROM 
                tblEmployee
            where
            (
                iEmployeeId = @iSecurityId 
                OR (@modulePermission & 2 ) = 2
            )
            AND
            (
                (@includeSubDepartments = 0 AND iDepartmentId = @iDepartmentId)
                OR iDepartmentId IN (SELECT iDepartmentId FROM @RecursiveDepartmentIdTable))
    END

    DECLARE @docTable TABLE(iEntityId int null, iDocumentId int null, strName varchar(200) null, iVersion int null, iHandbookId int null)
    INSERT INTO @docTable
    SELECT
        iEntityId,
        iDocumentId,
        strName as strDocumentName,
        iVersion,
        iHandbookId
    FROM
        m136_tblDocument
    WHERE
        iDocumentId = @iDocumentId
        AND iApproved = 1

    --Ansatt-utdrag
    DECLARE @empTable TABLE(iEmployeeId INT NULL, strFirstName VARCHAR(100) NULL, strLastName VARCHAR(100) NULL, iDepartmentId INT NULL)
    INSERT INTO @empTable
        SELECT
            iEmployeeId,
            strFirstName,
            strLastName,
            iDepartmentId
        FROM
            tblEmployee
        WHERE
            iDepartmentId = @iDepartmentId
            AND iDepartmentId in (SELECT iDepartmentId FROM @iDepIdTable)
		
		
    --Confirm-table utdrag
    DECLARE @cTable TABLE(iEntityId INT NOT NULL, iEmployeeId INT, dtmConfirm DATETIME)
    INSERT INTO @cTable
        SELECT
            iEntityId, iEmployeeId, dtmConfirm
        FROM
            m136_tblConfirmRead
        WHERE
            iEntityId in (SELECT iEntityId FROM @docTable)
            AND (dtmConfirm > @fromDate OR @fromDate IS NULL)
            AND (dtmConfirm < @toDate OR @toDate IS NULL)

    DECLARE @persons TABLE(DepartmentId INT, NumberOfEmployees INT)
    INSERT INTO @persons(DepartmentId, NumberOfEmployees)
        SELECT
            iDepartmentId,
            COUNT(iEmployeeId) AS NumberOfEmployees
        FROM
            tblEmployee
        GROUP BY iDepartmentId


    DECLARE @tmp TABLE(iEmployeeId INT, strEmployeeName NVARCHAR(200), iDepartmentId INT, strDepName NVARCHAR(200),
	iReadStatus INT, dtmConfirm DATETIME, iDocumentId INT, strDocumentName NVARCHAR(500), iVersion int, iVersionStatus int,
	iApproved INT, iDraft INT, iEntityId INT, iRead INT)

    INSERT INTO @tmp 
        (iEmployeeId, strEmployeeName, iDepartmentId, strDepName, iReadStatus, dtmConfirm, iDocumentId, 
        strDocumentName, iVersion, iVersionStatus, iApproved, iDraft, iEntityId, iRead)
        SELECT
            r.iEmployeeId, r.strEmployeeName, r.iDepartmentId, r.strDepName, r.iReadStatus, r.dtmConfirm, r.iDocumentId,
            r.strDocumentName, r.iVersion, r.iVersionStatus, r.iApproved, r.iDraft, r.iEntityId,
            SUM(
                CASE
                    WHEN cr.iConfirmId IS NULL then 0
                    ELSE 1
                END) as ConfirmedRead
        FROM (
            SELECT
                emp.iEmployeeId,
                emp.strFirstName +' '+ emp.strLastName as strEmployeeName,
                emp.iDepartmentId,
                dep.strName as strDepName,
                (case when isnull(cr.iEmployeeId, 0)=0 then 0 else 1 end) as iReadStatus,
                cr.dtmConfirm,
                doc.iDocumentId,
                doc.iEntityId,
                doc.strName as strDocumentName,
                doc.iVersion,
                --	round(dbo.m136_fnDocumentConfirmPercentage(dep.iDepartmentId, doc.iEntityId, @fromDate, @toDate),2) as readPercent,
                0 as readPercent,
                dbo.m136_fnGetVersionStatus(doc.iEntityId, doc.iDocumentId, doc.iVersion, 
                details.dtmPublish, details.dtmPublishUntil, getdate(), details.iDraft, details.iApproved) as iVersionStatus,
                details.iApproved,
                details.iDraft
            FROM
                @docTable doc
                    FULL JOIN @empTable emp on 1 = 1
                    JOIN m136_tblDocument details on details.iEntityId = doc.iEntityId
                    LEFT JOIN @cTable cr on cr.iEmployeeId = emp.iEmployeeId AND cr.iEntityId = doc.iEntityId
                    LEFT OUTER JOIN tblDepartment dep on dep.iDepartmentId = emp.iDepartmentId
        ) r
            LEFT JOIN m136_tblConfirmRead cr on (r.iEntityId = cr.iEntityId and cr.iEmployeeId = r.iEmployeeId)
            GROUP BY r.iEmployeeId, r.strEmployeeName, r.iDepartmentId, r.strDepName, r.iReadStatus, r.dtmConfirm, r.iDocumentId, r.strDocumentName, r.iVersion, r.iVersionStatus, r.iApproved, r.iDraft, r.iEntityId

        ORDER BY r.iVersion desc

    DECLARE @total INT
    SELECT
        @total = NumberOfEmployees
    FROM
        @persons
    WHERE
        DepartmentId = @iDepartmentId

    DECLARE @readPercentage TABLE(iEntityId INT, readPercentage DECIMAL)
    INSERT INTO @readPercentage(iEntityId, readPercentage)
        SELECT 
            r.iEntityId, (CAST(r.totalRead AS DECIMAL) / CAST(@total AS DECIMAL)) * 100 AS readPercentage
        FROM (
            SELECT iEntityId, sum(iRead) AS totalRead FROM @tmp 
        GROUP BY iEntityId
        ) r

    SELECT
        t.iEmployeeId, t.strEmployeeName, t.iDepartmentId, t.strDepName, t.iReadStatus, t.dtmConfirm, t.iDocumentId, t.strDocumentName, t.iVersion, t.iVersionStatus, t.iApproved, t.iDraft, p.readPercentage
    FROM @tmp t
        JOIN @readPercentage p on t.iEntityId = p.iEntityId
    ORDER BY 
        t.iVersion desc,
        t.strDepName,
        t.iReadStatus desc,
        t.strEmployeeName,
        t.dtmConfirm desc
END
GO