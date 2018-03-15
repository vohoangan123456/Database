INSERT INTO #Description VALUES('Revert function [dbo].[fnSecurityGetPermission], remove procedure m136_be_UserCanPublishInternetDocument')
GO

ALTER FUNCTION [dbo].[fnSecurityGetPermission]
(
    @iApplicationId int, 
    @iPermissionSetId int, 
    @iSecurityId int,
    @iEntityId int
)    
RETURNS int AS    
BEGIN   
  
    DECLARE @var INT;
    SELECT @var = 0;
    
    SELECT
        @var = @var | iBit
    FROM
        tblAcl a
            join relEmployeeSecGroup r on a.iSecurityId = r.iSecGroupId
            and r.iEmployeeId = @iSecurityId
    WHERE
        a.iApplicationId = @iApplicationId
        and a.iPermissionSetId = @iPermissionSetId
        and a.iEntityId = @iEntityId
  
    RETURN @var
END  
GO

IF OBJECT_ID('[dbo].[m136_be_UserCanPublishInternetDocument]', 'p') IS NOT NULL
	EXEC ('DROP PROCEDURE [dbo].[m136_be_UserCanPublishInternetDocument]')
GO

IF OBJECT_ID('[dbo].[m136_be_ChangeInternetDocument]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_ChangeInternetDocument]  AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_ChangeInternetDocument]
    @UserId INT,
    @DocumentIds AS [dbo].[Item] READONLY,
    @IsInternetDocument BIT
AS
BEGIN
    DECLARE @FullName NVARCHAR(100);

    SELECT
        @FullName = strFirstName + ' ' + strLastName
    FROM
        tblEmployee
    WHERE
        iEmployeeId = @UserId
    
    UPDATE
        m136_tblDocument
    SET
        iInternetDoc = @IsInternetDocument,
        iAlterId = @UserId,
		strAlterer = @FullName
    WHERE
        iDocumentId IN (SELECT Id FROM @DocumentIds)
        AND iLatestVersion = 1
        AND iInternetDoc <> @IsInternetDocument
END
GO