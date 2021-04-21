SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_AccountDetails
-- Description     : This procedure gets Account Details pertaining to passed AccountID
-- Input Parameters: 1. @IPI_AccountID   as integer
-- 
-- OUTPUT          : RecordSet of ID,Account Name,CustomerSince,PMCFlag,OwnerFalg,
--                                ComAddr1,ComAddr2,ComCity,ComState,ComZip,ComPhone,URL,
--                                SiebelID,SiteMasterID,EpicorID,CSTAddr1,CSTAddr2,CSTCity,
--                                CSTState,CSTZip,CBTAddr1,CBTAddr2,CBTCity,CBTState,CBTZip,
--                                TaxCreditFlag,StudentLivingFlag,HUDFlag,
--                                RHSFlag,RetailFlag,MilitaryPrivatizedFlag,GSAEntityFlag,SeniorLivingFlag,AccountTypeCode
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_AccountDetails @IPI_AccountID  =1
-- 

-- Revision History:
-- Author          : SRA Systems
-- 11/22/2006      : Stored Procedure Created.
-- 11/28/2006      : Changed by STA. Changed Variable Names.
-- 11/29/2006      : Changed by STA. Changed the spelling of OwnerFlag in line no. 57.
-- 04/28/2008      : Naval Kishore Modified Siebel ID
-- 05/20/2009	   : Naval kishore Modified to get Country Info for other countries. 
-- 09/07/2010	   : Naval kishore Modified to get CompanyStatus. Defect # 8211 
-- 11/04/2010	   : Damodar Nethunuri Modified to get RetailFlag,MilitaryPrivatizedFlag,GSAEntityFlag,SeniorLivingFlag. Defect # 8621
-- 08/30/2011      : Mahaboob modified to include "VendorFlag" of Company Table in result set.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_AccountDetails]
	(@IPI_AccountID varchar(50),
     @IPVC_OrderID varchar(50))


AS
BEGIN
  ----------------------------------------------------------------------------
  --Local Variable Declaration
  ----------------------------------------------------------------------------
  declare @LVC_PropertyID    varchar(20)
  declare @LVC_CompanyID     varchar(20)
  ----------------------------------------------------------------------------
  -- Select PropertyIDSeq into local variable @LVC_PropertyID,
  -- CompanyIDSeq into local variable @LVC_CompanyID 
  -- for the passed Input variable @IPI_AccountID
  select @LVC_PropertyID = PropertyIDSeq, @LVC_CompanyID = CompanyIDSeq
  from   Account
  where  IDSeq = @IPI_AccountID
  ----------------------------------------------------------------------------    
  if @LVC_PropertyID IS NULL
  begin
    ----------------------------------------------------------------------------    
    -- If @LVC_PropertyID is NULL then get CompanyName as AccountName
    -- from CUSTOMERS.DBO.Company for @IPI_AccountID
    ----------------------------------------------------------------------------    
      select @LVC_CompanyID                           as ID,
           
    isnull((select count(*)  as [rowcount]
    from (select distinct(select top 1 P.DisplayName  
                          from   Products.dbo.Product P (nolock) 
                          where  P.code = o.productcode
                          and    P.PriceVersion = o.PriceVersion
                          )   as [Name]
                          from   Orders.dbo.[OrderItem] o (nolock) 
                          where o.OrderIDSeq like '%' + @IPVC_OrderID + '%'
                         ) tbl 
    where   tbl.[Name] ='Premium Support' ),0)      as [rowcount],
           @LVC_CompanyID                           as CompanyIDSeq, 
           c.Name                                   as [Name], 
           c.Name                                   as CompanyName, 
           convert(varchar(10), c.CreatedDate, 101) as CustomerSince, 
           PMCFlag                                  as PMCFlag, 
           OwnerFlag                                as OwnerFlag, 
		   c.VendorFlag								as Vendor,
           aCOM.AddressLine1                        as ComAddr1, 
           aCOM.AddressLine2                        as ComAddr2, 
           aCOM.City                                as ComCity, 
           aCOM.State                               as ComState, 
           aCOM.Zip                                 as ComZip,
		   ISNULL(UPPER(cs.[Name]),'') as ComCountry,
          
           ltrim(rtrim(aCOM.PhoneVoice1))           as ComPhone,
           ltrim(rtrim(aCOM.PhoneVoiceExt1))        as ComExt,    
	       ltrim(rtrim(aCOM.PhoneFax))              as ComFax,
           ltrim(rtrim(aCOM.PhoneVoice4))           as ComCell,    
           aCOM.URL                                 as URL, 
           coalesce(convert(varchar(50),c.SiebelID),  
                 (select top 1 a.IDSeq from Customers.dbo.Account a  with (nolock)  
                  where  a.CompanyIDSeq = c.IDSeq  
                  and    a.accounttypecode = 'AHOFF'  
                  and    a.PropertyIDSeq is null                    
                  and    a.ActiveFlag = 1),  
                 'N/A')                 as SiebelID, 
           isnull(c.SiteMasterID, 0)                as SiteMasterID, 
           isnull(a.EpicorCustomerCode, 0)          as EpicorID, 
		   IsNull(c.LegacyRegistrationCode, 0)      as LegacyRegistrationCode,
           aCST.AddressLine1                        as CSTAddr1, 
           aCST.AddressLine2                        as CSTAddr2, 
           aCST.City                                as CSTCity, 
           aCST.State                               as CSTState, 
           aCST.Zip                                 as CSTZip,
		   ISNULL(UPPER(cp.[Name]),'') as CSTCountry,
           ltrim(rtrim(aCST.PhoneVoice1))           as CSTPhone,
		   ltrim(rtrim(aCST.PhoneVoiceExt1))        as CSTExt,
		   ltrim(rtrim(aCST.PhoneFax))              as CSTFax,  
		   ltrim(rtrim(aCST.PhoneVoice4))           as CSTCell, 
           aCBT.AddressLine1                        as CBTAddr1, 
           aCBT.AddressLine2                        as CBTAddr2, 
           aCBT.City                                as CBTCity, 
           aCBT.State                               as CBTState, 
           aCBT.Zip                                 as CBTZip,
		   ISNULL(UPPER(cb.[Name]),'') as CBTCountry,
		   ltrim(rtrim(aCBT.PhoneVoice1))           as CBTPhone,
           ltrim(rtrim(aCBT.PhoneVoiceExt1))        as CBtExt,
           ltrim(rtrim(aCBT.PhoneFax))              as CBTFax,  
           ltrim(rtrim(aCBT.PhoneVoice4))           as CBTCell,  
	       IsNull(p.ConventionalFlag, 0)            as ConventionalFlag, 
           IsNull(p.TaxCreditFlag, 0)               as TaxCreditFlag, 
           IsNull(p.StudentLivingFlag, 0)           as StudentLivingFlag,
           IsNull(p.HUDFlag, 0)                     as HUDFlag,
           IsNull(p.RHSFlag, 0)                     as RHSFlag, 
		   IsNull(p.VendorFlag, 0)		                as VendorFlag,
		   IsNull(p.RetailFlag, 0)					as RetailFlag,
		   IsNull(p.MilitaryPrivatizedFlag, 0)		as MilitaryPrivatizedFlag,
		   IsNull(p.GSAEntityFlag, 0)				as GSAEntityFlag,
		   IsNull(p.SeniorLivingFlag, 0)			as SeniorLivingFlag,
           a.AccountTypeCode                        as AccountTypeCode,
           IsNull(a.ActiveFlag, 0)                  as ActiveFlag,
           U.FirstName+' ' + U.LastName             as CreatedBy,
           st.[Name]                                as Status,
		   st.[Name]                                as CompanyStatus,
           IsNull(p.Units,0)						as Units,
           IsNull(p.Beds,0)							as Beds,
           IsNull(p.PPUPercentage,0)				as PPUPercentage,
           p.OwnerName								as OwnerName
    from   Customers.dbo.Company c with (nolock)
    inner join Customers.dbo.StatusType st with (nolock) on
      c.StatusTypeCode = st.Code

	left outer join Customers.dbo.Address aCOM with (nolock) on c.IDSeq = aCOM.CompanyIDSeq
		and aCOM.AddressTypeCode = 'COM' and aCOM.PropertyIDSeq is null
	left outer join [CUSTOMERS].[dbo].[Country] cs with (nolock) on cs.[Code]=aCOM.[CountryCode]

	left outer join Customers.dbo.Address aCST with (nolock) on c.IDSeq = aCST.CompanyIDSeq 
		and aCST.AddressTypeCode = 'CST' and aCST.PropertyIDSeq is null
	left outer join [CUSTOMERS].[dbo].[Country] cp with (nolock) on cp.[Code]=aCST.[CountryCode]

	left outer join Customers.dbo.Address aCBT with (nolock) on c.IDSeq = aCBT.CompanyIDSeq 
		and aCBT.AddressTypeCode = 'CBT' and aCBT.PropertyIDSeq is null
	left outer join [CUSTOMERS].[dbo].[Country] cb with (nolock) on cb.[Code]=aCBT.[CountryCode]

    left outer join 
           Customers.dbo.Account a with (nolock)
    ON     a.CompanyIdSeq = c.IdSeq 
    left outer join 
           Customers.dbo.[Property] p with (nolock)
    ON     p.idSeq = a.PropertyIdSeq 
    left outer join
           Security.dbo.[User] U with (nolock)
    on     a.CreatedByIDSeq = U.IDSeq
    where  a.IDSeq = @IPI_AccountID;
    ----------------------------------------------------------------------------    
  end
  else
  begin
    ----------------------------------------------------------------------------    
    --  Else PropertyName as AccountName
    --  from CUSTOMERS.DBO.Property for @IPI_AccountID
    ----------------------------------------------------------------------------    
    select @LVC_PropertyID                          as ID, 
    isnull((select count(*)  as [rowcount]
    from (select distinct(select top 1 P.DisplayName  
                          from   Products.dbo.Product P (nolock) 
                          where  P.code = o.productcode
                          and    P.PriceVersion = o.PriceVersion
                           ) as [Name]
                          from   Orders.dbo.[OrderItem] o (nolock) 
                          where o.OrderIDSeq  like '%' + @IPVC_OrderID + '%') tbl 
    where   tbl.[Name] ='Premium Support' ),0)      as [rowcount],
           p.PMCIDSeq                               as CompanyIDSeq,
           p.Name                                   as [Name], 
           c.Name                                   as CompanyName, 
           convert(varchar(10), p.CreatedDate, 101) as CustomerSince, 
           convert(bit, 0)                          as PMCFlag, 
           Convert(bit, 0)                          as OwnerFlag, 
		   Convert(bit, 0)						    as Vendor,
           aCOM.AddressLine1                        as ComAddr1, 
           aCOM.AddressLine2                        as ComAddr2, 
           aCOM.City                                as ComCity, 
           aCOM.State                               as ComState, 
           aCOM.Zip                                 as ComZip,
		   ISNULL(UPPER(cs.[Name]),'') as ComCountry,
    
           ltrim(rtrim(aCOM.PhoneVoice1))           as ComPhone,
		   ltrim(rtrim(aCOM.PhoneVoiceExt1))        as ComExt,    
		   ltrim(rtrim(aCOM.PhoneFax))              as ComFax,  
		   ltrim(rtrim(aCOM.PhoneVoice4))           as ComCell,
           aCOM.URL                                 as URL, 
         coalesce(convert(varchar(50),p.SiebelID),
                 (select top 1 a.IDSeq from Customers.dbo.Account a  with (nolock)
                  where  a.PropertyIDSeq   = p.IDSeq
                  and    a.accounttypecode = 'APROP'                  
                  and    a.ActiveFlag = 1),
                 'N/A')
                                                 as SiebelID, 
           isnull(p.SiteMasterID, 0)                as SiteMasterID, 
           isnull(a.EpicorCustomerCode, 0)          as EpicorID,
		   IsNull(p.LegacyRegistrationCode, 0)      as LegacyRegistrationCode, 
           aCST.AddressLine1                        as CSTAddr1, 
           aCST.AddressLine2                        as CSTAddr2, 
           aCST.City                                as CSTCity, 
           aCST.State                               as CSTState, 
           aCST.Zip                                 as CSTZip,
           ltrim(rtrim(aCST.PhoneVoice1))           as CSTPhone,
		   ltrim(rtrim(aCST.PhoneVoiceExt1))       as CSTExt,
		   ltrim(rtrim(aCST.PhoneFax))             as CSTFax,  
		   ltrim(rtrim(aCST.PhoneVoice4))          as CSTCell,
		   ISNULL(UPPER(cp.[Name]),'') as CSTCountry,
           ltrim(rtrim(aCST.PhoneVoice1))           as CstPhone,
           ltrim(rtrim(aCST.PhoneVoiceExt1))        as CstExt, 
           aCBT.AddressLine1                        as CBTAddr1, 
           aCBT.AddressLine2                        as CBTAddr2, 
           aCBT.City                                as CBTCity, 
           aCBT.State                               as CBTState, 
           aCBT.Zip                                 as CBTZip,
		   ltrim(rtrim(aCBT.PhoneVoice1))           as CBTPhone,
           ltrim(rtrim(aCBT.PhoneVoiceExt1))        as CBtExt,
           ltrim(rtrim(aCBT.PhoneFax))              as CBTFax,  
           ltrim(rtrim(aCBT.PhoneVoice4))           as CBTCell,  
		   ISNULL(UPPER(cb.[Name]),'') as CBTCountry,
           IsNull(p.ConventionalFlag, 0)            as ConventionalFlag, 
           IsNull(p.TaxCreditFlag, 0)               as TaxCreditFlag, 
           IsNull(p.StudentLivingFlag, 0)           as StudentLivingFlag,
           IsNull(p.HUDFlag, 0)                     as HUDFlag,
           IsNull(p.RHSFlag, 0)                     as RHSFlag, 
		   IsNull(p.VendorFlag, 0)				as VendorFlag,
		   IsNull(p.RetailFlag, 0)					as RetailFlag,
		   IsNull(p.MilitaryPrivatizedFlag, 0)		as MilitaryPrivatizedFlag,
		   IsNull(p.GSAEntityFlag, 0)				as GSAEntityFlag,
		   IsNull(p.SeniorLivingFlag, 0)			as SeniorLivingFlag,	
           a.AccountTypeCode                        as AccountTypeCode,
           IsNull(a.ActiveFlag, 0)                  as ActiveFlag,
           U.FirstName+' ' + U.LastName             as CreatedBy,
           st.[Name]                                as Status,
		   (select Top 1
                   case when StatusTypeCode = 'ACTIV'
						then 'Active'
						else 'Inactive'
					End 
			 from   Customers.dbo.Company c with (nolock)
			where c.Idseq=p.PMCIDSeq)               as CompanyStatus,
           IsNull(p.Units,0)						as Units,
           IsNull(p.Beds,0)							as Beds,
           IsNull(p.PPUPercentage,0)				as PPUPercentage,
           p.OwnerName								as OwnerName
    from   Customers.dbo.[Property] p with (nolock)
    inner join Customers.dbo.Account a with (nolock) ON a.PropertyIDSeq = p.IdSeq 
    inner join Customers.dbo.StatusType st with (nolock) ON p.StatusTypeCode = st.Code
    inner join Customers.dbo.Company c with (nolock) ON c.IDSeq = p.PMCIDSeq

	left outer join Customers.dbo.Address aCOM with (nolock) on p.IDSeq = aCOM.PropertyIDSeq
		and aCOM.AddressTypeCode = 'PRO'
	left outer join [CUSTOMERS].[dbo].[Country] cs with (nolock) on cs.[Code]=aCOM.[CountryCode]

	left outer join Customers.dbo.Address aCST with (nolock) on p.IDSeq = aCST.PropertyIDSeq 
		and aCST.AddressTypeCode = 'PST'
	left outer join [CUSTOMERS].[dbo].[Country] cp with (nolock) on cp.[Code]=aCST.[CountryCode]

	left outer join Customers.dbo.Address aCBT with (nolock) on p.IDSeq = aCBT.PropertyIDSeq 
		and aCBT.AddressTypeCode = 'PBT'
	left outer join [CUSTOMERS].[dbo].[Country] cb with (nolock) on cb.[Code]=aCBT.[CountryCode]
    left outer join
           Security.dbo.[User] U with (nolock)
    on     a.CreatedByIDSeq = U.IDSeq

    where  a.IDSeq = @IPI_AccountID;
    ----------------------------------------------------------------------------    
  end
END
GO
