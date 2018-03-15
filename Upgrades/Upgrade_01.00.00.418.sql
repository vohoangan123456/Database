INSERT INTO #Description VALUES ('Modify SP for report')
GO

IF OBJECT_ID('[dbo].[m136_rptGetPersonChapterConfirmsSums]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_rptGetPersonChapterConfirmsSums] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_rptGetPersonChapterConfirmsSums]
(
	@iSecurityId INT = 0,
	@iHandbookId INT = 0,
	@fromDate DATETIME = NULL,
	@toDate DATETIME = NULL,
	@iEmployeeId INT = 0,
	@iLatestVersions BIT = 1,
	@recursive BIT = 0
)
AS
BEGIN
	SET NOCOUNT ON;
	IF @toDate <> NULL
	BEGIN
		set @toDate = DATEADD(DAY, 1, @toDate)
	END

	DECLARE @empTable TABLE(iEmployeeId INT NULL)
	--Seg selv
	IF @iEmployeeId = @iSecurityId
		INSERT INTO @empTable(iEmployeeId) SELECT @iEmployeeId


	--Modul-administrator
	IF (SELECT COUNT(iEmployeeId) FROM @empTable)=0
	BEGIN
		IF (dbo.fnSecurityGetPermission(136, 460, @iSecurityId,0) & 2) = 2
		BEGIN
			INSERT INTO @emptable SELECT @iEmployeeId
		END
	END

	--Kan lese kvitteringer på egen org-enhet
	IF (SELECT COUNT(iEmployeeId) FROM @empTable) = 0
	BEGIN
		IF (dbo.fnSecurityGetPermission(136, 460, @iSecurityId, 0) & 4) = 4
		BEGIN
			INSERT INTO @emptable
			SELECT iEmployeeId FROM tblEmployee WHERE iDepartmentId 
			IN (SELECT iDepartmentId FROM tblEmployee WHERE iEmployeeId = @iSecurityId) AND iEmployeeId = @iEmployeeId
		END
	END


	IF (SELECT COUNT(iEmployeeId) FROM @empTable) > 0
	BEGIN
		DECLARE @HandbookIdTable TABLE(iHandbookId INT)
		IF @iHandbookId IS NOT NULL AND @iHandbookId <> 0
		BEGIN
			IF @recursive = 1
			BEGIN
				INSERT INTO @HandbookIdTable(iHandbookId)
				SELECT 
					DISTINCT h.iHandbookId 
				FROM 
					[dbo].[m136_GetHandbookRecursive](@iHandbookId, @iSecurityId, 1) h
					JOIN dbo.m136_tblDocument d ON h.iHandbookId = d.iHandbookId
					JOIN dbo.m136_tblConfirmRead c ON c.iEntityId = d.iEntityId
					AND c.iEmployeeId = @iEmployeeId
							AND (c.dtmConfirm >= @fromDate OR @fromDate IS NULL OR c.dtmConfirm IS NULL)
							AND (c.dtmConfirm <= @toDate OR @toDate IS NULL OR c.dtmConfirm IS NULL)
			END
			ELSE
				INSERT INTO @HandbookIdTable(iHandbookId) VALUES(@iHandbookId);
		END
		ELSE
		BEGIN
			IF @recursive = 1
			BEGIN
				INSERT INTO @HandbookIdTable(iHandbookId)
				SELECT 
					DISTINCT h.iHandbookId 
				FROM dbo.m136_tblHandbook h
					JOIN dbo.m136_tblDocument d ON h.iHandbookId = d.iHandbookId
					JOIN dbo.m136_tblConfirmRead c ON c.iEntityId = d.iEntityId
					AND c.iEmployeeId = @iEmployeeId
							AND (c.dtmConfirm >= @fromDate OR @fromDate IS NULL OR c.dtmConfirm IS NULL)
							AND (c.dtmConfirm <= @toDate OR @toDate IS NULL OR c.dtmConfirm IS NULL)
				WHERE [dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, h.iHandbookId) = 1
			END
			ELSE
				INSERT INTO @HandbookIdTable(iHandbookId)
				SELECT 
					DISTINCT h.iHandbookId 
				FROM dbo.m136_tblHandbook h
					JOIN dbo.m136_tblDocument d ON h.iHandbookId = d.iHandbookId
					JOIN dbo.m136_tblConfirmRead c ON c.iEntityId = d.iEntityId
					AND c.iEmployeeId = @iEmployeeId
							AND (c.dtmConfirm >= @fromDate OR @fromDate IS NULL OR c.dtmConfirm IS NULL)
							AND (c.dtmConfirm <= @toDate OR @toDate IS NULL OR c.dtmConfirm IS NULL)
				WHERE [dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, h.iHandbookId) = 1
				AND h.iParentHandbookId IS NULL;
		END
		
		--Mappeutdrag:
		DECLARE @bookTable TABLE(iHandbookId INT NOT NULL, 
			strChapterName VARCHAR(400) NULL, 
			strParentPath VARCHAR(1000) NULL, 
			confirmPercent FLOAT NULL, iMin INT )
		INSERT INTO @bookTable
		SELECT
			iHandbookId,
			strName,
			dbo.fn136_GetParentPath(iHandbookId),
			dbo.m136_fnPersonHandbookConfirmPercentage(@iEmployeeId, iHandbookId, @fromDate, @toDate),
			iMin
		FROM
			m136_tblHandbook
		WHERE
			iHandbookId IN (SELECT iHandbookId FROM @HandbookIdTable)
			AND iDeleted = 0

		--Dokumentutdrag:
		DECLARE @docTable TABLE(iEntityId INT NULL, 
			iDocumentId INT NULL, 
			strName varchar(200) NULL, 
			iVersion INT NULL, 
			iHandbookId INT NULL, 
			iSort INT NULL, 
			iVirt INT not NULL);
			
		INSERT INTO @docTable
		SELECT	doc.iEntityId,
			doc.iDocumentId,
			doc.strName,
			doc.iVersion,
			doc.iHandbookId,
			doc.iSort,
			0
		FROM
			@bookTable book
			RIGHT JOIN m136_tblDocument doc ON doc.iHandbookId = book.iHandbookId
		WHERE
			doc.iHandbookId = book.iHandbookId
			AND iLatestApproved = 1;

		--virtual
		INSERT INTO @docTable
		SELECT 	doc.iEntityId,
			virt.iDocumentId,
			doc.strName,
			doc.iVersion,
			virt.iHandbookId,
			virt.iSort,
			1
		FROM
			m136_relVirtualRelation virt
			left join m136_tblDocument doc on doc.iDocumentId=virt.iDocumentId
			right join @bookTable book on book.iHandbookId=virt.iHandbookId
		WHERE
			doc.iLatestApproved = 1;

		SELECT
			doc.iDocumentId,
			doc.iEntityId,
			doc.strName,
			doc.iVersion,
			doc.iHandbookId,
			book.strChapterName,
			book.strParentPath,
			book.confirmPercent,
			CASE WHEN (ISDATE(cr.dtmConfirm) = 1 AND cr.iEmployeeId = @iEmployeeId) THEN 1 ELSE 0 END AS iReadStatus,
			cr.dtmConfirm,
			doc.iVirt,
			dbo.m136_fnGetVersionStatus(doc.iEntityId, doc.iDocumentId, doc.iVersion, 
				details.dtmPublish, details.dtmPublishUntil, GETDATE(), details.iDraft, details.iApproved) AS iVersionStatus,
			details.iApproved,
			details.iDraft
		FROM
			@empTable emp
			CROSS JOIN @docTable doc 
			LEFT JOIN m136_tblDocument details ON details.iEntityId = doc.iEntityId
			LEFT OUTER JOIN m136_tblConfirmRead cr ON doc.iEntityId = cr.iEntityId
				AND emp.iEmployeeId = cr.iEmployeeId
				AND (dtmConfirm >= @fromDate OR @fromDate IS NULL OR dtmConfirm IS NULL)
				AND (dtmConfirm <= @toDate OR @toDate IS NULL OR dtmConfirm IS NULL)
			LEFT OUTER JOIN @bookTable book ON doc.iHandbookId=book.iHandbookId
		ORDER BY
			doc.iSort,
			doc.iDocumentId,
			doc.iVersion DESC,
			cr.dtmConfirm DESC
		
	END
END
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
	@toDate DATETIME = null,
	@includeAllVersions BIT = 0
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
		INSERT INTO @iDepIdTable
		SELECT iDepartmentId FROM m136_GetDepartmentsRecursive(@iDepartmentId);
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
        AND ((@includeAllVersions = 1 AND iApproved = 1)
			 OR ( @includeAllVersions = 0 AND iLatestApproved = 1))

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
            OR iDepartmentId in (SELECT iDepartmentId FROM @iDepIdTable)
		
		
    --Confirm-table utdrag
    DECLARE @cTable TABLE(iEntityId INT NOT NULL, iEmployeeId INT, dtmConfirm DATETIME)
    INSERT INTO @cTable
        SELECT
            iEntityId, iEmployeeId, dtmConfirm
        FROM
            m136_tblConfirmRead
        WHERE
            iEntityId in (SELECT iEntityId FROM @docTable)
            AND (dtmConfirm >= @fromDate OR @fromDate IS NULL)
            AND (dtmConfirm <= @toDate OR @toDate IS NULL)

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
            OR DepartmentId in (SELECT iDepartmentId FROM @iDepIdTable)

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

IF OBJECT_ID('[dbo].[m136_be_GetChapterEmployeeSums]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetChapterEmployeeSums] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetChapterEmployeeSums] 
(
	@iSecurityId INT = 0,
	@iHandbookId INT = 0,
	@iDepartmentId INT = 0,
	@fromDate DATETIME = null,
	@toDate DATETIME = null,
	@iRecursive INT = 0,
	@iRecursiveDepartment INT = 0
)
AS
BEGIN

	IF @toDate IS NOT NULL
	BEGIN
		SET @toDate = dateadd(day, 1, @toDate)
	END

	DECLARE @HandbookIdTable TABLE(iHandbookId INT)
	
	IF @iHandbookId IS NOT NULL AND @iHandbookId <> 0
	BEGIN
		IF @iRecursive = 1
		BEGIN
			INSERT INTO @HandbookIdTable(iHandbookId)
			SELECT 
				iHandbookId 
			FROM 
				[dbo].[m136_GetHandbookRecursive](@iHandbookId, @iSecurityId, 1);
		END
		ELSE
			INSERT INTO @HandbookIdTable(iHandbookId) VALUES(@iHandbookId);
	END
	ELSE
	BEGIN
		IF @iRecursive = 1
		BEGIN
			INSERT INTO @HandbookIdTable(iHandbookId)
			SELECT 
				iHandbookId 
			FROM dbo.m136_tblHandbook
			WHERE iDeleted = 0
				  AND [dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1;
		END
		ELSE
			INSERT INTO @HandbookIdTable(iHandbookId)
			SELECT 
				iHandbookId 
			FROM dbo.m136_tblHandbook
			WHERE iDeleted = 0
				  AND [dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1
				  AND iParentHandbookId IS NULL;
	END
	
	--Mappeutdrag:
	DECLARE @bookTable TABLE(iHandbookId INT NOT NULL, strChapterName VARCHAR(400) NULL, strParentPath VARCHAR(1000) NULL)
	INSERT INTO @bookTable
	SELECT
		iHandbookId,
		strName,
		dbo.fn136_GetParentPath(iHandbookId)
	FROM
		m136_tblHandbook
	WHERE
		iHandbookId IN (SELECT iHandbookId FROM @HandbookIdTable)
		AND iDeleted=0
		AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 0x01)>0 

	--Dokumentutdrag:
	DECLARE @docTable TABLE(iEntityId INT NULL, iDocumentId INT NULL, strName VARCHAR(200) NULL, iVersion INT NULL,
							 iHandbookId INT NULL, iSort INT NULL, iVirt INT NOT NULL,
							 dtmPublish DATETIME NULL, dtmPublishUntil DATETIME NULL, iDraft INT NULL,iApproved INT NULL)
	INSERT INTO @docTable
	SELECT	doc.iEntityId,
		doc.iDocumentId,
		doc.strName,
		doc.iVersion,
		doc.iHandbookId,
		doc.iSort,
		0,
		doc.dtmPublish,
		doc.dtmPublishUntil,
		doc.iDraft,
		doc.iApproved
	FROM
		@bookTable book
		RIGHT JOIN m136_tblDocument doc 
			ON doc.iHandbookId = book.iHandbookId
	WHERE
		doc.iHandbookId = book.iHandbookId
		AND iApproved = 1
		AND doc.iDeleted=0
		AND iLatestApproved = 1

	--virtual
	INSERT INTO @docTable
	SELECT 	doc.iEntityId,
		virt.iDocumentId,
		doc.strName,
		doc.iVersion,
		virt.iHandbookId,
		virt.iSort,
		1,
		doc.dtmPublish,
		doc.dtmPublishUntil,
		doc.iDraft,
		doc.iApproved
	FROM
		m136_relVirtualRelation virt
		LEFT JOIN m136_tblDocument doc ON doc.iDocumentId = virt.iDocumentId
		RIGHT JOIN @bookTable book ON book.iHandbookId = virt.iHandbookId
	WHERE
		doc.iApproved=1
		AND doc.iDeleted=0
		AND iLatestApproved = 1

	--Ansatt-utdrag
	DECLARE @empTable TABLE(iEmployeeId INT NULL, strFirstName VARCHAR(100) NULL, strLastName VARCHAR(100) NULL, iDepartmentId INT NULL)
	
	--Security, see own org-unit's reports?
	DECLARE @moduleAccess INT
	SET @moduleAccess = dbo.fnSecurityGetPermission(136, 460, @iSecurityId, 0)
	IF((@moduleAccess&4)=4)
	BEGIN
		DECLARE @iUserDepartmentId INT
		SELECT @iUserDepartmentId= iDepartmentId FROM tblEmployee WHERE iEmployeeId=@iSecurityId
		INSERT INTO @empTable
			SELECT
				iEmployeeId,
				strFirstName,
				strLastName,
				iDepartmentId
			FROM
				tblEmployee
			WHERE
				(iDepartmentId = @iDepartmentId 
				OR @iDepartmentId=0)
				AND iDepartmentId > 0
				AND iDepartmentId = @iUserDepartmentId
	END
	
	--Modul-administrator?
	IF((@moduleAccess&2)=2)
	BEGIN
		DELETE FROM @empTable
		DECLARE @Departments TABLE (iDepartmentId INT)
		IF (@iRecursiveDepartment = 0)
			BEGIN
				INSERT INTO @Departments SELECT @iDepartmentId;
			END
		ELSE
			BEGIN
				INSERT INTO @Departments SELECT iDepartmentId FROM dbo.m136_GetDepartmentsRecursive (@iDepartmentId);
			END
			
		INSERT INTO @empTable
		SELECT
			iEmployeeId,
			strFirstName,
			strLastName,
			iDepartmentId
		FROM
			tblEmployee
		WHERE
			iDepartmentId IN (SELECT iDepartmentId FROM @Departments) 
	END
	--Confirm-table utdrag
	DECLARE @cTable TABLE(iEntityId INT NOT NULL, iEmployeeId INT, dtmConfirm DATETIME)
	INSERT INTO @cTable
	SELECT
		iEntityId, 
		iEmployeeId, 
		dtmConfirm
	FROM
		m136_tblConfirmRead cr
	WHERE
		iEntityId in (SELECT iEntityId FROM @docTable)
		AND iEmployeeId IN (SELECT iEmployeeId FROM @empTable)
		AND (dtmConfirm >= @fromDate OR @fromDate IS NULL)
		AND (dtmConfirm <= @toDate OR @toDate IS NULL)

	-- Return select
	SELECT
		doc.iDocumentId,
		doc.iEntityId,
		doc.strName,
		doc.iVersion,
		doc.iHandbookId,
		book.strChapterName,
		book.strParentPath,
		dep.strName AS strDepName,
		dep.iDepartmentId,
		dep.iLevel,
		emp.strFirstName +' '+ emp.strLastName AS strEmployeeName,
		emp.iEmployeeId,
		(CASE WHEN ISNULL(cr.iEmployeeId, 0) = 0 THEN 0 ELSE 1 END) AS iReadStatus,
		cr.dtmConfirm,
		doc.iVirt,
		dbo.m136_fnGetVersionStatus(doc.iEntityId, doc.iDocumentId, doc.iVersion, doc.dtmPublish, doc.dtmPublishUntil, getDate(), doc.iDraft, doc.iApproved) iVersionStatus,
		doc.iDraft,
		doc.iApproved
	FROM
		@docTable doc
		FULL JOIN @empTable emp ON 1=1
		LEFT JOIN @cTable cr ON cr.iEmployeeId=emp.iEmployeeId AND cr.iEntityId=doc.iEntityId
		LEFT OUTER JOIN tblDepartment dep on dep.iDepartmentId=emp.iDepartmentId
		LEFT OUTER JOIN @bookTable book on doc.iHandbookId=book.iHandbookId
	WHERE
		ISNULL(doc.iEntityId, 0) > 0
	ORDER BY
		doc.iHandbookId ASC,
		doc.iSort ASC,
		doc.iDocumentId ASC,
		strDepName ASC,
		iReadStatus DESC,
		strEmployeeName ASC,
		dtmConfirm DESC
END
GO

IF OBJECT_ID('[dbo].[m136_be_ReportHandbookUpdatedOverview]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_ReportHandbookUpdatedOverview] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_ReportHandbookUpdatedOverview]
 @SecurityId AS INT,
 @DateFrom datetime = null,
 @DateTo dateTime = null
AS
BEGIN
 -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.
	 SET NOCOUNT ON;
	 DECLARE @EntityId INT
	 DECLARE @resultTable TABLE(iEntityId INT NOT NULL PRIMARY KEY, iDocId INT, iHandbookId INT, strName NVARCHAR(200), iLevelType INT, 
	 strDocName NVARCHAR(200), iVersion INT, DocumentType INT, strChanges NVARCHAR(MAX), strTargetGroup NVARCHAR(MAX))
	 
	 INSERT INTO @resultTable(iEntityId, iDocId, iHandbookId, strName, iLevelType ,strDocName, iVersion, DocumentType  ) 
	 SELECT  d.iEntityId, d.iDocumentId, d.iHandbookId ,  h.strName , h.iLevelType, d.strName, d.iVersion, t.Type
	 FROM m136_tblDocument d
	 INNER JOIN dbo.m136_tblHandbook h ON h.iHandbookId = d.iHandbookId
	 INNER JOIN m136_tblDocumentType t ON t.iDocumentTypeId = d.iDocumentTypeId
	 WHERE d.iLatestApproved = 1 and d.dtmPublish >= @DateFrom and 
		d.dtmPublish <= @DateTo  ;
	    
	 SELECT iMetaInfoTemplateRecordsId into #iMetaInfoTemplateRecordsIds 
	 FROM m136_tblMetaInfoTemplateRecords 
	 WHERE iMetaInfoTemplateRecordsId IN
		(SELECT iMetaInfoTemplateRecordsId 
		  FROM m136_relDocumentTypeInfo 
		  WHERE iDocumentTypeId IN (SELECT iDocumentTypeId FROM m136_tblDocument WHERE iEntityId in (SELECT r.iEntityId FROM @resultTable r)))
		 and strName like '%Målgruppe%'
	     
	 UPDATE r
	 SET r.strTargetGroup = m.value
	 FROM @resultTable r 
	 LEFT JOIN (SELECT Value,iEntityId 
					FROM m136_tblMetaInfoRichText 
					WHERE iMetaInfoTemplateRecordsId in (SELECT iMetaInfoTemplateRecordsId FROM #iMetaInfoTemplateRecordsIds)) as m
		ON m.iEntityId = r.iEntityId
	     
	 SELECT iMetaInfoTemplateRecordsId INTO #iMetaInfoTemplateRecordsIds2 
	 FROM m136_tblMetaInfoTemplateRecords 
	 WHERE iMetaInfoTemplateRecordsId IN 
		(SELECT iMetaInfoTemplateRecordsId 
			FROM m136_relDocumentTypeInfo 
			WHERE iDocumentTypeId in (SELECT iDocumentTypeId FROM m136_tblDocument WHERE iEntityId in (SELECT r.iEntityId FROM @resultTable r)))
		 and strName like '%Endringer fra%'
	 
	 UPDATE r
	 SET r.strChanges = m.value
	 FROM @resultTable r 
	 LEFT JOIN (SELECT Value,iEntityId 
					FROM m136_tblMetaInfoRichText 
					WHERE iMetaInfoTemplateRecordsId in (SELECT iMetaInfoTemplateRecordsId FROM #iMetaInfoTemplateRecordsIds2)) as m
		ON m.iEntityId = r.iEntityId
	 
	 SELECT DocumentType, strDocName AS Dokument, strName AS Mappe, iDocId AS DokId, iVersion AS Versjon, strChanges AS CustomField1, strTargetGroup AS CustomField2  
	 FROM @resultTable 
	 ORDER BY strName, iDocId
END
GO

IF OBJECT_ID('[dbo].[m136_be_ReportDocumentUpdatedOverview]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_ReportDocumentUpdatedOverview] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_ReportDocumentUpdatedOverview]
	@HandbookId AS INT,
	@SecurityId AS INT,
	@DateFrom DATETIME = null,
	@DateTo DATETIME = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result SETs from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @EntityId INT

	DECLARE @resultTable TABLE(iEntityId INT NOT NULL PRIMARY KEY, iDocId INT, iHandbookId INT, strName NVARCHAR(200), iLevelType INT, 
	strDocName NVARCHAR(200), iVersion INT, DocumentType INT, strChanges NVARCHAR(MAX), strTargetGroup NVARCHAR(MAX))
	
	DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
		
	INSERT INTO @AvailableChildren(iHandbookId)
	SELECT 
		iHandbookId 
	FROM 
		[dbo].[m136_GetHandbookRecursive](@HandbookId, @SecurityId, 1);
	
		
	INSERT INTO @resultTable(iEntityId, iDocId, iHandbookId , iVersion, strDocName  ) 
	SELECT  d.iEntityId, d.iDocumentId, d.iHandbookId ,  d.iVersion , d.strName 
			FROM m136_tblDocument d
				JOIN @AvailableChildren ac
					ON d.iHandbookId = ac.iHandbookId
				WHERE d.iApproved = 1 and d.dtmPublish >= @DateFrom and 
				d.dtmPublish <= @DateTo		

	DELETE
	FROM @resultTable
	WHERE iEntityId NOT IN ( SELECT MAX(iEntityId)
							  FROM @resultTable
							  GROUP BY iDocId)
							
	DECLARE curDocumentId CURSOR FOR
	SELECT iEntityId FROM @resultTable

	OPEN curDocumentId
	FETCH NEXT FROM curDocumentId INTO @EntityId
	WHILE @@FETCH_STATUS =0
	BEGIN		
		DECLARE @HandbookName NVARCHAR(200) 
		DECLARE @LevelType INT
		DECLARE @Changes NVARCHAR(MAX)
		DECLARE @TargetGroup NVARCHAR(MAX)
		DECLARE @DocumentType INT

		SELECT @HandbookName = (SELECT strName FROM m136_tblHandbook WHERE iHandbookId = (SELECT iHandbookId FROM m136_tblDocument WHERE iEntityId = @EntityId)) 
		SELECT @LevelType = (SELECT iLevelType FROM m136_tblHandbook WHERE iHandbookId = (SELECT iHandbookId FROM m136_tblDocument WHERE iEntityId = @EntityId)) 
		   
		SELECT @DocumentType = (SELECT m136_tblDocumentType.Type FROM m136_tblDocumentType WHERE iDocumentTypeId = (SELECT iDocumentTypeId FROM m136_tblDocument WHERE iEntityId = @EntityId))
		
		UPDATE @resultTable 
		SET strName = @HandbookName, iLevelType = @LevelType, DocumentType = @DocumentType
		WHERE iEntityId = @EntityId;
		
		DECLARE @MetaInfoTemplateRecordsId int
	
		SELECT @MetaInfoTemplateRecordsId = 
			(SELECT iMetaInfoTemplateRecordsId FROM m136_tblMetaInfoTemplateRecords WHERE iMetaInfoTemplateRecordsId in 
				(SELECT iMetaInfoTemplateRecordsId FROM m136_relDocumentTypeInfo WHERE iDocumentTypeId = (SELECT iDocumentTypeId FROM m136_tblDocument WHERE iEntityId = @EntityId))
			  and strName like '%Målgruppe%')

		IF @MetaInfoTemplateRecordsId > 0
		BEGIN
			SELECT @TargetGroup = (SELECT Value FROM m136_tblMetaInfoRichText WHERE iEntityId = @EntityId and iMetaInfoTemplateRecordsId = @MetaInfoTemplateRecordsId)		
			UPDATE @resultTable 
			SET strTargetGroup = @TargetGroup
			WHERE iEntityId = @EntityId;  
		END

		SELECT @MetaInfoTemplateRecordsId = 
			(SELECT iMetaInfoTemplateRecordsId FROM m136_tblMetaInfoTemplateRecords WHERE iMetaInfoTemplateRecordsId in 
				(SELECT iMetaInfoTemplateRecordsId FROM m136_relDocumentTypeInfo WHERE iDocumentTypeId = (SELECT iDocumentTypeId FROM m136_tblDocument WHERE iEntityId = @EntityId))
			  and strName like '%Endringer fra%')

		IF @MetaInfoTemplateRecordsId > 0
		BEGIN
			SELECT @Changes = (SELECT Value FROM m136_tblMetaInfoRichText WHERE iEntityId = @EntityId and iMetaInfoTemplateRecordsId = @MetaInfoTemplateRecordsId)		
			UPDATE @resultTable 
			SET strChanges = @Changes
			WHERE iEntityId = @EntityId;
		END	

	FETCH NEXT FROM curDocumentId INTO @EntityId
	END
		CLOSE curDocumentId
		DEALLOCATE curDocumentId
    
	SELECT DocumentType, strDocName AS Dokument, strName AS Mappe, iDocId AS DokId, iVersion AS Versjon, strChanges AS CustomField1, strTargetGroup AS CustomField2  
	FROM @resultTable 
	ORDER BY strName, iDocId

END
GO

IF OBJECT_ID('[dbo].[m136_be_ReportDocumentsPerFolder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_ReportDocumentsPerFolder] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_ReportDocumentsPerFolder]
@iParentHandbookId INT = 0,
@iSecurityId INT = 0
AS
BEGIN
	DECLARE @iHandbookId INT
	DECLARE @strName NVARCHAR(200)
	DECLARE @folderType INT
	DECLARE @iSort INT
	DECLARE @HandbookIdTable TABLE(iHandbookId INT)
	-- Do we have a specified root or do we assume we will list everything?
	IF ISNULL(@iParentHandbookId,0) = 0
		BEGIN
			INSERT INTO @HandbookIdTable
			SELECT iHandbookId FROM dbo.m136_tblHandbook WHERE iDeleted = 0 
		END
	ELSE
		BEGIN
			INSERT INTO @HandbookIdTable
			SELECT iHandbookId FROM dbo.m136_GetHandbookRecursive (@iParentHandbookId, @iSecurityId, 0)
		END 
	/* Declare some temporary tables */
	DECLARE @allApprovedDocuments TABLE(iEntityId INT, iHandbookId INT, iDocumentId INT, strName nvarchar(200), iVersion INT)
	/* Find all approved documents and latest version */
	INSERT INTO @allApprovedDocuments
	SELECT doc.iEntityId, doc.iHandbookId, doc.iDocumentId, doc.strName, doc.iVersion 
	FROM m136_tblDocument doc 
	WHERE doc.iLatestApproved = 1
		  AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, doc.iHandbookId) & 0x15) > 0
		  AND doc.iHandbookId IN (SELECT iHandbookId FROM @HandbookIdTable)
		  AND doc.iDeleted = 0
	ORDER BY doc.iDocumentId 
		/* Create temporary table to hold the end result */
	DECLARE @resultTable TABLE(iHandbookId INT, strName NVARCHAR(200), iLevel INT, TotalDocuments INT, Priority INT, Folders INT, folderType INT, iParentHandbookId INT, iSort INT)
	/* Populate result table with most data including number of valid and invalid documents */
	INSERT INTO @resultTable(iHandbookId, strName, iLevel, TotalDocuments, Priority, Folders, folderType, iParentHandbookId, iSort)
	SELECT s.iHandbookId, h.strName, h.iLevel, COUNT(s.iDocumentId), 0, 0, h.iLevelType, h.iParentHandbookId, h.iSort 
	FROM @allApprovedDocuments s join
	m136_tblHandbook h ON s.iHandbookId = h.iHandbookId 
	WHERE (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, s.iHandbookId) & 0x15) > 0
	GROUP BY s.iHandbookId, h.strName, h.iLevel, h.iLevelType, h.iParentHandbookId, h.iSort
	/* Populate table with all handbooks missing from the result set based on documents */
	INSERT INTO @resultTable (iHandbookId, strName, iLevel, TotalDocuments, Priority, Folders, folderType, iParentHandbookId, iSort)
	SELECT iHandbookId, strName, iLevel, 0, 0, 0, iLevelType, iParentHandbookId, iSort
	FROM m136_tblHandbook 
	WHERE (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 0x15) > 0 
		  AND iHandbookId NOT IN (SELECT iHandbookId FROM @resultTable)
	      AND iHandbookId IN (SELECT iHandbookId FROM @HandbookIdTable)
	/* Set priority - This is only a helper column for reports. We will insert an extra row for all items with 
	level one. This extra row will have priority 1 and the original row will get priority 2
	The row with priority 1 will contain a summary of all folders, valid documents, invalid documents etc recursively */
	UPDATE @resultTable SET Priority = CASE iLevel WHEN 1 THEN 2 ELSE iLevel END
	/* Helper table since we will add more rows to the @resultTable, this helper table is to avoid 
	problems with a cursor on the table we will be modifying */
	DECLARE @tmpResultTable TABLE(iHandbookId INT, strName NVARCHAR(200), folderType INT, iSort INT)
	/* Populate temp table with all handbooks */
	INSERT INTO @tmpResultTable(iHandbookId, strName, iSort) 
	SELECT iHandbookId, strName, iSort FROM @resultTable
	/* Update resultable with countings of folders */
	DECLARE cur CURSOR FOR
		SELECT iHandbookId FROM @tmpResultTable
	OPEN cur 
	FETCH NEXT FROM cur INTO @iHandbookId
	WHILE @@fetch_status=0
	BEGIN
		UPDATE @resultTable SET Folders = (SELECT COUNT(*) FROM m136_tblHandbook 
											WHERE iParentHandbookId = @iHandbookId AND iDeleted = 0 AND
											(dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 0x15) > 0)
		WHERE iHandbookId = @iHandbookId AND Priority > 1
	FETCH NEXT FROM cur INTO @iHandbookId
	END
	CLOSE cur 
	DEALLOCATE cur
	/* Remove all entries in this helper table and repopulate it with handbooks for level 1 only */
	DELETE FROM @tmpResultTable
	INSERT INTO @tmpResultTable(iHandbookId, strName, folderType, iSort) 
	SELECT iHandbookId, strName, folderType, iSort FROM @resultTable WHERE iParentHandbookId IS NULL
	IF NOT EXISTS(SELECT 1 FROM @tmpResultTable)
	BEGIN
		INSERT INTO @tmpResultTable(iHandbookId, strName, folderType, iSort) 
		SELECT iHandbookId, strName, folderType, iSort FROM @resultTable WHERE Priority = (SELECT MIN(Priority) FROM @resultTable)
	END
	-- Create summary columns - Update Priorty 1 records with recursive numbers
	DECLARE cur CURSOR FOR
		SELECT iHandbookId, strName, folderType, iSort FROM @tmpResultTable
	OPEN cur
	FETCH NEXT FROM cur INTO @iHandbookId, @strName, @folderType, @iSort
	WHILE @@fetch_status=0
	BEGIN
		INSERT INTO @resultTable(iHandbookId, strName, iLevel,TotalDocuments, Priority, folderType, iSort)
			VALUES(@iHandbookId, @strName, 1, 0, 1, @folderType, @iSort);
		WITH Children AS
		(
				SELECT 
					iHandbookId 
				FROM 
					@resultTable 
				WHERE
					iHandbookId = @iHandbookId 
			UNION ALL
				SELECT 
					h.iHandbookId 
				FROM 
					@resultTable h
					INNER JOIN Children 
						ON	iParentHandbookId = Children.iHandbookId 
		)
		SELECT 
			iHandbookId 
		INTO #Folders
		FROM 
			Children
		UPDATE @resultTable SET
			TotalDocuments = (SELECT SUM(TotalDocuments) FROM @resultTable WHERE iHandbookId in (select iHandbookId FROM #Folders)),
			Folders = (SELECT COUNT(*) FROM dbo.m136_tblHandbook 
						WHERE iHandbookId IN (select iHandbookId FROM #Folders)
					   ) - 1
		WHERE iHandbookId = @iHandbookId and Priority = 1
		DROP TABLE #Folders;
	FETCH NEXT FROM cur INTO @iHandbookId, @strName, @folderType , @iSort
	END
	CLOSE cur
	DEALLOCATE cur
	-- Return the result
	SELECT * FROM @resultTable ORDER BY iSort, strName
END
GO

IF OBJECT_ID('[dbo].[m136_spReportDocumentsPerFolderPerStatus]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_spReportDocumentsPerFolderPerStatus] AS SELECT 1')
GO

ALTER procedure [dbo].[m136_spReportDocumentsPerFolderPerStatus]
@iParentHandbookId int = 0,
@iSecurityId int = 0
as
begin
/* 
	This stored procedure creates a result set which returns the count of documents with various status.
	Important to note: Rows with iLevel = 1 contains the accumelated sum of documents recursivly for all sub folders beneath this folder 
	And extra row is added to the result set for all iLevel = 1 rows. This row is manipulated so I get iPriority = 2 in the result set.
	All other rows gets iPriority = iLevel. This is so you can separate the two rows, i.e that is the accumulated row from the regular row 
	of the rot level item. In addition the result set will be sorted on iMin, iPriority.
	So the result set will equal the menu listing of the items.
	
*/

DECLARE @iHandbookId INT
DECLARE @strName NVARCHAR(200)
DECLARE @folderType INT
DECLARE @iSort INT
DECLARE @HandbookIdTable TABLE(iHandbookId INT)

-- Do we have a specified root or do we assume we will list everything?
if ISNULL(@iParentHandbookId,0) = 0
begin
	INSERT INTO @HandbookIdTable
	SELECT iHandbookId FROM dbo.m136_tblHandbook WHERE iDeleted = 0 
end
else
begin
	INSERT INTO @HandbookIdTable
	SELECT iHandbookId FROM dbo.m136_GetHandbookRecursive (@iParentHandbookId, @iSecurityId, 0)
end 

/* Declare some temporary tables */
declare @allDocumentsWithStatus table(iEntityId int, iHandbookId int, iDocumentId int, strName nvarchar(200), iVersion int, iApproved int, iDraft int, iStatus int)
declare @allApprovedDocuments table(iDocumentId int, iVersion int)

/* Find all approved documents and latest version */
insert into @allApprovedDocuments(iDocumentId, iVersion)
select doc.iDocumentId, doc.iVersion from m136_tblDocument doc 
join (
select iDocumentId, max(iVersion) as iVersion from m136_tblDocument where iApproved in (1,4) and iHandbookId in (SELECT iHandbookId FROM @HandbookIdTable)
and (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 0x15) > 0
	group by iDocumentId
) result
on (doc.iDocumentId = result.iDocumentId and doc.iVersion = result.iVersion)
where doc.iApproved = 1
order by doc.iDocumentId 


/* Populate temporary table with status for each document */
insert into @allDocumentsWithStatus(iEntityId, iHandbookId, iDocumentId, strName, iVersion, iApproved, iDraft, iStatus)
select d.iEntityId, d.iHandbookId, d.iDocumentId, d.strName, d.iVersion, d.iApproved, d.iDraft, dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus  
from m136_tblDocument d join @allApprovedDocuments t on (t.iDocumentId = d.iDocumentId and t.iVersion = d.iVersion)
where d.iDeleted = 0 and d.iHandbookId in (SELECT iHandbookId FROM @HandbookIdTable)
and (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) & 0x15) > 0

/* Create temporary table to hold the end result */
declare @resultTable table(iHandbookId int, strName nvarchar(200), iLevel int, ValidDocuments int, InvalidDocuments int, InvalidDocumentsUnderRevision int, TotalDocuments int, Priority int, Folders int, folderType INT, iParentHandbookId INT, iSort INT)

/* Populate result table with most data including number of valid and invalid documents */
insert into @resultTable(iHandbookId, strName, iLevel, TotalDocuments, Priority, Folders, ValidDocuments, InvalidDocuments, InvalidDocumentsUnderRevision, folderType,iParentHandbookId, iSort )
select s.iHandbookId, h.strName, h.iLevel, 0, 0, 0, sum(dbo.m136_fnIsDocumentValid(s.iStatus))  as ValidDocuments, 
sum(dbo.m136_fnIsDocumentInvalid(s.iStatus, s.iDraft, s.iApproved, s.iDocumentId, s.iVersion)) as InvalidDocuments,
sum(dbo.m136_fnIsDocumentInvalidAndUnderRevision(s.iStatus, s.iDraft, s.iApproved, s.iDocumentId, s.iVersion)) as InvalidDocumentsUnderRevision,
h.iLevelType, h.iParentHandbookId, h.iSort
from @allDocumentsWithStatus s join
m136_tblHandbook h on s.iHandbookId = h.iHandbookId 
where (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, s.iHandbookId) & 0x15) > 0
group by s.iHandbookId, h.strName, h.iLevel,  h.iLevelType, h.iParentHandbookId, h.iSort

/* Populate table with all handbooks missing from the result set based on documents */
insert into @resultTable (iHandbookId, strName, iLevel, TotalDocuments, Priority, ValidDocuments, InvalidDocuments, InvalidDocumentsUnderRevision, Folders, folderType,iParentHandbookId, iSort )
	select iHandbookId, strName, iLevel, 0, 0, 0, 0, 0,
	0, iLevelType, iParentHandbookId, iSort
	from m136_tblHandbook where
		(dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 0x15) > 0 and iHandbookId not in (select iHandbookId from @resultTable)
	and iHandbookId in (SELECT iHandbookId FROM @HandbookIdTable)
		and (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 0x15) > 0

/* Set priority - This is only a helper column for reports. We will insert an extra row for all items with 
level one. This extra row will have priority 1 and the original row will get priority 2
The row with priority 1 will contain a summary of all folders, valid documents, invalid documents etc recursively */
update @resultTable set Priority = case iLevel when 1 then 2 else iLevel end

/* Helper table since we will add more rows to the @resultTable, this helper table is to avoid 
problems with a cursor on the table we will be modifying */
declare @tmpResultTable table(iHandbookId int, strName nvarchar(200), folderType INT, iSort INT)

/* Populate temp table with all handbooks */
insert into @tmpResultTable(iHandbookId, strName,iSort) 
	select iHandbookId, strName, iSort from @resultTable

/* Update resultable with countings of folders */
declare cur cursor for
	select iHandbookId from @tmpResultTable
open cur 
fetch next from cur into @iHandbookId
while @@fetch_status=0
begin
	update @resultTable set Folders = (select count(*) from m136_tblHandbook where iParentHandbookId = @iHandbookId and iDeleted = 0 and
			(dbo.fnSecurityGetPermission(136, 462, @iSecurityId, @iHandbookId) & 0x15) > 0) where iHandbookId = @iHandbookId 
		and Priority > 1
fetch next from cur into @iHandbookId
end
close cur 
deallocate cur

/* Remove all entries in this helper table and repopulate it with handbooks for level 1 only */
delete from @tmpResultTable
insert into @tmpResultTable(iHandbookId, strName, folderType, iSort) 
	select iHandbookId, strName, folderType, iSort from @resultTable where iParentHandbookId IS NULL
IF NOT EXISTS(SELECT 1 FROM @tmpResultTable)
BEGIN
	INSERT INTO @tmpResultTable(iHandbookId, strName, folderType, iSort) 
	SELECT iHandbookId, strName, folderType, iSort FROM @resultTable WHERE Priority = (SELECT MIN(Priority) FROM @resultTable)
END

-- Create summary columns - Update Priorty 1 records with recursive numbers
declare cur cursor for
	select iHandbookId, strName, folderType, iSort from @tmpResultTable
open cur
fetch next from cur into @iHandbookId, @strName, @folderType, @iSort
while @@fetch_status=0
begin
	insert into @resultTable(iHandbookId, strName, iLevel, ValidDocuments, InvalidDocuments, InvalidDocumentsUnderRevision, TotalDocuments, Priority, folderType, iSort)
		values(@iHandbookId, @strName, 1, 0, 0, 0, 0, 1, @folderType, @iSort);
	WITH Children AS
		(
				SELECT 
					iHandbookId 
				FROM 
					@resultTable 
				WHERE
					iHandbookId = @iHandbookId 
			UNION ALL
				SELECT 
					h.iHandbookId 
				FROM 
					@resultTable h
					INNER JOIN Children 
						ON	iParentHandbookId = Children.iHandbookId 
		)
		SELECT 
			iHandbookId 
		INTO #Folders
		FROM 
			Children
			
	update @resultTable set 
		ValidDocuments = (select sum(ValidDocuments) from @resultTable where iHandbookId in (select iHandbookId FROM #Folders)),
		InvalidDocuments = (select sum(InvalidDocuments) from @resultTable where iHandbookId in (select iHandbookId FROM #Folders)),
		InvalidDocumentsUnderRevision = (select sum(InvalidDocumentsUnderRevision) from @resultTable where iHandbookId in (select iHandbookId FROM #Folders)),
		Folders = (select count(*) from m136_tblHandbook where iDeleted = 0 and iHandbookId in (select iHandbookId FROM #Folders) and (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 0x15) > 0)
		where iHandbookId = @iHandbookId and Priority = 1
DROP TABLE #Folders;
fetch next from cur into @iHandbookId, @strName, @folderType, @iSort
end
close cur
deallocate cur

-- Update the total column with final values
update @resultTable set TotalDocuments = ValidDocuments + InvalidDocuments + InvalidDocumentsUnderRevision

-- Return the result
select * from @resultTable order by iSort, strName
end
GO