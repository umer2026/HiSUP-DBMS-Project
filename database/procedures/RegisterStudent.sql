CREATE OR ALTER PROCEDURE RegisterStudent
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Email NVARCHAR(100),
    @Phone NVARCHAR(15),
    @CNIC NVARCHAR(20), -- Raw CNIC to be encrypted
    @DateOfBirth DATE,
    @ProgramID INT,
    @PasswordHash NVARCHAR(256),
    @NewStudentID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        -- Validate Program
        IF NOT EXISTS (SELECT 1 FROM Programs WHERE ProgramID = @ProgramID)
        BEGIN
            THROW 50001, 'Program does not exist.', 16;
        END;
        -- Validate Email Unique
        IF EXISTS (SELECT 1 FROM Students WHERE Email = @Email)
        BEGIN
            THROW 50002, 'Email is already registered.', 16;
        END;
        -- Encrypt CNIC
        DECLARE @EncryptedCNIC VARBINARY(256);
        SET @EncryptedCNIC = ENCRYPTBYPASSPHRASE('HiSUP_CNIC_Passphrase', @CNIC);
        -- Insert Student
        INSERT INTO Students (FirstName, LastName, Email, Phone, CNIC, DateOfBirth, ProgramID, CurrentSemester, CGPA, Status)
        VALUES (@FirstName, @LastName, @Email, @Phone, @EncryptedCNIC, @DateOfBirth, @ProgramID, 1, 0.00, 'Active');
        SET @NewStudentID = SCOPE_IDENTITY();
        -- Create User Account
        INSERT INTO UserAccounts (Email, PasswordHash, Role, StudentID, IsActive)
        VALUES (@Email, @PasswordHash, 'Student', @NewStudentID, 1);
        COMMIT TRANSACTION;
        PRINT 'Student registered successfully with ID: ' + CAST(@NewStudentID AS VARCHAR(10));
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