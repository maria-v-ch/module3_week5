-- Создание таблицы customers

CREATE TABLE IF NOT EXISTS customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20) NOT NULL,
    address VARCHAR(255)
);


-- Создание таблицы orders

CREATE TABLE IF NOT EXISTS orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    shipping_address VARCHAR(255),
    order_status VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);


-- Создание таблицы product categories

CREATE TABLE IF NOT EXISTS product_categories (
    category_id SERIAL PRIMARY KEY, 
    category_name VARCHAR(50) UNIQUE
);


-- Создание таблицы products

CREATE TABLE IF NOT EXISTS products (
    product_id SERIAL PRIMARY KEY, 
    product_name VARCHAR(100), 
    description TEXT,
    price NUMERIC (18, 2),
    stock INT,
    category_id INT,
    FOREIGN KEY (category_id) REFERENCES product_categories(category_id) ON DELETE CASCADE
);


-- Создание таблицы order details

CREATE TABLE IF NOT EXISTS order_details (
    order_detail_id SERIAL PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price NUMERIC(10, 2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);


-- Вставка данных в таблицу customers
INSERT INTO customers (first_name, last_name, email, phone, address)
VALUES
('John', 'Doe', 'john.doe@example.com', '123-456-7890', '123 Elm St'),
('Jane', 'Doe', 'jane.doe@example.com', '987-654-3210', '456 Oak St'),
('Alice', 'Johnson', 'alice.johnson@example.com', '555-678-1234', '789 Pine St'),
('Bob', 'Smith', 'bob.smith@example.com', '555-123-4567', '789 Maple St'),
('Charlie', 'Brown', 'charlie.brown@example.com', '555-987-6543', '321 Chestnut St'),
('David', 'Jones', 'david.jones@example.com', '555-321-9876', '654 Willow St'),
('Eve', 'Taylor', 'eve.taylor@example.com', '555-654-3219', '987 Birch St'),
('Frank', 'Miller', 'frank.miller@example.com', '555-321-6540', '321 Ash St'),
('Grace', 'Davis', 'grace.davis@example.com', '555-654-3211', '654 Cedar St'),
('Helen', 'Wilson', 'helen.wilson@example.com', '555-321-6542', '987 Elm St');



-- Вставка данных в таблицу orders

INSERT INTO orders (customer_id, order_date, shipping_address, order_status)
VALUES
(1, '2023-01-01', '123 Elm St', 'Shipped'),
(2, '2023-01-02', '456 Oak St', 'Pending'),
(3, '2023-01-03', '789 Pine St', 'Delivered'),
(4, '2023-01-04', '789 Maple St', 'Cancelled'),
(5, '2023-01-05', '321 Chestnut St', 'Shipped');


-- Вставка данных в таблицу product_categories

INSERT INTO product_categories (category_name)
VALUES
('tables'),
('chairs'),
('cupboards'),
('beds'),
('sofas');


-- Вставка данных в таблицу products

INSERT INTO products (product_name, description, price, stock, category_id)
VALUES
('QWERTY', 'nice QWERTY', 10, 12, 5),
('ASDFGH', 'nice ASDFGH', 20, 10, 4),
('ZXCVBN', 'nice ZXCVBN', 30, 8, 3),
('MNBVCX', 'nice MNBVCX', 40, 2, 2),
('LKJHGF', 'nice LKJHGF', 50, 3, 1);


-- Вставка данных в таблицу order_details

INSERT INTO order_details (product_id, quantity, unit_price)
VALUES
(1, 1, 10),
(2, 2, 20),
(4, 2, 40),
(5, 1, 50),
(2, 4, 20);


-- Проверка вставки данных в таблицу customers

SELECT * FROM customers;


-- Проверка вставки данных в таблицу orders

SELECT * FROM orders;


-- Проверка вставки данных в таблицу product_categories

SELECT * FROM product_categories;


-- Проверка вставки данных в таблицу products

SELECT * FROM products;


-- Проверка вставки данных в таблицу order_order_details

SELECT * FROM order_details;


-- Проверка связей FOREIGN KEY

SELECT orders.order_id,
	orders.order_date,
	orders.shipping_address,
	orders.order_status,
	customers.first_name,
	customers.last_name,
    order_details.order_detail_id,
    order_details.product_id,
    order_details.quantity,
    order_details.unit_price,
    products.product_name,
    products.description,
    products.price,
    products.stock,
    products.category_id,
    product_categories.category_name
FROM orders
JOIN customers ON orders.customer_id = customers.customer_id
JOIN order_details ON orders.order_id = order_details.order_id
JOIN products ON order_details.product_id = products.product_id
JOIN product_categories ON products.category_id = product_categories.category_id


-- Функция для получения общей суммы продаж по категориям товаров за определенный период. 
-- На вход подается дата начала и конца периода. 
-- На выход должна быть таблица с колонками: название категории и общая сумма продаж.

CREATE FUNCTION get_total_sales_per_category_per_period(from_date DATE, to_date DATE)
RETURNS TABLE (
	category,
	total_sales_per_category_per_period
) AS $$ BEGIN RETURN (
	WITH cte AS (
		SELECT (
				SELECT category_name
				FROM product_categories prc
				WHERE prc.category_id = pr.category_id
			) AS category,
			SUM(od.quantity * od.unit_price) AS category_sales_per_date,
			o.order_date
		FROM products pr
			INNER JOIN order_details od ON pr.product_id = od.product_id
			INNER JOIN orders o ON od.order_id = o.order_id
		WHERE o.order_status <> 'Cancelled'
		GROUP BY category_id,
			order_date
	)
	SELECT cte.category,
		SUM(category_sales_per_date) AS total_sales_per_category_per_period
	FROM cte
	WHERE cte.order_date BETWEEN get_total_sales_per_category_per_period.from_date AND get_total_sales_per_category_per_period.to_date
	GROUP BY cte.category
);
END;
$$ LANGUAGE plpgsql;


-- Процедура для обновления количества товара на складе после создания нового заказа.
-- На вход подается id заказа.
-- Процедура должна обновить количество товаров, которые были добавлены в заказ, то есть уменьшить их количество на складе.
-- Если id заказа не существует, нужно вызвать исключение.

CREATE PROCEDURE update_stock(order_id INTEGER)
AS $$
BEGIN
    update products
    SET stock = stock - quantity
    FROM order_details
    WHERE order_details.order_id = update_stock.order_id;
    IF NOT order_details.order_id = update_stock.order_id 
    	THEN
    	dbms_output.put_line('SUCH ORDER_ID DOES NOT EXIST')
    END IF;
END;
$$ LANGUAGE plpgsql
