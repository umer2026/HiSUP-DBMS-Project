CREATE OR ALTER FUNCTION fn_GetAttendancePercentage
    (@StudentID INT, @SectionID INT = NULL)
    RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @Percentage DECIMAL(5,2) = 0.00;
    DECLARE @TotalClasses INT = 0;
    DECLARE @PresentClasses DECIMAL(5,1) = 0.0;
    -- Calculate attendance stats
    SELECT 
        @TotalClasses = COUNT(a.AttendanceID),
        @PresentClasses = SUM(
            CASE a.Status
                WHEN 'P' THEN 1.0
                WHEN 'L' THEN 0.5 -- Late counts as half presence
                ELSE 0.0
            END
        )
    FROM AttendanceRecords a
    JOIN Enrollments e ON a.EnrollmentID = e.EnrollmentID
    WHERE e.StudentID = @StudentID
      AND (@SectionID IS NULL OR e.SectionID = @SectionID);
    IF @TotalClasses > 0
    BEGIN
        SET @Percentage = CAST((@PresentClasses / @TotalClasses) * 100.0 AS DECIMAL(5,2));
    END;
    RETURN @Percentage;
END;
GO