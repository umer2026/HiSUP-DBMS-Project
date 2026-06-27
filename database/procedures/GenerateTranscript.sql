CREATE OR ALTER PROCEDURE GenerateTranscript
    @StudentID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Check if student exists
        IF NOT EXISTS (SELECT 1 FROM Students WHERE StudentID = @StudentID)
        BEGIN
            THROW 50010, 'Student does not exist.', 16;
        END;
        -- CTE to compile enrollment, course details, grades, and semester GPAs
        WITH StudentGrades AS (
            SELECT 
                c.CourseCode,
                c.CourseTitle,
                c.Credits,
                g.GradeValue,
                g.Marks,
                s.Semester,
                s.Year,
                -- Window function to calculate running sum of credits
                SUM(c.Credits) OVER (PARTITION BY s.Semester, s.Year) as SemesterCredits,
                -- Assign numeric point values to grades for calculation
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
                    WHEN 'F'  THEN 0.00
                    ELSE 0.00
                END as GradePoints
            FROM Enrollments e
            JOIN Sections s ON e.SectionID = s.SectionID
            JOIN Courses c ON s.CourseID = c.CourseID
            LEFT JOIN Grades g ON e.EnrollmentID = g.EnrollmentID
            WHERE e.StudentID = @StudentID AND e.Status = 'Completed'
        ),
        SemesterGPA AS (
            SELECT 
                Semester,
                Year,
                CAST(SUM(GradePoints * Credits) / NULLIF(SUM(Credits), 0) AS DECIMAL(3,2)) as SemGPA
            FROM StudentGrades
            GROUP BY Semester, Year
        )
        SELECT 
            sg.CourseCode,
            sg.CourseTitle,
            sg.Credits,
            sg.GradeValue,
            sg.Marks,
            sg.Semester,
            sg.Year,
            sg.GradePoints,
            gpa.SemGPA
        FROM StudentGrades sg
        JOIN SemesterGPA gpa ON sg.Semester = gpa.Semester AND sg.Year = gpa.Year
        ORDER BY sg.Year, sg.Semester, sg.CourseCode;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO