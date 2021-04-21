SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec Quotes.dbo.uspQUOTES_GetGroupDetails @IPC_CompanyID = 'A0000001089',@IPVC_quoteid =55,
                                          @IPI_GroupID = 50,@IPVC_RETURNTYPE='XML'
*/

CREATE PROCEDURE [quotes].[uspQUOTES_GetGroupDetails] (@IPC_CompanyID     char(11),
                                                    @IPVC_quoteid      varchar(50) = '0',
                                                    @IPI_GroupID       bigint = 0,
                                                    @IPVC_RETURNTYPE   varchar(100) = 'XML')
AS
BEGIN   
  set nocount on; 
  select @IPC_CompanyID  = ltrim(rtrim(@IPC_CompanyID))
  select @IPVC_quoteid   = coalesce(ltrim(rtrim(@IPVC_quoteid)),'0') 
  select @IPI_GroupID    = coalesce(ltrim(rtrim(@IPI_GroupID)),0)
  ------------------------------------------------------------------------------------------
  --Declaring local variables
  ------------------------------------------------------------------------------------------
  declare @LT_GroupDetails  TABLE (seq                   int not null identity (1,1),
                                   companyid             varchar(50)   not null,
                                   quoteid               varchar(50)   not null default '0',
                                   groupid               bigint        not null default 0,
                                   groupname             varchar(200)  not null default '',                                   
                                   description           varchar(255)  not null default '',
                                   discallocationcode    varchar(10)   not null default 'IND',                                   
                                   sites                 int           not null default 0,
                                   units                 int           not null default 0,
                                   beds                  int           not null default 0,
                                   ppupercentage         int           not null default 100,
                                   ilfdiscountamount     money         not null default 0.00,
                                   ilfdiscountpercent    numeric(30,5) not null default 0.00,
                                   accessdiscountamount  money         not null default 0.00,
                                   accessdiscountpercent numeric(30,5) not null default 0.00,                                                                      
                                   showdetailpriceflag     bit         not null default 0,                                  
                                   allowproductcancelflag  bit         not null default 1,
                                   grouptype               varchar(70)    not null default 'SITE',
                                   custombundlenameenabledflag bit        not null default 0, 
                                   autofulfillilfflag       int           not null  default 1,
                                   autofulfillacsancflag    int           not null  default 0,
								   autofulfillstartdate		datetime	not null,
                                   internalgroupid          varchar(200)  not null default ''                                    
                                  )
  ------------------------------------------------------------------------------------------                                    

  if exists (select top 1 1 from QUOTES.dbo.[Group] G (nolock) 
             where G.IDSeq = @IPI_GroupID and G.QuoteIDSeq = @IPVC_quoteid
            )
  begin
    insert into @LT_GroupDetails(companyid,quoteid,groupid,groupname,description,discallocationcode,
                                 sites,units,beds,ppupercentage,
                                 ilfdiscountamount,ilfdiscountpercent,
                                 accessdiscountamount,accessdiscountpercent,                                 
                                 showdetailpriceflag,
                                 allowproductcancelflag,
                                 grouptype,custombundlenameenabledflag,
                                 autofulfillilfflag,autofulfillacsancflag,autofulfillstartdate,
                                 internalgroupid)
    select distinct ltrim(rtrim(@IPC_CompanyID))       as companyid,
                    @IPVC_quoteid                      as quoteid,
                    @IPI_GroupID                       as groupid,
                    G.Name                             as groupname,
                    G.Description                      as description,                    
                    ltrim(rtrim(G.DiscAllocationCode)) as discallocationcode,                    
                    coalesce(G.Sites,0)                as sites,
                    coalesce(G.units,0)                as units, 
                    coalesce(G.beds,0)                 as beds,  
                    coalesce(G.ppupercentage,100)      as ppupercentage,
                    G.ILFDiscountAmount                as ilfdiscountamount,
                    G.ILFDiscountPercent               as ilfdiscountpercent,
                    G.AccessDiscountAmount             as accessdiscountamount,
                    G.AccessDiscountPercent            as accessdiscountpercent,                     
                    coalesce(G.showdetailpriceflag,0)                        as showdetailpriceflag,                    
                    coalesce(G.allowproductcancelflag,1)                     as allowproductcancelflag,
                    coalesce(G.grouptype,'SITE')                             as grouptype,
                    coalesce(G.custombundlenameenabledflag,0)                as custombundlenameenabledflag,  
                    coalesce(G.autofulfillilfflag,1)                         as autofulfillilfflag,
                    coalesce(G.autofulfillacsancflag,0)                      as autofulfillacsancflag,
					coalesce(G.autofulfillstartdate,'1900-01-01')			as autofulfillstartdate,
                    ''                                                       as internalgroupid
    from  QUOTES.dbo.[Group] G (nolock) 
    where G.IDSeq      = @IPI_GroupID 
    and   G.QuoteIDSeq = @IPVC_quoteid    
  end  
  else 
  begin
    insert into @LT_GroupDetails(companyid,quoteid,groupid,groupname,description,discallocationcode,
                                 sites,units,beds,ppupercentage,
                                 ilfdiscountamount,ilfdiscountpercent,
                                 accessdiscountamount,accessdiscountpercent,
                                 showdetailpriceflag,
                                 allowproductcancelflag,
                                 grouptype,custombundlenameenabledflag,
                                 autofulfillilfflag,autofulfillacsancflag,autofulfillstartdate,
                                 internalgroupid)
    select @IPC_CompanyID as companyid,@IPVC_quoteid as quoteid,@IPI_GroupID as groupid,'' as groupname,''as description,
           'IND'   as discallocationcode,0 as sites,0 as units,0 as beds,100 as ppupercentage,
           0.00    as ilfdiscountamount ,0.00 as ilfdiscountpercent,
           0.00    as accessdiscountamount,0.00 as accessdiscountpercent,           
           0       as showdetailpriceflag,          
           1       as allowproductcancelflag,
           'SITE'  as grouptype,0 as custombundlenameenabledflag,
           1       as autofulfillilfflag,
           0       as autofulfillacsancflag,
		'1900-01-01' as autofulfillstartdate,
           newid() as internalgroupid
  end
  ----------------------------------------------------------------------------
  -- Final Select 
  ----------------------------------------------------------------------------
  if @IPVC_RETURNTYPE  = 'XML'
  begin
    select companyid,quoteid,groupid,groupname,description,discallocationcode,
           sites,units,beds,ppupercentage,
           ilfdiscountpercent,Quotes.DBO.fn_FormatCurrency(ilfdiscountpercent,1,2) as displayilfdiscountpercent,
           ilfdiscountamount,Quotes.DBO.fn_FormatCurrency(ilfdiscountamount,1,2) as displayilfdiscountamount,
           accessdiscountpercent,Quotes.DBO.fn_FormatCurrency(accessdiscountpercent,1,2) as displayaccessdiscountpercent,
           accessdiscountamount,Quotes.DBO.fn_FormatCurrency(accessdiscountamount,1,2) as displayaccessdiscountamount,
           showdetailpriceflag,
           allowproductcancelflag,
           grouptype,custombundlenameenabledflag,
           autofulfillilfflag,autofulfillacsancflag,autofulfillstartdate,
           internalgroupid
    from @LT_GroupDetails FOR XML raw ,ROOT('groupmaster'), TYPE  
  end
  else
  begin
    select companyid,quoteid,groupid,groupname,description,discallocationcode,
           sites,units,beds,ppupercentage,
           ilfdiscountpercent,Quotes.DBO.fn_FormatCurrency(ilfdiscountpercent,1,2) as displayilfdiscountpercent,
           ilfdiscountamount,Quotes.DBO.fn_FormatCurrency(ilfdiscountamount,1,2) as displayilfdiscountamount,
           accessdiscountpercent,Quotes.DBO.fn_FormatCurrency(accessdiscountpercent,1,2) as displayaccessdiscountpercent,
           accessdiscountamount,Quotes.DBO.fn_FormatCurrency(accessdiscountamount,1,2) as displayaccessdiscountamount,
           showdetailpriceflag,
           allowproductcancelflag,
           grouptype,custombundlenameenabledflag,
           autofulfillilfflag,autofulfillacsancflag,autofulfillstartdate,
           internalgroupid
    from @LT_GroupDetails
  end  
  ----------------------------------------------------------------------------
END
GO
