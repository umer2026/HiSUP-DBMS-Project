CREATE OR ALTER VIEW vw_ResultCard
WITH SCHEMABINDING
AS
SELECT 
    GradeID,
    EnrollmentID,
    GradeValue,
    Marks,
    Status
FROM dbo.Grades;
G