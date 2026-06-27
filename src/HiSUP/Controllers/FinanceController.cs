using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using HiSUP.Data;
using System.Linq;
namespace HiSUP.Controllers
{
    [Authorize(Roles = "Finance")]
    public class FinanceController : Controller
    {
        private readonly HiSUPContext _context;
        public FinanceController(HiSUPContext context)
        {
            _context = context;
        }
        public async Task<IActionResult> Index()
        {
            // Summarize payment aggregates
            ViewBag.TotalReceived = await _context.FeePayments
                .Where(p => p.Status == "Approved")
                .SumAsync(p => (decimal?)p.AmountPaid) ?? 0.00m;
            ViewBag.PendingPayments = await _context.FeePayments
                .Where(p => p.Status == "Pending")
                .CountAsync();
            return View();
        }
        [HttpGet]
        public async Task<IActionResult> Defaulters()
        {
            // Load fee defaulters from vw_FeeDefaulters view
            var defaulters = await _context.Database
                .SqlQueryRaw<vw_FeeDefaultersDto>("SELECT * FROM vw_FeeDefaulters")
                .ToListAsync();
            return View(defaulters);
        }
    }
    public class vw_FeeDefaultersDto
    {
        public int StudentID { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Email { get; set; }
        public string ProgramName { get; set; }
        public int CurrentSemester { get; set; }
        public decimal OutstandingAmount { get; set; }
    }
}
