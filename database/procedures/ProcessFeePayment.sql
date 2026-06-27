CREATE OR ALTER PROCEDURE ProcessFeePayment
    @StudentID INT,
    @FeeStructureID INT,
    @AmountPaid DECIMAL(10,2),
    @PaymentMethod NVARCHAR(50),
    @TransactionID NVARCHAR(100),
    @BankAccount NVARCHAR(50) -- Raw Bank Account to be encrypted
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        -- Check Student
        IF NOT EXISTS (SELECT 1 FROM Students WHERE StudentID = @StudentID)
        BEGIN
            THROW 50008, 'Student does not exist.', 16;
        END;
        -- Check Fee Structure
        IF NOT EXISTS (SELECT 1 FROM FeeStructure WHERE FeeStructureID = @FeeStructureID)
        BEGIN
            THROW 50009, 'Fee structure does not exist.', 16;
        END;
        -- Encrypt BankAccount
        DECLARE @EncryptedBank VARBINARY(256);
        SET @EncryptedBank = ENCRYPTBYPASSPHRASE('HiSUP_Bank_Passphrase', @BankAccount);
        -- Insert Payment (trigger trg_AfterFeePayment will log/audit or update as required)
        INSERT INTO FeePayments (StudentID, FeeStructureID, AmountPaid, PaymentDate, PaymentMethod, TransactionID, BankAccount, Status)
        VALUES (@StudentID, @FeeStructureID, @AmountPaid, GETDATE(), @PaymentMethod, @TransactionID, @EncryptedBank, 'Approved');
        COMMIT TRANSACTION;
        PRINT 'Payment processed successfully.';
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
