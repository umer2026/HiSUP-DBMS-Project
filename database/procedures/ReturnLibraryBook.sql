CREATE OR ALTER PROCEDURE ReturnLibraryBook
    @IssueID INT,
    @FinePaid DECIMAL(10,2) = 0.00
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        -- Validate Issue record
        DECLARE @StudentID INT, @ItemID INT, @DueDate DATE, @Status NVARCHAR(20);
        SELECT @StudentID = StudentID, @ItemID = ItemID, @DueDate = DueDate, @Status = Status 
        FROM LibraryIssues 
        WHERE IssueID = @IssueID;
        IF @StudentID IS NULL
        BEGIN
            THROW 50021, 'Library issue record does not exist.', 16;
        END;
        IF @Status = 'Returned'
        BEGIN
            THROW 50022, 'This library item has already been returned.', 16;
        END;
        -- Calculate fine (10 units per day overdue)
        DECLARE @OverdueDays INT = DATEDIFF(day, @DueDate, GETDATE());
        DECLARE @CalculatedFine DECIMAL(10,2) = 0.00;
        
        IF @OverdueDays > 0
        BEGIN
            SET @CalculatedFine = CAST(@OverdueDays * 10.00 AS DECIMAL(10,2));
        END;
        -- Update the issue record
        UPDATE LibraryIssues
        SET ReturnDate = GETDATE(),
            FinePaid = @FinePaid,
            Status = 'Returned'
        WHERE IssueID = @IssueID;
        -- Note: The trigger 'trg_AfterLibraryReturn' will execute on UPDATE to restore copies-available.
        COMMIT TRANSACTION;
        PRINT 'Library item returned successfully. Calculated Fine: ' + CAST(@CalculatedFine AS VARCHAR(10)) + ', Paid Fine: ' + CAST(@FinePaid AS VARCHAR(10));
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
