SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec QUOTES.dbo.uspQUOTES_CreateTemplateQuote 
@IPVC_CompanyID='C0000032910',@IPVC_ExistingQuoteID= 'Q0000005367',
@IPI_CreatedByIDSeq=65,@IPVC_CreatedBy='Hetal Shah',@IPI_CopyGroupPropertiesFlag = 1

*/
-----------------------------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : uspQUOTES_CreateTemplateQuote
-- Description     : This procedure copies high level info of existing quote and creates a template quote.
-- Input Parameters: @IPVC_CompanyID       -- CompanyID of PMC for which Template Quote is to be created.
--                   @IPVC_ExistingQuoteID -- Existing QuoteID which feed info for Template Quote to be created.
--                   @IPVC_CreatedBy       -- Name of User who is creating the Template Quote.
--                   @IPI_CopyGroupPropertiesFlag = 1 or 0. 1 will copy GroupProperties too. 0 will not.
-- OUTPUT          : Rowset.
--  
--                   
-- Code Example    : exec QUOTES.dbo.uspQUOTES_CreateTemplateQuote 
--                        @IPVC_CompanyID       ='C0000001096',
--                        @IPVC_ExistingQuoteID ='Q0000000049',
--                        @IPVC_CreatedBy       ='Template User'
--                        @IPI_CopyGroupPropertiesFlag = 0
-- Revision History:
-- Author          : Satya B
-- 07/15/2011      : Added new column PrePaidFlag with refence to TFS #295 Instant Invoice Transactions through OMS
-- Author          : LWW
-- 06/09/2011      : Change to pre-set DDA Level to Unspecified ([DealDeskCurrentLevel]=-1)
-- Author          : SRS
-- 04/22/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_CreateTemplateQuote] (@IPVC_CompanyID              varchar(50),
                                                        @IPVC_ExistingQuoteID        varchar(50),
                                                        @IPVC_CreatedBy              varchar(70),
                                                        @IPI_CreatedByIDSeq          bigint,
                                                        @IPI_CopyGroupPropertiesFlag bigint = 0
                                                        )
AS
BEGIN
  set nocount on 
  ---------------------------------------------------------------------------------
  --Declare Local Varaible.
  declare @LVC_CompanyName           varchar(255)
  declare @LVC_NewQuoteID            varchar(50)
  declare @LVC_ErrorCodeSection      varchar(500)
  declare @LVC_OLDDescription        varchar(500)
  declare @LBI_GroupID               bigint
  declare @LBI_NewGroupID            bigint  
  declare @LI_Min                    int
  declare @LI_Max                    int
  declare @LBI_QuoteItemIDSeq        bigint
  Declare @LVC_ExistingDocumentIDSeq varchar(50)
  Declare @LVC_NewDocumentIDSeq      varchar(50)
  Declare @LVC_QuoteType             varchar(4)
  Declare @LI_PrePaidFlag            int
  ---------------------------------------------------------------------------------
  declare @LT_Group table (SEQ       int     not null identity(1,1),
                           GroupID   bigint
                          )
  declare @LT_ExistingDocuments table (SEQ int                not null identity(1,1),
                                       ExistingDocumentIDSeq  varchar(50) NULL
                                       )
  ---------------------------------------------------------------------------------
  select @LI_Min=1,@LI_Max=0
  ---------------------------------------------------------------------------------
  --Validation : Check if Existing QuoteId is valid and it has products associated.
  If not exists (select top 1 1 
                 from   QUOTES.dbo.Quote Q with (nolock)
                 where  Q.QuoteIDSeq =@IPVC_ExistingQuoteID
                 and exists (select top 1 1 
                             from   QUOTES.dbo.QuoteItem QI with (nolock)
                             where  QI.QuoteIDSeq =@IPVC_ExistingQuoteID
                             and    QI.QuoteIDSeq =Q.QuoteIDSeq
                            )
                )
  begin
    Select 'Quote or QuoteItem(s) not found for QuoteID :' + @IPVC_ExistingQuoteID
    RETURN
  end
  ---------------------------------------------------------------------------------   
  --Step 1 : Get CompanyName for @IPVC_CompanyID
  select @LVC_CompanyName = C.Name 
  from   CUSTOMERS.dbo.Company C with (nolock)
  where  C.IDSeq = @IPVC_CompanyID
  --------------------------------------------------------------------------------- 
  select @LVC_OLDDescription = coalesce(Description,'')
  From Quotes.dbo.Quote with (nolock) where QuoteIDSeq =@IPVC_ExistingQuoteID
  ---------------------------------------------------------------------------------
  select @LVC_QuoteType = QuoteTypeCode, @LI_PrePaidFlag = PrePaidFlag  
  From Quotes.dbo.Quote with (nolock) where QuoteIDSeq =@IPVC_ExistingQuoteID  
  ---------------------------------------------------------------------------------    
  BEGIN TRY
    BEGIN TRANSACTION   
      -----------------------------------------------------------
      --Step 2 : Generate new QuoteID for creating Template Quote
      -----------------------------------------------------------
      UPDATE QUOTES.DBO.IDGenerator with (TABLOCKX,XLOCK,HOLDLOCK)
      set    IDSeq = IDSeq+1,
             GeneratedDate =CURRENT_TIMESTAMP      

      select @LVC_NewQuoteID = QuoteIDSeq
      from   QUOTES.DBO.IDGenerator with (NOLOCK) 
    COMMIT TRANSACTION
  ---------------------------------------------------------------------------------------------
  END TRY
  BEGIN CATCH    
    -- XACT_STATE:
       -- If 1, the transaction is committable.
       -- If -1, the transaction is uncommittable and should be rolled back.
       -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
    if (XACT_STATE()) = -1
    begin
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    end
    else if (XACT_STATE()) = 1
    begin
      IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
    end 
    select @LVC_ErrorCodeSection = 'Failed To Create Template Quote Copy Of : ' + @IPVC_ExistingQuoteID
    exec QUOTES.dbo.uspQUOTES_DeleteQuote @IPVC_CompanyID = @IPVC_CompanyID,@IPVC_QuoteID = @LVC_NewQuoteID
    exec CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] @IPVC_CodeSection = @LVC_ErrorCodeSection 
    RETURN     
  END CATCH
  ------------------------------------------------------------------------------  
  BEGIN TRY
    BEGIN TRANSACTION 
      -----------------------------------------------------------
      --Step 3: Create a Quote Record for @LVC_NewQuoteID,@IPVC_CompanyID
      -----------------------------------------------------------
      Insert into QUOTES.dbo.QUOTE(QuoteIDSeq,CustomerIDSeq,CompanyName,Description,							 
                                   QuoteStatusCode,CreatedBy,CreatedByDisplayName,CreatedByIDSeq,ModifiedByDisplayName
                                   ,ModifiedBy,ModifiedByIDSeq,CreateDate, ExpirationDate,QuoteTypeCode
                                   ,[DealDeskReferenceLevel],[DealDeskCurrentLevel],PrePaidFlag
									)
      select @LVC_NewQuoteID,@IPVC_CompanyID,@LVC_CompanyName,
              'Copy of Quote ' + @IPVC_ExistingQuoteID  as Description,    
             'NSU',@IPVC_CreatedBy,@IPVC_CreatedBy,@IPI_CreatedByIDSeq,@IPVC_CreatedBy
             ,@IPVC_CreatedBy,@IPI_CreatedByIDSeq, getdate(), dateadd(month, 1, getdate()),@LVC_QuoteType
             ,-1,-1, @LI_PrePaidFlag
      -----------------------------------------------------------
      --Step 4: Create a Quote Log Record for @LVC_NewQuoteID,@IPVC_CompanyID
      -----------------------------------------------------------
      Insert into QUOTES.dbo.QUOTELOG(QuoteIDSeq,CustomerIDSeq,CompanyName,							 
                                   QuoteStatusCode,QuoteTypeCode,CreatedBy,CreatedByDisplayName,CreateDate,SQLActivityType, PrePaidFlag) 
      select @LVC_NewQuoteID,@IPVC_CompanyID,@LVC_CompanyName,'NSU',@LVC_QuoteType,@IPVC_CreatedBy,@IPVC_CreatedBy,
             getdate() as CreateDate,'I' as SQLActivityType, @LI_PrePaidFlag      
      -----------------------------------------------------------
      --Step 6: Get all GroupIDs of all existing bundles for @IPVC_ExistingQuoteID
      -----------------------------------------------------------
      Insert into @LT_Group(GroupID)
      select distinct G.IDSeq as GroupID
      from   QUOTES.dbo.[Group] G with (nolock)
      inner Join 
             QUOTES.dbo.Quoteitem QI with (nolock)
      on     G.Quoteidseq = QI.Quoteidseq
      and    G.idseq      = QI.Groupidseq
      and    G.QuoteIDseq = @IPVC_ExistingQuoteID  
      and    QI.QuoteIDseq = @IPVC_ExistingQuoteID  
      and    QI.productcode <> 'DMD-PSR-ADM-ADM-AMTF'
      -----------------------------------------------------------
      --Step 7:Start Loop for existing Group.
      ---      Copy Existing Group and Get New GroupID.
      ---      With New GroupID and New QuoteID, copy existing QuoteItems
      ---      Repeat Step 7 for as many existing Groups present
      -----------------------------------------------------------
      select @LI_Max = count(GroupID) from @LT_Group
      While @LI_Min <= @LI_Max
      begin
        select @LBI_GroupID = GroupID from @LT_Group where SEQ = @LI_Min

        Insert into QUOTES.dbo.[Group](QuoteIDSeq,DiscAllocationCode,Name,Description,
                                       CustomerIDSeq,OverrideFlag,ShowDetailPriceFlag,
                                       AllowProductCancelFlag,GroupType,CustomBundleNameEnabledFlag
                                       )
        select @LVC_NewQuoteID as QuoteIDSeq,G.DiscAllocationCode,G.Name,G.Description,
               @IPVC_CompanyID as CustomerIDSeq,G.OverrideFlag,
               G.ShowDetailPriceFlag,G.AllowProductCancelFlag,G.GroupType,
               G.CustomBundleNameEnabledFlag
        from  QUOTES.dbo.[Group] G with (nolock)
        where G.QuoteIDSeq = @IPVC_ExistingQuoteID
        and   G.IDSeq      = @LBI_GroupID
 
        --Get the New groupID Generated 
        select @LBI_NewGroupID =  SCOPE_IDENTITY()
        --------------------------------------------------------------------------------------------------
        --Step 7.1: If @IPI_CopyGroupPropertiesFlag = 1, then copy GroupProperties from existing Quote and Group
        --        as New Quote and Group.
        --------------------------------------------------------------------------------------------------
        if @IPI_CopyGroupPropertiesFlag = 1
        begin
          Insert into QUOTES.dbo.GroupProperties(QuoteIDSeq,GroupIDSeq,PropertyIDSeq,CustomerIDSeq,PriceTypeCode,
                                                 ThresholdOverrideFlag,AnnualizedILFAmount,AnnualizedAccessAmount,
                                                 Units,Beds,PPUPercentage)
          select distinct
                 @LVC_NewQuoteID as QuoteIDSeq,@LBI_NewGroupID as GroupIDSeq,
                 GP.PropertyIDSeq,GP.CustomerIDSeq,GP.PriceTypeCode,GP.ThresholdOverrideFlag,
                 0 AnnualizedILFAmount,0 AnnualizedAccessAmount,
                 P.Units,P.Beds,P.PPUPercentage
          From  QUOTES.dbo.[GroupProperties] GP with (nolock)
          inner join 
                CUSTOMERS.DBO.Property P with (nolock)
          on    GP.PropertyIDSeq = P.IDSeq 
          and   GP.QuoteIDSeq = @IPVC_ExistingQuoteID
          and   GP.GroupIDSeq = @LBI_GroupID
          and   P.StatusTypeCode = 'ACTIV'
        end
        --------------------------------------------------------------------------------------------------
	      --Insert QuoteItem from Existing.
        Insert into QUOTES.dbo.QuoteItem(QuoteIDSeq,GroupIDSeq,ProductCode,ChargeTypeCode,FrequencyCode,MeasureCode,
                                         FamilyCode,PublicationYear,PublicationQuarter,
                                         AllowProductCancelFlag,PriceVersion,Sites,Units,Beds,PPUPercentage,
                                         Quantity,MinUnits,MaxUnits,ChargeAmount,
                                         DiscountPercent,DiscountAmount,NetChargeAmount,
                                         capmaxunitsflag,dollarminimum,dollarmaximum,CredtCardPricingPercentage,
                                         excludeforbookingsflag,crossfiremaximumallowablecallvolume)
        select @LVC_NewQuoteID as QuoteIDSeq,@LBI_NewGroupID as GroupIDSeq,
               QI.ProductCode,QI.ChargeTypeCode,QI.FrequencyCode,QI.MeasureCode,
               QI.FamilyCode,QI.PublicationYear,QI.PublicationQuarter,
               QI.AllowProductCancelFlag,QI.PriceVersion,
               0 as Sites,0 as Units,0 as Beds,0 as PPUPercentage,QI.Quantity,
               QI.MinUnits,QI.MaxUnits,
               QI.ChargeAmount,QI.DiscountPercent,QI.DiscountAmount,QI.NetChargeAmount,
               QI.capmaxunitsflag,QI.dollarminimum,QI.dollarmaximum,QI.CredtCardPricingPercentage,
               QI.excludeforbookingsflag,QI.crossfiremaximumallowablecallvolume
        from   QUOTES.dbo.QuoteItem QI with (nolock)
        where  QI.QuoteIDSeq    = @IPVC_ExistingQuoteID
        and    QI.GroupIDSeq    = @LBI_GroupID 
        and    QI.productcode <> 'DMD-PSR-ADM-ADM-AMTF'
        --------------------------------------------------------------------------------
        -----Step 7.2: Updates Sites,Units,Beds and PPUPercentage for new QuoteItem 
        --------------------------------------------------------------------------------
        Update QI
        set    QI.Sites = S.Sites,
               QI.Units = S.Units,
               QI.Beds  = S.Beds,
               QI.PPUPercentage = S.PPUPercentage
        from   QUOTES.dbo.QuoteItem QI with (nolock) inner join 
               (select GP.QuoteIDSeq as QuoteIDSeq,GP.GroupIDSeq as GroupIDSeq,
                      count(GP.PropertyIdseq) as Sites,Sum(GP.Units) as Units,
                      sum(GP.Beds) as Beds,Sum(GP.PPUPercentage) as PPUPercentage 
               from  Quotes.dbo.GroupProperties GP With (nolock)
               where GP.QuoteIDSeq = @LVC_NewQuoteID
               and   GP.GroupIDSeq = @LBI_NewGroupID
               GROUP BY GP.QuoteIDSeq,GP.GroupIDSeq) S
        on    QI.QuoteIDSeq = S.QuoteIDSeq
        and   QI.GroupIDSeq = S.GroupIDSeq
        and   QI.QuoteIDSeq = @LVC_NewQuoteID
        and   QI.GroupIDSeq = @LBI_NewGroupID
        and   S.QuoteIDSeq  = @LVC_NewQuoteID
        and   S.GroupIDSeq  = @LBI_NewGroupID
        --------------------------------------------------------------------------------
        -----Step 7.3: Updates Sites,Units,Beds and PPUPercentage for new Group 
        --------------------------------------------------------------------------------
        Update G
        set    G.Sites = S.Sites,
               G.Units = S.Units,
               G.Beds  = S.Beds,
               G.PPUPercentage = S.PPUPercentage
        from   QUOTES.dbo.[Group] G with (nolock) inner join 
               (select GP.QuoteIDSeq as QuoteIDSeq,GP.GroupIDSeq as GroupIDSeq,
                      count(GP.PropertyIdseq) as Sites,Sum(GP.Units) as Units,
                      sum(GP.Beds) as Beds,Sum(GP.PPUPercentage) as PPUPercentage 
               from  Quotes.dbo.GroupProperties GP With (nolock)
               where GP.QuoteIDSeq = @LVC_NewQuoteID
               and   GP.GroupIDSeq = @LBI_NewGroupID
               GROUP BY GP.QuoteIDSeq,GP.GroupIDSeq) S
        on    G.QuoteIDSeq = S.QuoteIDSeq
        and   G.IDSeq      = S.GroupIDSeq
        and   G.QuoteIDSeq = @LVC_NewQuoteID
        and   G.IDSeq      = @LBI_NewGroupID
        and   S.QuoteIDSeq = @LVC_NewQuoteID
        and   S.GroupIDSeq = @LBI_NewGroupID
        --------------------------------------------------------------------------------
        -----Step 7.4:Call to Price Engine to reprice the New Quote's Group
        EXEC Quotes.dbo.uspQUOTES_SyncGroupAndQuote @IPVC_QuoteID=@LVC_NewQuoteID,@IPI_GroupID=@LBI_NewGroupID
        -------------------------------------------------------------------------------- 
        select @LI_Min = @LI_Min+1
      end
    COMMIT TRANSACTION
  ---------------------------------------------------------------------------------------------
  END TRY
  BEGIN CATCH    
    -- XACT_STATE:
       -- If 1, the transaction is committable.
       -- If -1, the transaction is uncommittable and should be rolled back.
       -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
    if (XACT_STATE()) = -1
    begin
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    end
    else if (XACT_STATE()) = 1
    begin
      IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
    end  
    select @LVC_ErrorCodeSection = 'Failed To Groups for Template Quote Copy Of : ' + @IPVC_ExistingQuoteID
    exec QUOTES.dbo.uspQUOTES_DeleteQuote @IPVC_CompanyID = @IPVC_CompanyID,@IPVC_QuoteID = @LVC_NewQuoteID
    exec CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] @IPVC_CodeSection = @LVC_ErrorCodeSection  
    RETURN     
  END CATCH
  ---------------------------------------------------------------------------------------------  
  ---Step 9: Updates Sites,Units,Beds and PPUPercentage for new Quote 
  ---------------------------------------------------------------------------------------------  
  Update Q
  set    Q.Sites = S.Sites,
         Q.Units = S.Units,
         Q.Beds  = S.Beds
  from   QUOTES.dbo.[Quote] Q with (nolock) inner join 
             (select GP.QuoteIDSeq as QuoteIDSeq,
                     count(GP.PropertyIdseq) as Sites,Sum(GP.Units) as Units,
                     sum(GP.Beds) as Beds,Sum(GP.PPUPercentage) as PPUPercentage 
              from  Quotes.dbo.GroupProperties GP With (nolock)
              where GP.QuoteIDSeq = @LVC_NewQuoteID
              GROUP BY GP.QuoteIDSeq
              ) S
  on    Q.QuoteIDSeq = S.QuoteIDSeq        
  and   Q.QuoteIDSeq = @LVC_NewQuoteID       
  and   Q.QuoteIDSeq = @LVC_NewQuoteID
  ---------------------------------------------------------------------------------------------  
  -- Step 8: Call Price Engine for the Entire New Quote
  EXEC Quotes.dbo.uspQUOTES_SyncGroupAndQuote @IPVC_QuoteID=@LVC_NewQuoteID
  ---------------------------------------------------------------------------------------------  
  ----------------------------------------------------------------------------------------
  --Get Existing Documents for Existing @IPVC_ExistingQuoteID
  Insert into @LT_ExistingDocuments(ExistingDocumentIDSeq)
  select IDSeq 
  from   Quotes.dbo.QuoteItemNote with (nolock)
  where  QuoteIDSeq = @IPVC_ExistingQuoteID 

  select Top 1 @LBI_QuoteItemIDSeq = QI.IDSeq
  from   Quotes.dbo.QuoteItem QI with (nolock)
  where  QI.QuoteIDSeq  = @LVC_NewQuoteID
  and    QI.ProductCode = 'DMD-OSD-PAY-PAY-PPAY'

  --Insert Documents for Newly created Quote
  select @LI_Max = count(*) from @LT_ExistingDocuments
  select @LI_Min=1
  while @LI_Min <= @LI_Max
  begin
    select @LVC_ExistingDocumentIDSeq = ExistingDocumentIDSeq 
    from @LT_ExistingDocuments where SEQ = @LI_Min
    begin TRY
      BEGIN TRANSACTION; 
        
        
        Insert into Quotes.dbo.QuoteItemNote(QuoteIDSeq,Title,Description,MandatoryFlag,PrintOnOrderFormFlag,SortSeq,CreatedDate)
        select @LVC_NewQuoteID as QuoteIDSeq,Title,Description,MandatoryFlag,PrintOnOrderFormFlag,SortSeq,CreatedDate
        from   Quotes.dbo.QuoteItemNote with (nolock)
        where  IDSeq            = @LVC_ExistingDocumentIDSeq 
        and    QuoteIDSeq       = @IPVC_ExistingQuoteID 
        COMMIT TRANSACTION;
    end TRY
    begin CATCH    
          -- XACT_STATE:
          -- If 1, the transaction is committable.
          -- If -1, the transaction is uncommittable and should be rolled back.
          -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
      if (XACT_STATE()) = -1
      begin
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
      end
      else if (XACT_STATE()) = 1
      begin
        IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
      end   
      select @LVC_ErrorCodeSection = 'uspQUOTES_CreateTemplateQuote : Document Insert Failed for Quote'+ @LVC_NewQuoteID
      exec QUOTES.dbo.uspQUOTES_DeleteQuote @IPVC_CompanyID = @IPVC_CompanyID,@IPVC_QuoteID = @LVC_NewQuoteID
      exec CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] @IPVC_CodeSection = @LVC_ErrorCodeSection 
      RETURN
    end CATCH
    SELECT @LI_Min = @LI_Min + 1
  end
  ---------------------------------------------------------------------------------
  --Reinitializing Local Variables for Further use down the code stream
  select @LI_Min=1,@LI_Max=0
  ---------------------------------------------------------------------------------


  
  --Final Cleanup
  --IF @@TRANCOUNT > 0 COMMIT TRANSACTION;  
  ---------------------------------------------------------------------------------------------
  -- Final Select to return newly Generated QuoteId
  select @LVC_NewQuoteID as QuoteIDSeq
  ---------------------------------------------------------------------------------------------
END
GO
