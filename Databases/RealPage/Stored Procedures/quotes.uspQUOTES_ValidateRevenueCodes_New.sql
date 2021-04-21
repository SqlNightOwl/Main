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
CREATE PROCEDURE  [quotes].[uspQUOTES_ValidateRevenueCodes_New] (@IPT_SetGroupXML  TEXT = NULL                                                   
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
 --------------------------------------------------------------------
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
