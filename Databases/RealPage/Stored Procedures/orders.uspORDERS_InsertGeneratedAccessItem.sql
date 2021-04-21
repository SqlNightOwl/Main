SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : uspORDERS_InsertGeneratedAccessItem
-- Description     : This procedure Inserts a new access row into OrderItem table.
--
-- Input Parameters:  
--
-- OUTPUT          : A data row will be inserted into OrderItem table
-- 
-- Revision History:
-- Author          :  
-- 12/20/2007      : Stored Procedure Created.
-- 
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_InsertGeneratedAccessItem](
                                                             @IPVC_OrderIDSeq      varchar(22),
                                                             @IPI_OrderGroupIDSeq  bigint,
                                                             @IPC_ProductCode      char(30),
                                                             @IPC_ChargeTypeCode   char(3),
                                                             @IPC_FrequencyCode    char(6),
                                                             @IPC_MeasureCode      char(6),
                                                             @IPC_FamilyCode       char(3),
                                                             @IPN_PriceVersion     numeric(18,0),
                                                             @IPD_Quantity         decimal(18,3),
                                                             @IPI_minunits         int,
                                                             @IPI_maxunits         int,	
                                                             @IPM_ChargeAmount     money,
                                                             @IPM_NetChargeAmount  money,
                                                             @IPVC_StatusCode      varchar(5),
                                                             @IPB_CapMaxUnitsFlag  bit,
                                                             @IPM_dollarminimum    money,
                                                             @IPM_dollarmaximum    money,
                                                             @IPVC_RenewalTypeCode varchar(6),
                                                             @IPVC_StartDate	   varchar(11),
                                                             @IPVC_EndDate	   varchar(11),
                                                             @IPVC_BillTo	   varchar(3),
                                                             @IPVC_ReportTypeCode  varchar(4),
                                                             @IPVC_Discount        money, 
                                                             @IPI_UserIDSeq        bigint = -1  ---> Mandatory: This is the userid logged on and doing the operation.
      
                                                            )	
AS
BEGIN
  set nocount on;
  ------------------------------------------------
  declare @LVC_CompanyIDSeq   varchar(50),
          @LVC_PropertyIDSeq  varchar(50)
  ------------------------------------------------
  ---NOTE : Generate Access should generate only Access Item. User cannot fulfil using this modal.
  ---       User will have to use Edit Option on Access Item to Fullfil.
  /****************************************************************************/
   IF not exists (select top 1 1 from ORDERS.DBO.OrderItem with (nolock)
                  where  OrderIDSeq      = @IPVC_OrderIDSeq
                   and   OrderGroupIDSeq = @IPI_OrderGroupIDSeq
                   and   ProductCode     = @IPC_ProductCode
                   and   ChargeTypeCode  = @IPC_ChargeTypeCode
                   and   FrequencyCode   = @IPC_FrequencyCode
                   and   MeasureCode     = @IPC_MeasureCode
                   and   PriceVersion    = @IPN_PriceVersion)
   Begin
     select Top 1
            @LVC_CompanyIDSeq   = O.CompanyIDSeq,
            @LVC_PropertyIDSeq  = O.PropertyIDSeq
     from   ORDERS.DBO.[Order] O with (nolock)
     where  O.OrderIDSeq        = @IPVC_OrderIDSeq;

     Insert into Orders.dbo.OrderItem (OrderIDSeq,OrderGroupIDSeq,ProductCode,ChargeTypeCode,FrequencyCode,MeasureCode,FamilyCode,
                                       PriceVersion,Quantity,EffectiveQuantity,minunits,maxunits,ChargeAmount,DiscountPercent,NetChargeAmount,ExtChargeAmount,
                                       ILFStartDate,ILFEndDate,ActivationStartDate,ActivationEndDate,StatusCode,
                                       StartDate,EndDate,LastBillingPeriodFromDate,LastBillingPeriodToDate,
                                       CapMaxUnitsFlag,dollarminimum,dollarmaximum,RenewalTypeCode,ReportingTypeCode,DiscountAmount
                                       ,BillToAddressTypeCode,billtodeliveryoptioncode)
     select           @IPVC_OrderIDSeq          as OrderIDSeq,
		      @IPI_OrderGroupIDSeq      as OrderGroupIDSeq,
		      @IPC_ProductCode          as ProductCode,
		      @IPC_ChargeTypeCode       as ChargeTypeCode, --ACS by default
		      @IPC_FrequencyCode        as FrequencyCode,
		      @IPC_MeasureCode          as MeasureCode,
		      @IPC_FamilyCode           as FamilyCode,
		      @IPN_PriceVersion         as PriceVersion,
		      @IPD_Quantity             as Quantity,
                      @IPD_Quantity             as EffectiveQuantity,
		      @IPI_minunits             as minunits,
		      @IPI_maxunits             as maxunits,	
		      convert(numeric(30,2),@IPM_ChargeAmount)         as ChargeAmount,
		      convert(float,(convert(float,convert(numeric(30,2),@IPM_ChargeAmount))-
                                     convert(float,convert(numeric(30,2),@IPM_NetChargeAmount)))*(100)/
                           (case when @IPM_ChargeAmount=0 then 1 else convert(float,convert(numeric(30,2),@IPM_ChargeAmount)) end)
                     )                  as DiscountPercent,
		      convert(numeric(30,2),@IPM_NetChargeAmount)      as NetChargeAmount,
                      convert(numeric(30,2),@IPM_NetChargeAmount)      as ExtChargeAmount, 
		      NULL                      as ILFStartDate,
		      NULL                      as ILFEndDate,
		      NULL                      as ActivationStartDate,
		      NULL                      as ActivationEndDate,
		      'PEND'                    as StatusCode,
		      NULL                      as StartDate,
		      NULL                      as EndDate,
		      null                      as LastBillingPeriodFromDate,
		      null                      as LastBillingPeriodToDate,
		      @IPB_CapMaxUnitsFlag      as CapMaxUnitsFlag,
		      @IPM_dollarminimum        as dollarminimum,
		      @IPM_dollarmaximum        as dollarmaximum,
		      'ARNW'                    as RenewalTypeCode,              
                      @IPVC_ReportTypeCode      as ReportingTypeCode,
                      @IPVC_Discount            as Discount,
                      (case when @LVC_PropertyIDSeq is not null then 'PBT' else 'CBT' end) as  BillToAddressTypeCode,
                      'SMAIL'                                                              as  billtodeliveryoptioncode
  End    
  ------------------------------------------------------------------------------
  ---Orders Pricing Engine is Integrated Below
  ------------------------------------------------------------------------------    
  exec ORDERS.dbo.uspORDERS_SyncOrderGroupAndOrderItem @IPVC_OrderID=@IPVC_OrderIDSeq,@IPI_GroupID=@IPI_OrderGroupIDSeq
  ------------------------------------------------------------------------------ 
  EXEC ORDERS.dbo.uspORDERS_ApplyMBADOExceptionRules  @IPVC_CompanyIDSeq=@LVC_CompanyIDSeq
                                                     ,@IPBI_UserIDSeq   =@IPI_UserIDSeq;
  /****************************************************************************/
END
GO
