SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec CUSTOMERS.dbo.uspCUSTOMERS_PushAccountInfoToSiebel @IPVC_CompanyID='C0000001830'
exec CUSTOMERS.dbo.uspCUSTOMERS_PushAccountInfoToSiebel @IPVC_CompanyID='C0000001830',@IPVC_PropertyID='P0000019054'
*/

----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_PushAccountInfoToSiebel
-- Description     : This procedure Selects Account Info for Siebel Push for the passed parameters.
-- Input Parameters: 1. @IPVC_CompanyID   as varchar(50)
--                   2. @IPVC_PropertyID  as varchar(50)
-- OUTPUT          : None
--  
--                   
-- Code Example    : exec CUSTOMERS.dbo.uspCUSTOMERS_PushAccountInfoToSiebel @IPVC_CompanyID='C0000001830'
--                   exec CUSTOMERS.dbo.uspCUSTOMERS_PushAccountInfoToSiebel @IPVC_CompanyID='C0000001830',
--                                                                         @IPVC_PropertyID='P0000019054'
-- 
-- 
-- Revision History:
-- Author          : SRS
-- 03/28/2007      : Stored Procedure Created.
-- 12/09/2008        Shashi Bhushan            Altered procedure not to use company's/property's SiebelID (defect #5803)
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_PushAccountInfoToSiebel] (@IPVC_CompanyID  varchar(50),
                                                           @IPVC_PropertyID varchar(50)=NULL                                      
                                                           )
AS
BEGIN
  set nocount on;
  -------------------------------------------------------------------------------------------
  IF (@IPVC_CompanyID is not null) and (@IPVC_PropertyID = '' or @IPVC_PropertyID IS NULL)
  BEGIN
    Select 
             C.Name                         as AccountName,
             'Property Management Company'  as AccountType,
             (Case when exists (select Top 1 P.Name 
                               from   CUSTOMERS.dbo.Property P with (nolock)
                               where  P.PMCIDSeq = C.IDSeq
                               and   (ltrim(rtrim(C.Name)) = ltrim(rtrim(P.Name)))
                               ) 
                              OR
                       exists (Select Top 1 PA.SiebelID
                               from   CUSTOMERS.dbo.Account PA with (nolock)
                               where  PA.CompanyIDSeq = C.IDSeq
                               and    PA.Accounttypecode = 'APROP'
                               and    PA.PropertyIDSeq is null
                               )
                    then A.IDSeq
              else coalesce(A.SiebelID,A.IDSeq)
              end)                                     as Location,

             isnull(nullif(C.SiteMasterID,''),'0')     as DatabaseID,
             A.EpicorCustomerCode           as EpicorID,
             C.LegacyRegistrationCode       as LegacyId,
             C.IDSeq                        as IntegrationID,
             ''                             as ParentAccountID,
             'Active'                       as AccountStatus,
             'N'                            as BillToParent,
             'N'                            as ShiptoParent,
             isnull(ADR.PhoneFax,'')                   as MainFaxNumber, 
             isnull(ADR.PhoneVoice1,'')                as MainPhoneNumber, 
             0                              as NumberOfUnits,
             100                              as AccountPPUPercentage,
             isnull((select Top 1 CONT.FirstName + ',' + CONT.LastName
              from   CUSTOMERS.DBO.CONTACT CONT with (nolock)
              where    CONT.CompanyIDSeq  = @IPVC_CompanyID
              and    CONT.PropertyIDSeq    is null
              and    CONT.ContactTypeCode = 'BIL'
             ),'')                              as Attention,
			 (UPPER(ADR.AddressLine1)+ ','  + UPPER(isnull(ADR.AddressLine2,'')) +
			  ',' + UPPER(ADR.City)+ ',' + UPPER(ADR.State)) as AddressName,
             ADR.AddressLine1               as StreetAddress,
             isnull(ADR.AddressLine2,'')              as StreetAddress2,
             ADR.City                       as City,
             ADR.State                      as State,
             ADR.Zip                        as PostalCode,
             ltrim(rtrim(coalesce(ADR.Country,'')))       as Country,
             coalesce(ADR.CountryCode,'')   as CountryCode,
             ADR.PhoneVoice1 as PhoneNumber,
             ADR.PhoneFax as FaxNumber,
             isnull((select Top 1 ADDRIN.Email
              from   CUSTOMERS.DBO.Address ADDRIN        with (nolock)
              inner join CUSTOMERS.DBO.CONTACT CONT with (nolock)
              on     ADDRIN.idseq     = CONT.AddressIDSeq
              and    CONT.CompanyIDSeq  = @IPVC_CompanyID
              and    CONT.PropertyIDSeq    is null
              and    CONT.ContactTypeCode = 'BIL'
             ),'')                              as EMailAddress,
              ADR.IDSeq                     as AdrIntegrationID,
              A.SiebelRowID                 as SiebelRowID,
              ADR.Sieb77AddrID              as Sieb77AddrID
    From   Customers.dbo.Account A with (nolock)
    inner join
           Customers.dbo.Company C with (nolock)
    on     A.CompanyIDSeq     =   C.IDSeq
    and    A.AccountTypeCode  = 'AHOFF'
    and    A.PropertyIDSeq    is null    
    and    A.ActiveFlag        = 1    
    inner join
          Customers.dbo.Address ADR with (nolock)
    on    A.CompanyIDSeq      = ADR.CompanyIDSeq
    and   ADR.PropertyIDSeq  is null  
    and   ADR.AddressTypeCode = 'COM'
    where A.CompanyIDSeq      =  @IPVC_CompanyID     
  END 
  --------------------------------------------------------------------------------  
  ELSE IF (@IPVC_CompanyID is not null) and (@IPVC_PropertyID <> '' and @IPVC_PropertyID IS NOT NULL)
  BEGIN
    select
             P.Name                         as AccountName,
             'Site'                         as AccountType,
             coalesce(A.SiebelID,A.IDSeq)   as Location,
             isnull(nullif(P.SiteMasterID,''),'0')    as DatabaseID,
             A.EpicorCustomerCode           as EpicorID,
             P.LegacyRegistrationCode       as LegacyId,
             P.IDSeq                        as IntegrationID,
             (select Top 1 SiebelRowID 
              from  CUSTOMERS.dbo.Account with (nolock)
              where CompanyIDSeq     = @IPVC_CompanyID
              and   AccountTypeCode  = 'AHOFF'
              and   PropertyIDSeq    is null
              and   ActiveFlag        = 1)
                                            as ParentAccountID,
             'Active'                       as AccountStatus,
             /*
             case when A.BillToPMCFlag = 1 
             then 'Y' else 'N' end          as BillToParent,
             case when A.ShipToPMCFlag = 1 
             then 'Y' else 'N' end          as ShiptoParent,
             */
             ----BilltoParent and ShipToParent are not used in Siebel for OMS to Siebel Integration.
             --- Hence Hardcoding to No as below.
             'N'                            as BillToParent,
             'N'                            as ShiptoParent,
             isnull(ADR.PhoneFax,'')                   as MainFaxNumber, 
             isnull(ADR.PhoneVoice1,'')                as MainPhoneNumber, 
             P.Units                        as NumberOfUnits,
             P.PPUPercentage                              as AccountPPUPercentage,
             isnull((select Top 1 CONT.FirstName + ',' + CONT.LastName
              from  CUSTOMERS.DBO.CONTACT CONT with (nolock)
              where CONT.CompanyIDSeq  = @IPVC_CompanyID
              and   CONT.PropertyIDSeq    is null
              and   CONT.ContactTypeCode = 'BIL'
             ),'')                                    as Attention,
			 (UPPER(ADR.AddressLine1)+ ','  + UPPER(isnull(ADR.AddressLine2,'')) +
			  ',' + UPPER(ADR.City)+ ',' + UPPER(ADR.State)) as AddressName,
             ADR.AddressLine1                          as StreetAddress,
             isnull(ADR.AddressLine2,'')               as StreetAddress2,
             ADR.City                       as City,
             ADR.State                      as State,
             ADR.Zip                        as PostalCode,
             ltrim(rtrim(isnull(ADR.Country,'')))         as Country,
             isnull(ADR.CountryCode,'')     as CountryCode,
             ADR.PhoneVoice1 as PhoneNumber,
             ADR.PhoneFax  as FaxNumber,
             isnull((select Top 1 ADDRIN.Email
              from   CUSTOMERS.DBO.Address ADDRIN        with (nolock)
              inner join CUSTOMERS.DBO.CONTACT CONT      with (nolock)
              on     ADDRIN.idseq     = CONT.AddressIDSeq
              and    CONT.CompanyIDSeq  = @IPVC_CompanyID
              and    CONT.PropertyIDSeq    is null
              and    CONT.ContactTypeCode = 'BIL'
             ),'')                          as EMailAddress,
              ADR.IDSeq                     as AdrIntegrationID,              
              A.SiebelRowID                 as SiebelRowID,
              ADR.Sieb77AddrID              as Sieb77AddrID 
      From   Customers.dbo.Account A with (nolock)
      inner join
             Customers.dbo.Property P with (nolock)
      on    A.CompanyIDSeq      = P.PMCIdSeq
      and   A.PropertyIDSeq     = P.IDSeq
      and   P.IDSeq             = @IPVC_PropertyID
      and   A.CompanyIDSeq      = @IPVC_CompanyID
      and   A.PropertyIDSeq     = @IPVC_PropertyID 
      and   A.AccountTypeCode   = 'APROP'  
      and   A.ActiveFlag        = 1      
      inner join
            Customers.dbo.Address ADR with (nolock)
      on    A.CompanyIDSeq      = ADR.CompanyIDSeq
      and   ADR.AddressTypeCode = 'PRO'
      and   ADR.PropertyIDSeq   = A.PropertyIDSeq
      where A.CompanyIDSeq      = @IPVC_CompanyID
      and   A.PropertyIDSeq     = @IPVC_PropertyID      
      and   A.AccountTypeCode   = 'APROP'  
      and   A.ActiveFlag        = 1            
      and   P.IDSeq             = @IPVC_PropertyID
  END
END

GO
