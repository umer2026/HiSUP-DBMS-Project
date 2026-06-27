CREATE OR ALTER PROCEDURE IssueLibraryBook
    @StudentID INT,
    @ItemID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        -- Check Student
        IF NOT EXISTS (SELECT 1 FROM Students WHERE StudentID = @StudentID)
        BEGIN
            THROW 50017, 'Student does not exist.', 16;
        END;
        -- Check Library Item exists
        IF NOT EXISTS (SELECT 1 FROM LibraryItems WHERE ItemID = @ItemID)
        BEGIN
            THROW 50018, 'Library item does not exist.', 16;
        END;
        -- Check availability using UDF (fn_IsLibraryItemAvailable)
        -- We will declare the UDF later, but we call it here.
        -- In SQL Server, scalar UDF must be called with schema name: dbo.fn_IsLibraryItemAvailable
        IF dbo.fn_IsLibraryItemAvailable(@ItemID) = 0
        BEGIN
            THROW 50019, 'Library item is currently not available (all copies issued).', 16;
        END;
        -- Check if student has outstanding issues that are overdue
        IF EXISTS (
            SELECT 1 FROM LibraryIssues 
            WHERE StudentID = @StudentID AND Status = 'Issued' AND DueDate < GETDATE()
        )
        BEGIN
            THROW 50020, 'Student cannot borrow books while they have overdue items.', 16;
        END;
        -- Issue the book
        INSERT INTO LibraryIssues (StudentID, ItemID, IssueDate, DueDate, ReturnDate, FinePaid, Status)
        VALUES (@StudentID, @ItemID, GETDATE(), DATEADD(day, 14, GETDATE()), NULL, 0.00, 'Issued');
        -- Decrement copies available
        UPDATE LibraryItems
        SET CopiesAvailable = CopiesAvailable - 1
        WHERE ItemID = @ItemID;
        COMMIT TRANSACTION;
        PRINT 'Library book issued successfully. Due date: ' + CONVERT(VARCHAR(10), DATEADD(day, 14, GETDATE()), 120);
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO
