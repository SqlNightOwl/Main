SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_GetCompanyPropertybySiteID
-- Description     :  return companyid and proeprty id if account id is null
-- Input Parameters: As Below in Sequential order.
-- Code Example    :  exec [uspCUSTOMERS_GetCompanyPropertybySiteID] 1050769,1014845
-- Revision History:
-- Author          : Raghavender
-- 09/09/2011 
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetCompanyPropertybySiteID] (@IPBI_PMCID          varchar(20), @IPBI_SITEID          varchar(20))
 AS
BEGIN


If Exists(	Select 1
			From property p 
			Join company c
				On c.idseq = p.PMCIDSeq
			Left Join account a 
				On a.propertyidseq = p.idseq 
			Left Join account ac 
				On ac.companyidseq = c.idseq 
			Where ( p.SitemasterID = @IPBI_SITEID  or p.idseq = @IPBI_SITEID)
    And (c.SiteMasterID = @IPBI_PMCID  or c.idseq = @IPBI_PMCID) 
				And (a.Propertyidseq Is Null 
				Or ac.Companyidseq Is Null))
Select Top 1 P.IDSeq As PropertyIDSeq,C.IDSeq As companyIDSeq
From property p 
Join company c
	On c.idseq = p.PMCIDSeq
Left Join account a 
	On a.propertyidseq = p.idseq 
Left Join account ac 
	On ac.companyidseq = c.idseq 
Where	( p.SitemasterID = @IPBI_SITEID  or p.idseq = @IPBI_SITEID)
    And (c.SiteMasterID = @IPBI_PMCID  or c.idseq = @IPBI_PMCID) 
		And (a.propertyidseq Is Null  
		Or ac.companyidseq Is Null  )				
Else
Select NULL As PropertyIDSeq,NULL As companyIDSeq
 
END
GO
