using System.Threading.Tasks;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using HiSUP.Models;
using HiSUP.Services;
using System;
namespace HiSUP.Controllers
{
    public class AuthController : Controller
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly SignInManager<ApplicationUser> _signInManager;
        private readonly AdoNetDbService _adoService;
        public AuthController(
            UserManager<ApplicationUser> userManager,
            SignInManager<ApplicationUser> signInManager,
            AdoNetDbService adoService)
        {
            _userManager = userManager;
            _signInManager = signInManager;
            _adoService = adoService;
        }
        [HttpGet]
        public IActionResult Login()
        {
            return View();
        }
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Login(string email, string password)
        {
            if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(password))
            {
                ModelState.AddModelError("", "Email and password are required.");
                return View();
            }
            var user = await _userManager.FindByEmailAsync(email);
            if (user != null && user.IsActive)
            {
                var result = await _signInManager.PasswordSignInAsync(user, password, false, false);
                if (result.Succeeded)
                {
                    var roles = await _userManager.GetRolesAsync(user);
                    if (roles.Contains("Admin"))
                        return RedirectToAction("Index", "Admin");
                    if (roles.Contains("Student"))
                        return RedirectToAction("Index", "Student");
                    if (roles.Contains("Faculty"))
                        return RedirectToAction("Index", "Faculty");
                    if (roles.Contains("Finance"))
                        return RedirectToAction("Index", "Finance");
                    return RedirectToAction("Index", "Home");
                }
            }
            ModelState.AddModelError("", "Invalid login attempt.");
            return View();
        }
        [HttpGet]
        public IActionResult Register()
        {
            return View();
        }
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Register(
            string firstName,
            string lastName,
            string email,
            string phone,
            string cnic,
            DateTime dob,
            int programId,
            string password)
        {
            try
            {
                // Create student and user account via secure ADO.NET transaction (stored procedure RegisterStudent)
                // This hashes password and saves everything
                var hasher = new PasswordHasher<ApplicationUser>();
                var simulatedUser = new ApplicationUser { UserName = email, Email = email };
                string passwordHash = hasher.HashPassword(simulatedUser, password);
                int studentId = await _adoService.RegisterStudentAsync(
                    firstName,
                    lastName,
                    email,
                    phone,
                    cnic,
                    dob,
                    programId,
                    passwordHash
                );
                // Load user and add to role Student
                var user = await _userManager.FindByEmailAsync(email);
                if (user != null)
                {
                    await _userManager.AddToRoleAsync(user, "Student");
                }
                TempData["Success"] = "Registration successful! Please login.";
                return RedirectToAction("Login");
            }
            catch (Exception ex)
            {
                ModelState.AddModelError("", ex.Message);
                return View();
            }
        }
        [HttpPost]
        public async Task<IActionResult> Logout()
        {
            await _signInManager.SignOutAsync();
            return RedirectToAction("Login");
        }
    }
}
