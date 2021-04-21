SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Procedure [invoices].[temp_usp_return]
(@PMCID Varchar(10),@SiteID Varchar(10))
As
Begin

If Exists(	Select 1
			From [property] p 
			Join company c
				On c.idseq = p.PMCIDSeq
			Left Join account a 
				On a.propertyidseq = p.idseq 
			Left Join account ac 
				On ac.companyidseq = c.idseq 
			Where p.SitemasterID = @SiteID
				And c.SiteMasterID = @PMCID
				And a.Propertyidseq Is Not Null 
				And ac.Companyidseq Is Not Null)
Select Top 1 P.IDSeq As PropertyIDSeq,C.IDSeq As companyIDSeq
From [property] p 
Join company c
	On c.idseq = p.PMCIDSeq
Left Join account a 
	On a.propertyidseq = p.idseq 
Left Join account ac 
	On ac.companyidseq = c.idseq 
Where a.propertyidseq Is Null 
	And ac.companyidseq Is Null 
Else
Select NULL As PropertyIDSeq,NULL As companyIDSeq
end
GO
