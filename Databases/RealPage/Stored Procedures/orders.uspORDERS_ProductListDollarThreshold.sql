SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  :  [ORDERS]
-- Procedure Name  :  [uspORDERS_ProductListDollarThreshold]
-- Description     :  This procedure gets the Product Min and Max units threshold for selected products.
-- Input Parameters:  @IPVC_ProductCode       varchar(50),
--					  @IPVC_FrequencyCode      char(6),
--					  @IPVC_MeasureCode        char(6)
--
-- Code Example    :  
--                  Exec ORDERS.dbo.[uspORDERS_ProductListDollarThreshold]
--					  @IPVC_ProductCode      = 'DMD-CFR-CCC-CCC-COSR|DMD-CFR-CCC-CCC-CPPW|DMD-CFR-COL-COL-CFOL|DMD-CFR-COR-COR-CFOR|DMD-LSD-SCR-SCR-SCSC|DMD-OSD-SDE-SDE-SVLW|',
--					  @IPVC_FrequencyCode    = 'mn',
--					  @IPVC_MeasureCode      = 'unit'
-- 
-- Revision History:
-- Author          : SRS
-- 12/19/2007      :  
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE  [orders].[uspORDERS_ProductListDollarThreshold]
                                                               (  
                                                                 @IPVC_ProductCode    varchar(8000),
                                                                 @IPVC_FrequencyCode  varchar(20),
                                                                 @IPVC_MeasureCode    varchar(20) 
                                                               )
AS
BEGIN
  set nocount on; 
  -----------------------------------------------------------------------------------
  -- Creating Temporary Table
  -----------------------------------------------------------------------------------
  Create table #TEMP_OrderItemProductListDollarThreshold    
                                                        (
                                                         SEQ                          int not null identity(1,1),
                                                         ProductCode                  varchar(50),                                                                      
                                                         FrequencyCode                varchar(20),                                                                                                       
                                                         MeasureCode                  varchar(20),    
                                                         ProductDisplayName           varchar(500), 
                                                         ACSDollarMinimum             int not null default 0,
                                                         ACSDollarMinimumEnabledFlag  int not null default 0,
                                                         ACSDollarMaximum             int not null default 0,
                                                         ACSDollarMaximumEnabledFlag  int not null default 0                                 
                                                        )   
 -----------------------------------------------------------------------------------  
  insert 
  into #TEMP_OrderItemProductListDollarThreshold
                                                 (
                                                   ProductCode,
                                                   FrequencyCode,
                                                   MeasureCode
                                                 )
  select ProductCode,
         @IPVC_FrequencyCode,
         @IPVC_MeasureCode
  from   customers.dbo.fnSplitProductCodes ('|'+@IPVC_ProductCode+'|')
 -----------------------------------------------------------------------------------
 --  Updating table with product name
 -----------------------------------------------------------------------------------
  Update D
  set    D.ProductDisplayName = P.Displayname
  from   #TEMP_OrderItemProductListDollarThreshold D with (nolock)
  inner join
         Products.dbo.Product P with (nolock)
  on     P.Code           = D.ProductCode 
  and    P.DisabledFlag   = 0
 ------------------------------------------------------------------
 --Updating ACS Dollar min and Max values for Products
 ------------------------------------------------------------------
  Update D
  set    D.ACSDollarMinimum            = C.DollarMinimum,
         D.ACSDollarMinimumEnabledFlag = C.DollarMinimumEnabledFlag,
         D.ACSDollarMaximum            = C.DollarMaximum,
         D.ACSDollarMaximumEnabledFlag = C.DollarMaximumEnabledFlag
  from   #TEMP_OrderItemProductListDollarThreshold D with (nolock)
  inner join
         Products.dbo.Charge C                       with (nolock)
  on     C.ProductCode    = D.ProductCode  
  and    C.MeasureCode    = D.measurecode
  and    C.FrequencyCode  = D.frequencycode  
  and    C.Chargetypecode = 'ACS'
  and    C.DisabledFlag   = 0
  and    C.MeasureCode    = @IPVC_MeasureCode
  and    C.FrequencyCode  = @IPVC_FrequencyCode
  where  C.MeasureCode    = @IPVC_MeasureCode
  and    C.FrequencyCode  = @IPVC_FrequencyCode
 ------------------------------------------------------------------
 --Final Select 
 ------------------------------------------------------------------
  select ProductCode,
         UPPER(FrequencyCode),
         UPPER(MeasureCode),
         ProductDisplayName,
	     ACSDollarMinimum,
         ACSDollarMinimumEnabledFlag,
         ACSDollarMaximum,
         ACSDollarMaximumEnabledFlag
  from   #TEMP_OrderItemProductListDollarThreshold with (nolock)
  where  ( (ACSDollarMinimumEnabledFlag <> 0) OR (ACSDollarMaximumEnabledFlag <> 0) ) 
 ------------------------------------------------------------------
 --Final clean up
  drop table #TEMP_OrderItemProductListDollarThreshold
 --------------------------------------------------------------------
END

--Exec ORDERS.dbo.[uspORDERS_ProductListDollarThreshold]
--  @IPVC_ProductCode      = 'DMD-CFR-CCC-CCC-COSR|DMD-CFR-CCC-CCC-CPPW|DMD-CFR-COL-COL-CFOL|DMD-CFR-COR-COR-CFOR|DMD-LSD-SCR-SCR-SCSC|DMD-OSD-SDE-SDE-SVLW|',
--  @IPVC_FrequencyCode    = 'mn',
--  @IPVC_MeasureCode      = 'unit'
GO
