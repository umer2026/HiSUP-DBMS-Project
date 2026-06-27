    CREATE OR ALTER PROCEDURE AllocateHostelRoom
    @StudentID INT,
    @HostelID INT,
    @RoomNo NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        -- Check Student
        IF NOT EXISTS (SELECT 1 FROM Students WHERE StudentID = @StudentID)
        BEGIN
            THROW 50012, 'Student does not exist.', 16;
        END;
        -- Check Hostel
        DECLARE @HostelCapacity INT, @HostelStatus NVARCHAR(20);
        SELECT @HostelCapacity = Capacity, @HostelStatus = Status 
        FROM Hostels 
        WHERE HostelID = @HostelID;
        IF @HostelCapacity IS NULL
        BEGIN
            THROW 50013, 'Hostel does not exist.', 16;
        END;
        IF @HostelStatus = 'Under Maintenance'
        BEGIN
            THROW 50014, 'Hostel is currently under maintenance.', 16;
        END;
        -- Check if student already has an active allotment
        IF EXISTS (SELECT 1 FROM HostelAllotments WHERE StudentID = @StudentID AND Status = 'Active')
        BEGIN
            THROW 50015, 'Student already has an active hostel allotment.', 16;
        END;
        -- Check current allotment count for this hostel
        DECLARE @CurrentAllotments INT;
        SELECT @CurrentAllotments = COUNT(*) 
        FROM HostelAllotments 
        WHERE HostelID = @HostelID AND Status = 'Active';
        IF @CurrentAllotments >= @HostelCapacity
        BEGIN
            -- Update hostel status to Full
            UPDATE Hostels SET Status = 'Full' WHERE HostelID = @HostelID;
            THROW 50016, 'Hostel has reached full capacity.', 16;
        END;
        -- Insert Allotment
        INSERT INTO HostelAllotments (StudentID, HostelID, RoomNo, AllotmentDate, Status)
        VALUES (@StudentID, @HostelID, @RoomNo, GETDATE(), 'Active');
        -- Check again if full and update
        IF (@CurrentAllotments + 1) >= @HostelCapacity
        BEGIN
            UPDATE Hostels SET Status = 'Full' WHERE HostelID = @HostelID;
        END;
        COMMIT TRANSACTION;
        PRINT 'Hostel room allocated successfully.';
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
