SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : [uspQUOTES_GetGroupProperties]
-- Description     : Fetch list of Property already assigned to a specific quote bundle
-- Input Parameters: Yes.  see below.
-- OUTPUT          : List of property and some of their attributes
-- 
-- Revision History:
-- Author          : Davon Cannon
-- 2007-04-23      : Stored Procedure Created.
-- 2010-12-14      : Larry adds SeniorLiving etc, for PCR 8528
------------------------------------------------------------------------------------------------------
---exec [QUOTES].[dbo].[uspQUOTES_GetGroupProperties] @IPVC_QuoteID = 'Q0000000004', @IPI_GroupID = '58', @IPC_CompanyID = 'C0000000387',@IPVC_RETURNTYPE='RECORDSET'                                                           
CREATE PROCEDURE [quotes].[uspQUOTES_GetGroupProperties] (@IPC_CompanyID      varchar(100),
                                                       @IPVC_QuoteID       varchar(50),
                                                       @IPI_GroupID        bigint,
                                                       @IPVC_RETURNTYPE    varchar(100) = 'XML'                                            
                                                       )
AS
BEGIN   
  set nocount on   
  -----------------------------------------------------------------------------------
  --Declaring Local Table Variable
  -----------------------------------------------------------------------------------
  create table #LT_groupproperties (SEQ           int not null identity(1,1),
                                    quoteid       varchar(50)  not null default '0',
                                    groupid       bigint       not null default 0,
                                    companyid     varchar(20),  
                                    propertyid    varchar(20)  not null default '', 
                                    propertyname  varchar(100) not null default '', 
                                    units         varchar(50)  not null default 0,
                                    beds          varchar(50)  not null default 0,
                                    ppupercentage int          not null default 100,
                                    addressline1  varchar(70)  not null default '', 
                                    addressline2  varchar(70)  not null default '', 
                                    city          varchar(70)  not null default '', 
                                    county        varchar(70)  not null default '', 
                                    state         varchar(2)   not null default '', 
                                    zip           varchar(20)  not null default '',                                    
                                    pricetypecode varchar(50)  not null default 'Normal',
                                    thresholdoverrideflag int  not null default 0,
                                    studentlivingflag     int  not null default 0,
                                    gsaentityflag         int  not null default 0
                                    ,[MilitaryPrivatizedFlag] int not null default 0
                                    ,[SeniorLivingFlag]   int not null default 0
                                    ,isselected    bit          not null default 0
                                    )
  select @IPC_CompanyID  = coalesce(ltrim(rtrim(@IPC_CompanyID)),'0'),
         @IPVC_QuoteID   = coalesce(ltrim(rtrim(@IPVC_QuoteID)),'0'),
         @IPI_GroupID    = coalesce(ltrim(rtrim(@IPI_GroupID)),'0')

  ----------------------------------------------------------------------------------- 
  --- Property status will only be ACTIVE or INACTIVE.
  --- There is no special case for Site transfer. May 16,2008
  /*   
  -- If the Quote is a Transfer Quote , Show only the property attached.
  -- All Bundles in Transfer Quote should have only one property attached to it.
  if exists (select top 1 1 from Quotes.dbo.[Quote] Q with (nolock)
				  where  Q.Quoteidseq    = @IPVC_QuoteID
				  and    Q.CustomerIDSeq = @IPC_CompanyID
				  and    Q.QuoteTypeCode = 'STFQ')
  begin   
    insert into #LT_groupproperties(quoteid,groupid,companyid,propertyid,propertyname,units,beds,ppupercentage,
                                    pricetypecode,thresholdoverrideflag,
                                    addressline1,addressline2,city,county,state,zip, 
                                    studentlivingflag,isselected                                    
                                    )
    select distinct @IPVC_QuoteID                                                           as quoteid,
                    @IPI_GroupID                                                            as groupid,
                    coalesce(PRP.PMCIDSeq,'0')                                              as companyid,
                    coalesce(PRP.IDSeq,'0')                                                 as propertyid,
                    coalesce(ltrim(rtrim(PRP.Name)),'0')                                    as propertyname,
                    CUSTOMERS.DBO.fn_FormatCurrency((case when PRP.QuotableUnits = 0 then coalesce(PRP.Units,'0')
                                                         else coalesce(PRP.QuotableUnits,PRP.Units,'0')
                                                    end),0,0)
                                                                                            as units,
                    CUSTOMERS.DBO.fn_FormatCurrency((case when PRP.QuotableBeds = 0 then coalesce(PRP.Beds,'0')
                                                         else coalesce(PRP.QuotableBeds,PRP.Beds,'0')
                                                    end),0,0)                               as beds, 
                    coalesce(PRP.ppupercentage,'100')                                       as ppupercentage,                                                                                                                                  
                    coalesce(GP.pricetypecode,'Normal')                                     as pricetypecode,
                    coalesce(GP.thresholdoverrideflag,0)                                    as thresholdoverrideflag,
                    coalesce(ltrim(rtrim(ADDR.addressline1)),' ')                           as addressline1,
                    coalesce(ltrim(rtrim(ADDR.addressline2)),' ')                           as addressline2,
                    coalesce(ltrim(rtrim(ADDR.city)),' ')                                   as city,
                    coalesce(ltrim(rtrim(ADDR.county)),' ')                                 as county,
                    coalesce(ltrim(rtrim(ADDR.state)),' ')                                  as state,
                    coalesce(ltrim(rtrim(ADDR.zip)),' ')                                    as zip,
                    coalesce(PRP.studentlivingflag,0)                                       as studentlivingflag,
                    (Case when GP.PropertyIDSeq is not null then 1 else 0 end)              as isselected                    
    from  CUSTOMERS.dbo.Property     PRP  with (nolock) 
    Left Outer Join 
          CUSTOMERS.dbo.Address      ADDR with (nolock)    
    on    ADDR.CompanyIDSeq    = PRP.PMCIDSeq
    and   ADDR.CompanyIDSeq    = @IPC_CompanyID   
    and   PRP.PMCIDSeq         = @IPC_CompanyID 
    and   ADDR.PropertyIDSeq   = PRP.IDSeq
    and   ADDR.AddressTypeCode = 'PRO'    
    Left Outer Join 
          QUOTES.dbo.GroupProperties  GP  with (nolock) 
    on    GP.CustomerIDSeq  = PRP.PMCIDSeq
    and   PRP.PMCIDSeq      = @IPC_CompanyID
    and   GP.CustomerIDSeq  = @IPC_CompanyID
    and   GP.QuoteIDSeq     = @IPVC_QuoteID
    and   GP.GroupIDSeq     = @IPI_GroupID
    and   GP.PropertyIDSeq  = PRP.IDSeq  
    and   PRP.StatusTypeCode='TRNSP'                                             
    where PRP.PMCIDSeq      = @IPC_CompanyID    
    and   PRP.StatusTypeCode='TRNSP'
    order by coalesce(ltrim(rtrim(PRP.Name)),'0') ASC
  ----------------------------------------------------------------------------------------------    
  end
  ----------------------------------------------------------------------------------------------   
  else */
  if exists (select top 1 1 
                  from   CUSTOMERS.dbo.Property with (nolock) 
                  where  PMCIDSeq       = @IPC_CompanyID 
                  and    StatusTypeCode ='ACTIV' )
  begin          
    insert into #LT_groupproperties(quoteid,groupid,companyid,propertyid,propertyname,units,beds,ppupercentage,
                                    pricetypecode,thresholdoverrideflag,
                                    addressline1,addressline2,city,county,state,zip, 
                                    studentlivingflag,gsaentityflag
                                    ,[MilitaryPrivatizedFlag],[SeniorLivingFlag]
                                    ,isselected                                    
                                    )
    select distinct @IPVC_QuoteID                                                           as quoteid,
                    @IPI_GroupID                                                            as groupid,
                    coalesce(PRP.PMCIDSeq,'0')                                              as companyid,
                    coalesce(PRP.IDSeq,'0')                                                 as propertyid,
                    coalesce(ltrim(rtrim(PRP.Name)),'0')                                    as propertyname,
                    CUSTOMERS.DBO.fn_FormatCurrency((case when PRP.QuotableUnits = 0 then coalesce(PRP.Units,'0')
                                                         else coalesce(PRP.QuotableUnits,PRP.Units,'0')
                                                    end),0,0)
                                                                                            as units,
                    CUSTOMERS.DBO.fn_FormatCurrency((case when PRP.QuotableBeds = 0 then coalesce(PRP.Beds,'0')
                                                         else coalesce(PRP.QuotableBeds,PRP.Beds,'0')
                                                    end),0,0)                               as beds, 
                    coalesce(PRP.ppupercentage,'100')                                       as ppupercentage,                                                                                                                                  
                    coalesce(GP.pricetypecode,'Normal')                                     as pricetypecode,
                    coalesce(GP.thresholdoverrideflag,0)                                    as thresholdoverrideflag,
                    coalesce(ltrim(rtrim(ADDR.addressline1)),' ')                           as addressline1,
                    coalesce(ltrim(rtrim(ADDR.addressline2)),' ')                           as addressline2,
                    coalesce(ltrim(rtrim(ADDR.city)),' ')                                   as city,
                    coalesce(ltrim(rtrim(ADDR.county)),' ')                                 as county,
                    coalesce(ltrim(rtrim(ADDR.state)),' ')                                  as state,
                    coalesce(ltrim(rtrim(ADDR.zip)),' ')                                    as zip,
                    coalesce(PRP.studentlivingflag,0)                                       as studentlivingflag,
                    coalesce(PRP.gsaentityflag,0)                                           as gsaentityflag
                    ,coalesce(PRP.[MilitaryPrivatizedFlag],0)								as [MilitaryPrivatizedFlag]
                    ,coalesce(PRP.[SeniorLivingFlag],0)										as [SeniorLivingFlag]
                    ,(Case when GP.PropertyIDSeq is not null then 1 else 0 end)             as isselected                    
    from  CUSTOMERS.dbo.Property     PRP  with (nolock) 
    Left Outer Join 
          CUSTOMERS.dbo.Address      ADDR with (nolock)    
    on    ADDR.CompanyIDSeq    = PRP.PMCIDSeq
    and   ADDR.CompanyIDSeq    = @IPC_CompanyID   
    and   PRP.PMCIDSeq         = @IPC_CompanyID 
    and   ADDR.PropertyIDSeq   = PRP.IDSeq
    and   ADDR.AddressTypeCode = 'PRO'    
    Left Outer Join 
          QUOTES.dbo.GroupProperties  GP  with (nolock) 
    on    GP.CustomerIDSeq  = PRP.PMCIDSeq
    and   PRP.PMCIDSeq      = @IPC_CompanyID
    and   GP.CustomerIDSeq  = @IPC_CompanyID
    and   GP.QuoteIDSeq     = @IPVC_QuoteID
    and   GP.GroupIDSeq     = @IPI_GroupID
    and   GP.PropertyIDSeq  = PRP.IDSeq  
    and   PRP.StatusTypeCode='ACTIV'                                             
    where PRP.PMCIDSeq      = @IPC_CompanyID    
    and   PRP.StatusTypeCode='ACTIV'
    order by coalesce(ltrim(rtrim(PRP.Name)),'0') ASC
  ----------------------------------------------------------------------------------------------    
  end
  ---------------------------------------------------------------------------------------------- 
  if (select count(*) from #LT_groupproperties with (nolock)) = 0    
  begin
    insert into #LT_groupproperties(companyid,quoteid,groupid) 
    select @IPC_CompanyID,@IPVC_QuoteID,@IPI_GroupID
  end

  --Final Select from #LT_groupproperties
  -----------------------------------------------------------------------------------
  if @IPVC_RETURNTYPE = 'XML'
  begin
    select companyid,quoteid,groupid,propertyid,propertyname,units,beds,ppupercentage,
           city,state,pricetypecode,thresholdoverrideflag,studentlivingflag,gsaentityflag
           ,[MilitaryPrivatizedFlag],[SeniorLivingFlag],isselected
    from #LT_groupproperties with (nolock)
    FOR XML raw ,ROOT('groupproperties'), TYPE
/*
    select companyid,quoteid,groupid,propertyid,propertyname,units,beds,ppupercentage,
           addressline1,addressline2,city,county,state,zip,
           pricetypecode,thresholdoverrideflag,studentlivingflag,isselected
    from #LT_groupproperties with (nolock)
    FOR XML raw ,ROOT('groupproperties'), TYPE
*/
  end
  else
  begin
    select companyid,quoteid,groupid,propertyid,propertyname,units,beds,ppupercentage,
           addressline1,addressline2,city,county,state,zip,
           pricetypecode,thresholdoverrideflag,studentlivingflag,gsaentityflag
           ,[MilitaryPrivatizedFlag],[SeniorLivingFlag],isselected
    from #LT_groupproperties with (nolock)    
  end  
  --------------------------------------------------------------------------------
  -- Final Cleanup
  drop table #LT_groupproperties
  --------------------------------------------------------------------------------
END
GO
