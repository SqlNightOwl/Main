SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_ContactListSelect]
-- Description     : This procedure returns the list of contacts based on the parameters
-- Input Parameters: 	1. @PageNumber  int
--                    2. @RowsPerPage int 
--                    3. @CompanyID   varchar(20)
-- 
-- OUTPUT          : RecordSet of ID, AddressIDSeq, Type, ContactName, EMail, 
--                     PhoneVoice1, PhoneVoiceExt1, PhoneVoice2, PhoneFax, and RowNumber
--
-- Code Example    : Exec uspCUSTOMERS_ContactListSelect  @PageNumber = 1, 
--                                                        @RowsPerPage = 14,
--                                                        @CompanyID = 'A0000048764'
-- 
-- 
-- Revision History:
-- Author          : RealPage 
-- 01/04/2006      : Modified by STA. The where clause condition is revised.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_ContactListSelect] @PageNumber int, 
                                                        @RowsPerPage int, 
                                                        @CompanyID varchar(20)
AS
BEGIN
---------------------------------------------------------------------
SELECT  * FROM (
  select top (@RowsPerPage * @PageNumber)
    c.IDSeq                               as ID, 
    addr.IDSeq                            as AddressIDSeq, 
    ctc.Name                              as [Type], 
    c.FirstName + ' ' + c.LastName        as ContactName,
    addr.Email                            as EMail, 
    addr.PhoneVoice1                      as PhoneVoice1,
    addr.PhoneVoiceExt1                   as PhoneVoiceExt1, 
    addr.PhoneFax                         as PhoneFax, 
    row_number() over(order by ctc.Name)  as RowNumber
    
  from Customers.dbo.ContactType      ctc 

  inner join  Customers.dbo.Contact    c 
    on        ctc.Code = c.ContactTypeCode

  inner join  Customers.dbo.Address addr 
    on        addr.CompanyIDSeq     = c.CompanyIDSeq
    and       addr.CompanyIDSeq     = @CompanyID   
    and       addr.AddressTypeCode  = 'CON'
    and       addr.IDSeq            = c.AddressIDSeq

  where       ctc.Code              = c.ContactTypeCode
  and         addr.CompanyIDSeq = @CompanyID

  ) as tbl

WHERE RowNumber > (@PageNumber-1) * @RowsPerPage
ORDER BY ContactName
---------------------------------------------------------------------
SELECT COUNT(*) FROM Customers.dbo.ContactType      ctc 

INNER JOIN  Customers.dbo.Contact    c 
  ON        ctc.Code = c.ContactTypeCode

INNER JOIN  Customers.dbo.Address addr 
  ON        addr.CompanyIDSeq     = c.CompanyIDSeq
  AND       addr.CompanyIDSeq     = @CompanyID   
  AND       addr.AddressTypeCode  = 'CON'
  AND       addr.IDSeq            = c.AddressIDSeq

WHERE       ctc.Code              = c.ContactTypeCode
AND         addr.CompanyIDSeq = @CompanyID
---------------------------------------------------------------------
END

GO
