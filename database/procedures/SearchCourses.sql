CREATE OR ALTER PROCEDURE SearchCourses
    @CourseCode NVARCHAR(10) = NULL,
    @CourseTitle NVARCHAR(100) = NULL,
    @DeptID INT = NULL,
    @Credits INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT 
            c.CourseID,
            c.CourseCode,
            c.CourseTitle,
            c.Credits,
            d.DeptName,
            pre.CourseCode as PrerequisiteCourseCode,
            pre.CourseTitle as PrerequisiteCourseTitle
        FROM Courses c
        JOIN Departments d ON c.DeptID = d.DepartmentID
        LEFT JOIN Courses pre ON c.PrerequisiteCourseID = pre.CourseID
        WHERE (@CourseCode IS NULL OR c.CourseCode LIKE '%' + @CourseCode + '%')
          AND (@CourseTitle IS NULL OR c.CourseTitle LIKE '%' + @CourseTitle + '%')
          AND (@DeptID IS NULL OR c.DeptID = @DeptID)
          AND (@Credits IS NULL OR c.Credits = @Credits)
        ORDER BY c.CourseCode;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO