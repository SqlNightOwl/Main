SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* 
exec customers.dbo.uspCUSTOMERS_Report_GetCompanySummary @IPC_CompanyID='C0000032910',@IPVC_QuoteID='Q0000005400'
exec customers.dbo.uspCUSTOMERS_Report_GetCompanySummary @IPC_CompanyID='C0000032910',
@IPVC_QuoteID='Q0000005367|Q0000005398|Q0000005399|Q0000005400'
*/

CREATE PROCEDURE [reports].[uspCUSTOMERS_Report_GetCompanySummary] (@IPC_CompanyID    varchar(50)    = NULL,
                                                                @IPVC_QuoteID     varchar(8000)  = '0', 
                                                                @IPVC_Delimiter   varchar(1)     = '|'                                  
                                                               )
AS
BEGIN
  set nocount on 
  declare @LI_CompanySites          int
  declare @LI_CompanyUnits          int
  declare @LVC_companyname          varchar(300) 
  declare @LVC_companySignatureText varchar(8000)

  select @LI_CompanySites=0,@LI_CompanyUnits=0,@LVC_companySignatureText=''

  select @IPC_CompanyID = coalesce(ltrim(rtrim(@IPC_CompanyID)),'0')
  -----------------------------------------------------------------------------------
  declare @LT_Quotes  TABLE (QuoteID varchar(50)) 
  -----------------------------------------------------------------------------------
  --Parse the string to get all the Quotes.
  insert into @LT_Quotes(QuoteID)
  select Items as QuoteID from QUOTES.dbo.fnSplitDelimitedString(@IPVC_QuoteID,@IPVC_Delimiter)
  -----------------------------------------------------------------------------------  
  ---Declaring local variables
  declare @LT_CompanySummary table (seq                       int identity(1,1) not null,                                    
                                    companyid                 varchar(50)       not null default '',
                                    companyname               varchar(300)      not null default '', 
                                    sites                     int               not null default 0,
                                    units                     int               not null default 0,
                                    quoteid                   varchar(50)       null,
                                    quotesites                int               not null default 0,
                                    quoteunits                int               not null default 0,  
                                    firstyear                 numeric(30,5)     not null default 0.00,
                                    ilfcharge                 numeric(30,5)     not null default 0.00,
                                    expireson                 varchar(50),
                                    createdate                varchar(50),
                                    createdby                 varchar(100)      not null default '',
                                    modifiedby                varchar(100)      not null default '',
                                    signaturetext             varchar(255)      not null default ''
                                   )
  -----------------------------------------------------------------------------------------------------
  if exists (select top 1 1 from CUSTOMERS.DBO.Company with (nolock) 
             where IDSeq = @IPC_CompanyID)
  begin
    select @LVC_companyname = ltrim(rtrim(coalesce(C.Name,''))),
           @LVC_companySignatureText = ltrim(rtrim(coalesce(C.signaturetext,'')))
    from   CUSTOMERS.DBO.Company C with (nolock)
    where  IDSEQ = @IPC_CompanyID

    select @LI_CompanySites = count(P.Idseq),@LI_CompanyUnits = coalesce(sum(P.Units),0)
    from   CUSTOMERS.DBO.Property P with (nolock)
    where  P.PMCIDSeq = @IPC_CompanyID
    and    P.StatusTypeCode = 'ACTIV'

    insert into @LT_CompanySummary(companyid,companyname,sites,units,
                                   quoteid,quotesites,quoteunits,firstyear,ilfcharge,
                                   createdate,expireson,createdby,modifiedby,signaturetext)
    select distinct @IPC_CompanyID       as companyid,
                    @LVC_companyname     as companyname,
                    @LI_CompanySites     as sites,
                    @LI_CompanyUnits     as units,
                    Q.QuoteIDSeq         as quoteid,
                    -----------------------------------------------------------------
                    coalesce((select Count(Z.IDSeq) 
                              from CUSTOMERS.dbo.Property Z with (nolock) 
                              where Z.PMCIDSeq    = Q.CustomerIDSeq
                              and   Z.PMCIDSeq    = @IPC_CompanyID                               
                              and   Z.StatusTypeCode = 'ACTIV'
                              and exists (select top 1 1 
                                          from QUOTES.dbo.GroupProperties X with (nolock)
                                          where X.quoteidseq    = Q.QuoteIDSeq                                         
                                          and   X.CustomerIDSeq = Q.CustomerIDSeq
                                          and   X.CustomerIDSeq = Z.PMCIDSeq
                                          and   X.PropertyIDSeq = Z.IDSeq
                                          and   X.CustomerIDSeq = @IPC_CompanyID
                                          and   Z.PMCIDSeq      = @IPC_CompanyID                                                                                   
                                          
                                         )                                          
                             ),0)                                         as quotesites,
                    coalesce((select sum(Z.QuotableUnits) 
                              from CUSTOMERS.dbo.Property Z with (nolock) 
                              where Z.PMCIDSeq    = Q.CustomerIDSeq
                              and   Z.PMCIDSeq    = @IPC_CompanyID                               
                              and   Z.StatusTypeCode = 'ACTIV'
                              and exists (select top 1 1 
                                          from QUOTES.dbo.GroupProperties X with (nolock)
                                          where X.quoteidseq    = Q.QuoteIDSeq                                         
                                          and   X.CustomerIDSeq = Q.CustomerIDSeq
                                          and   X.CustomerIDSeq = Z.PMCIDSeq
                                          and   X.PropertyIDSeq = Z.IDSeq
                                          and   X.CustomerIDSeq = @IPC_CompanyID
                                          and   Z.PMCIDSeq      = @IPC_CompanyID                                                                                   
                                          )                                        
                             ),0)                                        as quoteunits,
                    -----------------------------------------------------------------
                   sum(Q.AccessNetExtYear1ChargeAmount)                  as firstyear,
                   sum(Q.ILFNetExtYearChargeAmount)                      as ilfcharge,
                   convert(varchar(50),max(Q.CreateDate),101)            as createdate,
                   convert(varchar(50),max(Q.ExpirationDate),101)        as expireson,
                   coalesce(max(Q.CreatedBy),'')                         as createdby,
                   coalesce(max(Q.ModifiedBy),'')                        as ModifiedBy,
                   @LVC_companySignatureText                             as signaturetext
    from   Quotes.dbo.Quote Q with (nolock)
    inner join
           @LT_Quotes  S 
    on     Q.QuoteIDSeq    = S.QuoteID
    and    Q.CustomerIDSeq = @IPC_CompanyID
    group by Q.QuoteIDSeq,Q.CustomerIDSeq    
  end
  else
  begin
    insert into @LT_CompanySummary(companyid,companyname,sites,units,quotesites,quoteunits,firstyear,ilfcharge,
                                   createdate,expireson,createdby,modifiedby,signaturetext)
    select @IPC_CompanyID as companyid,'' as companyname,0 as sites,0 as units,0 as quotesites,0 as quoteunits,
           0 as firstyear,0 as ilfcharge, '' as createdate,'' as expireson,
           '' as createdby,'' as modifiedby,'' as signaturetext      
  end  
  -------------------------------------------------------------------------------
  --Final Select 
  ------------------------------------------------------------------------------- 

  select companyid,companyname,
           CUSTOMERS.DBO.fn_FormatCurrency(sites,0,0)          as sites,
           CUSTOMERS.DBO.fn_FormatCurrency(units,0,0)          as units,
	   quoteid                                             as quoteid,
           CUSTOMERS.DBO.fn_FormatCurrency(quotesites,0,0)     as quotesites,
           CUSTOMERS.DBO.fn_FormatCurrency(quoteunits,0,0)     as quoteunits,
           CUSTOMERS.DBO.fn_FormatCurrency(firstyear,0,0)      as firstyear,
           CUSTOMERS.DBO.fn_FormatCurrency(ilfcharge,0,0)      as ilfcharge, 
           createdate,expireson,createdby,modifiedby,
           signaturetext
  from @LT_CompanySummary
END

GO
