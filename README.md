# HiSUP — HITEC Smart University Portal

**HITEC University | Advanced Database Management Systems**  
ASP.NET Core 10 MVC Web Application

---

## Project Structure

```
HITEC-ADMS-HiSUP-<RollNo>/
├── src/
│   └── HiSUP/                      # ASP.NET Core MVC Project
│       ├── Controllers/             # MVC Controllers
│       │   ├── AuthController.cs   # Login, Register, Logout
│       │   ├── AdminController.cs  # Admin panel + student search
│       │   ├── StudentController.cs# Dashboard, registration, payments, transcript
│       │   ├── FacultyController.cs# Course load, attendance, grade entry
│       │   ├── FinanceController.cs# Revenue stats, fee defaulters
│       │   ├── LibraryController.cs# Full-Text Search catalog
│       │   └── HomeController.cs   # Landing page
│       ├── Models/                  # Entity and DTO classes
│       │   ├── Entities.cs         # All EF Core entity models
│       │   ├── Dtos.cs             # Data transfer objects
│       │   └── ApplicationUser.cs  # ASP.NET Identity user
│       ├── Data/
│       │   └── HISUPContext.cs     # EF Core DbContext
│       ├── Services/
│       │   └── AdoNetDbService.cs  # ADO.NET stored procedure calls
│       ├── Views/                   # Razor Views (per controller)
│       │   ├── Admin/              # Index, Students, AuditLog
│       │   ├── Auth/               # Login, Register
│       │   ├── Faculty/            # Index, MarkAttendance, GradeEntry
│       │   ├── Finance/            # Index, Defaulters
│       │   ├── Home/               # Index (landing)
│       │   ├── Library/            # Index (full-text search)
│       │   ├── Student/            # Index, CourseRegistration, Payments, Transcript
│       │   └── Shared/             # _Layout.cshtml, Error.cshtml
│       ├── appsettings.json
│       ├── appsettings.Development.json
│       └── Program.cs
├── database/
│   ├── procedures/                  # Stored procedures (.sql)
│   ├── functions/                   # UDFs (.sql)
│   ├── triggers/                    # Audit triggers (.sql)
│   ├── views/                       # SQL Views (.sql)
│   ├── indexes/                     # Full-Text & performance indexes (.sql)
│   ├── security/                    # Roles & DCL scripts (.sql)
│   └── backup/                      # Backup scripts (.sql)
├── docs/                            # Documentation
├── data/                            # Sample data scripts
└── .github/workflows/               # CI/CD pipeline
```

## Tech Stack

| Layer        | Technology                                      |
|--------------|-------------------------------------------------|
| Framework    | ASP.NET Core 10 MVC                             |
| ORM          | Entity Framework Core (SQL Server provider)     |
| Identity     | ASP.NET Core Identity with custom `UserAccounts`|
| Raw DB       | ADO.NET for stored procedure calls (TVP support)|
| Database     | Microsoft SQL Server                            |
| Auth         | Cookie-based, Role-based (`Admin/Student/Faculty/Finance`) |

## Database Concepts Used

- **Stored Procedures** — `EnrollInCourse`, `ProcessFeePayment`, `RegisterStudent`, `GenerateTranscript`, `ImportBulkGrades`, `MarkAttendance`, `SearchStudentsDynamic`
- **User-Defined Functions** — `fn_CalculateCGPA`, `fn_GetLetterGrade`
- **Views** — `vw_StudentDashboard`, `vw_FacultyCourseLoad`, `vw_FeeDefaulters`, `vw_LibraryOverdue`
- **Triggers** — `trg_AuditStudents`, `trg_AuditGrades` (INSERT/UPDATE/DELETE captured to `AuditLog`)
- **Full-Text Search** — Library catalog uses `CONTAINS` / `FREETEXT`
- **Table-Valued Parameters** — Bulk attendance and grade submission
- **Computed Columns** — `FeeStructure.TotalAmount`
- **Transactions** — Enrollment and payment procedures wrapped in transactions

## Running Locally

1. Update the connection string in `src/HiSUP/appsettings.Development.json`
2. Run the database SQL scripts in order (schema → seed → procedures)
3. Start the app:

```bash
cd src/HiSUP
dotnet run
```

Navigate to `https://localhost:5001`
