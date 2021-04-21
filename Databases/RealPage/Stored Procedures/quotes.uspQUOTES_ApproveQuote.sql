SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : [uspQUOTES_ApproveQuote]
-- Description     : This procedure approves the specified Quote. 
--                   It also updates the status of an Inactive property, if any,
--                   in the Quote to Active.
-- Input Parameters: @IPVC_ApprovalDate  VARCHAR(10),
--                   @IPVC_ApprovedBy      VARCHAR(70),
--                   @IPVC_QuoteIDSeq      VARCHAR(11)
-- 
-- OUTPUT          : 
-- Code Example    : Exec QUOTES.dbo.[uspQUOTES_ApproveQuote]   @IPVC_ApprovalDate  = GETDATE(),
--                                                              @IPVC_ApprovedBy    = 'Anonymous User',
--                                                              @IPVC_QuoteIDSeq    = 'Q0000000001'
--                                                              @IPB_DelayILFBilling = 0
-- Revision History:
-- Author          : STALLIN
-- 06/26/2007      : Stored Procedure Created.
-- 07/31/2007      : Naval Kishore Added DelafILFBilling Flag 
-- 09/14/2007      : Shashi Bhushan, To update Units,Beds columns with values
--                   of QuotableUnits and QuotableBeds when Quote is approved
-- 01/24/2008      : Naval Kishore Added parameter @IPVC_OrdedActivationDate
--                   for site transfer date
-- 03/29/2010	   : Defect 7702 Removed hardcoded user "Quote Approval Process" being updated as lastmodified
--                   for Property when property attributes are updated during Quote Approval Process.
-- 07/01/2011      : SRS - TFS 738 Enhancement for AutoFulfill at Group Level
-- 
-- 07/18/2011      : Satya B: Added new column RequestedBy with refence to TFS #295 Instant Invoice Transactions through OMS
-----------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_ApproveQuote] (
                                                @IPVC_ApprovalDate         VARCHAR(20),
                                                @IPVC_ApprovedBy           VARCHAR(70),
                                                @IPVC_QuoteIDSeq           VARCHAR(50)                                             
                                               )
AS
BEGIN
  set nocount on;  
  --------------------------------------------------------
  --      Update the Quote Status to Approved          ---
  --------------------------------------------------------
  declare @LBI_ModifiedByIDSeq        bigint;
  declare @LVC_ModifiedBy             varchar(70);
  declare @LVC_ModifiedByDisplayName  varchar(70); 

  select  @LBI_ModifiedByIDSeq       = U.IDSeq,
          @LVC_ModifiedBy            = U.NTUser,
          @LVC_ModifiedByDisplayName = U.FirstName + ' ' + U.LastName
  from   Security.dbo.[User] U with (nolock) 
  where  (
           (U.FirstName + ' ' + U.LastName = @IPVC_ApprovedBy)
            OR
            U.NTUser = (Select 'RRI\'+ substring (@IPVC_ApprovedBy,1,1) + rtrim(ltrim(substring (@IPVC_ApprovedBy,CHARINDEX(' ',@IPVC_ApprovedBy),len(@IPVC_ApprovedBy)))))
         )

  UPDATE  [Quotes].dbo.[Quote]
  SET     QuoteStatusCode          = 'APR',
          ApprovalDate             = @IPVC_ApprovalDate,
          ModifiedByDisplayName    = @LVC_ModifiedByDisplayName,         
          ModifiedByIDSeq          = @LBI_ModifiedByIDSeq,
          ModifiedBy               = @LVC_ModifiedBy,
          ModifiedDate             = getdate()          
  WHERE   QuoteIDSeq = @IPVC_QuoteIDSeq
  -----------------------------------------------------------------------
  -- InActive Properties added to the Quote becomes active on Approval --
  -----------------------------------------------------------------------
  UPDATE      P
  SET         P.StatusTypeCode           = 'ACTIV',
              P.ModifiedByIDSeq          = @LBI_ModifiedByIDSeq,
              P.ModifiedBy               = @LVC_ModifiedBy,
              P.ModifiedDate             = getdate()
  FROM        CUSTOMERS.dbo.[Property]     P  WITH (NOLOCK)
  INNER JOIN  QUOTES.dbo.[GroupProperties] GP WITH (NOLOCK)
  ON          GP.PropertyIDSeq = P.IDSeq
  AND         P.StatusTypeCode = 'INACT'
  AND         GP.QuoteIDSeq    = @IPVC_QuoteIDSeq
  -----------------------------------------------------------------------
  -- Update Customers.dbo.Property back with Units and Beds stored in Groupproperties
  -- for the given property of approved quote.

  ---Per BL is : When a Quote is approved with a given set of Quoteable Units and Quoteable beds for
  --             a given  property that is higher than the current Property values,
  --             then these units and beds should be considered latest and should override units,beds stored in customers
  --             at the time of Quote Approval.
  --Risk 1     : When a quote is approved by mistake and order is rolledback, the quote goes back to NonSubmitted State.
  --             But Units and Beds that are updated to customers cannot be rolledback and Original is lost.
  --Risk 2     : Even though the system is built per BL, Still Users should be allowed to see what changes they are about
  --             to make and ask for extra user confirmation at the time approval.
  --             Current implementation assumed Quote Approval as the final confirmation to make 
  --             Property related changes if units and Beds are different.
  -- Hetal to talk to Davon to Move the below piece of update as part of User Confirmation modal
  -- which will show what is current in customers and what would be updated as, to push the liability to 
  -- authorized user who is approving the quote rather than automatic Quote approval backend process
  -----------------------------------------------------------------------
  Update P  
  set    P.Units            = GP.Units,
         P.Beds             = GP.Beds,
         P.ModifiedByIDSeq  = @LBI_ModifiedByIDSeq,
         P.ModifiedBy       = @LVC_ModifiedBy,
         P.ModifiedDate     = getdate()
  From   CUSTOMERS.DBO.property     P  With (nolock)
  inner join
         QUOTES.DBO.GroupProperties GP with (nolock)
  on     P.IDSeq       = GP.PropertyIDSeq
  and    GP.QuoteIDSeq = @IPVC_QuoteIDSeq
  and   (
         (GP.Units <> P.Units and GP.Units > P.Units)
          OR
         (GP.Beds  <> P.Beds  and GP.Beds > P.Beds)
        )
  where  P.IDSeq       = GP.PropertyIDSeq
  and    GP.QuoteIDSeq = @IPVC_QuoteIDSeq
   and   (
          (GP.Units <> P.Units and GP.Units > P.Units)
           OR
          (GP.Beds  <> P.Beds  and GP.Beds > P.Beds)
         )
  -----------------------------------------------------------------------
END
GO
