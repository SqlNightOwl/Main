SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDER_ValidateOrderItemTransactionFroManualImport]
-- Description     : This procedure gets the list of CancelReasons
--
--
-- Code Example    : Exec Orders.dbo.[uspORDER_ValidateOrderItemTransactionFroManualImport]
--
-- Revision History:
-- Author          : Naval Kishore
-- 07/08/2009      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDER_ValidateOrderItemTransactionFroManualImport]
									(
									@IPVC_AccountIDSeq      varchar(50),
									@IPVC_ProductCode       varchar(50),
									@IPVC_ProductName       varchar(50),
									@IPVC_OrderIDSeq        varchar(20),
									@IPDT_TransactionDate   datetime
									)

AS
BEGIN -- Main BEGIN starts at Col 01
    
        /*********************************************************************************************/
        /*                 Main Select statement                                                     */  
        /*********************************************************************************************/
   set nocount on;
   ---Check for Existence of a Subscription Order for the same productcode for the same Account
   -- before allowing to add a Manual Transaction.
   Select Top 1 O.OrderIDSeq, @IPVC_ProductName as ProductName,OI.StartDate, OI.Enddate
   From  Orders.dbo.[Order]     O  with (nolock)
   inner join
         Orders.dbo.[OrderItem] OI with (nolock)
   on    O.OrderIDSeq  = OI.OrderIDSeq
   and   O.AccountIDSeq = @IPVC_AccountIDSeq
   and   OI.ProductCode = @IPVC_ProductCode
   inner join
         Products.dbo.Charge CHG with (nolock)
   on    OI.ProductCode   = CHG.ProductCode
   and   OI.ProductCode   = @IPVC_ProductCode
   and   CHG.ProductCode  = @IPVC_ProductCode
   and   OI.Priceversion  = CHG.Priceversion
   and   OI.Measurecode   = CHG.measurecode
   and   OI.Frequencycode = CHG.Frequencycode 
   and   OI.Chargetypecode= CHG.Chargetypecode
   and   CHG.QuantityEnabledFlag = 0
   and   CHG.ReportingTypecode   = 'ACSF'
   and   OI.Chargetypecode       = 'ACS'   
   and   OI.Frequencycode  in ('YR','MN')   
   and   isdate(OI.Startdate) = 1
   and   (@IPDT_TransactionDate >= OI.Startdate
           and
          @IPDT_TransactionDate <= coalesce(OI.Canceldate-1,OI.Enddate)
           and
          OI.Startdate<>OI.Canceldate
         )
END -- Main END starts at Col 01
GO
