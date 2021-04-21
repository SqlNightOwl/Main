SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : QUEUEMANAGER
-- Procedure Name  : uspQUEUEMANAGER_GetUsers
-- Description     : Gets valid Users along with UserID that had atleast participated in BBQ submit process once.
-- Input Parameters: 
-- Returns         : RecordSet of Unique UserID along with UserName,NTUserName
--                   to populate the Drop down in UI.
--                   All Users will have userid as 0

-- Code Example    : 
/*
Exec QUEUEMANAGER.dbo.uspQUEUEMANAGER_GetUsers
*/

-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 1037
------------------------------------------------------------------------------------------------------
Create PROCEDURE [QueueManager].[uspQUEUEMANAGER_GetUsers] 
as
BEGIN
  set nocount on;
  SET CONCAT_NULL_YIELDS_NULL ON;
  -------------------------------
  ;with CTE_Users(UserIDSeq,UserName,NTUserName)
   as (select  0                                as UserIDSeq,
               'All Users'                      as UserName,
               'All Users'                      as NTUserName
       ---------
       union
       ---------
       select UC.IDSeq                          as UserIDSeq,
              UC.FirstName + ' ' + UC.LastName  as UserName,
              UC.NTUser                         as NTUserName
       from   SECURITY.dbo.[User] UC with (nolock)
       where  exists (select top 1 1
                      from   QueueManager.dbo.QueueBatchHeader QBH with (nolock)
                      where  QBH.CreatedByIDSeq = UC.IDSeq
                     )
      )
   select  CTE_Users.UserIDSeq                  as UserIDSeq
          ,CTE_Users.UserName                   as UserName
          ,CTE_Users.NTUserName                 as NTUserName
   from   CTE_Users
   order by (case when UserName like 'All%' then '_AA' else UserName end) ASC; 
END
GO
