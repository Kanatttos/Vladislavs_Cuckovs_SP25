CREATE SCHEMA IF NOT EXISTS subway_system;


-- 1. Train table
CREATE TABLE IF NOT EXISTS subway_system.train(
	train_id BIGSERIAL PRIMARY KEY,
	model_name VARCHAR(100) DEFAULT 'X',
	capacity INT NOT NULL CHECK (capacity >= 0) DEFAULT 100,  --SET DEFAULT values
	manufacture_year INT NOT NULL CHECK(manufacture_year > 2000),
	status VARCHAR(100) DEFAULT 'Inactive',   --SET DEFAULT values
	train_number INT UNIQUE NOT NULL

);
-- Inserting data
INSERT INTO subway_system.train(model_name, capacity, manufacture_year, status, train_number  )
VALUES
('Miller321', 250, 2002, 'Active', 32),
(DEFAULT, 300, 2015, DEFAULT, 322);

--Show added data in table
SELECT  * FROM subway_system.train;

--Add row
ALTER TABLE subway_system.train
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE
CHECK (record_ts > '2000-01-01');

--Show added data in table with extra rows
SELECT  * FROM subway_system.train;

-- 2. Station table
CREATE TABLE IF NOT EXISTS subway_system.station (
    station_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    location VARCHAR(200) NOT NULL
);

-- Inserting data
INSERT INTO  subway_system.station (name, location )
VALUES 
('Midwest', 'Huston district 2'),
('City Hall', 'City district 3');

--Show added data in table
SELECT  * FROM subway_system.station;

--Add row
ALTER TABLE subway_system.station
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE
CHECK (record_ts > '2000-01-01');

--Show added data in table with extra rows
SELECT  * FROM subway_system.station;

-- 3. Employee table
CREATE TABLE IF NOT EXISTS subway_system.employees (
    employee_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(100) NOT NULL CHECK (role IN ('driver', 'technician', 'manager')), -- CHECK: ENUM-LIKE role
    contact_number VARCHAR(20)  NOT NULL ,
    assigned_station_id INT NOT NULL  REFERENCES subway_system.station(station_id)
);

-- Inserting data
INSERT INTO  subway_system.employees ( name, role,contact_number,assigned_station_id )
SELECT * FROM(
VALUES 
('Mather Jinks', 'manager', '33445' , (SELECT station_id FROM subway_system.station WHERE name LIKE 'Midwest')),
('Jil Mont', 'technician', '777676', (SELECT station_id FROM subway_system.station WHERE name LIKE 'City Hall'))
) AS new_employee (name, role, contact_number, assigned_station_id)
WHERE NOT EXISTS (SELECT 1 FROM subway_system.employees e WHERE e.name = new_employee.name 
														AND e.role = new_employee.role
														AND e.contact_number = new_employee.contact_number
														AND e.assigned_station_id = new_employee.assigned_station_id);

--Show added data in table
SELECT  * FROM subway_system.employees;

--Add row
ALTER TABLE subway_system.employees
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE
CHECK (record_ts > '2000-01-01');

--Show added data in table with extra rows
SELECT  * FROM subway_system.employees;

-- 4. Line table
CREATE TABLE IF NOT EXISTS subway_system.lines (
    line_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    colour VARCHAR(25) NOT NULL,
    open_from_hours TIME NOT NULL,
    open_to_hours TIME NOT NULL
);


-- Inserting data
INSERT INTO  subway_system.lines (name, colour, open_from_hours, open_to_hours )
VALUES 
('Center', 'Purple', '6:00:00'::TIME, '23:30:00'::TIME),
('North', 'Grey', '4:30:00'::TIME , '23:50:00'::TIME);

--Show added data in table
SELECT  * FROM subway_system.lines;

--Add row
ALTER TABLE subway_system.lines
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE
CHECK (record_ts > '2000-01-01');

--Show added data in table with extra rows
SELECT  * FROM subway_system.lines;


-- 5. Line Requirements table
CREATE TABLE IF NOT EXISTS  subway_system.line_requirements (
    requirement_id BIGSERIAL PRIMARY KEY,
    line_id INT NOT NULL REFERENCES subway_system.lines(line_id),
    required_train INT NOT NULL REFERENCES subway_system.train(train_id),
    required_employee INT NOT NULL REFERENCES subway_system.employees(employee_id),
    operating_frequency_minutes INT NOT NULL
);

-- Inserting data
INSERT INTO  subway_system.line_requirements (line_id, required_train, required_employee, operating_frequency_minutes )
SELECT * FROM(
VALUES 
((SELECT line_id FROM subway_system.lines  WHERE colour LIKE 'Purple'), (SELECT train_id FROM subway_system.train WHERE train_number = 322),
(SELECT employee_id FROM subway_system.employees WHERE name LIKE 'Mather Jinks'), 60),
((SELECT line_id FROM subway_system.lines  WHERE colour LIKE 'Grey'), (SELECT train_id FROM subway_system.train WHERE train_number = 32),
(SELECT employee_id FROM subway_system.employees WHERE name LIKE 'Jil Mont') , 25)) 
AS new_line_requirements(line_id, required_train, required_employee, operating_frequency_minutes)
WHERE NOT EXISTS (SELECT 1 FROM subway_system.line_requirements l WHERE l.line_id = new_line_requirements.line_id 
														AND l.required_train = new_line_requirements.required_train
														AND l.required_employee = new_line_requirements.required_employee
														AND l.operating_frequency_minutes = new_line_requirements.operating_frequency_minutes);
;

--Show added data in table
SELECT  * FROM subway_system.line_requirements;

--Add row
ALTER TABLE subway_system.line_requirements
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE
CHECK (record_ts > '2000-01-01');

--Show added data in table with extra rows
SELECT  * FROM subway_system.line_requirements;



-- 6. Routes table
CREATE TABLE IF NOT EXISTS  subway_system.routes (
    route_id BIGSERIAL PRIMARY KEY,
    line_id INT NOT NULL REFERENCES subway_system.lines(line_id),
    start_station_id INT NOT NULL REFERENCES subway_system.station(station_id),
    end_station_id INT NOT NULL REFERENCES subway_system.station(station_id),
    route_distance DECIMAL(4,2) NOT NULL CHECK (route_distance >= 0) -- CHECK: Non-negative
);

-- Inserting data
INSERT INTO  subway_system.routes (line_id, start_station_id, end_station_id, route_distance )
SELECT * FROM(
VALUES 
((SELECT line_id FROM subway_system.lines  WHERE colour LIKE 'Purple'), 
(SELECT station_id FROM subway_system.station WHERE name LIKE 'Midwest'), 
(SELECT station_id FROM subway_system.station WHERE name LIKE 'City Hall'), 43),
((SELECT line_id FROM subway_system.lines  WHERE colour LIKE 'Grey'), 
(SELECT station_id FROM subway_system.station WHERE name LIKE 'City Hall'),
(SELECT station_id FROM subway_system.station WHERE name LIKE 'Midwest'), 43)) AS new_routes(line_id, start_station_id, end_station_id, route_distance)
WHERE NOT EXISTS (SELECT 1 FROM subway_system.routes r WHERE r.line_id = new_routes.line_id 
														AND r.start_station_id = new_routes.start_station_id
														AND r.end_station_id = new_routes.end_station_id
														AND r.route_distance = new_routes.route_distance);
;

--Show added data in table
SELECT  * FROM subway_system.routes;

--Add row
ALTER TABLE subway_system.routes
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE
CHECK (record_ts > '2000-01-01');

--Show added data in table with extra rows
SELECT  * FROM subway_system.routes;


-- 7. Schedules table
CREATE TABLE IF NOT EXISTS subway_system.schedules (
    schedule_id BIGSERIAL PRIMARY KEY,
    route_id INT NOT NULL REFERENCES subway_system.routes(route_id),
    departure_time TIME NOT NULL,
    arrival_time TIME NOT NULL
);

-- Inserting data
INSERT INTO  subway_system.schedules (route_id, departure_time, arrival_time )
SELECT * FROM(
VALUES 
((SELECT route_id FROM subway_system.routes WHERE line_id = 1), '6:00:00'::TIME, '6:42:00'::TIME),
((SELECT route_id FROM subway_system.routes WHERE line_id = 2), '16:00:00'::TIME, '16:52:00'::TIME)) AS new_schedules(route_id, departure_time, arrival_time )
WHERE NOT EXISTS (SELECT 1 FROM subway_system.schedules s WHERE s.route_id = new_schedules.route_id 
														AND s.departure_time = new_schedules.departure_time
														AND s.arrival_time = new_schedules.arrival_time)
;

--Show added data in table
SELECT  * FROM subway_system.schedules;

--Add row
ALTER TABLE subway_system.schedules
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE
CHECK (record_ts > '2000-01-01');

--Show added data in table with extra rows
SELECT  * FROM subway_system.schedules;


-- 8. Route Stops table
CREATE TABLE IF NOT EXISTS subway_system.route_stops (
    stop_id BIGSERIAL PRIMARY KEY,
    route_id INT NOT NULL REFERENCES subway_system.routes(route_id),
    station_id INT NOT NULL REFERENCES subway_system.station(station_id),
    arrival_time TIME NOT NULL,
    departure_time TIME NOT NULL
);

-- Inserting data
INSERT INTO  subway_system.route_stops (route_id, station_id, arrival_time,departure_time )
SELECT * FROM(
VALUES 
((SELECT route_id FROM subway_system.routes WHERE line_id = 1), (SELECT station_id FROM subway_system.station WHERE name LIKE 'City Hall'), 
'6:42:00'::TIME, '6:55:00'::TIME),
((SELECT route_id FROM subway_system.routes WHERE line_id = 2), (SELECT station_id FROM subway_system.station WHERE name LIKE 'Midwest'),
'16:52:00'::TIME, '16:57:00'::TIME)) AS new_route_stops (route_id, station_id, arrival_time,departure_time )
WHERE NOT EXISTS (SELECT 1 FROM subway_system.route_stops r WHERE r.route_id = new_route_stops.route_id 
														AND r.station_id = new_route_stops.station_id
														AND r.arrival_time = new_route_stops.arrival_time
														AND r.departure_time = new_route_stops.departure_time)

;

--Show added data in table
SELECT  * FROM subway_system.route_stops;

--Add row
ALTER TABLE subway_system.route_stops
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE
CHECK (record_ts > '2000-01-01');

--Show added data in table with extra rows
SELECT  * FROM subway_system.route_stops;

-- 9. Train Operations table
CREATE TABLE IF NOT EXISTS subway_system.train_operations (
    operation_id BIGSERIAL PRIMARY KEY,
    train_id INT NOT NULL REFERENCES subway_system.train(train_id),
    route_id INT NOT NULL REFERENCES subway_system.routes(route_id),
    schedule_id INT NOT NULL REFERENCES subway_system.schedules(schedule_id),
    operator_id INT NOT NULL REFERENCES subway_system.employees(employee_id)
);

-- Inserting data
INSERT INTO  subway_system.train_operations (train_id, route_id, schedule_id,operator_id )
SELECT * FROM(
VALUES 
((SELECT train_id FROM subway_system.train WHERE train_number = 32), (SELECT route_id FROM subway_system.routes WHERE line_id = 2) ,
(SELECT schedule_id FROM subway_system.schedules s JOIN subway_system.routes r ON s.route_id = r.route_id 
WHERE s.departure_time = '16:00:00'::TIME AND r.line_id = 2 ) ,(SELECT employee_id FROM subway_system.employees WHERE name LIKE 'Mather Jinks')),
((SELECT train_id FROM subway_system.train WHERE train_number = 322), (SELECT route_id FROM subway_system.routes WHERE line_id = 1),
(SELECT schedule_id FROM subway_system.schedules s JOIN subway_system.routes r ON s.route_id = r.route_id 
WHERE s.departure_time = '16:00:00'::TIME AND r.line_id = 2 ), (SELECT employee_id FROM subway_system.employees WHERE name LIKE 'Jil Mont'))
) AS new_train_operations (train_id, route_id, schedule_id,operator_id )
WHERE NOT EXISTS (SELECT 1 FROM subway_system.train_operations t WHERE t.train_id = new_train_operations.train_id 
														AND t.route_id = new_train_operations.route_id
														AND t.schedule_id = new_train_operations.schedule_id
														AND t.operator_id = new_train_operations.operator_id)

;
--Show added data in table
SELECT  * FROM subway_system.train_operations;

--Add row
ALTER TABLE subway_system.train_operations
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE
CHECK (record_ts > '2000-01-01');

--Show added data in table with extra rows
SELECT  * FROM subway_system.train_operations;



-- 10. Infrastructure
CREATE TABLE IF NOT EXISTS subway_system.infrastructure (
    infrastructure_id BIGSERIAL PRIMARY KEY,
    type VARCHAR(80) NOT NULL,
    status VARCHAR(200) NOT NULL
);

-- Inserting data
INSERT INTO  subway_system.infrastructure (type, status )
SELECT * FROM(
VALUES 
('Station', 'Active'),
('Rails' , 'Inactive')) AS new_infrastructure(type, status )
WHERE NOT EXISTS (SELECT 1 FROM subway_system.infrastructure i WHERE i.type = new_infrastructure.type 
														AND i.status = new_infrastructure.status);

--Show added data in table
SELECT  * FROM subway_system.infrastructure;

--Add row
ALTER TABLE subway_system.infrastructure
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE
CHECK (record_ts > '2000-01-01');

--Show added data in table with extra rows
SELECT  * FROM subway_system.infrastructure;

-- 11. Maintenance Records
CREATE TABLE IF NOT EXISTS subway_system.maintenance_records (
    maintenance_id BIGSERIAL  PRIMARY KEY,
    infrastructure_id INT  NOT NULL REFERENCES subway_system.infrastructure(infrastructure_id),
    employee_id INT  NOT NULL REFERENCES subway_system.employees(employee_id),
    maintenance_date DATE NOT NULL CHECK (maintenance_date > '2000-01-01')
); 

-- Inserting data
INSERT INTO  subway_system.maintenance_records (infrastructure_id, employee_id, maintenance_date )
SELECT * FROM(
VALUES 
((SELECT infrastructure_id FROM subway_system.infrastructure WHERE UPPER(type) LIKE UPPER('Station') AND UPPER(status) LIKE UPPER('Active') ), (SELECT employee_id FROM subway_system.employees WHERE name LIKE 'Jil Mont'), '2009-01-01'::DATE),
((SELECT infrastructure_id FROM subway_system.infrastructure WHERE UPPER(type) LIKE UPPER('Rails') AND UPPER(status) LIKE UPPER('Inactive') ), (SELECT employee_id FROM subway_system.employees WHERE name LIKE 'Jil Mont'), '2009-11-01'::DATE)) AS new_maintenance_records (infrastructure_id, employee_id, maintenance_date )
WHERE NOT EXISTS (SELECT 1 FROM subway_system.maintenance_records m WHERE m.infrastructure_id = new_maintenance_records.infrastructure_id 
														AND m.employee_id = new_maintenance_records.employee_id
														AND m.maintenance_date = new_maintenance_records.maintenance_date);

--Show added data in table
SELECT  * FROM subway_system.maintenance_records;

--Add row
ALTER TABLE subway_system.maintenance_records
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE
CHECK (record_ts > '2000-01-01');

--Show added data in table with extra rows
SELECT  * FROM subway_system.maintenance_records;


 -- 12. Discount table
CREATE TABLE IF NOT EXISTS subway_system.discount (
    discount_id BIGSERIAL PRIMARY KEY,
    describtion VARCHAR(100) NOT NULL,
   	percentage DECIMAL(5,2) CHECK (percentage >= 0),
   	valid_from DATE NOT NULL CHECK (valid_from > '2000-01-01'),
    valid_to DATE NOT NULL CHECK (valid_to > '2000-01-01')
); 

-- Inserting data
INSERT INTO  subway_system.discount (describtion, percentage, valid_from,valid_to )
SELECT * FROM(
VALUES 
('Child discount', 25.0, CURRENT_DATE, CURRENT_DATE + 30),
('Tuesday discount', 12.0, CURRENT_DATE,  CURRENT_DATE + 1)) AS new_discount (describtion, percentage, valid_from,valid_to )
WHERE NOT EXISTS (SELECT 1 FROM subway_system.discount d WHERE d.describtion = new_discount.describtion 
														AND d.percentage = new_discount.percentage
														AND d.valid_from = new_discount.valid_from
														AND d.valid_to = new_discount.valid_to);

--Show added data in table
SELECT  * FROM subway_system.discount;

--Add row
ALTER TABLE subway_system.discount
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE
CHECK (record_ts > '2000-01-01');

--Show added data in table with extra rows
SELECT  * FROM subway_system.discount;

--13. Ticket table
CREATE TABLE IF NOT EXISTS subway_system.ticket (
    ticket_id BIGSERIAL PRIMARY KEY,
    type VARCHAR(50) NOT NULL CHECK ("type" IN ('One Way','Return')),
   	price DECIMAL(5,2) NOT NULL CHECK (price > 0),
   discount_id INT NOT NULL REFERENCES subway_system.discount(discount_id)
);

-- Inserting data
INSERT INTO  subway_system.ticket (type, price, discount_id)
SELECT * FROM(
VALUES 
('One Way', 25.00, (SELECT discount_id FROM subway_system.discount WHERE describtion = 'Child discount' AND valid_to = CURRENT_DATE)),
('Return', 40.00, (SELECT discount_id FROM subway_system.discount WHERE describtion = 'Tuesday discount' AND valid_to = CURRENT_DATE))
) AS new_ticket (type, price, c)
WHERE NOT EXISTS (SELECT 1 FROM subway_system.ticket t WHERE t.type = new_ticket.type 
														AND t.price = new_ticket.price
														AND t.price = new_ticket.price);

--Show added data in table
SELECT  * FROM subway_system.ticket;

--Add row
ALTER TABLE subway_system.ticket
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE
CHECK (record_ts > '2000-01-01');

--Show added data in table with extra rows
SELECT  * FROM subway_system.ticket;


-- 14. Ticket Sales table
CREATE TABLE IF NOT EXISTS subway_system.ticket_sales (
    sale_id BIGSERIAL PRIMARY KEY,
    ticket_id INT NOT NULL REFERENCES subway_system.ticket(ticket_id),
    purchase_date DATE NOT NULL CHECK (purchase_date > '2000-01-01') ,
    station_id INT NOT NULL REFERENCES subway_system.station(station_id),
    payment_method VARCHAR(40) NOT NULL CHECK (payment_method IN ('card', 'cash', 'other'))  -- CHECK: ENUM-LIKE payment method
);

-- Inserting data
INSERT INTO  subway_system.ticket_sales (ticket_id, purchase_date, station_id,payment_method )
SELECT * FROM(
VALUES 
((SELECT ticket_id FROM subway_system.ticket WHERE UPPER(type) LIKE UPPER('Return') AND discount_id = 2), CURRENT_DATE,  
(SELECT station_id FROM subway_system.station WHERE name LIKE 'City Hall'), 'card'),
((SELECT ticket_id FROM subway_system.ticket WHERE UPPER(type) LIKE UPPER('One Way') AND discount_id = 1), CURRENT_DATE,  
(SELECT station_id FROM subway_system.station WHERE name LIKE 'City Hall'), 'cash')) AS new_ticket_sales (ticket_id, purchase_date, station_id,payment_method )
WHERE NOT EXISTS (SELECT 1 FROM subway_system.ticket_sales t WHERE t.ticket_id = new_ticket_sales.ticket_id 
														AND t.purchase_date = new_ticket_sales.purchase_date
														AND t.station_id = new_ticket_sales.station_id
														AND t.payment_method = new_ticket_sales.payment_method);

--Show added data in table
SELECT  * FROM subway_system.ticket_sales;

--Add row
ALTER TABLE subway_system.ticket_sales
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE
CHECK (record_ts > '2000-01-01');

--Show added data in table with extra rows
SELECT  * FROM subway_system.ticket_sales;

-- 15. Passanger table
CREATE TABLE IF NOT EXISTS subway_system.passanger (
    passanger_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
   	surname VARCHAR(50) NOT NULL,
   	ticket_id INT NOT NULL REFERENCES subway_system.ticket(ticket_id)
);

-- Inserting data
INSERT INTO  subway_system.passanger (name, surname, ticket_id)
SELECT * FROM(
VALUES 
('Milly', 'Poppy', (SELECT ticket_id FROM subway_system.ticket WHERE UPPER(type) LIKE UPPER('Return') AND discount_id = 2)),
('Fion', 'Joje', (SELECT ticket_id FROM subway_system.ticket WHERE UPPER(type) LIKE UPPER('One Way') AND discount_id = 1))
) AS new_passanger (name, surname, ticket_id)
WHERE NOT EXISTS (SELECT 1 FROM subway_system.passanger p WHERE p.name = new_passanger.name 
														AND p.surname = new_passanger.surname
														AND p.ticket_id = new_passanger.ticket_id);

--Show added data in table
SELECT  * FROM subway_system.passanger;

--Add row
ALTER TABLE subway_system.passanger
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE
CHECK (record_ts > '2000-01-01');

--Show added data in table with extra rows
SELECT  * FROM subway_system.passanger;

