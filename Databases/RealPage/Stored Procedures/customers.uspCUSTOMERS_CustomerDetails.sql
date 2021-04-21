SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_CustomerDetails
-- Description     : This procedure gets IDSeq,Name,CreatedDate,PMCFlag,OwnerFlag,AddressLine1,AddressLine2,
--                   City,State,Zip,PhoneVoice1,URL,SiebelID,SiteMasterID,EpicorCustomerCode,AddressLine1,
--                   AddressLine2,City,State,Zip,AddressLine1,AddressLine2,City,State,Zip pertaining to passed 
--                   CompanyID
-- Input Parameters: @IPC_CompanyID       as    char
-- OUTPUT          : RecordSet of IDSeq,Name,CreatedDate,PMCFlag,OwnerFlag,AddressLine1,AddressLine2,
--                   City,State,Zip,PhoneVoice1,URL,SiebelID,SiteMasterID,EpicorCustomerCode,AddressLine1,
--                   AddressLine2,City,State,Zip,AddressLine1,AddressLine2,City,State,Zip
-- Code Example    : Exec ORDERS.DBO.uspORDERS_OrderList  @IPC_CompanyID        =   'A0000002438' 	
-- Revision History: Eric Font - Removed the -PAGING- parameters as this SP will always return 1 row.
-- Author          : KISHORE KUMAR A S 
-- 12/06/2006      : Stored Procedure Created.
-- 12/21/2006      : changed by T Madhu
--                 : changes to format the phone , extension and fax number 
-- 04/28/2008      : Naval Kishore Modified Siebel ID
-- 05/18/2009	   : Naval kishore Modified to get Country Info for other countries. 
-- 12/16/2009      : 7340 Scott Hensley Updating Notes
-- 2010-01-15      : 7111 Larry Wilson - return any country code that may occur in any address, (not only certain specials)
-- 2010-05-24      : Naval Kishore Modified to get Company StatusTypecode. Defect # 7750
-- 2010-06-28      : Larry - return GSA flag. PCR-7948
-- 2011-04-05	   : Mahaboob Mohammad Modified to change the current verbiage on OneSite Payments order forms . Defect # 9219
-- 2011-07-27	   : Mahaboob Mohammad Modified to display the Executive Company ID. Defect # 909
-- 2011-09-06      : Mahaboob ( TFS 1026)     --  Changes  are made as per the Revised "ExecutiveCompany" table script 
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_CustomerDetails] (@IPC_CompanyID varchar(50), @IPVC_QuoteID varchar(50) = NULL)					
AS
BEGIN
  set nocount on;
  declare @LVC_Notes  varchar(1000)
  set @LVC_Notes = ''
  
  Declare @AccountId char(50)
  select Top 1 @AccountId = A.IDSeq from customers.dbo.Account A  with (nolock) 
  where CompanyIdSeq=@IPC_CompanyID and AccountTYpeCode='AHOFF'
  
  
  if @IPVC_QuoteID is not null
  begin
    if exists (select 1 from Quotes.dbo.[QuoteItem] with (nolock)
               where QuoteIDSeq = @IPVC_QuoteID
               and ProductCode = 'DMD-OSD-PAY-PAY-PPAY')
      set @LVC_Notes = 'RealPage will debit electronically from the site owner''s, or duly appointed agent of the site owner''s designated bank account all Electronic Payment Processing Transaction Fees, including but not limited to ACH fees, IRD fees, monthly minimum fees, returns and Check 21 adjustments on or around the 15th business day of each month.'
  end

--  Declare @ExecutiveIDSeq varchar(11), @ExecutiveCustomerID varchar(11)
--  select @ExecutiveIDSeq = IDSeq,  @ExecutiveCustomerID = CustomerIDSeq from Customers.dbo.ExecutiveCompany E where E.CustomerIDSeq = @IPC_CompanyID and Status = 1
  Declare @IsExecutiveCustomer bit, @ExecutiveIDSeq varchar(11)
  select @IsExecutiveCustomer = 0, @ExecutiveIDSeq = ''
  select @ExecutiveIDSeq = E.ExecutiveCompanyIDSeq 
  from Customers.dbo.ExecutiveCompany E 
  inner join
  Customers.dbo.Company C with (nolock)
  on C.IDSeq = E.CompanyIDSeq  and C.StatusTypeCode = 'ACTIV'
  where E.CompanyIDSeq = @IPC_CompanyID and E.ActiveFlag = 1
  if(len(@ExecutiveIDSeq)=11)
  begin
		set @IsExecutiveCustomer = 1
  end

   select 
	c.IDSeq                                                    as ID, 
	c.Name                                                     as Name, 
	convert(varchar(10), c.CreatedDate, 101)                   as CustomerSince, 
	c.SignatureText                                            as SignatureText,
	PMCFlag                                                    as PMCFlag, 
	OwnerFlag                                                  as OwnerFlag, 
	aCOM.AddressLine1                                          as ComAddr1, 
	aCOM.AddressLine2                                          as ComAddr2, 
	aCOM.City                                                  as ComCity, 
	aCOM.State                                                 as ComState, 
	aCOM.Zip                                                   as ComZip,
    ISNULL(UPPER(cs.[Name]),'')                                as ComCountry,    
	ltrim(rtrim(aCOM.PhoneVoice1))                             as ComPhone,
    ltrim(rtrim(aCOM.PhoneVoiceExt1))                          as ComExt,    
	ltrim(rtrim(aCOM.PhoneFax))                                as ComFax,  
    ltrim(rtrim(aCOM.PhoneVoice4))                             as ComCell,  
	aCOM.URL                                                   as URL, 
	coalesce(convert(varchar(50),c.SiebelID),  
                 (select top 1 a.IDSeq from Customers.dbo.Account a  with (nolock)  
                  where  a.CompanyIDSeq = C.IDSeq  
                  and    a.accounttypecode = 'AHOFF'  
                  and    a.PropertyIDSeq is null                    
                  and    a.ActiveFlag = 1),  
                 'N/A')                 as SiebelID  , 
	isnull(SiteMasterID, 0)                                    as SiteMasterID,
	IsNull(c.LegacyRegistrationCode, 0)                        as LegacyRegistrationCode, 
    isnull((select EpicorCustomerCode from Customers..Account a where a.CompanyIDSeq = C.IDSeq
    and a.PropertyIDSeq is null and a.ActiveFlag = 1), 'N/A')as EpicorID,
	isnull((select sum(units) from Customers..Property CO where CO.PMCIDSeq = @IPC_CompanyID
    and CO.statustypecode = 'ACTIV'),0) as Units,
	aCST.AddressLine1                                          as CSTAddr1, 
	aCST.AddressLine2                                          as CSTAddr2, 
	aCST.City                                                  as CSTCity, 
	aCST.State                                                 as CSTState, 
	aCST.Zip                                                   as CSTZip,
    ISNULL(UPPER(cp.[Name]),'')                                as CSTCountry, 
    ltrim(rtrim(aCST.PhoneVoice1)) as CSTPhone,
    ltrim(rtrim(aCST.PhoneVoiceExt1)) as CSTExt,
    ltrim(rtrim(aCST.PhoneFax))                                as CSTFax,  
    ltrim(rtrim(aCST.PhoneVoice4))                             as CSTCell,  
	aCBT.AddressLine1                                          as CBTAddr1, 
	aCBT.AddressLine2                                          as CBTAddr2, 
	aCBT.City                                                  as CBTCity, 
	aCBT.State                                                 as CBTState, 
	aCBT.Zip                                                   as CBTZip,
    ISNULL(UPPER(cb.[Name]),'')                                as CBTCountry, 
    ltrim(rtrim(aCBT.PhoneVoice1))                             as CBTPhone,
    ltrim(rtrim(aCBT.PhoneVoiceExt1))                          as CBTExt,
    ltrim(rtrim(aCBT.PhoneFax))                                as CBTFax,  
    ltrim(rtrim(aCBT.PhoneVoice4))                             as CBTCell,  
	
	row_number() over(order by c.IDSeq)                        as RowNumber,
  aCOM.Email                                                 as Email,
 isnull((select count(*)  from Customers.dbo.property CO with (nolock)
where CO.PMCIDSeq=@IPC_CompanyID and CO.statustypecode = 'ACTIV'),0)                       as propertyCount,  
 isnull((select count(*)  from Customers.dbo.property CO with (nolock)  
where CO.OwnerIDSeq=@IPC_CompanyID and CO.statustypecode = 'ACTIV'),0)                     as propertiesOwnedCount, 
@LVC_Notes                                                   as AdditionalNotes,
isnull(@AccountId, 'N/A')                                    as AccountID,
	c.StatusTypecode                                         as CompanyStatus
	,[GSAEntityFlag]									     as [GSAEntityFlag]
--    ,coalesce(e.IDSeq, @ExecutiveIDSeq)					 as [ExecutiveCompanyID]
--    ,coalesce(e.CustomerIDSeq, @ExecutiveCustomerID)		 as [ExecutiveCustomerID]
	  ,e.ExecutiveCompanyIDSeq								 as [ExecutiveCompanyID]
	  ,e.CompanyIDSeq										 as [ExecutiveCustomerID]
      ,@IsExecutiveCustomer									 as IsExecutiveCustomer          ---> Check for ExecutiveCustomer
      ,c.VendorFlag											 as VendorFlag          
	from Customers.dbo.Company c with (nolock)

	left outer join Customers.dbo.Address aCOM with (nolock) on c.IDSeq = aCOM.CompanyIDSeq
		and aCOM.AddressTypeCode = 'COM' and aCOM.PropertyIDSeq is null
	left outer join [CUSTOMERS].[dbo].[Country] cs with (nolock) on cs.[Code]=aCOM.[CountryCode]

	left outer join Customers.dbo.Address aCST with (nolock) on c.IDSeq = aCST.CompanyIDSeq 
		and aCST.AddressTypeCode = 'CST' and aCST.PropertyIDSeq is null
	left outer join [CUSTOMERS].[dbo].[Country] cp with (nolock) on cp.[Code]=aCST.[CountryCode]

	left outer join Customers.dbo.Address aCBT with (nolock) on c.IDSeq = aCBT.CompanyIDSeq 
		and aCBT.AddressTypeCode = 'CBT' and aCBT.PropertyIDSeq is null
	left outer join [CUSTOMERS].[dbo].[Country] cb with (nolock) on cb.[Code]=aCBT.[CountryCode]
    left outer join [CUSTOMERS].[dbo].[ExecutiveCompany] e with (nolock) on e.ExecutiveCompanyIDSeq = c.ExecutiveCompanyIDSeq and c.StatusTypeCode = 'ACTIV' and e.ActiveFlag = 1
    where c.IDSeq = @IPC_CompanyID
END
GO
