CREATE OR ALTER TRIGGER trg_AfterFeePayment
ON FeePayments
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ActionType NVARCHAR(10);
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        SET @ActionType = 'UPDATE';
    ELSE IF EXISTS (SELECT 1 FROM inserted)
        SET @ActionType = 'INSERT';
    ELSE
        SET @ActionType = 'DELETE';
    -- Audit insert/update
    IF @ActionType IN ('INSERT', 'UPDATE')
    BEGIN
        INSERT INTO AuditLog (TableName, ActionType, OldValues, NewValues, ChangedBy, ChangedAt)
        SELECT 
            'FeePayments',
            @ActionType,
            (SELECT d.PaymentID, d.StudentID, d.FeeStructureID, d.AmountPaid, d.Status FROM deleted d WHERE d.PaymentID = i.PaymentID FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
            (SELECT i.PaymentID, i.StudentID, i.FeeStructureID, i.AmountPaid, i.Status FROM inserted i WHERE i.PaymentID = i.PaymentID FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
            SYSTEM_USER,
            GETDATE()
        FROM inserted i;
    END;
    -- Audit delete
    IF @ActionType = 'DELETE'
    BEGIN
        INSERT INTO AuditLog (TableName, ActionType, OldValues, NewValues, ChangedBy, ChangedAt)
        SELECT 
            'FeePayments',
            'DELETE',
            (SELECT d.PaymentID, d.StudentID, d.FeeStructureID, d.AmountPaid, d.Status FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
            NULL,
            SYSTEM_USER,
            GETDATE()
        FROM deleted d;
    END;
END;
GO
