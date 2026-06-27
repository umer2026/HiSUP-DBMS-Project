using System;
using System.Collections.Generic;
using System.Data;
using Microsoft.Data.SqlClient;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using HiSUP.Models;
namespace HiSUP.Services
{
    public class AdoNetDbService
    {
        private readonly string _connectionString;
        public AdoNetDbService(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString("HiSUP_DB");
        }
        // 1. Calling RegisterStudent Stored Procedure
        public async Task<int> RegisterStudentAsync(
            string firstName,
            string lastName,
            string email,
            string phone,
            string cnic,
            DateTime dob,
            int programId,
            string passwordHash)
        {
            using (var connection = new SqlConnection(_connectionString))
            {
                await connection.OpenAsync();

                using (var command = new SqlCommand("RegisterStudent", connection))
                {
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.AddWithValue("@FirstName", firstName);
                    command.Parameters.AddWithValue("@LastName", lastName);
                    command.Parameters.AddWithValue("@Email", email);
                    command.Parameters.AddWithValue("@Phone", (object)phone ?? DBNull.Value);
                    command.Parameters.AddWithValue("@CNIC", cnic);
                    command.Parameters.AddWithValue("@DateOfBirth", dob);
                    command.Parameters.AddWithValue("@ProgramID", programId);
                    command.Parameters.AddWithValue("@PasswordHash", passwordHash);
                    var outputIdParam = new SqlParameter("@NewStudentID", SqlDbType.Int)
                    {
                        Direction = ParameterDirection.Output
                    };
                    command.Parameters.Add(outputIdParam);
                    await command.ExecuteNonQueryAsync();
                    return (int)outputIdParam.Value;
                }
            }
        }
        // 2. Calling EnrollInCourse Stored Procedure
        public async Task EnrollInCourseAsync(int studentId, int sectionId)
        {
            using (var connection = new SqlConnection(_connectionString))
            {
                await connection.OpenAsync();
                using (var command = new SqlCommand("EnrollInCourse", connection))
                {
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.AddWithValue("@StudentID", studentId);
                    command.Parameters.AddWithValue("@SectionID", sectionId);
                    await command.ExecuteNonQueryAsync();
                }
            }
        }
        // 3. Calling ProcessFeePayment Stored Procedure
        public async Task ProcessFeePaymentAsync(
            int studentId,
            int feeStructureId,
            decimal amountPaid,
            string paymentMethod,
            string transactionId,
            string bankAccount)
        {
            using (var connection = new SqlConnection(_connectionString))
            {
                await connection.OpenAsync();
                using (var command = new SqlCommand("ProcessFeePayment", connection))
                {
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.AddWithValue("@StudentID", studentId);
                    command.Parameters.AddWithValue("@FeeStructureID", feeStructureId);
                    command.Parameters.AddWithValue("@AmountPaid", amountPaid);
                    command.Parameters.AddWithValue("@PaymentMethod", paymentMethod);
                    command.Parameters.AddWithValue("@TransactionID", transactionId);
                    command.Parameters.AddWithValue("@BankAccount", bankAccount);
                    await command.ExecuteNonQueryAsync();
                }
            }
        }
        // 4. Calling GenerateTranscript Stored Procedure (Returning Multi-row Result Set)
        public async Task<List<TranscriptEntryDto>> GenerateTranscriptAsync(int studentId)
        {
            var entries = new List<TranscriptEntryDto>();
            using (var connection = new SqlConnection(_connectionString))
            {
                await connection.OpenAsync();
                using (var command = new SqlCommand("GenerateTranscript", connection))
                {
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.AddWithValue("@StudentID", studentId);
                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            entries.Add(new TranscriptEntryDto
                            {
                                CourseCode = reader.GetString(reader.GetOrdinal("CourseCode")),
                                CourseTitle = reader.GetString(reader.GetOrdinal("CourseTitle")),
                                Credits = reader.GetInt32(reader.GetOrdinal("Credits")),
                                GradeValue = reader.IsDBNull(reader.GetOrdinal("GradeValue")) ? "I" : reader.GetString(reader.GetOrdinal("GradeValue")),
                                Marks = reader.IsDBNull(reader.GetOrdinal("Marks")) ? 0 : reader.GetInt32(reader.GetOrdinal("Marks")),
                                Semester = reader.GetString(reader.GetOrdinal("Semester")),
                                Year = reader.GetInt32(reader.GetOrdinal("Year")),
                                GradePoints = reader.IsDBNull(reader.GetOrdinal("GradePoints")) ? 0.00m : reader.GetDecimal(reader.GetOrdinal("GradePoints")),
                                SemGPA = reader.IsDBNull(reader.GetOrdinal("SemGPA")) ? 0.00m : reader.GetDecimal(reader.GetOrdinal("SemGPA"))
                            });
                        }
                    }
                }
            }
            return entries;
        }
        // Dynamic execution helper for RLS queries where we need to execute queries within session context.
        // Sets StudentID or FacultyID context inside the session transaction before running target.
        public async Task SetSessionContextAsync(SqlConnection connection, string key, object value)
        {
            using (var command = new SqlCommand("sp_set_session_context", connection))
            {
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.AddWithValue("@key", key);
                command.Parameters.AddWithValue("@value", value);
                await command.ExecuteNonQueryAsync();
            }
        }
    }
}
