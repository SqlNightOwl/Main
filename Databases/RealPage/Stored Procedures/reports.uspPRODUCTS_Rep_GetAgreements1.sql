SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [reports].[uspPRODUCTS_Rep_GetAgreements1] (@IPVC_QUOTEID varchar(50))
AS
BEGIN

  /* This should replace the next query when PriceVersion column is implemented in Products..Product table -- Vinod Krishnan 1/26/07
  select distinct P.FamilyCode from Products..Product P inner join Quotes.dbo.QuoteItem Q on P.Code = Q.Productcode and P.PriceVersion = Q.PriceVersion
  where QuoteIDSeq = @IPVC_QUOTEID

  select distinct FamilyCode
  from Products..Product
  where Code in (select distinct ProductCode from Quotes.dbo.quoteitem where QuoteIDSeq = @IPVC_QUOTEID)
  */
  -------------------------------------------------------------
  --Create Temp Table
  CREATE TABLE #tempAgreement(CompanyIDSeq  varchar(50)   NULL,
      	                      FamilyCode    varchar(3)    NULL,
	                      AgreementName varchar(2000) NULL,
	                      Addendum      text          NULL,
	                      Executed      varchar(50)   NULL,
	                      AgreementDate datetime      NULL, 
	                      DateSent      datetime      NULL
                             )
  ------------------------------------------------------------
  declare @Agreement varchar(8000)
  set @Agreement = ''
  ------------------------------------------------------------
  Insert into #TEMPAgreement(CompanyIDSeq,FamilyCode,AgreementName,Addendum,Executed,AgreementDate,DateSent)
  select A.CompanyIDSeq,(Case when A.familycode = 'OSD' then 'RPM'
                            else A.familycode 
                        end) as  familycode,
         A.AgreementName,A.Addendum,A.Executed,A.AgreementDate,A.DateSent
  from        Customers.dbo.Agreement A with (nolock)
  inner join  Quotes.dbo.Quote            Q with (nolock) 
  on           A.CompanyIDSeq = Q.CustomerIDSeq and Q.QuoteIDSeq = @IPVC_QUOTEID
  and   A.Executed = 'YES'
  and   A.AgreementDate <= getdate()
  and A.familycode in (select 'RPM' as familycode union
                       select P.FamilyCode 
                       from  Quotes.dbo.QuoteItem     QI with (nolock) 
                       inner join Products.dbo.Product P with (nolock) 
                       on    QI.ProductCode = P.Code
                       and   Q.QuoteIDSeq   = @IPVC_QUOTEID
                       and   QI.QuoteIDSeq  = @IPVC_QUOTEID
                       and   Q.QuoteIDSeq   = QI.QuoteIDSeq 
                       and   P.familycode   = A.familycode)  
  order by AgreementDate
  -----------------------------------------------------------------------------------
  --Query to get the Lastest Agreement on familycode of RPM and OSD +
  -- Lastest agreements on Other Familycodes
  select @Agreement = @Agreement + ', ' + AgreementName + ' dated ' + Convert(varchar(15), AgreementDate, 101)
  from #TEMPAgreement A with (nolock)
  where Not Exists (select * from 
                  #TEMPAgreement B with (nolock)
                  where A.CompanyIDSeq = B.CompanyIDSeq 
		  and   A.familycode   = B.familycode
                  and   B.AgreementDate > A.AgreementDate
                 )
  order by AgreementDate
  -----------------------------------------------------------------------------------
  if @Agreement = ''
  begin
    set @Agreement = 'RealPage Master dated:___________'
  end
  else
  begin
    set @Agreement = right(@Agreement, len(@Agreement)-2)
  end

  select @Agreement as Agreement

END

GO
