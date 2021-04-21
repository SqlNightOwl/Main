SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Customers
-- Procedure Name  : uspCustomers_ExecutiveCompanyListCount
-- Description     : This procedure gets ExecutiveCompanies Count.
-- Input Parameters: @IPVC_CustomerID      as  varchar,
--                   @IPVC_CustomerName     as  varchar 
-- Revision History:
-- Author          : Mahaboob
-- 07/26/2011      : Stored Procedure Created.
-- 2011-09-06      : Mahaboob ( TFS 1026)     --  Changes  are made as per the Revised "ExecutiveCompany" table script 
----------------------------------------------------------------------------------------------------

CREATE procedure [customers].[uspCUSTOMERS_ExecutiveCompanyListCount] (@IPVC_CustomerID   varchar(50), 
															     @IPVC_CustomerName varchar(200)
															     )  
AS
BEGIN-->Main Begin
  set nocount on;  
  --------------------------------------
  declare @LN_CHECKSUM  numeric(30,0)
  ---------------------------------------
 select @LN_CHECKSUM = checksum(coalesce(@IPVC_CustomerID,''),
								coalesce(@IPVC_CustomerName,'')
                                );
  ---------------------------------------
 
  SELECT @IPVC_CustomerID  = nullif(@IPVC_CustomerID,'')
	
  ---------------------------------------------------------------------------    
  --Final Select   
  ---------------------------------------------------------------------------- 
  if @LN_CHECKSUM = 0
  begin 
    WITH tablefinal AS   
       ----------------------------------------------------------  
       (SELECT tableinner.[Count]   as [Count]  
           FROM  
           ----------------------------------------------------------     
           (select  count(source.[ExecutiveCompanyID])  as [Count]    
            from  
             ----------------------------------------------------------  
				 (select distinct
				  e.ExecutiveCompanyIDSeq                       as ExecutiveCompanyID, 
				  e.CompanyIDSeq                                as CustomerID, 
				  e.CompanyName								    as CompanyName,
				  (case 
					when e.ActiveFlag = 1 then 'Active'
					when e.ActiveFlag = 0 then 'Inactive'
				   end
				   )												as Status    
				  from CUSTOMERS.dbo.ExecutiveCompany e with (nolock) 
				  inner join CUSTOMERS.dbo.Company c with (nolock)
				  on c.IDSeq = e.CompanyIDSeq and c.StatusTypeCode = 'ACTIV'
				  --where e.ActiveFlag = 1                  
               )source  
             ------------------------------------------------------------------------  
        ) tableinner  
      -----------------------------------------------------------------------------  
      )  
      SELECT  tablefinal.[Count]      
      from    tablefinal
  end
  else
  begin
    WITH tablefinal AS   
       ----------------------------------------------------------  
       (SELECT tableinner.[Count]   as [Count]  
           FROM  
           ----------------------------------------------------------     
           (select  count(source.[ExecutiveCompanyID])  as [Count]    
            from  
             ----------------------------------------------------------  
             (
				select distinct
				e.ExecutiveCompanyIDSeq                       as ExecutiveCompanyID, 
				e.CompanyIDSeq                                as CustomerID, 
				e.CompanyName								  as CompanyName,
				(case 
					when e.ActiveFlag = 1 then 'Active'
					when e.ActiveFlag = 0 then 'Inactive'
				end
				)												as Status    
				from CUSTOMERS.dbo.ExecutiveCompany e with (nolock)  
				inner join CUSTOMERS.dbo.Company c with (nolock)
				on c.IDSeq = e.CompanyIDSeq and c.StatusTypeCode = 'ACTIV'         
				where e.CompanyIDSeq = coalesce(@IPVC_CustomerID, e.CompanyIDSeq)
				and   e.CompanyName like '%' + @IPVC_CustomerName + '%' 
				--and   e.ActiveFlag = 1  
		)source  
	   ------------------------------------------------------------------------------  
        ) tableinner  
      -----------------------------------------------------------------------------  
      )  
      SELECT  tablefinal.[Count]      
      from    tablefinal
  end   
  --------------------------------------------------------------------------------------  
  ---Final Cleanup  
  --------------------------------------------------------------------------------------  
END-->Main End  

GO
