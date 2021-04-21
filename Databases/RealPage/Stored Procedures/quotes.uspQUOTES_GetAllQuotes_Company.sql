SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [quotes].[uspQUOTES_GetAllQuotes_Company] (@IPVC_COMPANYID varchar(20), @IPVC_RETURNTYPE  varchar(100) = 'XML')
AS
BEGIN
  set nocount on 
  -----------------------------------------------------------------------------------------------------
  ---Declaring local variables
  declare @LT_AllQuotes  table (seq                       int identity(1,1) not null,    
                                quoteid                   varchar(50)       not null default '0',                                
                                companyid                 varchar(50)       not null default 0,
                                companyname               varchar(300)      not null default '',
                                quotestatuscode           varchar(50)       not null default '',
                                quotestatus               varchar(100)      not null default '',
                                createdby                 varchar(50)       not null default '',
                                createdbydisplayname      varchar(100)      not null default '',
                                createdate                varchar(50),
                                modifiedby                varchar(50)       not null default '',
                                modifiedbydisplayname     varchar(100)      not null default '',
                                modifieddate              varchar(50),
                                expirationdate            varchar(50)
                               )  
  -----------------------------------------------------------------------------------------------------  
  if exists (select Top 1 1 from QUOTES.dbo.Quote (nolock) where CustomerIDSeq = @IPVC_COMPANYID )
  begin
    insert into @LT_AllQuotes(quoteid,companyid,companyname,quotestatuscode,quotestatus,
                              createdby,createdbydisplayname,createdate,
                              modifiedby,modifiedbydisplayname,modifieddate,expirationdate)
    select DISTINCT
           A.QuoteIDSeq                                            as quoteid,
           ltrim(rtrim(A.CustomerIDSeq))                           as companyid,           
           ltrim(rtrim(coalesce(A.companyname,'')))                as companyname,
           ltrim(rtrim(A.quotestatuscode))                         as quotestatuscode,
           (select ltrim(rtrim(B.Name)) 
            from QUOTES.dbo.QuoteStatus B (nolock)
            where ltrim(rtrim(B.Code)) = ltrim(rtrim(A.quotestatuscode))
           )                                                       as quotestatus,
           ltrim(rtrim(coalesce(A.createdby,'')))                  as createdby,
           ltrim(rtrim(coalesce(A.createdbydisplayname,'')))       as createdbydisplayname,
           convert(varchar(50),A.CreateDate,107)                   as createdate,
           ltrim(rtrim(coalesce(A.modifiedby,'')))                 as modifiedby,
           ltrim(rtrim(coalesce(A.modifiedbydisplayname,'')))      as modifiedbydisplayname,
           convert(varchar(50),A.ModifiedDate,107)                 as modifieddate,           
           convert(varchar(50),A.expirationdate,107)               as expirationdate           
    from  QUOTES.DBO.quote A (nolock) 
    where A.CustomerIDSeq = @IPVC_COMPANYID
    order by companyname asc, A.QuoteIDSeq  asc,createdate asc    
  end
  else
  begin
    insert into @LT_AllQuotes(quoteid,companyid,companyname,quotestatuscode,quotestatus,
                              createdby,createdbydisplayname,createdate,
                              modifiedby,modifiedbydisplayname,modifieddate,expirationdate)
    select '0'    as quoteid,
           '0'    as companyid,
           ''     as companyname,           
           'NSU'  as quotestatuscode,
           (select ltrim(rtrim(B.Name)) 
            from QUOTES.dbo.QuoteStatus B (nolock)
            where ltrim(rtrim(B.Code)) = 'NSU'
           )      as quotestatus,
           ''     as createdby,
           ''     as createdbydisplayname,           
           ''     as createdate,
           ''     as modifiedby,
           ''     as modifiedbydisplayname,
           ''     as ModifiedDate,
           ''     as expirationdate                     
  end 
  -------------------------------------------------------------------------------
  --Final Select 
  -------------------------------------------------------------------------------
  if @IPVC_RETURNTYPE = 'XML'
  begin
    select quoteid,companyid,companyname,quotestatuscode,quotestatus,
                              createdby,createdbydisplayname,createdate,
                              modifiedby,modifiedbydisplayname,modifieddate,expirationdate    
    from @LT_AllQuotes 
    order by companyname asc, quoteid  asc,createdate asc
    FOR XML raw ,ROOT('quote'),TYPE
  end
  else
  begin
    select quoteid,companyid,companyname,quotestatuscode,quotestatus,
                              createdby,createdbydisplayname,createdate,
                              modifiedby,modifiedbydisplayname,modifieddate,expirationdate
    from @LT_AllQuotes 
    order by companyname asc, quoteid  asc,createdate asc
  end
END




GO
