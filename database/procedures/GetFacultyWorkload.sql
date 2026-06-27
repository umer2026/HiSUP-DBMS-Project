CREATE OR ALTER PROCEDURE GetFacultyWorkload
    @FacultyID INT = NULL -- If NULL, return all faculty workloads
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        WITH WorkloadStats AS (
            SELECT 
                f.FacultyID,
                f.FirstName,
                f.LastName,
                d.DeptName,
                s.SectionID,
                c.CourseCode,
                c.CourseTitle,
                s.Semester,
                s.Year,
                s.EnrolledCount,
                -- Window function to count sections per faculty
                COUNT(s.SectionID) OVER(PARTITION BY f.FacultyID) as TotalSectionsTaught,
                -- Window function to sum total students taught by faculty
                SUM(s.EnrolledCount) OVER(PARTITION BY f.FacultyID) as TotalStudentsTaught,
                -- Window function to rank faculty workload within their department
                DENSE_RANK() OVER (PARTITION BY f.DeptID ORDER BY COUNT(s.SectionID) OVER(PARTITION BY f.FacultyID) DESC) as DeptWorkloadRank
            FROM Faculty f
            JOIN Departments d ON f.DeptID = d.DepartmentID
            LEFT JOIN Sections s ON f.FacultyID = s.FacultyID
            LEFT JOIN Courses c ON s.CourseID = c.CourseID
            WHERE @FacultyID IS NULL OR f.FacultyID = @FacultyID
        )
        SELECT DISTINCT 
            FacultyID,
            FirstName,
            LastName,
            DeptName,
            TotalSectionsTaught,
            TotalStudentsTaught,
            DeptWorkloadRank
        FROM WorkloadStats
        ORDER BY DeptName, DeptWorkloadRank;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO