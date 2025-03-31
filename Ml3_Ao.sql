-- 1. list all angents who have more than 12 years of experience  and their contracts numbers
SELECT XMLROOT(
      XMLELEMENT("agentExpert",
         XMLAGG(XMLELEMENT("agent",
               XMLATTRIBUTES(ac.aoid.aid AS "aid"),
                   XMLFOREST(ac.aoid.aname AS "AgentName", 
                        (EXTRACT(YEAR FROM SYSDATE) - ac.aoid.yearStarted) AS "ExperienceYears"),
                XMLAGG(XMLELEMENT("contract",
                     XMLFOREST(ac.acid AS "contractID")))))), VERSION '1.0') AS doc
FROM agentContract ac
WHERE (EXTRACT(YEAR FROM SYSDATE) - ac.aoid.yearStarted) > 12
GROUP BY ac.aoid.aid, ac.aoid.aname, ac.aoid.yearStarted;

-- 2. list all buyers' information who buy house before year 2025
SELECT XMLROOT(
      XMLELEMENT("BuyersPre",
         XMLAGG(
            XMLELEMENT("Buyer",
               XMLATTRIBUTES(sc.buyerid.cid AS "BuyerID"),
               XMLFOREST(sc.buyerid.cname AS "BuyerName",
                         sc.buyerid.phoneNum AS "BuyerPhone", 
                         sc.buyerid.emailAddress AS "BuyerEmail"),
               XMLELEMENT("Purchases",
                  XMLAGG(
                     XMLELEMENT("Purchase",
                        XMLATTRIBUTES(sc.scid AS "SaleContractID"),
                        XMLFOREST(sc.salePrice AS "PurchasePrice", 
                                  sc.signedTime AS "PurchaseDate"))))))), VERSION '1.0') AS doc
FROM saleContract sc 
WHERE sc.signedTime < DATE '2025-01-01'
GROUP BY sc.buyerid.cid, sc.buyerid.cname, sc.buyerid.phoneNum, sc.buyerid.emailAddress;

-- 3. list all properties that not handled by agents with their own details
-- modified: missed a XMLAGG so that it's one document, also added references to region, to fulfill requirement of more then one table.
SELECT XMLROOT( XMLELEMENT("PropertiesUn",
    XMLAGG(
        XMLELEMENT("Property",
        XMLATTRIBUTES(py.pid as "PropertyID"),
        XMLAGG(XMLFOREST(py.propertyType as "type", py.builtYear as "establishedYear", py.address as "Address", py.roid.city AS "City")
            )))),
        VERSION '1.0') as doc
FROM property py
GROUP BY py.pid, py.propertyType, py.builtYear, py.address;

-- 4.XSU: find the sellers who have house before year 2018 and their price of property
OracleXML getXML -user "grp2/here4grp2" -conn 
"jdbc:oracle:thin:@sit.itec.yorku.ca:1521/studb10g" "SELECT DISTINCT sc.sellerid.cname as sellerName, 
sc.sellerid.phoneNum as sellerPhone, sc.sellerid.emailAddress as sellerEmail, sc.sellerid.dateOwned as owningDate, 
sc.sellerid.cid as sellerID, sc.scid as saleContractID, sc.salePrice as propertyPrice
FROM saleContract sc WHERE sc.sellerid.dateOwned < DATE '2018-01-01'"

-- XQuery:
-- 5. calculate the average price of the all rented properties
xquery
let $agentC := doc("/public/mj/agentContract.xml")/AgentContracts/AgentContract
let $rentC := doc("/public/mj/rentContract.xml")/RentContracts/RentContract
let $rentedPrices := 
  for $ac in $agentC
  let $rc := $rentC[@rcid = $ac/rcoid/text()]
  where $ac/contractType = "rentContract"
  return $rc/rentPrice/text()
return format-number(avg($rentedPrices), "#.00")
/

-- 6. no one interests in the seventh property because of expensive, so its price is updated and return with property's information.
xquery
let $propery := doc("/public/mj/property.xml")/Properties
return
  copy $updatePrice := $propery  
  modify (  
    for $property in $updatePrice/Property
    where $property[@pid = "p07"] and $property/listing/listedPrice = 1750000.00
    return replace value of node $property/listing/listedPrice with 1400000.00  
  )
  return ($updatePrice/Property[@pid = "p07"],
    $updatePrice/Property[@pid = "p07"]/propertyType)
/


-- 7. find the buyer's ID who enrolled in real estate system after year 2017 and their info detail
-- modified: it's better to only display one element's value.
xquery
let $buy := doc("/public/mj/buyer.xml")/Buyers/Buyer
for $buyer in $buy
where xs:date($buyer/dateStarted) > xs:date("2018-01-01")  
return $buyer/@buyerID
/


