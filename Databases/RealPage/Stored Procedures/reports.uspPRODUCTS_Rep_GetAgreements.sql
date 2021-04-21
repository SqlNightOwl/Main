SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [reports].[uspPRODUCTS_Rep_GetAgreements] (@IPVC_QUOTEID varchar(50))
AS
BEGIN
  -------------------------------------------------------------
  --Create Temp Table
  CREATE TABLE #tempAgreement(CompanyIDSeq           varchar(50)   NULL,
      	                      FamilyCode             varchar(3)    NULL,
	                      AgreementName          varchar(2000) NULL,	                      
	                      AgreementSignedDate    datetime      NULL, 
	                      AgreementSentDate      datetime      NULL,
                              AgreementDisplayName   varchar(4000) NULL
                             )
  ------------------------------------------------------------
  declare @LVC_CompanyID  varchar(50)
  declare @Agreement varchar(8000)
  set @Agreement = ''  
  ----------------------------------------------------
  select @LVC_CompanyID = Q.CustomerIDSeq
  from   QUOTES.dbo.QUOTE Q with (nolock)
  where  QuoteIDSeq     = @IPVC_QUOTEID
  ----------------------------------------------------
  Insert into #TEMPAgreement(CompanyIDSeq,FamilyCode,AgreementName,AgreementSignedDate,AgreementSentDate,AgreementDisplayName)
  select distinct
         A.CompanyIDSeq          as CompanyIDSeq, 
         A.FamilyCode            as FamilyCode,
         A.Name                  as AgreementName,
         A.AgreementSignedDate   as AgreementSignedDate,
         A.AgreementSentDate     as AgreementSentDate,
		 A.Name + ' dated ' + Convert(varchar(50), A.AgreementSignedDate, 101) as AgreementDisplayName
  From   DOCUMENTS.dbo.Document A with (nolock)
  where  A.CompanyIDSeq     = @LVC_CompanyID
  and    A.DocumentTypeCode = 'AGGR' 
  and    (A.AgreementExecutedFlag = 1 Or A.ActiveFlag = 1)
  and    Not Exists (select * 
                     from  DOCUMENTS.dbo.Document B with (nolock)
                     where A.CompanyIDSeq = B.CompanyIDSeq 
                     and   B.CompanyIDSeq = @LVC_CompanyID
                     and   A.CompanyIDSeq = @LVC_CompanyID
                     and   A.DocumentTypeCode = B.DocumentTypeCode
                     and   A.DocumentTypeCode = 'AGGR' 
                     and   B.DocumentTypeCode = 'AGGR' 
		     and   (Case when A.familycode = 'OSD' then 'RPM'
                                 else A.familycode 
                            end)  = (Case when B.familycode = 'OSD' then 'RPM'
                                          else B.familycode 
                                     end)
                     and   convert(datetime,convert(varchar(50),B.AgreementSignedDate,101)) > 
                           convert(datetime,convert(varchar(50),A.AgreementSignedDate,101)) 
                     )
  and A.familycode in (select 'RPM' as familycode union
                       select 'OSD' as familycode union
                       select P.FamilyCode 
                       from  Quotes.dbo.QuoteItem      QI with (nolock) 
                       inner join Products.dbo.Product P  with (nolock) 
                       on    QI.ProductCode = P.Code  
                       and   QI.PriceVersion= P.PriceVersion                     
                       and   QI.QuoteIDSeq  = @IPVC_QUOTEID                       
                       and   P.familycode   = A.familycode)
  order by A.AgreementSignedDate Asc
  -----------------------------------------------------------------------------------
  --Query to get the Lastest Agreement on familycode of RPM and OSD +
  -- Lastest agreements on Other Familycodes
  select @Agreement = @Agreement + ', ' + AgreementDisplayName
  from #TEMPAgreement A with (nolock)  
  order by A.AgreementSignedDate Asc
  -----------------------------------------------------------------------------------
  if @Agreement = ''
  begin
    set @Agreement = ''
  end
  else
  begin
    set @Agreement = right(@Agreement,len(@Agreement)-2)
  end
  -----------------------------------------------------------------------------------

  select @Agreement as Agreement
  -----------------------------------------------------------------------------------
  --Final CleanUp
  drop table #tempAgreement
  -----------------------------------------------------------------------------------
END

GO
