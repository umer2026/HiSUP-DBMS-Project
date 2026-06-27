CREATE OR ALTER VIEW vw_FacultyCourseLoad
AS
SELECT 
    f.FacultyID,
    f.FirstName,
    f.LastName,
    f.Designation,
    s.SectionID,
    s.SectionName,
    c.CourseCode,
    c.CourseTitle,
    s.Semester,
    s.Year,
    s.RoomNo,
    s.Capacity,
    s.EnrolledCount
FROM Faculty f
JOIN Sections s ON f.FacultyID = s.FacultyID
JOIN Courses c ON s.CourseID = c.CourseID;
GO
