USE MaxMinManufacturingDW;
GO

/*----------------------------------------
    Create a view: vInventoryByType 
----------------------------------------*/

-- Check View exists
IF OBJECT_ID('vInventoryByType', 'V') IS NOT NULL
BEGIN
	DROP VIEW vInventoryByType;
	PRINT 'DROP VIEW vInventoryByType';
END
GO

-- Create View vInventoryByType
CREATE VIEW vInventoryByType AS
	SELECT DimProductType.ProductTypeName,
		   DimProductSubtype.ProductSubtypeName,
		   CAST(InventoryFact.DateOfInventory AS date) AS DateOfInventory,
	       InventoryFact.InventoryLevel		   
	FROM DimProductSubtype
	INNER JOIN DimProductType
	ON DimProductSubtype.ProductTypeCode = DimProductType.ProductTypeCode
	INNER JOIN DimProduct
	ON DimProductSubtype.ProductSubtypeCode = DimProduct.ProductSubtypeCode
	INNER JOIN InventoryFact
	ON DimProduct.ProductCode = InventoryFact.ProductCode
GO

-- Check the content of the view: vInventoryByType
SELECT * 
FROM vInventoryByType;
GO

-- Check View exists
IF OBJECT_ID('vAcceptedByCountry', 'V') IS NOT NULL
BEGIN
	DROP VIEW vAcceptedByCountry;
	PRINT 'DROP VIEW vAcceptedByCountry';
END
GO
-- Create View vAcceptedByCountry
CREATE VIEW vAcceptedByCountry AS
	SELECT DimCountry.CountryCode,
		   DimCountry.CountryName,
		   DimPlant.PlantName,
		   CAST(ManufacturingFact.DateOfManufacture AS date) AS DateOfManufacture,
		   ManufacturingFact.AcceptedProducts
	FROM DimPlant
	INNER JOIN DimCountry
	ON DimPlant.CountryCode = DimCountry.CountryCode 
	INNER JOIN DimMachine
	ON DimPlant.PlantNumber = DimMachine.PlantNumber
	INNER JOIN ManufacturingFact
	ON DimMachine.MachineNumber = ManufacturingFact.MachineNumber	
GO

SELECT * 
FROM vAcceptedByCountry;
GO

-- Check View exists
IF OBJECT_ID('vRejectedProductsByType', 'V') IS NOT NULL
BEGIN
	DROP VIEW vRejectedProductsByType;
	PRINT 'DROP VIEW vRejectedProductsByType';
END
GO

CREATE VIEW vRejectedProductsByType AS
	SELECT DimProductType.ProductTypeName,
		   DimProductSubtype.ProductSubtypeName,
--		   ROUND(CAST(ManufacturingFact.RejectedProducts*100 AS decimal)/CAST(ManufacturingFact.RejectedProducts + ManufacturingFact.AcceptedProducts AS decimal), 7) AS PercentRejected,
	       ROUND((CAST(ManufacturingFact.RejectedProducts*100 AS float)/CAST(ManufacturingFact.RejectedProducts + ManufacturingFact.AcceptedProducts AS float)), 7, 2) AS PercentRejected,
		   (ManufacturingFact.RejectedProducts + ManufacturingFact.AcceptedProducts) AS TotalManufactured,
		   CAST(ManufacturingFact.DateOfManufacture AS date) AS DateOfManufacture
	FROM DimProduct
	INNER JOIN ManufacturingFact
	ON DimProduct.ProductCode = ManufacturingFact.ProductCode
	INNER JOIN DimProductSubtype
	ON DimProduct.ProductSubtypeCode = DimProductSubtype.ProductSubtypeCode
	INNER JOIN DimProductType
	ON DimProductSubtype.ProductTypeCode = DimProductType.ProductTypeCode
GO

SELECT * 
FROM vRejectedProductsByType;
GO

/*--------------------------------------------------------------
	Create the spMaxInventoryByType Stored Procedure
	-----------------------------------------------------------*/

-- Check spMaxInventoryByType Stored Procedure exists
IF OBJECT_ID('spMaxInventoryByType', 'P') IS NOT NULL
BEGIN
	DROP PROCEDURE spMaxInventoryByType;
	PRINT 'DROP PROCEDURE spMaxInventoryByType';
END
GO

-- Create stored procedure spMaxInventoryByType
CREATE PROCEDURE spMaxInventoryByType @Year as int, @Month as int AS
BEGIN
	SELECT ProductTypeName,
		   ProductSubtypeName,
		   MAX(InventoryLevel) AS MaxInventory
	FROM vInventoryByType
	WHERE YEAR(DateOfInventory) = @Year AND MONTH(DateOfInventory) = @Month
	GROUP BY ProductTypeName, ProductSubtypeName 
	ORDER BY ProductTypeName, ProductSubtypeName
END
GO

EXEC spMaxInventoryByType 2009, 04;

/*--------------------------------------------------------------
	Create the spAcceptedByCountry Stored Procedure
	-----------------------------------------------------------*/

-- Check spAcceptedByCountry Stored Procedure exists
IF OBJECT_ID('spAcceptedByCountry', 'P') IS NOT NULL
BEGIN
	DROP PROCEDURE spAcceptedByCountry;
	PRINT 'DROP PROCEDURE spAcceptedByCountry';
END
GO

-- Create stored procedure spAcceptedByCountry
CREATE PROCEDURE spAcceptedByCountry @Year as int, @Month as int AS
BEGIN
	SELECT CountryCode,
		   CountryName,
		   REPLACE(PlantName, 'Maximum Miniatures -','') AS PlantName,
--		   RIGHT(PlantName, CHARINDEX('Maximum Miniatures -', PlantName)-1) AS PlantName, 
		   SUM(AcceptedProducts) AS AcceptedProducts
	FROM vAcceptedByCountry
	WHERE YEAR(DateOfManufacture) = @Year AND MONTH(DateOfManufacture) = @Month
--	AND PlantName LIKE '%Maximum Miniatures -'
	GROUP BY CountryCode, CountryName, PlantName  
	ORDER BY CountryCode, CountryName, PlantName 
END
GO

EXEC spAcceptedByCountry 2009, 04;

/*--------------------------------------------------------------
	Create the spAvgRejected Stored Procedure
	-----------------------------------------------------------*/

-- Check spAvgRejected Stored Procedure exists
IF OBJECT_ID('spAvgRejected', 'P') IS NOT NULL
BEGIN
	DROP PROCEDURE spAvgRejected;
	PRINT 'DROP PROCEDURE spAvgRejected';
END
GO

-- Create stored procedure spAcceptedByCountry
CREATE PROCEDURE spAvgRejected @Year as int, @Month as int AS
BEGIN
	SELECT ProductTypeName,
		   ProductSubtypeName,
		   ROUND(AVG(PercentRejected), 9, 1) AS AvgPercentRejected,
		   SUM(TotalManufactured) AS TotManufactured
	FROM vRejectedProductsByType	
	WHERE YEAR(DateOfManufacture) = @Year AND MONTH(DateOfManufacture) = @Month
	GROUP BY ProductTypeName, ProductSubtypeName
	ORDER BY ProductTypeName, ProductSubtypeName
END
GO

EXEC spAvgRejected 2009, 04;