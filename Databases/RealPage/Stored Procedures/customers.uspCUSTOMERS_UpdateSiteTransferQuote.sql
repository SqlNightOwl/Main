SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		STA
-- Create date: 05/21/2007
-- Description:	This procedure updates the Quote and returns the recordset of the 
--              details of the quote table if the user edits the details in the course of transferring sites
---             
-- =============================================
CREATE PROCEDURE [customers].[uspCUSTOMERS_UpdateSiteTransferQuote] (
                                                              @IPVC_CustomerID    varchar(11),
                                                              @IPVC_CustomerName  varchar(70),
                                                              @IPI_Units int,
                                                              @IPI_Beds int,
                                                              @IPVC_QuoteID varchar(11)
                                                            )
	
AS
BEGIN
	/*************************************************************************************/
    UPDATE  QUOTES.[dbo].Quote 
    SET     CustomerIDSeq = @IPVC_CustomerID,
            CompanyName  = @IPVC_CustomerName,
            Units         = @IPI_Units,
            Beds          = @IPI_Beds
    WHERE   QuoteIDSeq    = @IPVC_QuoteID
  /*************************************************************************************/

  /****
        Final select
  *****/

 declare @LT_Summary table
          (
              productname varchar(255),
              units int,
              ilflistprice money,
              accesslistprice money,
              discountpercent int,
              discountamount money,
              ilfnetprice money,
              accessnetprice money
          )

          insert into @LT_Summary
          (
              productname,
              units,
              ilflistprice,
              accesslistprice,
              discountpercent,
              discountamount,
              ilfnetprice,
              accessnetprice
          )

          select 

                prod.DisplayName as productname,
                qitem.units as units,
                grp.ILFExtYearChargeAmount as ilflistprice,
                grp.AccessExtYear1ChargeAmount    as accesslistprice,
                grp.ILFDiscountPercent         as discountpercent,
                grp.ILFDiscountAmount         as discountamount,
                grp.ILFNetExtYearChargeAmount                         as ilfnetprice,
                grp.AccessNetExtYear1ChargeAmount                     as accessnetprice

          from Quotes.dbo.QuoteItem qitem

          inner join Products.dbo.Product prod

          on    qitem.ProductCode = prod.Code
          and   qitem.PriceVersion= prod.PriceVersion

          inner join Quotes.dbo.[Group] grp

          on qitem.QuoteIDSeq = grp.QuoteIDSeq

          where qitem.QuoteIDSeq = @IPVC_QuoteID


          select 
                productname,
                units,
                convert(numeric(10,2),ilflistprice)        as ilflistprice,
                convert(numeric(10,2),accesslistprice)     as accesslistprice,
                convert(numeric(10,2),discountpercent)     as discountpercent,
                convert(numeric(10,2),discountamount)      as discountamount,
                convert(numeric(10,2),ilfnetprice)         as ilfnetprice,
                convert(numeric(10,2),accessnetprice)      as accessnetprice
          from @LT_Summary

          select 
                sum(convert(numeric(10,2),ilflistprice))        as ilflistprice,
                sum(convert(numeric(10,2),accesslistprice))     as accesslistprice,
                sum(convert(numeric(10,2),discountpercent))     as discountpercent,
                sum(convert(numeric(10,2),discountamount))      as discountamount,
                sum(convert(numeric(10,2),ilfnetprice))         as ilfnetprice,
                sum(convert(numeric(10,2),accessnetprice))      as accessnetprice
          from @LT_Summary          

END

GO
