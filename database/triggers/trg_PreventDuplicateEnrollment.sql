CREATE OR ALTER TRIGGER trg_PreventDuplicateEnrollment
ON Enrollments
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    -- Check if any of the incoming enrollments are duplicates for the same course in the same semester
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Sections target_s ON i.SectionID = target_s.SectionID
        JOIN Enrollments e ON i.StudentID = e.StudentID
        JOIN Sections existing_s ON e.SectionID = existing_s.SectionID
        WHERE target_s.CourseID = existing_s.CourseID 
          AND target_s.Semester = existing_s.Semester 
          AND target_s.Year = existing_s.Year
          AND e.Status = 'Enrolled'
    )
    BEGIN
        RAISERROR('Student is already enrolled in another section of this course for this semester.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
    -- Insert valid enrollments
    INSERT INTO Enrollments (StudentID, SectionID, EnrollDate, Status)
    SELECT StudentID, SectionID, ISNULL(EnrollDate, GETDATE()), ISNULL(Status, 'Enrolled')
    FROM inserted;
END;
GO