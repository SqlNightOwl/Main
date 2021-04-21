SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_ValidateProductItemCode
-- Description     : This procedure gets the list of Family
--
-- OUTPUT          : RecordSet of  ItemCode from PRODUCTS..[Product]
--
-- Code Example    : Exec uspPRODUCTS_ValidateProductItemCode 'RPIO',true,'DMD-CFR-ACS-ASL-RPIO'
--
-- Revision History:
-- Author          : Raghavender Talusani
-- 06/09/2009     : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_ValidateProductItemCode] 
@IPVC_ItemCode varchar(10),
@IPB_Mode bit,
@IPVC_ProductCode char(30)
 
As
BEGIN 
  
  IF(@IPB_Mode=0)
	  BEGIN
		  SELECT   ItemCode 
		  FROM     PRODUCTS.dbo.[Product]  with (nolock)
		  WHERE    ItemCode =@IPVC_ItemCode 
	  END
  ELSE
	  BEGIN
		 DECLARE @LV_ItemCode varchar(10)
		 SELECT @LV_ItemCode = ItemCode 
		 FROM   PRODUCTS.dbo.[Product] with (nolock)
		 WHERE  Code=@IPVC_ProductCode

		  IF(@LV_ItemCode<>@IPVC_ItemCode)
		  BEGIN
			  SELECT   ItemCode 
			  FROM     PRODUCTS.dbo.[Product]  with (nolock)
			  WHERE    ItemCode =@IPVC_ItemCode 
		  END

      END
END
GO
