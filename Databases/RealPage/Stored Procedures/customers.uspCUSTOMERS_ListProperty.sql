SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [customers].[uspCUSTOMERS_ListProperty]  (

                                                      @IPVC_CompanyID varchar(11),
                                                      @IPVC_PropertyName varchar(255),
                                                      @IPVC_City varchar(70),
                                                      @IPVC_State varchar(2),
                                                      @IPVC_PriceCapIDSeq varchar(11)
                                                    )
AS
BEGIN 

										  select p.IDseq  as ID, 
                                                 p.Name   as [Name],
                                                 addr.City as City,
                                                 addr.State as State
												 
                                          from   Customers.dbo.[Property] p with (nolock)
                                          left outer join Customers.dbo.Address addr with (nolock)
                                          on p.IDSeq = addr.PropertyIDSeq 
                                          where addr.AddressTypeCode ='PRO'
										  and p.statustypecode='ACTIV'		
                                          and p.PMCIDSeq = @IPVC_CompanyID
                                          and p.Name like '%'+@IPVC_PropertyName+'%'
                                          and addr.City like '%'+@IPVC_City+'%'
                                          and addr.State like '%'+@IPVC_State+'%'
                                          and  p.IdSeq not in(select PropertyIDSeq from Customers.dbo.PriceCapProperties with (nolock) 
										  where PriceCapIDSeq = @IPVC_PriceCapIDSeq and PropertyIDSeq is not null)
                                          
                                          
UNION  
									 	  select  distinct 'NULL'  as ID, 
                                                 ' '+c.[name]  as [Name],
                                                 '' as City,
                                                 '' as State
										  from   Customers.dbo.Company c with (nolock)
                                           left outer join [Property] p on c.idseq=p.pmcidseq
                                          where 	
                                           c.IDSeq = @IPVC_CompanyID
                                          and p.IdSeq not in(select PropertyIDSeq from Customers.dbo.PriceCapProperties with (nolock) 
										  where PriceCapIDSeq = @IPVC_PriceCapIDSeq and PropertyIDSeq is null)
                                          order by [Name]  

                                          select count(*) from Customers.dbo.[Property] with (nolock) where PMCIDSeq = @IPVC_CompanyID

                           
END

--exec [dbo].[uspCUSTOMERS_ListProperty] 'C0901001467', '','','',''
--exec [dbo].[uspCUSTOMERS_ListProperty] 'C0901000018', '','','','563'
GO
