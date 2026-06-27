-- Create Table Type if not exists
IF NOT EXISTS (SELECT 1 FROM sys.types WHERE name = 'AttendanceTableType' AND is_table_type = 1)
BEGIN
    CREATE TYPE AttendanceTableType AS TABLE (
        EnrollmentID INT,
        AttendanceDate DATE,
        Status CHAR(1),
        Remarks NVARCHAR(100)
    );
END;
GO
CREATE OR ALTER PROCEDURE MarkAttendance
    @AttendanceList AttendanceTableType READONLY
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        -- Use MERGE to insert new or update existing attendance records
        MERGE AttendanceRecords AS Target
        USING @AttendanceList AS Source
        ON (Target.EnrollmentID = Source.EnrollmentID AND Target.Date = Source.AttendanceDate)
        
        WHEN MATCHED THEN
            UPDATE SET 
                Target.Status = Source.Status, 
                Target.Remarks = Source.Remarks
        
        WHEN NOT MATCHED THEN
            INSERT (EnrollmentID, Date, Status, Remarks)
            VALUES (Source.EnrollmentID, Source.AttendanceDate, Source.Status, Source.Remarks);
        COMMIT TRANSACTION;
        PRINT 'Attendance marked successfully.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO
