SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec [QUOTES].[dbo].[uspQUOTES_ValidateSetGroup] @IPT_SetGroupXML = 
'<products>
<familyproducts>
<row quoteid="Q0000002266" groupid="8228" productcode="DMD-OSD-OLR-CNV-RCNV" priceversion="100" isselected="1" />
<row quoteid="Q0000002266" groupid="8228" productcode="DMD-OSD-FAC-FAC-FFAC" priceversion="100" isselected="1" />
<row quoteid="Q0000002266" groupid="8228" productcode="DMD-PSR-ICM-ICM-MICV" priceversion="100" isselected="1" />
</familyproducts>
</products>'
----------------------------------------------------------------------
exec [QUOTES].[dbo].[uspQUOTES_ValidateSetGroup] @IPT_SetGroupXML = 
'<products>
<familyproducts>
<row quoteid="Q0000002266" groupid="8228" productcode="DMD-PSR-ICM-ICM-MICV" priceversion="100" isselected="1" />
</familyproducts>
</products>'

---------- TFS 1437 
*/
CREATE PROCEDURE [quotes].[uspQUOTES_ValidateSetGroup] (@IPT_SetGroupXML  XML = NULL                                                
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
  declare @LVC_Companyid                 varchar(50)
  declare @LVC_Grouptype                 varchar(20)
  declare @LVC_CodeSection               varchar(500)  
  -----------------------------------------------------------------------------------
  --Declaring Local Table Variable
  -----------------------------------------------------------------------------------
  create table #LT_groupmaster    (SEQ                      int not null identity(1,1),
                                   companyid	 	    varchar(50),                                   
                                   quoteid                  varchar(50),
                                   groupid                  bigint,
                                   grouptype                varchar(10)
                                  )

  create table #LT_quoteitem      (SEQ                      int not null identity(1,1),
                                   quoteid                  varchar(50),
                                   groupid                  bigint,
                                   productcode              varchar(50),                                                
                                   priceversion             numeric(18,0) null,   
                                   familycode               varchar(10),                                                                                                                                       
                                   measurecode              varchar(6),    
                                   frequencycode            varchar(6),
                                   ilfmeasurecode           varchar(6),
                                   ilffrequencycode         varchar(6),
                                   publicationyear          varchar(50),
                                   publicationquarter       varchar(50), 
                                   isselected               int not null default 0                                                                     
                                  )   

  create table #LT_ErrorTable   (SEQ                   int not null identity(1,1),                                 
                                 propertyid            varchar(50),  
                                 Propertyname          varchar(255),
                                 groupname             varchar(255),
                                 productname           varchar(255) 
                                )  

  create Table #temp_QuoteItem     (Companyid             varchar(50),
                                    Propertyid            varchar(50),
                                    Quoteidseq            varchar(50),
                                    groupidseq            bigint,
                                    familycode            varchar(10),
                                    Productcode           varchar(50),
                                    Priceversion          numeric(18,0),
                                    QuantityEnabledFlag   int,
                                    publicationyear       varchar(50),
                                    publicationquarter    varchar(50)
                                    ) 
      
  create Table #temp_QuoteItemGrouping
                                   (Companyid             varchar(50),
                                    Propertyid            varchar(50),
                                    Quoteidseq            varchar(50),                                    
                                    Productcode           varchar(50),
                                    Priceversion          numeric(18,0),
                                    QuantityEnabledFlag   int                                    
                                    )  

  -----------------------------------------------------------------------------------
  declare @idoc  int
  -----------------------------------------------------------------------------------
  --Create Handle to access newly created internal representation of the XML document
  -----------------------------------------------------------------------------------
  EXEC sp_xml_preparedocument @idoc OUTPUT,@IPT_SetGroupXML
  -----------------------------------------------------------------------------------
  --OPENXML to read XML and Insert Data into @LT_bundlessummary
  --Records of this with bundledeleteflag=1 is used only to delete group
  -----------------------------------------------------------------------------------
  begin TRY
    insert into #LT_groupmaster(companyid,quoteid,groupid,grouptype)
    select      A.companyid,A.quoteid,A.groupid,A.grouptype
    from (select coalesce(ltrim(rtrim(companyid)),'0')           as companyid,
                 coalesce(ltrim(rtrim(quoteid)),'0')             as quoteid,
                 coalesce(ltrim(rtrim(groupid)),0)               as groupid,
                 coalesce(ltrim(rtrim(grouptype)),'')            as grouptype
          from OPENXML (@idoc,'//groupmaster/row',1) 
          with (companyid                varchar(50),
                quoteid                  varchar(50),
                groupid                  bigint,
                grouptype                varchar(20)
                )
          ) A
   
    select Top 1  @LVC_Companyid = companyid,
                  @LVC_quoteid   = quoteid,
                  @LI_groupid    = groupid,
                  @LVC_GroupType = grouptype 
    from #LT_groupmaster  with (nolock)
    -----------------------------------------------------------------------------
    insert into #LT_quoteitem(quoteid,groupid,productcode,priceversion,familycode,
                              frequencycode,measurecode,ilffrequencycode,ilfmeasurecode,publicationyear,publicationquarter,isselected)
    select @LVC_quoteid,@LI_groupid,A.productcode,A.priceversion,A.familycode,
           A.frequencycode,A.measurecode,A.ilffrequencycode,A.ilfmeasurecode,A.publicationyear,A.publicationquarter,A.isselected
    from (select  ltrim(rtrim(productcode))                            as productcode,                  
                  coalesce(priceversion,0)                             as priceversion,
                  ltrim(rtrim(familycode))                             as familycode,                             
                  ltrim(rtrim(frequencycode))                          as frequencycode,
                  ltrim(rtrim(measurecode))                            as measurecode,
                  ltrim(rtrim(ilffrequencycode))                       as ilffrequencycode,
                  ltrim(rtrim(ilfmeasurecode))                         as ilfmeasurecode,
                  ltrim(rtrim(publicationyear))                        as publicationyear,
                  ltrim(rtrim(publicationquarter))                     as publicationquarter,  
                  coalesce(isselected,0)                               as isselected          
          from OPENXML (@idoc,'//familyproducts/row[@isselected = "1"]',1) 
          with (productcode             varchar(50),                
                priceversion            numeric(18,0),
                familycode              varchar(10),
                frequencycode           varchar(6),
                measurecode             varchar(6),
                ilffrequencycode        varchar(6),
                ilfmeasurecode          varchar(6),
                publicationyear         varchar(50),
                publicationquarter      varchar(50),
                isselected              int          
                )
          ) A
  end TRY
  begin CATCH
    SELECT @LVC_CodeSection = '//groupmaster/row and //products/familyproducts/row XML QuoteItem Read Section'
    Exec CUSTOMERS.dbo.uspCUSTOMERS_RaiseError @IPVC_CodeSection = @LVC_CodeSection    
    if @idoc is not null
    begin
      EXEC sp_xml_removedocument @idoc
      set @idoc = NULL
    end  
    return
  end CATCH;
  ------------------------------------------------------------------
  ---select * from #LT_quoteitem --:Validation
  if (select count(*) from #LT_quoteitem with (nolock) where isselected = 1) > 0
  begin
    --------------------------------------------------------------------------
    if @LVC_Grouptype <> 'PMC'
    begin
      Insert into #temp_QuoteItem(Companyid,propertyid,Quoteidseq,groupidseq,familycode,Productcode,Priceversion,publicationyear,publicationquarter,QuantityEnabledFlag)
      select @LVC_Companyid as companyid,
             GP.propertyidseq,QI.quoteid,QI.groupid,Max(QI.familycode) as familycode,
             QI.ProductCode,QI.Priceversion,coalesce(QI.publicationyear,''),coalesce(QI.publicationquarter,''),C.QuantityEnabledFlag
      from   QUOTES.dbo.GroupProperties GP with (nolock)
      inner join
             #LT_quoteitem QI with (nolock)
      on     GP.QuoteIDSeq  = QI.QuoteID
      and    GP.GroupIDSeq  = QI.GroupID
      and    GP.quoteidseq  = @LVC_quoteid    
      and    QI.QuoteID     = @LVC_quoteid
      and    GP.groupidseq  = @LI_groupid
      and    QI.GroupID     = @LI_groupid 
      and    QI.isselected  = 1   
      inner join
             Products.dbo.Charge C with (nolock)
      on     QI.Productcode   = C.ProductCode
      and    QI.PriceVersion  = C.PriceVersion
      and    C.ChargetypeCode = 'ACS'
      and    QI.Measurecode   = C.Measurecode
      and    QI.Frequencycode = C.Frequencycode          
      group by GP.propertyidseq,QI.Quoteid,QI.groupid,QI.ProductCode,QI.Priceversion,
               QI.Measurecode,QI.FrequencyCode,coalesce(QI.publicationyear,''),coalesce(QI.publicationquarter,''),C.QuantityEnabledFlag
      --------------------------------------------------------------------------
      Insert into #temp_QuoteItem(companyid,propertyid,Quoteidseq,groupidseq,familycode,Productcode,Priceversion,publicationyear,publicationquarter,QuantityEnabledFlag)
      select @LVC_Companyid as companyid,
             GP.propertyidseq,QI.Quoteid,QI.groupid,Max(QI.familycode) as familycode,
             QI.ProductCode,QI.Priceversion,coalesce(QI.publicationyear,''),coalesce(QI.publicationquarter,''),C.QuantityEnabledFlag
      from   QUOTES.dbo.GroupProperties GP with (nolock)
      inner join
             #LT_quoteitem QI with (nolock)
      on     GP.QuoteIDSeq  = QI.Quoteid
      and    GP.GroupIDSeq  = QI.groupid
      and    GP.quoteidseq  = @LVC_quoteid    
      and    QI.Quoteid     = @LVC_quoteid
      and    GP.groupidseq  = @LI_groupid
      and    QI.groupid     = @LI_groupid
      and    QI.isselected  = 1    
      inner join
             Products.dbo.Charge C with (nolock)
      on     QI.Productcode   = C.ProductCode
      and    QI.PriceVersion  = C.PriceVersion
      and    C.ChargetypeCode = 'ILF'
      and    QI.ilfmeasurecode   = C.MeasureCode
      and    QI.ilffrequencycode = C.FrequencyCode    
      and    not Exists (select top 1 1 from products.dbo.charge Ch with (nolock)
                         where  ch.productcode    = C.productcode
                         and    ch.priceversion   = C.priceversion
                         and    ch.chargetypecode = 'ACS')
      group by GP.propertyidseq,QI.Quoteid,QI.groupid,QI.ProductCode,QI.Priceversion,
               QI.ilfmeasurecode,QI.ilffrequencycode,coalesce(QI.publicationyear,''),coalesce(QI.publicationquarter,''),C.QuantityEnabledFlag
      --------------------------------------------------------------------------
      Insert into #temp_QuoteItem(companyid,propertyid,Quoteidseq,familycode,groupidseq,Productcode,Priceversion,publicationyear,publicationquarter,QuantityEnabledFlag)
      select @LVC_Companyid as companyid,
             GP.propertyidseq,QI.Quoteidseq,QI.groupidseq,Max(QI.familycode) as familycode,
             QI.ProductCode,QI.Priceversion,coalesce(QI.publicationyear,''),coalesce(QI.publicationquarter,''),C.QuantityEnabledFlag
      from   QUOTES.dbo.GroupProperties GP with (nolock)
      inner join
             QUOTES.dbo.QuoteItem QI with (nolock)
      on     GP.QuoteIDSeq = QI.QuoteIDSeq 
      and    GP.GroupIDSeq = QI.GroupIDSeq
      and    GP.QuoteIDSeq = @LVC_quoteid
      and    GP.GroupIDSeq <> @LI_groupid
      and    QI.GroupIDSeq <> @LI_groupid
      inner join
             Products.dbo.Charge C with (nolock)
      on     QI.Productcode   = C.ProductCode
      and    QI.PriceVersion  = C.PriceVersion
      and    QI.Chargetypecode= C.ChargetypeCode
      and    QI.Measurecode   = C.Measurecode
      and    QI.Frequencycode = C.Frequencycode
      and    QI.Chargetypecode = 'ACS'      
      group by GP.propertyidseq,QI.Quoteidseq,QI.groupidseq,QI.ProductCode,QI.Priceversion,QI.Chargetypecode,
               QI.Measurecode,QI.FrequencyCode,coalesce(QI.publicationyear,''),coalesce(QI.publicationquarter,''),C.QuantityEnabledFlag 
      --------------------------------------------------------------------------
      Insert into #temp_QuoteItem(companyid,propertyid,Quoteidseq,groupidseq,familycode,Productcode,Priceversion,publicationyear,publicationquarter,QuantityEnabledFlag)
      select @LVC_Companyid as companyid,
             GP.propertyidseq,QI.Quoteidseq,QI.groupidseq,Max(QI.familycode) as familycode,
             QI.ProductCode,QI.Priceversion,coalesce(QI.publicationyear,''),coalesce(QI.publicationquarter,''),C.QuantityEnabledFlag
      from   QUOTES.dbo.GroupProperties GP with (nolock)
      inner join
             QUOTES.dbo.QuoteItem QI with (nolock)
      on     GP.QuoteIDSeq = QI.QuoteIDSeq 
      and    GP.GroupIDSeq = QI.GroupIDSeq
      and    GP.QuoteIDSeq = @LVC_quoteid
      and    GP.GroupIDSeq <> @LI_groupid
      and    QI.GroupIDSeq <> @LI_groupid
      inner join
             Products.dbo.Charge C with (nolock)
      on     QI.Productcode   = C.ProductCode
      and    QI.PriceVersion  = C.PriceVersion
      and    QI.Chargetypecode= C.ChargetypeCode
      and    QI.Measurecode   = C.Measurecode
      and    QI.Frequencycode = C.Frequencycode
      and    QI.Chargetypecode = 'ILF'
      and    Not Exists (select top 1 1 from products.dbo.charge Ch with (nolock)
                         where  ch.productcode    = C.productcode
                         and    ch.priceversion   = C.priceversion
                         and    ch.chargetypecode = 'ACS')
      group by GP.propertyidseq,QI.Quoteidseq,QI.groupidseq,QI.ProductCode,QI.Priceversion,QI.Chargetypecode,
               QI.Measurecode,QI.FrequencyCode,coalesce(QI.publicationyear,''),coalesce(QI.publicationquarter,''),C.QuantityEnabledFlag 
      ------------------------------------------------------------------------------
      Insert into #temp_QuoteItemGrouping(companyid,propertyid,Quoteidseq,Productcode,Priceversion,QuantityEnabledFlag)
      select companyid,propertyid,Quoteidseq,Productcode,Priceversion,QuantityEnabledFlag
      from   #temp_QuoteItem with (nolock)
      group by companyid,propertyid,Quoteidseq,Productcode,Priceversion,publicationyear,publicationquarter,QuantityEnabledFlag
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
      order by PRP.Name asc,P.DisplayName asc  
    end
    else ----> this @LVC_Grouptype = 'PMC'
    begin
      Insert into #temp_QuoteItem(Companyid,propertyid,Quoteidseq,groupidseq,familycode,Productcode,Priceversion,publicationyear,publicationquarter,QuantityEnabledFlag)
      select @LVC_Companyid as companyid,
             NULL as propertyidseq,QI.quoteid,QI.groupid,Max(QI.familycode) as familycode,
             QI.ProductCode,QI.Priceversion,coalesce(QI.publicationyear,''),coalesce(QI.publicationquarter,''),C.QuantityEnabledFlag
      from   #LT_quoteitem QI with (nolock)      
      inner join
             Products.dbo.Charge C with (nolock)
      on     QI.QuoteID       = @LVC_quoteid      
      and    QI.GroupID       = @LI_groupid
      and    QI.isselected    = 1    
      and    QI.Productcode   = C.ProductCode
      and    QI.PriceVersion  = C.PriceVersion
      and    C.ChargetypeCode = 'ACS'
      and    QI.Measurecode   = C.Measurecode
      and    QI.Frequencycode = C.Frequencycode      
      group by QI.Quoteid,QI.groupid,QI.ProductCode,QI.Priceversion,
               QI.Measurecode,QI.FrequencyCode,coalesce(QI.publicationyear,''),coalesce(QI.publicationquarter,''),C.QuantityEnabledFlag
      --------------------------------------------------------------------------
      Insert into #temp_QuoteItem(companyid,propertyid,Quoteidseq,groupidseq,familycode,Productcode,Priceversion,publicationyear,publicationquarter,QuantityEnabledFlag)
      select @LVC_Companyid as companyid,
             NULL as propertyidseq,QI.Quoteid,QI.groupid,Max(QI.familycode) as familycode,
             QI.ProductCode,QI.Priceversion,coalesce(QI.publicationyear,''),coalesce(QI.publicationquarter,''),C.QuantityEnabledFlag
      from   #LT_quoteitem QI with (nolock)      
      inner join
             Products.dbo.Charge C with (nolock)
      on     QI.QuoteID       = @LVC_quoteid      
      and    QI.GroupID       = @LI_groupid 
      and    QI.isselected    = 1   
      and    QI.Productcode   = C.ProductCode
      and    QI.PriceVersion  = C.PriceVersion
      and    C.ChargetypeCode = 'ILF'
      and    QI.Measurecode   = C.Measurecode
      and    QI.Frequencycode = C.Frequencycode     
      and    not Exists (select top 1 1 from products.dbo.charge Ch with (nolock)
                         where  ch.productcode    = C.productcode
                         and    ch.priceversion   = C.priceversion
                         and    ch.chargetypecode = 'ACS')
      group by QI.Quoteid,QI.groupid,QI.ProductCode,QI.Priceversion,
               QI.ilfmeasurecode,QI.ilffrequencycode,coalesce(QI.publicationyear,''),coalesce(QI.publicationquarter,''),C.QuantityEnabledFlag
      --------------------------------------------------------------------------
      Insert into #temp_QuoteItem(companyid,propertyid,Quoteidseq,groupidseq,familycode,Productcode,Priceversion,publicationyear,publicationquarter,QuantityEnabledFlag)
      select @LVC_Companyid as companyid,
             NULL propertyidseq,QI.Quoteidseq,QI.groupidseq,Max(QI.familycode) as familycode,
             QI.ProductCode,QI.Priceversion,coalesce(QI.publicationyear,''),coalesce(QI.publicationquarter,''),C.QuantityEnabledFlag
      from   QUOTES.dbo.[Group] G with (nolock)
      inner join
             QUOTES.dbo.QuoteItem QI with (nolock)
      on     G.QuoteIDSeq = QI.QuoteIDSeq 
      and    G.IDSeq      = QI.GroupIDSeq
      and    G.QuoteIDSeq = @LVC_quoteid
      and    G.GroupType  = 'PMC'
      and    G.IDSeq       <> @LI_groupid
      and    QI.GroupIDSeq <> @LI_groupid
      inner join
             Products.dbo.Charge C with (nolock)
      on     QI.Productcode   = C.ProductCode
      and    QI.PriceVersion  = C.PriceVersion
      and    QI.Chargetypecode= C.ChargetypeCode
      and    QI.Measurecode   = C.Measurecode
      and    QI.Frequencycode = C.Frequencycode
      and    QI.Chargetypecode = 'ACS'      
      group by QI.Quoteidseq,QI.groupidseq,QI.ProductCode,QI.Priceversion,QI.Chargetypecode,
               QI.Measurecode,QI.FrequencyCode,coalesce(QI.publicationyear,''),coalesce(QI.publicationquarter,''),C.QuantityEnabledFlag 
      --------------------------------------------------------------------------
      Insert into #temp_QuoteItem(companyid,propertyid,Quoteidseq,groupidseq,familycode,Productcode,Priceversion,publicationyear,publicationquarter,QuantityEnabledFlag)
      select @LVC_Companyid as companyid,
             NULL as propertyidseq,QI.Quoteidseq,QI.groupidseq,Max(QI.familycode) as familycode,
             QI.ProductCode,QI.Priceversion,coalesce(QI.publicationyear,''),coalesce(QI.publicationquarter,''),C.QuantityEnabledFlag
      from   QUOTES.dbo.[Group] G with (nolock)
      inner join
             QUOTES.dbo.QuoteItem QI with (nolock)
      on     G.QuoteIDSeq = QI.QuoteIDSeq 
      and    G.IDSeq      = QI.GroupIDSeq
      and    G.QuoteIDSeq = @LVC_quoteid
      and    G.GroupType  = 'PMC'
      and    G.IDSeq       <> @LI_groupid
      and    QI.GroupIDSeq <> @LI_groupid
      inner join
             Products.dbo.Charge C with (nolock)
      on     QI.Productcode   = C.ProductCode
      and    QI.PriceVersion  = C.PriceVersion
      and    QI.Chargetypecode= C.ChargetypeCode
      and    QI.Measurecode   = C.Measurecode
      and    QI.Frequencycode = C.Frequencycode
      and    QI.Chargetypecode = 'ILF'
      and    Not Exists (select top 1 1 from products.dbo.charge Ch with (nolock)
                         where  ch.productcode    = C.productcode
                         and    ch.priceversion   = C.priceversion
                         and    ch.chargetypecode = 'ACS')
      group by QI.Quoteidseq,QI.groupidseq,QI.ProductCode,QI.Priceversion,QI.Chargetypecode,
               QI.Measurecode,QI.FrequencyCode,coalesce(QI.publicationyear,''),coalesce(QI.publicationquarter,''),C.QuantityEnabledFlag 
      ------------------------------------------------------------------------------
      Insert into #temp_QuoteItemGrouping(companyid,propertyid,Quoteidseq,Productcode,Priceversion,QuantityEnabledFlag)
      select companyid,propertyid,Quoteidseq,Productcode,Priceversion,QuantityEnabledFlag
      from   #temp_QuoteItem with (nolock)         
      group by companyid,propertyid,Quoteidseq,Productcode,Priceversion,publicationyear,publicationquarter,QuantityEnabledFlag
      having count(*) > 1 
      --------------------------------------------------------------------------------
      Insert into #LT_ErrorTable(propertyid,Propertyname,groupname,productname)
      select 
             C.IDSeq          as companyid,
             C.Name           as companyname,
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
             Customers.dbo.Company C     with (nolock)
      on     TQIG.companyid = C.IDSeq
      ---------------------------------------------------   
      group by C.IDSeq,C.Name,P.DisplayName
      order by C.Name asc,P.DisplayName asc  


      Insert into #LT_ErrorTable(propertyid,Propertyname,groupname,productname)
      select 
             C.IDSeq          as companyid,
             C.Name           as companyname,
             ''               as groupname,
             'GSA Product : ' + P.DisplayName + ' cannot be sold to Non GSA Company'             
                              as productname
      ---------------------------------------------------
      from  #temp_QuoteItem TQIG            with (nolock)   
      Inner join
             Products.dbo.Product P         with (nolock)
      on     TQIG.ProductCode = P.Code
      and    TQIG.PriceVersion= P.PriceVersion 
      inner join
             Products.dbo.Family             F   with (nolock)
      on     P.FamilyCode     = F.Code
      and    P.FamilyCode     = 'GSA'
      and    TQIG.Quoteidseq  = @LVC_quoteid
      and    TQIG.GroupIDSeq  = @LI_groupid   
      --------------------------------------------------
      inner join
             Customers.dbo.Company C     with (nolock)
      on     TQIG.companyid = C.IDSeq 
      and    C.IDSeq        = @LVC_Companyid
      and    TQIG.companyid = @LVC_Companyid
      and    C.GSAEntityFlag <> 1
      ---------------------------------------------------   
      group by C.IDSeq,C.Name,P.DisplayName
      order by C.Name asc,P.DisplayName asc  
    end
  end
  ----------------------------------------------------------------------------------- 
  if ((select Count(*) from #LT_ErrorTable with (nolock)) = 0)
  begin    
    Insert into #LT_ErrorTable(propertyid,Propertyname,groupname,productname)
    select  
           PRP.IDSeq        as propertyid,
           PRP.Name         as Propertyname,
           ''               as groupname,
           P.DisplayName    as productname
     ---------------------------------------------------
    from  #temp_QuoteItem QI             with (nolock)
    Inner join
           Products.dbo.Product P         with (nolock)
    on     QI.ProductCode = P.Code
    and    QI.PriceVersion= P.PriceVersion
    and    QI.Quoteidseq  = @LVC_quoteid
    and    QI.GroupIdSeq  = @LI_groupid
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
                  and    X.GroupIdSeq                   <> @LI_groupid
                  and    QI.propertyid                  = X.propertyid
                 )    
    ---------------------------------------------------   
    group by PRP.IDSeq,PRP.Name,P.DisplayName
    order by PRP.Name asc,P.DisplayName asc
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
    and    QI.Quoteidseq          = @LVC_quoteid
    and    QI.GroupIDseq          = @LI_groupid 
    inner join
           #temp_QuoteItem LQI with (nolock)
    on     FIC.SecondFamilyCode = LQI.FamilyCode
    and    LQI.Quoteidseq       = @LVC_quoteid
    and    LQI.GroupIDseq      <> @LI_groupid 
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
    and    QI.Quoteidseq            = @LVC_quoteid
    and    QI.GroupIDseq            = @LI_groupid 
    inner join
           #temp_QuoteItem LQI with (nolock)
    on     FIC.FirstFamilyCode = LQI.FamilyCode
    and    LQI.Quoteidseq         = @LVC_quoteid
    and    LQI.GroupIDseq         <> @LI_groupid 
    group by F.Name,F1.Name
    order by productname asc
  end
  ----------------------------------------------------------------------------------
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
  drop table #LT_groupmaster
  drop table #LT_quoteitem
  drop table #temp_QuoteItem
  drop table #temp_QuoteItemGrouping
  drop table #LT_ErrorTable
  ------------------------------------------------------------------------------------
END
GO
