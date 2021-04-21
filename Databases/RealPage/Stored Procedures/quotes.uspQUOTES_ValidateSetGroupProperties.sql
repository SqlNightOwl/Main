SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec [QUOTES].[dbo].[uspQUOTES_ValidateSetGroupProperties] @IPT_SetGroupPropertiesXML = 
'<groupproperties>
<row companyid="C0000027521" quoteid="Q0000002266" groupid="8228" propertyid="P0000025383" 
 isselected="1"/>
</groupproperties>'
-------------------------------------------
exec [QUOTES].[dbo].[uspQUOTES_ValidateSetGroupProperties] @IPT_SetGroupPropertiesXML = 
'<groupproperties>
<row companyid="C0802000021" quoteid="Q0803000006" groupid="9581" propertyid="P0802000136" 
 isselected="1"/>
</groupproperties>'
---- DNETHUNURI (Added Domin-8 validations) related to workitem# 517, SRS : TFS 1437 
*/
CREATE PROCEDURE [quotes].[uspQUOTES_ValidateSetGroupProperties] (@IPT_SetGroupPropertiesXML  XML = NULL                                                 
                                                              )
AS
BEGIN --: Main BEGIN
  set nocount on; 
  set XACT_ABORT on; -- set XACT_ABORT on will render the transaction uncommittable
                     -- when the constraint violation occurs.
  -----------------------------------------------------------------------------------
  --Declaring Local Variables
  -----------------------------------------------------------------------------------  
  declare @LVC_quoteid                   varchar(50)
  declare @LI_groupid                    int  

  declare @LVC_CodeSection               varchar(500)  
  -----------------------------------------------------------------------------------
  --Declaring Local Table Variable
  -----------------------------------------------------------------------------------
  create table #LT_GroupProperties (SEQ                   int not null identity(1,1) primary key,
                                    companyid             varchar(50),
                                    propertyid            varchar(50),  
                                    quoteid               varchar(50),
                                    groupid               bigint,                                    
                                    isselected            int not null default 0
                                    ) 
  create Table #temp_QuoteItem     (SEQ                   int not null identity(1,1) primary key,
                                    Propertyid            varchar(50),
                                    Quoteidseq            varchar(50),
                                    groupidseq            bigint,
                                    Productcode           varchar(50),
                                    Priceversion          numeric(18,0),
                                    familycode            varchar(10),
                                    QuantityEnabledFlag   int                                    
                                    ) 
      
  create Table #temp_QuoteItemGrouping
                                   (SEQ                   int not null identity(1,1) primary key,
                                    Propertyid            varchar(50),
                                    Quoteidseq            varchar(50),                                    
                                    Productcode           varchar(50),
                                    Priceversion          numeric(18,0),
                                    QuantityEnabledFlag   int                                    
                                    )  

  create table #LT_ErrorTable   (SEQ                   int not null identity(1,1) primary key,
                                 propertyid            varchar(50),  
                                 Propertyname          varchar(255),
                                 groupname             varchar(255),
                                 productname           varchar(255) 
                                )  

  -----------------------------------------------------------------------------------
  declare @idoc  int
  -----------------------------------------------------------------------------------
  --Create Handle to access newly created internal representation of the XML document
  -----------------------------------------------------------------------------------
  EXEC sp_xml_preparedocument @idoc OUTPUT,@IPT_SetGroupPropertiesXML
  -----------------------------------------------------------------------------------
  --OPENXML to read XML and Insert Data into @LT_bundlessummary
  --Records of this with bundledeleteflag=1 is used only to delete group
  -----------------------------------------------------------------------------------
  begin TRY
    insert into #LT_GroupProperties(companyid,propertyid,quoteid,groupid,isselected)
    select distinct A.companyid,A.propertyid,A.quoteid,A.groupid,A.isselected
    from (select ltrim(rtrim(companyid))           as companyid,
                 ltrim(rtrim(propertyid))          as propertyid, 
                 ltrim(rtrim(quoteid))             as quoteid,
                 ltrim(rtrim(groupid))             as groupid,                 
                 coalesce(isselected,0)            as isselected
          from OPENXML (@idoc,'//groupproperties/row[@isselected = "1"]',1) 
          with (companyid             varchar(50),
                propertyid            varchar(50),
                quoteid               varchar(50),
                groupid               bigint,               
                isselected            int)                
          ) A        
  end TRY
  begin CATCH
    SELECT @LVC_CodeSection = '//groupproperties/row XML ReadSection'
    Exec CUSTOMERS.dbo.uspCUSTOMERS_RaiseError @IPVC_CodeSection = @LVC_CodeSection
    if @idoc is not null
    begin
      EXEC sp_xml_removedocument @idoc
      set @idoc = NULL
    end 
    return
  end CATCH;
  ------------------------------------------------------------------
  ---select * from @LT_GroupProperties --:Validation
  if (select count(*) from #LT_GroupProperties with (nolock) where isselected = 1) > 0
  begin
    select Top 1  @LVC_quoteid = quoteid,
                  @LI_groupid  = groupid
    from #LT_GroupProperties with (nolock)  
    --------------------------------------------------------------------------
    Insert into #temp_QuoteItem(propertyid,Quoteidseq,groupidseq,Productcode,Priceversion,familycode,QuantityEnabledFlag)
    select LTG.propertyid,QI.Quoteidseq,QI.groupidseq,QI.ProductCode,QI.Priceversion,QI.familycode,C.QuantityEnabledFlag
    from   #LT_GroupProperties LTG with (nolock)
    inner join
           QUOTES.dbo.QuoteItem QI with (nolock)
    on     LTG.quoteid     = QI.QuoteIDSeq 
    and    LTG.groupid     = QI.GroupIDSeq
    and    LTG.quoteid     = @LVC_quoteid
    and    QI.QuoteIDSeq   = @LVC_quoteid
    and    LTG.groupid     = @LI_groupid
    and    QI.GroupIDSeq   = @LI_groupid
    and    LTG.isselected  = 1    
    inner join
           Products.dbo.Charge C with (nolock)
    on     QI.Productcode   = C.ProductCode
    and    QI.PriceVersion  = C.PriceVersion
    and    QI.Chargetypecode= C.ChargetypeCode
    and    QI.Measurecode   = C.Measurecode
    and    QI.Frequencycode = C.Frequencycode
    and    QI.Chargetypecode = 'ACS'    
    group by LTG.propertyid,QI.Quoteidseq,QI.groupidseq,QI.ProductCode,QI.Priceversion,QI.familycode,QI.Chargetypecode,
             QI.Measurecode,QI.FrequencyCode,C.QuantityEnabledFlag
    --------------------------------------------------------------------------
    Insert into #temp_QuoteItem(propertyid,Quoteidseq,groupidseq,Productcode,Priceversion,familycode,QuantityEnabledFlag)
    select LTG.propertyid,QI.Quoteidseq,QI.groupidseq,QI.ProductCode,QI.Priceversion,QI.familycode,C.QuantityEnabledFlag
    from   #LT_GroupProperties LTG with (nolock)
    inner join
           QUOTES.dbo.QuoteItem QI with (nolock)
    on     LTG.quoteid     = QI.QuoteIDSeq 
    and    LTG.groupid     = QI.GroupIDSeq
    and    LTG.quoteid     = @LVC_quoteid
    and    QI.QuoteIDSeq   = @LVC_quoteid
    and    LTG.groupid     = @LI_groupid
    and    QI.GroupIDSeq   = @LI_groupid 
    and    LTG.isselected  = 1
    inner join
           Products.dbo.Charge C with (nolock)
    on     QI.Productcode   = C.ProductCode
    and    QI.PriceVersion  = C.PriceVersion
    and    QI.Chargetypecode= C.ChargetypeCode
    and    QI.Measurecode   = C.Measurecode
    and    QI.Frequencycode = C.Frequencycode
    and    QI.Chargetypecode = 'ILF'
    and    not Exists (select top 1 1 from products.dbo.charge Ch with (nolock)
                       where  ch.productcode    = C.productcode
                       and    ch.priceversion   = C.priceversion
                       and    ch.chargetypecode = 'ACS')
    group by LTG.propertyid,QI.Quoteidseq,QI.groupidseq,QI.ProductCode,QI.Priceversion,QI.familycode,QI.Chargetypecode,
             QI.Measurecode,QI.FrequencyCode,C.QuantityEnabledFlag
    --------------------------------------------------------------------------
    Insert into #temp_QuoteItem(propertyid,Quoteidseq,groupidseq,Productcode,Priceversion,familycode,QuantityEnabledFlag)
    select GP.propertyidseq,QI.Quoteidseq,QI.groupidseq,QI.ProductCode,QI.Priceversion,QI.familycode,C.QuantityEnabledFlag
    from   QUOTES.dbo.GroupProperties GP
    inner join
           QUOTES.dbo.QuoteItem QI with (nolock)
    on     GP.quoteidseq = QI.QuoteIDSeq 
    and    GP.groupidseq = QI.GroupIDSeq
    and    GP.quoteidseq = @LVC_quoteid
    and    QI.quoteidseq = @LVC_quoteid
    and    GP.groupidseq <> @LI_groupid
    and    QI.GroupIDSeq <> @LI_groupid    
    inner join
           Products.dbo.Charge C with (nolock)
    on     QI.Productcode   = C.ProductCode
    and    QI.PriceVersion  = C.PriceVersion
    and    QI.Chargetypecode= C.ChargetypeCode
    and    QI.Measurecode   = C.Measurecode
    and    QI.Frequencycode = C.Frequencycode
    and    QI.Chargetypecode = 'ACS'    
    group by GP.propertyidseq,QI.Quoteidseq,QI.ProductCode,QI.groupidseq,QI.Priceversion,QI.familycode,QI.Chargetypecode,
             QI.Measurecode,QI.FrequencyCode,C.QuantityEnabledFlag
    --------------------------------------------------------------------------
    Insert into #temp_QuoteItem(propertyid,Quoteidseq,groupidseq,Productcode,Priceversion,familycode,QuantityEnabledFlag)
    select GP.propertyidseq,QI.Quoteidseq,QI.groupidseq,QI.ProductCode,QI.Priceversion,QI.familycode,C.QuantityEnabledFlag
    from   QUOTES.dbo.GroupProperties GP
    inner join
           QUOTES.dbo.QuoteItem QI with (nolock)
    on     GP.quoteidseq = QI.QuoteIDSeq 
    and    GP.groupidseq = QI.GroupIDSeq
    and    GP.quoteidseq = @LVC_quoteid
    and    QI.quoteidseq = @LVC_quoteid
    and    GP.groupidseq <> @LI_groupid
    and    QI.GroupIDSeq <> @LI_groupid
    inner join
           Products.dbo.Charge C with (nolock)
    on     QI.Productcode   = C.ProductCode
    and    QI.PriceVersion  = C.PriceVersion
    and    QI.Chargetypecode= C.ChargetypeCode
    and    QI.Measurecode   = C.Measurecode
    and    QI.Frequencycode = C.Frequencycode
    and    QI.Chargetypecode = 'ILF'
    and    not Exists (select top 1 1 from products.dbo.charge Ch with (nolock)
                       where  ch.productcode    = C.productcode
                       and    ch.priceversion   = C.priceversion
                       and    ch.chargetypecode = 'ACS')
    group by GP.propertyidseq,QI.Quoteidseq,QI.ProductCode,QI.groupidseq,QI.Priceversion,QI.familycode,QI.Chargetypecode,
             QI.Measurecode,QI.FrequencyCode,C.QuantityEnabledFlag
    -------------------------------------------------------------------------------   
    Insert into #temp_QuoteItemGrouping(propertyid,Quoteidseq,Productcode,Priceversion,QuantityEnabledFlag)
    select propertyid,Quoteidseq,Productcode,Priceversion,QuantityEnabledFlag
    from   #temp_QuoteItem with (nolock)
    group by propertyid,Quoteidseq,Productcode,Priceversion,QuantityEnabledFlag
    having count(*) > 1 
    --------------------------------------------------------------------------------
    Insert into #LT_ErrorTable(propertyid,Propertyname,groupname,productname)
    select 
           PRP.IDSeq        as propertyid,
           PRP.Name         as Propertyname,
           ''               as groupname,
           P.DisplayName    as productname
    ---------------------------------------------------
    from  #temp_QuoteItemGrouping TQIG    with (nolock)   
    Inner join
           Products.dbo.Product P         with (nolock)
    on     TQIG.ProductCode = P.Code
    and    TQIG.PriceVersion= P.PriceVersion
    and    TQIG.Quoteidseq  = @LVC_quoteid   
    --------------------------------------------------
    inner join
           Customers.dbo.Property PRP     with (nolock)
    on     TQIG.propertyid = PRP.IDSeq
    ---------------------------------------------------   
    group by PRP.IDSeq,PRP.Name,P.DisplayName
    order by PRP.Name asc,P.DisplayName asc; 


    Insert into #LT_ErrorTable(propertyid,Propertyname,groupname,productname)
    select 
           PRP.IDSeq        as propertyid,
           PRP.Name         as Propertyname,
           ''               as groupname,
           'GSA Product : ' + P.DisplayName + ' cannot be sold to Non GSA Property'       
                            as productname
    ---------------------------------------------------
    from  #temp_QuoteItem TQIG    with (nolock)   
    Inner join
           Products.dbo.Product P         with (nolock)
    on     TQIG.ProductCode = P.Code
    and    TQIG.PriceVersion= P.PriceVersion
    and    TQIG.FamilyCode  = 'GSA'
    and    TQIG.Quoteidseq  = @LVC_quoteid   
    --------------------------------------------------
    inner join
           Customers.dbo.Property PRP     with (nolock)
    on     TQIG.propertyid = PRP.IDSeq
    and    PRP.GSAEntityFlag <> 1
    ---------------------------------------------------   
    group by PRP.IDSeq,PRP.Name,P.DisplayName
    order by PRP.Name asc,P.DisplayName asc;    
  end
  ----------------------------------------------------------------------------------- 
  if ((select Count(*) from #LT_ErrorTable with (nolock) ) = 0)
  begin    
    Insert into #LT_ErrorTable(propertyid,Propertyname,groupname,productname)
    select  
           PRP.IDSeq        as propertyid,
           PRP.Name         as Propertyname,
           ''               as groupname,
           P.DisplayName    as productname
     ---------------------------------------------------
    from  #temp_QuoteItem QI              with (nolock)
    Inner join
           Products.dbo.Product P         with (nolock)
    on     QI.ProductCode = P.Code
    and    QI.PriceVersion= P.PriceVersion
    and    QI.Quoteidseq  = @LVC_quoteid     
    --------------------------------------------------
    inner join
           Customers.dbo.Property PRP     with (nolock)
    on     QI.propertyid = PRP.IDSeq
    --------------------------------------------------- 
    and   Exists (select top 1 1
                  from   #temp_QuoteItem                  X   with (nolock)
    		  Inner join
		         Products.dbo.ProductInvalidCombo PIC with (nolock)
                  on     PIC.FirstProductCode           = QI.ProductCode                  
		  and    X.ProductCode                  = PIC.SecondProductCode		  
                  and    X.GroupIdSeq                   = @LI_groupid
                  and    QI.GroupIdSeq                  <> @LI_groupid
                  and    QI.propertyid                  = X.propertyid
                 )    
    ---------------------------------------------------   
    group by PRP.IDSeq,PRP.Name,P.DisplayName
    order by PRP.Name asc,P.DisplayName asc;
  end
  ----------------------------------------------------------------------------------- 
  --Validation for FamilyInvalidCombo 
  if ((select Count(*) from #LT_ErrorTable with (nolock)) = 0)
  begin    
    Insert into #LT_ErrorTable(propertyid,Propertyname,groupname,productname)    
    select  
           ''               as propertyid,
           ''               as Propertyname,
           ''               as groupname,
           F.Name + ' family is incompatible with ' + F1.Name + ' family.'
                            as productname
     ---------------------------------------------------
    from   Products.dbo.FamilyInvalidCombo FIC with (nolock)
    inner join
           Products.dbo.Family             F   with (nolock)
    on     FIC.FirstFamilyCode = F.Code
    inner join
           Products.dbo.Family             F1   with (nolock)
    on     FIC.SecondFamilyCode = F1.Code
    inner join
           #temp_QuoteItem QI with (nolock)
    on     FIC.FirstFamilyCode = QI.FamilyCode
    and    QI.Quoteidseq     = @LVC_quoteid
    inner join
           #temp_QuoteItem LQI with (nolock)
    on     FIC.SecondFamilyCode = LQI.FamilyCode
    and    LQI.Quoteidseq      = @LVC_quoteid 
    group by F.Name,F1.Name
    ------
    UNION
    ------
    select  
           ''               as propertyid,
           ''               as Propertyname,
           ''               as groupname,
           F.Name + ' family is incompatible with ' + F1.Name + ' family.'
                            as productname
     ---------------------------------------------------
    from   Products.dbo.FamilyInvalidCombo FIC with (nolock)
    inner join
           Products.dbo.Family             F   with (nolock)
    on     FIC.FirstFamilyCode = F.Code
    inner join
           Products.dbo.Family             F1   with (nolock)
    on     FIC.SecondFamilyCode = F1.Code
    inner join
           #temp_QuoteItem QI with (nolock)
    on     FIC.SecondFamilyCode  = QI.FamilyCode
    and    QI.Quoteidseq         = @LVC_quoteid
    inner join
           #temp_QuoteItem LQI with (nolock)
    on     FIC.FirstFamilyCode = LQI.FamilyCode
    and    LQI.Quoteidseq      = @LVC_quoteid
    group by F.Name,F1.Name
    order by productname asc
  end
  -------------------------------------------------------------------------------
  ---Domin-8 validations------- TFS 1437 
  -------------------------------------------------------------------------------   
  if ((select Count(*) from #LT_ErrorTable with (nolock) ) = 0)  
  begin 
  Insert into #LT_ErrorTable(propertyid,Propertyname,groupname,productname)  
    select    
           PRP.IDSeq        as propertyid,  
           PRP.Name         as Propertyname,  
           ''               as groupname,  
           'Domin-8 USA family is incompatible with non USA property(s). Please select United States property(s) only.'   as productname 
      
    from   #temp_QuoteItem QI        with (nolock)  
    inner join  
           Products.dbo.Product P    with (nolock)  
    on     QI.ProductCode = P.Code  
    and    QI.PriceVersion= P.PriceVersion  
    and    QI.FamilyCode  = 'DMN'  
    and    QI.Quoteidseq  = @LVC_quoteid
    and    QI.GroupIDSeq  = @LI_groupid  
    inner join
          #LT_GroupProperties GP with (nolock)
    on    QI.propertyid = GP.propertyid
    and   GP.isselected = 1
    inner join
          Customers.dbo.Property PRP with (nolock)
    on    QI.propertyid = PRP.IDSeq
    and   GP.propertyid = PRP.IDSeq
    and   GP.companyid  = PRP.PMCIDSeq
    inner join  Customers.dbo.[Address] A     with (nolock)  
    on    GP.companyid  = A.CompanyIDSeq
    and   PRP.PMCIDSeq  = A.CompanyIDSeq
    and   GP.propertyid = A.propertyidseq  
    and   PRP.IDSeq     = A.propertyidseq  
    and   A.AddressTypeCode = 'PRO' 
    and   A.countrycode    <> 'USA'  
    group by PRP.IDSeq,PRP.Name  
    order by PRP.Name asc    
  end
  
  
   if ((select Count(*) from #LT_ErrorTable with (nolock) ) = 0)  
  begin 
  Insert into #LT_ErrorTable(propertyid,Propertyname,groupname,productname)  
    select    
           PRP.IDSeq        as propertyid,  
           PRP.Name         as Propertyname,  
           ''               as groupname,  
           'Domin-8 CANADA family is incompatible with non CANADA property(s). Please select CANADA property(s) only.'   as productname 
      
    from  #temp_QuoteItem QI              with (nolock)  
    inner join  Products.dbo.Product P    with (nolock)  
    on     QI.ProductCode = P.Code  
    and    QI.PriceVersion= P.PriceVersion  
    and    QI.FamilyCode  = 'DCN'  
    and    QI.Quoteidseq  = @LVC_quoteid
    and    QI.GroupIDSeq  = @LI_groupid  
    inner join
          #LT_GroupProperties GP with (nolock)
    on    QI.propertyid = GP.propertyid
    and   GP.isselected = 1
    inner join
          Customers.dbo.Property PRP with (nolock)
    on    QI.propertyid = PRP.IDSeq
    and   GP.propertyid = PRP.IDSeq
    and   GP.companyid  = PRP.PMCIDSeq
    inner join  Customers.dbo.[Address] A     with (nolock)  
    on    GP.companyid  = A.CompanyIDSeq
    and   PRP.PMCIDSeq  = A.CompanyIDSeq
    and   GP.propertyid = A.propertyidseq  
    and   PRP.IDSeq     = A.propertyidseq  
    and   A.AddressTypeCode = 'PRO' 
    and   A.countrycode    <> 'CAN'  
    group by PRP.IDSeq,PRP.Name  
    order by PRP.Name asc     
  end
  -------------------------------------------------------------------------------  
  ---Final Select
  select distinct propertyid,Propertyname,groupname as groupname,productname
  from #LT_ErrorTable with (nolock)
  ----------------------------------------------------------------------------------- 
  if @idoc is not null
  begin
    EXEC sp_xml_removedocument @idoc
    set @idoc = NULL
  end 
  ------------------------------------------------------------------------------------
  ---Final Cleanup
  drop table #LT_GroupProperties
  drop table #temp_QuoteItem
  drop table #temp_QuoteItemGrouping
  drop table #LT_ErrorTable
  ------------------------------------------------------------------------------------
END
GO
