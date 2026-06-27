using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using HiSUP.Data;
using HiSUP.Models;
using HiSUP.Services;
namespace HiSUP.Controllers
{
    [Authorize(Roles = "Student")]
    public class StudentController : Controller
    {
        private readonly HiSUPContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly AdoNetDbService _adoService;
        public StudentController(
            HiSUPContext context,
            UserManager<ApplicationUser> userManager,
            AdoNetDbService adoService)
        {
            _context = context;
            _userManager = userManager;
            _adoService = adoService;
        }
        private async Task<int> GetCurrentStudentID()
        {
            var user = await _userManager.GetUserAsync(User);
            if (user == null || user.StudentID == null)
            {
                throw new Exception("Student ID not linked to this account.");
            }
            return user.StudentID.Value;
        }
        public async Task<IActionResult> Index()
        {
            try
            {
                int studentId = await GetCurrentStudentID();

                // Fetch student dashboard view details (we can filter on StudentID)
                var dashboardData = await _context.Database
                    .SqlQueryRaw<vw_StudentDashboardDto>(
                        "SELECT * FROM vw_StudentDashboard WHERE StudentID = {0}", studentId)
                    .FirstOrDefaultAsync();
                return View(dashboardData);
            }
            catch (Exception ex)
            {
                TempData["Error"] = ex.Message;
                return RedirectToAction("Login", "Auth");
            }
        }
        [HttpGet]
        public async Task<IActionResult> CourseRegistration()
        {
            int studentId = await GetCurrentStudentID();
            // Get available sections for student program
            var student = await _context.Students.FindAsync(studentId);
            var sections = await _context.Sections
                .Include(s => s.Course)
                .Include(s => s.Faculty)
                .ToListAsync();
            return View(sections);
        }
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Enroll(int sectionId)
        {
            try
            {
                int studentId = await GetCurrentStudentID();
                // Call stored procedure EnrollInCourse via ADO.NET
                await _adoService.EnrollInCourseAsync(studentId, sectionId);
                TempData["Success"] = "Successfully enrolled in course!";
            }
            catch (Exception ex)
            {
                TempData["Error"] = ex.Message;
            }
            return RedirectToAction("CourseRegistration");
        }
        [HttpGet]
        public async Task<IActionResult> Payments()
        {
            int studentId = await GetCurrentStudentID();
            var student = await _context.Students.Include(s => s.Program).FirstOrDefaultAsync(s => s.StudentID == studentId);

            // Get fee payments
            var payments = await _context.FeePayments
                .Include(fp => fp.FeeStructure)
                .Where(fp => fp.StudentID == studentId)
                .ToListAsync();
            // Get fee structures for program
            var structures = await _context.FeeStructures
                .Where(fs => fs.ProgramID == student.ProgramID)
                .ToListAsync();
            ViewBag.FeeStructures = structures;
            return View(payments);
        }
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> PayFee(int feeStructureId, decimal amount, string paymentMethod, string bankAccount)
        {
            try
            {
                int studentId = await GetCurrentStudentID();
                string transactionId = "TXN-" + Guid.NewGuid().ToString().Substring(0, 8).ToUpper();
                // Call stored procedure ProcessFeePayment via ADO.NET
                await _adoService.ProcessFeePaymentAsync(
                    studentId,
                    feeStructureId,
                    amount,
                    paymentMethod,
                    transactionId,
                    bankAccount
                );
                TempData["Success"] = "Fee payment processed successfully!";
            }
            catch (Exception ex)
            {
                TempData["Error"] = ex.Message;
            }
            return RedirectToAction("Payments");
        }
        [HttpGet]
        public async Task<IActionResult> Transcript()
        {
            try
            {
                int studentId = await GetCurrentStudentID();
                // Call stored procedure GenerateTranscript via ADO.NET
                var transcriptEntries = await _adoService.GenerateTranscriptAsync(studentId);
                return View(transcriptEntries);
            }
            catch (Exception ex)
            {
                TempData["Error"] = ex.Message;
                return RedirectToAction("Index");
            }
        }
    }
    // Helper DTO class to read SQL execution details of vw_StudentDashboard
    public class vw_StudentDashboardDto
    {
        public int StudentID { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Email { get; set; }
        public string ProgramName { get; set; }
        public int CurrentSemester { get; set; }
        public decimal CGPA { get; set; }
        public string Status { get; set; }
        public decimal OutstandingFee { get; set; }
        public decimal AttendancePercentage { get; set; }
    }
}
