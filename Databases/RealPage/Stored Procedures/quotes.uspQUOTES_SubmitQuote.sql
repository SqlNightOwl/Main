SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : [uspQUOTES_SubmitQuote]
-- Description     : This procedure approves the specified Quote. 
--                   It also updates the status of an Inactive property, if any,
--                   in the Quote to Active.
-- Input Parameters: @IPVC_SubmittedDate  VARCHAR(10),
--                   @IPVC_SubmittedBy    VARCHAR(70),
--                   @IPVC_QuoteIDSeq   VARCHAR(11)
-- 
-- OUTPUT          : 
-- Code Example    : Exec QUOTES.dbo.[uspQUOTES_SubmitQuote]    @IPVC_SubmittedDate  = GETDATE(),
--                                                              @IPVC_SubmittedBy    = 'Anonymous User',
--                                                              @IPVC_QuoteIDSeq    = 'Q0000000001'
--                                                              
-- Revision History:
-- Author          : Kiran Kusumba
-- 09/03/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_SubmitQuote]  @IPVC_SubmittedDate    VARCHAR(10),
                                                @IPVC_SubmittedBy      VARCHAR(70),
                                                @IPVC_QuoteIDSeq      VARCHAR(11)
                                                
AS
------------------------------------------------------------------------------------------------------
BEGIN
  --------------------------------------------------------
  --      Update the Quote Status to Approved          ---
  --------------------------------------------------------
	  UPDATE  [Quotes].dbo.[Quote]

    SET     QuoteStatusCode         = 'SUB',
            SubmittedDate           = @IPVC_SubmittedDate,
            ModifiedDate            = getdate(),
            ModifiedByIDSeq         = (select IDSeq 
                                       from Security.dbo.[User] with (nolock) 
                                       where NTUser = (Select 'RRI\'+ substring (@IPVC_SubmittedBy,1,1) + rtrim(ltrim(substring (@IPVC_SubmittedBy,CHARINDEX(' ',@IPVC_SubmittedBy),len(@IPVC_SubmittedBy)))))),
            ModifiedBy              = @IPVC_SubmittedBy,         
            ModifiedByDisplayName   = @IPVC_SubmittedBy   
    WHERE   QuoteIDSeq = @IPVC_QuoteIDSeq
  --------------------------------------------------------

  -----------------------------------------------------------------------
  -- InActive Properties added to the Quote becomes active on Approval --
  -----------------------------------------------------------------------
    UPDATE      P
    SET         P.StatusTypeCode = 'ACTIV'
    FROM        CUSTOMERS.dbo.[Property] P

    INNER JOIN  QUOTES.dbo.[GroupProperties] GP
      ON        GP.PropertyIDSeq = P.IDSeq

    WHERE       GP.QuoteIDSeq = @IPVC_QuoteIDSeq
    AND         P.StatusTypeCode = 'INACT'
  -----------------------------------------------------------------------
END
------------------------------------------------------------------------------------------------------
GO
