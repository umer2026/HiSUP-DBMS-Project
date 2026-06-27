using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using HiSUP.Data;
using HiSUP.Models;
using HiSUP.Services;
namespace HiSUP.Controllers
{
    [Authorize(Roles = "Faculty")]
    public class FacultyController : Controller
    {
        private readonly HiSUPContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly AdoNetDbService _adoService;
        public FacultyController(
            HiSUPContext context,
            UserManager<ApplicationUser> userManager,
            AdoNetDbService adoService)
        {
            _context = context;
            _userManager = userManager;
            _adoService = adoService;
        }
        private async Task<int> GetCurrentFacultyID()
        {
            var user = await _userManager.GetUserAsync(User);
            if (user == null || user.FacultyID == null)
            {
                throw new Exception("Faculty ID not linked to this account.");
            }
            return user.FacultyID.Value;
        }
        public async Task<IActionResult> Index()
        {
            try
            {
                int facultyId = await GetCurrentFacultyID();

                // Fetch workload and sections from vw_FacultyCourseLoad view
                var workload = await _context.Database
                    .SqlQueryRaw<vw_FacultyCourseLoadDto>(
                        "SELECT * FROM vw_FacultyCourseLoad WHERE FacultyID = {0}", facultyId)
                    .ToListAsync();
                return View(workload);
            }
            catch (Exception ex)
            {
                TempData["Error"] = ex.Message;
                return RedirectToAction("Login", "Auth");
            }
        }
        [HttpGet]
        public async Task<IActionResult> MarkAttendance(int sectionId)
        {
            var students = await _context.Enrollments
                .Include(e => e.Student)
                .Where(e => e.SectionID == sectionId && e.Status == "Enrolled")
                .ToListAsync();
            ViewBag.SectionID = sectionId;
            return View(students);
        }
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SubmitAttendance(int sectionId, DateTime date, List<AttendanceRecordInput> attendanceList)
        {
            try
            {
                // Create DataTable matching SQL AttendanceTableType
                var dt = new DataTable();
                dt.Columns.Add("EnrollmentID", typeof(int));
                dt.Columns.Add("AttendanceDate", typeof(DateTime));
                dt.Columns.Add("Status", typeof(string));
                dt.Columns.Add("Remarks", typeof(string));
                foreach (var item in attendanceList)
                {
                    dt.Rows.Add(item.EnrollmentID, date.Date, item.Status, item.Remarks);
                }
                var connString = _context.Database.GetDbConnection().ConnectionString;
                using (var conn = new SqlConnection(connString))
                {
                    await conn.OpenAsync();
                    using (var cmd = new SqlCommand("MarkAttendance", conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        var tvpParam = cmd.Parameters.AddWithValue("@AttendanceList", dt);
                        tvpParam.SqlDbType = SqlDbType.Structured;
                        tvpParam.TypeName = "dbo.AttendanceTableType";
                        await cmd.ExecuteNonQueryAsync();
                    }
                }
                TempData["Success"] = "Attendance submitted successfully!";
                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                TempData["Error"] = ex.Message;
                return RedirectToAction("MarkAttendance", new { sectionId });
            }
        }
        [HttpGet]
        public async Task<IActionResult> GradeEntry(int sectionId)
        {
            var enrollments = await _context.Enrollments
                .Include(e => e.Student)
                .Include(e => e.Grade)
                .Where(e => e.SectionID == sectionId)
                .ToListAsync();
            ViewBag.SectionID = sectionId;
            return View(enrollments);
        }
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SubmitGrades(int sectionId, List<GradeRecordInput> gradeList)
        {
            try
            {
                // Create DataTable matching GradeImportTableType
                var dt = new DataTable();
                dt.Columns.Add("EnrollmentID", typeof(int));
                dt.Columns.Add("Marks", typeof(int));
                dt.Columns.Add("GradeValue", typeof(string));
                dt.Columns.Add("Status", typeof(string));
                foreach (var item in gradeList)
                {
                    // Call function to determine letter grade (can simulate locally for UI, but merge procedure recalculates or uses it)
                    string gradeValue = DetermineLetterGrade(item.Marks);
                    dt.Rows.Add(item.EnrollmentID, item.Marks, gradeValue, "Submitted");
                }
                var connString = _context.Database.GetDbConnection().ConnectionString;
                using (var conn = new SqlConnection(connString))
                {
                    await conn.OpenAsync();
                    using (var cmd = new SqlCommand("ImportBulkGrades", conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        var tvpParam = cmd.Parameters.AddWithValue("@GradeList", dt);
                        tvpParam.SqlDbType = SqlDbType.Structured;
                        tvpParam.TypeName = "dbo.GradeImportTableType";
                        await cmd.ExecuteNonQueryAsync();
                    }
                }
                TempData["Success"] = "Grades submitted/merged successfully!";
                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                TempData["Error"] = ex.Message;
                return RedirectToAction("GradeEntry", new { sectionId });
            }
        }
        private string DetermineLetterGrade(int marks)
        {
            if (marks >= 90) return "A+";
            if (marks >= 85) return "A";
            if (marks >= 80) return "A-";
            if (marks >= 75) return "B+";
            if (marks >= 70) return "B";
            if (marks >= 65) return "B-";
            if (marks >= 60) return "C+";
            if (marks >= 55) return "C";
            if (marks >= 50) return "C-";
            if (marks >= 45) return "D+";
            if (marks >= 40) return "D";
            return "F";
        }
    }
    public class vw_FacultyCourseLoadDto
    {
        public int FacultyID { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Designation { get; set; }
        public int SectionID { get; set; }
        public string SectionName { get; set; }
        public string CourseCode { get; set; }
        public string CourseTitle { get; set; }
        public string Semester { get; set; }
        public int Year { get; set; }
        public string RoomNo { get; set; }
        public int Capacity { get; set; }
        public int EnrolledCount { get; set; }
    }
    public class AttendanceRecordInput
    {
        public int EnrollmentID { get; set; }
        public string Status { get; set; }
        public string Remarks { get; set; }
    }
    public class GradeRecordInput
    {
        public int EnrollmentID { get; set; }
        public int Marks { get; set; }
    }
}