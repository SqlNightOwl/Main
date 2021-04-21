SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  :  ORDERS
-- Procedure Name  :  [uspORDERS_ProductListUnitsThreshold]
-- Description     :  This procedure gets the Product Min and Max units threshold for selected products.
-- Input Parameters:  
--					  @IPVC_ProductCode       varchar(50),
--					  @IPVC_FrequencyCode      char(6),
--					  @IPVC_MeasureCode        char(6)
--						
-- Code Example    :  Exec ORDERS.dbo.[uspORDERS_ProductListUnitsThreshold]
--					  @IPVC_ProductCode      = 'DMD-CFR-CCC-CCC-COSR|DMD-CFR-CCC-CCC-CPPW|DMD-CFR-COL-COL-CFOL|DMD-CFR-COR-COR-CFOR|DMD-LSD-SCR-SCR-SCSC|DMD-OSD-SDE-SDE-SVLW|',
--					  @IPVC_FrequencyCode    = 'mn',
--					  @IPVC_MeasureCode      = 'unit'
-- 
-- Revision History:
-- Author          : SRS
-- 12/19/2007      : 
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE  [orders].[uspORDERS_ProductListUnitsThreshold] 
                                                             (
                                                               @IPVC_ProductCode       varchar(8000),
                                                               @IPVC_FrequencyCode     varchar(20),
                                                               @IPVC_MeasureCode       varchar(20)                                             
                                                              )
AS
BEGIN
  set nocount on; 
 --------------------------------------------------------------------------------------------------------
 --  Creating Temporary Table
 --------------------------------------------------------------------------------------------------------
  Create table #TEMP_OrderItemProductListUnitsThreshold   
                                                       (
                                                        SEQ                      int not null identity(1,1),
                                                        ProductCode              varchar(50),                                                                      
                                                        FrequencyCode            varchar(20),                                                                                                       
                                                        MeasureCode              varchar(20),    
                                                        ProductDisplayName       varchar(500),
                                                        AcsMinUnits              int,
                                                        AcsMaxUnits              int
                                                       )
 -------------------------------------------------------------------------------------------------------- 
 --  Inserting date into Temporary Table
 --------------------------------------------------------------------------------------------------------
    insert 
    into  #TEMP_OrderItemProductListUnitsThreshold
                                                   (
                                                    ProductCode,
                                                    FrequencyCode,
                                                    MeasureCode
                                                    )
    select  ProductCode,
            @IPVC_FrequencyCode,
            @IPVC_MeasureCode
    from   customers.dbo.fnSplitProductCodes ('|'+@IPVC_ProductCode+'|')
 -----------------------------------------------------------------------------------
 --  Updating table with product name
 -----------------------------------------------------------------------------------
  Update D
  set    D.ProductDisplayName = P.Displayname
  from   #TEMP_OrderItemProductListUnitsThreshold D with (nolock)
  inner join
         Products.dbo.Product P with (nolock)
  on     P.Code           = D.ProductCode 
  and    P.DisabledFlag   = 0
  ------------------------------------------------------------------
  --PROD ACS Min and Max Units
  ------------------------------------------------------------------
  Update D
  set    D.AcsMinUnits = C.Minunits,
         D.AcsMaxUnits = C.MaxUnits
  from   #TEMP_OrderItemProductListUnitsThreshold D with (nolock)
  inner join
         Products.dbo.Charge C with (nolock)
  on     C.ProductCode    = D.ProductCode
  and    C.DisabledFlag   = 0
  and    C.MeasureCode    = D.measurecode
  and    C.FrequencyCode  = D.frequencycode
  and    C.chargetypecode = 'ACS'
  and    C.MeasureCode    = @IPVC_MeasureCode
  and    C.FrequencyCode  = @IPVC_FrequencyCode
  where  C.MeasureCode    = @IPVC_MeasureCode
  and    C.FrequencyCode  = @IPVC_FrequencyCode
  ------------------------------------------------------------------
  --Final Select 
  ------------------------------------------------------------------
  select ProductCode,UPPER(FrequencyCode) as FrequencyCode,UPPER(MeasureCode) as MeasureCode,
         ProductDisplayName,AcsMinUnits,AcsMaxUnits
  from   #TEMP_OrderItemProductListUnitsThreshold with (nolock)
  order by ProductCode asc
  ------------------------------------------------------------------
  --Final clean up
  drop table #TEMP_OrderItemProductListUnitsThreshold
  --------------------------------------------------------------------
END
--
--Exec ORDERS.dbo.[uspORDERS_ProductListUnitsThreshold]
--  @IPVC_ProductCode      = 'DMD-CFR-CCC-CCC-COSR|DMD-CFR-CCC-CCC-CPPW|DMD-CFR-COL-COL-CFOL|DMD-CFR-COR-COR-CFOR|DMD-LSD-SCR-SCR-SCSC|DMD-OSD-SDE-SDE-SVLW|',
--  @IPVC_FrequencyCode    = 'mn',
--  @IPVC_MeasureCode      = 'unit'
GO
