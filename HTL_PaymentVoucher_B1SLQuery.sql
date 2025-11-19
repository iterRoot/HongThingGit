--USE [SBOHTL_v4]
--GO

--/****** Object:  View [dbo].[HTL_PaymentVoucher_B1SLQuery]    Script Date: 11/19/2025 9:10:17 AM ******/
--DROP VIEW [dbo].[HTL_PaymentVoucher_B1SLQuery]
--GO

--/****** Object:  View [dbo].[HTL_PaymentVoucher_B1SLQuery]    Script Date: 11/19/2025 9:10:17 AM ******/
--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO


---- Create the view
--CREATE VIEW [dbo].[HTL_PaymentVoucher_B1SLQuery] AS

SELECT        A.DocEntry,  CONCAT(ISNULL(N.BeginStr,''), ISNULL(A.DocNum,'')) AS PCNo, A.TaxDate AS Date, P.PrcName AS LOB, A.NumAtCard AS SuppliersRef, A.CardName AS PayTo, A.Address AS Dep_Address, AC.AcctName AS Account, 
                         B.Dscription AS Description,
						 (ISNULL(B.LineTotal,0) + ISNULL(B.VatSum,0))AS Amount,
						 --B.GTotal AS Amount, 
						 A.Comments AS RemarkO
FROM            dbo.OPCH AS A LEFT OUTER JOIN
                         dbo.PCH1 AS B ON A.DocEntry = B.DocEntry LEFT OUTER JOIN
                         dbo.OACT AS AC ON B.AcctCode = AC.AcctCode LEFT OUTER JOIN
                         dbo.NNM1 AS N ON A.Series = N.Series LEFT OUTER JOIN
                         dbo.OPRC AS P ON A.U_cost_center = P.PrcCode

GO


