SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- EXEC uspRestoreFromFolder 'E:\restore' ,@LiteSpeed=0 ,@excludeDrive='e' ,@IPVC_Data='C:\test' ,@IPVC_Log='C:\test'
CREATE procedure [orders].[uspRestoreFromFolder](@IPVC_LOCALBAKPATH VARCHAR (1000),
                                      @LiteSpeed         BIT=0,
                                      @DELETEBAK         BIT=0,
                                      @IPVC_Data         VARCHAR (25)=NULL,
                                      @IPVC_Log          VARCHAR (25)=NULL,
                                      @excludeDrive      VARCHAR (1)=NULL,
                                      @Shrink            BIT=1)
AS
DECLARE @COUNTER INT, @LVC_DBNAME sysname, @LVC_FULLBACKUPPATH VARCHAR(1000), @LVC_DATAVER VARCHAR(1000), @LVC_LOGVER VARCHAR(1000),
        @LVC_FILEDATASTMT VARCHAR(1000), @LVC_DIRSTMT VARCHAR(1000),@SQL NVARCHAR (4000),@SQLDriveLOG CHAR, @SQLDriveData CHAR,@LVC_cmd VARCHAR (255),
        @LVC_DATAPATH VARCHAR(1000), @LVC_LOGPATH VARCHAR(1000), @Result INT, @LOGIN varchar(1000), @BACKUP_HISTORY varchar(1000)
--Create temp table and perfom a DIR to populate with .bak file names
Set nocount on
Create Table #Dir_List
	(db_name	VARCHAR(255))
Select @LVC_DIRSTMT = 'DIR /B /A-D ' + Rtrim(@IPVC_LOCALBAKPATH) 
Insert #Dir_List Execute master.dbo.xp_cmdshell @LVC_DIRSTMT
delete from #Dir_List where  db_name like '%File not%' or db_name is null

update #Dir_List set db_name=replace(DB_NAME,'.bak', '') 
WHILE (SELECT count(db_name) from #Dir_List)> 0
BEGIN
    -- Restore Databases to different drive. Now that we don't have all MFDs and LDFs on the SAME Drive
    CREATE TABLE #DRIVEINFO (DRIVE CHAR (1),MB_FREE INT)
    INSERT INTO #DRIVEINFO
    EXEC MASTER.DBO.XP_FIXEDDRIVES
    IF LEN(@excludeDrive)>0
       DELETE FROM #DRIVEINFO WHERE DRIVE=@excludeDrive
    DELETE FROM #DRIVEINFO WHERE DRIVE='C' -- Don't want things on the "C" drive
    IF (SELECT COUNT (DRIVE) FROM  #DRIVEINFO) > 4
       DELETE FROM #DRIVEINFO WHERE DRIVE IN ('D','E','F')
    -- Don't want data and log on the same drive.
    SELECT @SQLDriveData =(SELECT top 1 DRIVE FROM #DRIVEINFO WHERE MB_FREE=(SELECT MAX (MB_FREE) FROM #DRIVEINFO))
    SELECT @SQLDriveLog = (SELECT TOP 1 DRIVE FROM #DRIVEINFO WHERE DRIVE <> @SQLDriveData ORDER BY MB_FREE DESC)
    IF @SQLDriveLog IS NULL OR @SQLDriveLog='' 
       SET @SQLDriveLog=@SQLDriveData
    SELECT @LVC_DATAPATH=@SQLDriveData+':\sql2000\data'
    SELECT @LVC_LOGPATH=@SQLDriveLog+':\sql2000\Log'
    -- If You want to specify Data and log path
    IF LEN(@IPVC_Data)>0
       SELECT @LVC_DATAPATH=@IPVC_Data
    IF LEN(@IPVC_Log)>0
       SELECT @LVC_LOGPATH=@IPVC_Log
    -- Check if the "data" and "log" folder exists if not create them.
    SET @LVC_cmd = 'if not exist ' + @LVC_DATAPATH  + ' mkdir ' + @LVC_DATAPATH
    exec master..xp_cmdshell @LVC_cmd,no_output
    SET @LVC_cmd = 'if not exist ' + @LVC_LOGPATH+ ' mkdir ' + @LVC_LOGPATH
    exec master..xp_cmdshell @LVC_cmd,no_output
    SELECT TOP 1 @LVC_DBNAME=db_name from #Dir_List
    SELECT @LVC_FULLBACKUPPATH = @IPVC_LOCALBAKPATH +'\' +@LVC_DBNAME +'.bak'
    
    create table #filelist
    (LogicalName  nvarchar(128),PhysicalName nvarchar(260),Type char(1),FileGroupName nvarchar(128),Size numeric(20,0),MaxSize numeric(20,0),FileID bigint NULL,
    CreateLSN numeric(25,0) NULL,DropLSN numeric(25,0) NULL,UniqueID uniqueidentifier  NULL,ReadOnlyLSN numeric(25,0) NULL,ReadWriteLSN numeric(25,0) NULL,BackupSizeInBytes bigint  NULL,
    SourceBlockSize int  NULL,FileGroupID int  NULL,LogGroupGUID uniqueidentifier NULL,DifferentialBaseLSN numeric(25,0) NULL,DifferentialBaseGUID uniqueidentifier  NULL,IsReadOnly bit  NULL,IsPresent bit  NULL)
    select @LVC_FILEDATASTMT = 'restore Filelistonly from disk = ' +'''' +@LVC_FULLBACKUPPATH +''''
 
    If @LiteSpeed=1
       BEGIN
           --Uncompress it here.
           EXEC master..xp_fileexist 'c:\windows\system32\Extractor.exe', @Result OUTPUT
  if @Result = 0
              BEGIN
                  PRINT 'Extractor file is missing from C:\winnt\system32.  You can find it here \\rpidaldss001\Datasets\ProductionBackups\Extractor'
                  RETURN
              END
           SET @SQL = 'extractor –F'+@LVC_FULLBACKUPPATH+' -E'+@LVC_FULLBACKUPPATH
           EXEC MASTER.dbo.xp_cmdshell @SQL,no_output
           SET @SQL = 'del '+@LVC_FULLBACKUPPATH+' /Q'
           EXEC MASTER.dbo.xp_cmdshell @SQL,no_output
           SET @SQL = 'rename '+@LVC_FULLBACKUPPATH+'0 ' +@LVC_DBNAME+'.bak'
           EXEC MASTER.dbo.xp_cmdshell @SQL,no_output
       END

    IF LEFT (CONVERT(char(20), SERVERPROPERTY('ProductVersion')),1)='9'
       --2005 
       insert into #filelist 
       (LogicalName,PhysicalName,Type,FileGroupName,Size,MaxSize,FileId,CreateLSN,DropLSN,UniqueId,ReadOnlyLSN,ReadWriteLSN,BackupSizeInBytes,SourceBlockSize,FileGroupId,LogGroupGUID,DifferentialBaseLSN,DifferentialBaseGUID,IsReadOnly,IsPresent)
       exec(@LVC_FILEDATASTMT)
    ELSE
       --2000
       insert into #filelist (LogicalName,PhysicalName,Type,FileGroupName,Size,MaxSize)
       exec(@LVC_FILEDATASTMT)
       -- get the logical filenames into a table
    IF (select count (type) from #filelist)= 2
       BEGIN
           SELECT @LVC_DATAVER=Logicalname from #filelist where type='D'
           SELECT @LVC_LOGVER=Logicalname from #filelist where type='L'
           -- kick 'em out
           if exists (select name from master.dbo.sysdatabases (NOLOCK) where name=@LVC_DBNAME)
              exec master..sp_dboption2 @dbname = @LVC_DBNAME, @optname = 'read only', @optvalue = 'FALSE'
  SELECT @SQL='RESTORE DATABASE '+@LVC_DBNAME+'
              FROM DISK = '+''''+@LVC_FULLBACKUPPATH+''''+'
              WITH STATS = 100, RECOVERY, REPLACE,
              MOVE '+''''+@LVC_DATAVER+''''+'  TO '''+@LVC_DATAPATH +'\' +@LVC_DBNAME +'_Data.mdf'', 
              MOVE '+''''+@LVC_LOGVER+''''+'  TO  '''+@LVC_LOGPATH +'\' +@LVC_DBNAME +'_Log.ldf'''
              EXEC SP_EXECUTESQL @SQL
              DELETE FROM #filelist
       END
    IF (select count (LogicalName) from #filelist) > 2
       -- Same starting "logic" for all restores
       select @SQL='RESTORE DATABASE '+@LVC_DBNAME+' FROM DISK='+''''+@LVC_FULLBACKUPPATH+''''+'
                    WITH  STATS = 100,  RECOVERY ,  REPLACE ,'
       WHILE (select count (LogicalName) from #filelist) > 0
       -- Used to "tack on"  X number of logicalNames...
           BEGIN
           --  Used for multiple datafiles
           WHILE (select count (LogicalName) from #filelist WHERE TYPE='D')> 0
               BEGIN
                   SELECT @COUNTER=(select count (LogicalName) from #filelist)
                   SELECT TOP 1 @LVC_DATAVER=Logicalname from #filelist (NOLOCK) WHERE TYPE='D'
                   SELECT @SQL= @SQL +'MOVE '+''''+@LVC_DATAVER+''''+' TO '+''''+@LVC_DATAPATH+''+'\'+''+@LVC_DBNAME+''+'_'+convert (varchar (10),@COUNTER)+'_Data.MDF'''+',' --NEED TO FIX THIS  THE LVC_DATAVER NEEDS TO BE DB_NAME!!! 
                   DELETE FROM #filelist where logicalName=@LVC_DATAVER
               END
           --  Used for multiple logfiles if we ever have those....
           WHILE (select count (LogicalName) from #filelist WHERE TYPE='L') > 0
               BEGIN
                  IF (select count (LogicalName) from #filelist WHERE TYPE='L')= 1  
                      BEGIN
                          SELECT @COUNTER=(select count (LogicalName) from #filelist)
                          SELECT TOP 1 @LVC_DATAVER=Logicalname from #filelist (NOLOCK) WHERE TYPE='L'
                         select @SQL= @SQL +'MOVE '+''''+@LVC_DATAVER+''''+' TO '+''''+@LVC_LOGPATH+''+'\'+''+@LVC_DBNAME+'_'+convert (varchar (10),@COUNTER)+'_Log.LDF'''+''
                         DELETE FROM #filelist where logicalName=@LVC_DATAVER
                      END
                      ELSE BEGIN
                          SELECT @COUNTER=(select count (LogicalName) from #filelist)
                          SELECT TOP 1 @LVC_DATAVER=Logicalname from #filelist (NOLOCK) WHERE TYPE='L'
                          SELECT @SQL=@SQL +'MOVE '+''''+@LVC_DATAVER+''''+' TO '+''''+@LVC_LOGPATH+''+'\'+''+@LVC_DBNAME+'_'+convert (varchar (10),@COUNTER)+'_Log.LDF'''+','
                          DELETE FROM #filelist where logicalName=@LVC_DATAVER
                      END
               IF exists (SELECT NAME FROM master.dbo.sysdatabases (NOLOCK) where name=@LVC_DBNAME)
                  EXEC master..sp_dboption2 @dbname = @LVC_DBNAME, @optname = 'read only', @optvalue = 'FALSE'
                  EXEC SP_EXECUTESQL @SQL
               END
       END
       --  If you want to remove the .bak after the restore
       IF @DELETEBAK=1
         BEGIN
             SET @SQL = 'del '+@LVC_FULLBACKUPPATH+' /Q'
             EXEC MASTER.dbo.xp_cmdshell @SQL,no_output
         END
       IF @Shrink=1
         BEGIN
              SELECT @SQL='backup log '+@LVC_DBNAME+' with TRUNCATE_ONLY dbcc shrinkdatabase ('+@LVC_DBNAME+', 10)'
              EXEC SP_EXECUTESQL @SQL 
         END
    DELETE FROM #Dir_List where db_name=@LVC_DBNAME
    DROP TABLE #filelist,#DRIVEINFO
END
Drop TABLE #Dir_List


GO
