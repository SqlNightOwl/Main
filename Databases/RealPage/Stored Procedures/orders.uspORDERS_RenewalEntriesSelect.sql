SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--exec uspORDERS_RenewalEntriesSelect 90
---------------------------------------------------------------------------------------------------
-- Database  Name  : Orders
-- Procedure Name  : uspORDERS_RenewalEntriesSelect
-- Description     : This procedure gets number of entries that will be renewed during the next
--                    renewal execution.
-- Code Example    : Exec ORDERS.DBO.uspORDERS_RenewalEntriesSelect
-- 
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_RenewalEntriesSelect] (@IPI_RenewalDays       int         =60,
                                                         @IPVC_BillingCycleDate varchar(50) ='',
                                                         @IPVC_CompanyID        varchar(50) ='',
                                                         @IPVC_AccountID        varchar(50) =''
                                                        )
AS
BEGIN 
  set nocount on;
  ----------------------------------------------------------------------
  -- Declare Local Variables
  Declare @IPD_EndDate              datetime  
  ----------------------------------------------------------------------
  set @IPVC_CompanyID    =  nullif(@IPVC_CompanyID, '')
  set @IPVC_AccountID    =  nullif(@IPVC_AccountID, '');
  ----------------------------------------------------------------------
  --Renewals are usually done 60 days in advance. But user can still pass
  -- it as a parameter. The default is 60 days
  if (@IPI_RenewalDays = '' or @IPI_RenewalDays is null)
  begin
    select @IPI_RenewalDays = 60
  end
  -----------------------
  --Renewals are done 60 days in advance. If @IPVC_BillingCycleDate or @IPI_RenewalDays are not passed,
  -- RenewalOrderEngine defaults to 60 days.
  --Fulfilling of OrderItems ie (status change from PENR to FULF is set 45 in advance)
  --These 2 @IPI_RenewalDays,@IPI_FulfillDays are hardcoded to 60 and 45 respectively,
  --  although these are parameterized to override for future changes in Business needs.
  if (isdate(@IPVC_BillingCycleDate)=0)--> if @IPVC_BillingCycleDate is not passed,then go with current OPEN BillingCycleDate from INVOICES.DBO.InvoiceEOMServiceControl 
  begin
    select  Top 1 @IPVC_BillingCycleDate = B.BillingCycleDate,
                  @IPD_EndDate           =(case when ((day(B.BillingCycleDate)= 15))
                                                  then convert(datetime,
                                                               convert(varchar(50),Month(DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate)+3,0))))+
                                                               '/15/'+
                                                               convert(varchar(50),Year(DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate)+3,0))))
                                                               )                                                                                  --> Middle Day of forward 2 Month from BillingCycleDate 
                                                 when ((day(B.BillingCycleDate)<> 15))
                                                        then convert(datetime,DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate)+3,0)))    --> Last Day of forward 2 Month from BillingCycleDate
                                           end)
    from    INVOICES.DBO.InvoiceEOMServiceControl B with (nolock)
    where   B.BillingCycleClosedFlag = 0 
  end
  else if (isdate(@IPVC_BillingCycleDate)=1) 
  begin    
    select @IPVC_BillingCycleDate = convert(varchar(50),convert(datetime,@IPVC_BillingCycleDate),101)
    select @IPD_EndDate   = (case when ((day(convert(datetime,@IPVC_BillingCycleDate))= 15))
                                    then convert(datetime,
                                                 convert(varchar(50),Month(DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,convert(datetime,@IPVC_BillingCycleDate))+3,0))))+
                                                 '/15/'+
                                                 convert(varchar(50),Year(DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,convert(datetime,@IPVC_BillingCycleDate))+3,0))))
                                                )                                                                                                    --> Middle Day of forward 2 Month from BillingCycleDate 
                                   when ((day(convert(datetime,@IPVC_BillingCycleDate))<> 15))
                                     then convert(datetime,DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,convert(datetime,@IPVC_BillingCycleDate))+3,0)))    --> Last Day of forward 2 Month from BillingCycleDate
                             end)
  end
  else
  begin    
    select @IPD_EndDate   = convert(datetime,convert(varchar(50),'01/01/1900',101)) 
  end 

  ---------------------------------------------------------------------------------------------
  ---Select Count of OrderItems that qualify for renewal
  -- Criteria is below:
  select XII.IDSeq as OrderItemIDSeq,Max(XII.OrderIDSeq) as OrderIDSeq,
         MAX(XII.OrderGroupIDSeq)                        as OrderGroupIDSeq,
         XII.ProductCode,XII.Measurecode,XII.Frequencycode,
         Coalesce(XII.MasterOrderItemIDSeq,XII.IDSeq) as MasterOrderItemIDSeq,XII.Renewalcount
  Into  #Temp_UIOrderItemsfirst
  from   ORDERS.DBO.[Order]       O  with (nolock)       
  inner join
          CUSTOMERS.DBO.Company COM with (nolock)
  on      O.CompanyIDSeq = COM.IDSeq
  and     COM.IDSeq          = coalesce(@IPVC_CompanyID,COM.IDSeq)
  and     O.AccountIDseq     = coalesce(@IPVC_AccountID,O.AccountIDseq)   
  inner join
          ORDERS.dbo.[Orderitem] XII with (nolock)
  on    XII.Orderidseq     = O.Orderidseq         
        ---------------------------------------------------------------------------------------------  
        and     XII.ChargeTypeCode  = 'ACS'
        and     XII.Measurecode    <> 'TRAN'
        and     XII.FrequencyCode  <> 'OT'
        and     XII.RenewalTypeCode = 'ARNW'        
        and     XII.ActivationEndDate   < @IPD_EndDate
        and     XII.StatusCode          = 'FULF'          
        --------------------------------------------------------------------------------------------- 
  where XII.HistoryFlag     = 0   
  group by XII.IDSeq, XII.ProductCode,XII.Measurecode,XII.Frequencycode,
           Coalesce(XII.MasterOrderItemIDSeq,XII.IDSeq),XII.Renewalcount

  select S.OrderItemIDSeq 
  into  #Temp_OrdersItemsToRenewCount
  from  #Temp_UIOrderItemsfirst S with (nolock)
  Where 
       S.Renewalcount >=
                      (select Max(XI.Renewalcount)
                       from   #Temp_UIOrderItemsfirst XI with (nolock)
                       where  XI.OrderIDSeq      = S.OrderIDSeq
                       and    XI.OrderGroupIDSeq = S.OrderGroupIDSeq
                       and    XI.ProductCode     = S.ProductCode                                             
                       and    XI.Measurecode     = S.Measurecode
                       and    XI.Frequencycode   = S.Frequencycode                      
                       and    XI.MasterOrderItemIDSeq = S.MasterOrderItemIDSeq                          
                     )         
  group by S.OrderItemIDSeq
  -----------------------------------------------
  --Final Select
  select Count(OrderItemIDSeq) as OrderItemsToRenewCount
  from #Temp_OrdersItemsToRenewCount with (nolock)
  -----------------------------------------------
  drop table #Temp_UIOrderItemsfirst
  drop table #Temp_OrdersItemsToRenewCount
  ----------------------------------------------
END
GO
