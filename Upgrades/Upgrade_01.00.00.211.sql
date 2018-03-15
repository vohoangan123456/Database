INSERT INTO #Description VALUES('Set default permissions for root folder')
GO

DELETE FROM tblAcl
WHERE
    iEntityId = 0
    AND iApplicationId = 136
    AND iSecurityId = 1
    AND iPermissionSetId IN (461, 462)
    
INSERT INTO
    tblAcl
        (iEntityId, iApplicationId, iSecurityId, iPermissionSetId, iGroupingId, iBit)
    VALUES
        (0, 136, 1, 461, 0, 31),
        (0, 136, 1, 462, 0, 47)