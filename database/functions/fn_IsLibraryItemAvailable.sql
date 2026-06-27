CREATE OR ALTER FUNCTION fn_IsLibraryItemAvailable
    (@ItemID INT)
    RETURNS BIT
AS
BEGIN
    DECLARE @Available BIT = 0;
    DECLARE @Copies INT = 0;
    SELECT @Copies = CopiesAvailable 
    FROM LibraryItems 
    WHERE ItemID = @ItemID;
    IF @Copies > 0
    BEGIN
        SET @Available = 1;
    END;
    RETURN @Available;
END;
GO