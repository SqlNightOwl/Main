SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_GetActiveExecutiveCompaniesForExport]
-- Revision History:  
-- 2011-09-14      : Mahaboob ( TFS 1030)     -- Get Active Executive Companies for Export 
------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetActiveExecutiveCompaniesForExport] 
as   
BEGIN  
		select 
		e.ExecutiveCompanyIDSeq                       as [Executive Company ID], 
		e.CompanyIDSeq								  as [Customer ID], 
		e.CompanyName								  as [Executive Company/Customer Name],
		c.IDSeq                                       as [Child Company ID],
        c.Name										  as [Child Company Name]    
		from CUSTOMERS.dbo.ExecutiveCompany e with (nolock) 
		left outer join CUSTOMERS.dbo.Company c with (nolock)
		on c.ExecutiveCompanyIDSeq = e.ExecutiveCompanyIDSeq and c.StatusTypeCode = 'ACTIV'
		where e.ActiveFlag = 1     
END  
GO
