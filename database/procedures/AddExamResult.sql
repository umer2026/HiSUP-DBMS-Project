CREATE OR ALTER PROCEDURE AddExamResult
    @EnrollmentID INT,
    @Marks INT,
    @Status NVARCHAR(20) = 'Submitted'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        -- Validate Enrollment
        IF NOT EXISTS (SELECT 1 FROM Enrollments WHERE EnrollmentID = @EnrollmentID)
        BEGIN
            THROW 50023, 'Enrollment record does not exist.', 16;
        END;
        -- Check Marks range
        IF @Marks < 0 OR @Marks > 100
        BEGIN
            THROW 50024, 'Marks must be between 0 and 100.', 16;
        END;
        -- Determine Letter Grade using helper logic (will match fn_GetLetterGrade)
        DECLARE @GradeValue VARCHAR(2);
        SET @GradeValue = dbo.fn_GetLetterGrade(@Marks);
        -- Upsert Grade record
        IF EXISTS (SELECT 1 FROM Grades WHERE EnrollmentID = @EnrollmentID)
        BEGIN
            UPDATE Grades
            SET Marks = @Marks,
                GradeValue = @GradeValue,
                Status = @Status
            WHERE EnrollmentID = @EnrollmentID;
        END
        ELSE
        BEGIN
            INSERT INTO Grades (EnrollmentID, GradeValue, Marks, Status)
            VALUES (@EnrollmentID, @GradeValue, @Marks, @Status);
        END;
        -- Update Enrollment status to Completed
        UPDATE Enrollments
        SET Status = 'Completed'
        WHERE EnrollmentID = @EnrollmentID;
        -- Trigger trg_AfterGradeInsert will update Student GPA/CGPA
        COMMIT TRANSACTION;
        PRINT 'Exam result added/updated successfully with Grade: ' + @GradeValue;
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
