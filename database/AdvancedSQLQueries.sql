-- =========================================================================
-- HITEC Smart University Portal (HiSUP) Advanced SQL Queries
-- Includes Recursive CTEs, Window Functions, PIVOT/UNPIVOT, Dynamic SQL, and MERGE
-- =========================================================================
USE HiSUP_DB;
GO
-- 1. Recursive CTE for Course Prerequisites Chain
-- Anchors on a course and traces its entire prerequisite history.
DECLARE @TargetCourseID INT = 3; -- Example CourseID
WITH PrerequisiteChain AS (
    -- Anchor Member: Select target course
    SELECT 
        CourseID, 
        CourseCode, 
        CourseTitle, 
        PrerequisiteCourseID,
        0 AS HierarchyLevel
    FROM Courses
    WHERE CourseID = @TargetCourseID
    
    UNION ALL
    
    -- Recursive Member: Join upstream prerequisites
    SELECT 
        c.CourseID, 
        c.CourseCode, 
        c.CourseTitle, 
        c.PrerequisiteCourseID,
        p.HierarchyLevel + 1
    FROM Courses c
    INNER JOIN PrerequisiteChain p ON p.PrerequisiteCourseID = c.CourseID
)
SELECT 
    HierarchyLevel, 
    CourseCode, 
    CourseTitle, 
    ISNULL(CAST(PrerequisiteCourseID AS VARCHAR), 'None') as PrereqID
FROM PrerequisiteChain
ORDER BY HierarchyLevel;
GO
-- 2. Department Ranking Using Window Functions
-- Ranks departments based on total students enrolled and average student CGPA.
SELECT 
    d.DeptName,
    COUNT(s.StudentID) as EnrolledStudents,
    AVG(s.CGPA) as AverageCGPA,
    RANK() OVER (ORDER BY COUNT(s.StudentID) DESC) as EnrollmentRank,
    DENSE_RANK() OVER (ORDER BY AVG(s.CGPA) DESC) as CGPARank
FROM Departments d
LEFT JOIN Programs p ON d.DepartmentID = p.DeptID
LEFT JOIN Students s ON p.ProgramID = s.ProgramID
GROUP BY d.DeptName;
GO
-- 3. Student Ranking using DENSE_RANK
-- Ranks students by CGPA within their academic programs.
SELECT 
    StudentID,
    FirstName,
    LastName,
    ProgramID,
    CGPA,
    DENSE_RANK() OVER (PARTITION BY ProgramID ORDER BY CGPA DESC) as CGPARankWithinProgram
FROM Students;
GO
-- 4. Attendance Analytics Using NTILE
-- Partitions students into quartiles (1-4) based on attendance rates.
WITH StudentAttendance AS (
    SELECT 
        StudentID,
        FirstName,
        LastName,
        dbo.fn_GetAttendancePercentage(StudentID, NULL) as AttendanceRate
    FROM Students
)
SELECT 
    StudentID,
    FirstName,
    LastName,
    AttendanceRate,
    NTILE(4) OVER (ORDER BY AttendanceRate DESC) as AttendanceQuartile -- 1 is Top Quartile, 4 is Bottom
FROM StudentAttendance;
GO
-- 5. Running Fee Totals
-- Displays fee payment history for each student with a running total of amount paid.
SELECT 
    StudentID,
    PaymentID,
    AmountPaid,
    PaymentDate,
    SUM(AmountPaid) OVER (PARTITION BY StudentID ORDER BY PaymentDate, PaymentID) as RunningTotalPaid
FROM FeePayments
WHERE Status = 'Approved';
GO
-- 6. Dynamic SQL Student Search using sp_executesql
-- Parameterized dynamic SQL execution preventing injection attacks.
CREATE OR ALTER PROCEDURE SearchStudentsDynamic
    @SearchTerm NVARCHAR(100) = NULL,
    @ProgramID INT = NULL,
    @MinCGPA DECIMAL(3,2) = NULL,
    @Status NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @ParamDefinition NVARCHAR(MAX);
    SET @SQL = N'SELECT StudentID, FirstName, LastName, Email, ProgramID, CGPA, Status 
                 FROM Students 
                 WHERE 1=1';
    IF @SearchTerm IS NOT NULL
    BEGIN
        SET @SQL = @SQL + N' AND (FirstName LIKE @pSearchTerm OR LastName LIKE @pSearchTerm OR Email LIKE @pSearchTerm)';
    END;
    IF @ProgramID IS NOT NULL
    BEGIN
        SET @SQL = @SQL + N' AND ProgramID = @pProgramID';
    END;
    IF @MinCGPA IS NOT NULL
    BEGIN
        SET @SQL = @SQL + N' AND CGPA >= @pMinCGPA';
    END;
    IF @Status IS NOT NULL
    BEGIN
        SET @SQL = @SQL + N' AND Status = @pStatus';
    END;
    SET @ParamDefinition = N'@pSearchTerm NVARCHAR(100), @pProgramID INT, @pMinCGPA DECIMAL(3,2), @pStatus NVARCHAR(20)';
    DECLARE @LikeSearch NVARCHAR(102) = '%' + @SearchTerm + '%';
    EXEC sp_executesql @SQL, @ParamDefinition, 
        @pSearchTerm = @LikeSearch, 
        @pProgramID = @ProgramID, 
        @pMinCGPA = @MinCGPA, 
        @pStatus = @Status;
END;
GO
-- 7. PIVOT Semester-wise Attendance Report
-- Transforms row-wise semester attendance statistics into column-wise format.
SELECT StudentID, FirstName, LastName, ISNULL([Fall], 0.00) as FallAttPercent, ISNULL([Spring], 0.00) as SpringAttPercent, ISNULL([Summer], 0.00) as SummerAttPercent
FROM (
    SELECT 
        s.StudentID,
        s.FirstName,
        s.LastName,
        sec.Semester,
        dbo.fn_GetAttendancePercentage(s.StudentID, sec.SectionID) as AttPercent
    FROM Students s
    JOIN Enrollments e ON s.StudentID = e.StudentID
    JOIN Sections sec ON e.SectionID = sec.SectionID
) as SourceTable
PIVOT (
    AVG(AttPercent)
    FOR Semester IN ([Fall], [Spring], [Summer])
) as PivotTable;
GO
-- 8. UNPIVOT Report
-- Normalizes and transforms column-wise mark scores to row-wise.
SELECT StudentID, ExamType, Score
FROM (
    SELECT 
        e.StudentID, 
        g.Marks as FinalExamScore, 
        CAST(g.Marks * 0.7 AS INT) as MidtermExamScore -- Simulated Midterm
    FROM Enrollments e
    JOIN Grades g ON e.EnrollmentID = g.EnrollmentID
) p
UNPIVOT (
    Score FOR ExamType IN (FinalExamScore, MidtermExamScore)
) AS unpvt;
GO
-- 9. MERGE Statement for Bulk Grade Upload
-- Creates bulk grade table type and MERGE procedure.
IF NOT EXISTS (SELECT 1 FROM sys.types WHERE name = 'GradeImportTableType' AND is_table_type = 1)
BEGIN
    CREATE TYPE GradeImportTableType AS TABLE (
        EnrollmentID INT,
        Marks INT,
        GradeValue VARCHAR(2),
        Status NVARCHAR(20)
    );
END;
GO
CREATE OR ALTER PROCEDURE ImportBulkGrades
    @GradeList GradeImportTableType READONLY
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        -- MERGE Grades (inserts new, updates existing, and deletes absent rows)
        MERGE Grades AS Target
        USING @GradeList AS Source
        ON (Target.EnrollmentID = Source.EnrollmentID)
        
        WHEN MATCHED THEN
            UPDATE SET 
                Target.Marks = Source.Marks,
                Target.GradeValue = Source.GradeValue,
                Target.Status = Source.Status
        
        WHEN NOT MATCHED THEN
            INSERT (EnrollmentID, GradeValue, Marks, Status)
            VALUES (Source.EnrollmentID, Source.GradeValue, Source.Marks, Source.Status)
            
        WHEN NOT MATCHED BY SOURCE THEN
            DELETE;
        -- Recalculate CGPA for affected students
        UPDATE Students
        SET CGPA = dbo.fn_CalculateCGPA(StudentID)
        WHERE StudentID IN (
            SELECT DISTINCT e.StudentID
            FROM Enrollments e
            LEFT JOIN Grades g ON e.EnrollmentID = g.EnrollmentID
        );
        COMMIT TRANSACTION;
        PRINT 'Bulk grades merged successfully.';
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