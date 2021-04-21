SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------- 
-- procedure   : uspORDERS_ScreeningGetOrderTransactions
-- server      : OMS
-- Database    : ORDERS
 
-- purpose     : Get all Screening ACCCESS Only Orders
--
-- Input Param: @IPDT_ReportMonthEndDate datetime -- Month end date of reporting month end
--              
-- returns     : resultset as below

-- Example of how to call this stored procedure:
-- EXEC ORDERS.dbo.uspORDERS_ScreeningGetOrderTransactions @IPDT_ReportMonthEndDate = '1/31/2009'

-- Date         Author          Comments
-- -----------  -------------   ---------------------------
-- 2009-MAR-30	Bhavesh Shah  	Initial creation


-- Copyright  : copyright (c) 2008.  RealPage Inc.
-- This module is the confidential & proprietary property of
-- RealPage Inc.
-----------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_ScreeningGetOrderTransactions] 
AS
BEGIN
  set nocount on;

	SELECT	
		O.CompanyIDSeq
		, OIT.IDSeq AS OrderItemTransactionIDSeq
		-- These Column makes this a unique transaction.  They will be used to compare duplicates.
		, O.PropertyIDSeq
		, OIT.SourceTransactionID
		, OIT.TransactionItemName
		, CAST(CONVERT(varchar(10), OIT.ServiceDate, 101) AS Datetime) AS ServiceDate
		, OIT.ProductCode
		, OIT.NetChargeAmount
	FROM
		OrderItemTransaction OIT WITH (NOLOCK)
			INNER JOIN [Order] O WITH (NOLOCK)
				ON OIT.OrderIDSeq = O.OrderIDSeq
			INNER JOIN PRODUCTS.dbo.ScreeningProductMapping SPM WITH (NOLOCK)
				ON OIT.ProductCode = SPM.ProductCode
						-- Added this to make sure we only get one record for given product code.
						AND   SPM.Priority   = (Select MIN(SM.Priority) 
																		FROM   Products.dbo.ScreeningProductMapping SM WITH (NOLOCK) 
																		WHERE  SM.ProductCode = OIT.ProductCode)
	ORDER BY
	-- Sort by these columns so SSIS can use it in merge.
		O.PropertyIDSeq
		, OIT.SourceTransactionID
		, OIT.TransactionItemName
		, OIT.ServiceDate
		, OIT.ProductCode
		, OIT.NetChargeAmount
	
END

GO
