-- 1. list all angents who have more than 12 years of experience  and their contracts numbers
SELECT XMLROOT( XMLELEMENT("AgentsExpert",
    XMLAGG( XMLELEMENT("Agent",
        XMLATTRIBUTES(a.aid as "AgentID"),
        XMLFOREST(a.aname as "AgentName", (EXTRACT(YEAR FROM SYSDATE) - a.yearStarted) as "ExperienceYears"),
        XMLELEMENT("Contracts",
            (SELECT XMLAGG(
                XMLELEMENT("Contract",
                XMLATTRIBUTES(c.acid as "ContractID")))
                FROM agentContract_t c
                WHERE c.aoid = a.aid)
               )))),
         VERSION '1.0') as doc
FROM agent_t a WHERE (EXTRACT(YEAR FROM SYSDATE) - a.yearStarted) > 12;

-- 2. list all buyers' information who buy house before year 2025
SELECT XMLROOT( XMLELEMENT("BuyersPre",
    XMLAGG( XMLELEMENT("Buyer",
        XMLATTRIBUTES(b.cid as "BuyerID"),
        XMLFOREST(b.cname as "BuyerName", b.phoneNum as "BuyerPhone", b.emailAddress as "BuyerEmail"),
        XMLELEMENT("Purchased",
            (SELECT XMLAGG(
                XMLELEMENT("Purchases",
                XMLATTRIBUTES(sc.scid as "SaleContractID"),
                XMLFOREST(sc.salePrice as "PurchasePrice", sc.signedTime as "PurchaseDate")))
                  FROM saleContract_t sc
                  WHERE sc.buyerid = b.cid AND sc.signedTime < DATE '2025-01-01')
               )))),
         VERSION '1.0') as doc
FROM customer_t b WHERE value(b) is of (only buyer_t)
GROUP BY b.cid, b.cname, b.phoneNum, b.emailAddress；
--error: ORA-04044: procedure, function, package, or type is not allowed here!

-- 3. list all properties that not handled by agents with their own details
SELECT XMLROOT( XMLELEMENT("PropertiesUn",
    XMLAGG(
        XMLELEMENT("Property",
        XMLATTRIBUTES(py.pid as "PropertyID"),
        XMLFOREST(py.propertyType as "type", py.builtYear as "establishedYear", py.address as "Address")
            ))),
        VERSION '1.0') as doc
FROM property_t py
WHERE NOT EXISTS (
  SELECT 1
  FROM agentContract_t ac
  WHERE ac.poid = py.pid
)
GROUP BY py.pid, py.propertyType, py.builtYear, py.address;
--error: ORA-04044: procedure, function, package, or type is not allowed here!

  
-- 1~ find the sellers who have house before year 2018 and their price of property
OracleXML getXML -user "grp2/here4grp2" -conn "jdbc:oracle:thin:@sit.itec.yorku.ca:1521/studb10g"
"SELECT DISTINCT 
    s.cname as sellerName, s.phoneNum as sellerPhone, s.emailAddress as sellerEmail, s.timeOwned as owningDate
    sc.sellerid as sellerID, sc.scid as saleContractID, sc.salePrice as propertyPrice
FROM saleContract_t sc, customer_t s WHERE sc.sellerid = s.cid AND value(s) is of (only seller_t) AND s.timeOwned < DATE '2018-01-01'"
--values return objects' row, is of only condition to subtype

  
-- 1` calculate the average price of the all rented properties
xquery
let $agentC := doc("/public/mj/agentContract.xml")/AgentContracts/AgentContract
let $rentC := doc("/public/mj/rentContract.xml")/RentContracts/RentContract
let $rentedPrices := 
  for $ac in $agentC
  let $rc := $rentC[@rcid = $ac/rcoid/text()]
  where $ac/contractType = "rentContract"
  return $rc/rentPrice/text()
return avg($rentedPrices)
/

-- 2` no one interests in the seventh property because of expensive, so its price is updated 
xquery
let $proper := doc("/public/mj/property.xml")/Properties
return
  copy $updatePrice := $proper  
  modify (  
    for $property in $updatePrice/Property
    where $property[@pid = "p07"] and $property/listing/listedPrice = 1750000.00
    return replace value of node $property/listing/listedPrice with 1400000.00  
  )
  return $updatePrice/Property[@pid = "p07"]
/
--copy: dot edit original XML.  modify: update xml data to insert, delete.  replace value of node $targetNode with $newValue

-- 3` find the buyer who enrolled in real estate system after year 2017 and their info detail
xquery
let $buy := doc("/public/mj/buyer.xml")/Buyers/Buyer
for $buyer in $buy
where xs:date($buyer/dateStarted) > xs:date("2018-01-01")  
return
  <BuyerInfo>
    <BuyerID>{$buyer/@buyerID}</BuyerID>
    <BuyerName>{$buyer/buyerName/text()}</BuyerName>
    <PhoneNumber>{$buyer/phoneNum/text()}</PhoneNumber>
    <EmailAddress>{$buyer/emailAddress/text()}</EmailAddress>
    <DateStarted>{$buyer/dateStarted/text()}</DateStarted>
    <PricePreferred>{$buyer/pricePreferred/text()}</PricePreferred>
  </BuyerInfo>
/
--xs:translate data type to be required type under Schema

