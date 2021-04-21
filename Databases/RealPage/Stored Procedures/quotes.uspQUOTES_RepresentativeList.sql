SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : uspQUOTES_RepresentativeList
-- Description     : This procedure gets the list of Sales Representatives
--
-- OUTPUT          : RecordSet of Sales Representatives
--
-- Code Example    : Exec DOCUMENTS.dbo.[uspQUOTES_RepresentativeList]
--
-- Revision History:
-- Author          : KISHORE KUMAR A S 
-- 22/02/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_RepresentativeList] 
as
begin -- Main BEGIN starts at Col 01
    
        /*********************************************************************************************/
        /*                 Main Select statement                                                     */  
        /*********************************************************************************************/

  select distinct u.IDSeq, u.FirstName + ' ' + u.LastName as [RepName]
  from Security..[User] u with (nolock) inner join Security..UserRoles ur with (nolock)
  on u.IDSeq = ur.UserIDSeq inner join
  Security..RoleRights rr with (nolock) on rr.RoleIDSeq = ur.RoleIDSeq inner join
  Security..Rights r with (nolock) on r.IDSeq = rr.RightIDSeq 
  and r.Code = 'SalesRep'
  order by [RepName]

END -- Main END starts at Col 01

GO
