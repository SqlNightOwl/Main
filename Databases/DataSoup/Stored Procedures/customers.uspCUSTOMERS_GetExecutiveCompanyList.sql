SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : CUSTOMERS  
-- Procedure Name  : uspCUSTOMERS_GetExecutiveCompanyList  
-- Description     : This procedure gets the list of Executive Companies which are in Active State
-- Revision History:  
-- Author          : Mahaboob  
-- 07/27/2011      : Stored Procedure Created. 
-- 2011-09-06      : Mahaboob ( TFS 1026)     --  Changes  are made as per the Revised "ExecutiveCompany" table script  
------------------------------------------------------------------------------------------------------  
CREATE procedure [customers].[uspCUSTOMERS_GetExecutiveCompanyList]   
AS  
BEGIN-->Main Begin  
          select 
          upper(E.CompanyIDSeq)				as [Customer ID],   
          upper(E.CompanyName)				as [Name],
          upper(E.ExecutiveCompanyIDSeq)	as [ExecutiveIDSeq]
          from CUSTOMERS.dbo.ExecutiveCompany E with (nolock) 
		  inner join
          Customers.dbo.Company C with (nolock)
          on C.IDSeq = E.CompanyIDSeq and C.StatusTypeCode = 'ACTIV'     
          where E.ActiveFlag = 1 
END--->Main End  
  
GO
