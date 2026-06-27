using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using HiSUP.Models;

namespace HiSUP.Controllers;

public class HomeController : Controller
{
    public IActionResult Index()
    {
        if (User.Identity != null && User.Identity.IsAuthenticated)
        {
            if (User.IsInRole("Admin")) return RedirectToAction("Index", "Admin");
            if (User.IsInRole("Student")) return RedirectToAction("Index", "Student");
            if (User.IsInRole("Faculty")) return RedirectToAction("Index", "Faculty");
            if (User.IsInRole("Finance")) return RedirectToAction("Index", "Finance");
        }
        return View();
    }

    public IActionResult Privacy()
    {
        return View();
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}
