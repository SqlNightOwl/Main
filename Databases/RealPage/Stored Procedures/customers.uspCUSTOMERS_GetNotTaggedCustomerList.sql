SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : CUSTOMERS  
-- Procedure Name  : uspCUSTOMERS_GetNotTaggedCustomerList  
-- Description     : This procedure gets list of Customers which are not tagged as "Executive Company"  
-- Revision History:  
-- Author          : Mahaboob  
-- 07/27/2011      : Stored Procedure Created.
-- 2011-09-06      : Mahaboob ( TFS 1026)     --  Changes  are made as per the Revised "ExecutiveCompany" table script   
------------------------------------------------------------------------------------------------------  
CREATE procedure [customers].[uspCUSTOMERS_GetNotTaggedCustomerList]   
AS  
BEGIN-->Main Begin  
          select 
          upper(C.IDSeq)         as [Customer ID],   
          upper(C.Name)          as [Name]            
          from CUSTOMERS.dbo.Company C with (nolock)    
          left outer join  
          Customers.dbo.ExecutiveCompany E with (nolock)    
		  ON  C.IDSeq = E.CompanyIDSeq  
		  where E.CompanyIDSeq is null 
		  and C.ExecutiveCompanyIDSeq is null and C.StatusTypeCode = 'ACTIV' 
		  and ( C.PMCFlag = 1 or C.VendorFlag = 1 ) and C.OwnerFlag = 0
          order by C.Name  
END--->Main End  
  
  
GO
