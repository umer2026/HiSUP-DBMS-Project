CREATE OR ALTER FUNCTION fn_GetLetterGrade
    (@Marks INT)
    RETURNS VARCHAR(2)
AS
BEGIN
    DECLARE @Grade VARCHAR(2);
    IF @Marks >= 90 SET @Grade = 'A+';
    ELSE IF @Marks >= 85 SET @Grade = 'A';
    ELSE IF @Marks >= 80 SET @Grade = 'A-';
    ELSE IF @Marks >= 75 SET @Grade = 'B+';
    ELSE IF @Marks >= 70 SET @Grade = 'B';
    ELSE IF @Marks >= 65 SET @Grade = 'B-';
    ELSE IF @Marks >= 60 SET @Grade = 'C+';
    ELSE IF @Marks >= 55 SET @Grade = 'C';
    ELSE IF @Marks >= 50 SET @Grade = 'C-';
    ELSE IF @Marks >= 45 SET @Grade = 'D+';
    ELSE IF @Marks >= 40 SET @Grade = 'D';
    ELSE SET @Grade = 'F';
    RETURN @Grade;
END;
GO
