SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_GetSitePropertyDetails]
-- Description     : This procedure gets Property Details pertaining to passed 
--                        PropertyID
-- Input Parameters:  @IPVC_PropertyID  varchar(11)  
 
-- OUTPUT          : RecordSet of the ID, Name of Customers from Customers..Company,

-- Code Example    : Exec CUSTOMERS.dbo.[uspCUSTOMERS_GetSitePropertyDetails] @IPVC_PropertyID = 'P0000000006'

	
-- Revision History:
-- Author          : KRK
-- 05/14/2006      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE procedure [customers].[uspCUSTOMERS_GetSitePropertyDetails] (    
                                                                @IPVC_PropertyID  varchar(11)  
                                                             )
AS
BEGIN
  
select 
        prop.IDSeq              as PropertyID,
        prop.Name               as PropertyName,
        comp.IDSeq              as CompanyID,
        comp.Name               as CompanyName,
        addr.AddressLine1       as AddressLine1,
        addr.AddressLine2       as AddressLine2,
        addr.City               as City,
        addr.State              as State,
        addr.Zip                as Zip,
        acct.IDSeq              as AccountID,        
        acct.EpicorCustomerCode as EpicorID,
        prop.SiteMasterID       as SiteMasterID,
        prop.SiebelID           as SiebelID

from Customers.dbo.Property prop


inner join Customers.dbo.Company comp

on comp.idseq = prop.pmcidseq


inner join Customers.dbo.Address addr

on prop.IDSeq = addr.PropertyIDSeq


left outer join Customers.dbo.Account acct

on acct.CompanyIDSeq = prop.PMCIDSeq and acct.PropertyIDSeq = prop.IDSeq


where addr.AddressTypeCode = 'PRO' and prop.IDSeq like '%'+@IPVC_PropertyID+'%'
    

END


--exec [dbo].[uspCUSTOMERS_GetSitePropertyDetails] 'P0000000006'
GO
