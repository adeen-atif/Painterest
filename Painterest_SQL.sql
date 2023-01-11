--CREATING THE TABLES

-- Category table
CREATE TABLE Category (
  category CHAR(1) PRIMARY KEY,
  catDescription varchar(25) NOT NULL,
  catDiscount NUMBER(2,1) NOT NULL,
  CHECK (category IN ('B', 'S', 'G', 'P'))
  
);

select * from owner;

-- Customer table
CREATE TABLE Customer (
  cNo INT PRIMARY KEY,
  cName VARCHAR(50) NOT NULL,
  cAddress VARCHAR(100) NOT NULL,
  category CHAR(1) NOT NULL references Category,
  CHECK (category IN ('B', 'S', 'G', 'P'))
);

-- Artist table
CREATE TABLE Artist (
  aNo INT PRIMARY KEY NOT NULL,
  aName VARCHAR(50) NOT NULL,
  countryOfBirth VARCHAR(50) NOT NULL,
  yearOfBirth INT NOT NULL,
  yearOfDeath INT,
  age number
);

-- Owner table
CREATE TABLE Owner (
  oNo INT PRIMARY KEY,
  oName VARCHAR(50) NOT NULL,
  oAddress VARCHAR(100) NOT NULL,
  oTelephone varchar(20)
);

-- Painting table
CREATE TABLE Painting (
  pNo INT PRIMARY KEY,
  pTitle VARCHAR(100) NOT NULL,
  pTheme VARCHAR(100) NOT NULL,
  aNo INT NOT NULL,
  FOREIGN KEY (aNo) REFERENCES Artist(aNo) ON DELETE CASCADE,
  oNo INT NOT NULL,
  FOREIGN KEY (oNo) REFERENCES Owner(oNo)ON DELETE CASCADE,
  rental_price NUMBER(10,2) NOT NULL,
  status varchar(10) check (status IN ('available', 'unavailable')),
  dateEntered date
);


-- Rented_By table (relationship between Painting and Customer)
CREATE TABLE Rented_By (
  rNo INT PRIMARY KEY,
  pNo INT NOT NULL,
  FOREIGN KEY (pNo) REFERENCES Painting(pNo),
  cNo INT NOT NULL,
  FOREIGN KEY (cNo) REFERENCES Customer(cNo),
  dateOfHire DATE NOT NULL,
  dateDueBack DATE NOT NULL,
  returned CHAR(1) CHECK (returned IN ('T', 'F')),
  rentalFee number(5,2)
);


-- Returned_To table (relationship between Painting and Owner)
CREATE TABLE Returned_To (
  rtNo INT PRIMARY KEY,
  pNo INT NOT NULL,
  FOREIGN KEY (pNo) REFERENCES Painting(pNo),
  oNo INT NOT NULL,
  FOREIGN KEY (oNo) REFERENCES Owner(oNo),
  returnDate DATE NOT NULL
);



--GENERATING THE REPORT USING PL/SQL

--For each customer, a report showing an overview of all the paintings they have hired or are currently hiring

CREATE OR REPLACE PROCEDURE get_customer_report (p_cNo IN NUMBER) AS

  CURSOR c_customer_report IS
    SELECT c.cNo, c.cName, c.cAddress, c.category, g.catDescription, g.catDiscount, p.pNo,  p.pTitle, p.pTheme, r.dateOfHire, r.dateDueBack, r.Returned
    FROM Customer c
    JOIN Category g
    ON c.category = g.category
    JOIN Rented_By r
    ON c.cNo = r.cNo
    AND c.cNo = p_cNo
    JOIN Painting p
    ON r.pNo = p.pNo;


    v_cnt number;
  v_customer_report c_customer_report%ROWTYPE;
BEGIN
-- Check if customer number is valid
  SELECT COUNT(*) INTO v_cnt
  FROM Customer
  WHERE cNo = p_cNo;
  IF v_cnt = 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Invalid Customer Number entered');
  END IF;
  
  OPEN c_customer_report;
  FETCH c_customer_report INTO v_customer_report;
  DBMS_OUTPUT.PUT_LINE(v_customer_report.cNo || ' | ' 
  || v_customer_report.cName || ' | '
  || v_customer_report.category || ' | '
  || v_customer_report.catDescription || ' | '
  || v_customer_report.catDiscount || ' | '
  || v_customer_report.pNo || ' | '
  || v_customer_report.pTitle || ' | '
  || v_customer_report.pTheme || ' | '
  || v_customer_report.dateOfHire || ' | '
  || v_customer_report.dateDueBack || ' | ' 
  || v_customer_report.dateDueBack || ' | ' 
  || v_customer_report.Returned);
  CLOSE c_customer_report;
END;


--for executing a customer report
EXECUTE get_customer_report(1001);


select * from customer;

--For each artist, a report of all paintings submitted for hire
CREATE OR REPLACE PROCEDURE get_artist_report (p_aNo IN NUMBER) AS
  CURSOR c_artist_report IS
    SELECT Artist.aNo, Artist.aName, Artist.countryOfBirth, Artist.yearOfBirth, Artist.yearOfDeath, Artist.age,
           Painting.pNo, Painting.pTitle, Painting.pTheme, Painting.rental_price,
           Owner.oNo, Owner.oName, Owner.oTelephone
    FROM Artist
    JOIN Painting
    ON Artist.aNo = Painting.aNo
    LEFT JOIN Rented_By
    ON Painting.pNo = Rented_By.pNo
    LEFT JOIN Customer
    ON Rented_By.cNo = Customer.cNo
    JOIN Owner
    ON Painting.oNo = Owner.oNo
    WHERE Artist.aNo = p_aNo;
    
  v_age number;
  v_cnt number;
  v_artist_report c_artist_report%ROWTYPE;
BEGIN

SELECT COUNT(*) INTO v_cnt
  FROM Artist
  WHERE aNo = p_aNo;
  IF v_cnt = 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Invalid Artist Number entered');
  END IF;

  OPEN c_artist_report;
  FETCH c_artist_report INTO v_artist_report;
  DBMS_OUTPUT.PUT_LINE(v_artist_report.aNo || ' | ' || v_artist_report.aName || ' | ' || v_artist_report.countryOfBirth || ' | ' ||
                     v_artist_report.yearOfBirth || ' | ' || v_artist_report.yearOfDeath || ' | ' || v_age || ' | ' ||
                     v_artist_report.pNo || ' | ' || v_artist_report.pTitle || ' | ' || v_artist_report.pTheme || ' | ' ||
                     v_artist_report.rental_price || ' | ' || v_artist_report.oNo || ' | ' || v_artist_report.oName || ' | ' ||
                     v_artist_report.oTelephone);
CLOSE c_artist_report;
END;


--for executing a artist report
EXECUTE get_artist_report(300);


--For each owner, a returns report for those paintings not hired over the past six months
CREATE OR REPLACE PROCEDURE get_owner_report (p_oNo IN NUMBER) AS
  CURSOR c_owner_report IS
    SELECT Owner.oNo, Owner.oName, Owner.oAddress, Painting.pNo, Painting.pTitle, Returned_To.returnDate
    FROM Owner
    JOIN Returned_To
    ON Owner.oNo = Returned_To.oNo
    JOIN Painting
    ON Returned_To.pNo = Painting.pNo
    WHERE Returned_To.returnDate > ADD_MONTHS(CURRENT_DATE, -6) AND Owner.oNo = p_oNo;

v_cnt number;
  v_owner_report c_owner_report%ROWTYPE;
BEGIN

SELECT COUNT(*) INTO v_cnt
  FROM Owner
  WHERE oNo = p_oNo;
  IF v_cnt = 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Invalid Owner Number entered');
  END IF;
  
  -- Print out owner information
SELECT oNo, oName, oAddress INTO v_owner_report.oNo, v_owner_report.oName, v_owner_report.oAddress FROM Owner WHERE oNo = p_oNo;
DBMS_OUTPUT.PUT_LINE(v_owner_report.oNo || ' | ' || v_owner_report.oName || ' | ' || v_owner_report.oAddress);


  OPEN c_owner_report;
  LOOP
    FETCH c_owner_report INTO v_owner_report;
    EXIT WHEN c_owner_report%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(v_owner_report.pNo || ' | ' || v_owner_report.pTitle || ' | ' || v_owner_report.returnDate);
  END LOOP;
  CLOSE c_owner_report;
END;


--for executing a owner report
EXECUTE get_owner_report(4005);



--OTHER PROCEDURES

--SIGNING UP AS A NEW OWNER
CREATE OR REPLACE PROCEDURE signUp_owner (p_name IN VARCHAR2, p_address IN VARCHAR2, p_telephone IN VARCHAR2) AS
  v_oNo NUMBER;
BEGIN
  -- Generate a unique oNo primary key
  SELECT Owner_seq.NEXTVAL INTO v_oNo FROM DUAL;

  -- Insert the new owner into the Owner table
  INSERT INTO Owner (oNo, oName, oAddress, oTelephone)
  VALUES (v_oNo, p_name, p_address, p_telephone);

  -- Output a successful signing up message and the oNo assigned to the owner
  DBMS_OUTPUT.PUT_LINE('Successfully signed up as owner with oNo: ' || v_oNo);
END;


--TO DELETE AN OWNER'S ACCOUNT ON THE BASIS OF OWNER NUMBER
CREATE PROCEDURE delete_owner_account (oNo_in INT)
AS
cnt number;
v_cnt number;
BEGIN
-- Check if owner number is valid
  SELECT COUNT(*) INTO v_cnt
  FROM Owner
  WHERE oNo = oNo_in;
  IF v_cnt = 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Invalid Owner Number entered');
  END IF;


  -- Check if owner has any paintings currently rented out
  SELECT COUNT(*) INTO cnt FROM Rented_By rb INNER JOIN Painting p ON rb.pNo = p.pNo WHERE p.oNo = oNo_in AND rb.returned = 'F';
  
  -- If owner has rented paintings, raise an error
  IF cnt > 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Cannot delete owner account as owner has rented paintings.');
  END IF;
  
  DELETE FROM Owner
  WHERE oNo = oNo_in;
  
END;


--TO DELETE A CUSTOMER'S ACCOUNT ON THE BASIS OF CUSTOMER NUMBER
CREATE OR REPLACE PROCEDURE delete_customer_account (p_cNo IN number)
AS
v_count number;
v_cnt number;
BEGIN

-- Check if customer number is valid
  SELECT COUNT(*) INTO v_cnt
  FROM Customer
  WHERE cNo = p_cNo;
  IF v_cnt = 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Invalid Customer Number entered');
  END IF;

  -- Check if the customer has any outstanding rentals
  SELECT COUNT(*) INTO v_count FROM Rented_By WHERE cNo = p_cNo AND returned = 'F';
  
  -- If the customer has no outstanding rentals, delete their account
  IF v_count = 0 THEN
    DELETE FROM Customer WHERE cNo = p_cNo;
    COMMIT;
  ELSE
    -- If the customer has outstanding rentals, raise an error
    RAISE_APPLICATION_ERROR(-20001, 'Cannot delete customer account as they have outstanding rentals');
  END IF;
END;





--TO CHANGE THE RENTAL PRICE OF A PAINTING
CREATE OR REPLACE PROCEDURE change_painting_price (p_oNo IN number, p_pNo IN number, p_newPrice IN number)
AS
  v_count number;
BEGIN

  
  -- Check if owner number and painting number are valid
  SELECT COUNT(*) INTO v_count FROM Owner WHERE oNo = p_oNo;
  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Invalid Owner Number entered');
  END IF;

  SELECT COUNT(*) INTO v_count FROM Painting WHERE pNo = p_pNo;
  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20003, 'Invalid Painting Number entered');
  END IF;

  -- Check if the owner actually owns the painting
  SELECT COUNT(*) INTO v_count FROM Painting WHERE pNo = p_pNo AND oNo = p_oNo;
  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'This owner does not own the specified painting');
  END IF;
  
   -- Disable the update_returned_to_painting trigger
  EXECUTE IMMEDIATE 'ALTER TRIGGER update_returned_to_painting DISABLE';


  -- Change the price of the painting
  UPDATE Painting
  SET rental_price = p_newPrice
  WHERE pNo = p_pNo AND oNo = p_oNo;
  
  -- Re-enable the update_returned_to_painting trigger
  EXECUTE IMMEDIATE 'ALTER TRIGGER update_returned_to_painting ENABLE';
  
  
  COMMIT;
END;



execute change_painting_price(4003, 2002, 350);

select * from painting;

--TO DELETE A PAINTING (OWNER DOES IT)
CREATE OR REPLACE PROCEDURE delete_painting (p_pNo IN number, p_oNo IN number)
AS
v_count number;
BEGIN
  -- Check if the owner number is valid
  SELECT COUNT(*) INTO v_count FROM Owner WHERE oNo = p_oNo;
  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20003, 'Invalid Owner Number entered');
  END IF;
  
  -- Check if the painting number is valid
  SELECT COUNT(*) INTO v_count FROM Painting WHERE pNo = p_pNo;
  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20004, 'Invalid Painting Number entered');
  END IF;
  
  -- Check if the owner owns the painting
  SELECT COUNT(*) INTO v_count FROM Painting WHERE pNo = p_pNo AND oNo = p_oNo;
  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20005, 'The owner does not own the painting');
  END IF;
  
  -- Check if the painting is currently rented out
  SELECT COUNT(*) INTO v_count FROM Rented_By WHERE pNo = p_pNo AND returned = 'F';
  IF v_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20006, 'Cannot delete painting as it is currently rented out');
  END IF;
  
  -- If the painting is not rented out, delete it
  DELETE FROM Painting WHERE pNo = p_pNo AND oNo = p_oNo;
  COMMIT;
END;

exec delete_painting(2005, 4006);




--TO ALLOW CUSTOMERS TO CHANGE/UPDATE THE CATEGORY ATTRIBUTE OF ITS TABLE
CREATE OR REPLACE PROCEDURE change_customer_category (p_cNo IN number, p_newCategory IN varchar2)
AS
v_count number;
BEGIN
  -- Check if customer number is valid
  SELECT COUNT(*) INTO v_count
  FROM Customer
  WHERE cNo = p_cno;
  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Invalid Customer Number entered');
  END IF;

  -- Check if the new category is valid
  IF p_newCategory NOT IN ('B', 'S', 'G', 'P') THEN
    RAISE_APPLICATION_ERROR(-20003, 'Invalid category entered. Must be B, S, G, or P');
  END IF;

  -- Change the category of the customer
  UPDATE Customer
  SET category = p_newCategory
  WHERE cNo = p_cNo;
  COMMIT;
END;

EXECUTE change_customer_category(1001, 'A');




--ENTERING A NEW ARTIST
CREATE OR REPLACE PROCEDURE enter_artist (p_name IN VARCHAR2, p_country_of_birth IN VARCHAR2, p_year_of_birth IN NUMBER, p_year_of_death IN NUMBER) AS
  v_aNo NUMBER;
  v_age NUMBER;
BEGIN
  -- Generate a unique aNo primary key
  SELECT Artist_seq.NEXTVAL INTO v_aNo FROM DUAL;

  -- Calculate the age of the artist
  IF p_year_of_death IS NULL THEN
    v_age := EXTRACT(YEAR FROM CURRENT_DATE) - p_year_of_birth;
  ELSE
    v_age := p_year_of_death - p_year_of_birth;
  END IF;

  -- Insert the new artist into the Artist table
  INSERT INTO Artist (aNo, aName, countryOfBirth, yearOfBirth, yearOfDeath, age)
  VALUES (v_aNo, p_name, p_country_of_birth, p_year_of_birth, p_year_of_death, v_age);

  -- Output a successful artist insertion message and the aNo assigned to the artist
  DBMS_OUTPUT.PUT_LINE('Successfully entered artist with aNo: ' || v_aNo);
END;

--Executing the enter_artist procedure
BEGIN 
enter_artist('herondale', 'london', 1930, 2002);
END; 


--ENTERING A NEW PAINTING
CREATE OR REPLACE PROCEDURE enter_new_painting (
  p_oNo IN NUMBER,
  p_pTitle IN VARCHAR2,
  p_pTheme IN VARCHAR2,
  p_rentalPrice IN NUMBER,
  p_aName IN VARCHAR2
) AS
  v_oExists NUMBER;
  v_aNo NUMBER;
  v_pNo NUMBER;
  v_paymentAmount NUMBER;
BEGIN
  -- Check if the owner number entered exists
  SELECT COUNT(*) INTO v_oExists FROM owner WHERE oNo = p_oNo;
  IF v_oExists = 0 THEN
  DBMS_OUTPUT.PUT_LINE('Error: Owner with oNo ' || p_oNo || ' does not exist.');    RETURN;
  RETURN; 
  END IF;
  
  -- Generate a unique pNo primary key
  SELECT Painting_seq.NEXTVAL INTO v_pNo FROM dual;
  
  -- Check if the artist specified in the input exists
  SELECT aNo INTO v_aNo FROM artist WHERE aName = p_aName;
  IF v_aNo IS NULL THEN
DBMS_OUTPUT.PUT_LINE('Error: Artist with name ' || p_aName || ' does not exist. Please enter the correct artist first.');    RETURN;
  END IF;
  
  -- Insert the new painting into the painting table
  INSERT INTO Painting (pNo, pTitle, pTheme, aNo, oNo, rental_price, status, dateEntered)
  VALUES (v_pNo, p_pTitle, p_pTheme, v_aNo, p_oNo, p_rentalPrice, 'available', SYSDATE);
  
  -- Calculate the payment amount for the owner
  v_paymentAmount := p_rentalPrice * 0.1;
  
  -- Set the output parameters
  DBMS_OUTPUT.PUT_LINE('Successfully added new painting with pNo ' || v_pNo || '. Payment amount for the owner: $' || v_paymentAmount || '.');
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;

--FOR EXECUTING THE enter_new_painting procedure
BEGIN
  enter_new_painting(
    4004,
    'The Starry Neigh',
    'landscape',
    100,
    'Vincent bus Gogh'
  );
END;




--OWNER RESUBMITTING A PAINTING ALREADY IN THE RECORD UP FOR RENTING
CREATE OR REPLACE PROCEDURE resubmit_painting (p_oNo IN NUMBER, p_pNo IN NUMBER) AS 
  v_oExists NUMBER;
  v_pExists NUMBER;
  v_ownerMatch NUMBER;
  v_status VARCHAR2(20);
  v_returnDate DATE;
  v_everReturned NUMBER;
BEGIN
  -- Check if the owner number entered exists
  SELECT COUNT(*) INTO v_oExists FROM Owner WHERE oNo = p_oNo;
  IF v_oExists = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Error: Invalid Owner Number entered.');
    RETURN;
  END IF;

  -- Check if the painting number entered exists
  SELECT COUNT(*) INTO v_pExists FROM Painting WHERE pNo = p_pNo;
  IF v_pExists = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Error: Invalid Painting Number entered.');
    RETURN;
  END IF;

  -- Check if the owner number and painting number match
  SELECT COUNT(*) INTO v_ownerMatch FROM Painting WHERE pNo = p_pNo AND oNo = p_oNo;
  IF v_ownerMatch = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Error: Wrong Owner Number entered; you do not have access to resubmit this painting.');
    RETURN;
  END IF;

  -- Check if the painting is already available to be rented
  SELECT status INTO v_status FROM Painting WHERE pNo = p_pNo;
  IF v_status = 'available' THEN
    DBMS_OUTPUT.PUT_LINE('Error: Painting is already available to be rented.');
    RETURN;
  END IF;

  -- Check if the painting was ever returned to the owner
     SELECT COUNT(*) INTO v_everReturned FROM rented_by WHERE pNo = p_pNo;
  IF v_everReturned != 0 THEN
        DBMS_OUTPUT.PUT_LINE('Error: Painting was never returned to you owner. Its already available to rent');
        RETURN;
  END IF;
      
-- Check if the painting was returned within the last 3 months
  SELECT returnDate INTO v_returnDate FROM returned_to WHERE pNo = p_pNo;
  IF v_returnDate IS NULL THEN
    DBMS_OUTPUT.PUT_LINE('Error: Painting was never returned to you owner.');
    RETURN;
  ELSE
    IF (SYSDATE - v_returnDate) < INTERVAL '3' MONTH THEN
      DBMS_OUTPUT.PUT_LINE('Error: Can not re-submit the painting until ' || TO_CHAR(v_returnDate + INTERVAL '3' MONTH, 'DD-MON-YYYY'));
      RETURN;
    END IF;
  END IF;
  
  -- Update the status of the painting to 'available'
  UPDATE painting SET status = 'available' WHERE pNo = p_pNo;
  
  DBMS_OUTPUT.PUT_LINE('Successfully resubmitted painting with pNo ' || p_pNo || '.');
END;

select * from painting;
exec resubmit_painting(4004, 3);
select * from painting;


select * from owner;

--SIGNING UP AS A NEW CUSTOMER
CREATE OR REPLACE PROCEDURE sign_up_customer (p_cName IN VARCHAR2, p_cAddress IN VARCHAR2, p_category IN CHAR) AS
v_cNo NUMBER;
BEGIN
-- Generate a unique cNo primary key
SELECT Customer_seq.NEXTVAL INTO v_cNo FROM dual;

-- Check if the category entered is valid
IF p_category NOT IN ('B', 'S', 'G', 'P') THEN
DBMS_OUTPUT.PUT_LINE('Error: Invalid category entered. Please enter one of the following values: ''B'', ''S'', ''G'', ''P''.');
RETURN;
END IF;

-- Insert the new customer into the Customer table
INSERT INTO Customer (cNo, cName, cAddress, category)
VALUES (v_cNo, p_cName, p_cAddress, p_category);

-- Output successful sign up message and cNo assigned to the customer
DBMS_OUTPUT.PUT_LINE('Successfully signed up as a new customer. Your assigned cNo is: ' || v_cNo || '.');
END;

--Executing the sign_up_customer procedure
BEGIN
sign_up_customer('Don Smith', '123 Main Street', 'B');
END;


-- A customer finding painting according to a theme
CREATE OR REPLACE PROCEDURE find_paintings_by_theme (p_pTheme VARCHAR2)
AS
  CURSOR c_paintings IS
    SELECT pNo, pTitle
    FROM Painting
    WHERE pTheme = p_pTheme;
    
v_pNo VARCHAR2(32767);
v_pTitle VARCHAR2(32767);
BEGIN
OPEN c_paintings;
  LOOP
FETCH c_paintings INTO v_pNo, v_pTitle;
    EXIT WHEN c_paintings%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('pNo: ' || v_pNo || ', pTitle: ' || v_pTitle);
  END LOOP;
  
  -- If no rows are returned, there are no paintings with the given theme
  IF c_paintings%ROWCOUNT = 0
  THEN
    DBMS_OUTPUT.PUT_LINE('There''s no painting with the requested theme');
  END IF;
  
  CLOSE c_paintings;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;

--Executing the find_paintings_by_theme procedure
EXEC find_paintings_by_theme ('Renaissance');



-- A customer finding painting according to artist name
CREATE OR REPLACE PROCEDURE find_paintings_by_artist (p_artist_name IN VARCHAR2)
AS
  CURSOR c_paintings_a IS
    SELECT p.pNo, p.pTitle
    FROM Painting p
    JOIN Artist a ON p.aNo = a.aNo
    WHERE a.aName = p_artist_name;
  v_pno painting.pno%TYPE;
  v_pname painting.pTitle%TYPE;
BEGIN
  OPEN c_paintings_a;
  FETCH c_paintings_a INTO v_pno, v_pname;
  IF c_paintings_a%NOTFOUND THEN
    RAISE_APPLICATION_ERROR(-20001, 'There''s no painting with the requested artist');
    RETURN;
  END IF;
  LOOP
    EXIT WHEN c_paintings_a%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('pNo: ' || v_pno || ',  pTitle: ' || v_pname);
    FETCH c_paintings_a INTO v_pno, v_pname;
  END LOOP;
  CLOSE c_paintings_a;
   EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END find_paintings_by_artist;

--Executing the find_paintings_by_artist procedure
EXEC find_paintings_by_artist('Dominic Sherwood');


-- A customer renting a painting
CREATE OR REPLACE PROCEDURE rent_painting (p_cno IN NUMBER, p_pno IN NUMBER)
AS
  v_rental_price NUMBER;
  v_discount NUMBER;
  v_rental_fee NUMBER;
  v_rno NUMBER;
  v_count NUMBER;
  v_status VARCHAR2(32767);
  v_title VARCHAR2(32767);
  v_theme VARCHAR2(32767);
  v_return_date date;
  
BEGIN
  -- Check if customer number is valid
  SELECT COUNT(*) INTO v_count
  FROM Customer
  WHERE cNo = p_cno;
  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Invalid Customer Number entered');
  END IF;
  
  -- Check if painting number is valid
  SELECT COUNT(*) INTO v_count
  FROM Painting
  WHERE pNo = p_pno;
  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20003, 'Invalid Painting Number entered. Go to the ''find painting'' feature to get your desired Painting Number');
  END IF;
  
  -- Check if painting is available to be rented
SELECT status INTO v_status
FROM Painting
WHERE pNo = p_pno;

IF v_status = 'unavailable' THEN
  RAISE_APPLICATION_ERROR(-20004, 'Painting is not available to be rented');
END IF;

SELECT RB_seq.NEXTVAL INTO v_rno FROM DUAL;

SELECT rental_price INTO v_rental_price
FROM Painting
WHERE pNo = p_pno;

SELECT catDiscount INTO v_discount
FROM Category c
JOIN Customer cu ON c.category = cu.category
WHERE cu.cNo = p_cno;

v_rental_fee := v_rental_price - v_rental_price * (v_discount / 100);


INSERT INTO Rented_By (rNo, pNo, cNo, dateOfHire, dateDueBack,returned, rentalFee)
VALUES (v_rno, p_pno, p_cno, SYSDATE, ADD_MONTHS(SYSDATE, 2),'F', v_rental_fee);

SELECT p.pTitle, p.pTheme, rb.dateDueBack
INTO v_title, v_theme, v_return_date
FROM Painting p
JOIN Rented_By rb ON p.pNo = rb.pNo
WHERE rb.pNo = p_pno;

DBMS_OUTPUT.PUT_LINE('Booking successful!');
DBMS_OUTPUT.PUT_LINE('Painting: ' || v_title);
DBMS_OUTPUT.PUT_LINE('Theme: ' || v_theme);
DBMS_OUTPUT.PUT_LINE('Return date: ' || TO_CHAR(v_return_date, 'DD-MON-YYYY'));
DBMS_OUTPUT.PUT_LINE('Rental Fee: $' || v_rental_fee);

END rent_painting;

--Executing the rent_painting procedure
execute rent_painting(1001, 205);


--Return paintings not hired within 6 months after their submission to their owners
CREATE OR REPLACE PROCEDURE return_unrented_paintings
AS
BEGIN
  -- Find paintings that are not in Rented_To and have been entered more than 6 months ago
  FOR p IN (SELECT p.pNo, p.dateEntered, p.status, p.oNo
            FROM Painting p
            WHERE p.pNo NOT IN (SELECT rb.pNo FROM Rented_By rb)
            AND (SYSDATE - p.dateEntered) > (182))
  LOOP
    -- Create record in Returned_To for each painting
    INSERT INTO Returned_To (rtNo, pNo, oNo, returnDate)
    VALUES (RdT_seq.NEXTVAL, p.pNo, p.oNo, SYSDATE);
    
    -- Update status of painting to 'unavailable'
    UPDATE Painting
    SET status = 'unavailable'
    WHERE pNo = p.pNo;
  END LOOP;
END return_unrented_paintings;

execute return_unrented_paintings;

--TRIGGERS for updating Returned_To table
--Returning the paintings to the owners which weren’t hired for 6 months (within being entered into the Painting table)
CREATE OR REPLACE TRIGGER update_returned_to_painting
BEFORE INSERT OR UPDATE ON Painting
FOR EACH ROW
BEGIN
 return_unrented_paintings;
END;


CREATE OR REPLACE TRIGGER update_returned_to_artist
AFTER INSERT OR UPDATE ON Artist
FOR EACH ROW
BEGIN
 return_unrented_paintings;
END;

CREATE OR REPLACE TRIGGER update_returned_to_owner
AFTER INSERT OR UPDATE ON Owner
FOR EACH ROW
BEGIN
 return_unrented_paintings;
END;

CREATE OR REPLACE TRIGGER update_returned_to_rentedBy
AFTER INSERT OR UPDATE ON Rented_By
FOR EACH ROW
BEGIN
 return_unrented_paintings;
END;


-- A trigger to update the returned column of the Rented_By table to 'T'
-- for all rows with returned value 'F' and dateDueBack value in the past.
CREATE TRIGGER update_returned_and_status
AFTER UPDATE ON Rented_By
FOR EACH ROW
BEGIN
  -- Check if returned column is 'F' and current date is past dateDueBack
   IF :OLD.returned = 'F' AND SYSDATE > :OLD.dateDueBack THEN
    -- Update returned column in Rented_By table for all rows that match the condition
    UPDATE Rented_By r
    SET r.returned = 'T'
    WHERE r.returned = 'F' AND r.dateDueBack < SYSDATE;
    
    -- Update status column in Painting table for all rows that match the condition
    UPDATE Painting p
    SET p.status = 'available'
    WHERE p.pNo IN (SELECT r.pNo FROM Rented_By r WHERE r.returned = 'T' AND r.dateDueBack < SYSDATE);
  END IF;
END;




--SEQUENCES TO GENERATE A UNIQUE PRIMARY KEY EVERY TIME
CREATE SEQUENCE Owner_seq
  MINVALUE 1
  MAXVALUE 999999999999999999999999999
  START WITH 1
  INCREMENT BY 1
  CACHE 20;
  
  
CREATE SEQUENCE Artist_seq
  MINVALUE 1
  MAXVALUE 999999999999999999999999999
  START WITH 1
  INCREMENT BY 1
  CACHE 20;
  
  
  
  CREATE SEQUENCE Painting_seq
  MINVALUE 1
  MAXVALUE 999999999999999999999999999
  START WITH 1
  INCREMENT BY 1
  CACHE 20;

CREATE SEQUENCE Customer_seq
  MINVALUE 1
  MAXVALUE 999999999999999999999999999
  START WITH 1
  INCREMENT BY 1
  CACHE 20;  
  
  
CREATE SEQUENCE RB_seq
  MINVALUE 1
  MAXVALUE 999999999999999999999999999
  START WITH 1
  INCREMENT BY 1
  CACHE 20;  

CREATE SEQUENCE RdT_seq
  MINVALUE 1
  MAXVALUE 999999999999999999999999999
  START WITH 1
  INCREMENT BY 1
  CACHE 20;  
