USE [SBOHTL_v4]
GO

/****** Object:  View [dbo].[HTL_SummuryAdvanceB1SLQuery]    Script Date: 11/20/2025 9:30:13 AM ******/
DROP VIEW [dbo].[HTL_SummuryAdvanceB1SLQuery]
GO
/****** Object:  View [dbo].[HTL_SummuryAdvanceB1SLQuery]    Script Date: 11/20/2025 9:30:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--For Down Payment Summary
CREATE   VIEW [dbo].[HTL_SummuryAdvanceB1SLQuery] AS
SELECT
    dp.AbsEntry,
    dp.Project_Name,
    (ISNULL(a.DpmAmnt, 0)-ISNULL(cr.CrTotal, 0)) AS DpmAmnt,
    dp.TaxDate,
    dp.Project_Name AS [DOCNUM],
    dp.[Sequence Number],
    SUM(ISNULL(a.DpmAmnt, 0)-ISNULL(cr.CrTotal, 0)) OVER (PARTITION BY dp.AbsEntry) AS TotalAmount,
    /* per-project total*/
    dp.ObjType,
    dp.FIPROJECT
FROM (
        SELECT DISTINCT
            A.AbsEntry, A.[Name] AS Project_Name, O.DocEntry as [ApDowmPayment], O.DocNum AS DOCNUM, O.U_HT_DocSequence AS [Sequence Number], O.TaxDate, O.ObjType, A.FIPROJECT
        FROM dbo.OPMG AS A
            LEFT JOIN dbo.PMG4 AS A4 ON A.AbsEntry = A4.AbsEntry
            LEFT JOIN dbo.ODPO AS O ON A.AbsEntry = O.U_HT_JobNo
            AND O.CANCELED = 'N' 
    ) AS dp
    LEFT JOIN (
        SELECT L.DocEntry, SUM(L.LineTotal
                --CASE
                --    WHEN L.U_tl_expdic IS NULL
                --    OR L.U_tl_expdic <> 'OP-0041' THEN ISNULL(L.LineTotal, 0) /* use LineTotal for SQL Server B1*/
                --    ELSE 0
                --END
            ) AS DpmAmnt
        FROM dbo.DPO1 AS L
        GROUP BY
            L.DocEntry
    ) AS a ON a.DocEntry = dp.[ApDowmPayment]
    LEFT JOIN (
        SELECT Cr_Do.DocTotal as [CrTotal],Cr_Do1.BaseEntry FROM ORPC Cr_Do
        LEFT JOIN RPC1 Cr_Do1 on Cr_Do.docentry = Cr_Do1.docentry
        -- WHERE Cr_Do1.U_tl_expdic = 'OP-0041'
    )Cr ON Cr.BaseEntry = dp.[ApDowmPayment]

GO
