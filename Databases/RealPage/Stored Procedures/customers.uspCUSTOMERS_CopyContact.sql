SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [customers].[uspCUSTOMERS_CopyContact] (
                                                    @IPI_ContactID int   
                                                  )     
AS
BEGIN 
  
  DECLARE @AddressIDSeq INT
  
  INSERT INTO Customers.dbo.Address(CompanyIDSeq, 
                      AddressLine1,
                      AddressLine2,
                      City,
                      State,
                      Zip,
                      Country,
				      CountryCode,   
                      PhoneVoice1, 
                      PhoneVoiceExt1,
                      PhoneVoice2, 
                      PhoneFax, 
                      Email,
                      AddressTypeCode,
                      CreatedBy,
                      SameAsPMCAddressFlag
	) SELECT 
          CompanyIDSeq, 
          AddressLine1,
          AddressLine2,
          City,
          State,
          Zip,
          Country,
          CountryCode,   
          PhoneVoice1, 
          PhoneVoiceExt1,
          PhoneVoice2, 
          PhoneFax, 
          Email,
          AddressTypeCode,
          CreatedBy,
          SameAsPMCAddressFlag
  FROM    Customers.dbo.Address 
  WHERE IDSeq IN (SELECT AddressIDSeq FROM Customers.dbo.Contact WHERE IDSeq = @IPI_ContactID)

  SET @AddressIDSeq = SCOPE_IDENTITY()

  INSERT INTO Customers.dbo.Contact(
                        CompanyIDSeq,
                        ContactTypeCode,                    
                        FirstName, 
                        LastName, 
                        AddressIDSeq, 
                        Salutation, 
                        Title,
                        CreatedBy,
                        CreateDate,
                        ContactEmail  
                     )
  SELECT                CompanyIDSeq,
                        ContactTypeCode,                    
                        FirstName, 
                        LastName, 
                        @AddressIDSeq, 
                        Salutation, 
                        Title,
                        CreatedBy,
                        CreateDate,
                        ContactEmail   

  FROM Customers.dbo.Contact WHERE IDseq = @IPI_ContactID

  SELECT SCOPE_IDENTITY() AS NewContactID

END
GO
