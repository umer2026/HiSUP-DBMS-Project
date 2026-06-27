CREATE OR ALTER TRIGGER trg_AfterEnrollment
ON Enrollments
AFTER INSERT, DELETE, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- Update seat count for sections affected by inserts
    IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        UPDATE Sections
        SET EnrolledCount = EnrolledCount + (
            SELECT COUNT(*) 
            FROM inserted i 
            WHERE i.SectionID = Sections.SectionID AND i.Status = 'Enrolled'
        )
        WHERE SectionID IN (SELECT SectionID FROM inserted WHERE Status = 'Enrolled');
    END;
    -- Update seat count for sections affected by deletions
    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        UPDATE Sections
        SET EnrolledCount = EnrolledCount - (
            SELECT COUNT(*) 
            FROM deleted d 
            WHERE d.SectionID = Sections.SectionID AND d.Status = 'Enrolled'
        )
        WHERE SectionID IN (SELECT SectionID FROM deleted WHERE Status = 'Enrolled');
    END;
END;
GO