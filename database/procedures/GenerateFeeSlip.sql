CREATE OR ALTER PROCEDURE GenerateFeeSlip
    @StudentID INT,
    @Semester INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Check if student exists
        IF NOT EXISTS (SELECT 1 FROM Students WHERE StudentID = @StudentID)
        BEGIN
            THROW 50026, 'Student does not exist.', 16;
        END;
        DECLARE @StudentSem INT;
        SELECT @StudentSem = CurrentSemester FROM Students WHERE StudentID = @StudentID;
        IF @Semester IS NULL
        BEGIN
            SET @Semester = @StudentSem;
        END;
        -- Generate Fee Slip Details
        SELECT 
            s.StudentID,
            s.FirstName,
            s.LastName,
            s.Email,
            p.ProgramName,
            fs.Semester,
            fs.TuitionFee,
            fs.AdmissionFee,
            fs.LibraryFee,
            fs.HostelFee,
            fs.TotalAmount as TotalDue,
            -- Calculate total paid for this specific semester fee structure
            ISNULL((
                SELECT SUM(fp.AmountPaid) 
                FROM FeePayments fp 
                WHERE fp.StudentID = s.StudentID AND fp.FeeStructureID = fs.FeeStructureID AND fp.Status = 'Approved'
            ), 0.00) as TotalPaid,
            dbo.fn_GetOutstandingFee(s.StudentID) as TotalOutstandingBalance
        FROM Students s
        JOIN Programs p ON s.ProgramID = p.ProgramID
        JOIN FeeStructure fs ON p.ProgramID = fs.ProgramID
        WHERE s.StudentID = @StudentID AND fs.Semester = @Semester;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO
