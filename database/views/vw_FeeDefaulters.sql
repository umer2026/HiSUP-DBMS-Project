CREATE OR ALTER VIEW vw_FeeDefaulters
AS
SELECT 
    s.StudentID,
    s.FirstName,
    s.LastName,
    s.Email,
    p.ProgramName,
    s.CurrentSemester,
    dbo.fn_GetOutstandingFee(s.StudentID) as OutstandingAmount
FROM Students s
JOIN Programs p ON s.ProgramID = p.ProgramID
WHERE dbo.fn_GetOutstandingFee(s.StudentID) > 0.00;
GO
