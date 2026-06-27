namespace HiSUP.Models
{
    public class TranscriptEntryDto
    {
        public string CourseCode { get; set; }
        public string CourseTitle { get; set; }
        public int Credits { get; set; }
        public string GradeValue { get; set; }
        public int Marks { get; set; }
        public string Semester { get; set; }
        public int Year { get; set; }
        public decimal GradePoints { get; set; }
        public decimal SemGPA { get; set; }
    }
    public class StudentReportDto
    {
        public int StudentID { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Email { get; set; }
        public string ProgramName { get; set; }
        public int CurrentSemester { get; set; }
        public decimal CGPA { get; set; }
        public string EnrollmentStatus { get; set; }
        public decimal OutstandingFee { get; set; }
        public decimal OverallAttendancePercentage { get; set; }
    }
    public class FacultyWorkloadDto
    {
        public int FacultyID { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string DeptName { get; set; }
        public int TotalSectionsTaught { get; set; }
        public int TotalStudentsTaught { get; set; }
        public long DeptWorkloadRank { get; set; }
    }
}