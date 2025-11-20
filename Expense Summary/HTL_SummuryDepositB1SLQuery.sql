USE [SBOHTL_v4]
GO

/****** Object:  View [dbo].[HTL_SummuryDepositB1SLQuery]    Script Date: 11/20/2025 9:31:06 AM ******/
DROP VIEW [dbo].[HTL_SummuryDepositB1SLQuery]
GO

/****** Object:  View [dbo].[HTL_SummuryDepositB1SLQuery]    Script Date: 11/20/2025 9:31:06 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE   VIEW [dbo].[HTL_SummuryDepositB1SLQuery] AS

WITH CR_AGG AS (
    SELECT
        Y1.BaseEntry,
        Y1.BaseLine,
        SUM(ISNULL(Y1.GTotal, 0)) AS CR_GTotal
    FROM dbo.RPC1 AS Y1
    GROUP BY Y1.BaseEntry, Y1.BaseLine
),
NetPerDoc AS (
    SELECT
        H.DocEntry,
        H.DocNum,
        SUM(ISNULL(L.GTotal, 0) - ISNULL(CA.CR_GTotal, 0)) AS DpmAmnt_ByDoc
    FROM dbo.OPCH AS H
    JOIN dbo.PCH1 AS L
      ON L.DocEntry = H.DocEntry
    LEFT JOIN CR_AGG AS CA
      ON CA.BaseEntry = L.DocEntry
     AND CA.BaseLine  = L.LineNum
    --WHERE (L.U_tl_expdic IS NULL OR L.U_tl_expdic = 'OP-0041')
	WHERE (L.U_tl_expdic = 'OP-0041')
    GROUP BY H.DocEntry, H.DocNum
)
SELECT
    A.AbsEntry,
    A.DocNum                                  AS paramater,
    A.[Name]                                   AS Project_Name,
    N.DpmAmnt_ByDoc                            AS DpmAmnt,          -- summed per DOCNUM
    B.TaxDate,
    A.U_HT_Carrier                             AS DOCNUM,          -- renamed from [DOCNUM]
    B.U_HT_DocSequence                         AS [Sequence Number],
    COALESCE(SUM(N.DpmAmnt_ByDoc) OVER (PARTITION BY A.AbsEntry), 0) AS [TotalAmount],
    A.FIProject
FROM dbo.OPMG AS A
LEFT JOIN dbo.PMG4 AS A4
  ON A4.AbsEntry = A.AbsEntry
 AND A4.TYP = 18
LEFT JOIN dbo.OPCH AS B
  ON B.U_HT_JobNo = A4.AbsEntry
 AND B.CANCELED = 'N'
LEFT JOIN NetPerDoc AS N
  ON N.DocEntry = B.DocEntry
WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.PCH1 AS p
        WHERE p.DocEntry = B.DocEntry
          AND p.BaseType = 204           -- exclude AP Invoices stemming from AP Down Payments
) AND N.DpmAmnt_ByDoc <>0
GROUP BY
    A.AbsEntry,
    B.DocNum,
    A.DocNum,
    A.[Name],
    N.DpmAmnt_ByDoc,
    B.TaxDate,
    A.U_HT_Carrier,
    B.U_HT_DocSequence,
    A.FIProject;
GO


