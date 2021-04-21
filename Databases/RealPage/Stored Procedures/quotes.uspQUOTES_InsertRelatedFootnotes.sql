SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_InsertRelatedFootnotes] (@IPVC_CompanyID varchar(50),
                                                           @IPVC_QuoteID   varchar(50),
                                                           @IPVC_CreatedBy varchar(70)=NULL
                                                           )
AS
BEGIN
  set nocount on;
  declare @LVC_BusinessUnit varchar(50);
  ---------------------------------------------------------------------
  ---If the Quote is already in Approved state, simply return
  -- Quote should be in Locked down state when Approved.
  if exists(select top 1 1 from QUOTES.dbo.[Quote] Q with (nolock)
            where  Q.QuoteIDSeq = @IPVC_QuoteID
            and    Q.QuoteStatusCode = 'APR'
            )
  begin
    return;
  end
  ----------------------------------------------------------------------
  --Step 0 -- For Other Default mandatory footnotes
  if exists (select top 1 1 
             from   Quotes.dbo.QuoteItem QI with (nolock)
             where  QI.QuoteIDSeq  = @IPVC_QuoteID
            )
  begin
    Insert into Quotes.dbo.Quoteitemnote(QuoteIDSeq,Title,Description,MandatoryFlag,PrintOnOrderFormFlag,CreatedDate)
    select @IPVC_QuoteID as QuoteIDSeq,PF.Title as Title,
           PF.Description,1 as MandatoryFlag,1 as PrintOnOrderFormFlag,getdate() as CreatedDate
    from   Products.dbo.FootNote PF with (nolock)
    where  PF.MandatoryFlag = 1
    and    PF.ActiveFlag    = 1
    and    PF.ApplyTo       = 'Quote'
    and    (nullif(PF.ApplyToProductCategory,'') Is NULL or PF.ApplyToProductCategory = '')
    and    PF.Title like 'Default Footnote #%'
    and    not exists (select top 1 1 from Quotes.dbo.Quoteitemnote Q with (nolock)
                       where  QuoteIDSeq = @IPVC_QuoteID
                       and    Q.Title    = PF.Title
                      )
    Order by PF.IDSeq asc
  end
  ----------------------------------------------------------------------------
  --Step 1 : Delete Mandatory FootNotes for Payments for the @IPVC_QuoteID
  Delete D
  from   Quotes.dbo.Quoteitemnote D with (nolock)
  where  D.QuoteIDSeq =@IPVC_QuoteID
  and    Exists (select top 1 1
                 from   Products.dbo.FootNote X with (nolock)
                 where  X.MandatoryFlag = 1
                 and    X.Title = D.Title
                 and    X.ApplyToProductCategory = 'Payments'
                )
  ----------------------------------------------------------------------------
  --Step 2 : Insert Payments related Mandatory FootNotes
  if exists (select Top 1 1
             from   Quotes.dbo.QuoteItem QI with (nolock)
             where  QI.QuoteIDSeq  = @IPVC_QuoteID
             and    QI.ProductCode = 'DMD-OSD-PAY-PAY-PPAY'
            )  
  begin
    Insert into Quotes.dbo.Quoteitemnote(QuoteIDSeq,Title,Description,MandatoryFlag,PrintOnOrderFormFlag,CreatedDate)
    select @IPVC_QuoteID as QuoteIDSeq,PF.Title as Title,
           PF.Description,1 as MandatoryFlag,1 as PrintOnOrderFormFlag,getdate() as CreatedDate
    from   Products.dbo.FootNote PF with (nolock)
    where  PF.MandatoryFlag = 1
    and    PF.ActiveFlag    = 1
    and    PF.ApplyToProductCategory = 'Payments'
    Order by PF.IDSeq asc
  end
  ----------------------------------------------------------------------------  
  --Step 3 : Special case for Evergreen,eREI,AL Wizard to remove Default Footnote #1 and Default Footnote #2
  --         ie. For all Non RealPage Business Unit,  Realpage Specific Default FootNote #2 and #3 are not valid.
  select @LVC_BusinessUnit = Quotes.dbo.fnGetQuoteBusinessUnitLogo(@IPVC_QuoteID)
  if @LVC_BusinessUnit <> 'RealPage'
  begin
    Delete D
    from   Quotes.dbo.Quoteitemnote D with (nolock)
    where  D.QuoteIDSeq =@IPVC_QuoteID
    and    Exists (select top 1 1
                   from   Products.dbo.FootNote X with (nolock)
                   where  X.MandatoryFlag = 1
                   and    X.ActiveFlag    = 1
                   and    X.Title = D.Title
                   and    X.Title in ('Default Footnote #2','Default Footnote #3')
                  )
  end
  ------------------------------------------------------------------------------
  --Step 4: Special Case When Business Unit is eREI
  --Delete Mandatory FootNotes for eREI for the @IPVC_QuoteID, if Quote is revised and Non eREI is added.
  Delete D
  from   Quotes.dbo.Quoteitemnote D with (nolock)
  where  D.QuoteIDSeq =@IPVC_QuoteID
  and    Exists (select top 1 1
                 from   Products.dbo.FootNote X with (nolock)
                 where  X.MandatoryFlag = 1
                 and    X.Title = D.Title
                 and    X.ApplyToProductCategory = 'eREI'
                );
  ---Insert will take care of adding mandatory FootNotes for eREI for the @IPVC_QuoteID,if it has eREI Product and BusinessUnit
  if (@LVC_BusinessUnit = 'eREI')
  begin
    Insert into Quotes.dbo.Quoteitemnote(QuoteIDSeq,Title,Description,MandatoryFlag,PrintOnOrderFormFlag,CreatedDate)
    select @IPVC_QuoteID as QuoteIDSeq,PF.Title as Title,
           PF.Description,1 as MandatoryFlag,1 as PrintOnOrderFormFlag,getdate() as CreatedDate
    from   Products.dbo.FootNote PF with (nolock)
    where  PF.MandatoryFlag = 1
    and    PF.ActiveFlag    = 1
    and    PF.ApplyToProductCategory = 'eREI'
    Order by PF.IDSeq asc
  end
  ------------------------------------------------------------------------------
END
GO
