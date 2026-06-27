CREATE OR ALTER TRIGGER trg_AfterLibraryReturn
ON LibraryIssues
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- Update inventory count when status transitions to 'Returned'
    UPDATE LibraryItems
    SET CopiesAvailable = CopiesAvailable + 1
    WHERE ItemID IN (
        SELECT i.ItemID
        FROM inserted i
        JOIN deleted d ON i.IssueID = d.IssueID
        WHERE i.Status = 'Returned' AND d.Status = 'Issued'
    );
END;
GO