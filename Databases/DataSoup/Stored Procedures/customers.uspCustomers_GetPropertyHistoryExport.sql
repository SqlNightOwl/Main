SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCustomers_GetPropertyHistoryExport]
-- Description     : This procedure will do the following in an all or Nothing fashion
--                        a) get data from Property history table for particular companyid 
-- Input Parameters: 1.  @IPVC_PropertyID    as String,
--                   2.  @IPVC_ModifiedIDSeq as String
--         		 3.  @IPVC_ModifiedDate   as String
--
-- Code Example    : 
/*
Exec CUSTOMERS.dbo.uspCustomers_GetPropertyHistoryExport @IPVC_ModifiedIDSeq='',@IPVC_ModifiedDate='',@IPVC_PropertyID='P0901064709'
*/
-- Revision History:
-- Author          : Naval Kishore Singh
-- 06/29/2010      : Stored Procedure Created.
-- Date         Author          Comments
-- -----------  -------------   ---------------------------
-- 06/29/2010   Naval Kishore	Defect #7695 -- Company and Property Modal to show up History.
-- 08/11/2010   Naval kishore   Defect #8099 -- Modified Expand Custom bundle option.
--============================================================================================================================
CREATE PROCEDURE [customers].[uspCustomers_GetPropertyHistoryExport] (@IPVC_PropertyID     varchar(50),
                                                                @IPVC_ModifiedIDSeq  varchar(30),
                                                                @IPVC_ModifiedDate   varchar(30)
                                                               )
AS
BEGIN --> Main Begin
  set nocount on;
  SET CONCAT_NULL_YIELDS_NULL off;
  -----------------------------------------------------------------------------------
  select @IPVC_PropertyID      = nullif(@IPVC_PropertyID,''),
         @IPVC_ModifiedDate    = nullif(@IPVC_ModifiedDate,''),
         @IPVC_ModifiedIDSeq   = nullif(@IPVC_ModifiedIDSeq,'')        
  -----------------------------------------------------------------------------------
  select
         PH.PropertyIDSeq                          as      [Property ID],         		
         PH.SiteMasterID                           as      [Site Master ID],                  
         PH.Name                                   as      [Property Name],                          	
         PH.PMCIDSeq                               as      [Company ID],                          
         PH.OwnerName                              as      [Owner Name],
        (case when (PH.StatusTypecode = 'ACTIV')
               then 'Active'
              else 'InActive'
         end)                                      as      [Status],
         PH.Units                                  as      [Units],                          	
         PH.Beds                                   as      [Beds],                          	
         PH.PPUPercentage                          as      [PPU Percentage],                  
         PH.SubPropertyFlag                        as      [Sub Property],         		
         PH.ConventionalFlag                       as      [Conventional],         		
         PH.StudentLivingFlag                      as      [Student Living],         		
         PH.HUDFlag                                as      [HUD],                          	
         PH.RHSFlag                                as      [RHS],                          	
         PH.TaxCreditFlag                          as      [Tax Credit],         		
         PH.VendorFlag                         as      [Vendor],                          	
         (case when UC.IDSeq is null
                then 'Not Captured'
               else UC.FirstName + ' ' + UC.LastName
          end)                                                  as   [Created By],
         (case when PH.CreatedDate is null
                then 'Not Captured'
               else convert(varchar(50),PH.CreatedDate,22)  
          end)                                                  as   [Created Date],
         (case when UM.IDSeq is null
                then 'Not Captured'
               else UM.FirstName + ' ' + UM.LastName
          end)                                                  as   [Modified By],
         (case when PH.ModifiedDate is null
                then 'Not Captured'
               else convert(varchar(50),PH.ModifiedDate,22)  
          end)                                                  as   [Modified Date],                 
         PH.SiebelID                               				as      [Siebel ID],         
         PH.QuotableUnits                          				as      [Quotable Units],                  
         PH.QuotableBeds                           				as      [Quotable Beds],         	
         PH.Phase                                  				as      [Phase],                          	
        (case when (PH.CustomBundlesProductBreakDownTypeCode = 'YEBR')
			  then 'Yes'
			  else 'No'
		 end)								as      [Expand Custom Bundle],
         PH.EpicorCustomerCode                     				as      [Epicor ID],         	                  
         PH.SeparateInvoiceByFamilyFlag            				as      [Print Separate Invoice by Product Family],		
         PH.SendInvoiceToClientFlag                				as      [Send Invoice To Client],
         PH.RetailFlag                             				as      [Retail Flag],                  
         PH.GSAEntityFlag                          				as      [GSA Entity Flag]                  
  from   CUSTOMERS.dbo.PropertyHistory PH with (nolock)
  left outer join
         Security.dbo.[User] UC with (nolock)
  on     PH.CreatedByIDSeq  = UC.IDSeq
  and    PH.PropertyIDSeq    = coalesce(@IPVC_PropertyID,PH.PropertyIDSeq)
  left outer join
         Security.dbo.[User] UM with (nolock)
  on     PH.ModifiedByIDSeq = UM.IDSeq
  and    PH.PropertyIDSeq    = coalesce(@IPVC_PropertyID,PH.PropertyIDSeq)
  where  PH.PropertyIDSeq    = coalesce(@IPVC_PropertyID,PH.PropertyIDSeq)
  and    coalesce(PH.ModifiedByIDSeq,'0')  = coalesce(@IPVC_ModifiedIDSeq,coalesce(PH.ModifiedByIDSeq,'0'))  		
  and    convert(varchar(20),PH.ModifiedDate,101) = coalesce(@IPVC_ModifiedDate,convert(varchar(20),PH.ModifiedDate,101))
  order by PH.IDSeq desc;
END 
GO
