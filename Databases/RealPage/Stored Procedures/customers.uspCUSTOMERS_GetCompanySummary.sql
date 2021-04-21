SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* 
exec uspCUSTOMERS_GetCompanySummary @IPC_CompanyID = 'C0000000799',@IPVC_QuoteID = '',@IPVC_RETURNTYPE = 'RECORDSET'
exec uspCUSTOMERS_GetCompanySummary @IPC_CompanyID = 'C0000000799',@IPVC_QuoteID = 'Q0000000576',@IPVC_RETURNTYPE = 'RECORDSET'
*/

CREATE PROCEDURE [customers].[uspCUSTOMERS_GetCompanySummary] (@IPC_CompanyID    varchar(50)  = NULL,
                                                         @IPVC_QuoteID     varchar(50)  = '0',
                                                         @IPVC_RETURNTYPE  varchar(100) = 'XML'                                     
                                                         )
AS
BEGIN
  set nocount on 
  select @IPC_CompanyID = coalesce(ltrim(rtrim(@IPC_CompanyID)),'0')
  select @IPVC_QuoteID  = coalesce(ltrim(rtrim(@IPVC_QuoteID)),'0')  

  -----------------------------------------------------------------------------------------------------
  ---Declaring local variables
  declare @LT_CompanySummary table (seq                       int identity(1,1) not null,
                                    companyid                 varchar(50)       not null default '',
                                    companyname               varchar(300)      not null default '', 
                                    sites                     int               not null default 0,
                                    units                     int               not null default 0,
                                    quotesites                int               not null default 0,
                                    quoteunits                int               not null default 0,  
                                    quotebeds                 int               null,                                      
                                    firstyear                 numeric(30,5)     not null default 0.00,
                                    ilfcharge                 numeric(30,5)     not null default 0.00,
                                    quotestatus               varchar(100)      not null default 'Not Submitted',
                                    expireson                 varchar(50),
                                    createdate                varchar(50),
                                    createdby                 varchar(100)      not null default '',
                                    modifiedby                varchar(100)      not null default '',
                                    accountid                 varchar(50)       default '',
                                    signaturetext             varchar(255)      not null default '',
                                    BusinessUnitLogo          varchar(50)       not null default 'RealPage'
                                   )
  -----------------------------------------------------------------------------------------------------
  if exists (select top 1 1 from CUSTOMERS.DBO.Company (nolock) 
             where IDSeq = @IPC_CompanyID)
  begin
    insert into @LT_CompanySummary(companyid,companyname,sites,units,quotesites,quoteunits,firstyear,ilfcharge,
                                   quotestatus,createdate,expireson,createdby,modifiedby,accountid,signaturetext,quotebeds,
                                   BusinessUnitLogo)
    select distinct summary.IDSeq as companyid,ltrim(rtrim(summary.Name)) as companyname,
                    coalesce((select Count(Z.IDSeq) 
                              from CUSTOMERS.dbo.Property Z (nolock) 
                              where Z.PMCIDSeq = summary.IDSeq
                              and   Z.PMCIDSeq = @IPC_CompanyID
                              and   summary.IDSeq =@IPC_CompanyID
                              and   Z.StatusTypeCode = 'ACTIV' ),0)     as sites,
                    coalesce((select Sum(Z.Units)
                              from CUSTOMERS.dbo.Property Z (nolock) 
                              where Z.PMCIDSeq = summary.IDSeq
                              and   Z.PMCIDSeq = @IPC_CompanyID
                              and   summary.IDSeq =@IPC_CompanyID
                              and   Z.StatusTypeCode = 'ACTIV' ),0)     as units,
                    -----------------------------------------------------------------
                    coalesce((select Count(Z.IDSeq) 
                              from CUSTOMERS.dbo.Property Z (nolock) 
                              where Z.PMCIDSeq    = summary.IDSeq
                              and   Z.PMCIDSeq    = @IPC_CompanyID 
                              and   summary.IDSeq = @IPC_CompanyID
			      and   Z.StatusTypeCode = 'ACTIV'
                              and exists (select top 1 1 
                                          from QUOTES.dbo.GroupProperties X (nolock)
                                          where X.CustomerIDSeq = summary.IDSeq
                                          and   X.CustomerIDSeq = Z.PMCIDSeq
                                          and   X.PropertyIDSeq = Z.IDSeq
                                          and   X.CustomerIDSeq = @IPC_CompanyID
                                          and   Z.PMCIDSeq      = @IPC_CompanyID 
                                          and   summary.IDSeq   = @IPC_CompanyID                                          
                                          and   X.quoteidseq    = @IPVC_QuoteID
                                         )                                          
                             ),0)                                         as quotesites,
                    coalesce((select sum(source.Units)
                             from   (select X.PropertyIDSeq,sum(distinct X.Units) as Units
                                     from   QUOTES.dbo.GroupProperties X (nolock)
                                     where  X.CustomerIDSeq = @IPC_CompanyID
                                     and    X.quoteidseq    = @IPVC_QuoteID
                                     group by X.PropertyIDSeq
                                      ) source
                              ),0)                                        as quoteunits,
                    -----------------------------------------------------------------
                    Coalesce((select (sum(Q.AccessNetExtYear1ChargeAmount))
                              from QUOTES.dbo.QUOTE Q (nolock)
                              where Q.CustomerIDSeq = summary.IDSeq
                              and   Q.CustomerIDSeq = @IPC_CompanyID 
                              and   summary.IDSeq   = @IPC_CompanyID
                              and   Q.QuoteIDSeq    = @IPVC_QuoteID
                             ),0)                                         as firstyear,
                    Coalesce((select (sum(Q.ILFNetExtYearChargeAmount))
                              from QUOTES.dbo.QUOTE Q (nolock)
                              where Q.CustomerIDSeq = summary.IDSeq
                              and   Q.CustomerIDSeq = @IPC_CompanyID 
                              and   summary.IDSeq   = @IPC_CompanyID
                              and   Q.QuoteIDSeq    = @IPVC_QuoteID
                             ),0)                                         as ilfcharge,
                    coalesce((select TOP 1 ltrim(rtrim(Z.Name)) from QUOTES.DBO.QuoteStatus Z (nolock)
                     where  Z.Code = (select Top 1 Q.QuoteStatusCode 
                                      from   QUOTES.dbo.QUOTE Q (nolock)
                                      where  Q.QuoteIDSeq    = @IPVC_QuoteID
                                      and    Q.CustomerIDSeq = summary.IDSeq
                                      and    Q.CustomerIDSeq = @IPC_CompanyID 
                                      and    summary.IDSeq   = @IPC_CompanyID                                      
                                      /*
                                      and    Q.QuoteIDSeq = (select Max(X.QuoteIDSeq) 
                                                        from   QUOTES.dbo.QUOTE X (nolock)
                                                        where  X.CustomerIDSeq = summary.IDSeq
                                                        and    Q.CustomerIDSeq = summary.IDSeq
                                                        and    Q.CustomerIDSeq = @IPC_CompanyID
                                                        and    X.CustomerIDSeq = @IPC_CompanyID
                                                        anD    summary.IDSeq   = @IPC_CompanyID
                                                        ----
                                                        and    (X.ILFNetExtYearChargeAmount > 0 and AccessNetExtYear1ChargeAmount > 0)
                                                        ----
                                                        )
                                      */
                                   )),'Not Submitted') as quotestatus,
                     coalesce((select Top 1 convert(varchar(50),Q.CreateDate,101) 
                               from   QUOTES.dbo.QUOTE Q (nolock)
                                      where  Q.QuoteIDSeq    = @IPVC_QuoteID
                                      and    Q.CustomerIDSeq = summary.IDSeq
                                      and    Q.CustomerIDSeq = @IPC_CompanyID 
                                      and    summary.IDSeq   = @IPC_CompanyID                                      
                                      /*
                                      and    Q.QuoteIDSeq = (select Max(X.QuoteIDSeq) 
                                                        from   QUOTES.dbo.QUOTE X (nolock)
                                                        where  X.CustomerIDSeq = summary.IDSeq
                                                        and    Q.CustomerIDSeq = summary.IDSeq
                                                        and    Q.CustomerIDSeq = @IPC_CompanyID
                                                        and    X.CustomerIDSeq = @IPC_CompanyID
                                                        anD    summary.IDSeq   = @IPC_CompanyID
                                                        ----
                                                        and    (X.ILFNetExtYearChargeAmount > 0 and AccessNetExtYear1ChargeAmount > 0)
                                                        ----
                                                        )
                                      */
                     ),'') as createdate, 
                     coalesce((select Top 1 convert(varchar(50),Q.ExpirationDate,101) 
                               from   QUOTES.dbo.QUOTE Q (nolock)
                                      where  Q.QuoteIDSeq    = @IPVC_QuoteID
                                      and    Q.CustomerIDSeq = summary.IDSeq
                                      and    Q.CustomerIDSeq = @IPC_CompanyID 
                                      and    summary.IDSeq   = @IPC_CompanyID                                      
                                      /*
                                      and    Q.QuoteIDSeq = (select Max(X.QuoteIDSeq) 
                                                        from   QUOTES.dbo.QUOTE X (nolock)
                                                        where  X.CustomerIDSeq = summary.IDSeq
                                                        and    Q.CustomerIDSeq = summary.IDSeq
                                                        and    Q.CustomerIDSeq = @IPC_CompanyID
                                                        and    X.CustomerIDSeq = @IPC_CompanyID
                                                        anD    summary.IDSeq   = @IPC_CompanyID
                                                        ----
                                                        and    (X.ILFNetExtYearChargeAmount > 0 and AccessNetExtYear1ChargeAmount > 0)
                                                        ----
                                                        )
                                      */
                     ),'') as expireson,
                     coalesce(summary.CreatedBy,'')  as  createdby,
                     coalesce(summary.ModifiedBy,'') as  modifiedby,
		     (select top 1 IDSeq from Account with (nolock) where CompanyIDSeq = @IPC_CompanyID and PropertyIDSeq is null and ActiveFlag = 1) as accountid,
		     coalesce(summary.SignatureText,'') as  signaturetext,

                     coalesce((select sum(source.beds)
                              from   (select X.PropertyIDSeq,sum(distinct X.beds) as beds
                                      from   QUOTES.dbo.GroupProperties X (nolock)
                                      inner join
                                             Customers.dbo.Property P with (nolock)
                                      on     X.PropertyIDSeq = P.IDSeq
                                      and    P.PMCIDSEQ      = @IPC_CompanyID
                                      and    P.StudentLivingFlag = 1
                                      and    X.CustomerIDSeq = @IPC_CompanyID
                                      and    X.quoteidseq    = @IPVC_QuoteID
                                      group by X.PropertyIDSeq
                                      ) source
                              ),0)                      as quotebeds,
                     Quotes.dbo.fnGetQuoteBusinessUnitLogo(@IPVC_QuoteID) as BusinessUnitLogo                    
      from  CUSTOMERS.DBO.Company summary (nolock)   
      where summary.IDSeq = @IPC_CompanyID      
  end
  else
  begin
    insert into @LT_CompanySummary(companyid,companyname,sites,units,quotesites,quoteunits,firstyear,ilfcharge,
                                   quotestatus,createdate,expireson,createdby,modifiedby,signaturetext)
    select @IPC_CompanyID as companyid,'' as companyname,0 as sites,0 as units,0 as quotesites,0 as quoteunits,
           0 as firstyear,0 as ilfcharge, 'Not Submitted' as quotestatus,'' as createdate,'' as expireson,
           '' as createdby,'' as modifiedby ,'' as signaturetext     
  end  
  -------------------------------------------------------------------------------
  --Final Select 
  -------------------------------------------------------------------------------
  if @IPVC_RETURNTYPE = 'XML'
  begin
    select companyid,companyname,
           (case when sites=0 then '--'
                else CUSTOMERS.DBO.fn_FormatCurrency(sites,0,0) 
           end)                                                 as sites,
           (case when units=0 then '--'
                else CUSTOMERS.DBO.fn_FormatCurrency(units,0,0) 
           end)                                                 as units,
           (case when quotesites=0 then '--'
                else CUSTOMERS.DBO.fn_FormatCurrency(quotesites,0,0) 
           end)                                                as quotesites,
           (case when quoteunits=0 then '--'
                else CUSTOMERS.DBO.fn_FormatCurrency(quoteunits,0,0) 
           end)                                                as quoteunits,            
           CUSTOMERS.DBO.fn_FormatCurrency(firstyear,0,0)      as firstyear,
           CUSTOMERS.DBO.fn_FormatCurrency(ilfcharge,0,0)      as ilfcharge,
           quotestatus,createdate,expireson,createdby,modifiedby,accountid,signaturetext,
           (case when quotebeds = 0 then '--'
                  else CUSTOMERS.DBO.fn_FormatCurrency(quotebeds,0,0)
            end)                                               as beds,
           BusinessUnitLogo                                    as BusinessUnitLogo
    from @LT_CompanySummary FOR XML raw ,ROOT('companysummary'),TYPE
  end
  else
  begin
    select companyid,companyname,
           (case when sites=0 then '--'
                else CUSTOMERS.DBO.fn_FormatCurrency(sites,0,0) 
           end)                                                 as sites,
           (case when units=0 then '--'
                else CUSTOMERS.DBO.fn_FormatCurrency(units,0,0) 
           end)                                                 as units,
           (case when quotesites=0 then '--'
                else CUSTOMERS.DBO.fn_FormatCurrency(quotesites,0,0) 
           end)                                                as quotesites,
           (case when quoteunits=0 then '--'
                else CUSTOMERS.DBO.fn_FormatCurrency(quoteunits,0,0) 
           end)                                                as quoteunits,            
           CUSTOMERS.DBO.fn_FormatCurrency(firstyear,0,0)      as firstyear,
           CUSTOMERS.DBO.fn_FormatCurrency(ilfcharge,0,0)      as ilfcharge,
           quotestatus,createdate,expireson,createdby,modifiedby,accountid,signaturetext,
           (case when quotebeds = 0 then '--'
                  else CUSTOMERS.DBO.fn_FormatCurrency(quotebeds,0,0)
            end)                                               as beds,
           BusinessUnitLogo                                    as BusinessUnitLogo
    from @LT_CompanySummary
  end
END
GO
