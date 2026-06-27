CREATE OR ALTER VIEW vw_ExamTimetable
WITH SCHEMABINDING
AS
SELECT 
    ExamScheduleID,
    CourseID,
    ExamDate,
    StartTime,
    EndTime,
    RoomNo
FROM dbo.ExamSchedule;
GO