SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [customers].[uspCUSTOMERS_ContactSelect] @ContactID varchar(11), @CompanyID varchar(10)
AS
BEGIN 
  select 
        c.IDSeq                     as  ContactID, 
        addr.IDSeq                  as  AddrID,
        c.Title                     as  Title,  
        c.FirstName                 as  FirstName, 
        c.LastName                  as  LastName, 
        c.ContactTypeCode           as  ContactTypeCode,
        addr.PhoneVoice1            as  PhoneVoice1,
        addr.PhoneVoiceExt1         as  PhoneVoiceExt1, 
        addr.PhoneVoice2            as  PhoneVoice2, 
        addr.AddressLine1           as  AddressLine1,
        addr.AddressLine2           as  AddressLine2,
        addr.City                   as  City,
        addr.State                  as  State,
        addr.Country                as  Country,
		addr.CountryCode            as  CountryCode,
        addr.Zip                    as  Zip,
        addr.PhoneFax               as  PhoneFax, 
        addr.Email                  as  Email, 
        addr.AddressTypeCode        as  AddressTypeCode, 
        @CompanyID                  as  CompanyID,
        addr.SameAsPMCAddressFlag   as  SameAsPMCAddressFlag
  from 
        Address addr, Contact c
  where 
        c.IDSeq                  =    @ContactID
  and   
        c.CompanyIDSeq           =    addr.CompanyIDSeq
  and   
        c.AddressIDSeq           =    addr.IDSeq
END
GO
