SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Exec uspORDERS_ExpireOldOrdersandFulfillRenewals
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : uspORDERS_ExpireOldOrdersandFulfillRenewals
-- Description     : Expire old Orderitems and Fulfil Pending Renewals
-- Input Parameters: 
-- Code Example    : Exec ORDERS.dbo.[uspORDERS_ExpireOldOrdersandFulfillRenewals] @IPI_FulfillDays = 45
-- Revision History:
-- Author          : SRS
-- 04/15/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_ExpireOldOrdersandFulfillRenewals](@IPI_FulfillDays     int = 45
                                                                     )
AS
BEGIN  
  set nocount on;
  declare @IPD_FullFillDate   datetime, 
          @LDT_SystemDate     datetime 
  select  @LDT_SystemDate     = getdate()
  --------------------------------------------------------------
  --Renewals are done 60 days in advance.
  --Fulfilling of OrderItems ie (status change from PENR to FULF is set 45 in advance)
  --These @IPI_FulfillDays is hardcoded 45 days,
  --  although this is parameterized to override for future changes in Business needs.    
  -----select @IPI_FulfillDays = 45
  set @IPD_FullFillDate = convert(datetime,convert(varchar(50),
                                                   dateadd(day, @IPI_FulfillDays, @LDT_SystemDate),101)
                                 ) 
  --------------------------------------------------------------
  create table #TEMP_RegAdminQueueForExpiredOrderItems(IDSeq          int not null identity(1,1),
                                                       AccountIDSeq   varchar(50),
                                                       OrderIDSeq     varchar(50),
                                                       OrderItemIDSeq bigint
                                                       );
  -------------------------------------------------------------------
  --Step 1 : Fulfill Pending Renewals entries to be invoiced 
  -------------------------------------------------------------------
  update ORDERS.dbo.OrderItem
  set    StatusCode      = 'FULF',
         SystemLogDate   = @LDT_SystemDate
  where  StatusCode      = 'PENR'
  and    Chargetypecode  = 'ACS'
  and    convert(datetime,convert(varchar(50),StartDate,101)) <= @IPD_FullFillDate
  -------------------------------------------------------------------
  UPDATE OI
  set    OI.StatusCode      ='EXPD',
         OI.RenewalTypeCode ='DRNW',
         OI.HistoryFlag     = 1, 
         OI.HistoryDate     = @LDT_SystemDate,
         OI.SystemLogDate   = @LDT_SystemDate
  OUTPUT O.AccountIDSeq,Inserted.OrderIDSeq,Inserted.IDSeq as OrderItemIDSeq
  into   #TEMP_RegAdminQueueForExpiredOrderItems
  from   Orders.dbo.[Order] O with (nolock)
  inner join
         Orders.dbo.[Orderitem]  OI  with (nolock)
  on     OI.Orderidseq = O.Orderidseq
  and    (OI.HistoryFlag     = 0 OR OI.StatusCode not in ('EXPD','CNCL'))
  and    (OI.FrequencyCode   in ('OT','SG') ---> This is for ILF and OneTimers 
            OR
          exists (select top 1 1 
                  from   Orders.dbo.[Orderitem]  XI  with (nolock)
                  where  OI.Orderidseq      = XI.Orderidseq
                  and    OI.OrderGroupIDSeq = XI.OrderGroupIDSeq
                  and    OI.ProductCode     = XI.ProductCode
                  and    OI.Chargetypecode  = XI.Chargetypecode
                  and    OI.MeasureCode     = XI.MeasureCode
                  and    OI.FrequencyCode   = XI.FrequencyCode
                  and    OI.IDSeq           = XI.RenewedFromorderItemIDSeq
                  and    OI.RenewalCount    < XI.RenewalCount
                 ) --- This is for Access Subscription that have renewed.
             OR
          (OI.RenewalTypecode = 'DRNW') ---This is for any orderitem that is marked as Do not renew.
         )
  and    isdate(OI.StartDate) = 1
  and    isdate(OI.EndDate)   = 1
  and    (
              (
               convert(datetime,convert(varchar(50),OI.EndDate,101)) <= convert(datetime,convert(varchar(50),@LDT_SystemDate,101))
                  and
               OI.Measurecode = 'TRAN'
              )
              OR
             (
              (
                (isdate(OI.POILastBillingPeriodToDate) = 1 and OI.EndDate <= OI.POILastBillingPeriodToDate)
                 OR
                (isdate(OI.LastBillingPeriodToDate) = 1    and OI.EndDate <= OI.LastBillingPeriodToDate)
              )
              AND
               (
                convert(datetime,convert(varchar(50),OI.EndDate,101)) <= convert(datetime,convert(varchar(50),@LDT_SystemDate,101))
                and
                OI.Measurecode <>  'TRAN'
               )
             )
        )
  -----------------------------------------------------------------------
  ---Step 10 : Update/Insert ORDERS.dbo.RegAdminQueue
  Update RAQ
  set    RAQ.PushedToRegAdminFlag = 0,
         RAQ.CreatedDate          = @LDT_SystemDate
  from   ORDERS.dbo.RegAdminQueue RAQ with (nolock)
  inner join
         #TEMP_RegAdminQueueForExpiredOrderItems S with (nolock)
  on     RAQ.OrderItemIDSeq = S.OrderItemIDSeq
  and    RAQ.OrderItemIDSeq is not null
  and    RAQ.AccountIDSeq  = S.AccountIDSeq
  and    RAQ.OrderIDSeq    = S.OrderIDSeq
    
  Insert Into ORDERS.dbo.RegAdminQueue(AccountIDSeq,OrderIDSeq,OrderItemIDSeq,CreatedDate,ModifiedDate,PushedToRegAdminFlag)
  select S.AccountIDSeq,S.OrderIDSeq,S.OrderItemIDSeq,@LDT_SystemDate as CreatedDate,NULL,0 as PushedToRegAdminFlag
  from   #TEMP_RegAdminQueueForExpiredOrderItems S with (nolock)
  where  S.OrderItemIDSeq not in (select RAQ.OrderItemIDSeq 
                                  from   ORDERS.dbo.RegAdminQueue RAQ with (nolock)
                                  where  RAQ.OrderItemIDSeq is not null
                                  and    RAQ.AccountIDSeq  = S.AccountIDSeq
                                  and    RAQ.OrderIDSeq    = S.OrderIDSeq
                                 )
  ------------------------------------------------------------------------------------
  --Purge OLD Invoice XML data; Retain only last 3 months worth of InvoiceXML data
  ------------------------------------------------------------------------------------
  declare @LDT_CriteriaDate datetime,
          @LI_IMin int,@LI_IMax int
  select  @LDT_CriteriaDate=dateadd(mm,-3,B.BillingCycleDate) 
  from   Invoices.dbo.InvoiceEOMServiceControl B with (nolock) 

  select @LI_IMin=1,@LI_IMax =count(1) from Invoices.dbo.InvoiceXML with (nolock)

  if isdate(@LDT_CriteriaDate) = 1
  begin
    while @LI_IMin <= @LI_IMax
    begin      
      set ROWCOUNT 2000;
  
      Delete Invoices.dbo.InvoiceXML 
      where  BillingCycleDate < @LDT_CriteriaDate
      and    OutboundProcessStatus = 1
      and    InboundProcessStatus  = 1
        
      if not exists (select top 1 1
                     from  Invoices.dbo.InvoiceXML IXML with (nolock)
                     where IXML.BillingCycleDate < @LDT_CriteriaDate
                     and   IXML.OutboundProcessStatus = 1
                     and   IXML.InboundProcessStatus  = 1
                    )
      begin        
        select @LI_IMin = @LI_IMax        
        break
      end 
      select @LI_IMin = @LI_IMin +1
    end
  end
  set ROWCOUNT 0;
  ------------------------------------------------------------------------------------
  --Delete Duplicated Orphan Properties that do not have an account
  ------------------------------------------------------------------------------------
   select  IDENTITY (int,1,1) AS rownum,X.CompanyIDSeq
   into #LT_DuplicateOrphanProp
   from 
       (select P.PMCIDSeq as CompanyIDSeq  
        from  customers.dbo.Property P with (nolock) 
        left outer join
              customers.dbo.Address  AP with (nolock)
        on    P.PMCIDSeq = AP.CompanyIDSeq
        and   P.IDSeq    = AP.PropertyIDSeq
        and   AP.Addresstypecode = 'PRO'
        and   AP.PropertyIDSeq is not null   
        where Not exists (select top 1 1
                          from   CUSTOMERS.dbo.Account A with (nolock)
                          where  A.CompanyIDSeq = P.PMCIDSeq
                          and    A.CompanyIDSeq = P.PMCIDSeq
                          and    A.PropertyIDseq= P.IDSeq
                          and    A.PropertyIDSeq is not null
                         )
        group by  P.PMCIDSeq
                  ,ltrim(rtrim(P.Name))                                        
                  ,coalesce(nullif(ltrim(rtrim(P.phase)),''),'ABCDEF')         
                  ,coalesce(nullif(ltrim(rtrim(AP.AddressLine1)),''),'ABCDEF') 
                  ,coalesce(nullif(ltrim(rtrim(AP.AddressLine2)),''),'ABCDEF') 
                  ,coalesce(nullif(ltrim(rtrim(AP.City)),''),'ABCDEF')         
                  ,coalesce(nullif(ltrim(rtrim(AP.State)),''),'ABCDEF')        
                  ,coalesce(nullif(ltrim(rtrim(left(AP.Zip,5))),''),'ABCDEF')  
                  ,coalesce(nullif(ltrim(rtrim(AP.Country)),''),'ABCDEF')      
        having count(1) > 1
       ) X
   order by X.CompanyIDSeq;

   declare @LVC_CompanyID varchar(50),
           @LI_OIMin int,@LI_OIMax int
   
   select @LI_OIMin=1,@LI_OIMax=count(1) from #LT_DuplicateOrphanProp with (nolock)
   while @LI_OIMin <= @LI_OIMax
   begin
     select @LVC_CompanyID = X.CompanyIDSeq 
     from   #LT_DuplicateOrphanProp X with (nolock)
     where  X.rownum = @LI_OIMin
     Exec CUSTOMERS.dbo.uspCUSTOMERS_DeleteOrphanDuplicateProperties @IPVC_CompanyIDSeq=@LVC_CompanyID
     select @LI_OIMin = @LI_OIMin+1
   end
  ------------------------------------------------------------------------------------
  --Final Cleanup  
  ------------------------------------------------------------------------------------
  if (object_id('tempdb.dbo.#TEMP_RegAdminQueueForExpiredOrderItems') is not null) 
  begin
    drop table #TEMP_RegAdminQueueForExpiredOrderItems;
  end;   
  if (object_id('tempdb.dbo.#LT_DuplicateOrphanProp') is not null) 
  begin
    drop table #LT_DuplicateOrphanProp;
  end;
  ----------------------------------------------------------------------------
END  
GO
