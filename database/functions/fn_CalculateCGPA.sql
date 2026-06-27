CREATE OR ALTER FUNCTION fn_CalculateCGPA
    (@StudentID INT)
    RETURNS DECIMAL(3,2)
AS
BEGIN
    DECLARE @CGPA DECIMAL(3,2) = 0.00;
    DECLARE @TotalPoints DECIMAL(7,2) = 0.00;
    DECLARE @TotalCredits INT = 0;
    SELECT 
        @TotalPoints = SUM(
            CASE g.GradeValue
                WHEN 'A+' THEN 4.00
                WHEN 'A'  THEN 4.00
                WHEN 'A-' THEN 3.70
                WHEN 'B+' THEN 3.30
                WHEN 'B'  THEN 3.00
                WHEN 'B-' THEN 2.70
                WHEN 'C+' THEN 2.30
                WHEN 'C'  THEN 2.00
                WHEN 'C-' THEN 1.70
                WHEN 'D+' THEN 1.30
                WHEN 'D'  THEN 1.00
                ELSE 0.00
            END * c.Credits
        ),
        @TotalCredits = SUM(c.Credits)
    FROM Enrollments e
    JOIN Sections s ON e.SectionID = s.SectionID
    JOIN Courses c ON s.CourseID = c.CourseID
    JOIN Grades g ON e.EnrollmentID = g.EnrollmentID
    WHERE e.StudentID = @StudentID 
      AND e.Status = 'Completed'
      AND g.GradeValue NOT IN ('I', 'W');
    IF @TotalCredits > 0
    BEGIN
        SET @CGPA = CAST(@TotalPoints / @TotalCredits AS DECIMAL(3,2));
    END;
    RETURN @CGPA;
END;
GO