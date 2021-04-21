SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--uspQUOTES_GetGroupSummary @IPC_CompanyID = 'A0000000001', @IPVC_QuoteID = '1',@IPVC_RETURNTYPE  ='XML'

CREATE PROCEDURE [quotes].[uspQUOTES_GetGroupSummary] (@IPC_CompanyID     char(11),
                                                    @IPVC_QuoteID      varchar(50) = '0',
                                                    @IPI_GroupID       bigint = 0,
                                                    @IPVC_RETURNTYPE   varchar(100) = 'XML'                                            
                                                   )
AS
BEGIN   
  set nocount on 
  select @IPC_CompanyID = ltrim(rtrim(@IPC_CompanyID))
  select @IPVC_QuoteID   = coalesce(ltrim(rtrim(@IPVC_QuoteID)),'0') 
  select @IPI_GroupID   = coalesce(ltrim(rtrim(@IPI_GroupID)),0)
  -----------------------------------------------------------------------------------
  --Declaring Local Variables
  -----------------------------------------------------------------------------------
  declare @LT_GROUPSUMMARY Table 
           (recordidentificationtype varchar(100) NOT NULL,
            companyid             char(11),
            quoteid               varchar(50) NOT NULL default '0',
            quotestatus           varchar(5) not null default 'NSU', 
            groupid               bigint NOT NULL default 0, 
            groupname             varchar(200) NOT NULL default '',
            groupdescription      varchar(255) NOT NULL default '',
            overrideflag          int    NOT NULL default 0,   
            sites                 int    NOT NULL default 0,
            units                 int    NOT NULL default 0,
            beds                  int    NOT NULL default 0,  
            ppupercentage         int    NOT NULL default 100,          
            ilflistprice          money  NOT NULL default 0.00,
            accesslistprice       money  NOT NULL default 0.00,
            ilfdiscountpercent    numeric(30,5)  NOT NULL default 0.00,
            ilfdiscountamount     money          NOT NULL default 0.00,
            accessdiscountpercent numeric(30,5)  NOT NULL default 0,
            accessdiscountamount  money  NOT NULL default 0.00,
            ilfnetprice           money  NOT NULL default 0.00,
            accessnetprice        money  NOT NULL default 0.00,            
            totaldiscountamount   as (ilflistprice+accesslistprice)-(ilfnetprice+accessnetprice),
            totaldiscountpercent  as convert(numeric(30,2),(
                                       (convert(numeric(30,5),(ilflistprice+accesslistprice)-(ilfnetprice+accessnetprice)) * (100))
                                        /(case when (ilflistprice+accesslistprice)=0 then 1
                                               else convert(numeric(30,5),(ilflistprice+accesslistprice)) 
                                          end)
                                       )),                         
            grouptype              varchar(70)   not null default 'SITE',
            custombundlenameenabledflag bit          NOT NULL default 0,            
            allowproductcancelflag bit          NOT NULL default 1,
            showdetailpriceflag    bit          NOT NULL default 0,
            hastransferfee         bit          NOT NULL DEFAULT 0
           )       
   -----------------------------------------------------------------------------------
   if exists (select top 1 1 from QUOTES.dbo.[Group] G (nolock) 
              where  ltrim(rtrim(G.CustomerIDSeq)) = @IPC_CompanyID 
              and    G.QuoteIDSeq = @IPVC_QuoteID
             )
   begin     
     insert into @LT_GROUPSUMMARY(recordidentificationtype,companyid,quoteid,groupid,groupname,groupdescription,
                                  overrideflag,
                                  sites,units,beds,ppupercentage,
                                  ilflistprice,accesslistprice,
                                  ilfdiscountpercent,ilfdiscountamount,accessdiscountpercent,accessdiscountamount,
                                  ilfnetprice,accessnetprice,showdetailpriceflag,grouptype,custombundlenameenabledflag,                                  
                                  allowproductcancelflag,hastransferfee)
     select 'bundle'                                            as recordidentificationtype,
            ltrim(rtrim(@IPC_CompanyID))                        as companyid,
            G.QuoteIDSeq                                        as quoteid,
            G.IDSeq                                             as groupid,
            ltrim(rtrim(coalesce(G.Name,'')))                   as groupname,
            ltrim(rtrim(coalesce(G.Description,'')))            as groupdescription,
            G.overrideflag                                      as overrideflag,
            G.Sites                                             as sites,
            G.Units                                             as units,
            G.beds                                              as beds,
            G.ppupercentage                                     as ppupercentage,
            G.ILFExtYearChargeAmount                            as ilflistprice, 
            G.AccessExtYear1ChargeAmount                        as accesslistprice,
            convert(numeric(30,5),G.ILFDiscountPercent)         as ilfdiscountpercent,
            G.ILFDiscountAmount                                 as ilfdiscountamount,
            convert(numeric(30,5),G.AccessDiscountPercent)      as accessdiscountpercent,
            G.AccessDiscountAmount                              as accessdiscountamount,
            G.ILFNetExtYearChargeAmount                         as ilfnetprice,
            G.AccessNetExtYear1ChargeAmount                     as accessnetprice,
            G.ShowDetailPriceFlag                               as showdetailpriceflag,
            G.grouptype                                         as grouptype,
            coalesce(G.custombundlenameenabledflag,0)           as custombundlenameenabledflag,             
            coalesce(G.allowproductcancelflag,1)                as allowproductcancelflag,           
            coalesce((select Top 1 1
                       from  Quotes.dbo.QuoteItem QI with (nolock)
                       where QI.GroupIDSeq  = G.IDSeq
                       and   QI.ProductCode = 'DMD-PSR-ADM-ADM-AMTF' 
                      ),0)  as hastransferfee
      from   QUOTES.dbo.[Group] G (nolock) 
      where  ltrim(rtrim(G.CustomerIDSeq)) = @IPC_CompanyID and G.QuoteIDSeq = @IPVC_QuoteID 
      and    G.IDSeq         = (case when (@IPI_GroupID is null or  coalesce(ltrim(rtrim(@IPI_GroupID)),0) = 0) 
                                         then G.IDSeq
                                     else  ltrim(rtrim(@IPI_GroupID)) 
                                end)    
  end
  else
  begin
    insert into @LT_GROUPSUMMARY(recordidentificationtype,companyid,quoteid,groupid)
    select 'bundle',@IPC_CompanyID,@IPVC_QuoteID,@IPI_GroupID
  end

  -------------------------------------------------------------------------  
  insert into @LT_GROUPSUMMARY(recordidentificationtype,companyid,quoteid,groupid,groupname,groupdescription,
                                 overrideflag,
                                 sites,units,beds,ppupercentage,
                                 ilflistprice,accesslistprice,
                                 ilfdiscountpercent,ilfdiscountamount,accessdiscountpercent,accessdiscountamount,
                                 ilfnetprice,accessnetprice,showdetailpriceflag,grouptype,
                                 allowproductcancelflag)
  select 'total'      as recordidentificationtype,X.companyid as companyid,X.quoteid as quoteid,
           ''           as groupid,'' as groupname,'' as groupdescription,
           0 as overrideflag,sum(X.sites) as sites,sum(X.units)  as units,
           sum(X.beds)  as beds,
           sum(ppupercentage) as ppupercentage,
           sum(X.ilflistprice)  as ilflistprice,sum(X.accesslistprice) as accesslistprice,
           0.00         as ilfdiscountpercent,sum(X.ilfdiscountamount) as ilfdiscountamount,
           0.00         as accessdiscountpercent,sum(X.accessdiscountamount) as accessdiscountamount,
           sum(X.ilfnetprice) as ilfnetprice,sum(X.accessnetprice) as accessnetprice,
           0 as showdetailpriceflag,'' as grouptype,
           1 as allowproductcancelflag
  from @LT_GROUPSUMMARY X
  group by X.companyid,X.quoteid
   
  update @LT_GROUPSUMMARY set quotestatus = (select QuoteStatusCode from Quotes.dbo.Quote where QuoteIDSeq = @IPVC_QuoteID)  

  -----------------------------------------------------------------------
  -- Final Select 
  -----------------------------------------------------------------------
  if @IPVC_RETURNTYPE = 'XML'
  begin
    select recordidentificationtype,companyid,quoteid,groupid,groupname,groupdescription,
         overrideflag                                            as overrideflag, 
         Quotes.DBO.fn_FormatCurrency(sites,0,0)                 as sites ,
         Quotes.DBO.fn_FormatCurrency(units,0,0)                 as units,  
         Quotes.DBO.fn_FormatCurrency(beds,0,0)                  as beds,  
         Quotes.DBO.fn_FormatCurrency(ppupercentage,0,0)         as ppupercentage,      
         Quotes.DBO.fn_FormatCurrency(ilflistprice,0,0)          as ilflistprice,
         Quotes.DBO.fn_FormatCurrency(accesslistprice,0,0)       as accesslistprice,
         Quotes.DBO.fn_FormatCurrency(totaldiscountpercent,1,1)  as discountpercent,
         Quotes.DBO.fn_FormatCurrency(totaldiscountamount,0,0)   as discountamount,
         Quotes.DBO.fn_FormatCurrency(ilfnetprice,0,0)           as ilfnetprice,
         Quotes.DBO.fn_FormatCurrency(accessnetprice,0,0)        as accessnetprice,
         quotestatus                                             as quotestatus,         
         showdetailpriceflag                                     as showdetailpriceflag,
         grouptype                                               as grouptype,                   
         allowproductcancelflag                                  as allowproductcancelflag,
         custombundlenameenabledflag                             as custombundlenameenabledflag, 
         0                                                       as bundledeleteflag, 
         hastransferfee                                          as hastransferfee
    from @LT_GROUPSUMMARY order by recordidentificationtype asc
    FOR XML raw ,ROOT('bundlessummary'),TYPE
  end
  else
  begin
    select recordidentificationtype,companyid,quoteid,groupid,groupname,groupdescription,
         overrideflag                                            as overrideflag, 
         Quotes.DBO.fn_FormatCurrency(sites,0,0)                 as sites ,
         Quotes.DBO.fn_FormatCurrency(units,0,0)                 as units,  
         Quotes.DBO.fn_FormatCurrency(beds,0,0)                  as beds,  
         Quotes.DBO.fn_FormatCurrency(ppupercentage,0,0)         as ppupercentage,      
         Quotes.DBO.fn_FormatCurrency(ilflistprice,0,0)          as ilflistprice,
         Quotes.DBO.fn_FormatCurrency(accesslistprice,0,0)       as accesslistprice,
         Quotes.DBO.fn_FormatCurrency(totaldiscountpercent,1,1)  as discountpercent,
         Quotes.DBO.fn_FormatCurrency(totaldiscountamount,0,0)   as discountamount,
         Quotes.DBO.fn_FormatCurrency(ilfnetprice,0,0)           as ilfnetprice,
         Quotes.DBO.fn_FormatCurrency(accessnetprice,0,0)        as accessnetprice,
         quotestatus                                             as quotestatus,         
         showdetailpriceflag                                     as showdetailpriceflag,
         grouptype                                               as grouptype,                   
         allowproductcancelflag                                  as allowproductcancelflag,
         custombundlenameenabledflag                             as custombundlenameenabledflag, 
         0                                                       as bundledeleteflag, 
         hastransferfee                                          as hastransferfee
    from @LT_GROUPSUMMARY order by recordidentificationtype asc
  end
  
END

GO
