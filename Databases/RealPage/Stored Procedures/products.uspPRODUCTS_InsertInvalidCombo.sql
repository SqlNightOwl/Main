SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : [uspPRODUCTS_InsertInvalidCombo]
-- Description     : This procedure gets Code,Name
--                   from product table 
-- Input Parameters: @IPC_ProductCode char(30),
--                   @IPN_PriceVersion numeric(18,0),
--                   @IPVC_StartDate datetime,
--									 @IPVC_EndDate datetime,
--                   @IPC_SecondProduct varchar(300)
-- OUTPUT          : RecordSet of Code,Name,PriceVersion
-- Code Example    : exec [dbo].[uspPRODUCTS_InsertInvalidCombo] 'PRM-LEG-LEG-LEG-LAAP','101',
--                    '01/01/1900','12/31/2050','DMD-ADM-ACS-ACS-kksn|DMD-CFR-CCC-CCC-CCCC|'
-- Author          : Naval Kishore Singh 
-- 12/06/2007      : Stored Procedure Created.

------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_InsertInvalidCombo](
                                                          @IPC_ProductCode		CHAR(30),
                                                          @IPN_PriceVersion		NUMERIC(18,0),
                                                          @IPC_SecondProduct	VARCHAR(4000)
                                                     ) 		
AS
BEGIN
DECLARE @loopid INT;
DECLARE @PriceVersion NUMERIC(18,0)
--------------------------------------------------------------------------------------------------
--Delete from ProductInvalidCombo for existing Combination
--------------------------------------------------------------------------------------------------
  DELETE FROM dbo.ProductInvalidCombo WHERE FirstProductCode=@IPC_ProductCode
                                      AND FirstProductPriceVersion=@IPN_PriceVersion    

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
--Update Product Table
--------------------------------------------------------------------------------------------------
--  UPDATE dbo.Product set StartDate= @IPVC_StartDate, EndDate=@IPVC_EndDate
--     WHERE Code = @IPC_ProductCode AND PriceVersion=@IPN_PriceVersion  

--------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------
--Insert into ProductInvalidCombo

CREATE TABLE #Tbl1 (rowid int identity(1,1),
					ProductCode varchar(300))

INSERT INTO #Tbl1(ProductCode)  
SELECT ProductCode  FROM   Customers.dbo.fnSplitProductCodes ('|'+@IPC_SecondProduct)

SELECT @loopid = 1

WHILE @loopid <= (SELECT Count(rowid) FROM #Tbl1)
BEGIN

SET @PriceVersion = (select P.Priceversion from Products.dbo.Product P inner join #Tbl1 T1 on p.code = T1.Productcode where T1.ProductCode = P.Code and P.DisabledFlag = 0 and P.PendingApprovalFlag=0 and  T1.rowid = @loopid)
INSERT INTO dbo.ProductInvalidCombo
              (
                FirstProductCode,
                FirstProductPriceVersion,
                SecondProductCode,
                SecondProductPriceVersion
              ) 
           SELECT 
                  @IPC_ProductCode,
                  @IPN_PriceVersion, 
                  T1.ProductCode,
                  @PriceVersion  
           From  #Tbl1 T1
           where T1.rowid = @loopid  
          
SET @loopid = @loopid + 1
END
drop table #Tbl1
END
--exec [dbo].[uspPRODUCTS_InsertInvalidCombo] 'PRM-LEG-LEG-LEG-LAAP','101','01/01/1900','12/31/2050','DMD-ADM-ACS-ACS-kksn|DMD-CFR-CCC-CCC-CCCC|'
GO
