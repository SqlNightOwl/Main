SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--------------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_RegAdminQueueTableInsert]
-- Description     : Insert values into the RegAdminQueue table - a later process will update REGISTERDB
--------------------------------------------------------------------------------------------------------
CREATE procedure [customers].[uspCUSTOMERS_RegAdminQueueTableInsert] (@IPVC_AccountID      varchar(50),
                                                                @IPVC_OrderID        varchar(50) = '',
                                                                @IPVC_OrderItemIDSeq varchar(50) = ''
                                                               )
AS
BEGIN
  set nocount on;
  set @IPVC_OrderID = nullif(@IPVC_OrderID,'');
  set @IPVC_OrderItemIDSeq = nullif(@IPVC_OrderItemIDSeq,'');
  -------------------------------------------
  If (@IPVC_OrderID is NULL or @IPVC_OrderID = '')
  begin
    If not exists (select top 1 1 from Orders.dbo.Regadminqueue with (nolock)
                   where  AccountIDSeq = @IPVC_AccountID
                   and    OrderIDSeq is null
                  )
    begin
      Insert into Orders.dbo.Regadminqueue(AccountIDSeq,OrderIDSeq,OrderItemIDSeq,CreatedDate,ModifiedDate,PushedToRegAdminFlag)
      Select @IPVC_AccountID as AccountIDSeq,NULL as OrderIDSeq,NULL as OrderItemIDSeq,Getdate() as CreatedDate,NULL as  ModifiedDate,0 as PushedToRegAdminFlag
   end
   else
   begin
     Update Orders.dbo.Regadminqueue
     set    PushedToRegAdminFlag = 0,
            ModifiedDate         = Getdate()
     where  AccountIDSeq = @IPVC_AccountID
     and    OrderIDSeq is null
   end
  end
  Else if (@IPVC_OrderID is not null and (@IPVC_OrderItemIDSeq is null or @IPVC_OrderItemIDSeq = ''))
  begin
    ---------------------------------------------------------------------------    
    Insert into Orders.dbo.Regadminqueue(AccountIDSeq,OrderIDSeq,OrderItemIDSeq,CreatedDate,ModifiedDate,PushedToRegAdminFlag)
    Select distinct @IPVC_AccountID as AccountIDSeq,@IPVC_OrderID as OrderIDSeq,OI.IDSeq as OrderItemIDSeq,Getdate() as CreatedDate,NULL as  ModifiedDate,0 as PushedToRegAdminFlag
    From   Orders.dbo.[Order]      O   with (nolock)
    inner join
           Orders.dbo.[Orderitem]  OI  with (nolock)
    on     OI.Orderidseq = O.Orderidseq
    and    OI.ChargeTypeCode     ='ACS'   
    and    OI.Statuscode         <> 'PEND'
    and    OI.OrderIDSeq         = @IPVC_OrderID      
    inner join
           PRODUCTS.dbo.Product   P with (nolock)
    On     OI.ProductCode        =P.Code
    and    OI.PriceVersion       =P.PriceVersion
    and    P.RegAdminProductFlag =1
    and    OI.ChargeTypeCode     ='ACS'   
    where  OI.Orderidseq         =O.Orderidseq
    and    OI.OrderIDSeq         =@IPVC_OrderID      
    and    OI.ProductCode        =P.Code
    and    OI.PriceVersion       =P.PriceVersion
    and    P.RegAdminProductFlag =1
    and    OI.ChargeTypeCode     ='ACS' 
    and    OI.Statuscode         <> 'PEND'
    and    not exists (select top 1 1 from Orders.dbo.Regadminqueue R with (nolock)
                       where R.AccountIDSeq = @IPVC_AccountID
                       and   R.OrderIDSeq   = O.OrderIDSeq
                       and   R.OrderIDSeq   = @IPVC_OrderID
                       and   R.OrderItemIDSeq = OI.IDSeq
                      )
    
    Update Orders.dbo.Regadminqueue
    set    PushedToRegAdminFlag = 0,
           ModifiedDate         = Getdate()
    where  AccountIDSeq = @IPVC_AccountID
    and    OrderIDSeq   = @IPVC_OrderID      
    ---------------------------------------------------------------------------
  end
  else if (@IPVC_OrderID is not null and @IPVC_OrderItemIDSeq is not null)
  begin
    ---------------------------------------------------------------------------
    If not exists (select top 1 1 from Orders.dbo.Regadminqueue with (nolock)
                   where  AccountIDSeq   = @IPVC_AccountID
                   and    OrderIDSeq     = @IPVC_OrderID
                   and    OrderItemIDSeq = @IPVC_OrderItemIDSeq
                  )
    begin
      Insert into Orders.dbo.Regadminqueue(AccountIDSeq,OrderIDSeq,OrderItemIDSeq,CreatedDate,ModifiedDate,PushedToRegAdminFlag)
      Select distinct @IPVC_AccountID as AccountIDSeq,@IPVC_OrderID as OrderIDSeq,@IPVC_OrderItemIDSeq as OrderItemIDSeq,Getdate() as CreatedDate,NULL as  ModifiedDate,0 as PushedToRegAdminFlag
      From   Orders.dbo.[Order]      O   with (nolock)
      inner join
             Orders.dbo.[Orderitem]  OI  with (nolock)
      on     OI.Orderidseq = O.Orderidseq
      and    OI.ChargeTypeCode     ='ACS'   
      and    OI.Statuscode         <> 'PEND'
      and    OI.OrderIDSeq         = @IPVC_OrderID
      and    OI.IDSeq              = @IPVC_OrderItemIDSeq
      inner join
             PRODUCTS.dbo.Product   P with (nolock)
      On     OI.ProductCode        =P.Code
      and    OI.PriceVersion       =P.PriceVersion
      and    P.RegAdminProductFlag =1
      and    OI.ChargeTypeCode     ='ACS'   
      where  OI.Orderidseq         =O.Orderidseq
      and    OI.OrderIDSeq         =@IPVC_OrderID
      and    OI.IDSeq              =@IPVC_OrderItemIDSeq
      and    OI.ProductCode        =P.Code
      and    OI.PriceVersion       =P.PriceVersion
      and    P.RegAdminProductFlag =1
      and    OI.ChargeTypeCode     ='ACS' 
      and    OI.Statuscode         <> 'PEND'
    end
    else
    begin
      Update Orders.dbo.Regadminqueue
      set    PushedToRegAdminFlag = 0,
             ModifiedDate         = Getdate()
      where  AccountIDSeq = @IPVC_AccountID
      and    OrderIDSeq     = @IPVC_OrderID
      and    OrderItemIDSeq = @IPVC_OrderItemIDSeq
    end
    --------------------------------------------------------------------------- 
  end
END




GO
