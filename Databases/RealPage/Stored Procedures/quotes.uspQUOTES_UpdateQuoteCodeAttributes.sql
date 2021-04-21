SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--exec uspQUOTES_UpdateQuoteCodeAttributes @IPVC_QuoteID = 3
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : uspQUOTES_UpdateQuoteCodeAttributes
-- Description     : This procedure is called from UI to update Code Attributes for a given Quote
-- Input Parameters: 1. @IPVC_QuoteID   as varchar(20)
--
--                   
-- OUTPUT          : None
--  
--                   
-- Code Example    : exec QUOTES.dbo.uspQUOTES_UpdateQuoteCodeAttributes @IPVC_QuoteID = 'Q1104001010'...
-- 
-- 
-- Author          : SRS
-- 05/15/2011      : Stored Procedure Created. TFS # 267 Deal Desk Project
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_UpdateQuoteCodeAttributes]  (@IPVC_QuoteIDSeq                 varchar(50),        ---> MANDATORY : QuoteID Q.... This is  QuoteID from UI
                                                               @IPVC_QuoteStatusCode            varchar(5),         ---> MANDATORY : This is quote status code of the Quote depending on operation.
                                                                                                                        --NSU for Not Submitted (default), SUB for Submit,CNL for Cancel,APR for Approve.
                                                                                                                        --eg: UI to pass this as NSU to put quote back to not submit state                                                                                                                        
                                                               @IPVC_QuoteDescription           varchar(1000)='',   ---> Optional  : This is Quote Description. 
                                                                                                                     --  Pass Blank if UI does not have it or UI has it as N/A or UI does not want to update.
                                                               @IPVC_ClientServiceRepIDSeq      varchar(50)  ='',   ---> Optional  : This is  CSRIDSeq -- Client Service Rep ID from Drop down selected.
                                                                                                                     --  Pass Blank if UI does not have it or UI has it as 0 or UI does not want to update. 
                                                               @IPVC_ExpirationDate             varchar(50)  ='',   ---> Optional : This is Expiration date already available in UI
                                                                                                                     --  Pass Blank if UI does not have it or Pass value what UI has it.
                                                               @IPVC_CancelledDate              varchar(50)  ='',   ---> Optional : This is Cancel date already available in UI
                                                                                                                     --  Pass Blank if UI does not have it or Pass value what UI has it.                 
                                                               @IPVC_SubmittedDate              varchar(50)  ='',   ---> Optional : This is SubmittedDate date already available in UI
                                                                                                                      --  Pass Blank if UI does not have it or Pass value what UI has it.
                                                               @IPVC_ApprovedDate               varchar(50)  ='',   ---> Optional : This is ApprovedDate date already available in UI
                                                                                                                      --  Pass Blank if UI does not have it or Pass value what UI has it.
                                                               @IPI_DealDeskReferenceLevel      int          =0,    ---> Optional: This is  Deal Desk Reference Level. Default is 0
                                                                                                                      --  UI will pass this based on Deal Desk Expression evaluation.
                                                               @IPI_DealDeskCurrentLevel        int          =0,    ---> Optional: This is  Deal Desk Reference Level. Default is 0
                                                                                                                      --  UI will pass this based on Deal Desk Expression evaluation.
                                                               @IPVC_DealDeskStatusCode         varchar(4)   ='NSU',---> Optional: This is Deal Desk Status Code
                                                                                                                      --  Default is NSU (Deal Desk Not Submitted).
                                                                                                                      --  SUB (For Deal Desk  Submitted).DNY for Deal Desk  Denied. APR for Deal Desk Approved.                                                                                                                      
                                                               @IPVC_DealDeskQueuedDate         varchar(50)  ='',   ---> Optional : This is DealDeskQueuedDate date already available in UI
                                                               @IPVC_DealDeskQueuedByIDSeq      varchar(50)  ='',   ---> Optional  : This is  DealDeskQueuedByIDSeq -- Deal Desk Queued Date
                                                                                                                     --  Pass Blank if UI does not have it or UI has it as 0 or UI does not want to update. 

                                                                                                                      --  Pass Blank if UI does not have it or Pass value what UI has it.
                                                               @IPVC_DealDeskDecisionMadeBy     varchar(100) ='',   ---> Optional: This is Full name of Person who is making decision on the Deal Desk Quote outside of Client Services
                                                                                                                      -- When @IPVC_DealDeskStatusCode is DNY or APR, this becomes mandatory to record the data.
                                                               @IPVC_DealDeskNote               varchar(1000)='',   ---> Optional: This is Deal Desk Note when Note is entered for Approval or denial of Deal Desk.
                                                                                                                      -- Pass Blank if UI does not have it. UI will enforce this to 1000 characters.
                                                               @IPVC_DealDeskResolvedByIDSeq    varchar(50)  ='',   ---> Optional  : To Record UserID of person logged on to record Deal Desk Decision on behalf of DealDeskDecisionMadeBy
                                                                                                                      --  Pass Blank if UI does not have it or UI has it as N/A or UI does not want to update. 
                                                               @IPVC_DealDeskResolvedDate       varchar(50)  ='',   ---> Optional : This is DealDeskQueuedDate date already available in UI
                                                                                                                      --  Pass Blank if UI does not have it or the date that UI has it.
                                                               @IPI_PrepaidFlag			        int          =0,    ---> Optional: This quote is an "Instant Invoice"
                                                               @IPVC_RequestedBy                varchar(70)  ='',    ---> This is RequestedBy (For Instant Invoice Prepaid Quote). 
                                                                                                                      --  UI to pass value if known. Else Pass Blank. 
                                                               @IPBI_UserIDSeq                  bigint              ---> MANDATORY : User ID of the User Logged on and operating on the Quote.
                                                                
                                                          ) 
AS
BEGIN -- :Main Begin
  set nocount on;
  ------------------------------------
  declare @LDT_SystemDate  datetime
  select  @LDT_SystemDate = getdate()
  ------------------------------------
  select @IPVC_QuoteDescription        = nullif(nullif(ltrim(rtrim(@IPVC_QuoteDescription)),'N/A'),''),
         @IPVC_ClientServiceRepIDSeq   = nullif(nullif(ltrim(rtrim(@IPVC_ClientServiceRepIDSeq)),'0'),''),
         @IPVC_ExpirationDate          = (case when isdate(@IPVC_ExpirationDate)=0 then NULL
                                               else @IPVC_ExpirationDate
                                          end),
         @IPVC_CancelledDate           = (case when (isdate(@IPVC_CancelledDate)=0 or @IPVC_CancelledDate = '01/01/1900') then NULL
                                               else @IPVC_CancelledDate
                                          end), 
         @IPVC_SubmittedDate           = (case when (isdate(@IPVC_SubmittedDate)=0 or @IPVC_SubmittedDate = '01/01/1900') then NULL
                                               else @IPVC_SubmittedDate
                                          end),
         @IPVC_ApprovedDate            = (case when (isdate(@IPVC_ApprovedDate)=0 or @IPVC_ApprovedDate = '01/01/1900')  then NULL
                                               else @IPVC_ApprovedDate
                                          end),
         @IPVC_DealDeskQueuedDate      = (case when (isdate(@IPVC_DealDeskQueuedDate)=0 or @IPVC_DealDeskQueuedDate = '01/01/1900' ) then NULL
                                               else @IPVC_DealDeskQueuedDate
                                          end),
         @IPVC_DealDeskQueuedByIDSeq   = nullif(nullif(ltrim(rtrim(@IPVC_DealDeskQueuedByIDSeq)),'0'),''),
         @IPVC_DealDeskDecisionMadeBy  = nullif(ltrim(rtrim(@IPVC_DealDeskDecisionMadeBy)),''),
         @IPVC_DealDeskNote            = nullif(nullif(ltrim(rtrim(@IPVC_DealDeskNote)),'N/A'),''),
         @IPVC_DealDeskResolvedByIDSeq = nullif(nullif(ltrim(rtrim(@IPVC_DealDeskResolvedByIDSeq)),'0'),''),
         @IPVC_DealDeskResolvedDate    = (case when (isdate(@IPVC_DealDeskResolvedDate)=0 or @IPVC_DealDeskResolvedDate = '01/01/1900') then NULL
                                               else @IPVC_DealDeskResolvedDate
                                          end),
         @IPVC_RequestedBy             = nullif(ltrim(rtrim(@IPVC_RequestedBy)),'');
  ------------------------------------
  Update Quotes.dbo.Quote
  set    QuoteStatusCode               = coalesce(@IPVC_QuoteStatusCode,QuoteStatusCode),
         [Description]                 = coalesce(@IPVC_QuoteDescription,nullif(nullif(ltrim(rtrim([Description])),'N/A'),''))
        ,[CSRIDSeq]                    = coalesce(@IPVC_ClientServiceRepIDSeq,nullif(nullif(ltrim(rtrim([CSRIDSeq])),'0'),''))
        ,[ExpirationDate]              = coalesce(@IPVC_ExpirationDate,ExpirationDate)
        ,[CancelledDate]               = (case when coalesce(@IPVC_QuoteStatusCode,QuoteStatusCode) = 'CNL'
                                                  then coalesce(@IPVC_CancelledDate,CancelledDate)
                                               else NULL
                                          end)
        ,[SubmittedDate]               = (case when coalesce(@IPVC_QuoteStatusCode,QuoteStatusCode) = 'NSU'
                                                  then NULL 
                                               else coalesce(@IPVC_SubmittedDate,SubmittedDate)
                                          end) 
        ,[ApprovalDate]                = (case when coalesce(@IPVC_QuoteStatusCode,QuoteStatusCode) = 'NSU'
                                                  then NULL 
                                               when coalesce(@IPVC_QuoteStatusCode,QuoteStatusCode) = 'SUB'
                                                  then NULL   
                                               else coalesce(@IPVC_ApprovedDate,ApprovalDate)
                                          end) 
        ,[AcceptanceDate]              = (case when coalesce(@IPVC_QuoteStatusCode,QuoteStatusCode) = 'NSU'
                                                  then NULL 
                                               when coalesce(@IPVC_QuoteStatusCode,QuoteStatusCode) = 'SUB'
                                                  then NULL
                                               else coalesce(@IPVC_ApprovedDate,ApprovalDate)
                                          end) 
        ,DealDeskReferenceLevel        = @IPI_DealDeskReferenceLevel
        ,DealDeskCurrentLevel          = @IPI_DealDeskCurrentLevel
        ,DealDeskStatusCode            = @IPVC_DealDeskStatusCode
        ,DealDeskQueuedDate            = (case when (coalesce(@IPVC_QuoteStatusCode,QuoteStatusCode)       = 'NSU'
                                                              and
                                                     coalesce(@IPVC_DealDeskStatusCode,DealDeskStatusCode) = 'NSU'
                                                    )
                                                  then NULL
                                               when coalesce(@IPVC_DealDeskStatusCode,DealDeskStatusCode)  = 'SUB'
                                                  then coalesce(@IPVC_DealDeskQueuedDate,DealDeskQueuedDate,@LDT_SystemDate)
                                               else coalesce(@IPVC_DealDeskQueuedDate,DealDeskQueuedDate)
                                          end)
        ,DealDeskQueuedByIDSeq         = (case when (coalesce(@IPVC_QuoteStatusCode,QuoteStatusCode)       = 'NSU'
                                                              and
                                                     coalesce(@IPVC_DealDeskStatusCode,DealDeskStatusCode) = 'NSU'
                                                    )
                                                  then NULL
                                               when coalesce(@IPVC_DealDeskStatusCode,DealDeskStatusCode)  = 'SUB'
                                                  then coalesce(@IPVC_DealDeskQueuedByIDSeq,DealDeskQueuedByIDSeq,@IPBI_UserIDSeq)                                               
                                               else coalesce(@IPVC_DealDeskQueuedByIDSeq,DealDeskQueuedByIDSeq) 
                                          end)
        ,DealDeskDecisionMadeBy       = (case when (coalesce(@IPVC_QuoteStatusCode,QuoteStatusCode)        = 'NSU'
                                                              and
                                                     coalesce(@IPVC_DealDeskStatusCode,DealDeskStatusCode) = 'NSU'
                                                    )
                                                 then NULL
                                               when coalesce(@IPVC_DealDeskStatusCode,DealDeskStatusCode)  in ('APR','DNY')
                                                  then coalesce(@IPVC_DealDeskDecisionMadeBy,DealDeskDecisionMadeBy)
                                               else coalesce(@IPVC_DealDeskDecisionMadeBy,DealDeskDecisionMadeBy)
                                          end) 
        ,DealDeskNote                  = (case when (coalesce(@IPVC_QuoteStatusCode,QuoteStatusCode)       = 'NSU'
                                                              and
                                                     coalesce(@IPVC_DealDeskStatusCode,DealDeskStatusCode) = 'NSU'
                                                    )
                                                  then NULL
                                               when coalesce(@IPVC_DealDeskStatusCode,DealDeskStatusCode)  in ('APR','DNY')
                                                  then coalesce(@IPVC_DealDeskNote,DealDeskNote)
                                               else coalesce(@IPVC_DealDeskNote,DealDeskNote)
                                          end) 
        ,DealDeskResolvedByIDSeq       = (case when (coalesce(@IPVC_QuoteStatusCode,QuoteStatusCode)       = 'NSU'
                                                              and
                                                     coalesce(@IPVC_DealDeskStatusCode,DealDeskStatusCode) = 'NSU'
                                                    )
                                                  then NULL
                                               when coalesce(@IPVC_DealDeskStatusCode,DealDeskStatusCode)  in ('APR','DNY')
                                                  then coalesce(@IPVC_DealDeskResolvedByIDSeq,DealDeskResolvedByIDSeq)
                                               else coalesce(@IPVC_DealDeskResolvedByIDSeq,DealDeskResolvedByIDSeq)
                                          end) 
        ,DealDeskResolvedDate           = (case when (coalesce(@IPVC_QuoteStatusCode,QuoteStatusCode)       = 'NSU'
                                                             and
                                                      coalesce(@IPVC_DealDeskStatusCode,DealDeskStatusCode) = 'NSU'
                                                      )
                                                    then NULL
                                                when coalesce(@IPVC_DealDeskStatusCode,DealDeskStatusCode)  in ('APR','DNY')
                                                   then coalesce(@IPVC_DealDeskResolvedDate,DealDeskResolvedDate,@LDT_SystemDate)
                                                else coalesce(@IPVC_DealDeskResolvedDate,DealDeskResolvedDate)
                                          end)
        ,PrepaidFlag				   = @IPI_PrepaidFlag
        ,RequestedBy                   = coalesce(@IPVC_RequestedBy,RequestedBy)  
        ,ModifiedByIDSeq               = @IPBI_UserIDSeq
        ,ModifiedDate                  = @LDT_SystemDate
        ,SystemLogDate                 = @LDT_SystemDate
  where QuoteIDSeq = @IPVC_QuoteIDSeq;
  ------------------------------------
  exec Quotes.dbo.uspQUOTES_SyncGroupAndQuote @IPVC_QuoteID= @IPVC_QuoteIDSeq;
  ------------------------------------
END -- :Main End
GO
