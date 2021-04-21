SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_GetOrderMeasureCode]
-- Description     : Returns the product code based on the passed parameters
-- Input Parameters: 
-- 
-- Select * From Orders..Order
-- EXEC ORDERS..[uspORDERS_GetOrderMeasureCode] 'C0804000183', '', ''
-- EXEC ORDERS..[uspORDERS_GetOrderMeasureCode] 'C0804002651', 'P0804033512', ''
-- EXEC ORDERS..[uspORDERS_GetOrderMeasureCode] @IPVC_CompanyIDSeq = 'C0804000183', @IPVC_MeasureCode = 'TRAN', @IPVC_ProductCode = 'DMD-PSR-ICM-ICM-MOSC'
-- EXEC ORDERS..[uspORDERS_GetOrderMeasureCode] @IPVC_CompanyIDSeq = 'C0804002651', @IPVC_PropertyIDSeq='P0804033512', @IPVC_MeasureCode = 'TRAN', @IPVC_ProductCode = 'DMD-PSR-ICM-ICM-MOSC'
------------------------------------------------------------------------------------------------------
-- Revision History:
-- Author          : Bhavesh Shah
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_GetOrderMeasureCode] 
(
  @IPVC_CompanyIDSeq varchar(11), 
  @IPVC_PropertyIDSeq varchar(11) = null,
  @IPVC_MeasureCode varchar(6) = null,
  @IPVC_ProductCode varchar(30) = null
)					
AS
BEGIN 
  set nocount on;
  ------------------------------------
  declare @LC_ProductCode  varchar(30)
  declare @LVC_MeasureCode varchar(5)
  ------------------------------------

  SET @IPVC_PropertyIDSeq = NULLIF(@IPVC_PropertyIDSeq, '');
  SET @IPVC_MeasureCode = NULLIF(@IPVC_MeasureCode, '');
  SET @IPVC_ProductCode = NULLIF(@IPVC_ProductCode, '');

  select 
    oi.ProductCode,
    oi.MeasureCode,
    o.CompanyIDSeq,
    o.AccountIDSeq,
    o.PropertyIDSeq
  from  
    Orders.dbo.[Order] o WITH (NOLOCK)
      inner join Orders.dbo.OrderItem  oi WITH (NOLOCK)
        on  oi.OrderIDSeq  = o.OrderIDSeq
        and oi.StatusCode  <> 'EXPD'
        and Coalesce(oi.canceldate,oi.ActivationEndDate) >= Getdate()
        and oi.Measurecode = Coalesce(@IPVC_MeasureCode,oi.Measurecode)
        and oi.ProductCode = Coalesce(@IPVC_ProductCode,oi.ProductCode)    
        and ( 
              ( @IPVC_PropertyIDSeq IS NULL AND o.PropertyIDSeq IS NULL )
              OR ( @IPVC_PropertyIDSeq IS NOT NULL AND o.PropertyIDSeq = @IPVC_PropertyIDSeq )
            )
        and o.CompanyIDSeq = @IPVC_CompanyIDSeq
  where
    o.CompanyIDSeq = @IPVC_CompanyIDSeq
    and ( 
          ( @IPVC_PropertyIDSeq IS NULL AND o.PropertyIDSeq IS NULL )
          OR ( @IPVC_PropertyIDSeq IS NOT NULL AND o.PropertyIDSeq = @IPVC_PropertyIDSeq )
        )
    and oi.StatusCode  <> 'EXPD'
    and oi.Measurecode = Coalesce(@IPVC_MeasureCode,oi.Measurecode)
    and oi.ProductCode = Coalesce(@IPVC_ProductCode,oi.ProductCode)    
    and Coalesce(oi.canceldate,oi.ActivationEndDate) >= Getdate()
END

GO
