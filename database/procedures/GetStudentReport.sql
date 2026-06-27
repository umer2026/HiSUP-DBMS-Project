CREATE OR ALTER PROCEDURE GetStudentReport
    @StudentID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Check if student exists
        IF NOT EXISTS (SELECT 1 FROM Students WHERE StudentID = @StudentID)
        BEGIN
            THROW 50025, 'Student does not exist.', 16;
        END;
        -- Return compiled statistics using functions and CTEs
        WITH StudentBase AS (
            SELECT 
                s.StudentID,
                s.FirstName,
                s.LastName,
                s.Email,
                p.ProgramName,
                s.CurrentSemester,
                s.CGPA,
                s.Status as EnrollmentStatus
            FROM Students s
            JOIN Programs p ON s.ProgramID = p.ProgramID
            WHERE s.StudentID = @StudentID
        )
        SELECT 
            sb.*,
            dbo.fn_GetOutstandingFee(@StudentID) as OutstandingFee,
            dbo.fn_GetAttendancePercentage(@StudentID, NULL) as OverallAttendancePercentage
        FROM StudentBase sb;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO
