CREATE OR ALTER VIEW vw_LibraryOverdue
AS
SELECT 
    li.IssueID,
    s.StudentID,
    s.FirstName,
    s.LastName,
    s.Email,
    item.Title as BookTitle,
    item.Author,
    li.IssueDate,
    li.DueDate,
    DATEDIFF(day, li.DueDate, GETDATE()) as OverdueDays,
    CAST(DATEDIFF(day, li.DueDate, GETDATE()) * 10.00 AS DECIMAL(10,2)) as AccruedFine
FROM LibraryIssues li
JOIN Students s ON li.StudentID = s.StudentID
JOIN LibraryItems item ON li.ItemID = item.ItemID
WHERE li.Status = 'Issued' AND li.DueDate < GETDATE();
GO
