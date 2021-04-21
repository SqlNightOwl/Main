SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : uspQuotes_UpdateModifiedByIDSEq
-- Description     : This procedure updates the modified by IDSeq in the Quotes table.
-- Input Parameters: 	1. @IPVC_UserName    as varchar(1000),
--                    2. @IPVC_UserIDSeq   as varchar(11), 
--                    3. @IPVC_QuoteIDSeq  as varchar(11),
--                    4. @IPVC_Mode        as varchar(10)
-- 
-- OUTPUT          : 
-- Code Example    : exec dbo.uspQuotes_UpdateModifiedByIDSEq 'NALINI/ADMINISTRATOR','5','Q0000000040','modify'
-- 
-- 
-- Revision History:
-- Author          : NAL
-- 03/14/2007      : Stored Procedure Created.
-- 04/24/2007      : Modified by STA as per the required functionality and standards.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQuotes_UpdateModifiedByIDSEq] (    
                                                        @IPVC_UserName    as varchar(1000),
                                                        @IPVC_UserIDSeq   as varchar(11), 
                                                        @IPVC_QuoteIDSeq  as varchar(11),
                                                        @IPVC_Mode        as varchar(10)
                                                      )

AS
/***************************************************************************/
BEGIN
  IF(@IPVC_QuoteIDSeq IS NOT NULL)
    /***************************************************************/
    BEGIN
      UPDATE  
              Quotes..Quote 
      SET     
              ModifiedByDisplayName = ISNULL((SELECT FirstName + ' ' + LastName 
                FROM Security..[User] WHERE IDSeq = @IPVC_UserIDSeq), @IPVC_UserName),
              ModifiedBy = @IPVC_UserName,
              ModifiedDate = GetDate(),
              ModifiedByIdSeq = @IPVC_UserIDSeq 
      WHERE 
              QuoteIDSeq = @IPVC_QuoteIDSeq
    END
    /***************************************************************/
  ELSE
    /***************************************************************/
    BEGIN
      UPDATE  
              Quotes..Quote 
      SET 
              CreatedByIDSeq = @IPVC_UserIDSeq, 
              CreatedByDisplayName = ISNULL((SELECT FirstName + ' ' + LastName 
                FROM Security..[User] WHERE IDSeq = @IPVC_UserIDSeq), @IPVC_UserName),
              CreatedBy = @IPVC_UserName,
              CreateDate = GetDate(),
              
              ModifiedByDisplayName = ISNULL((SELECT FirstName + ' ' + LastName 
                FROM Security..[User] WHERE IDSeq = @IPVC_UserIDSeq), @IPVC_UserName),
              ModifiedBy = @IPVC_UserName,
              ModifiedDate = GetDate(),
              ModifiedByIdSeq = @IPVC_UserIDSeq
      WHERE 
              QuoteIDSeq = @IPVC_QuoteIDSeq
    END
    /***************************************************************/
/***************************************************************************/
END

--exec dbo.uspQuotes_UpdateModifiedByIDSEq 'NALINI/ADMINISTRATOR','5','Q0000000040','modify'
GO
