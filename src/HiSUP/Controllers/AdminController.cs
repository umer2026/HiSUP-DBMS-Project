using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Data.SqlClient;
using HiSUP.Data;
using HiSUP.Models;
using System.Data;
namespace HiSUP.Controllers
{
    [Authorize(Roles = "Admin")]
    public class AdminController : Controller
    {
        private readonly HiSUPContext _context;
        public AdminController(HiSUPContext context)
        {
            _context = context;
        }
        public async Task<IActionResult> Index()
        {
            ViewBag.TotalStudents = await _context.Students.CountAsync();
            ViewBag.TotalFaculty = await _context.Faculty.CountAsync();
            ViewBag.TotalCourses = await _context.Courses.CountAsync();
            ViewBag.TotalAuditLogs = await _context.AuditLogs.CountAsync();
            return View();
        }
        [HttpGet]
        public async Task<IActionResult> Students(string searchTerm = null, int? programId = null, decimal? minCGPA = null, string status = null)
        {
            var pSearchTerm = new SqlParameter("@SearchTerm", (object)searchTerm ?? DBNull.Value);
            var pProgramID = new SqlParameter("@ProgramID", (object)programId ?? DBNull.Value);
            var pMinCGPA = new SqlParameter("@MinCGPA", (object)minCGPA ?? DBNull.Value);
            var pStatus = new SqlParameter("@Status", (object)status ?? DBNull.Value);
            // Execute dynamic search stored procedure
            var students = await _context.Database
                .SqlQueryRaw<StudentSearchResultDto>(
                    "EXEC SearchStudentsDynamic @SearchTerm, @ProgramID, @MinCGPA, @Status",
                    pSearchTerm, pProgramID, pMinCGPA, pStatus)
                .ToListAsync();
            ViewBag.Programs = await _context.Programs.ToListAsync();
            return View(students);
        }
        [HttpGet]
        public async Task<IActionResult> AuditLogs()
        {
            var logs = await _context.AuditLogs
                .OrderByDescending(l => l.ChangedAt)
                .Take(100)
                .ToListAsync();
            return View(logs);
        }
    }
    public class StudentSearchResultDto
    {
        public int StudentID { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Email { get; set; }
        public int ProgramID { get; set; }
        public decimal CGPA { get; set; }
        public string Status { get; set; }
    }
}
