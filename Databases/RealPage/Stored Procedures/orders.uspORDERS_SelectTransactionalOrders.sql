SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : uspORDERS_SelectTransactionalOrders
-- Description     : This procedure gets all Active Tran Enabler Orders based on Input Parameters
-- Syntax
/*
 --Some Sample Syntax Calls
  EXEC ORDERS.dbo.uspORDERS_SelectTransactionalOrders @IPVC_CompanyIDSeq = 'C0901004914',@IPI_IncludeProperty=0
  EXEC ORDERS.dbo.uspORDERS_SelectTransactionalOrders @IPVC_CompanyIDSeq = 'C0901004914',@IPI_IncludeProperty=1
  EXEC ORDERS.dbo.uspORDERS_SelectTransactionalOrders @IPVC_CompanyIDSeq = 'C0901004914',@IPVC_PropertyIDSeq='P0910000524'
  EXEC ORDERS.dbo.uspORDERS_SelectTransactionalOrders @IPVC_CompanyName  = 'MIAMI'
  EXEC ORDERS.dbo.uspORDERS_SelectTransactionalOrders @IPVC_PropertyName = 'COURT'
  EXEC ORDERS.dbo.uspORDERS_SelectTransactionalOrders @IPVC_CompanyName  = 'MIAMI',@IPVC_PropertyName  = 'COURT',@IPI_IncludeProperty=1
  EXEC ORDERS.dbo.uspORDERS_SelectTransactionalOrders @IPVC_ProductName  = 'Screening'
  EXEC ORDERS.dbo.uspORDERS_SelectTransactionalOrders @IPVC_FamilyCode   = 'LSD'
*/
-- Revision History:
-- Author          : Surya Kiran
-- 10/22/2010      : Stored Procedure Created.
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_SelectTransactionalOrders] ( @IPVC_CompanyIDSeq      varchar(50)  = NULL   ----> This is CompanyIDSeq from UI Text Box if Filled by User.
                                                          ,@IPVC_PropertyIDSeq     varchar(50)  = NULL   ----> This is PropertyIDSeq from UI Text Box if Filled by User.
                                                          ,@IPVC_CompanyName       varchar(255) = ''     ----> This is Company Name from UI Text Box for Like Search.
                                                          ,@IPVC_PropertyName	   varchar(255) = ''     ----> This is Property Name from UI Text Box for Like Search
                                                          ,@IPI_IncludeProperty  BIT          = 1      ----> Default will be Checked in UI. 1 for checked. 0 for UnChecked.
                                                          ,@IPVC_ProductName       varchar(500) = ''     ----> This is Product Displayname from UI Text Box for Like Search.
                                                          ,@IPVC_FamilyCode        varchar(50)  = NULL   ----> This is Code(hidden) Pertaining to User Selection of Familyname from Drop down. If Not selected UI will pass blank.
                                                                                                           --- UI will call EXEC PRODUCTS.dbo.uspPRODUCTS_FamilyList to populate the drop down showing Familyname. FamilyCode will be UI hidden value.
                                                         )


AS
BEGIN
  set nocount on;
          -------------------------------------------------------------
  --Initialize Variables.
  select @IPVC_CompanyIDSeq  =nullif(@IPVC_CompanyIDSeq,''),
         @IPVC_PropertyIDSeq =nullif(@IPVC_PropertyIDSeq,''),
         @IPVC_FamilyCode    =nullif(@IPVC_FamilyCode,'')
          -------------------------------------------------------------
  select   [Order ID]       = Max(O.OrderIDSeq)                      ----> This is Informational attribute for user. User will eventually remove this column for Final Transactional Import.
		  ,[Product Code]   = OI.ProductCode                         ----> This is the productcode pertaining to Transaction. User will retain this column for Final Transactional Import.
          ,[Product Name]   = Max(PROD.DisplayName)                  ----> This is Informational attribute for user. User will eventually remove this column for Final Transactional Import.
          ,[Description]    = ''                                     ----> This is Description of the Transaction from External System.
                                                                      ---     This will be filled in by User. User will retain this column for Final Transactional Import.
                                                                      ---     As per requirement "leave column blank" for Export Out of OMS.
          ,[PMC Name]       = Max(C.Name)                            ----> This is the company Name pertaining to Transaction. User will retain this column for Final Transactional Import.
          ,[PMC ID]         = O.CompanyIDSeq                         ----> This is the CompanyID pertaining to Transaction. User will retain this column for Final Transactional Import.
          ,[Site Name]      = coalesce(Max(P.Name),'')               ----> This is the Property Name pertaining to Transaction. User will retain this column for Final Transactional Import.
          ,[Site ID]        = coalesce(O.PropertyIDSeq,'')           ----> This is the PropertyID pertaining to Transaction. User will retain this column for Final Transactional Import. 
          ,[Quantity]       = ''                                     ----> This is Quantity from External System for the Transaction.
                                                                      ---     This will be filled in as Non Zero value by User. User will retain this column for Final Transactional Import.
                                                                      ---     As per requirement "leave column blank" for Export Out of OMS.
          ,[Unit Price]     = ''                                     ----> This is Unit Price from External System for the Transaction.
                                                                      ---     This will be filled in as Non Zero value if Override is set to 1 by User. User will retain this column for Final Transactional Import.
                                                                      ---     As per requirement "leave column blank" for Export Out of OMS.
          ,[Date]           = ''                                     ----> This is Date from External System for the Transaction.
                                                                      ---     This will be filled in as valid Date value by User. ValidFrom and ValidTo are used as reference to see if transaction date fall into this valid range.
                                                                      ---     User will retain this column for Final Transactional Import.
                                                                      ---     As per requirement "leave column blank" for Export Out of OMS.
          ,[Override]       = ''                                     ----> This is override attribute for the Transaction.
                                                                      ---     This will be filled as 0, if user does not want to override the price but chooses to go with OrderPrice.
                                                                      ---     This will be filled as 1, if user wants to override the price for the transaction with a different [Unit Price].
                                                                      ---     User will retain this column for Final Transactional Import.
                                                                      ---     As per requirement "leave column blank" for Export Out of OMS.
          ,[Valid From]        = convert(varchar(50),OI.StartDate,101)  ----> This is Informational attribute for user. User will eventually remove this column for Final Transactional Import.
          ,[Valid To]          = convert(varchar(50),OI.EndDate,101)    ----> This is Informational attribute for user. User will eventually remove this column for Final Transactional Import.
          ,[Order Price]       = Max(OI.NetChargeAmount)                ----> This is Informational attribute for user. User will eventually remove this column for Final Transactional Import.
          -------------------------------------------------------------
          ---Mandatory columns for Final Transactional Import into OMS
          -------------------------------------------------------------
          ,[Tran ID]        = ''                                     ----> This is TransactionID from External System identifying the Transaction.
                                                                      ---     This will be filled in by User. User will retain this column for Final Transactional Import.
                                                                      ---     As per requirement "leave column blank" for Export Out of OMS.
          
          
         
  from   ORDERS.dbo.[Order] O with (nolock)
  inner join
         ORDERS.dbo.[Orderitem] OI with (nolock)
  on     O.Orderidseq    = OI.OrderIDSeq
  and    OI.Measurecode  = 'TRAN'
  and    OI.FrequencyCode= 'OT'
  and    OI.StatusCode   = 'FULF'
  inner Join
         PRODUCTS.dbo.Product PROD with (nolock)
  on     OI.ProductCode = PROD.Code
  and    OI.Priceversion= PROD.Priceversion
  and    PROD.FamilyCode= Coalesce(@IPVC_FamilyCode,PROD.FamilyCode)
  and    PROD.DisplayName like '%' + @IPVC_ProductName + '%'
  inner join
         CUSTOMERS.dbo.Company C with (nolock)
  on     O.CompanyIDSeq = C.IDSeq
  and    C.IDSeq        = Coalesce(@IPVC_CompanyIDSeq,C.IDSeq)
  and    C.Name like '%' + @IPVC_CompanyName + '%'
  left outer Join
         CUSTOMERS.dbo.Property P with (nolock)
  on     O.PropertyIDSeq = P.IDSeq
  and    O.CompanyIDSeq  = P.PMCIDSeq
  where  (  (@IPI_IncludeProperty=0 and O.PropertyIDSeq is null)
               OR
            (@IPI_IncludeProperty = 1  
             and             
             coalesce(O.PropertyIDSeq,'ABCDEF') = Coalesce(@IPVC_PropertyIDSeq,coalesce(O.PropertyIDSeq,'ABCDEF'))  
             and
             coalesce(P.Name,'') like '%' + @IPVC_PropertyName + '%'           
            )
        )  
  group by O.CompanyIDSeq,O.PropertyIDSeq,OI.ProductCode,OI.StartDate,OI.EndDate
  Order by [PMC Name],[Site Name],[Product Name],OI.StartDate,OI.EndDate
END
GO
