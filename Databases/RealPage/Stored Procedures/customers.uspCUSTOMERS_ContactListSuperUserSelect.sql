SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_ContactListSuperUSerSelect]
-- Description     : This procedure returns the list of Super User contacts based on the parameters
-- Input Parameters: @CompanyID   varchar(20)
-- 
-- OUTPUT          : RecordSet of ID, AddressIDSeq, Type, ContactName, EMail, 
--                     PhoneVoice1, PhoneVoiceExt1, PhoneVoice2, PhoneFax, and RowNumber
--
-- Code Example (to get SuperUser)   : Exec [uspCUSTOMERS_ContactListSuperUserSelect] @CompanyID = 'C0000000287',@ContactCode ='SU'
-- Code Example (to get Contact )    : Exec [uspCUSTOMERS_ContactListSuperUserSelect] @CompanyID = 'C0000000287',@ContactCode =''
-- 
-- Revision History:
-- Author          : Vidhya Venkatapathy
-- 03/20/2007      : Created
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_ContactListSuperUserSelect] @CompanyID varchar(20),@ContactCode varchar(2)
AS
BEGIN
	SELECT TOP 3
		c.IDSeq                               as ID, 
		addr.IDSeq                            as AddressIDSeq, 
		c.Title                               as [Type],
    c.Title                               as Title,
		c.FirstName + ' ' + c.LastName        as ContactName,
		addr.Email                            as EMail, 
		addr.PhoneVoice1                      as PhoneVoice1,
		addr.PhoneVoiceExt1                   as PhoneVoiceExt1, 
		addr.PhoneVoice2                      as PhoneVoice2, 
		addr.PhoneFax                         as PhoneFax	    
	  FROM Customers.dbo.ContactType ct (NOLOCK)
	  inner join  Customers.dbo.Contact c (NOLOCK) on ct.Code = c.ContactTypeCode 
	  inner join  Customers.dbo.Address addr (NOLOCK) on addr.CompanyIDSeq = c.CompanyIDSeq
			and addr.CompanyIDSeq     = @CompanyID
			and addr.AddressTypeCode  = 'CON'
			and addr.IDSeq            = c.AddressIDSeq
	  WHERE ct.Code = c.ContactTypeCode	
			and ((@ContactCode <> 'SU' and LEFT(ct.Code,2)<>'SU')
				or (@ContactCode = 'SU' and LEFT(ct.Code,2)='SU'))			
	  ORDER BY ct.Code, ContactName
END


GO
