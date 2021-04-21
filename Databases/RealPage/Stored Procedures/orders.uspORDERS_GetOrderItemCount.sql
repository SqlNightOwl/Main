SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : uspORDERS_GetOrderItemCount
-- Description     : This procedure gets the no. of order items that a property holds.
--
-- Input Parameters: @IPVC_PropertyID VARCHAR(22)
--
-- OUTPUT          : The no. of order items that a property holds.
--
-- Code Example    : Exec [dbo].[uspORDERS_GetOrderItemCount] (@IPVC_PropertyID = '')
-- 
-- Revision History:
-- Author          : STA, SRA Systems Limited.
-- 05/22/2007      : Stored Procedure Created.
-- 
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_GetOrderItemCount] (@IPVC_PropertyID VARCHAR(50))	
AS
BEGIN
  /****************************************************************************/
	SELECT      COUNT(*) 
  FROM        Orders..OrderItem OI WITH (NOLOCK)

  INNER JOIN  Orders..[Order]   O  WITH (NOLOCK)
    ON        O.OrderIDSeq      = OI.OrderIDSeq

  WHERE       O.PropertyIDSeq   = @IPVC_PropertyID
    AND       (
                OI.ILFEndDate         >= GETDATE()  OR 
                OI.ActivationEndDate  <= GETDATE()
              )
    AND       (
                OI.CancelDate   IS NULL       OR 
                OI.CancelDate   >= GETDATE()
              )
  /****************************************************************************/
END

GO
