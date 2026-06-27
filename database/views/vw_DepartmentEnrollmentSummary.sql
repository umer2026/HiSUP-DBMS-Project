CREATE OR ALTER VIEW vw_DepartmentEnrollmentSummary
AS
SELECT 
    d.DeptName,
    p.ProgramName,
    p.DegreeLevel,
    COUNT(s.StudentID) as EnrolledStudentsCount
FROM Departments d
JOIN Programs p ON d.DepartmentID = p.DeptID
LEFT JOIN Students s ON p.ProgramID = s.ProgramID
GROUP BY d.DeptName, p.ProgramName, p.DegreeLevel;
GO
