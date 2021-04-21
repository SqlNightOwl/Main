SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
--bpquotesummary
exec Quotes.dbo.uspQUOTES_RepDealSheet_GetBPQuoteSummary 
@IPC_CompanyID='C0000002003',@IPVC_QuoteID='Q0000000880'
----------------------------------------------------------------------
*/
CREATE PROCEDURE [quotes].[uspQUOTES_RepDealSheet_GetBPQuoteSummary]
                                                         (@IPC_CompanyID     varchar(50),
                                                          @IPVC_QuoteID      varchar(8000),
                                                          @IPVC_String       varchar(1), 
                                                          @IPVC_Delimiter    varchar(1)= '|'                                                                                                                                                                                                                                                                                                           
                                                          )
AS
BEGIN   
  set nocount on 
  -----------------------------------------------------------------------------------
  declare @LT_Quotes  TABLE (QuoteID varchar(50)) 
  -----------------------------------------------------------------------------------
  --Declaring Local Variables 
  declare @LI_QuoteSites  int
  declare @LI_QuoteUnits  int
  
  select @LI_QuoteSites=0,@LI_QuoteUnits=0

  select @IPC_CompanyID = ltrim(rtrim(@IPC_CompanyID))
  -----------------------------------------------------------------------------------
  --Parse the string to get all the Quotes.
  insert into @LT_Quotes(QuoteID)
  select Items as QuoteID from QUOTES.dbo.fnSplitDelimitedString(@IPVC_QuoteID,@IPVC_Delimiter)
  -----------------------------------------------------------------------------------
  --QuoteSummary
  --Declare Local Table @LT_BPQuoteSummary
  declare @LT_BPQuoteSummary TABLE(seq                      bigint        not null default 1,                                   
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
  select @LI_QuoteSites = sum(Sites),@LI_QuoteUnits = sum(Units)
  from   QUOTES.dbo.Quote Q (nolock) 
  inner join
         @LT_Quotes  S 
  on     Q.QuoteIDSeq    = S.QuoteID
  and    Q.CustomerIDSeq = @IPC_CompanyID
  ---------------------------------------------------------------
  insert into @LT_BPQuoteSummary(seq,fees,sites,units,listprice,netprice)
  select 1 as seq,           
           'Initial License Fees'                     as fees,
           sum(Q.Sites)                               as sites,
           sum(Q.units)                               as units,
           sum(Q.ILFExtYearChargeAmount)              as listprice,         
           sum(Q.ILFNetExtYearChargeAmount)           as netprice     
  from   Quotes.dbo.[Quote] Q (nolock) 
  inner join
         @LT_Quotes  S 
  on     Q.QuoteIDSeq    = S.QuoteID
  and    Q.CustomerIDSeq = @IPC_CompanyID
   
  insert into @LT_BPQuoteSummary(seq,fees,sites,units,listprice,netprice)
  select 2 as seq,           
           'Access Fees - Year I'                     as fees,
           sum(Q.Sites)                               as sites,
           sum(Q.units)                               as units,
           sum(Q.AccessExtYear1ChargeAmount)          as listprice,         
           sum(Q.AccessNetExtYear1ChargeAmount)       as netprice  
  from   Quotes.dbo.[Quote] Q (nolock) 
  inner join
         @LT_Quotes  S 
  on     Q.QuoteIDSeq    = S.QuoteID
  and    Q.CustomerIDSeq = @IPC_CompanyID
    
  insert into @LT_BPQuoteSummary(seq,fees,sites,units,listprice,netprice)
  select 4 as seq,           
           'Access Fees - Year II'                    as fees,
           sum(Q.Sites)                               as sites,
           sum(Q.units)                               as units,
           sum(Q.AccessExtYear2ChargeAmount)          as listprice,       
           sum(Q.AccessNetExtYear2ChargeAmount)       as netprice   
  from   Quotes.dbo.[Quote] Q (nolock) 
  inner join
         @LT_Quotes  S 
  on     Q.QuoteIDSeq    = S.QuoteID
  and    Q.CustomerIDSeq = @IPC_CompanyID
 
  insert into @LT_BPQuoteSummary(seq,fees,sites,units,listprice,netprice)
  select 5 as seq,           
           'Access Fees - Year III'                   as fees,
           sum(Q.Sites)                               as sites,
           sum(Q.units)                               as units,
           sum(Q.AccessExtYear3ChargeAmount)          as listprice, 
           sum(Q.AccessNetExtYear3ChargeAmount)       as netprice   
  from   Quotes.dbo.[Quote] Q (nolock) 
  inner join
         @LT_Quotes  S 
  on     Q.QuoteIDSeq    = S.QuoteID
  and    Q.CustomerIDSeq = @IPC_CompanyID

  ----------------------------------------------
  if (select count(*) from @LT_BPQuoteSummary) = 0
  begin 
      insert into @LT_BPQuoteSummary(seq,fees,sites,units,listprice,netprice)
      select 1 as Seq,
             'Initial License Fees' as fees,0 as sites,0 as units,0 as listprice,0 as netprice
      union
      select 2 as Seq,
             'Access Fees - Year I' as fees,0 as sites,0 as units,0 as listprice,0 as netprice
      union
      select 4 as Seq,
             'Access Fees - Year II' as fees,0 as sites,0 as units,0 as listprice,0 as netprice
      union
      select 5 as Seq,
             'Access Fees - Year III' as fees,0 as sites,0 as units,0 as listprice,0 as netprice
  end
  ----------------------------------------------
  --add Total for QuoteSummary
  insert into @LT_BPQuoteSummary(seq,fees,sites,units,listprice,netprice)
  select   3                               as seq,                    
           'Total For Year I'              as fees,
           coalesce(@LI_QuoteSites,0)      as sites,
           coalesce(@LI_QuoteUnits,0)      as units,    
           coalesce(sum(BPQS.listprice),0) as listprice,
           coalesce(sum(BPQS.netprice),0)  as netprice
  from   @LT_BPQuoteSummary  BPQS
  where  (BPQS.fees = 'Initial License Fees' or BPQS.fees ='Access Fees - Year I')  
  ----------------------------------------------------------------------------------- 
  --Final Select for bpquotesummary
  -----------------------------------------------------------------------------------                     
  IF( @IPVC_String = 'N')
  BEGIN
    SELECT TOP 3
           Z.fees                                              as fees,
           Quotes.DBO.fn_FormatCurrency(Z.listprice,0,0)       as listprice,
           Quotes.DBO.fn_FormatCurrency(Z.discountpercent,1,2) as discountpercent,
           Quotes.DBO.fn_FormatCurrency(Z.discountamount,0,0)  as discountamount,
           Quotes.DBO.fn_FormatCurrency(Z.netprice,0,0)        as netprice,
           Quotes.DBO.fn_FormatCurrency(Z.averagespersite,0,0) as averagespersite,
           Quotes.DBO.fn_FormatCurrency(Z.averagesperunit,1,2) as averagesperunit
    FROM @LT_BPQuoteSummary Z
    ORDER BY Z.seq ASC,Z.fees ASC    
  END
  ELSE IF( @IPVC_String = 'Y')
  BEGIN
    SELECT Z.fees                                              as fees1,
           Quotes.DBO.fn_FormatCurrency(Z.listprice,0,0)       as listprice1,
           Quotes.DBO.fn_FormatCurrency(Z.discountpercent,1,2) as discountpercent1,
           Quotes.DBO.fn_FormatCurrency(Z.discountamount,0,0)  as discountamount1,
           Quotes.DBO.fn_FormatCurrency(Z.netprice,0,0)        as netprice1,
           Quotes.DBO.fn_FormatCurrency(Z.averagespersite,0,0) as averagespersite1,
           Quotes.DBO.fn_FormatCurrency(Z.averagesperunit,1,2) as averagesperunit1
    FROM @LT_BPQuoteSummary Z WHERE
     Z.fees  NOT IN ( 
            SELECT TOP 3  Z.fees as fees FROM @LT_BPQuoteSummary Z
    ORDER BY Z.seq ASC,Z.fees ASC)  
    ORDER BY Z.seq ASC,Z.fees ASC
  END
  return  
 ---> End of bpquotesummary 
END
GO
