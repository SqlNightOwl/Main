SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
--bpquotesummary
Exec uspQUOTES_GetBillingProjections @IPVC_recordidentificationtype = 'bpquotesummary',
     @IPC_CompanyID='C0000000387',@IPVC_QuoteID='Q0000000002',@IPVC_RETURNTYPE ='RECORDSET'
----------------------------------------------------------------------
--bpbundlesummary
Exec uspQUOTES_GetBillingProjections @IPVC_recordidentificationtype = 'bpbundlesummary',
    @IPC_CompanyID='C0000000387',@IPVC_QuoteID='Q0000000002',@IPVC_Fees = 'Initial License Fees',@IPVC_RETURNTYPE ='RECORDSET'

Exec uspQUOTES_GetBillingProjections @IPVC_recordidentificationtype = 'bpbundlesummary',
    @IPC_CompanyID='C0000000387',@IPVC_QuoteID='Q0000000002',@IPVC_Fees = 'Access Fees - First Year',@IPVC_RETURNTYPE ='RECORDSET'

Exec uspQUOTES_GetBillingProjections @IPVC_recordidentificationtype = 'bpbundlesummary',
    @IPC_CompanyID='C0000000387',@IPVC_QuoteID='Q0000000002',@IPVC_Fees = 'Access Fees - Second Year',@IPVC_RETURNTYPE ='RECORDSET'

Exec uspQUOTES_GetBillingProjections @IPVC_recordidentificationtype = 'bpbundlesummary',
    @IPC_CompanyID='C0000000387',@IPVC_QuoteID='Q0000000002',@IPVC_Fees = 'Access Fees - Third Year',@IPVC_RETURNTYPE ='RECORDSET'
----------------------------------------------------------------------
--bpbundledetail
Exec uspQUOTES_GetBillingProjections @IPVC_recordidentificationtype = 'bpbundledetail',
    @IPC_CompanyID='C0000000387',@IPVC_QuoteID='Q0000000002',@IPVC_Fees = 'Initial License Fees',
    @IPI_GroupID = 4,@IPVC_RETURNTYPE ='RECORDSET'

Exec uspQUOTES_GetBillingProjections @IPVC_recordidentificationtype = 'bpbundledetail',
    @IPC_CompanyID='C0000000387',@IPVC_QuoteID='Q0000000002',@IPVC_Fees = 'Access Fees - First Year',
    @IPI_GroupID = 4,@IPVC_RETURNTYPE ='RECORDSET'

Exec uspQUOTES_GetBillingProjections @IPVC_recordidentificationtype = 'bpbundledetail',
    @IPC_CompanyID='C0000000387',@IPVC_QuoteID='Q0000000002',@IPVC_Fees = 'Access Fees - Second Year',
    @IPI_GroupID = 4,@IPVC_RETURNTYPE ='RECORDSET'

Exec uspQUOTES_GetBillingProjections @IPVC_recordidentificationtype = 'bpbundledetail',
    @IPC_CompanyID='C0000000387',@IPVC_QuoteID='Q0000000002',@IPVC_Fees = 'Access Fees - Third Year',
    @IPI_GroupID = 4,@IPVC_RETURNTYPE ='RECORDSET'
----------------------------------------------------------------------

*/

CREATE PROCEDURE [quotes].[uspQUOTES_GetBillingProjections] (@IPVC_recordidentificationtype  varchar(50) = 'bpquotesummary',
                                                          @IPC_CompanyID     varchar(11),
                                                          @IPVC_QuoteID      varchar(50),                                                          
                                                          @IPVC_Fees         varchar(100) = 'Initial License Fees',
                                                          @IPI_GroupID       bigint = 0,                                                          
                                                          @IPVC_RETURNTYPE   varchar(100) = 'XML'                                                                                                                                                                   
                                                          )
AS
BEGIN   
  set nocount on 
  -----------------------------------------------------------------------------------
  --Declaring Local Variables 
  declare @LI_QuoteSites  int
  declare @LI_QuoteUnits  int
  
  select @LI_QuoteSites=0,@LI_QuoteUnits=0

  select @IPC_CompanyID = ltrim(rtrim(@IPC_CompanyID))
  -----------------------------------------------------------------------------------
  --QuoteSummary
  if (@IPVC_recordidentificationtype = 'bpquotesummary')
  begin ---> Begining of bpquotesummary   
    --Declare Local Table @LT_BPQuoteSummary
    declare @LT_BPQuoteSummary TABLE(seq                      bigint        not null default 1,
                                     recordidentificationtype varchar(50)   not null default 'bpquotesummary',
                                     companyid                varchar(50)   not null default 0,
                                     quotestatus              varchar(5)            default 'NSU', 
                                     quoteid                  varchar(50)   not null default '0',
                                     fees                     varchar(100)  not null default '',
                                     sites                    int           not null default 1,
                                     units                    int           not null default 1,
                                     listprice                money         not null default 0,  
                                     discountpercent          as  ((listprice-netprice)* (100)/
                                                                   (case when listprice=0 then 1 
                                                                         else listprice 
                                                                    end
                                                                   )                                                        
                                                                  ),
                                     discountamount           as (listprice-netprice),
                                     netprice                 money         not null default 0,
                                     averagespersite          as ((netprice)/(case when sites = 0 then 1 else sites end)),
                                     averagesperunit          as ((netprice)/(case when units = 0 then 1 else units end))
                                    )
    -------------------------------------------------------------------
    select @LI_QuoteSites = Sites,@LI_QuoteUnits = Units
    from   QUOTES.dbo.Quote (nolock) where QuoteIDseq = @IPVC_QuoteID
    ---------------------------------------------------------------
    insert into @LT_BPQuoteSummary(seq,quoteid,quotestatus,companyid,fees,sites,units,listprice,netprice)
    select 1 as seq,
           Q.QuoteIDSeq                          as quoteid,
           Q.QuoteStatusCode                     as quotestatus,
           @IPC_CompanyID                        as companyid,
           'Initial License Fees'                as fees,
           Q.Sites                               as sites,
           Q.units                               as units,
           Q.ILFExtYearChargeAmount              as listprice,         
           Q.ILFNetExtYearChargeAmount           as netprice     
    from   Quotes.dbo.[Quote] Q (nolock) 
    where  Q.QuoteIDSeq    = @IPVC_QuoteID 
    and    Q.CustomerIDSeq = @IPC_CompanyID
   
    insert into @LT_BPQuoteSummary(seq,quoteid,quotestatus,companyid,fees,sites,units,listprice,netprice)
    select 2 as seq,
           Q.quoteIDSeq                          as quoteid,
           Q.QuoteStatusCode                     as quotestatus,
           @IPC_CompanyID                        as companyid,
           'Access Fees - Year I'                as fees,
           Q.Sites                               as sites,
           Q.units                               as units,
           Q.AccessExtYear1ChargeAmount          as listprice,         
           Q.AccessNetExtYear1ChargeAmount       as netprice  
    from   Quotes.dbo.[Quote] Q (nolock) 
    where  Q.QuoteIDSeq = @IPVC_QuoteID
    and    Q.CustomerIDSeq = @IPC_CompanyID
    
    insert into @LT_BPQuoteSummary(seq,quoteid,quotestatus,companyid,fees,sites,units,listprice,netprice)
    select 3 as seq,
           Q.quoteIDSeq                          as quoteid,
           Q.QuoteStatusCode                     as quotestatus,
           @IPC_CompanyID                        as companyid,
           'Access Fees - Year II'               as fees,
           Q.Sites                               as sites,
           Q.units                               as units,
           Q.AccessExtYear2ChargeAmount          as listprice,         
           Q.AccessNetExtYear2ChargeAmount       as netprice  
    from   Quotes.dbo.[Quote] Q (nolock) 
    where  Q.QuoteIDSeq = @IPVC_QuoteID
    and    Q.CustomerIDSeq = @IPC_CompanyID
 
    insert into @LT_BPQuoteSummary(seq,quoteid,quotestatus,companyid,fees,sites,units,listprice,netprice)
    select 4 as seq,
           Q.quoteIDSeq                          as quoteid,
           Q.QuoteStatusCode                     as quotestatus,
           @IPC_CompanyID                        as companyid,
           'Access Fees - Year III'              as fees,
           Q.Sites                               as sites,
           Q.units                               as units,
           Q.AccessExtYear3ChargeAmount          as listprice,         
           Q.AccessNetExtYear3ChargeAmount       as netprice  
    from   Quotes.dbo.[Quote] Q (nolock) 
    where  Q.QuoteIDSeq = @IPVC_QuoteID
    and    Q.CustomerIDSeq = @IPC_CompanyID

    ----------------------------------------------
    if (select count(*) from @LT_BPQuoteSummary) = 0
    begin 
      insert into @LT_BPQuoteSummary(seq,quoteid,companyid,fees,sites,units,listprice,netprice)
      select 1 as Seq,@IPVC_QuoteID  as quoteid,@IPC_CompanyID as companyid,
             'Initial License Fees' as fees,0 as sites,0 as units,0 as listprice,0 as netprice
      union
      select 2 as Seq,@IPVC_QuoteID as quoteid,@IPC_CompanyID as companyid,
             'Access Fees - Year I' as fees,0 as sites,0 as units,0 as listprice,0 as netprice
      union
      select 3 as Seq,@IPVC_QuoteID as quoteid,@IPC_CompanyID as companyid,
             'Access Fees - Year II' as fees,0 as sites,0 as units,0 as listprice,0 as netprice
      union
      select 4 as Seq,@IPVC_QuoteID as quoteid,@IPC_CompanyID as companyid,
             'Access Fees - Year III' as fees,0 as sites,0 as units,0 as listprice,0 as netprice
    end
    ----------------------------------------------
    --add Total for QuoteSummary
    insert into @LT_BPQuoteSummary(seq,recordidentificationtype,companyid,quoteid,quotestatus,
                                   fees,sites,units,listprice,netprice)
    select 9999999999                      as seq,
           'total'                         as recordidentificationtype,
           BPQS.companyid                  as companyid,
           BPQS.quoteid                    as quoteid,
           ''                              as quotestatus,
           'Total for 3 Years'             as fees,
           coalesce(@LI_QuoteSites,0)      as sites,
           coalesce(@LI_QuoteUnits,0)      as units,    
           coalesce(sum(BPQS.listprice),0) as listprice,
           coalesce(sum(BPQS.netprice),0)  as netprice
    from   @LT_BPQuoteSummary  BPQS
    group by BPQS.companyid,BPQS.quoteid
    ----------------------------------------------------------------------------------- 
    --Final Select for bpquotesummary
    -----------------------------------------------------------------------------------                 
    if @IPVC_RETURNTYPE = 'XML'
    begin
      select Z.recordidentificationtype,Z.companyid,Z.quoteid,z.quotestatus,Z.fees,
             Quotes.DBO.fn_FormatCurrency(Z.listprice,0,0)       as listprice,
             Quotes.DBO.fn_FormatCurrency(Z.discountpercent,1,1) as discountpercent,
             Quotes.DBO.fn_FormatCurrency(Z.discountamount,0,0)  as discountamount,          
             Quotes.DBO.fn_FormatCurrency(Z.netprice,0,0)        as netprice,
             Quotes.DBO.fn_FormatCurrency(Z.sites,0,0)           as sites,
             Quotes.DBO.fn_FormatCurrency(Z.units,0,0)           as units,
             Quotes.DBO.fn_FormatCurrency(Z.averagespersite,0,0) as averagespersite,
             Quotes.DBO.fn_FormatCurrency(Z.averagesperunit,1,2) as averagesperunit
      from @LT_BPQuoteSummary Z
      order by Z.seq asc,Z.recordidentificationtype asc
      FOR XML raw ,ROOT('bpquotesummary'),TYPE  
    end
    else
    begin
      select Z.recordidentificationtype,Z.companyid,z.quotestatus,Z.quoteid,Z.fees,
             Quotes.DBO.fn_FormatCurrency(Z.listprice,0,0)       as listprice,
             Quotes.DBO.fn_FormatCurrency(Z.discountpercent,1,1) as discountpercent,
             Quotes.DBO.fn_FormatCurrency(Z.discountamount,0,0)  as discountamount,          
             Quotes.DBO.fn_FormatCurrency(Z.netprice,0,0)        as netprice,
             Quotes.DBO.fn_FormatCurrency(Z.sites,0,0)           as sites,
             Quotes.DBO.fn_FormatCurrency(Z.units,0,0)           as units,
             Quotes.DBO.fn_FormatCurrency(Z.averagespersite,0,0) as averagespersite,
             Quotes.DBO.fn_FormatCurrency(Z.averagesperunit,1,2) as averagesperunit
      from @LT_BPQuoteSummary Z
      order by Z.seq asc,Z.recordidentificationtype asc
    end
    return  
  end ---> End of bpquotesummary
  -----------------------------------------------------------------------------------
  ---BundleSummary
  else if (@IPVC_recordidentificationtype = 'bpbundlesummary')
  begin ---> Begining of BundleSummary   
    ---------------------------------------------
    --Declare Local Table @LT_BPQuoteSummary
    declare @LT_BPBundleSummary TABLE(SEQ             bigint not null default 1,
                                      recordidentificationtype varchar(50) not null default 'bpbundlesummary',
                                      quoteid         varchar(50) not null default '0',
                                      groupid         bigint not null default 0,
                                      groupname       varchar(60)   not null default '',
                                      fees            varchar(100)  not null default '',      
                                      sites           int    not null default 1,
                                      units           int    not null default 1,
                                      listprice       money  not null default 0,  
                                      discountpercent as ((listprice-netprice)* (100)/
                                                          (case when listprice=0 then 1 
                                                                else listprice 
                                                           end
                                                          )                                                        
                                                         ),
                                     discountamount  as (listprice-netprice),
                                     netprice        money  not null default 0
                                    )
    ---------------------------------------------------- 
    if @IPVC_Fees = 'Initial License Fees'
    begin
      insert into @LT_BPBundleSummary(seq,quoteid,groupid,groupname,fees,sites,units,
                                      listprice,netprice)
      select 1 as seq,G.quoteidseq                 as quoteid,
             G.idseq                               as groupid,
             G.[Name]                              as groupname,
             'Initial License Fees'                as fees,
             G.Sites                               as sites,
             G.units                               as units,
             G.ILFExtYearChargeAmount              as listprice,         
             G.ILFNetExtYearChargeAmount           as netprice     
      from   Quotes.dbo.[Group] (nolock) G 
      where  G.QuoteIDSeq = @IPVC_QuoteID      
    end
    else if (@IPVC_Fees = 'Access Fees - First Year' or
             @IPVC_Fees = 'Access Fees - Year I'     or
             @IPVC_Fees = 'Access Fees - Year 1')
    begin
      insert into @LT_BPBundleSummary(seq,quoteid,groupid,groupname,fees,sites,units,
                                      listprice,netprice)
      select 2 as seq,G.quoteidseq                 as quoteid,
             G.idseq                               as groupid,
             G.[Name]                              as groupname,
             'Access Fees - Year I'                as fees,
             G.Sites                               as sites,
             G.units                               as units,
             G.AccessExtYear1ChargeAmount          as listprice,         
             G.AccessNetExtYear1ChargeAmount       as netprice     
      from   Quotes.dbo.[Group] (nolock) G 
      where  G.QuoteIDSeq = @IPVC_QuoteID  
    end
    else if (@IPVC_Fees = 'Access Fees - Second Year' or
             @IPVC_Fees = 'Access Fees - Year II'     or
             @IPVC_Fees = 'Access Fees - Year 2' )
    begin
      insert into @LT_BPBundleSummary(seq,quoteid,groupid,groupname,fees,sites,units,
                                      listprice,netprice)
      select 3 as seq,G.quoteidseq                 as quoteid,
             G.idseq                               as groupid,
             G.[Name]                              as groupname,
             'Access Fees - Year II'               as fees,
             G.Sites                               as sites,
             G.units                               as units,
             G.AccessExtYear2ChargeAmount          as listprice,         
             G.AccessNetExtYear2ChargeAmount       as netprice     
      from   Quotes.dbo.[Group] (nolock) G 
      where  G.QuoteIDSeq = @IPVC_QuoteID  
    end
    else if (@IPVC_Fees = 'Access Fees - Third Year'  or
             @IPVC_Fees = 'Access Fees - Year III'    or
             @IPVC_Fees = 'Access Fees - Year 3' ) 
    begin
      insert into @LT_BPBundleSummary(seq,quoteid,groupid,groupname,fees,sites,units,
                                      listprice,netprice)
      select 4 as seq,G.quoteidseq                 as quoteid,
             G.idseq                               as groupid,
             G.[Name]                              as groupname,
             'Access Fees - Year III'              as fees,
             G.Sites                               as sites,
             G.units                               as units,
             G.AccessExtYear3ChargeAmount          as listprice,         
             G.AccessNetExtYear3ChargeAmount       as netprice     
      from   Quotes.dbo.[Group] (nolock) G 
      where  G.QuoteIDSeq = @IPVC_QuoteID  
    end
    ----------------------------------------------
    if (select count(*) from @LT_BPBundleSummary) = 0
    begin 
      if @IPVC_Fees = 'Initial License Fees'
      begin
        insert into @LT_BPBundleSummary(seq,quoteid,groupid,groupname,fees,sites,units,listprice,netprice)
        select 1 as Seq,@IPVC_QuoteID as quoteid,@IPI_GroupID as groupid,'' as groupname,
               'Initial License Fees' as fees,0 as sites,0 as units,0 as listprice,0 as netprice
      end
      else if (@IPVC_Fees = 'Access Fees - First Year' or
               @IPVC_Fees = 'Access Fees - Year I'     or
               @IPVC_Fees = 'Access Fees - Year 1' )
      begin
        insert into @LT_BPBundleSummary(seq,quoteid,groupid,groupname,fees,sites,units,listprice,netprice)
        select 2 as Seq,@IPVC_QuoteID as quoteid,@IPI_GroupID as groupid,'' as groupname,
               'Access Fees - Year I' as fees,0 as sites,0 as units,0 as listprice,0 as netprice
      end
      else if (@IPVC_Fees = 'Access Fees - Second Year' or
               @IPVC_Fees = 'Access Fees - Year II'     or
               @IPVC_Fees = 'Access Fees - Year 2' )
      begin
        insert into @LT_BPBundleSummary(seq,quoteid,groupid,groupname,fees,sites,units,listprice,netprice)
        select 3 as Seq,@IPVC_QuoteID as quoteid,@IPI_GroupID as groupid,'' as groupname,
               'Access Fees - Year II' as fees,0 as sites,0 as units,0 as listprice,0 as netprice
      end 
      else if (@IPVC_Fees = 'Access Fees - Third Year'  or
               @IPVC_Fees = 'Access Fees - Year III'    or
               @IPVC_Fees = 'Access Fees - Year 3' ) 
      begin
        insert into @LT_BPBundleSummary(seq,quoteid,groupid,groupname,fees,sites,units,listprice,netprice)
        select 4 as Seq,@IPVC_QuoteID as quoteid,@IPI_GroupID as groupid,'' as groupname,
               'Access Fees - Year III' as fees,0 as sites,0 as units,0 as listprice,0 as netprice
      end
    end
    ----------------------------------------------
    --add Total for BundleSummary
    insert into @LT_BPBundleSummary(seq,recordidentificationtype,quoteid,groupid,groupname,
                                    fees,sites,units,listprice,netprice)
    select   9999999999 as seq,'total' as recordidentificationtype,B.quoteid as quoteid,99999999999999999 as groupid,
             '' as groupname,
             B.fees,coalesce(sum(B.sites),0) as sites,coalesce(sum(B.units),0) as units,
             coalesce(sum(B.listprice),0) as listprice,coalesce(sum(B.netprice),0) as netprice
    from     @LT_BPBundleSummary B 
    where    B.quoteid = @IPVC_QuoteID
    group by B.quoteid,B.fees     
    ----------------------------------------------------------------------------------- 
    --Final Select for bpquotesummary
    ----------------------------------------------------------------------------------- 
    if @IPVC_RETURNTYPE = 'XML'
    begin
      select   Z.recordidentificationtype                          as recordidentificationtype,
               Z.quoteid                                           as quoteid,
               (case when Z.recordidentificationtype = 'total' then 0
                     else Z.groupid 
                end)                                               as groupid,
               Z.groupname,
               Z.fees,
               Quotes.DBO.fn_FormatCurrency(Z.sites,0,0)           as sites,
               Quotes.DBO.fn_FormatCurrency(Z.units,0,0)           as units,
               Quotes.DBO.fn_FormatCurrency(Z.discountpercent,1,1) as discountpercent,
               Quotes.DBO.fn_FormatCurrency(Z.discountamount,0,0)  as discountamount, 
               Quotes.DBO.fn_FormatCurrency(Z.listprice,0,0)       as listprice,
               Quotes.DBO.fn_FormatCurrency(Z.netprice,0,0)        as netprice
      from     @LT_BPBundleSummary Z
      order by Z.groupid asc,Z.seq asc,Z.recordidentificationtype asc
      FOR XML raw ,ROOT('bpbundlesummary'),TYPE
    end
    else
    begin
      select   Z.recordidentificationtype                          as recordidentificationtype,
               Z.quoteid                                           as quoteid,
               (case when Z.recordidentificationtype = 'total' then 0
                     else Z.groupid 
                end)                                               as groupid,
               Z.groupname,
               Z.fees,
               Quotes.DBO.fn_FormatCurrency(Z.sites,0,0)           as sites,
               Quotes.DBO.fn_FormatCurrency(Z.units,0,0)           as units,
               Quotes.DBO.fn_FormatCurrency(Z.discountpercent,1,1) as discountpercent,
               Quotes.DBO.fn_FormatCurrency(Z.discountamount,0,0)  as discountamount, 
               Quotes.DBO.fn_FormatCurrency(Z.listprice,0,0)       as listprice,
               Quotes.DBO.fn_FormatCurrency(Z.netprice,0,0)        as netprice
      from     @LT_BPBundleSummary Z
      order by Z.groupid asc,Z.seq asc,Z.recordidentificationtype asc
    end
    return
  end ---> End of BundleSummary   
  -----------------------------------------------------------------------------------
  ---bpbundledetail
  else if (@IPVC_recordidentificationtype = 'bpbundledetail')
  begin ---> Begining of bpbundledetail 
    --------------------------------------------------------
    --Declaring Local Variable Table @LT_BPBundleDetail 
    declare @LT_BPBundleDetail  TABLE (SEQ                      int not null identity(1,1),
                                       recordidentificationtype varchar(50) not null default 'bpbundledetail',
                                       quoteid                  varchar(50),
                                       quotestatus              varchar(5)    not null default 'NSU',  
                                       groupid                  bigint,
                                       productcode              varchar(100)  not null default '',
                                       productname              varchar(200)  not null default '',
                                       productdisplayname       varchar(200)  not null default '', 
                                       sortseq                  int           not null default 0,
                                       optionflag               int           not null default 0,
                                       productcategorycode      varchar(50)   not null default '', 
                                       familycode               varchar(20)   not null default '',
                                       familyname               varchar(100)  not null default '', 
                                       chargetypecode           varchar(50)   not null default '',
                                       measurecode              varchar(20)   not null default '',
                                       measurename              varchar(100)  not null default '', 
                                       frequencycode            varchar(20)   not null default '',
                                       frequencyname            varchar(100)  not null default '', 
                                       chargeamount             money         not null default 0,                                       
                                       extchargeamount          money         not null default 0,
                                       quantity                 numeric(30,3) not null default 0.00,
                                       multiplier               numeric(30,5) not null default 0.00,
                                       extyear1chargeamount     money         not null default 0,
                                       extyear2chargeamount     money         not null default 0,
                                       extyear3chargeamount     money         not null default 0,
                                       netchargeamount          money         not null default 0,
                                       netextchargeamount       money         not null default 0,
                                       netextyear1chargeamount  money         not null default 0,
                                       netextyear2chargeamount  money         not null default 0,
                                       netextyear3chargeamount  money         not null default 0,                                       
                                       year1discountpercent     as ((extyear1chargeamount-netextyear1chargeamount)* (100)/
                                                                    (case when extyear1chargeamount=0 then 1 
                                                                          else extyear1chargeamount 
                                                                     end
                                                                     )                                                        
                                                                    ),
                                       year1discountamount      as (extyear1chargeamount-netextyear1chargeamount),
                                       year2discountpercent     as ((extyear2chargeamount-netextyear2chargeamount)* (100)/
                                                                    (case when extyear2chargeamount=0 then 1 
                                                                          else extyear2chargeamount 
                                                                     end
                                                                     )                                                        
                                                                    ),
                                       year2discountamount      as (extyear2chargeamount-netextyear2chargeamount),
                                       year3discountpercent     as ((extyear3chargeamount-netextyear3chargeamount)* (100)/
                                                                    (case when extyear3chargeamount=0 then 1 
                                                                          else extyear3chargeamount 
                                                                     end
                                                                     )                                                        
                                                                    ),
                                       year3discountamount      as (extyear3chargeamount-netextyear3chargeamount)
                                      )
    -----------------------------------------
    /* insert into @LT_BPBundleDetail(quoteid,groupid,productcode,productname,productdisplayname,
                                   sortseq,optionflag,productcategorycode,
                                   familycode,familyname,chargetypecode,
                                   measurecode,measurename,frequencycode,frequencyname,
                                   chargeamount,
                                   discountpercent,discountamount,
                                   extchargeamount,multiplier,extyear1chargeamount,
                                   extyear2chargeamount,extyear3chargeamount,
                                   netchargeamount,netextchargeamount,netextyear1chargeamount,
                                   netextyear2chargeamount,netextyear3chargeamount)
      exec QUOTES.dbo.uspQUOTES_PriceEngine @IPVC_QuoteID=@IPVC_QuoteID,
                                            @IPI_GroupID =@IPI_GroupID,
                                            @IPVC_PropertyAmountAnnualized='NO'    
    */
    insert into @LT_BPBundleDetail(quoteid,groupid,quotestatus,
                                   productcode,productname,productdisplayname,sortseq,optionflag,
                                   productcategorycode,familycode,familyname,
                                   chargetypecode,
                                   measurecode,measurename,frequencycode,frequencyname,
                                   chargeamount,quantity,multiplier,extchargeamount,
                                   extyear1chargeamount,extyear2chargeamount,extyear3chargeamount,
                                   netchargeamount,netextchargeamount,
                                   netextyear1chargeamount,netextyear2chargeamount,netextyear3chargeamount)
    select distinct Q.QuoteIDSeq                                 as quoteid,
                    QI.groupidseq                                as groupid,
                    Q.QuoteStatusCode                            as quotestatus,       
                    ltrim(rtrim(QI.productcode))                 as productcode,
                    P.name                                       as productname,
                    P.displayname                                as productdisplayname,
                    P.sortseq                                    as sortseq,
                    P.optionflag                                 as optionflag,
                    P.categorycode                               as productcategorycode,       
                    QI.familycode                                as familycode,
                    (select Top 1 X.Name 
                     from Products.dbo.Family X with (nolock)
                     where X.Code = QI.familycode)               as familyName,
                    QI.chargetypecode                            as chargetypecode,                    
                    QI.measurecode                               as measurecode,
                    (select Top 1 Z.Name 
                     from Products.dbo.Measure Z with (nolock)
                     where Z.Code = QI.measurecode)              as measurename,
                    QI.frequencycode                             as frequencycode,
                    (select Top 1 A.Name 
                     from Products.dbo.Frequency A with (nolock)
                     where A.Code = QI.frequencycode)            as frequencyname,
                    sum(QI.chargeamount)                         as chargeamount,
                    sum(distinct QI.quantity)                    as quantity,
                    sum(distinct QI.multiplier)                  as multiplier,                                   
                    sum(QI.extchargeamount)                      as extchargeamount,
                    sum(QI.extyear1chargeamount)                 as extyear1chargeamount,
                    sum(QI.extyear2chargeamount)                 as extyear2chargeamount,
                    sum(QI.extyear3chargeamount)                 as extyear3chargeamount,
                    sum(QI.netchargeamount)                      as netchargeamount,
                    sum(QI.netextchargeamount)                   as netextchargeamount,
                    sum(QI.netextyear1chargeamount)              as netextyear1chargeamount,
                    sum(QI.netextyear2chargeamount)              as netextyear2chargeamount,
                    sum(QI.netextyear3chargeamount)              as netextyear3chargeamount
    from Quotes.dbo.Quote Q (nolock) 
    inner join Quotes.dbo.QuoteItem QI (nolock)
    on  Q.QuoteIDSeq      = QI.QuoteIDSeq
    and Q.QuoteIDSeq      = @IPVC_QuoteID
    and QI.QuoteIDSeq     = @IPVC_QuoteID
    and QI.GroupIDSeq     = @IPI_GroupID
    and Q.CustomerIDSeq   = @IPC_CompanyID
    inner join Products.dbo.Product P (nolock) 
    on    QI.productcode  = P.code
    and   QI.PriceVersion = P.PriceVersion
    and   QI.familycode   = P.familycode
    and   QI.QuoteIDSeq   = @IPVC_QuoteID
    and   QI.GroupIDSeq   = @IPI_GroupID
    GROUP BY Q.QuoteIDSeq,QI.groupidseq,Q.QuoteStatusCode,ltrim(rtrim(QI.productcode)),
             P.name,P.displayname,P.sortseq,P.optionflag,P.categorycode,
             QI.familycode,QI.chargetypecode,QI.measurecode,QI.frequencycode
    order by P.sortseq asc,measurename asc,frequencyname asc
    -------------------------------------------------------------------------------------
    if (select count(*) from @LT_BPBundleDetail) = 0
    begin 
      insert into @LT_BPBundleDetail(quoteid,groupid,chargetypecode)
      select @IPVC_QuoteID as quoteid,@IPI_GroupID as groupid,'ILF' as chargetypecode
      union
      select @IPVC_QuoteID as quoteid,@IPI_GroupID as groupid,'ACS' as chargetypecode
    end
    ----------------------------------------------------------------------------------- 
    --Final Select for bpbundledetail
    ----------------------------------------------------------------------------------- 
    if @IPVC_RETURNTYPE = 'XML'
    begin 
      select   Z.recordidentificationtype                                    as recordidentificationtype,
               Z.quoteid                                                     as quoteid,
               z.quotestatus                                                 as quotestatus, 
               Z.groupid                                                     as groupid,
               Z.measurecode                                                 as measurecode,
               Z.measurename                                                 as measurename,
               Z.frequencycode                                               as frequencycode,
               Z.frequencyname                                               as frequencyname,
               Z.familycode                                                  as familycode,
               Z.familyname                                                  as familyname,
               Z.productcode                                                 as productcode,
               Z.productdisplayname                                          as productname,
               Z.productdisplayname                                          as productdisplayname,
               (case when (@IPVC_Fees = 'Initial License Fees')     
                          then Quotes.DBO.fn_FormatCurrency(Z.extyear1chargeamount,1,2)
                     when (@IPVC_Fees = 'Access Fees - First Year' or
                           @IPVC_Fees = 'Access Fees - Year I'     or
                           @IPVC_Fees = 'Access Fees - Year 1' )
                          then Quotes.DBO.fn_FormatCurrency(Z.extyear1chargeamount,1,2)
                     when (@IPVC_Fees = 'Access Fees - Second Year' or
                           @IPVC_Fees = 'Access Fees - Year II'     or
                           @IPVC_Fees = 'Access Fees - Year 2' )
                          then Quotes.DBO.fn_FormatCurrency(Z.extyear2chargeamount,1,2)
                     when (@IPVC_Fees = 'Access Fees - Third Year'  or
                           @IPVC_Fees = 'Access Fees - Year III'    or
                           @IPVC_Fees = 'Access Fees - Year 3' ) 
                          then Quotes.DBO.fn_FormatCurrency(Z.extyear3chargeamount,1,2)
                end
               )                                                             as listprice,
               (case when (@IPVC_Fees = 'Initial License Fees')     
                          then Quotes.DBO.fn_FormatCurrency(Z.year1discountpercent,1,2)
                     when (@IPVC_Fees = 'Access Fees - First Year' or
                           @IPVC_Fees = 'Access Fees - Year I'     or
                           @IPVC_Fees = 'Access Fees - Year 1' )
                          then Quotes.DBO.fn_FormatCurrency(Z.year1discountpercent,1,2)
                     when (@IPVC_Fees = 'Access Fees - Second Year' or
                           @IPVC_Fees = 'Access Fees - Year II'     or
                           @IPVC_Fees = 'Access Fees - Year 2' )
                          then Quotes.DBO.fn_FormatCurrency(Z.year2discountpercent,1,2)
                     when (@IPVC_Fees = 'Access Fees - Third Year'  or
                           @IPVC_Fees = 'Access Fees - Year III'    or
                           @IPVC_Fees = 'Access Fees - Year 3' )  
                          then Quotes.DBO.fn_FormatCurrency(Z.year3discountpercent,1,2)
                end
               )                                                             as discountpercent,   
               (case when (@IPVC_Fees = 'Initial License Fees')     
                          then Quotes.DBO.fn_FormatCurrency(Z.year1discountamount,1,2)
                     when (@IPVC_Fees = 'Access Fees - First Year' or
                           @IPVC_Fees = 'Access Fees - Year I'     or
                           @IPVC_Fees = 'Access Fees - Year 1' )
                          then Quotes.DBO.fn_FormatCurrency(Z.year1discountamount,1,2)
                     when (@IPVC_Fees = 'Access Fees - Second Year' or
                           @IPVC_Fees = 'Access Fees - Year II'     or
                           @IPVC_Fees = 'Access Fees - Year 2' )
                          then Quotes.DBO.fn_FormatCurrency(Z.year2discountamount,1,2)
                     when (@IPVC_Fees = 'Access Fees - Third Year'  or
                           @IPVC_Fees = 'Access Fees - Year III'    or
                           @IPVC_Fees = 'Access Fees - Year 3' ) 
                          then Quotes.DBO.fn_FormatCurrency(Z.year3discountamount,1,2)
                end
               )                                                             as discountamount, 
               (case when (@IPVC_Fees = 'Initial License Fees')     
                          then Quotes.DBO.fn_FormatCurrency(Z.netextyear1chargeamount,1,2)
                     when (@IPVC_Fees = 'Access Fees - First Year' or
                           @IPVC_Fees = 'Access Fees - Year I'     or
                           @IPVC_Fees = 'Access Fees - Year 1' )
                          then Quotes.DBO.fn_FormatCurrency(Z.netextyear1chargeamount,1,2)
                     when (@IPVC_Fees = 'Access Fees - Second Year' or
                           @IPVC_Fees = 'Access Fees - Year II'     or
                           @IPVC_Fees = 'Access Fees - Year 2' )
                          then Quotes.DBO.fn_FormatCurrency(Z.netextyear2chargeamount,1,2)
                     when (@IPVC_Fees = 'Access Fees - Third Year'  or
                           @IPVC_Fees = 'Access Fees - Year III'    or
                           @IPVC_Fees = 'Access Fees - Year 3' ) 
                          then Quotes.DBO.fn_FormatCurrency(Z.netextyear3chargeamount,1,2)
                end
               )                                                             as netprice,                  
               Z.optionflag                                                  as optionflag,
               Z.sortseq                                                     as sortseq
      from     @LT_BPBundleDetail Z
      where    Z.quoteid = @IPVC_QuoteID and Z.groupid = @IPI_GroupID
      and      Z.chargetypecode = (case when (@IPVC_Fees = 'Initial License Fees') then 'ILF'
                                        else 'ACS' 
                                   end
                                  )        
      order by Z.sortseq asc,Z.measurename asc,Z.frequencyname asc
      FOR XML raw ,ROOT('bpbundledetail'), TYPE
    end 
    else
    begin 
      select   Z.recordidentificationtype                                    as recordidentificationtype,
               Z.quoteid                                                     as quoteid,
               z.quotestatus                                                 as quotestatus, 
               Z.groupid                                                     as groupid,
               Z.measurecode                                                 as measurecode,
               Z.measurename                                                 as measurename,
               Z.frequencycode                                               as frequencycode,
               Z.frequencyname                                               as frequencyname,
               Z.familycode                                                  as familycode,
               Z.familyname                                                  as familyname,
               Z.productcode                                                 as productcode,
               Z.productdisplayname                                          as productname,
               Z.productdisplayname                                          as productdisplayname,
               (case when (@IPVC_Fees = 'Initial License Fees')     
                          then Quotes.DBO.fn_FormatCurrency(Z.extyear1chargeamount,1,2)
                     when (@IPVC_Fees = 'Access Fees - First Year' or
                           @IPVC_Fees = 'Access Fees - Year I'     or
                           @IPVC_Fees = 'Access Fees - Year 1' )
                          then Quotes.DBO.fn_FormatCurrency(Z.extyear1chargeamount,1,2)
                     when (@IPVC_Fees = 'Access Fees - Second Year' or
                           @IPVC_Fees = 'Access Fees - Year II'     or
                           @IPVC_Fees = 'Access Fees - Year 2' )
                          then Quotes.DBO.fn_FormatCurrency(Z.extyear2chargeamount,1,2)
                     when (@IPVC_Fees = 'Access Fees - Third Year'  or
                           @IPVC_Fees = 'Access Fees - Year III'    or
                           @IPVC_Fees = 'Access Fees - Year 3' ) 
                          then Quotes.DBO.fn_FormatCurrency(Z.extyear3chargeamount,1,2)
                end
               )                                                             as listprice,
               (case when (@IPVC_Fees = 'Initial License Fees')     
                          then Quotes.DBO.fn_FormatCurrency(Z.year1discountpercent,1,2)
                     when (@IPVC_Fees = 'Access Fees - First Year' or
                           @IPVC_Fees = 'Access Fees - Year I'     or
                           @IPVC_Fees = 'Access Fees - Year 1' )
                          then Quotes.DBO.fn_FormatCurrency(Z.year1discountpercent,1,2)
                     when (@IPVC_Fees = 'Access Fees - Second Year' or
                           @IPVC_Fees = 'Access Fees - Year II'     or
                           @IPVC_Fees = 'Access Fees - Year 2' )
                          then Quotes.DBO.fn_FormatCurrency(Z.year2discountpercent,1,2)
                     when (@IPVC_Fees = 'Access Fees - Third Year'  or
                           @IPVC_Fees = 'Access Fees - Year III'    or
                           @IPVC_Fees = 'Access Fees - Year 3' )  
                          then Quotes.DBO.fn_FormatCurrency(Z.year3discountpercent,1,2)
                end
               )                                                             as discountpercent,   
               (case when (@IPVC_Fees = 'Initial License Fees')     
                          then Quotes.DBO.fn_FormatCurrency(Z.year1discountamount,1,2)
                     when (@IPVC_Fees = 'Access Fees - First Year' or
                           @IPVC_Fees = 'Access Fees - Year I'     or
                           @IPVC_Fees = 'Access Fees - Year 1' )
                          then Quotes.DBO.fn_FormatCurrency(Z.year1discountamount,1,2)
                     when (@IPVC_Fees = 'Access Fees - Second Year' or
                           @IPVC_Fees = 'Access Fees - Year II'     or
                           @IPVC_Fees = 'Access Fees - Year 2' )
                          then Quotes.DBO.fn_FormatCurrency(Z.year2discountamount,1,2)
                     when (@IPVC_Fees = 'Access Fees - Third Year'  or
                           @IPVC_Fees = 'Access Fees - Year III'    or
                           @IPVC_Fees = 'Access Fees - Year 3' ) 
                          then Quotes.DBO.fn_FormatCurrency(Z.year3discountamount,1,2)
                end
               )                                                             as discountamount, 
               (case when (@IPVC_Fees = 'Initial License Fees')     
                          then Quotes.DBO.fn_FormatCurrency(Z.netextyear1chargeamount,1,2)
                     when (@IPVC_Fees = 'Access Fees - First Year' or
                           @IPVC_Fees = 'Access Fees - Year I'     or
                           @IPVC_Fees = 'Access Fees - Year 1' )
                          then Quotes.DBO.fn_FormatCurrency(Z.netextyear1chargeamount,1,2)
                     when (@IPVC_Fees = 'Access Fees - Second Year' or
                           @IPVC_Fees = 'Access Fees - Year II'     or
                           @IPVC_Fees = 'Access Fees - Year 2' )
                          then Quotes.DBO.fn_FormatCurrency(Z.netextyear2chargeamount,1,2)
                     when (@IPVC_Fees = 'Access Fees - Third Year'  or
                           @IPVC_Fees = 'Access Fees - Year III'    or
                           @IPVC_Fees = 'Access Fees - Year 3' ) 
                          then Quotes.DBO.fn_FormatCurrency(Z.netextyear3chargeamount,1,2)
                end
               )                                                             as netprice,                  
               Z.optionflag                                                  as optionflag,
               Z.sortseq                                                     as sortseq
      from     @LT_BPBundleDetail Z
      where    Z.quoteid = @IPVC_QuoteID and Z.groupid = @IPI_GroupID
      and      Z.chargetypecode = (case when (@IPVC_Fees = 'Initial License Fees') then 'ILF'
                                        else 'ACS' 
                                   end
                                  )        
      order by Z.sortseq asc,Z.measurename asc,Z.frequencyname asc
    end     
    return
  end ---> End of bpbundledetail     
  ---------------------------------------------------------------------------------------------------
END

-- exec Quotes.dbo.uspQUOTES_GetBillingProjections @IPVC_recordidentificationtype = 'bpquotesummary', @IPC_CompanyID = 'C0000023596', @IPVC_QuoteID = 'Q0000000054', @IPVC_RETURNTYPE = 'RECORDSET'
GO
