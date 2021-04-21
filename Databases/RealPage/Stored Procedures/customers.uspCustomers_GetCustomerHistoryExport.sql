SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCustomers_GetCustomerHistoryExport]
-- Description     : This procedure will do the following in an all or Nothing fashion
--                        a) get data from Company history table for particular companyid 
-- Input Parameters: 1.  @IPVC_CompanyID    as String,
--                   2.  @IPVC_ModifiedIDSeq as String
--                  	 3.  @IPVC_ModifiedDate   as String
--
-- Code Example    : 
/*
Exec CUSTOMERS.dbo.uspCustomers_GetCustomerHistoryExport @IPVC_ModifiedIDSeq='',@IPVC_ModifiedDate='',@IPVC_CompanyID='C0901006950'
*/
-- Revision History:
-- Author          : Naval Kishore Singh
-- 06/29/2010      : Stored Procedure Created.
-- Date         Author          Comments
-- -----------  -------------   ---------------------------
-- 06/29/2010   Naval Kishore	Defect #7695 -- Company and Property Modal to show up History.
-- 08/11/2010   Naval kishore   Defect #8099 -- Modified Expand Custom bundle option.
--============================================================================================================================
CREATE PROCEDURE [customers].[uspCustomers_GetCustomerHistoryExport] (@IPVC_CompanyID      varchar(50),
                                                                @IPVC_ModifiedIDSeq  varchar(30),
                                                                @IPVC_ModifiedDate   varchar(30)
                                                               )
AS
BEGIN --> Main Begin
  set nocount on;
  SET CONCAT_NULL_YIELDS_NULL off;
  -----------------------------------------------------------------------------------
  select @IPVC_CompanyID       = nullif(@IPVC_CompanyID,''),
         @IPVC_ModifiedDate    = nullif(@IPVC_ModifiedDate,''),
         @IPVC_ModifiedIDSeq   = nullif(@IPVC_ModifiedIDSeq,'')        
  -----------------------------------------------------------------------------------
  select
         CompanyIDSeq                                           as   [Company ID],                           
         SiteMasterID                                           as   [SiteMaster ID],                           
         Name                                                   as   [Name],                                    
         PMCFlag                                                as   [PMC Flag],                                    
         OwnerFlag                                              as   [Owner Flag],
         (case when (CH.StatusTypecode = 'ACTIV')
                         then 'Active'
                       else 'InActive'
                  end)                                          as   [Status],
         (case when UC.IDSeq is null
                then 'Not Captured'
               else UC.FirstName + ' ' + UC.LastName
          end)                                                  as   [Created By],
         (case when CH.CreatedDate is null
                then 'Not Captured'
               else convert(varchar(50),CH.CreatedDate,22)  
          end)                                                  as   [Created Date],
         (case when UM.IDSeq is null
                then 'Not Captured'
               else UM.FirstName + ' ' + UM.LastName
          end)                                                  as   [Modified By],
         (case when CH.ModifiedDate is null
                then 'Not Captured'
               else convert(varchar(50),CH.ModifiedDate,22)  
          end)                                                  as   [Modified Date],
         SiebelID                                               as   [Siebel ID],                           
         SignatureText                                          as   [Signature Text],                                  
         LegacyRegistrationCode                  		as   [Legacy Registration Code],         	
         OrderSynchStartMonth                  	                as   [Synch Start Month],         	
		 (case when (CustomBundlesProductBreakDownTypeCode = 'YEBR')
			  then 'Yes'
			  else 'No'
		 end)						as   [Custom Bundle Display],
         EpicorCustomerCode                                     as   [Epicor ID] ,         	
         SeparateInvoiceByFamilyFlag                            as   [Separate Invoice],         	
         MultiFamilyFlag                                        as   [Multi Family Flag],         	
         VendorFlag                                         as   [Vendor Flag],         
         SendInvoiceToClientFlag        		        as   [Send Invoice To Client Flag],         	        
         GSAEntityFlag                                          as   [GSA Entity Flag]
  from   CUSTOMERS.dbo.CompanyHistory CH with (nolock)
  left outer join
         Security.dbo.[User] UC with (nolock)
  on     CH.CreatedByIDSeq  = UC.IDSeq
  and    CH.CompanyIDSeq    = coalesce(@IPVC_CompanyID,CH.CompanyIDSeq)
  left outer join
         Security.dbo.[User] UM with (nolock)
  on     CH.ModifiedByIDSeq = UM.IDSeq
  and    CH.CompanyIDSeq    = coalesce(@IPVC_CompanyID,CH.CompanyIDSeq)
  where  CH.CompanyIDSeq    = coalesce(@IPVC_CompanyID,CH.CompanyIDSeq)
  and    coalesce(CH.ModifiedByIDSeq,'0')  = coalesce(@IPVC_ModifiedIDSeq,coalesce(CH.ModifiedByIDSeq,'0'))  		
  and    convert(varchar(20),CH.ModifiedDate,101) = coalesce(@IPVC_ModifiedDate,convert(varchar(20),CH.ModifiedDate,101))
  order by CH.IDSeq desc;
END 
GO
