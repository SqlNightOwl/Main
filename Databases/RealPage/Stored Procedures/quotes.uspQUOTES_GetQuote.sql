SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--exec uspQUOTES_GetQuote 'A0000000001'

CREATE PROCEDURE [quotes].[uspQUOTES_GetQuote]  (@IPVC_CompanyID    varchar(50) = ''                                      
                                         )
AS
BEGIN
  set nocount on 
  if exists (select Top 1 1 from QUOTES.DBO.quote (nolock) where ltrim(rtrim(CustomerIDSeq)) = @IPVC_CompanyID)
  begin
    select ltrim(rtrim(A.CustomerIDSeq))                as companyid,
           A.QuoteIDSeq                                 as quoteid,
           ltrim(rtrim(coalesce(A.companyname,'')))     as companyname,
           ltrim(rtrim(A.quotestatuscode))              as quotestatuscode,
           (select ltrim(rtrim(B.Name)) 
            from QUOTES.dbo.QuoteStatus B (nolock)
            where ltrim(rtrim(B.Code)) = ltrim(rtrim(A.quotestatuscode))
           )                                            as quotestatus,
           ltrim(rtrim(coalesce(A.createdby,'')))       as createdby,
           ltrim(rtrim(coalesce(A.modifiedby,'')))      as modifiedby,
           ltrim(rtrim(coalesce(A.createdbydisplayname,'')))   as createdbydisplayname,
           ltrim(rtrim(coalesce(A.modifiedbydisplayname,'')))  as modifiedbydisplayname,
           convert(varchar(50),A.expirationdate,107)           as expirationdate,
           ''                                                  as internalquoteid
    from  QUOTES.DBO.quote A (nolock) 
    where ltrim(rtrim(A.CustomerIDSeq)) = @IPVC_CompanyID
    FOR XML raw ,ROOT('quote'), TYPE
  end
  else
  begin
    select @IPVC_CompanyID    as companyid,
           ''     as companyname,
           '0'    as quoteid,
           'NSU'  as quotestatuscode,
           (select ltrim(rtrim(B.Name)) 
            from QUOTES.dbo.QuoteStatus B (nolock)
            where ltrim(rtrim(B.Code)) = 'NSU'
           )      as quotestatus,
           ''     as createdby,
           ''     as modifiedby,
           ''     as createdbydisplayname,
           ''     as modifiedbydisplayname,
           ''     as expirationdate,
           newid() as internalquoteid        
    FOR XML raw ,ROOT('quote'), TYPE
  end 
END
GO
