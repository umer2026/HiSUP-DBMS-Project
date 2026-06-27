using Microsoft.AspNetCore.Identity;
namespace HiSUP.Models
{
    public class ApplicationUser : IdentityUser<int>
    {
        public int? StudentID { get; set; }
        public int? FacultyID { get; set; }
        public int? StaffID { get; set; }
        public bool IsActive { get; set; } = true;
        public Student Student { get; set; }
        public Faculty Faculty { get; set; }
        public Staff Staff { get; set; }
    }
}