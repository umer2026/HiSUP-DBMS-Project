CREATE OR ALTER TRIGGER trg_AfterGradeInsert
ON Grades
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- Recalculate CGPA for all students whose grades changed
    DECLARE @AffectedStudents TABLE (StudentID INT);
    INSERT INTO @AffectedStudents (StudentID)
    SELECT DISTINCT e.StudentID
    FROM inserted i
    JOIN Enrollments e ON i.EnrollmentID = e.EnrollmentID;
    -- Update Students table using UDF fn_CalculateCGPA
    UPDATE Students
    SET CGPA = dbo.fn_CalculateCGPA(StudentID)
    WHERE StudentID IN (SELECT StudentID FROM @AffectedStudents);
END;
GO