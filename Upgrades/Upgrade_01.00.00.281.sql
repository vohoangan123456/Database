INSERT INTO #Description VALUES ('Add column iRecepitsCopied to table m136_tblDocument, modify procedures m136_be_ApproveDocument, m136_GetRecentlyApprovedDocuments, m136_GetLatestApprovedSubscriptions')
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.m136_tblDocument') AND name = 'iReceiptsCopied')
BEGIN
    ALTER TABLE dbo.m136_tblDocument
	ADD iReceiptsCopied BIT NOT NULL DEFAULT(0)
END
GO

IF OBJECT_ID('[dbo].[m136_be_ApproveDocument]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_ApproveDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_ApproveDocument]
    @UserId INT,
    @EntityId INT,
    @TransferReadingReceipts BIT,
    @PublishFrom DATETIME,
    @PublishUntil DATETIME,
    @IsInternetDocument BIT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            DECLARE @DocumentId INT;
            DECLARE @FullName NVARCHAR(100);
            
            SELECT
                @DocumentId = iDocumentId
            FROM
                m136_tblDocument
            WHERE
                iEntityId = @EntityId
            
            SELECT
                @FullName = strFirstName + ' ' + strLastName
            FROM
                tblEmployee
            WHERE
                iEmployeeId = @UserId
            
            IF @TransferReadingReceipts = 1
            BEGIN
                EXEC m136_doCopyConfirms @DocumentId
            END
            ELSE
            BEGIN
                EXEC m136_SetCopyConfirms @DocumentId, 0
            END

            UPDATE
                m136_tblDocument
            SET
                iApproved = 1,
                iApprovedById = @UserId,
                dtmApproved = GETDATE(),
                strApprovedBy = @FullName,
                dtmPublish = @PublishFrom,
                dtmPublishUntil = @PublishUntil,
                iInternetDoc = @isInternetDocument,
                iReceiptsCopied = @TransferReadingReceipts
            WHERE
                iDocumentId = @DocumentId
                AND iLatestVersion = 1
            
            EXEC m136_insertEntityIntoTextIndex @EntityId
                
            EXEC dbo.m136_SetVersionFlags @DocumentId
            
            INSERT INTO dbo.CacheUpdate (ActionType, EntityId) VALUES (11, @DocumentId);
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK
    END CATCH
END
GO

IF OBJECT_ID('[dbo].[m136_GetRecentlyApprovedDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetRecentlyApprovedDocuments]  AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetRecentlyApprovedDocuments] 
	@iDaysLimit int,
	@maxCount int
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @Now DATETIME = GETDATE();
	SELECT TOP (@maxCount)
		d.iDocumentId as Id,
		d.iHandbookId,
		d.strName,
		d.iDocumentTypeId,
		d.iVersion as [Version],
		d.dtmApproved,
		d.strApprovedBy,
		dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
		h.strName as ParentFolderName,
		dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
		[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
		h.iLevelType AS LevelType,
		h.iDepartmentId As DepartmentId
	FROM
		m136_tblDocument d
        INNER JOIN m136_tblHandbook h 
			ON d.iHandbookId = h.iHandbookId
   	WHERE 
        d.iLatestApproved = 1
        AND d.iReceiptsCopied = 0
        AND DATEDIFF(d, ISNULL(d.dtmApproved, CONVERT(DATETIME, '01.01.1970', 104)), @Now) <  @iDaysLimit
	ORDER BY
		d.dtmApproved DESC
END
GO

IF OBJECT_ID('[dbo].[m136_GetLatestApprovedSubscriptions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetLatestApprovedSubscriptions]  AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetLatestApprovedSubscriptions]
	@iSecurityId INT = 0,
	@iApprovedDocumentCount INT = 0,
	@TreatDepartmentFoldersAsFavorites INT = 0
AS
SET NOCOUNT ON
BEGIN
	DECLARE @iUserDepId INT;
	SELECT @iUserDepId = iDepartmentId FROM tblEmployee WHERE iEmployeeId = @iSecurityId;
	DECLARE @PreviousLogin Datetime;
	SELECT @PreviousLogin = PreviousLogin FROM tblEmployee WHERE iEmployeeId = @iSecurityId;
	-- get list of handbookId which is favorite and have read access
	DECLARE @FavoriteHandbooksWithReadContents TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	INSERT INTO @FavoriteHandbooksWithReadContents(iHandbookId)
	SELECT 
		iHandbookId 
	FROM 
		[dbo].[m136_fnGetAllFavoritesFoldersWithContentsAccessRecursively](@iSecurityId, @TreatDepartmentFoldersAsFavorites, @iUserDepId);
	-- get list of favorite document
	WITH Documents AS
	(
		SELECT
			iDocumentId
		FROM
			m136_relVirtualRelation
		WHERE iHandbookId IN (SELECT DISTINCT iHandbookId 
							  FROM @FavoriteHandbooksWithReadContents)
		UNION
		SELECT
			iDocumentId
		FROM
			m136_tblSubscriberDocument
		WHERE 
			iEmployeeId = @iSecurityId
	)
	SELECT DISTINCT 
		TOP(@iApprovedDocumentCount) 
		d.iDocumentId AS Id, 
		d.iEntityId, 
		d.strName, 
        dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) AS iAccess, 
		d.iHandbookId, 
        d.dtmApproved, 
		h.strName AS ParentFolderName, 
		d.iVersion AS [Version], 
        d.iDocumentTypeId,
		dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
        (e.strLastName + ' ' + e.strFirstName) AS strApprovedBy, 
        dbo.fnOrgGetUserName(d.iCreatedById, '', 0) AS Responsible, 
		[dbo].[fnHasDocumentAttachment](d.iEntityId) AS HasAttachment,
		h.iLevelType AS LevelType,
		h.iDepartmentId AS DepartmentId,
        CASE WHEN 
			d.dtmApproved > @PreviousLogin THEN 1
		ELSE 0
		END AS IsNew
	FROM  
		m136_tblDocument d
		JOIN m136_tblHandbook h ON d.iHandbookId = h.iHandbookId
		LEFT JOIN tblEmployee e ON e.iEmployeeId = d.iApprovedById
	WHERE 
		d.iLatestApproved = 1
        AND d.iReceiptsCopied = 0
		AND (		(d.iHandbookId IN (SELECT iHandbookId FROM @FavoriteHandbooksWithReadContents))
				OR	d.iDocumentId IN (SELECT iDocumentId FROM Documents))
	ORDER BY d.dtmApproved DESC
END
GO