using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using HiSUP.Models;
namespace HiSUP.Data
{
    public class HiSUPContext : IdentityDbContext<ApplicationUser, IdentityRole<int>, int>
    {
        public HiSUPContext(DbContextOptions<HiSUPContext> options)
            : base(options)
        {
        }
        public DbSet<Department> Departments { get; set; }
        public DbSet<AcademicProgram> Programs { get; set; }
        public DbSet<Student> Students { get; set; }
        public DbSet<Faculty> Faculty { get; set; }
        public DbSet<Staff> Staff { get; set; }
        public DbSet<Course> Courses { get; set; }
        public DbSet<Section> Sections { get; set; }
        public DbSet<Enrollment> Enrollments { get; set; }
        public DbSet<Grade> Grades { get; set; }
        public DbSet<AttendanceRecord> AttendanceRecords { get; set; }
        public DbSet<FeeStructure> FeeStructures { get; set; }
        public DbSet<FeePayment> FeePayments { get; set; }
        public DbSet<LibraryItem> LibraryItems { get; set; }
        public DbSet<LibraryIssue> LibraryIssues { get; set; }
        public DbSet<Hostel> Hostels { get; set; }
        public DbSet<HostelAllotment> HostelAllotments { get; set; }
        public DbSet<ExamSchedule> ExamSchedules { get; set; }
        public DbSet<Result> Results { get; set; }
        public DbSet<AuditLog> AuditLogs { get; set; }
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            // Configure Identity table name mapping to match UserAccounts
            modelBuilder.Entity<ApplicationUser>(entity =>
            {
                entity.ToTable("UserAccounts");
                entity.Property(u => u.Id).HasColumnName("UserID");
                entity.HasOne(u => u.Student)
                    .WithOne()
                    .HasForeignKey<ApplicationUser>(u => u.StudentID)
                    .OnDelete(DeleteBehavior.SetNull);
                entity.HasOne(u => u.Faculty)
                    .WithOne()
                    .HasForeignKey<ApplicationUser>(u => u.FacultyID)
                    .OnDelete(DeleteBehavior.SetNull);
                entity.HasOne(u => u.Staff)
                    .WithOne()
                    .HasForeignKey<ApplicationUser>(u => u.StaffID)
                    .OnDelete(DeleteBehavior.SetNull);
            });
            // Map standard Identity tables to cleaner names
            modelBuilder.Entity<IdentityRole<int>>().ToTable("Roles").Property(r => r.Id).HasColumnName("RoleID");
            modelBuilder.Entity<IdentityUserRole<int>>().ToTable("UserRoles");
            modelBuilder.Entity<IdentityUserClaim<int>>().ToTable("UserClaims");
            modelBuilder.Entity<IdentityUserLogin<int>>().ToTable("UserLogins");
            modelBuilder.Entity<IdentityRoleClaim<int>>().ToTable("RoleClaims");
            modelBuilder.Entity<IdentityUserToken<int>>().ToTable("UserTokens");
            // Departments Mapping
            modelBuilder.Entity<Department>(entity =>
            {
                entity.ToTable("Departments");
                entity.HasKey(e => e.DepartmentID);
                entity.HasIndex(e => e.DeptName).IsUnique();
                entity.HasIndex(e => e.DeptCode).IsUnique();
            });
            // Programs Mapping
            modelBuilder.Entity<AcademicProgram>(entity =>
            {
                entity.ToTable("Programs");
                entity.HasKey(e => e.ProgramID);
                entity.HasIndex(e => e.ProgramName).IsUnique();
                entity.HasOne(e => e.Department)
                    .WithMany(d => d.Programs)
                    .HasForeignKey(e => e.DeptID)
                    .OnDelete(DeleteBehavior.Cascade);
            });
            // Students Mapping
            modelBuilder.Entity<Student>(entity =>
            {
                entity.ToTable("Students");
                entity.HasKey(e => e.StudentID);
                entity.HasIndex(e => e.Email).IsUnique();
                entity.HasOne(e => e.Program)
                    .WithMany(p => p.Students)
                    .HasForeignKey(e => e.ProgramID)
                    .OnDelete(DeleteBehavior.Restrict);
            });
            // Faculty Mapping
            modelBuilder.Entity<Faculty>(entity =>
            {
                entity.ToTable("Faculty");
                entity.HasKey(e => e.FacultyID);
                entity.HasIndex(e => e.Email).IsUnique();
                entity.HasOne(e => e.Department)
                    .WithMany(d => d.Faculty)
                    .HasForeignKey(e => e.DeptID)
                    .OnDelete(DeleteBehavior.Restrict);
            });
            // Staff Mapping
            modelBuilder.Entity<Staff>(entity =>
            {
                entity.ToTable("Staff");
                entity.HasKey(e => e.StaffID);
                entity.HasIndex(e => e.Email).IsUnique();
            });
            // Courses Mapping
            modelBuilder.Entity<Course>(entity =>
            {
                entity.ToTable("Courses");
                entity.HasKey(e => e.CourseID);
                entity.HasIndex(e => e.CourseCode).IsUnique();
                entity.HasOne(e => e.Department)
                    .WithMany(d => d.Courses)
                    .HasForeignKey(e => e.DeptID)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(e => e.Prerequisite)
                    .WithMany()
                    .HasForeignKey(e => e.PrerequisiteCourseID)
                    .OnDelete(DeleteBehavior.Restrict);
            });
            // Sections Mapping
            modelBuilder.Entity<Section>(entity =>
            {
                entity.ToTable("Sections");
                entity.HasKey(e => e.SectionID);
                entity.HasIndex(e => new { e.CourseID, e.SectionName, e.Semester, e.Year }).IsUnique();
                entity.HasOne(e => e.Course)
                    .WithMany(c => c.Sections)
                    .HasForeignKey(e => e.CourseID)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(e => e.Faculty)
                    .WithMany(f => f.Sections)
                    .HasForeignKey(e => e.FacultyID)
                    .OnDelete(DeleteBehavior.SetNull);
            });
            // Enrollments Mapping
            modelBuilder.Entity<Enrollment>(entity =>
            {
                entity.ToTable("Enrollments");
                entity.HasKey(e => e.EnrollmentID);
                entity.HasIndex(e => new { e.StudentID, e.SectionID }).IsUnique();
                entity.HasOne(e => e.Student)
                    .WithMany(s => s.Enrollments)
                    .HasForeignKey(e => e.StudentID)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(e => e.Section)
                    .WithMany(sec => sec.Enrollments)
                    .HasForeignKey(e => e.SectionID)
                    .OnDelete(DeleteBehavior.Cascade);
            });
            // Grades Mapping
            modelBuilder.Entity<Grade>(entity =>
            {
                entity.ToTable("Grades");
                entity.HasKey(e => e.GradeID);
                entity.HasIndex(e => e.EnrollmentID).IsUnique();
                entity.HasOne(e => e.Enrollment)
                    .WithOne(en => en.Grade)
                    .HasForeignKey<Grade>(e => e.EnrollmentID)
                    .OnDelete(DeleteBehavior.Cascade);
            });
            // Attendance Mapping
            modelBuilder.Entity<AttendanceRecord>(entity =>
            {
                entity.ToTable("AttendanceRecords");
                entity.HasKey(e => e.AttendanceID);
                entity.HasIndex(e => new { e.EnrollmentID, e.Date }).IsUnique();
                entity.HasOne(e => e.Enrollment)
                    .WithMany(en => en.AttendanceRecords)
                    .HasForeignKey(e => e.EnrollmentID)
                    .OnDelete(DeleteBehavior.Cascade);
            });
            // Fee Structure Mapping
            modelBuilder.Entity<FeeStructure>(entity =>
            {
                entity.ToTable("FeeStructure");
                entity.HasKey(e => e.FeeStructureID);
                entity.HasIndex(e => new { e.ProgramID, e.Semester }).IsUnique();
                entity.Property(e => e.TotalAmount).HasComputedColumnSql("(([TuitionFee]+[AdmissionFee])+[LibraryFee])+[HostelFee]", stored: true);
                entity.HasOne(e => e.Program)
                    .WithMany(p => p.FeeStructures)
                    .HasForeignKey(e => e.ProgramID)
                    .OnDelete(DeleteBehavior.Cascade);
            });
            // Fee Payments Mapping
            modelBuilder.Entity<FeePayment>(entity =>
            {
                entity.ToTable("FeePayments");
                entity.HasKey(e => e.PaymentID);
                entity.HasIndex(e => e.TransactionID).IsUnique();
                entity.HasOne(e => e.Student)
                    .WithMany(s => s.FeePayments)
                    .HasForeignKey(e => e.StudentID)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(e => e.FeeStructure)
                    .WithMany(fs => fs.FeePayments)
                    .HasForeignKey(e => e.FeeStructureID)
                    .OnDelete(DeleteBehavior.Restrict);
            });
            // Library Items Mapping
            modelBuilder.Entity<LibraryItem>(entity =>
            {
                entity.ToTable("LibraryItems");
                entity.HasKey(e => e.ItemID);
                entity.HasIndex(e => e.ISBN).IsUnique();
            });
            // Library Issues Mapping
            modelBuilder.Entity<LibraryIssue>(entity =>
            {
                entity.ToTable("LibraryIssues");
                entity.HasKey(e => e.IssueID);
                entity.HasOne(e => e.Student)
                    .WithMany(s => s.LibraryIssues)
                    .HasForeignKey(e => e.StudentID)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(e => e.LibraryItem)
                    .WithMany(l => l.LibraryIssues)
                    .HasForeignKey(e => e.ItemID)
                    .OnDelete(DeleteBehavior.Cascade);
            });
            // Hostels Mapping
            modelBuilder.Entity<Hostel>(entity =>
            {
                entity.ToTable("Hostels");
                entity.HasKey(e => e.HostelID);
                entity.HasIndex(e => e.HostelName).IsUnique();
            });
            // Hostel Allotments Mapping
            modelBuilder.Entity<HostelAllotment>(entity =>
            {
                entity.ToTable("HostelAllotments");
                entity.HasKey(e => e.AllotmentID);
                entity.HasIndex(e => e.StudentID).IsUnique();
                entity.HasOne(e => e.Student)
                    .WithOne(s => s.HostelAllotment)
                    .HasForeignKey<HostelAllotment>(e => e.StudentID)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(e => e.Hostel)
                    .WithMany(h => h.HostelAllotments)
                    .HasForeignKey(e => e.HostelID)
                    .OnDelete(DeleteBehavior.Cascade);
            });
            // Exam Schedule Mapping
            modelBuilder.Entity<ExamSchedule>(entity =>
            {
                entity.ToTable("ExamSchedule");
                entity.HasKey(e => e.ExamScheduleID);
                entity.HasIndex(e => new { e.CourseID, e.ExamDate }).IsUnique();
                entity.HasOne(e => e.Course)
                    .WithMany(c => c.ExamSchedules)
                    .HasForeignKey(e => e.CourseID)
                    .OnDelete(DeleteBehavior.Cascade);
            });
            // Results Mapping
            modelBuilder.Entity<Result>(entity =>
            {
                entity.ToTable("Results");
                entity.HasKey(e => e.ResultID);
                entity.HasIndex(e => new { e.StudentID, e.Semester }).IsUnique();
                entity.HasOne(e => e.Student)
                    .WithMany(s => s.Results)
                    .HasForeignKey(e => e.StudentID)
                    .OnDelete(DeleteBehavior.Cascade);
            });
            // Audit Logs Mapping
            modelBuilder.Entity<AuditLog>(entity =>
            {
                entity.ToTable("AuditLog");
                entity.HasKey(e => e.AuditLogID);
            });
        }
    }
}
