SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetCompanyAgreements] (@IPVC_QUOTEID varchar(50))
AS
BEGIN
  declare @LVC_CompanyID  varchar(50)
  ----------------------------------------------------
  select @LVC_CompanyID = Q.CustomerIDSeq
  from   QUOTES.dbo.QUOTE Q with (nolock)
  where  QuoteIDSeq     = @IPVC_QUOTEID
  ----------------------------------------------------
  select distinct 
         A.FamilyCode                            as FamilyCode,
         D.Name                                  as AgreementName,
         coalesce(A.BeginDate,A.ExecutedDate)    as AgreementDate,
	 D.Name + ' dated ' + Convert(varchar(50),coalesce(A.BeginDate,A.ExecutedDate), 101) as AgreementDisplayName
  From   DOCS.dbo.Contract A with (nolock)
          INNER JOIN DOCS.DBO.Document D WITH (NOLOCK)
            on A.IDSeq = D.ContractIDSeq
  where  A.CompanyIDSeq     = @LVC_CompanyID
  and    A.TypeCode = 'AGR' 
  and    (D.StatusCode = 'APD' AND D.ActiveFlag = 1)
--  and    Not Exists (select * 
--                     from  DOCS.DBO.Contract B with (nolock)
--                     where A.CompanyIDSeq = B.CompanyIDSeq 
--                     and   B.CompanyIDSeq = @LVC_CompanyID
--                     and   A.CompanyIDSeq = @LVC_CompanyID
--                     and   A.TypeCode = B.TypeCode
--                     and   A.TypeCode = 'AGR' 
--                     and   B.TypeCode = 'AGR' 
--		     and   (Case when A.familycode = 'OSD' then 'RPM'
--                                 else A.familycode 
--                            end)  = (Case when B.familycode = 'OSD' then 'RPM'
--                                          else B.familycode 
--                                     end)
--                     and   convert(datetime,convert(varchar(50),B.ExecutedDate,101)) > 
--                           convert(datetime,convert(varchar(50),A.ExecutedDate,101)) 
--                     )
--  order by A.FamilyCode asc,A.ExecutedDate
  ----------------------------------------------------
END

GO
