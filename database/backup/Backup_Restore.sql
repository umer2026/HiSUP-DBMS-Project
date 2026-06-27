-- =========================================================================
-- HITEC Smart University Portal (HiSUP) Backup and Restore Scripts
-- Full Backup, Differential Backup, and Complete Database Restore
-- =========================================================================
USE master;
GO
-- 1. Full Database Backup Script
-- Creates a complete copy of the database to a backup file.
BACKUP DATABASE HiSUP_DB
TO DISK = 'C:\Users\umerz\.gemini\antigravity\scratch\HITEC-ADMS-HiSUP-000000\database\backup\HiSUP_DB_Full.bak'
WITH FORMAT,
     MEDIANAME = 'HiSUP_DB_Backup_Media',
     NAME = 'Full Backup of HiSUP_DB',
     STATS = 10;
GO
-- 2. Differential Database Backup Script
-- Backs up only the data that has changed since the last full backup.
BACKUP DATABASE HiSUP_DB
TO DISK = 'C:\Users\umerz\.gemini\antigravity\scratch\HITEC-ADMS-HiSUP-000000\database\backup\HiSUP_DB_Diff.bak'
WITH DIFFERENTIAL,
     FORMAT,
     NAME = 'Differential Backup of HiSUP_DB',
     STATS = 10;
GO
-- 3. Database Restore Script (Demonstration)
-- Restores the database from the full backup first (with NORECOVERY),
-- and then applies the differential backup (with RECOVERY).
-- Kick out active sessions to prevent database in-use locks
ALTER DATABASE HiSUP_DB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
-- Step A: Restore full backup
RESTORE DATABASE HiSUP_DB
FROM DISK = 'C:\Users\umerz\.gemini\antigravity\scratch\HITEC-ADMS-HiSUP-000000\database\backup\HiSUP_DB_Full.bak'
WITH FILE = 1,
     NORECOVERY, -- Allows subsequent differential restore
     REPLACE;
GO
-- Step B: Restore differential backup and bring database online
RESTORE DATABASE HiSUP_DB
FROM DISK = 'C:\Users\umerz\.gemini\antigravity\scratch\HITEC-ADMS-HiSUP-000000\database\backup\HiSUP_DB_Diff.bak'
WITH FILE = 1,
     RECOVERY; -- Database online
GO
-- Re-enable multi-user mode
ALTER DATABASE HiSUP_DB SET MULTI_USER;
GO
