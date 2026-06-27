using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using HiSUP.Data;
using HiSUP.Models;
using HiSUP.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllersWithViews();

builder.Services.AddDbContext<HiSUPContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("HiSUP_DB")));

builder.Services.AddIdentity<ApplicationUser, IdentityRole<int>>()
    .AddEntityFrameworkStores<HiSUPContext>()
    .AddDefaultTokenProviders();

// Register ADO.NET service
builder.Services.AddScoped<AdoNetDbService>();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();