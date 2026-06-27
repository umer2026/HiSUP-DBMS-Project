using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
namespace HiSUP.Models
{
    public class Department
    {
        public int DepartmentID { get; set; }
        public string DeptName { get; set; }
        public string DeptCode { get; set; }
        public int EstablishedYear { get; set; }
        public DateTime CreatedAt { get; set; }
        public ICollection<AcademicProgram> Programs { get; set; }
        public ICollection<Faculty> Faculty { get; set; }
        public ICollection<Course> Courses { get; set; }
    }
    public class AcademicProgram
    {
        public int ProgramID { get; set; }
        public string ProgramName { get; set; }
        public int DeptID { get; set; }
        public int DurationYears { get; set; }
        public string DegreeLevel { get; set; }
        public Department Department { get; set; }
        public ICollection<Student> Students { get; set; }
        public ICollection<FeeStructure> FeeStructures { get; set; }
    }
    public class Student
    {
        public int StudentID { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Email { get; set; }
        public string Phone { get; set; }
        public byte[] CNIC { get; set; } // Encrypted binary representation
        public DateTime DateOfBirth { get; set; }
        public DateTime EnrollDate { get; set; }
        public int ProgramID { get; set; }
        public int CurrentSemester { get; set; }
        public decimal CGPA { get; set; }
        public string Status { get; set; }
        public AcademicProgram Program { get; set; }
        public ICollection<Enrollment> Enrollments { get; set; }
        public ICollection<FeePayment> FeePayments { get; set; }
        public ICollection<LibraryIssue> LibraryIssues { get; set; }
        public HostelAllotment HostelAllotment { get; set; }
        public ICollection<Result> Results { get; set; }
    }
    public class Faculty
    {
        public int FacultyID { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Email { get; set; }
        public string Phone { get; set; }
        public int DeptID { get; set; }
        public string Designation { get; set; }
        public DateTime HireDate { get; set; }
        public decimal Salary { get; set; }
        public string Status { get; set; }
        public Department Department { get; set; }
        public ICollection<Section> Sections { get; set; }
    }
    public class Staff
    {
        public int StaffID { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Email { get; set; }
        public string Phone { get; set; }
        public string Role { get; set; }
        public decimal Salary { get; set; }
        public string Status { get; set; }
    }
    public class Course
    {
        public int CourseID { get; set; }
        public string CourseCode { get; set; }
        public string CourseTitle { get; set; }
        public int Credits { get; set; }
        public int DeptID { get; set; }
        public int? PrerequisiteCourseID { get; set; }
        public Department Department { get; set; }
        public Course Prerequisite { get; set; }
        public ICollection<Section> Sections { get; set; }
        public ICollection<ExamSchedule> ExamSchedules { get; set; }
    }
    public class Section
    {
        public int SectionID { get; set; }
        public int CourseID { get; set; }
        public string SectionName { get; set; }
        public string Semester { get; set; }
        public int Year { get; set; }
        public int? FacultyID { get; set; }
        public int Capacity { get; set; }
        public int EnrolledCount { get; set; }
        public string RoomNo { get; set; }
        public Course Course { get; set; }
        public Faculty Faculty { get; set; }
        public ICollection<Enrollment> Enrollments { get; set; }
    }
    public class Enrollment
    {
        public int EnrollmentID { get; set; }
        public int StudentID { get; set; }
        public int SectionID { get; set; }
        public DateTime EnrollDate { get; set; }
        public string Status { get; set; }
        public Student Student { get; set; }
        public Section Section { get; set; }
        public Grade Grade { get; set; }
        public ICollection<AttendanceRecord> AttendanceRecords { get; set; }
    }
    public class Grade
    {
        public int GradeID { get; set; }
        public int EnrollmentID { get; set; }
        public string GradeValue { get; set; }
        public int Marks { get; set; }
        public string Status { get; set; }
        public Enrollment Enrollment { get; set; }
    }
    public class AttendanceRecord
    {
        public int AttendanceID { get; set; }
        public int EnrollmentID { get; set; }
        public DateTime Date { get; set; }
        public string Status { get; set; }
        public string Remarks { get; set; }
        public Enrollment Enrollment { get; set; }
    }
    public class FeeStructure
    {
        public int FeeStructureID { get; set; }
        public int ProgramID { get; set; }
        public int Semester { get; set; }
        public decimal TuitionFee { get; set; }
        public decimal AdmissionFee { get; set; }
        public decimal LibraryFee { get; set; }
        public decimal HostelFee { get; set; }
        public decimal TotalAmount { get; private set; } // Database computed field
        public AcademicProgram Program { get; set; }
        public ICollection<FeePayment> FeePayments { get; set; }
    }
    public class FeePayment
    {
        public int PaymentID { get; set; }
        public int StudentID { get; set; }
        public int FeeStructureID { get; set; }
        public decimal AmountPaid { get; set; }
        public DateTime PaymentDate { get; set; }
        public string PaymentMethod { get; set; }
        public string TransactionID { get; set; }
        public byte[] BankAccount { get; set; } // Encrypted binary representation
        public string Status { get; set; }
        public Student Student { get; set; }
        public FeeStructure FeeStructure { get; set; }
    }
    public class LibraryItem
    {
        public int ItemID { get; set; }
        public string Title { get; set; }
        public string Author { get; set; }
        public string Type { get; set; }
        public string Publisher { get; set; }
        public string ISBN { get; set; }
        public int CopiesAvailable { get; set; }
        public int TotalCopies { get; set; }
        public string Location { get; set; }
        public ICollection<LibraryIssue> LibraryIssues { get; set; }
    }
    public class LibraryIssue
    {
        public int IssueID { get; set; }
        public int StudentID { get; set; }
        public int ItemID { get; set; }
        public DateTime IssueDate { get; set; }
        public DateTime DueDate { get; set; }
        public DateTime? ReturnDate { get; set; }
        public decimal FinePaid { get; set; }
        public string Status { get; set; }
        public Student Student { get; set; }
        public LibraryItem LibraryItem { get; set; }
    }
    public class Hostel
    {
        public int HostelID { get; set; }
        public string HostelName { get; set; }
        public string Type { get; set; }
        public int TotalRooms { get; set; }
        public int Capacity { get; set; }
        public string Status { get; set; }
        public ICollection<HostelAllotment> HostelAllotments { get; set; }
    }
    public class HostelAllotment
    {
        public int AllotmentID { get; set; }
        public int StudentID { get; set; }
        public int HostelID { get; set; }
        public string RoomNo { get; set; }
        public DateTime AllotmentDate { get; set; }
        public string Status { get; set; }
        public Student Student { get; set; }
        public Hostel Hostel { get; set; }
    }
    public class ExamSchedule
    {
        public int ExamScheduleID { get; set; }
        public int CourseID { get; set; }
        public DateTime ExamDate { get; set; }
        public TimeSpan StartTime { get; set; }
        public TimeSpan EndTime { get; set; }
        public string RoomNo { get; set; }
        public Course Course { get; set; }
    }
    public class Result
    {
        public int ResultID { get; set; }
        public int StudentID { get; set; }
        public int Semester { get; set; }
        public decimal GPA { get; set; }
        public int CreditsEarned { get; set; }
        public string Status { get; set; }
        public Student Student { get; set; }
    }
    public class AuditLog
    {
        public int AuditLogID { get; set; }
        public string TableName { get; set; }
        public string ActionType { get; set; }
        public string OldValues { get; set; }
        public string NewValues { get; set; }
        public string ChangedBy { get; set; }
        public DateTime ChangedAt { get; set; }
    }
}
