SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- database  name  : invoices
-- procedure name  : [uspINVOICES_InvoicingEngine]
-- description     : This procedure determine steps to take based on input parameters, especially 
--                 : the Event parameter.
-- input parameters: @IPVC_QuoteID     varchar(50)=NULL,
--                 : @IPVC_AccountID   varchar(50),
--                 : @IPVC_CompanyID   varchar(50),
--                 : @IPVC_PropertyID  varchar(50)=NULL,
--                 : @LDT_TargetDate   datetime=NULL 
-- 	           : @LVC_Event        varchar(30) ,
-- 	           : @LBI_OrderID      varchar(50),
-- 	           : @LBI_OrderItemID  bigint NULL 
-- output          : None                          
-- code example    : 
--                  exec INVOICES.DBO.uspINVOICES_InvoicingEngine
-- 		    @IPVC_QuoteID    = null,     
-- 	            @IPVC_AccountID  = 'A0000000045',  
-- 	            @IPVC_CompanyID  = 'C0000004848',  
-- 	            @IPVC_PropertyID = 'P0000000088',
-- 	            @LDT_TargetDate  = null,  
-- 		    @LVC_Event       = 'CreateInvoice',
-- 		    @LBI_OrderID     = 70892 ,
--                  @LBI_OrderItemID = null      
----------------------------------------------------------------------------------------------------
-- Notes : Only one event will be executed at a given time. 
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- revision history:
-- Date		author		Description
----------------------------------------------------------------------------------------------------
-- 2007/08/23	gwen guidroz	updated 3 error messages to use the same procedure name as that being called.
----------------------------------------------------------------------------------------------------
CREATE procedure [invoices].[uspINVOICES_InvoicingEngine]       
     ( @IPVC_QuoteID      varchar(50)=NULL
       ,@IPVC_AccountID   varchar(50)
       ,@IPVC_CompanyID   varchar(50)
       ,@IPVC_PropertyID  varchar(50)=NULL
       ,@LDT_TargetDate   datetime=NULL --used for creating invoices
       ,@LVC_Event        varchar(30) 
       ,@LBI_OrderID      varchar(50)
       ,@LBI_OrderItemID  bigint = null
     )  
as
begin
-- declare @IPVC_QuoteID      varchar(50)
-- declare @IPVC_AccountID   varchar(50)
-- declare @IPVC_CompanyID   varchar(50)
-- declare @IPVC_PropertyID  varchar(50)
-- declare @LDT_TargetDate   datetime
-- declare @LVC_Event        varchar(30) 
-- declare @LBI_OrderID      varchar(50)
-- declare @LBI_OrderItemID  bigint
-- 
-- set @IPVC_QuoteID    = null  
-- set @IPVC_AccountID  = 'A0000000045'
-- set @IPVC_CompanyID  = 'C0000004848'
-- set @IPVC_PropertyID = 'P0000000088'
-- set @LDT_TargetDate  = null
-- set @LVC_Event       = 'CreateInvoice'
-- set @LBI_OrderID     = '70892' 
-- set @LBI_OrderItemID = null

        ----------------------------------------------------------------------
	--declare variables - 
	----------------------------------------------------------------------
        create table #temp_CreateInvoiceHoldingTable (SQLErrorcode varchar(50),
                                                      InvoiceID    varchar(50)
                                                      )  
        ----------------------------------------------------------------------
        --for error handling 
        declare @SQLErrorCode                 int--if 0 succcessful, else error.
        declare @ErrorDescription             varchar(300)
        declare @LI_DebugCode                 int 
        declare @LVC_InvoiceID                varchar(50)
        ----------------------------------------------------------------------
	--Initialize variables - 
	----------------------------------------------------------------------
        set  @LI_DebugCode = 0 
        if (@IPVC_PropertyID = '')  select @IPVC_PropertyID = NULL
        if (@IPVC_QuoteID = '')     select @IPVC_QuoteID = NULL

	if (@LDT_TargetDate is null or @LDT_TargetDate = '' )   --incase target date was not supplied.
	begin 
	select @LDT_TargetDate = dateadd(dd,45,getdate()) --changed from 50 to 45
	end
        ----------------------------------------------------------------------
	--When "GenerateOrders" link is clicked. 
        --Procedure call to uspINVOICES_CreateInvoice will do following -
        --1. create an invoice for an account if there is none.
        --2. create invoice line items if dates are populated and is within
        --   billing target date range. 
	----------------------------------------------------------------------
	if @LVC_Event = 'CreateInvoice' 
	begin           
          insert into #temp_CreateInvoiceHoldingTable(SQLErrorcode,InvoiceID)
  	  exec  INVOICES.dbo.uspINVOICES_CreateInvoice
		    @IPVC_QuoteID    = @IPVC_QuoteID,     --optional parameter.
	            @IPVC_AccountID  = @IPVC_AccountID,   --required paramter.
	            @IPVC_CompanyID  = @IPVC_CompanyID,   --required parameter.
	            @IPVC_PropertyID = @IPVC_PropertyID,  --optional parameter.
	            @LDT_TargetDate  = @LDT_TargetDate,   --optional parameter,if null, it will be calculated based on getdate()
		    @LVC_Event       = @LVC_Event,        --required input parameter.
		    @LBI_OrderID     = @LBI_OrderID      --required input parameter.
    
          select Top 1 @SQLErrorcode = SQLErrorcode,
                        @LVC_InvoiceID= InvoiceID
          from   #temp_CreateInvoiceHoldingTable with (nolock)          
	end         
        
        -- display messages -- 
        if @LI_DebugCode = 1 
        begin 
             if @SQLErrorCode <> 0
             begin
	     select 'error occured while calling stored procedure = invoices.dbo.uspINVOICES_CreateInvoice'
	     select @SQLErrorCode [ProcedureStatus],-1 [ErrorNumber], @ErrorDescription [ErrorMessage]
	     return
             end

        select 	'exec @SQLErrorCode = INVOICES.dbo.uspINVOICES_CreateInvoice' + 
		    ' @IPVC_QuoteID = ' + @IPVC_QuoteID +         --optional parameter.
	            ' ,@IPVC_AccountID  = ' + @IPVC_AccountID +   --required paramter.
	            ' ,@IPVC_CompanyID  = ' + @IPVC_CompanyID  +  --required parameter.
	            ' ,@IPVC_PropertyID = ' + @IPVC_PropertyID +  --optional parameter.
	            ' ,@LDT_TargetDate  = ' + @LDT_TargetDate +   --optional parameter,if null, it will be calculated based on getdate()
		    ' ,@LVC_Event       = ' + @LVC_Event +        --required input parameter.
		    ' ,@LBI_OrderID     = ' + @LBI_OrderID +      --required input parameter.
		    ' ,@LBI_OrderItemID = ' + null                --optional input parameter.
	
        end
	----------------------------------------------------------------------
        --when there is a change on an order line item, for example - when 
        -- user changes dates, prices, ppu % increase or decrease etc. 
        -- Call to uspINVOICES_ReCreateInvoiceItem will do following - 
        --1. It requires an OrderItemIDSeq to remove invoice line items 
        --  associated with this OrderItemIDSeq and then re-insert if that 
        --  invoice line items if dates are populated and is within billing 
        --  target date range. 
	----------------------------------------------------------------------
        --Validation Query to check if @LBI_OrderID is passed. 
        ----------------------------------------------------------------------
	if @LVC_Event = 'ReCreateInvoiceItem'and @LBI_OrderItemID is not null
	begin 
        insert into #temp_CreateInvoiceHoldingTable(SQLErrorcode,InvoiceID)
	exec @SQLErrorCode = invoices.dbo.uspINVOICES_ReCreateInvoiceItem
		    @IPVC_QuoteID    = @IPVC_QuoteID,     --optional parameter.
	            @IPVC_AccountID  = @IPVC_AccountID,   --required paramter.
	            @IPVC_CompanyID  = @IPVC_CompanyID,   --required parameter.
	            @IPVC_PropertyID = @IPVC_PropertyID,  --optional parameter.
	            @LDT_TargetDate  = @LDT_TargetDate,   --optional parameter,if null, it will be calculated based on getdate()
		    @LVC_Event       = @LVC_Event,        --required input parameter.
		    @LBI_OrderID     = @LBI_OrderID,      --required input parameter.
		    @LBI_OrderItemID = @LBI_OrderItemID   --required input parameter here! 

          select Top 1 @SQLErrorcode = SQLErrorcode,
                        @LVC_InvoiceID= InvoiceID
          from   #temp_CreateInvoiceHoldingTable with (nolock)    
	end 
        

       -- display custom messages -- 
       if @LI_DebugCode = 1 
       begin 
             if @SQLErrorCode <> 0
             begin
	     select 'error occured in stored procedure = invoices.dbo.uspINVOICES_ReCreateInvoiceItem'
	     select @SQLErrorCode [ProcedureStatus],-1 [ErrorNumber], @ErrorDescription [ErrorMessage]
	     return
             end
        select 	'exec @SQLErrorCode = INVOICES.dbo.uspINVOICES_ReCreateInvoiceItem' + 
		    ' @IPVC_QuoteID = ' + @IPVC_QuoteID +         --optional parameter.
	            ' ,@IPVC_AccountID  = ' + @IPVC_AccountID +   --required paramter.
	            ' ,@IPVC_CompanyID  = ' + @IPVC_CompanyID  +  --required parameter.
	            ' ,@IPVC_PropertyID = ' + @IPVC_PropertyID +  --optional parameter.
	            ' ,@LDT_TargetDate  = ' + @LDT_TargetDate +   --optional parameter,if null, it will be calculated based on getdate()
		    ' ,@LVC_Event       = ' + @LVC_Event +        --required input parameter.
		    ' ,@LBI_OrderID     = ' + @LBI_OrderID +      --required input parameter.
		    ' ,@LBI_OrderItemID = ' + @LBI_OrderItemID    --required input parameter.
        end
	----------------------------------------------------------------------
        --For recurring invoice - monthly billing 
        --This step is intended for back end process when order line items 
        --that are in the middle of a billing cycle will be picked up by this 
        --stored procedure if dates fall within in the Target billing date 
        --range. 
	----------------------------------------------------------------------
--         if @LVC_Event = 'RecurringInvoice' and (@LBI_OrderID is null or @LBI_OrderID= '')  
--         begin 
--         exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = '@LBI_OrderID is blank.' 
--         end 
        
	if (@LVC_Event = 'RecurringInvoice'and @LBI_OrderID is not null)
	begin 
            insert into #temp_CreateInvoiceHoldingTable(SQLErrorcode,InvoiceID)
	    exec @SQLErrorCode = invoices.dbo.uspINVOICES_CreateRecurringInvoice
	            @IPVC_AccountID  = @IPVC_AccountID,   --required paramter.
	            @IPVC_CompanyID  = @IPVC_CompanyID,   --required parameter.
	            @IPVC_PropertyID = @IPVC_PropertyID,  --optional parameter.
	            @LDT_TargetDate  = @LDT_TargetDate,   --optional parameter,if null, it will be calculated based on getdate()
		    @LVC_Event       = @LVC_Event,        --required input parameter.
		    @IPVC_OrderID     = @LBI_OrderID      --required input parameter.

          select Top 1 @SQLErrorcode = SQLErrorcode,
                        @LVC_InvoiceID= InvoiceID
          from   #temp_CreateInvoiceHoldingTable with (nolock)    
	end 
        
       -- display custom messages -- 
       if @LI_DebugCode = 1 
       begin 

                if (@LVC_Event = 'RecurringInvoice' and (@LBI_OrderID is null or @LBI_OrderID= ''))
                begin 
	        select @ErrorDescription = '@LBI_OrderID is null or blank, please provide a valid @LBI_OrderID for [RecurringInvoice] event.'
	        select @LBI_OrderItemID [OrderItemIDSeq], -1 [ErrorNumber], @ErrorDescription [ErrorMessage]
                end
    
                if @SQLErrorCode <> 0
                begin
	        select 'error occured in stored procedure = invoices.dbo.uspINVOICES_CreateRecurringInvoice'
	        select @SQLErrorCode [ProcedureStatus],-1 [ErrorNumber], @ErrorDescription [ErrorMessage]
                end
          select  'exec @SQLErrorCode = INVOICES.dbo.uspINVOICES_CreateRecurringInvoice' + 
		    ' @IPVC_QuoteID = ' + @IPVC_QuoteID +         --optional parameter.
	            ' ,@IPVC_AccountID  = ' + @IPVC_AccountID +   --required paramter.
	            ' ,@IPVC_CompanyID  = ' + @IPVC_CompanyID  +  --required parameter.
	            ' ,@IPVC_PropertyID = ' + @IPVC_PropertyID +  --optional parameter.
	            ' ,@LDT_TargetDate  = ' + @LDT_TargetDate +   --optional parameter,if null, it will be calculated based on getdate()
		    ' ,@LVC_Event       = ' + @LVC_Event +        --required input parameter.
		    ' ,@LBI_OrderID     = ' + @LBI_OrderID +      --required input parameter.
		    ' ,@LBI_OrderItemID = ' + @LBI_OrderItemID    --required input parameter.
        end
  -----------------------------------------------------------------------
  -- Final Select to send invoice id to UI
  if (@LVC_InvoiceID is not null)
    select @LVC_InvoiceID as InvoiceID
  -----------------------------------------
  -- drop temp tables
  drop table #temp_CreateInvoiceHoldingTable
  -----------------------------------------------------------------------
end 

GO
