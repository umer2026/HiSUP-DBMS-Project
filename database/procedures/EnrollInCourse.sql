CREATE OR ALTER PROCEDURE EnrollInCourse
    @StudentID INT,
    @SectionID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        -- Check Student existence
        IF NOT EXISTS (SELECT 1 FROM Students WHERE StudentID = @StudentID)
        BEGIN
            THROW 50003, 'Student does not exist.', 16;
        END;
        -- Check Section existence
        DECLARE @CourseID INT, @Capacity INT, @EnrolledCount INT;
        SELECT @CourseID = CourseID, @Capacity = Capacity, @EnrolledCount = EnrolledCount 
        FROM Sections 
        WHERE SectionID = @SectionID;
        IF @CourseID IS NULL
        BEGIN
            THROW 50004, 'Section does not exist.', 16;
        END;
        -- Check if already enrolled
        IF EXISTS (SELECT 1 FROM Enrollments WHERE StudentID = @StudentID AND SectionID = @SectionID)
        BEGIN
            THROW 50005, 'Student is already enrolled in this section.', 16;
        END;
        -- Check section capacity
        IF @EnrolledCount >= @Capacity
        BEGIN
            THROW 50006, 'Section is full. No available seats.', 16;
        END;
        -- Check prerequisite requirements
        DECLARE @PrereqCourseID INT;
        SELECT @PrereqCourseID = PrerequisiteCourseID FROM Courses WHERE CourseID = @CourseID;
        IF @PrereqCourseID IS NOT NULL
        BEGIN
            -- Check if student has completed the prerequisite course with a passing grade (not F, W, or I)
            IF NOT EXISTS (
                SELECT 1 
                FROM Enrollments e
                JOIN Sections s ON e.SectionID = s.SectionID
                JOIN Grades g ON e.EnrollmentID = g.EnrollmentID
                WHERE e.StudentID = @StudentID 
                  AND s.CourseID = @PrereqCourseID
                  AND g.GradeValue NOT IN ('F', 'W', 'I')
            )
            BEGIN
                THROW 50007, 'Prerequisite course has not been completed successfully.', 16;
            END;
        END;
        -- Insert enrollment (trigger trg_AfterEnrollment will update seat count)
        INSERT INTO Enrollments (StudentID, SectionID, EnrollDate, Status)
        VALUES (@StudentID, @SectionID, GETDATE(), 'Enrolled');
        COMMIT TRANSACTION;
        PRINT 'Student enrolled in course successfully.';
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