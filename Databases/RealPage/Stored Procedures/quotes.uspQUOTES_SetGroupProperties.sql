SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec [QUOTES].[dbo].[uspQUOTES_SetGroupProperties] @IPT_SetGroupPropertiesXML = 
'<groupproperties xmlns=""><row companyid="A0000000001" quoteid="2" groupid="1" propertyid="B0000000085" propertyname="Cameo Real" units="100" addressline1="4000 Horizon North" addressline2="" city="Dallas" county="Denton" state="TX" zip="75001" pricetypecode="Normal" isselected="1"/>
<row companyid="A0000000001" quoteid="2" groupid="1" propertyid="B0000000004" propertyname="Cameo Real 32" units="1,564" addressline1="5002 Midway Road" addressline2="#432" city="Dallas" county="Dallas" state="TX" zip="75001" pricetypecode="Normal"  isselected="1"/>
<row companyid="A0000000001" quoteid="2" groupid="1" propertyid="B0000000029" propertyname="New Realty Cameo" units="543" addressline1="1212 cameo Blvd" addressline2="New Cameo Drive" city="Dallas" county="" state="TX" zip="75001" pricetypecode="Normal"  isselected="1"/>
<row companyid="A0000000001" quoteid="2" groupid="1" propertyid="B0000000002" propertyname="Realty Cameo2" units="1,128" addressline1="5000 Midway Road" addressline2="" city="Plano" county="" state="TX" zip="75001" pricetypecode="Normal" isselected="1"/>
<row companyid="A0000000001" quoteid="2" groupid="1" propertyid="B0000000190" propertyname="test 2 2" units="22" addressline1="test" addressline2="tste" city="test" county="" state="AK" zip="22222" pricetypecode="Normal" isselected="0"/>
<row companyid="A0000000001" quoteid="2" groupid="1" propertyid="B0000000193" propertyname="test 3 3" units="3" addressline1="se" addressline2="de" city="dasss" county="" state="AK" zip="44444" pricetypecode="Normal" isselected="0"/>
</groupproperties>'
*/
CREATE PROCEDURE [quotes].[uspQUOTES_SetGroupProperties] (@IPT_SetGroupPropertiesXML  TEXT = NULL                                                 
                                                      )
AS
BEGIN --: Main BEGIN
  set nocount on; 
  set XACT_ABORT on; -- set XACT_ABORT on will render the transaction uncommittable
                     -- when the constraint violation occurs.
  -----------------------------------------------------------------------------------
  --Declaring Local Variables
  -----------------------------------------------------------------------------------
  declare @LI_Min                        int
  declare @LI_Max                        int  
  declare @LVC_companyid                 varchar(50)
  declare @LVC_propertyid                varchar(50)
  declare @LVC_quoteid                   varchar(50)
  declare @LI_groupid                    int
  declare @LI_units                      int
  declare @LI_beds                       int
  declare @LI_sites                      int
  declare @LI_ppupercentage              int
  declare @LVC_pricetypecode             varchar(50)
  declare @LI_thresholdoverrideflag      int
  declare @LI_isselected                 int

  select @LI_Min=0,@LI_Max=0,@LI_isselected=0,@LI_units=0,@LI_sites = 0,@LI_beds=0,
         @LI_ppupercentage=100,@LVC_pricetypecode='Normal',@LI_thresholdoverrideflag=0
  -----------------------------------------------------------------------------------
  --Declaring Local Table Variable
  -----------------------------------------------------------------------------------
  declare @LT_GroupProperties TABLE(SEQ                   int not null identity(1,1),
                                    companyid             varchar(50),
                                    propertyid            varchar(50),  
                                    quoteid               varchar(50),
                                    groupid               bigint,
                                    units                 int not null default 0,
                                    beds                  int not null default 0,
                                    ppupercentage         int not null default 100, 
                                    pricetypecode         varchar(50) not null default 'Normal',
                                    thresholdoverrideflag int not null default 0,
                                    isselected            int not null default 0
                                    )
  declare @LT_DistinctGroup  TABLE (SEQ                   int not null identity(1,1),
                                    companyid             varchar(50),                                     
                                    quoteid               varchar(50),
                                    groupid               bigint,
                                    sites                 int not null default 0,
                                    units                 int not null default 0,
                                    beds                  int not null default 0,
                                    ppupercentage         int not null default 100                                    
                                    )
  declare @LT_DistinctQuote TABLE  (SEQ                   int not null identity(1,1),
                                    companyid             varchar(50),                                     
                                    quoteid               varchar(50)                                                                     
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
    insert into @LT_GroupProperties(companyid,propertyid,quoteid,groupid,units,beds,ppupercentage,
                                    pricetypecode,thresholdoverrideflag,isselected)
    select distinct A.companyid,A.propertyid,A.quoteid,A.groupid,A.units,A.beds,A.ppupercentage,
                    A.pricetypecode,A.thresholdoverrideflag,A.isselected
    from (select ltrim(rtrim(companyid))           as companyid,
                 ltrim(rtrim(propertyid))          as propertyid, 
                 ltrim(rtrim(quoteid))             as quoteid,
                 ltrim(rtrim(groupid))             as groupid,
                 convert(int,coalesce(units,0))    as units,
                 convert(int,coalesce(beds,0))     as beds,
                 convert(int,coalesce(ppupercentage,0))    as ppupercentage,
                 ltrim(rtrim(pricetypecode))       as pricetypecode,
                 coalesce(thresholdoverrideflag,0) as thresholdoverrideflag,
                 coalesce(isselected,0)            as isselected
          from OPENXML (@idoc,'//groupproperties/row',1) 
          with (companyid             varchar(50),
                propertyid            varchar(50),
                quoteid               varchar(50),
                groupid               bigint,
                units                 money,
                beds                  money,
                ppupercentage         money,
                pricetypecode         varchar(50),
                thresholdoverrideflag int,
                isselected            int)                
          ) A
    
    insert into @LT_DistinctGroup(companyid,quoteid,groupid,sites,units,beds,ppupercentage) 
    select distinct Z.companyid,Z.quoteid,Z.groupid,
           coalesce((select count(X.propertyid) from @LT_GroupProperties X 
                    where X.isselected = 1  and X.companyid = Z.companyid and X.quoteid = Z.quoteid
                    and   X.groupid = Z.groupid),0) as sites,
           coalesce((select sum(X.units) from @LT_GroupProperties X 
                    where X.isselected = 1  and X.companyid = Z.companyid and X.quoteid = Z.quoteid
                    and   X.groupid = Z.groupid),0) as units,
           coalesce((select sum(X.beds) from @LT_GroupProperties X 
                    where X.isselected = 1  and X.companyid = Z.companyid and X.quoteid = Z.quoteid
                    and   X.groupid = Z.groupid),0) as beds,
           coalesce((select sum(X.ppupercentage) from @LT_GroupProperties X 
                    where X.isselected = 1  and X.companyid = Z.companyid and X.quoteid = Z.quoteid
                    and   X.groupid = Z.groupid),0) as ppupercentage          
    from   @LT_GroupProperties Z
    group by Z.companyid,Z.quoteid,Z.groupid
 
    insert into @LT_DistinctQuote(companyid,quoteid) 
    select distinct Z.companyid,Z.quoteid
    from   @LT_GroupProperties Z where Z.isselected = 1
        
  end TRY
  begin CATCH
    EXEC CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] '//groupproperties/row XML ReadSection'  
    if @idoc is not null
    begin
      EXEC sp_xml_removedocument @idoc
      set @idoc = NULL
    end 
    return
  end CATCH;
  ----------------------------------------------------------------------------------
  select Top 1 @LVC_quoteid = quoteid,@LI_groupid = groupid
  from   @LT_DistinctGroup
  Delete from QUOTES.dbo.GroupProperties 
  where  QuoteIDSeq=@LVC_quoteid and GroupIDSeq = @LI_groupid  
  -----------------------------------------------------------------------------------
  ---select * from @LT_GroupProperties --:Validation
  if (select count(*) from @LT_GroupProperties) > 0
  begin
    select @LI_Min = Min(SEQ),@LI_Max = Max(SEQ) from @LT_GroupProperties
    while @LI_Min <= @LI_Max
    begin --: begin while
      select @LVC_companyid = companyid,@LVC_propertyid = propertyid,
             @LVC_quoteid = quoteid,@LI_groupid = groupid,@LVC_pricetypecode=pricetypecode,
             @LI_thresholdoverrideflag = thresholdoverrideflag,
             @LI_isselected = isselected,
             @LI_units=units,@LI_beds=beds,@LI_ppupercentage=ppupercentage
      from   @LT_GroupProperties where SEQ = @LI_Min
      begin TRY
        BEGIN TRANSACTION;
          if (@LI_isselected = 0)
          begin
            Delete from QUOTES.dbo.GroupProperties 
            where PropertyIDSeq = @LVC_propertyid
            and   QuoteIDSeq    = @LVC_quoteid    and GroupIDSeq    = @LI_groupid
          end
          else if (@LI_isselected = 1)
          begin
            if not exists(select top 1 1 from QUOTES.dbo.GroupProperties (nolock)
                          where CustomerIDSeq = @LVC_companyid  and PropertyIDSeq = @LVC_propertyid
                          and   QuoteIDSeq    = @LVC_quoteid    and GroupIDSeq    = @LI_groupid 
                          )
            and exists   (select top 1 1 from CUSTOMERS.dbo.Property (nolock)
                          where  IDSeq    = @LVC_propertyid
                          and    StatusTypeCode ='ACTIV'
                          and    PMCIDSeq = @LVC_companyid
                         )
            begin
              insert into QUOTES.dbo.GroupProperties(CustomerIDSeq,PropertyIDSeq,QuoteIDSeq,GroupIDSeq,pricetypecode,
                                                     thresholdoverrideflag,units,beds,ppupercentage)
              select @LVC_companyid,@LVC_propertyid,@LVC_quoteid,@LI_groupid,@LVC_pricetypecode,
                     @LI_thresholdoverrideflag,@LI_units,@LI_beds,@LI_ppupercentage
            end
            else
            begin
              Update QUOTES.dbo.GroupProperties
              set    pricetypecode         = @LVC_pricetypecode,
                     thresholdoverrideflag = @LI_thresholdoverrideflag,
                     units                 = @LI_units,
                     beds                  = @LI_beds,
                     ppupercentage         = @LI_ppupercentage
              where  CustomerIDSeq = @LVC_companyid 
              and    PropertyIDSeq = @LVC_propertyid
              and    QuoteIDSeq    = @LVC_quoteid    
              and    GroupIDSeq    = @LI_groupid 
            end
          end
        COMMIT TRANSACTION;
      end TRY
      begin CATCH
        EXEC CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] 'Insert GroupProperties Section' 
        -- XACT_STATE:
           -- If 1, the transaction is committable.
           -- If -1, the transaction is uncommittable and should be rolled back.
           -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
        if (XACT_STATE()) = -1
        begin
          IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        end
        else if (XACT_STATE()) = 1
        begin
          IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
        end      
      end CATCH         
      select @LI_Min = @LI_Min + 1
    end --: end while
  end
  -----------------------------------------------------------------------------------
  select @LI_Min=0,@LI_Max=0,@LI_isselected=0,@LI_units=0,@LI_sites = 0,@LI_beds=0,@LI_ppupercentage=100
  -----------------------------------------------------------------------------------
  ---select * from @LT_DistinctGroup --:Validation
  if (select count(*) from @LT_DistinctGroup) > 0
  begin
    select @LI_Min = Min(SEQ),@LI_Max = Max(SEQ) from @LT_DistinctGroup
    while @LI_Min <= @LI_Max
    begin --: begin while
      select @LVC_companyid = companyid,@LVC_quoteid = quoteid,@LI_groupid = groupid,
             @LI_sites = sites,@LI_units = units,@LI_beds = beds,
             @LI_ppupercentage=ppupercentage
      from   @LT_DistinctGroup where SEQ = @LI_Min
      begin TRY
        BEGIN TRANSACTION;
          update QUOTES.dbo.QuoteItem
          set    sites = @LI_sites,units = @LI_units,beds=@LI_beds,ppupercentage=@LI_ppupercentage                 
          where  QuoteIDSeq = @LVC_quoteid and GroupIDSeq = @LI_groupid

          update QUOTES.dbo.[Group]
          set    sites = @LI_sites,units = @LI_units,beds=@LI_beds,ppupercentage=@LI_ppupercentage
          where  QuoteIDSeq = @LVC_quoteid and IDSeq = @LI_groupid
          and    CustomerIDSeq = @LVC_companyid
        COMMIT TRANSACTION;
      end TRY
      begin CATCH        
	EXEC CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] 'Update QuoteItem,Group Section' 
        -- XACT_STATE:
           -- If 1, the transaction is committable.
           -- If -1, the transaction is uncommittable and should be rolled back.
           -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
        if (XACT_STATE()) = -1
        begin
          IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        end
        else if (XACT_STATE()) = 1
        begin
          IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
        end      
      end CATCH 
      exec Quotes.dbo.uspQUOTES_SyncGroupAndQuote @IPVC_QuoteID=@LVC_quoteid,@IPI_GroupID=@LI_groupid          
      select @LI_Min = @LI_Min + 1
    end --: end while   
  end
  -----------------------------------------------------------------------------------
  select @LI_Min=0,@LI_Max=0,@LI_isselected=0,@LI_units=0,@LI_sites = 0,@LI_beds=0,@LI_ppupercentage=100
  -----------------------------------------------------------------------------------
  ---select * from @LT_DistinctQuote --:Validation
  if (select count(*) from @LT_DistinctQuote) > 0
  begin
    select @LI_Min = Min(SEQ),@LI_Max = Max(SEQ) from @LT_DistinctQuote
    while @LI_Min <= @LI_Max
    begin --: begin while
      select @LVC_companyid = companyid,@LVC_quoteid = quoteid
      from   @LT_DistinctQuote where SEQ = @LI_Min
      begin TRY
        select @LI_units = sum(Z.units),@LI_sites = sum(Z.sites),
               @LI_beds  = sum(Z.beds),
               @LI_ppupercentage=sum(ppupercentage)
        from   QUOTES.dbo.[Group] Z (nolock)
        where  Z.CustomerIDSeq = @LVC_companyid
        and    Z.QuoteIDSeq = @LVC_quoteid

        BEGIN TRANSACTION;
          update QUOTES.dbo.Quote
          set    sites = @LI_sites,units = @LI_units,beds=@LI_beds
          where  QuoteIDSeq = @LVC_quoteid and CustomerIDSeq = @LVC_companyid          
        COMMIT TRANSACTION;
      end TRY
      begin CATCH
        EXEC CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] 'Update Quote Section' 
        -- XACT_STATE:
           -- If 1, the transaction is committable.
           -- If -1, the transaction is uncommittable and should be rolled back.
           -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
        if (XACT_STATE()) = -1
        begin
          IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        end
        else if (XACT_STATE()) = 1
        begin
          IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
        end      
      end CATCH  
      exec Quotes.dbo.uspQUOTES_SyncGroupAndQuote @IPVc_QuoteID=@LVC_quoteid,@IPI_GroupID=@LI_groupid         
      select @LI_Min = @LI_Min + 1
    end --: end while   
  end
  ---------------------------------------------------------------------------------------
  IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
  if @idoc is not null
  begin
    EXEC sp_xml_removedocument @idoc
    set @idoc = NULL
  end 
  ---------------------------------------------------------------------------------------
END
GO
