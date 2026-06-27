CREATE OR ALTER VIEW vw_StudentDashboard
AS
SELECT 
    s.StudentID,
    s.FirstName,
    s.LastName,
    s.Email,
    p.ProgramName,
    s.CurrentSemester,
    s.CGPA,
    s.Status,
    dbo.fn_GetOutstandingFee(s.StudentID) as OutstandingFee,
    dbo.fn_GetAttendancePercentage(s.StudentID, NULL) as AttendancePercentage
FROM Students s
JOIN Programs p ON s.ProgramID = p.ProgramID;
GO
