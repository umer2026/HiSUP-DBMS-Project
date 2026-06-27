using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using HiSUP.Data;
using System.Linq;
namespace HiSUP.Controllers
{
    [Authorize]
    public class LibraryController : Controller
    {
        private readonly HiSUPContext _context;
        public LibraryController(HiSUPContext context)
        {
            _context = context;
        }
        [HttpGet]
        public async Task<IActionResult> Index(string search = null)
        {
            var items = _context.LibraryItems.AsQueryable();
            if (!string.IsNullOrEmpty(search))
            {
                // Utilize SQL Server native Full-Text Search via EF.Functions.Contains
                // It searches for the word or phrase in the Title and Author columns
                items = items.Where(l => EF.Functions.Contains(l.Title, search) || EF.Functions.Contains(l.Author, search));
            }
            var results = await items.ToListAsync();
            ViewBag.SearchTerm = search;
            return View(results);
        }
    }
}
