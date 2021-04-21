SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : QUEUEMANAGER
-- Procedure Name  : usp_RebuildIndexes
-- Description     : This is the Maintenance Proc for Periodic Index Defrag , Index rebuild
-- Input Parameters: As below
-- Returns         : None
-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 1037
------------------------------------------------------------------------------------------------------
create proc [QueueManager].[usp_RebuildIndexes]    
AS
BEGIN
  ------------------------------------
  SET CONCAT_NULL_YIELDS_NULL OFF;  
  set nocount on;
  ------------------------------------
  --Step 1 : ReIndex
  Begin Try
    EXEC dbo.sp_MSforeachtable @command1="SET QUOTED_IDENTIFIER ON;ALTER INDEX ALL ON ? REBUILD WITH (FILLFACTOR = 100,STATISTICS_NORECOMPUTE = OFF);"
  End  Try
  Begin Catch    
    return
  end  Catch;
  ------------------------------------
  --Step 2 : IndexDefrag
  Begin Try
    EXEC dbo.sp_MSforeachtable @command1="SET QUOTED_IDENTIFIER ON;ALTER INDEX ALL ON ? REORGANIZE;";
  End  Try
  Begin Catch    
    return
  end  Catch;
  ------------------------------------
  --Step 3 : Update Stats
  Begin Try
    EXEC dbo.sp_MSforeachtable @command1="SET QUOTED_IDENTIFIER ON; begin print'?';EXEC sp_updatestats;end"
  End  Try
  Begin Catch    
    return
  end  Catch;
  ------------------------------------
END--> Main End
GO
