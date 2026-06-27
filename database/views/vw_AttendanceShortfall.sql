CREATE OR ALTER VIEW vw_AttendanceShortfall
AS
SELECT 
    s.StudentID,
    s.FirstName,
    s.LastName,
    c.CourseCode,
    c.CourseTitle,
    sec.SectionName,
    dbo.fn_GetAttendancePercentage(s.StudentID, sec.SectionID) as AttendancePercentage
FROM Students s
JOIN Enrollments e ON s.StudentID = e.StudentID
JOIN Sections sec ON e.SectionID = sec.SectionID
JOIN Courses c ON sec.CourseID = c.CourseID
WHERE e.Status = 'Enrolled' 
  AND dbo.fn_GetAttendancePercentage(s.StudentID, sec.SectionID) < 75.00;
GO