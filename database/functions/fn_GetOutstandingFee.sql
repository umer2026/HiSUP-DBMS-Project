CREATE OR ALTER FUNCTION fn_GetOutstandingFee
    (@StudentID INT)
    RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Outstanding DECIMAL(10,2) = 0.00;
    DECLARE @TotalDue DECIMAL(10,2) = 0.00;
    DECLARE @TotalPaid DECIMAL(10,2) = 0.00;
    -- Get Student Program and Current Semester
    DECLARE @ProgramID INT, @CurrentSem INT;
    SELECT @ProgramID = ProgramID, @CurrentSem = CurrentSemester 
    FROM Students 
    WHERE StudentID = @StudentID;
    -- Calculate total due fee based on program and current semester
    SELECT @TotalDue = ISNULL(SUM(TotalAmount), 0.00)
    FROM FeeStructure
    WHERE ProgramID = @ProgramID AND Semester <= @CurrentSem;
    -- Calculate total payments made (approved status)
    SELECT @TotalPaid = ISNULL(SUM(AmountPaid), 0.00)
    FROM FeePayments
    WHERE StudentID = @StudentID AND Status = 'Approved';
    SET @Outstanding = @TotalDue - @TotalPaid;
    
    -- If they paid more, outstanding is 0
    IF @Outstanding < 0
    BEGIN
        SET @Outstanding = 0.00;
    END;
    RETURN @Outstanding;
END;
GO