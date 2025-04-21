--2 Create a new user with the username "rentaluser" and the password "rentalpassword". Give the user the ability to connect to the database but no other permissions.
--2.1
--Create a new user
CREATE ROLE rentaluser WITH LOGIN PASSWORD 'rentalpassword';
-- Grant connect ability to database
GRANT CONNECT ON DATABASE dvdrental TO rentaluser;
--2.2 Grant "rentaluser" SELECT permission for the "customer" table. Сheck to make sure this permission works correctly—write a SQL query to select all customers.
-- Grant SELECT permission on customer table
GRANT SELECT ON customer TO rentaluser;
-- Test:
-- SELECT * FROM customer;

--2.3 Create a new user group called "rental" and add "rentaluser" to the group. 
-- Create a role group
CREATE ROLE rental;
-- Add rentaluser to the rental group
GRANT rental TO rentaluser;
--2.4 Grant the "rental" group INSERT and UPDATE permissions for the "rental" table. Insert a new row and update one existing row in the "rental" table under that role. 
-- Grant INSERT and UPDATE to the group on rental table
GRANT INSERT, UPDATE ON rental TO rental;

-- Test as rentaluser:
INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id)
VALUES (NOW(), 1, 1, 1);
UPDATE rental SET return_date = NOW() WHERE rental_id = 1;

--2.5 Revoke the "rental" group's INSERT permission for the "rental" table. Try to insert new rows into the "rental" table make sure this action is denied.
-- Revoke INSERT from group
REVOKE INSERT ON rental FROM rental;
-- Test
Should throw an error
INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id)
VALUES (NOW(), 1, 1, 1);

--2.6 Create a personalized role for any customer already existing in the dvd_rental database. The name of the role name must be client_{first_name}_{last_name} (omit curly brackets). 
--The customer's payment and rental history must not be empty. 
-- Find a customer with at least 1 rental and 1 payment
DO $$
DECLARE
    cust RECORD;
    role_name TEXT;
BEGIN
    FOR cust IN
        SELECT DISTINCT c.customer_id, c.first_name, c.last_name
        FROM public.customer c
        WHERE EXISTS (SELECT 1 FROM public.payment p WHERE p.customer_id = c.customer_id)
          AND EXISTS (SELECT 1 FROM public.rental r WHERE r.customer_id = c.customer_id)
    LOOP
        role_name := format('client_%s_%s', LOWER(cust.first_name), LOWER(cust.last_name));

        -- Avoid duplicates
        IF NOT EXISTS (
            SELECT 1 FROM pg_roles WHERE rolname = role_name
        ) THEN
            EXECUTE format('CREATE ROLE %I WITH LOGIN PASSWORD %L', role_name, 'securepassword123');
            EXECUTE format('GRANT CONNECT ON DATABASE dvdrental TO %I', role_name);
            EXECUTE format('GRANT SELECT ON payment TO %I', role_name);
            EXECUTE format('GRANT SELECT ON rental TO %I', role_name);
            RAISE NOTICE 'Created role: %', role_name;
        ELSE
             EXECUTE format('DROP ROLE %I', role_name);
        END IF;
    END LOOP;
END $$;

--3.Configure that role so that the customer can only access their own data in the "rental" and "payment" tables. Write a query to make sure this user sees only their own data.
-- Allow row-level security
ALTER TABLE rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;
-- Policy that customer can see only his own data
-- Policy for rental
CREATE POLICY rental_rls_policy ON rental
FOR SELECT
TO PUBLIC
USING (
 customer_id = current_setting('app.current_customer_id', true)::INTEGER
);
-- Policy for payment
CREATE POLICY payment_rls_policy ON payment
FOR SELECT
TO PUBLIC
USING (
 customer_id = current_setting('app.current_customer_id', true)::INTEGER
);
--
-- Connect as client_JENNIFER_DAVIS
SET ROLE client_JENNIFER_DAVIS;
SET app.current_customer_id = '130';

-- Check
SELECT * FROM rental;
SELECT * FROM payment;





