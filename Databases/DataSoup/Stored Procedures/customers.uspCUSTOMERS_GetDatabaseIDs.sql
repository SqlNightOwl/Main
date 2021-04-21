SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspCUSTOMERS_GetDatabaseIDs]
-- Description     : Returns the databases for account ID passed
-- Input Parameters: 
-- 
------------------------------------------------------------------------------------------------------
-- Revision History:
-- Author          : Davon Cannon 
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetDatabaseIDs] (@IPVC_AccountIDSeq varchar(20))					
AS
BEGIN 
  set nocount on;
  declare @LVC_CompanySiteMasterID  varchar(50)
  declare @LVC_PropertySiteMasterID varchar(50)
  ----------------------------------------------------
  select Top 1 @LVC_CompanySiteMasterID = Coalesce(cmp.SiteMasterID,''),
               @LVC_PropertySiteMasterID= Coalesce(prop.SiteMasterID,'')
  from   Customers.dbo.Account     acct with (nolock)
  inner join 
         Customers.dbo.Company cmp  with (nolock)
  on     cmp.IDSeq  = acct.CompanyIDSeq
  and    acct.IDSeq = @IPVC_AccountIDSeq
  and    acct.ActiveFlag = 1
  left  outer join 
        Customers.dbo.[Property] prop with (nolock)
  on    prop.IDSeq = acct.PropertyIDSeq
  where acct.IDSeq = @IPVC_AccountIDSeq
  and    acct.ActiveFlag = 1
  ----------------------------------------------------
  if (@LVC_CompanySiteMasterID is null or @LVC_CompanySiteMasterID='')
  begin
    select Top 1 @LVC_CompanySiteMasterID = Coalesce(acct.CompanyIDSeq,''),
                @LVC_PropertySiteMasterID= Coalesce(acct.PropertyIDSeq,'')
    from   Customers.dbo.Account     acct with (nolock)
    inner join 
           Customers.dbo.Company cmp  with (nolock)
    on     cmp.IDSeq  = acct.CompanyIDSeq
    and    acct.IDSeq = @IPVC_AccountIDSeq
    and    acct.ActiveFlag = 1
    left  outer join 
           Customers.dbo.[Property] prop with (nolock)
    on     prop.IDSeq = acct.PropertyIDSeq
    where  acct.IDSeq = @IPVC_AccountIDSeq
    and    acct.ActiveFlag = 1  
  end
  ----------------------------------------------------
  --Final Select
  select @LVC_CompanySiteMasterID,@LVC_PropertySiteMasterID

END

GO
