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
-- Code Example    : Exec CUSTOMERS.dbo.[uspCUSTOMERS_ContractAdminList]
--
-- Revision History:
-- Author          : Naval Kishore Singh 
-- 28/07/2010      : Stored Procedure Created.Defect # 8027
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_ContractAdminList] 
as
begin -- Main BEGIN starts at Col 01
    
        /*********************************************************************************************/
        /*                 Main Select statement                                                     */  
        /*********************************************************************************************/

  select distinct u.IDSeq, u.FirstName + ' ' + u.LastName as [RepName]
  from Security..[User] u with (nolock) inner join Security..UserRoles ur with (nolock)
  on u.IDSeq = ur.UserIDSeq inner join
  Security..Roles ro with (nolock) on ro.IDSEQ = ur.RoleIDSeq
  and ro.code in ('CADM','UCon') 
  order by [RepName]

END -- Main END starts at Col 01
GO
