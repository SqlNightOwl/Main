SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : uspQUOTES_BundleNamesSelect
-- Description     : This procedure gets the list of all stock bundle names
--
-- Revision History:
-- Author          : DCANNON
-- 4/11/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_BundleNamesSelect] 
as
begin 
    
  SELECT     DisplayName
  FROM       Products.dbo.Product with (nolock)
  WHERE     (FamilyCode = 'SBL')
  AND       (DisabledFlag = 0)
  order by   DisplayName asc

END 

GO
