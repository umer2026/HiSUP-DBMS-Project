-- =========================================================================
-- HITEC Smart University Portal (HiSUP) Security Configuration
-- Roles, Row-Level Security, and Column Encryption Decryption Demos
-- =========================================================================
USE HiSUP_DB;
GO
-- ==========================================
-- 1. Database Roles & Grants
-- ==========================================
-- Create Roles if they do not exist
IF DATABASE_PRINCIPAL_ID('db_student') IS NULL CREATE ROLE db_student;
IF DATABASE_PRINCIPAL_ID('db_faculty') IS NULL CREATE ROLE db_faculty;
IF DATABASE_PRINCIPAL_ID('db_finance') IS NULL CREATE ROLE db_finance;
IF DATABASE_PRINCIPAL_ID('db_admin') IS NULL CREATE ROLE db_admin;
GO
-- Deny direct table SELECT access for roles (security principal of least privilege)
DENY SELECT ON dbo.Grades TO db_student;
DENY SELECT ON dbo.FeePayments TO db_student;
DENY SELECT ON dbo.Enrollments TO db_student;
DENY SELECT ON dbo.Students TO db_faculty;
DENY SELECT ON dbo.FeePayments TO db_faculty;
-- Grant EXECUTE permissions on Stored Procedures
GRANT EXECUTE ON OBJECT::dbo.RegisterStudent TO db_student;
GRANT EXECUTE ON OBJECT::dbo.EnrollInCourse TO db_student;
GRANT EXECUTE ON OBJECT::dbo.ProcessFeePayment TO db_student;
GRANT EXECUTE ON OBJECT::dbo.GenerateTranscript TO db_student;
GRANT EXECUTE ON OBJECT::dbo.GetStudentReport TO db_student;
GRANT EXECUTE ON OBJECT::dbo.GenerateFeeSlip TO db_student;
GRANT EXECUTE ON OBJECT::dbo.SearchCourses TO db_student;
GRANT EXECUTE ON OBJECT::dbo.MarkAttendance TO db_faculty;
GRANT EXECUTE ON OBJECT::dbo.AddExamResult TO db_faculty;
GRANT EXECUTE ON OBJECT::dbo.GetFacultyWorkload TO db_faculty;
GRANT EXECUTE ON OBJECT::dbo.SearchCourses TO db_faculty;
GRANT EXECUTE ON OBJECT::dbo.ProcessFeePayment TO db_finance;
GRANT EXECUTE ON OBJECT::dbo.GenerateFeeSlip TO db_finance;
-- Admin has control access
GRANT CONTROL TO db_admin;
GO
-- ==========================================
-- 2. Row-Level Security (RLS) Policies
-- ==========================================
-- Predicate function for Students, Enrollments, and FeePayments
CREATE OR ALTER FUNCTION dbo.fn_SecurityPredicateStudent (@StudentID INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS fn_security_predicate_result
WHERE 
    CAST(SESSION_CONTEXT(N'StudentID') AS INT) = @StudentID
    OR CAST(SESSION_CONTEXT(N'Role') AS NVARCHAR(50)) IN (N'Admin', N'Finance', N'Faculty');
GO
-- Predicate function for Grades
CREATE OR ALTER FUNCTION dbo.fn_SecurityPredicateGrades (@EnrollmentID INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS fn_security_predicate_result
WHERE 
    CAST(SESSION_CONTEXT(N'Role') AS NVARCHAR(50)) IN (N'Admin', N'Faculty')
    OR EXISTS (
        SELECT 1 
        FROM dbo.Enrollments e
        WHERE e.EnrollmentID = @EnrollmentID 
          AND e.StudentID = CAST(SESSION_CONTEXT(N'StudentID') AS INT)
    );
GO
-- Predicate function for Sections
CREATE OR ALTER FUNCTION dbo.fn_SecurityPredicateSections (@FacultyID INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS fn_security_predicate_result
WHERE 
    CAST(SESSION_CONTEXT(N'Role') AS NVARCHAR(50)) IN (N'Admin', N'Finance', N'Student')
    OR @FacultyID = CAST(SESSION_CONTEXT(N'FacultyID') AS INT);
GO
-- Create Security Policy
-- Drop policy if exists
IF EXISTS (SELECT 1 FROM sys.security_policies WHERE name = 'PortalSecurityPolicy')
BEGIN
    DROP SECURITY POLICY PortalSecurityPolicy;
END;
GO
CREATE SECURITY POLICY PortalSecurityPolicy
ADD FILTER PREDICATE dbo.fn_SecurityPredicateStudent(StudentID) ON dbo.Students,
ADD FILTER PREDICATE dbo.fn_SecurityPredicateStudent(StudentID) ON dbo.Enrollments,
ADD FILTER PREDICATE dbo.fn_SecurityPredicateStudent(StudentID) ON dbo.FeePayments,
ADD FILTER PREDICATE dbo.fn_SecurityPredicateGrades(EnrollmentID) ON dbo.Grades,
ADD FILTER PREDICATE dbo.fn_SecurityPredicateSections(FacultyID) ON dbo.Sections;
GO
-- ==========================================
-- 3. Decryption Demos (Column Decryption)
-- ==========================================
-- Demo stored procedure for viewing decrypted student CNIC
CREATE OR ALTER PROCEDURE GetDecryptedStudentCNIC
    @StudentID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        StudentID,
        FirstName,
        LastName,
        -- Decrypt CNIC using pass phrase
        CAST(DECRYPTBYPASSPHRASE('HiSUP_CNIC_Passphrase', CNIC) AS NVARCHAR(20)) as DecryptedCNIC
    FROM Students
    WHERE StudentID = @StudentID;
END;
GO
-- Demo stored procedure for viewing decrypted bank account
CREATE OR ALTER PROCEDURE GetDecryptedFeePayments
    @StudentID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        PaymentID,
        StudentID,
        AmountPaid,
        PaymentDate,
        TransactionID,
        -- Decrypt BankAccount using pass phrase
        CAST(DECRYPTBYPASSPHRASE('HiSUP_Bank_Passphrase', BankAccount) AS NVARCHAR(50)) as DecryptedBankAccount
    FROM FeePayments
    WHERE StudentID = @StudentID;
END;
GO
-- ==========================================
-- 4. Additional Audit Logging Configuration
-- ==========================================
-- Trigger to audit Grade inserts and changes
CREATE OR ALTER TRIGGER trg_AuditGradeUpdate
ON Grades
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ActionType NVARCHAR(10);
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        SET @ActionType = 'UPDATE';
    ELSE IF EXISTS (SELECT 1 FROM inserted)
        SET @ActionType = 'INSERT';
    ELSE
        SET @ActionType = 'DELETE';
    IF @ActionType IN ('INSERT', 'UPDATE')
    BEGIN
        INSERT INTO AuditLog (TableName, ActionType, OldValues, NewValues, ChangedBy, ChangedAt)
        SELECT 
            'Grades',
            @ActionType,
            (SELECT d.GradeID, d.EnrollmentID, d.GradeValue, d.Marks, d.Status FROM deleted d WHERE d.GradeID = i.GradeID FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
            (SELECT i.GradeID, i.EnrollmentID, i.GradeValue, i.Marks, i.Status FROM inserted i WHERE i.GradeID = i.GradeID FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
            SYSTEM_USER,
            GETDATE()
        FROM inserted i;
    END;
    IF @ActionType = 'DELETE'
    BEGIN
        INSERT INTO AuditLog (TableName, ActionType, OldValues, NewValues, ChangedBy, ChangedAt)
        SELECT 
            'Grades',
            'DELETE',
            (SELECT d.GradeID, d.EnrollmentID, d.GradeValue, d.Marks, d.Status FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
            NULL,
            SYSTEM_USER,
            GETDATE()
        FROM deleted d;
    END;
END;
GO