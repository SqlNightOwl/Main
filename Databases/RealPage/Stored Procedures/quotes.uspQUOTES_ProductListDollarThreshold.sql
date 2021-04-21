SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  :  Products
-- Procedure Name  :  [uspQUOTES_ProductListDollarThreshold]
-- Description     :  This procedure gets the Product Min and Max units threshold for selected products.
-- Input Parameters:  1. @IPT_SetGroupXML TEXT 
--
-- Code Example    : Exec Quotes.dbo.uspQUOTES_ProductListDollarThreshold @IPT_SetGroupXML
-- 
-- Revision History:
-- Author          : SRS
-- 11/16/2007      : OLD proc uspPRODUCTS_ProductListDollarThreshold has serious drawbacks and delimiter parsing.
--                   Doing away with that.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE  [quotes].[uspQUOTES_ProductListDollarThreshold] (@IPT_SetGroupXML  TEXT = NULL                                                 
                                                         )
AS
BEGIN
  set nocount on; 
  -----------------------------------------------------------------------------------
  --Declaring Local Variables
  declare @LVC_ErrorCodeSection varchar(1000)
  -----------------------------------------------------------------------------------
  Create table #TEMP_quoteitemProductListDollarThreshold    
                                  (SEQ                          int not null identity(1,1),
                                   quoteid                      varchar(50),
                                   groupid                      bigint,
                                   productcode                  varchar(50),                                                                      
                                   frequencycode                varchar(6),                                                                                                       
                                   measurecode                  varchar(6),    
                                   ilffrequencycode             varchar(6),
                                   ilfmeasurecode               varchar(6),                    
                                   priceversion                 numeric(18,0) null,
                                  
                                   ProductDisplayName           varchar(500),
                                   ProductName                  varchar(500),
                                   
                                   ILFDollarMinimum             INT not null default 0,
                                   ILFDollarMinimumEnabledFlag  int not null   default 0,
                                   ILFDollarMaximum             INT not null default 0,
                                   ILFDollarMaximumEnabledFlag  int not null   default 0,
 
                                   ACSDollarMinimum             INT not null default 0,
                                   ACSDollarMinimumEnabledFlag  int not null   default 0,
                                   ACSDollarMaximum             INT not null default 0,
                                   ACSDollarMaximumEnabledFlag  int not null   default 0,
                                   
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
    insert into #TEMP_quoteitemProductListDollarThreshold(quoteid,groupid,productcode,frequencycode,measurecode,ilffrequencycode,ilfmeasurecode,
                                priceversion
                                )
    select A.quoteid,A.groupid,A.productcode,A.frequencycode,A.measurecode,ilffrequencycode,ilfmeasurecode,         
           A.priceversion
     from (select coalesce(ltrim(rtrim(quoteid)),'0')                   as quoteid,
                  coalesce(ltrim(rtrim(groupid)),0)                     as groupid,
                  ltrim(rtrim(productcode))                             as productcode,
                  ltrim(rtrim(frequencycode))                           as frequencycode,
                  ltrim(rtrim(measurecode))                             as measurecode,
                  ltrim(rtrim(ilffrequencycode))                        as ilffrequencycode,
                  ltrim(rtrim(ilfmeasurecode))                          as ilfmeasurecode,                                        
                  coalesce(priceversion,0)                              as priceversion
          from OPENXML (@idoc,'//familyproducts/row[@isselected = "1"]',1) 
          with (quoteid                 varchar(50),
                groupid                 bigint,
                productcode             varchar(50),
                frequencycode           varchar(6),
                measurecode             varchar(6),
                ilffrequencycode        varchar(6),
                ilfmeasurecode          varchar(6),
                priceversion            numeric(18,0)                        
                )
          ) A
  end TRY
  begin CATCH
    select @LVC_ErrorCodeSection = '//products/row uspQUOTES_ProductListDollarThreshold XML Read Section'
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
  set    D.ProductDisplayName = P.Displayname,
         D.ProductName        = P.Name
  from   #TEMP_quoteitemProductListDollarThreshold D      with (nolock)
  inner join
         Products.dbo.Product P with (nolock)
  on     P.Code         = D.ProductCode 
  and    P.DisabledFlag = 0
  ------------------------------------------------------------------
  --PROD ILF Dollar min and Max
  Update D
  set    D.ILFDollarMinimum            = C.DollarMinimum,
         D.ILFDollarMinimumEnabledFlag = C.DollarMinimumEnabledFlag,
         D.ILFDollarMaximum            = C.DollarMaximum,
         D.ILFDollarMaximumEnabledFlag = C.DollarMaximumEnabledFlag
  from   #TEMP_quoteitemProductListDollarThreshold D     with (nolock)
  inner join
         Products.dbo.Charge C with (nolock)
  on     C.ProductCode  = D.ProductCode
  and    C.DisabledFlag = 0
  and    C.MeasureCode  = D.ilfmeasurecode
  and    C.FrequencyCode= D.ilffrequencycode
  and    C.Chargetypecode='ILF'
  ------------------------------------------------------------------
  --PROD ACS Dollar min and Max
  Update D
  set    D.ACSDollarMinimum            = C.DollarMinimum,
         D.ACSDollarMinimumEnabledFlag = C.DollarMinimumEnabledFlag,
         D.ACSDollarMaximum            = C.DollarMaximum,
         D.ACSDollarMaximumEnabledFlag = C.DollarMaximumEnabledFlag
  from   #TEMP_quoteitemProductListDollarThreshold D     with (nolock)
  inner join
         Products.dbo.Charge C with (nolock)
  on     C.ProductCode  = D.ProductCode
  and    C.DisabledFlag = 0
  and    C.MeasureCode  = D.measurecode
  and    C.FrequencyCode= D.frequencycode
  and    C.Chargetypecode='ACS'
  ------------------------------------------------------------------
  --Final Select 
  select ProductDisplayName,ProductName,productcode,
         ILFDollarMinimum,ILFDollarMinimumEnabledFlag,
         ILFDollarMaximum,ILFDollarMaximumEnabledFlag,
         ACSDollarMinimum,ACSDollarMinimumEnabledFlag,
         ACSDollarMaximum,ACSDollarMaximumEnabledFlag
  from   #TEMP_quoteitemProductListDollarThreshold with (nolock)
  where  ((ILFDollarMinimumEnabledFlag <> 0) OR
          (ILFDollarMaximumEnabledFlag <> 0) OR
          (ACSDollarMinimumEnabledFlag <> 0) OR
          (ACSDollarMaximumEnabledFlag <> 0) 
         ) 
  ------------------------------------------------------------------
  --Final clean up
  if @idoc is not null
  begin
    EXEC sp_xml_removedocument @idoc
    set @idoc = NULL
  end 
  drop table #TEMP_quoteitemProductListDollarThreshold
  --------------------------------------------------------------------
END
GO
