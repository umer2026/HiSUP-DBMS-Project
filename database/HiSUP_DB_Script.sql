-- =========================================================================
-- HITEC Smart University Portal (HiSUP) Database Script
-- Database: HiSUP_DB
-- Normalized to BCNF with complete constraints & documentation
-- =========================================================================
CREATE DATABASE HiSUP_DB;
GO
USE HiSUP_DB;
GO
-- 1. Departments Table
-- Stores departmental details. DepName and DeptCode are unique candidates.
CREATE TABLE Departments (
    DepartmentID INT PRIMARY KEY IDENTITY(1,1),
    DeptName NVARCHAR(100) NOT NULL UNIQUE,
    DeptCode NVARCHAR(10) NOT NULL UNIQUE,
    EstablishedYear INT CHECK (EstablishedYear >= 1990),
    CreatedAt DATETIME DEFAULT GETDATE()
);
GO
-- 2. Programs Table
-- Stores academic programs offered by departments.
CREATE TABLE Programs (
    ProgramID INT PRIMARY KEY IDENTITY(1,1),
    ProgramName NVARCHAR(100) NOT NULL UNIQUE,
    DeptID INT NOT NULL CONSTRAINT FK_Programs_Dept FOREIGN KEY REFERENCES Departments(DepartmentID) ON DELETE CASCADE ON UPDATE CASCADE,
    DurationYears INT CHECK (DurationYears BETWEEN 1 AND 5),
    DegreeLevel NVARCHAR(50) CHECK (DegreeLevel IN ('Associate', 'Bachelors', 'Masters', 'PhD'))
);
GO
-- 3. Students Table
-- Stores student profiles. CNIC is encrypted for security.
CREATE TABLE Students (
    StudentID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    Phone NVARCHAR(15) NULL,
    CNIC VARBINARY(256) NOT NULL, -- Encrypted Column
    DateOfBirth DATE NOT NULL,
    EnrollDate DATE DEFAULT GETDATE(),
    ProgramID INT NOT NULL CONSTRAINT FK_Students_Program FOREIGN KEY REFERENCES Programs(ProgramID) ON DELETE NO ACTION ON UPDATE CASCADE,
    CurrentSemester INT CHECK (CurrentSemester BETWEEN 1 AND 10) DEFAULT 1,
    CGPA DECIMAL(3,2) CHECK (CGPA BETWEEN 0.00 AND 4.00) DEFAULT 0.00,
    Status NVARCHAR(20) CHECK (Status IN ('Active', 'Suspended', 'Graduated', 'Withdrawn')) DEFAULT 'Active'
);
GO
-- 4. Faculty Table
-- Stores academic faculty details.
CREATE TABLE Faculty (
    FacultyID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    Phone NVARCHAR(15) NULL,
    DeptID INT NOT NULL CONSTRAINT FK_Faculty_Dept FOREIGN KEY REFERENCES Departments(DepartmentID) ON DELETE NO ACTION ON UPDATE CASCADE,
    Designation NVARCHAR(50) CHECK (Designation IN ('Lecturer', 'Assistant Professor', 'Associate Professor', 'Professor')),
    HireDate DATE DEFAULT GETDATE(),
    Salary DECIMAL(10,2) CHECK (Salary > 0.00),
    Status NVARCHAR(20) CHECK (Status IN ('Active', 'On Leave', 'Retired', 'Terminated')) DEFAULT 'Active'
);
GO
-- 5. Staff Table
-- Stores university non-academic staff details.
CREATE TABLE Staff (
    StaffID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    Phone NVARCHAR(15) NULL,
    Role NVARCHAR(50) CHECK (Role IN ('Registrar', 'Librarian', 'Finance Officer', 'Hostel Warden', 'IT Support', 'Admin')),
    Salary DECIMAL(10,2) CHECK (Salary > 0.00),
    Status NVARCHAR(20) CHECK (Status IN ('Active', 'On Leave', 'Retired', 'Terminated')) DEFAULT 'Active'
);
GO
-- 6. Courses Table
-- Stores course curricula. PrerequisiteCourseID references the same table.
CREATE TABLE Courses (
    CourseID INT PRIMARY KEY IDENTITY(1,1),
    CourseCode NVARCHAR(10) NOT NULL UNIQUE,
    CourseTitle NVARCHAR(100) NOT NULL,
    Credits INT CHECK (Credits BETWEEN 1 AND 6),
    DeptID INT NOT NULL CONSTRAINT FK_Courses_Dept FOREIGN KEY REFERENCES Departments(DepartmentID) ON DELETE NO ACTION ON UPDATE CASCADE,
    PrerequisiteCourseID INT NULL CONSTRAINT FK_Courses_Prereq FOREIGN KEY REFERENCES Courses(CourseID) ON DELETE NO ACTION ON UPDATE NO ACTION
);
GO
-- 7. Sections Table
-- Stores specific offerings of courses.
CREATE TABLE Sections (
    SectionID INT PRIMARY KEY IDENTITY(1,1),
    CourseID INT NOT NULL CONSTRAINT FK_Sections_Course FOREIGN KEY REFERENCES Courses(CourseID) ON DELETE CASCADE ON UPDATE CASCADE,
    SectionName NVARCHAR(5) NOT NULL,
    Semester NVARCHAR(10) CHECK (Semester IN ('Fall', 'Spring', 'Summer')),
    Year INT CHECK (Year >= 2020),
    FacultyID INT NULL CONSTRAINT FK_Sections_Faculty FOREIGN KEY REFERENCES Faculty(FacultyID) ON DELETE SET NULL ON UPDATE CASCADE,
    Capacity INT CHECK (Capacity > 0) DEFAULT 50,
    EnrolledCount INT CHECK (EnrolledCount >= 0) DEFAULT 0,
    RoomNo NVARCHAR(20) NOT NULL,
    CONSTRAINT UQ_Section UNIQUE(CourseID, SectionName, Semester, Year)
);
GO
-- 8. Enrollments Table
-- Maps students to sections they are enrolled in.
CREATE TABLE Enrollments (
    EnrollmentID INT PRIMARY KEY IDENTITY(1,1),
    StudentID INT NOT NULL CONSTRAINT FK_Enrollments_Student FOREIGN KEY REFERENCES Students(StudentID) ON DELETE CASCADE ON UPDATE CASCADE,
    SectionID INT NOT NULL CONSTRAINT FK_Enrollments_Section FOREIGN KEY REFERENCES Sections(SectionID) ON DELETE CASCADE ON UPDATE CASCADE,
    EnrollDate DATE DEFAULT GETDATE(),
    Status NVARCHAR(20) CHECK (Status IN ('Enrolled', 'Dropped', 'Completed', 'Failed')) DEFAULT 'Enrolled',
    CONSTRAINT UQ_Enrollment UNIQUE(StudentID, SectionID)
);
GO
-- 9. Grades Table
-- Stores academic grade results. 1:1 relation with Enrollments.
CREATE TABLE Grades (
    GradeID INT PRIMARY KEY IDENTITY(1,1),
    EnrollmentID INT NOT NULL UNIQUE CONSTRAINT FK_Grades_Enrollment FOREIGN KEY REFERENCES Enrollments(EnrollmentID) ON DELETE CASCADE ON UPDATE CASCADE,
    GradeValue VARCHAR(2) CHECK (GradeValue IN ('A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'F', 'I', 'W')),
    Marks INT CHECK (Marks BETWEEN 0 AND 100),
    Status NVARCHAR(20) CHECK (Status IN ('Draft', 'Submitted', 'Approved')) DEFAULT 'Draft'
);
GO
-- 10. AttendanceRecords Table
-- Stores daily student attendance for enrolled sections.
CREATE TABLE AttendanceRecords (
    AttendanceID INT PRIMARY KEY IDENTITY(1,1),
    EnrollmentID INT NOT NULL CONSTRAINT FK_Attendance_Enrollment FOREIGN KEY REFERENCES Enrollments(EnrollmentID) ON DELETE CASCADE ON UPDATE CASCADE,
    Date DATE NOT NULL,
    Status CHAR(1) CHECK (Status IN ('P', 'A', 'L', 'E')), -- Present, Absent, Late, Excused
    Remarks NVARCHAR(100) NULL,
    CONSTRAINT UQ_Attendance UNIQUE(EnrollmentID, Date)
);
GO
-- 11. FeeStructure Table
-- Stores fee structure schedules per Program and Semester.
CREATE TABLE FeeStructure (
    FeeStructureID INT PRIMARY KEY IDENTITY(1,1),
    ProgramID INT NOT NULL CONSTRAINT FK_FeeStructure_Program FOREIGN KEY REFERENCES Programs(ProgramID) ON DELETE CASCADE ON UPDATE CASCADE,
    Semester INT CHECK (Semester BETWEEN 1 AND 10),
    TuitionFee DECIMAL(10,2) CHECK (TuitionFee >= 0.00),
    AdmissionFee DECIMAL(10,2) CHECK (AdmissionFee >= 0.00) DEFAULT 0.00,
    LibraryFee DECIMAL(10,2) CHECK (LibraryFee >= 0.00) DEFAULT 0.00,
    HostelFee DECIMAL(10,2) CHECK (HostelFee >= 0.00) DEFAULT 0.00,
    TotalAmount AS (TuitionFee + AdmissionFee + LibraryFee + HostelFee) PERSISTED,
    CONSTRAINT UQ_FeeStructure UNIQUE(ProgramID, Semester)
);
GO
-- 12. FeePayments Table
-- Stores details of student fee processing. BankAccount is encrypted.
CREATE TABLE FeePayments (
    PaymentID INT PRIMARY KEY IDENTITY(1,1),
    StudentID INT NOT NULL CONSTRAINT FK_FeePayments_Student FOREIGN KEY REFERENCES Students(StudentID) ON DELETE NO ACTION ON UPDATE CASCADE,
    FeeStructureID INT NOT NULL CONSTRAINT FK_FeePayments_Structure FOREIGN KEY REFERENCES FeeStructure(FeeStructureID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    AmountPaid DECIMAL(10,2) CHECK (AmountPaid > 0.00),
    PaymentDate DATETIME DEFAULT GETDATE(),
    PaymentMethod NVARCHAR(50) CHECK (PaymentMethod IN ('Bank Transfer', 'Credit Card', 'Cash', 'Challan')),
    TransactionID NVARCHAR(100) NOT NULL UNIQUE,
    BankAccount VARBINARY(256) NOT NULL, -- Encrypted Column
    Status NVARCHAR(20) CHECK (Status IN ('Pending', 'Approved', 'Rejected')) DEFAULT 'Approved'
);
GO
-- 13. LibraryItems Table
-- Stores library books and journals. Location designates physical shelf.
CREATE TABLE LibraryItems (
    ItemID INT PRIMARY KEY IDENTITY(1,1),
    Title NVARCHAR(200) NOT NULL,
    Author NVARCHAR(100) NOT NULL,
    Type NVARCHAR(20) CHECK (Type IN ('Book', 'Journal', 'Thesis', 'Research Paper')),
    Publisher NVARCHAR(100) NULL,
    ISBN NVARCHAR(20) NULL UNIQUE,
    CopiesAvailable INT CHECK (CopiesAvailable >= 0),
    TotalCopies INT CHECK (TotalCopies > 0),
    Location NVARCHAR(50) NOT NULL,
    CONSTRAINT CK_Copies CHECK (CopiesAvailable <= TotalCopies)
);
GO
-- 14. LibraryIssues Table
-- Tracks issuance of library assets.
CREATE TABLE LibraryIssues (
    IssueID INT PRIMARY KEY IDENTITY(1,1),
    StudentID INT NOT NULL CONSTRAINT FK_LibraryIssues_Student FOREIGN KEY REFERENCES Students(StudentID) ON DELETE CASCADE ON UPDATE CASCADE,
    ItemID INT NOT NULL CONSTRAINT FK_LibraryIssues_Item FOREIGN KEY REFERENCES LibraryItems(ItemID) ON DELETE CASCADE ON UPDATE CASCADE,
    IssueDate DATE DEFAULT GETDATE(),
    DueDate DATE NOT NULL,
    ReturnDate DATE NULL,
    FinePaid DECIMAL(10,2) CHECK (FinePaid >= 0.00) DEFAULT 0.00,
    Status NVARCHAR(20) CHECK (Status IN ('Issued', 'Returned', 'Overdue')) DEFAULT 'Issued',
    CONSTRAINT CK_DueDate CHECK (DueDate >= IssueDate),
    CONSTRAINT CK_ReturnDate CHECK (ReturnDate IS NULL OR ReturnDate >= IssueDate)
);
GO
-- 15. Hostels Table
-- Stores hostel accommodation structures.
CREATE TABLE Hostels (
    HostelID INT PRIMARY KEY IDENTITY(1,1),
    HostelName NVARCHAR(100) NOT NULL UNIQUE,
    Type NVARCHAR(10) CHECK (Type IN ('Boys', 'Girls')),
    TotalRooms INT CHECK (TotalRooms > 0),
    Capacity INT CHECK (Capacity > 0),
    Status NVARCHAR(20) CHECK (Status IN ('Active', 'Under Maintenance', 'Full')) DEFAULT 'Active'
);
GO
-- 16. HostelAllotments Table
-- Maps students to their hostelled rooms.
CREATE TABLE HostelAllotments (
    AllotmentID INT PRIMARY KEY IDENTITY(1,1),
    StudentID INT NOT NULL UNIQUE CONSTRAINT FK_HostelAllotments_Student FOREIGN KEY REFERENCES Students(StudentID) ON DELETE CASCADE ON UPDATE CASCADE,
    HostelID INT NOT NULL CONSTRAINT FK_HostelAllotments_Hostel FOREIGN KEY REFERENCES Hostels(HostelID) ON DELETE CASCADE ON UPDATE CASCADE,
    RoomNo NVARCHAR(10) NOT NULL,
    AllotmentDate DATE DEFAULT GETDATE(),
    Status NVARCHAR(20) CHECK (Status IN ('Active', 'Vacated')) DEFAULT 'Active'
);
GO
-- 17. ExamSchedule Table
-- Stores upcoming exam schedules.
CREATE TABLE ExamSchedule (
    ExamScheduleID INT PRIMARY KEY IDENTITY(1,1),
    CourseID INT NOT NULL CONSTRAINT FK_ExamSchedule_Course FOREIGN KEY REFERENCES Courses(CourseID) ON DELETE CASCADE ON UPDATE CASCADE,
    ExamDate DATE NOT NULL,
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL,
    RoomNo NVARCHAR(20) NOT NULL,
    CONSTRAINT UQ_ExamSchedule UNIQUE(CourseID, ExamDate),
    CONSTRAINT CK_ExamTime CHECK (EndTime > StartTime)
);
GO
-- 18. Results Table
-- Stores final calculated semester results.
CREATE TABLE Results (
    ResultID INT PRIMARY KEY IDENTITY(1,1),
    StudentID INT NOT NULL CONSTRAINT FK_Results_Student FOREIGN KEY REFERENCES Students(StudentID) ON DELETE CASCADE ON UPDATE CASCADE,
    Semester INT CHECK (Semester BETWEEN 1 AND 10),
    GPA DECIMAL(3,2) CHECK (GPA BETWEEN 0.00 AND 4.00) DEFAULT 0.00,
    CreditsEarned INT CHECK (CreditsEarned >= 0) DEFAULT 0,
    Status NVARCHAR(20) CHECK (Status IN ('Passed', 'Failed', 'Incomplete')) DEFAULT 'Incomplete',
    CONSTRAINT UQ_Results UNIQUE(StudentID, Semester)
);
GO
-- 19. UserAccounts Table
-- Stores system login accounts mapped to role hierarchies.
CREATE TABLE UserAccounts (
    UserID INT PRIMARY KEY IDENTITY(1,1),
    Email NVARCHAR(100) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(256) NOT NULL,
    Role NVARCHAR(20) CHECK (Role IN ('Admin', 'Student', 'Faculty', 'Finance')),
    StudentID INT NULL UNIQUE CONSTRAINT FK_UserAccounts_Student FOREIGN KEY REFERENCES Students(StudentID) ON DELETE SET NULL,
    FacultyID INT NULL UNIQUE CONSTRAINT FK_UserAccounts_Faculty FOREIGN KEY REFERENCES Faculty(FacultyID) ON DELETE SET NULL,
    StaffID INT NULL UNIQUE CONSTRAINT FK_UserAccounts_Staff FOREIGN KEY REFERENCES Staff(StaffID) ON DELETE SET NULL,
    IsActive BIT DEFAULT 1,
    CONSTRAINT CK_UserLink CHECK (
        (StudentID IS NOT NULL AND FacultyID IS NULL AND StaffID IS NULL) OR
        (StudentID IS NULL AND FacultyID IS NOT NULL AND StaffID IS NULL) OR
        (StudentID IS NULL AND FacultyID IS NULL AND StaffID IS NOT NULL) OR
        (StudentID IS NULL AND FacultyID IS NULL AND StaffID IS NULL) -- Admin has no link
    )
);
GO
-- 20. AuditLog Table
-- Audits data updates (INSERT, UPDATE, DELETE).
CREATE TABLE AuditLog (
    AuditLogID INT PRIMARY KEY IDENTITY(1,1),
    TableName NVARCHAR(100) NOT NULL,
    ActionType NVARCHAR(10) CHECK (ActionType IN ('INSERT', 'UPDATE', 'DELETE')),
    OldValues NVARCHAR(MAX) NULL, -- JSON formatted string
    NewValues NVARCHAR(MAX) NULL, -- JSON formatted string
    ChangedBy NVARCHAR(100) DEFAULT SYSTEM_USER,
    ChangedAt DATETIME DEFAULT GETDATE()
);
GO
