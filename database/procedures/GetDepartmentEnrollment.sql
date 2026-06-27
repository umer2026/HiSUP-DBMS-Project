CREATE OR ALTER PROCEDURE GetDepartmentEnrollment
    @DeptID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT 
            d.DepartmentID,
            d.DeptName,
            d.DeptCode,
            p.ProgramID,
            p.ProgramName,
            p.DegreeLevel,
            COUNT(s.StudentID) as TotalEnrolledStudents,
            AVG(s.CGPA) as AverageCGPA
        FROM Departments d
        JOIN Programs p ON d.DepartmentID = p.DeptID
        LEFT JOIN Students s ON p.ProgramID = s.ProgramID
        WHERE (@DeptID IS NULL OR d.DepartmentID = @DeptID)
        GROUP BY d.DepartmentID, d.DeptName, d.DeptCode, p.ProgramID, p.ProgramName, p.DegreeLevel
        ORDER BY d.DeptName, p.ProgramName;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO