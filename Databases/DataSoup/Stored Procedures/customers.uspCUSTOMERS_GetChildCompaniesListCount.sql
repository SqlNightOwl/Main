SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Customers
-- Procedure Name  : uspCustomers_GetChildCompaniesListCount
-- Description     : This procedure gets Count of child companies for an Executive Company 
-- Revision History:
-- Author          : Mahaboob
-- 07/26/2011      : Stored Procedure Created.
-- 2011-09-06      : Mahaboob ( TFS 1026)     --  Changes  are made as per the Revised "ExecutiveCompany" table script 
----------------------------------------------------------------------------------------------------

CREATE procedure [customers].[uspCUSTOMERS_GetChildCompaniesListCount] (@IPVC_CustomerID   varchar(50))													     
															      
AS
BEGIN-->Main Begin
  set nocount on;  
  
  SELECT @IPVC_CustomerID  = nullif(@IPVC_CustomerID,'');
	
  ---------------------------------------------------------------------------    
  --Final Select   
  ---------------------------------------------------------------------------- 
    WITH tablefinal AS   
       ----------------------------------------------------------  
       (SELECT tableinner.[Count]   as [Count]  
           FROM  
           ----------------------------------------------------------     
           (select  count(source.[CustomerID])  as [Count]    
            from  
             ----------------------------------------------------------  
				  (select 
				  upper(C.IDSeq)         as [CustomerID], 
				  upper(Acct.IDSeq)		 as [AccountID],  
				  upper(C.Name)          as [Name]            
				  from CUSTOMERS.dbo.Company C with (nolock) 
				  inner join
				  Customers.dbo.ExecutiveCompany E with (nolock)
				  on C.ExecutiveCompanyIDSeq = E.ExecutiveCompanyIDSeq   and C.StatusTypeCode = 'ACTIV'
				  left outer join 
					   Customers.dbo.Account Acct with (nolock)
				  on    Acct.CompanyIDSeq  = C.IDSeq  and Acct.AccountTypeCode = 'AHOFF' and Acct.PropertyIDSeq is null
				  where E.CompanyIDSeq   = @IPVC_CustomerID
				  and E.ActiveFlag = 1 
				                
               )source  
             ------------------------------------------------------------------------  
        ) tableinner  
      -----------------------------------------------------------------------------  
      )  
      
      SELECT  tablefinal.[Count]      
      from    tablefinal
   --------------------------------------------------------------------------------------  
  ---Final Cleanup  
  --------------------------------------------------------------------------------------  
END-->Main End  

GO
