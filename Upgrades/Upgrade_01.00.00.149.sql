INSERT INTO #Description VALUES('Modified stored procedure [dbo].[m136_be_ArchiveDocument]')
GO

IF OBJECT_ID('[dbo].[m136_be_ArchiveDocument]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_ArchiveDocument] AS SELECT 1')
GO
-- =============================================
-- Author:		SI.NGUYEN.MANH
-- Create date: NOV 16, 2015
-- Description:	Update Archive document
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_ArchiveDocument] 
	@DocumentIds AS [dbo].[Item] READONLY,
	@UserId INT,
	@Description varchar(2000)
AS
BEGIN
	IF @Description IS NOT NULL
		BEGIN	      
			UPDATE dbo.m136_tblDocument
			SET iApproved = 4,
				iApprovedById = @UserId,
				dtmApproved = getdate(),
				strApprovedBy = dbo.fnOrgGetUserName(@UserId, '', 0),
				strDescription = @Description + ' ' + strDescription,
				iDraft = 0
			WHERE iEntityId IN(
					SELECT iEntityId 
					FROM @DocumentIds AS doc
					JOIN	m136_tblDocument d ON d.iDocumentId = doc.Id AND d.iLatestVersion = 1
				  )
		END
	ELSE
		BEGIN
			UPDATE dbo.m136_tblDocument
			SET iApproved = 4,
				iApprovedById = @UserId,
				dtmApproved = getdate(),
				strApprovedBy = dbo.fnOrgGetUserName(@UserId, '', 0),
				iDraft = 0
			WHERE iEntityId IN(
					SELECT iEntityId 
					FROM @DocumentIds AS doc
					JOIN	m136_tblDocument d ON d.iDocumentId = doc.Id AND d.iLatestVersion = 1
				  )
		END
	DECLARE @iDocumentId INT
	DECLARE curDocumentId CURSOR FOR 
		SELECT Id
		FROM @DocumentIds;
	OPEN curDocumentId; 
	FETCH NEXT FROM curDocumentId INTO @iDocumentId;
	WHILE @@FETCH_STATUS = 0
    BEGIN
		EXEC dbo.m136_SetVersionFlags @iDocumentId
		FETCH NEXT FROM curDocumentId INTO @iDocumentId;
	END
	CLOSE curDocumentId;
	DEALLOCATE curDocumentId;
END
GO