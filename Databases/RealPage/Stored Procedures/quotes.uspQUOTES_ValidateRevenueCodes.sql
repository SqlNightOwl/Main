SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  :  Products
-- Procedure Name  :  [uspQUOTES_ValidateRevenueCodes]
-- Description     :  This procedure Validate all important Revenue and tax codes for selected products.
-- Input Parameters:  1. @IPT_SetGroupXML TEXT 
--
-- Code Example    : Exec Quotes.dbo.uspQUOTES_ValidateRevenueCodes @IPT_SetGroupXML
-- 
-- Revision History:
-- Author          : SRS
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE  [quotes].[uspQUOTES_ValidateRevenueCodes] (@IPT_SetGroupXML  TEXT = NULL                                                 
                                                         )
AS
BEGIN
  set nocount on; 
  -----------------------------------------------------------------------------------
  --Declaring Local Variables
  declare @LVC_ErrorCodeSection varchar(1000)  
  -----------------------------------------------------------------------------------
  Create table #TEMP_quoteitemForValidateRevenueCodes   
                                  (SEQ                      int not null identity(1,1),
                                   quoteid                  varchar(50),
                                   groupid                  bigint,
                                   productcode              varchar(50),                                                                      
                                   frequencycode            varchar(6),                                                                                                       
                                   measurecode              varchar(6),    
                                   ilffrequencycode         varchar(6),
                                   ilfmeasurecode           varchar(6),                    
                                   priceversion             numeric(18,0) null,                                  
                                   ProductDisplayName       varchar(500)                                   
                                  )   
  Create table #Temp_ErrorHolding (Seq int not null identity(1,1),
                                   ProductDisplayName varchar(500),
                                   ErrorMsg varchar(255))

  Create table #Temp_ErrorResults (ProductDisplayName         varchar(500),
                                   RevenueAccountCode         varchar(1) NULL,
                                   DeferredRevenueAccountCode varchar(1) NULL,
                                   RevenueTierCode            varchar(1) NULL,
                                   TaxwareCode                varchar(1) NULL
                                  )
 
  -----------------------------------------------------------------------------------  
  declare @idoc  int
  -----------------------------------------------------------------------------------
  --Create Handle to access newly created internal representation of the XML document
  -----------------------------------------------------------------------------------
  EXEC sp_xml_preparedocument @idoc OUTPUT,@IPT_SetGroupXML
  -----------------------------------------------------------------------------------  
  -----------------------------------------------------------------------------------
  --OPENXML to read XML and Insert Data into @LT_quoteitem
  ----------------------------------------------------------------------------------- 
  begin TRY
    insert into #TEMP_quoteitemForValidateRevenueCodes(quoteid,groupid,productcode,frequencycode,measurecode,ilffrequencycode,ilfmeasurecode,
                                priceversion,productdisplayname                                
                                )
    select A.quoteid,A.groupid,A.productcode,A.frequencycode,A.measurecode,ilffrequencycode,ilfmeasurecode,         
           A.priceversion,A.productdisplayname              
     from (select coalesce(ltrim(rtrim(quoteid)),'0')                   as quoteid,
                  coalesce(ltrim(rtrim(groupid)),0)                     as groupid,
                  ltrim(rtrim(productcode))                             as productcode,
                  ltrim(rtrim(frequencycode))                           as frequencycode,
                  ltrim(rtrim(measurecode))                             as measurecode,
                  ltrim(rtrim(ilffrequencycode))                        as ilffrequencycode,
                  ltrim(rtrim(ilfmeasurecode))                          as ilfmeasurecode,                                        
                  coalesce(priceversion,0)                              as priceversion,                                
                  ltrim(rtrim(productdisplayname))                      as productdisplayname                 
          from OPENXML (@idoc,'//familyproducts/row[@isselected = "1"]',1) 
          with (quoteid                 varchar(50),
                groupid                 bigint,
                productcode             varchar(50),
                frequencycode           varchar(6),
                measurecode             varchar(6),
                ilffrequencycode        varchar(6),
                ilfmeasurecode          varchar(6),
                priceversion            numeric(18,0),                
                productdisplayname      varchar(500)                
                )
          ) A
  end TRY
  begin CATCH
    select @LVC_ErrorCodeSection = '//products/row uspQUOTES_ValidateRevenueCodes XML Read Section'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorCodeSection    
    if @idoc is not null
    begin
      EXEC sp_xml_removedocument @idoc
      set @idoc = NULL
    end   
    return
  end CATCH;      
  ------------------------------------------------------------------
  Update D
  set    D.ProductDisplayName = P.Displayname         
  from   #TEMP_quoteitemForValidateRevenueCodes D      with (nolock)
  inner join
         Products.dbo.Product P with (nolock)
  on     P.Code         = D.ProductCode 
  and    P.PriceVersion = D.PriceVersion
  ------------------------------------------------------------------
  Insert into #Temp_ErrorHolding(ProductDisplayName,ErrorMsg)
  select D.ProductDisplayName + ': ILF/' + D.ilfmeasurecode + '/' + replace(replace(D.ilffrequencycode,'SG','Initial fee'),'OT','One-time'),
         'RevenueAccountCode' 
  from   #TEMP_quoteitemForValidateRevenueCodes D     with (nolock)
  inner join
         Products.dbo.Charge C with (nolock)
  on     C.ProductCode  = D.ProductCode
  and    C.DisabledFlag = 0
  and    C.MeasureCode  = D.ilfmeasurecode
  and    C.FrequencyCode= D.ilffrequencycode
  and    C.Chargetypecode='ILF'
  and    (C.RevenueAccountCode is NULL or C.RevenueAccountCode = '')
  ------------------------------------------------------------------
  Insert into #Temp_ErrorHolding(ProductDisplayName,ErrorMsg)
  select D.ProductDisplayName + ': ILF/' + D.ilfmeasurecode + '/' + replace(replace(D.ilffrequencycode,'SG','Initial fee'),'OT','One-time'),
         'DeferredRevenueAccountCode' 
  from   #TEMP_quoteitemForValidateRevenueCodes D     with (nolock)
  inner join
         Products.dbo.Charge C with (nolock)
  on     C.ProductCode  = D.ProductCode
  and    C.DisabledFlag = 0
  and    C.MeasureCode  = D.ilfmeasurecode
  and    C.FrequencyCode= D.ilffrequencycode
  and    C.Chargetypecode='ILF'
  and    C.RevenueRecognitionCode = 'SRR'
  and    (C.DeferredRevenueAccountCode is NULL or C.DeferredRevenueAccountCode = '')
  ------------------------------------------------------------------
  Insert into #Temp_ErrorHolding(ProductDisplayName,ErrorMsg)
  select D.ProductDisplayName + ': ILF/' + D.ilfmeasurecode + '/' + replace(replace(D.ilffrequencycode,'SG','Initial fee'),'OT','One-time'),
        'RevenueTierCode' 
  from   #TEMP_quoteitemForValidateRevenueCodes D     with (nolock)
  inner join
         Products.dbo.Charge C with (nolock)
  on     C.ProductCode  = D.ProductCode
  and    C.DisabledFlag = 0
  and    C.MeasureCode  = D.ilfmeasurecode
  and    C.FrequencyCode= D.ilffrequencycode
  and    C.Chargetypecode='ILF'
  and    (C.RevenueTierCode is NULL or C.RevenueTierCode = '')
  ------------------------------------------------------------------
  Insert into #Temp_ErrorHolding(ProductDisplayName,ErrorMsg)
  select D.ProductDisplayName + ': ILF/' + D.ilfmeasurecode + '/' + replace(replace(D.ilffrequencycode,'SG','Initial fee'),'OT','One-time'),
         'TaxwareCode' 
  from   #TEMP_quoteitemForValidateRevenueCodes D     with (nolock)
  inner join
         Products.dbo.Charge C with (nolock)
  on     C.ProductCode  = D.ProductCode
  and    C.DisabledFlag = 0
  and    C.MeasureCode  = D.ilfmeasurecode
  and    C.FrequencyCode= D.ilffrequencycode
  and    C.Chargetypecode='ILF'
  and    (C.TaxwareCode is NULL or C.TaxwareCode = '')
  ------------------------------------------------------------------
  Insert into #Temp_ErrorHolding(ProductDisplayName,ErrorMsg)
  select D.ProductDisplayName + ': ACS/' + D.measurecode + '/' + replace(replace(D.frequencycode,'SG','Initial fee'),'OT','One-time'),
         'RevenueAccountCode' 
  from   #TEMP_quoteitemForValidateRevenueCodes D     with (nolock)
  inner join
         Products.dbo.Charge C with (nolock)
  on     C.ProductCode  = D.ProductCode
  and    C.DisabledFlag = 0
  and    C.MeasureCode  = D.measurecode
  and    C.FrequencyCode= D.frequencycode
  and    C.Chargetypecode='ACS'
  and    (C.RevenueAccountCode is NULL or C.RevenueAccountCode = '')
  ------------------------------------------------------------------
  Insert into #Temp_ErrorHolding(ProductDisplayName,ErrorMsg)
  select D.ProductDisplayName + ': ACS/' + D.measurecode + '/' + replace(replace(D.frequencycode,'SG','Initial fee'),'OT','One-time'),
         'DeferredRevenueAccountCode'
  from   #TEMP_quoteitemForValidateRevenueCodes D     with (nolock)
  inner join
         Products.dbo.Charge C with (nolock)
  on     C.ProductCode  = D.ProductCode
  and    C.DisabledFlag = 0
  and    C.MeasureCode  = D.measurecode
  and    C.FrequencyCode= D.frequencycode
  and    C.Chargetypecode='ACS'
  and    C.RevenueRecognitionCode = 'SRR'
  and    (C.DeferredRevenueAccountCode is NULL or C.DeferredRevenueAccountCode = '')
  ------------------------------------------------------------------
  Insert into #Temp_ErrorHolding(ProductDisplayName,ErrorMsg)
  select D.ProductDisplayName + ': ACS/' + D.measurecode + '/' + replace(replace(D.frequencycode,'SG','Initial fee'),'OT','One-time'),
         'RevenueTierCode' 
  from   #TEMP_quoteitemForValidateRevenueCodes D     with (nolock)
  inner join
         Products.dbo.Charge C with (nolock)
  on     C.ProductCode  = D.ProductCode
  and    C.DisabledFlag = 0
  and    C.MeasureCode  = D.measurecode
  and    C.FrequencyCode= D.frequencycode
  and    C.Chargetypecode='ACS'
  and    (C.RevenueTierCode is NULL or C.RevenueTierCode = '')
  ------------------------------------------------------------------
  Insert into #Temp_ErrorHolding(ProductDisplayName,ErrorMsg)
  select D.ProductDisplayName + ': ACS/' + D.measurecode + '/' + replace(replace(D.frequencycode,'SG','Initial fee'),'OT','One-time'),
         'TaxwareCode'
  from   #TEMP_quoteitemForValidateRevenueCodes D     with (nolock)
  inner join
         Products.dbo.Charge C with (nolock)
  on     C.ProductCode  = D.ProductCode
  and    C.DisabledFlag = 0
  and    C.MeasureCode  = D.measurecode
  and    C.FrequencyCode= D.frequencycode
  and    C.Chargetypecode='ACS'
  and    (C.TaxwareCode is NULL or C.TaxwareCode = '')
  ------------------------------------------------------------------
  Insert into #Temp_ErrorResults(ProductDisplayName)
  select distinct ProductDisplayName 
  from   #Temp_ErrorHolding with (nolock)
  order  by ProductDisplayName asc

  Update D
  set    D.RevenueAccountCode         = (case when S.ErrorMsg = 'RevenueAccountCode' then 'X' else '' end)         
  from   #Temp_ErrorResults D with (nolock)
  inner join
        #Temp_ErrorHolding S with (nolock)
  on     D.ProductDisplayName = S.ProductDisplayName
  and    S.ErrorMsg = 'RevenueAccountCode'

  Update D
  set    D.DeferredRevenueAccountCode = (case when S.ErrorMsg = 'DeferredRevenueAccountCode' then 'X' else '' end)
  from   #Temp_ErrorResults D with (nolock)
  inner join
        #Temp_ErrorHolding S with (nolock)
  on     D.ProductDisplayName = S.ProductDisplayName
  and    S.ErrorMsg = 'DeferredRevenueAccountCode'

  Update D
  set    D.RevenueTierCode            = (case when S.ErrorMsg = 'RevenueTierCode' then 'X' else '' end)
  from   #Temp_ErrorResults D with (nolock)
  inner join
        #Temp_ErrorHolding S with (nolock)
  on     D.ProductDisplayName = S.ProductDisplayName
  and    S.ErrorMsg = 'RevenueTierCode'


  Update D
  set    D.TaxwareCode                = (case when S.ErrorMsg = 'TaxwareCode' then 'X' else '' end)
  from   #Temp_ErrorResults D with (nolock)
  inner join
        #Temp_ErrorHolding S with (nolock)
  on     D.ProductDisplayName = S.ProductDisplayName
  and    S.ErrorMsg = 'TaxwareCode'
   
  Update #Temp_ErrorResults set RevenueAccountCode = '' where RevenueAccountCode is null
  Update #Temp_ErrorResults set DeferredRevenueAccountCode = '' where DeferredRevenueAccountCode is null
  Update #Temp_ErrorResults set RevenueTierCode = '' where RevenueTierCode is null
  Update #Temp_ErrorResults set TaxwareCode = '' where TaxwareCode is null
  ------------------------------------------------------------------
  --Final Select 
  select ProductDisplayName,RevenueAccountCode,DeferredRevenueAccountCode,RevenueTierCode,TaxwareCode
  from   #Temp_ErrorResults   with (nolock)  
  order by ProductDisplayName asc
  ------------------------------------------------------------------
  --Final clean up
  if @idoc is not null
  begin
    EXEC sp_xml_removedocument @idoc
    set @idoc = NULL
  end 
  drop table #TEMP_quoteitemForValidateRevenueCodes
  drop table #Temp_ErrorHolding
  drop table #Temp_ErrorResults
  --------------------------------------------------------------------
END
GO
