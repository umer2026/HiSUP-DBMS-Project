CREATE OR ALTER PROCEDURE CalculateSemesterGPA
    @StudentID INT,
    @Semester NVARCHAR(10),
    @Year INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        -- Validate student
        IF NOT EXISTS (SELECT 1 FROM Students WHERE StudentID = @StudentID)
        BEGIN
            THROW 50011, 'Student does not exist.', 16;
        END;
        -- Calculate GPA and credits earned
        DECLARE @TotalPoints DECIMAL(5,2) = 0;
        DECLARE @TotalCredits INT = 0;
        DECLARE @CreditsEarned INT = 0;
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
            @TotalCredits = SUM(c.Credits),
            @CreditsEarned = SUM(CASE WHEN g.GradeValue != 'F' THEN c.Credits ELSE 0 END)
        FROM Enrollments e
        JOIN Sections s ON e.SectionID = s.SectionID
        JOIN Courses c ON s.CourseID = c.CourseID
        JOIN Grades g ON e.EnrollmentID = g.EnrollmentID
        WHERE e.StudentID = @StudentID 
          AND s.Semester = @Semester 
          AND s.Year = @Year
          AND e.Status = 'Completed';
        DECLARE @SemesterGPA DECIMAL(3,2) = 0.00;
        IF @TotalCredits > 0
        BEGIN
            SET @SemesterGPA = CAST(@TotalPoints / @TotalCredits AS DECIMAL(3,2));
        END;
        -- Upsert into Results table (using a merge or check)
        -- Since Results matches StudentID and Semester (where Semester is representable as an integer or mapping name)
        -- In our schema: Results has StudentID INT, Semester INT. Let's map Semester name ('Fall', 'Spring', 'Summer') to a number,
        -- or update the Results table to use NVARCHAR(10) or mapping. Let's map 'Fall' as 1, 'Spring' as 2 etc. or let's assume
        -- Semester in Results is an integer representing current progress semester. Let's map:
        -- Let's extract Student's CurrentSemester or map from incoming Semester. Let's check:
        -- Let's see what is student's current semester.
        DECLARE @SemNumber INT;
        SELECT @SemNumber = CurrentSemester FROM Students WHERE StudentID = @StudentID;
        IF EXISTS (SELECT 1 FROM Results WHERE StudentID = @StudentID AND Semester = @SemNumber)
        BEGIN
            UPDATE Results
            SET GPA = @SemesterGPA,
                CreditsEarned = @CreditsEarned,
                Status = CASE WHEN @SemesterGPA >= 2.00 THEN 'Passed' ELSE 'Failed' END
            WHERE StudentID = @StudentID AND Semester = @SemNumber;
        END
        ELSE
        BEGIN
            INSERT INTO Results (StudentID, Semester, GPA, CreditsEarned, Status)
            VALUES (@StudentID, @SemNumber, @SemesterGPA, @CreditsEarned, CASE WHEN @SemesterGPA >= 2.00 THEN 'Passed' ELSE 'Failed' END);
        END;
        COMMIT TRANSACTION;
        PRINT 'Semester GPA calculated and updated successfully. GPA: ' + CAST(@SemesterGPA AS VARCHAR(5));
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