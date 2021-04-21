SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Exec CUSTOMERS.dbo.uspCUSTOMERS_ValidatePropertySITEMANAGERID @IPVC_SiteMasterID='1058223',@IPVC_PropertyName='05-BASE STUHR GARDENS',
@IPVC_AddressLine1 = '5 W MAIN ST STE 214',@IPVC_City='ELMSFORD',@IPVC_State='NY',@IPVC_Zip='10523-2437'

Exec CUSTOMERS.dbo.uspCUSTOMERS_ValidatePropertySITEMANAGERID @IPVC_SiteMasterID='99999999',@IPVC_PropertyName='05-BASE STUHR GARDENS',
@IPVC_AddressLine1 = '5 W MAIN ST STE 214',@IPVC_City='ELMSFORD',@IPVC_State='NY',@IPVC_Zip='10523-2437'


Exec CUSTOMERS.dbo.uspCUSTOMERS_ValidatePropertySITEMANAGERID @IPVC_SiteMasterID='',@IPVC_PropertyName='05-BASE STUHR GARDENS',
@IPVC_AddressLine1 = '5 W MAIN ST STE 214',@IPVC_City='ELMSFORD',@IPVC_State='NY',@IPVC_Zip='10523-2437'


Exec CUSTOMERS.dbo.uspCUSTOMERS_ValidatePropertySITEMANAGERID @IPVC_SiteMasterID='1058223',@IPVC_PropertyName='ABCD-BASE STUHR GARDENS',
@IPVC_AddressLine1 = '5 W MAIN ST STE 214',@IPVC_City='ELMSFORD',@IPVC_State='NY',@IPVC_Zip='10523-2437'
                         
*/                                                  

----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_ValidatePropertySITEMANAGERID
-- Description     : Validate Property SiteMaster with OneSite SITEMANAGER.dbo.SiteProfile 
--                      based on the parameters passed
-- Input Parameters: 
--                   
-- OUTPUT          : 
-- Code Example    : Exec CUSTOMERS.dbo.[uspCUSTOMERS_ValidatePropertySITEMANAGERID] input parameters
--                                                             
-- Revision History:
-- Author          : SRS
-- 07/31/2008      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_ValidatePropertySITEMANAGERID] (@IPVC_SiteMasterID  varchar(50) ='',
                                                                     @IPVC_PropertyName  varchar(500),
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
  Create table #temp_PropertySearchvalues(IDSeq          int not null identity(1,1),
                                          SiteMasterID   varchar(50),
                                          OneSiteStatus  varchar(50),
                                          [Name]    varchar(500),
                                          AddressLine1   varchar(255),
                                          City           varchar(255),
                                          State          varchar(255),
                                          Zip            varchar(50),
                                          Message        varchar(4000),
                                          MessageFlag    int
                                         )
  -----------------------------------------
  ---Exact Match
  if exists(select top 1 1 from Customers.dbo.SiteProfile with (nolock)
            where  convert(varchar(50),siteID) = @IPVC_SiteMasterID
            and    ltrim(rtrim(siteName))      = ltrim(rtrim(@IPVC_PropertyName))
            and    ltrim(rtrim(siteAddress1))  = ltrim(rtrim(@IPVC_AddressLine1))
            and    ltrim(rtrim(siteCityName))  = ltrim(rtrim(@IPVC_City))
            and    ltrim(rtrim(siteState))     = ltrim(rtrim(@IPVC_State))
            and    ltrim(rtrim(siteZip))       = ltrim(rtrim(@IPVC_Zip))
           )
  begin
    insert into #temp_PropertySearchvalues(SiteMasterID,OneSiteStatus,[Name],AddressLine1,City,State,Zip,Message,MessageFlag)
    select convert(varchar(50),siteID) as SiteMasterID,ltrim(rtrim(codeSiteStatusCode)) as OneSiteStatus,
           ltrim(rtrim(siteName))      as [Name],
           ltrim(rtrim(siteAddress1))  as AddressLine1,ltrim(rtrim(siteCityName)) as City,
           ltrim(rtrim(siteState))     as State,ltrim(rtrim(siteZip)) as Zip,
           'Exact match'        as Message,0 as MessageFlag
    from Customers.dbo.SiteProfile with (nolock)
    where  convert(varchar(50),siteID) = @IPVC_SiteMasterID
    and    ltrim(rtrim(siteName))      = ltrim(rtrim(@IPVC_PropertyName))
    and    ltrim(rtrim(siteAddress1))  = ltrim(rtrim(@IPVC_AddressLine1))
    and    ltrim(rtrim(siteCityName))  = ltrim(rtrim(@IPVC_City))
    and    ltrim(rtrim(siteState))     = ltrim(rtrim(@IPVC_State))
    and    ltrim(rtrim(siteZip))       = ltrim(rtrim(@IPVC_Zip))
 
    select SiteMasterID,[Name] as [Name],AddressLine1,City,State,Zip,Message,MessageFlag
    from   #temp_PropertySearchvalues with (nolock)
    drop table #temp_PropertySearchvalues
    RETURN
  end
  else
  begin
    insert into #temp_PropertySearchvalues(SiteMasterID,OneSiteStatus,[Name],AddressLine1,City,State,Zip,Message,MessageFlag)
    select '' as SiteMasterID,NULL        as OneSiteStatus,
           ltrim(rtrim(@IPVC_PropertyName))  as [Name],
           ltrim(rtrim(@IPVC_AddressLine1)) as AddressLine1,ltrim(rtrim(@IPVC_City)) as City,
           ltrim(rtrim(@IPVC_State))        as State,ltrim(rtrim(@IPVC_Zip)) as Zip,
           'No Match',2 as MessageFlag    
  end
  -----------------------------------------
  ---Possible Recommendations
  -----------------------------------------  
  begin
    insert into #temp_PropertySearchvalues(SiteMasterID,OneSiteStatus,[Name],AddressLine1,City,State,Zip,Message,MessageFlag)
    select convert(varchar(50),siteID)   as SiteMasterID,ltrim(rtrim(codeSiteStatusCode)) as OneSiteStatus,
           ltrim(rtrim(siteName))        as [Name],
           ltrim(rtrim(siteAddress1))    as AddressLine1,ltrim(rtrim(siteCityName)) as City,
           ltrim(rtrim(siteState))       as State,ltrim(rtrim(siteZip)) as Zip,
           'Partial Match (Name and Address,City,State,partial Zip)'  as Message,1 as MessageFlag
    from Customers.dbo.SiteProfile with (nolock)
    where  ltrim(rtrim(siteName))      = ltrim(rtrim(@IPVC_PropertyName))
    and    ltrim(rtrim(siteAddress1))  = ltrim(rtrim(@IPVC_AddressLine1))
    and    ltrim(rtrim(siteCityName))  = ltrim(rtrim(@IPVC_City))
    and    ltrim(rtrim(siteState))     = ltrim(rtrim(@IPVC_State))
    and    (
            ltrim(rtrim(siteZip))       = ltrim(rtrim(@IPVC_Zip))
             OR
            ltrim(rtrim(substring(siteZip,1,5))) = ltrim(rtrim(substring(@IPVC_Zip,1,5)))  
            )
    --------------------------------------------------------------------------------
    insert into #temp_PropertySearchvalues(SiteMasterID,OneSiteStatus,[Name],AddressLine1,City,State,Zip,Message,MessageFlag)
    select convert(varchar(50),siteID)   as SiteMasterID,ltrim(rtrim(codeSiteStatusCode)) as OneSiteStatus,
           ltrim(rtrim(siteName))        as [Name],
           ltrim(rtrim(siteAddress1))    as AddressLine1,ltrim(rtrim(siteCityName)) as City,
           ltrim(rtrim(siteState))       as State,ltrim(rtrim(siteZip)) as Zip,
           'Partial Match (Partial Name and Address,City,State,partial Zip)'  as Message,1 as MessageFlag
    from Customers.dbo.SiteProfile with (nolock)
    where (charindex(ltrim(rtrim(siteName)),ltrim(rtrim(@IPVC_PropertyName))) > 0
                OR
           charindex(ltrim(rtrim(@IPVC_PropertyName)),ltrim(rtrim(siteName))) > 0
          )
    and    ltrim(rtrim(siteAddress1))  = ltrim(rtrim(@IPVC_AddressLine1))
    and    ltrim(rtrim(siteCityName))  = ltrim(rtrim(@IPVC_City))
    and    ltrim(rtrim(siteState))     = ltrim(rtrim(@IPVC_State))
    and    (
            ltrim(rtrim(siteZip))       = ltrim(rtrim(@IPVC_Zip))
             OR
            ltrim(rtrim(substring(siteZip,1,5))) = ltrim(rtrim(substring(@IPVC_Zip,1,5)))  
            )
    --------------------------------------------------------------------------------
    insert into #temp_PropertySearchvalues(SiteMasterID,OneSiteStatus,[Name],AddressLine1,City,State,Zip,Message,MessageFlag)
    select convert(varchar(50),siteID)   as SiteMasterID,ltrim(rtrim(codeSiteStatusCode)) as OneSiteStatus,
           ltrim(rtrim(siteName))        as [Name],
           ltrim(rtrim(siteAddress1))    as AddressLine1,ltrim(rtrim(siteCityName)) as City,
           ltrim(rtrim(siteState))       as State,ltrim(rtrim(siteZip)) as Zip,
           'Partial Match (Address1,City,State,partial Zip)'  as Message,1 as MessageFlag
    from Customers.dbo.SiteProfile with (nolock)
    where  ltrim(rtrim(siteAddress1))  = ltrim(rtrim(@IPVC_AddressLine1))
    and    ltrim(rtrim(siteCityName))  = ltrim(rtrim(@IPVC_City))
    and    ltrim(rtrim(siteState))     = ltrim(rtrim(@IPVC_State))
    and    (
           ltrim(rtrim(siteZip))       = ltrim(rtrim(@IPVC_Zip))
             OR
           ltrim(rtrim(substring(siteZip,1,5))) = ltrim(rtrim(substring(@IPVC_Zip,1,5)))  
           )  
    --------------------------------------------------------------------------------
    insert into #temp_PropertySearchvalues(SiteMasterID,OneSiteStatus,[Name],AddressLine1,City,State,Zip,Message,MessageFlag)
    select convert(varchar(50),siteID)   as SiteMasterID,ltrim(rtrim(codeSiteStatusCode)) as OneSiteStatus,
           ltrim(rtrim(siteName))        as [Name],
           ltrim(rtrim(siteAddress1))    as AddressLine1,ltrim(rtrim(siteCityName)) as City,
           ltrim(rtrim(siteState))       as State,ltrim(rtrim(siteZip)) as Zip,
           'Partial Match (Partial name and SiteMasterID)'  as Message,1 as MessageFlag
    from Customers.dbo.SiteProfile with (nolock)
    where convert(varchar(50),siteID) = @IPVC_SiteMasterID
    and   (charindex(ltrim(rtrim(siteName)),ltrim(rtrim(@IPVC_PropertyName))) > 0
             OR
           charindex(ltrim(rtrim(@IPVC_PropertyName)),ltrim(rtrim(siteName))) > 0
          )
    --------------------------------------------------------------------------------
    insert into #temp_PropertySearchvalues(SiteMasterID,OneSiteStatus,[Name],AddressLine1,City,State,Zip,Message,MessageFlag)    
    select convert(varchar(50),siteID)   as SiteMasterID,ltrim(rtrim(codeSiteStatusCode)) as OneSiteStatus,
           ltrim(rtrim(siteName))        as [Name],
           ltrim(rtrim(siteAddress1))    as AddressLine1,ltrim(rtrim(siteCityName)) as City,
           ltrim(rtrim(siteState))       as State,ltrim(rtrim(siteZip)) as Zip,
           'Partial Match (Partial Name,City,State,partial Zip)'  as Message,1 as MessageFlag
    from Customers.dbo.SiteProfile with (nolock)
    where  (charindex(ltrim(rtrim(siteName)),ltrim(rtrim(@IPVC_PropertyName))) > 0
             OR
            charindex(ltrim(rtrim(@IPVC_PropertyName)),ltrim(rtrim(siteName))) > 0
           )
    and    ltrim(rtrim(siteCityName))  = ltrim(rtrim(@IPVC_City))
    and    ltrim(rtrim(siteState))     = ltrim(rtrim(@IPVC_State))
    and    (
            ltrim(rtrim(siteZip))       = ltrim(rtrim(@IPVC_Zip))
             OR
            ltrim(rtrim(substring(siteZip,1,5))) = ltrim(rtrim(substring(@IPVC_Zip,1,5)))  
            )
    --------------------------------------------------------------------------------
    insert into #temp_PropertySearchvalues(SiteMasterID,OneSiteStatus,[Name],AddressLine1,City,State,Zip,Message,MessageFlag)    
    select convert(varchar(50),siteID)   as SiteMasterID,ltrim(rtrim(codeSiteStatusCode)) as OneSiteStatus,
           ltrim(rtrim(siteName))        as [Name],
           ltrim(rtrim(siteAddress1))    as AddressLine1,ltrim(rtrim(siteCityName)) as City,
           ltrim(rtrim(siteState))       as State,ltrim(rtrim(siteZip)) as Zip,
           'Partial Match (Partial Name,City,State)'  as Message,1 as MessageFlag
    from Customers.dbo.SiteProfile with (nolock)
    where  (charindex(ltrim(rtrim(siteName)),ltrim(rtrim(@IPVC_PropertyName))) > 0
             OR
            charindex(ltrim(rtrim(@IPVC_PropertyName)),ltrim(rtrim(siteName))) > 0
           )
    and    ltrim(rtrim(siteCityName))  = ltrim(rtrim(@IPVC_City))
    and    ltrim(rtrim(siteState))     = ltrim(rtrim(@IPVC_State))    
    --------------------------------------------------------------------------------      
  end
  -------------------------------------------------------------------------
  ---Final Select 
select * from #temp_PropertySearchvalues
  -------------------------------------------------------------------------   
  select S.SiteMasterID,S.[Name] as [Name],S.OneSiteStatus,S.AddressLine1,S.City,S.State,S.Zip,S.Message,S.MessageFlag
  from   #temp_PropertySearchvalues S with (nolock)
  where  S.IDSeq <= (select Min(D.IDSeq) 
                     from   #temp_PropertySearchvalues D with (nolock)
                     where  D.Sitemasterid = S.SitemasterID
                    )
  ------------------------------------------------------------------------- 
  drop table #temp_PropertySearchvalues  
END  

GO
