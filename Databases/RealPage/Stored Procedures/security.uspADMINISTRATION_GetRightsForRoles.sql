SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


----------------------------------------------------------------------------------------------------
-- Database  Name  : Administration
-- Procedure Name  : uspAdministration_GetRoles.sql
-- Description     : This procedure gets Roles

-- Input Parameters:
-- 
-- OUTPUT          : 

-- Code Example    : exec Security..[uspADMINISTRATION_GetRightsForRoles] 43

-- Revision History:

-- Author          : NAL, SRA Systems Limited.

-- 22/02/2007      : Stored Procedure Created.
-- 10/28/2011      : TFS 1384 
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [security].[uspADMINISTRATION_GetRightsForRoles] (@IDSeq     bigint
                                                              )
AS
BEGIN
  set nocount on; 
  -----------------
  --First Set : Get Every Rights pertaining to the Role in Question
  SELECT IDSeq,Code,[Name] 
  FROM   [SECURITY].[dbo].Rights r with (nolock)
  where  exists (select Top 1 1
                 from  [SECURITY].[dbo].RoleRights rr with (nolock)
                 where rr.RightIdSeq = r.IDSeq
                 and   rr.RoleIDSeq  = @IDSeq
                )
  order  by [Name] ASC
  -----------------
  --Second Set : Get Every Rights NOT pertaining to the Role in Question
  SELECT IDSeq,Code,[Name] 
  FROM   [SECURITY].[dbo].Rights r with (nolock)
  where  not exists (select Top 1 1
                     from  [SECURITY].[dbo].RoleRights rr with (nolock)
                     where rr.RightIdSeq = r.IDSeq
                     and   rr.RoleIDSeq = @IDSeq
                    )
  order  by [Name] ASC
  ----------------- 
END
GO
