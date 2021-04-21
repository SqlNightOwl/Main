SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Exec CUSTOMERS.dbo.uspCUSTOMERS_ValidateCompanySiteMasterID @IPVC_SiteMasterID='1069454',@IPVC_CompanyName='Sheltering Palms Foundation Inc',
@IPVC_AddressLine1 = '9045 La Fontana Blvd Ste C-12',@IPVC_City = 'Boca Raton',@IPVC_State='FL',@IPVC_Zip='33434-5636'

Exec CUSTOMERS.dbo.uspCUSTOMERS_ValidateCompanySiteMasterID @IPVC_SiteMasterID='999999',@IPVC_CompanyName='Sheltering Palms Foundation Inc',
@IPVC_AddressLine1 = '9045 La Fontana Blvd Ste C-12',@IPVC_City = 'Boca Raton',@IPVC_State='FL',@IPVC_Zip='33434-5636'

Exec CUSTOMERS.dbo.uspCUSTOMERS_ValidateCompanySiteMasterID @IPVC_SiteMasterID='',@IPVC_CompanyName='Sheltering Palms Foundation Inc',
@IPVC_AddressLine1 = '9045 La Fontana Blvd Ste C-12',@IPVC_City = 'Boca Raton',@IPVC_State='FL',@IPVC_Zip='33434-5636'

Exec CUSTOMERS.dbo.uspCUSTOMERS_ValidateCompanySiteMasterID @IPVC_SiteMasterID='',@IPVC_CompanyName='Palms Foundation Inc',
@IPVC_AddressLine1 = '9045 La Fontana Blvd Ste C-12',@IPVC_City = 'Boca Raton',@IPVC_State='FL',@IPVC_Zip='33434-5636'

*/

----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_ValidateCompanySiteMasterID
-- Description     : Validate Company SiteMasterID with OneSite SITEMANAGER.dbo.Entity 
--                      based on the parameters passed
-- Source          : RPIDALPRM400.SITEMANAGER.dbo.Entity is available as View Customers.dbo.Entity
-- Input Parameters: 
--                   
-- OUTPUT          : 
-- Code Example    : Exec CUSTOMERS.dbo.[uspCUSTOMERS_ValidateCompanySiteMasterID] input parameters
--                                                             
-- Revision History:
-- Author          : SRS
-- 06/18/2010      : LWW-Add OMS Company ID to final result set, where any exists. (PCR 7783)
-- 07/31/2008      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_ValidateCompanySiteMasterID] (@IPVC_SiteMasterID  varchar(50) ='',
                                                                   @IPVC_CompanyName   varchar(500),
                                                                   @IPVC_AddressLine1  varchar(255),
                                                                   @IPVC_City          varchar(255),
                                                                   @IPVC_State         varchar(255),
                                                                   @IPVC_Zip           varchar(255)
                                                                  )
AS
BEGIN-->Main Begin
  set nocount on;
  -----------------------------------------
  set @IPVC_SiteMasterID = nullif(@IPVC_SiteMasterID,'')
  -----------------------------------------
  Create table #temp_EntitySearchvalues(IDSeq          int not null identity(1,1),
                                        SiteMasterID   varchar(50),
                                        OneSiteStatus  varchar(50),
                                        [Name]         varchar(500),
                                        AddressLine1   varchar(255),
                                        City           varchar(255),
                                        State          varchar(255),
                                        Zip            varchar(50),
                                        Message        varchar(4000),
                                        MessageFlag    int
                                       )
  -----------------------------------------
  ---Exact Match
  if exists(select top 1 1 from Customers.dbo.Entity with (nolock)
            where  convert(varchar(50),entID) = @IPVC_SiteMasterID
            and    ltrim(rtrim(entname))      = ltrim(rtrim(@IPVC_CompanyName))
            and    ltrim(rtrim(entAddress1))  = ltrim(rtrim(@IPVC_AddressLine1))
            and    ltrim(rtrim(entCityName))  = ltrim(rtrim(@IPVC_City))
            and    ltrim(rtrim(entState))     = ltrim(rtrim(@IPVC_State))
            and    ltrim(rtrim(entZip))       = ltrim(rtrim(@IPVC_Zip))
           )
  begin
    insert into #temp_EntitySearchvalues(SiteMasterID,OneSiteStatus,[Name],AddressLine1,City,State,Zip,Message,MessageFlag)
    select convert(varchar(50),entID) as SiteMasterID,ltrim(rtrim(codePMCStatusCode)) as OneSiteStatus,
           ltrim(rtrim(entname))      as [Name],
           ltrim(rtrim(entAddress1))  as AddressLine1,ltrim(rtrim(entCityName)) as City,
           ltrim(rtrim(entState))     as State,ltrim(rtrim(entZip)) as Zip,
           'Exact match'        as Message,0 as MessageFlag
    from Customers.dbo.Entity with (nolock)
    where  convert(varchar(50),entID) = @IPVC_SiteMasterID
    and    ltrim(rtrim(entname))      = ltrim(rtrim(@IPVC_CompanyName))
    and    ltrim(rtrim(entAddress1))  = ltrim(rtrim(@IPVC_AddressLine1))
    and    ltrim(rtrim(entCityName))  = ltrim(rtrim(@IPVC_City))
    and    ltrim(rtrim(entState))     = ltrim(rtrim(@IPVC_State))
    and    ltrim(rtrim(entZip))       = ltrim(rtrim(@IPVC_Zip))
 
    select S.SiteMasterID,S.[Name] as [Name],S.OneSiteStatus,S.AddressLine1,S.City,S.State,S.Zip,S.Message,S.MessageFlag
		,p.[IDSeq] as [OMSPropertyID]
    from   #temp_EntitySearchvalues S with (nolock)
	LEFT OUTER JOIN [dbo].[Company] p with (nolock) on p.[SiteMasterID]=S.SiteMasterID
    if (object_id('tempdb.dbo.#temp_EntitySearchvalues') is not null) 
    begin
      drop table #temp_EntitySearchvalues
    end;     
    RETURN;
  end
  else
  begin
    insert into #temp_EntitySearchvalues(SiteMasterID,OneSiteStatus,[Name],AddressLine1,City,State,Zip,Message,MessageFlag)
    select '' as SiteMasterID,NULL        as OneSiteStatus,
           ltrim(rtrim(@IPVC_CompanyName))  as [Name],
           ltrim(rtrim(@IPVC_AddressLine1)) as AddressLine1,ltrim(rtrim(@IPVC_City)) as City,
           ltrim(rtrim(@IPVC_State))        as State,ltrim(rtrim(@IPVC_Zip)) as Zip,
           'No Match',2 as MessageFlag    
  end
  -----------------------------------------
  ---Possible Recommendations
  -----------------------------------------  
  begin
    insert into #temp_EntitySearchvalues(SiteMasterID,OneSiteStatus,[Name],AddressLine1,City,State,Zip,Message,MessageFlag)
    select convert(varchar(50),entID)   as SiteMasterID,ltrim(rtrim(codePMCStatusCode)) as OneSiteStatus,
           ltrim(rtrim(entname))        as [Name],
           ltrim(rtrim(entAddress1))    as AddressLine1,ltrim(rtrim(entCityName)) as City,
           ltrim(rtrim(entState))       as State,ltrim(rtrim(entZip)) as Zip,
           'Partial Match (Name and Address,City,State,partial Zip)'  as Message,1 as MessageFlag
    from Customers.dbo.Entity with (nolock)
    where  ltrim(rtrim(entname))      = ltrim(rtrim(@IPVC_CompanyName))
    and    ltrim(rtrim(entAddress1))  = ltrim(rtrim(@IPVC_AddressLine1))
    and    ltrim(rtrim(entCityName))  = ltrim(rtrim(@IPVC_City))
    and    ltrim(rtrim(entState))     = ltrim(rtrim(@IPVC_State))
    and    (
            ltrim(rtrim(entZip))       = ltrim(rtrim(@IPVC_Zip))
             OR
            ltrim(rtrim(substring(entZip,1,5))) = ltrim(rtrim(substring(@IPVC_Zip,1,5)))  
            )
    --------------------------------------------------------------------------------
    insert into #temp_EntitySearchvalues(SiteMasterID,OneSiteStatus,[Name],AddressLine1,City,State,Zip,Message,MessageFlag)
    select convert(varchar(50),entID)   as SiteMasterID,ltrim(rtrim(codePMCStatusCode)) as OneSiteStatus,
           ltrim(rtrim(entname))        as [Name],
           ltrim(rtrim(entAddress1))    as AddressLine1,ltrim(rtrim(entCityName)) as City,
           ltrim(rtrim(entState))       as State,ltrim(rtrim(entZip)) as Zip,
           'Partial Match (Partial Name and Address,City,State,partial Zip)'  as Message,1 as MessageFlag
    from Customers.dbo.Entity with (nolock)
    where (
            (charindex(ltrim(rtrim(entname)),ltrim(rtrim(@IPVC_CompanyName))) > 0
                OR
             charindex(ltrim(rtrim(@IPVC_CompanyName)),ltrim(rtrim(entname))) > 0
            )
            OR              
            (charindex(substring(ltrim(rtrim(entname)),1,10),ltrim(rtrim(@IPVC_CompanyName))) > 0
                OR
             charindex(substring(ltrim(rtrim(@IPVC_CompanyName)),1,10),ltrim(rtrim(entname))) > 0
            )
          )
    and    ltrim(rtrim(entAddress1))  = ltrim(rtrim(@IPVC_AddressLine1))
    and    ltrim(rtrim(entCityName))  = ltrim(rtrim(@IPVC_City))
    and    ltrim(rtrim(entState))     = ltrim(rtrim(@IPVC_State))
    and    (
            ltrim(rtrim(entZip))       = ltrim(rtrim(@IPVC_Zip))
             OR
            ltrim(rtrim(substring(entZip,1,5))) = ltrim(rtrim(substring(@IPVC_Zip,1,5)))  
            )
    --------------------------------------------------------------------------------
    insert into #temp_EntitySearchvalues(SiteMasterID,OneSiteStatus,[Name],AddressLine1,City,State,Zip,Message,MessageFlag)
    select convert(varchar(50),entID)   as SiteMasterID,ltrim(rtrim(codePMCStatusCode)) as OneSiteStatus,
           ltrim(rtrim(entname))        as [Name],
           ltrim(rtrim(entAddress1))    as AddressLine1,ltrim(rtrim(entCityName)) as City,
           ltrim(rtrim(entState))       as State,ltrim(rtrim(entZip)) as Zip,
           'Partial Match (Address1,City,State,partial Zip)'  as Message,1 as MessageFlag
    from Customers.dbo.Entity with (nolock)
    where  ltrim(rtrim(entAddress1))  = ltrim(rtrim(@IPVC_AddressLine1))
    and    ltrim(rtrim(entCityName))  = ltrim(rtrim(@IPVC_City))
    and    ltrim(rtrim(entState))     = ltrim(rtrim(@IPVC_State))
    and    (
           ltrim(rtrim(entZip))       = ltrim(rtrim(@IPVC_Zip))
             OR
           ltrim(rtrim(substring(entZip,1,5))) = ltrim(rtrim(substring(@IPVC_Zip,1,5)))  
           )  
    --------------------------------------------------------------------------------
    insert into #temp_EntitySearchvalues(SiteMasterID,OneSiteStatus,[Name],AddressLine1,City,State,Zip,Message,MessageFlag)
    select convert(varchar(50),entID)   as SiteMasterID,ltrim(rtrim(codePMCStatusCode)) as OneSiteStatus,
           ltrim(rtrim(entname))        as [Name],
           ltrim(rtrim(entAddress1))    as AddressLine1,ltrim(rtrim(entCityName)) as City,
           ltrim(rtrim(entState))       as State,ltrim(rtrim(entZip)) as Zip,
           'Partial Match (Partial name and SiteMasterID)'  as Message,1 as MessageFlag
    from Customers.dbo.Entity with (nolock)
    where convert(varchar(50),entID) = @IPVC_SiteMasterID
    and   (charindex(ltrim(rtrim(entname)),ltrim(rtrim(@IPVC_CompanyName))) > 0
             OR
           charindex(ltrim(rtrim(@IPVC_CompanyName)),ltrim(rtrim(entname))) > 0
          )
    --------------------------------------------------------------------------------
    insert into #temp_EntitySearchvalues(SiteMasterID,OneSiteStatus,[Name],AddressLine1,City,State,Zip,Message,MessageFlag)    
    select convert(varchar(50),entID)   as SiteMasterID,ltrim(rtrim(codePMCStatusCode)) as OneSiteStatus,
           ltrim(rtrim(entname))        as [Name],
           ltrim(rtrim(entAddress1))    as AddressLine1,ltrim(rtrim(entCityName)) as City,
           ltrim(rtrim(entState))       as State,ltrim(rtrim(entZip)) as Zip,
           'Partial Match (Partial Name,City,State,partial Zip)'  as Message,1 as MessageFlag
    from Customers.dbo.Entity with (nolock)
    where  (
            (charindex(ltrim(rtrim(entname)),ltrim(rtrim(@IPVC_CompanyName))) > 0
                OR
             charindex(ltrim(rtrim(@IPVC_CompanyName)),ltrim(rtrim(entname))) > 0
            )
            OR              
            (charindex(substring(ltrim(rtrim(entname)),1,10),ltrim(rtrim(@IPVC_CompanyName))) > 0
                OR
             charindex(substring(ltrim(rtrim(@IPVC_CompanyName)),1,10),ltrim(rtrim(entname))) > 0
            )
          )
    and    ltrim(rtrim(entCityName))  = ltrim(rtrim(@IPVC_City))
    and    ltrim(rtrim(entState))     = ltrim(rtrim(@IPVC_State))
    and    (
            ltrim(rtrim(entZip))       = ltrim(rtrim(@IPVC_Zip))
             OR
            ltrim(rtrim(substring(entZip,1,5))) = ltrim(rtrim(substring(@IPVC_Zip,1,5)))  
            )
    --------------------------------------------------------------------------------
    insert into #temp_EntitySearchvalues(SiteMasterID,OneSiteStatus,[Name],AddressLine1,City,State,Zip,Message,MessageFlag)    
    select convert(varchar(50),entID)   as SiteMasterID,ltrim(rtrim(codePMCStatusCode)) as OneSiteStatus,
           ltrim(rtrim(entname))        as [Name],
           ltrim(rtrim(entAddress1))    as AddressLine1,ltrim(rtrim(entCityName)) as City,
           ltrim(rtrim(entState))       as State,ltrim(rtrim(entZip)) as Zip,
           'Partial Match (Partial Name,City,State)'  as Message,1 as MessageFlag
    from Customers.dbo.Entity with (nolock)
    where  (
            (charindex(ltrim(rtrim(entname)),ltrim(rtrim(@IPVC_CompanyName))) > 0
                OR
             charindex(ltrim(rtrim(@IPVC_CompanyName)),ltrim(rtrim(entname))) > 0
            )
            OR              
            (charindex(substring(ltrim(rtrim(entname)),1,10),ltrim(rtrim(@IPVC_CompanyName))) > 0
                OR
             charindex(substring(ltrim(rtrim(@IPVC_CompanyName)),1,10),ltrim(rtrim(entname))) > 0
            )
          )
    and    ltrim(rtrim(entCityName))  = ltrim(rtrim(@IPVC_City))
    and    ltrim(rtrim(entState))     = ltrim(rtrim(@IPVC_State))    
    ------------------------------------------------------------------------  
  end
  -------------------------------------------------------------------------
  ---Final Select 
  -------------------------------------------------------------------------   
  select S.SiteMasterID,S.[Name] as [Name],S.OneSiteStatus,S.AddressLine1,S.City,S.State,S.Zip,S.Message,S.MessageFlag
		,p.[IDSeq] as [OMSPropertyID]
  from   #temp_EntitySearchvalues S with (nolock)
  LEFT OUTER JOIN [dbo].[Company] p with (nolock) on p.[SiteMasterID]=S.SiteMasterID
  where  S.IDSeq <= (select Min(D.IDSeq) 
                     from   #temp_EntitySearchvalues D with (nolock)
                     where  D.Sitemasterid = S.SitemasterID
                    )
  order by S.OneSiteStatus ASC
  ------------------------------------------------------------------------- 
  if (object_id('tempdb.dbo.#temp_EntitySearchvalues') is not null) 
  begin
    drop table #temp_EntitySearchvalues
  end; 
  -------------------------------------------------------------------------
END  
GO
