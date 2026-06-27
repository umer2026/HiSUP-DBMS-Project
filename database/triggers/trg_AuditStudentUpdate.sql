CREATE OR ALTER TRIGGER trg_AuditStudentUpdate
ON Students
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- Record old and new values for each student profile update
    INSERT INTO AuditLog (TableName, ActionType, OldValues, NewValues, ChangedBy, ChangedAt)
    SELECT 
        'Students',
        'UPDATE',
        (SELECT d.StudentID, d.FirstName, d.LastName, d.Email, d.Phone, d.Status FROM deleted d WHERE d.StudentID = i.StudentID FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT i.StudentID, i.FirstName, i.LastName, i.Email, i.Phone, i.Status FROM inserted i WHERE i.StudentID = i.StudentID FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        SYSTEM_USER,
        GETDATE()
    FROM inserted i;
END;
GO