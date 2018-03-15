INSERT INTO #Description VALUES ('Send document to approval should reset iApproved. Replace JOIN m136_relSentEmpApproval ap on d.iEntityId = ap.iEntityId by LEFT JOIN m136_vSentForApproval ap on d.iEntityId = ap.iEntityId')
GO

IF OBJECT_ID('[dbo].[m136_be_SendDocumentToApproval]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_SendDocumentToApproval] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_SendDocumentToApproval]
    @ApproverId INT,
	@EntityId INT,
	@TransferReadingReceipts BIT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            DECLARE @DocumentId INT;
            SELECT
                @DocumentId = iDocumentId
            FROM
                m136_tblDocument
            WHERE
                iEntityId = @EntityId
            UPDATE
                m136_tblDocument
            SET
                iDraft = 0, 
                iApproved = 0
            WHERE
                iEntityId = @EntityId;
                
            INSERT INTO
                m136_relSentEmpApproval
                    (iEmployeeId, iEntityId, dtmSentToApproval)
                VALUES
                    (@ApproverId, @EntityId, GETDATE())
            DELETE FROM
                m136_tblCopyConfirms
            WHERE
                iEntityId = @EntityId;
                
            IF @TransferReadingReceipts = 1
            BEGIN
                INSERT INTO
                    m136_tblCopyConfirms
                        (iEntityId)
                    VALUES
                        (@EntityId)
            END
            EXEC m136_SetVersionFlags @DocumentId;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
			ROLLBACK
		DECLARE @ErrorMessage nvarchar(MAX), @ErrorNumber int, @ErrorSeverity int, @ErrorState int, @ErrorLine int
		SELECT @ErrorMessage = N'Error %d, Line %d, Message: '+ERROR_MESSAGE(),@ErrorNumber = ERROR_NUMBER(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(),@ErrorLine = ERROR_LINE();
		RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber,@ErrorLine);
    END CATCH
END
GO


IF OBJECT_ID('[dbo].[m136_be_GetMyDocumentsSentToApproval]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetMyDocumentsSentToApproval] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetMyDocumentsSentToApproval] 
	@iSecurityId int = 0,
	@PageSize int = 10,
	@PageIndex int = 0
AS
BEGIN
	SET NOCOUNT ON;
	SELECT  d.iDocumentId, 
			d.iEntityId,
			d.strName,
			d.iDocumentTypeId,
			d.iVersion,
			h.iLevelType AS LevelType,
			d.dtmApproved,
			dbo.fnOrgGetUserName(ap.iEmployeeId, '', 0) AS strApprovedBy,
			d.iCreatedById,
			h.iDepartmentId,
			d.iSort,
            h.iHandbookId,
			h.strName AS ParentFolderName,
			d.iApproved,
			d.iDraft,
            d.iInternetDoc,
			row_number() OVER (ORDER BY d.dtmCreated DESC) AS rownumber,
			d.dtmPublish,
			d.dtmPublishUntil,
			dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) as iAccess,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, GETDATE(), d.iDraft, d.iApproved) iVersionStatus,
			d.iDeleted,
			dbo.fn136_GetParentPathEx(d.iHandbookId) as [Path],
			d.dtmCreated,
			d.dtmAlter,
			d.iReadCount
		INTO #Filters
		FROM m136_tblDocument d
			JOIN m136_tblHandbook h on d.iHandbookId = h.iHandbookId
            LEFT JOIN m136_vSentForApproval ap on d.iEntityId = ap.iEntityId
		WHERE d.iDeleted = 0
			AND d.iLatestVersion = 1 
			AND d.iDraft = 0
			AND d.iApproved = 0
			AND (d.iCreatedById = @iSecurityId OR d.iAlterId = @iSecurityId);  
	SELECT  d.iDocumentId AS Id,
			d.strName,
			d.iDocumentTypeId,
			d.iVersion AS [Version],
			d.LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) AS Responsible,
			d.iDepartmentId AS DepartmentId,
			0 AS Virtual,
			d.iSort,
            d.iHandbookId,
			d.ParentFolderName,
			d.[Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) AS HasAttachment,
			d.iApproved,
			d.iDraft,
            d.iInternetDoc,
			d.dtmPublish,
			d.dtmPublishUntil,
			d.iAccess,
			d.iCreatedbyId,
			d.iVersionStatus,
			d.iDeleted,
			d.dtmCreated,
			d.dtmAlter,
			d.iReadCount AS ReadCount
		FROM #Filters d 
		WHERE (@PageSize = 0 OR rownumber BETWEEN @PageSize * @PageIndex + 1 AND @PageSize * (@PageIndex + 1)) ORDER BY rownumber;
	SELECT COUNT(*) FROM #Filters;
	DROP TABLE #Filters;                                 
END
GO


IF OBJECT_ID('[dbo].[m136_GetMenuGroups]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetMenuGroups] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetMenuGroups] 
    @UserId INT,
    @MenuId INT
AS
BEGIN
	DECLARE @CurrentDate DATETIME = GETDATE();
    DECLARE @UserDepartmentId TABLE (Id INT);
    
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        tblEmployee
    WHERE
        iEmployeeId = @UserId
        
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        relEmployeeDepartment
    WHERE iEmployeeId = @UserId
    
	SELECT iItemId INTO #Groups FROM tblMenu WHERE iItemParentId = @MenuId;
    
    WITH Children AS
	(
			SELECT 
				m.iItemId, 
				m.iItemParentId, 
				m.strName, 
				m.strDescription,
				m.iLevel, 
				m.strURL, 
				m.dtmDisplay,
				m.dtmRemove,
				m.bNewWindow,
                m.bExpanded,
				m.iSort
			FROM 
				[dbo].[tblMenu] m
			WHERE
				iItemId IN (SELECT g.iItemId FROM #Groups g)
                AND
                (
                    dbo.fnSecurityGetPermission(99, 99, @UserId, iItemId) & 1 = 1
                    OR EXISTS (
                        SELECT 1 
                        FROM tblAcl 
                        WHERE 
                            iEntityId = m.iItemId
                            AND iApplicationId = 99 
                            AND iPermissionSetId = 100 
                            AND iSecurityId IN (SELECT Id FROM @UserDepartmentId) 
                            AND iBit & 1 = 1
                    )
                )
		UNION ALL
			SELECT 
				m.iItemId, 
				m.iItemParentId, 
				m.strName, 
				m.strDescription,
				m.iLevel, 
				m.strURL, 
				m.dtmDisplay,
				m.dtmRemove,
				m.bNewWindow,
                m.bExpanded,
				m.iSort
			FROM 
				[dbo].[tblMenu] m
                    INNER JOIN Children 
                        ON	m.iItemParentId = Children.iItemId 
            WHERE
                dbo.fnSecurityGetPermission(99, 99, @UserId, m.iItemId) & 1 = 1
                OR EXISTS (
                        SELECT 1 
                        FROM tblAcl 
                        WHERE 
                            iEntityId = m.iItemId
                            AND iApplicationId = 99 
                            AND iPermissionSetId = 100 
                            AND iSecurityId IN (SELECT Id FROM @UserDepartmentId) 
                            AND iBit & 1 = 1
                    )
	)
	SELECT 
		iItemId, iItemParentId, strName, strDescription, iLevel, strURL, dtmDisplay, dtmRemove, bNewWindow, bExpanded, iSort
	FROM 
		Children
	WHERE @CurrentDate BETWEEN dtmDisplay AND dtmRemove 
			OR (dtmRemove IS NULL AND dtmDisplay IS NULL)
			OR (@CurrentDate> dtmDisplay AND dtmRemove IS NULL)
			OR (dtmDisplay IS NULL AND @CurrentDate < dtmRemove)
	ORDER BY iSort, strName;
	DROP TABLE #Groups;
END
GO