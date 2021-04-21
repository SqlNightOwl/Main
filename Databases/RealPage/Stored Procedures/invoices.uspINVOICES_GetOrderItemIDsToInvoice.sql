SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_GetOrderItemIDsToInvoice
-- Description     : Retrieves OrderItemIDs that have to be Invoiced.
-- Input Parameters: @IPVC_OrderIDSeq varchar(50)
--                   
-- OUTPUT          : 
-- Code Example    : Exec INVOICES.dbo.[uspINVOICES_GetOrderItemIDsToInvoice]   @IPVC_OrderIDSeq  = 'O0805000032'
--                                                             
-- Revision History:
-- Author          : Shashi Bhushan
-- 04/26/2008      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_GetOrderItemIDsToInvoice] (@IPVC_OrderIDSeq VARCHAR(50))
AS
BEGIN
  set nocount on;
  DECLARE @LDT_TargetDate   DATETIME;
  SELECT  @LDT_TargetDate = dateadd(dd,45,getdate()) 

  select  distinct OI.IDSeq
  from    ORDERS.dbo.Orderitem OI with (nolock)
  where   OI.Orderidseq     = @IPVC_OrderIDSeq
  and     OI.StatusCode     <>  'EXPD'
  AND     OI.MeasureCode    <>  'TRAN'
  -----------------------------------
  AND     OI.DoNotInvoiceFlag    = 0
  AND     (
           (OI.ChargeTypeCode = 'ILF' and (OI.ILFStartDate <> Coalesce(OI.canceldate,'')) and OI.ILFEndDate is NOT NULL ---->and OI.ILFStartDate <= @LDT_TargetDate Defect#5467
            and (coalesce(OI.Canceldate,OI.ILFStartDate) >= OI.ILFStartDate) and  OI.LastBillingPeriodToDate is NULL)
                     OR
           (OI.ChargeTypeCode = 'ACS' and OI.Frequencycode = 'OT'  and (OI.ActivationStartDate <> Coalesce(OI.canceldate,'')) and OI.ActivationEndDate is NOT NULL 
            and (coalesce(OI.Canceldate,OI.ActivationStartDate) >= OI.ActivationStartDate) and OI.LastBillingPeriodToDate is NULL)
                             OR
           (OI.ChargeTypeCode = 'ACS' and OI.Frequencycode  <> 'OT' and (OI.ActivationStartDate <> Coalesce(OI.canceldate,'')) and OI.ActivationEndDate is NOT NULL and OI.ActivationStartDate <= @LDT_TargetDate 
            and (coalesce(OI.Canceldate,OI.ActivationStartDate) >= OI.ActivationStartDate) and  OI.LastBillingPeriodToDate is NULL)
                           OR
           (OI.ChargeTypeCode = 'ACS' and OI.Frequencycode  <> 'OT' and (OI.ActivationStartDate <> Coalesce(OI.canceldate,'')) and OI.ActivationEndDate is NOT NULL and OI.ActivationStartDate <= @LDT_TargetDate 
            and (coalesce(OI.Canceldate,OI.ActivationStartDate) >= OI.ActivationStartDate)
            and  OI.LastBillingPeriodToDate < Coalesce(OI.canceldate,OI.ActivationEndDate)
            and  OI.LastBillingPeriodToDate < @LDT_TargetDate)                      
          )
  ----------------------------------- 
  
END

GO
