CREATE OR REPLACE FUNCTION createtable()
    RETURNS TEXT
    AS $$ 
    DECLARE
        query TEXT;
    BEGIN 

        RAISE NOTICE 'HELLO';
        IF EXISTS(SELECT tablename FROM pg_tables WHERE tablename='mitabla') 
            THEN 
                query:='DROP TABLE mitabla;';
                EXECUTE query;
        END IF; 

        RAISE NOTICE 'BYE';
        IF NOT EXISTS(SELECT tablename FROM pg_tables WHERE tablename='mitabla' ) 
            THEN 
                CREATE TABLE mitabla(id SERIAL, name VARCHAR(45));
                

        END IF; 
RETURN 'table created'; 
END; 
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION applyiva(INTEGER)
RETURNS NUMERIC AS $BODY$
DECLARE 
    precioproducto NUMERIC:=(SELECT price FROM productos WHERE id=$1);
    ivaproducto NUMERIC:=precioproducto*0.16;
    total NUMERIC:=precioproducto+ivaproducto;

BEGIN
    RETURN total;
END;
$BODY$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION returnid(INTEGER)
RETURNS NUMERIC AS $$
DECLARE
    id INTEGER:=$1;
BEGIN
    RETURN 'el id es: '||id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION forlearn(INTEGER)
RETURNS SETOF RECORD AS $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN
        EXECUTE 'SELECT * FROM productos'
    LOOP

    RETURN NEXT rec;
    END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION fn_copy(OUT resultado TEXT)
RETURNS TEXT AS $$
DECLARE
    consulta TEXT;

BEGIN
    IF EXISTS(SELECT tablename FROM pg_tables WHERE tablename='tmp_productos') THEN
        DROP TABLE tmp_productos;
        RAISE NOTICE 'Se elimino la table tmp_productos';
    END IF;

    CREATE TABLE tmp_productos(codigo INTEGER, nombre VARCHAR(150), precio MONEY);

    COPY tmp_productos FROM 'C:\employees\productos.csv' DELIMITER ',' CSV HEADER;

    resultado:='TODO OK';
    RETURN;
    
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION act_precio(INTEGER, NUMERIC) RETURNS NUMERIC AS $$

DECLARE
    codigoproducto INTEGER;
    priceproducto NUMERIC;
BEGIN

    UPDATE productos SET price=$2 WHERE id=$1;
    SELECT price INTO priceproducto FROM productos WHERE id=$1;

RETURN priceproducto;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION fn_copy_intocsv() RETURNS BOOLEAN AS $$
DECLARE

BEGIN
COPY(SELECT*FROM productos) TO 'etc/thiswascopied.csv' CSV HEADER DELIMITER ',';

RETURN TRUE;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION delete_alumnos() RETURNS INTEGER AS $$
DECLARE 
    alls INTEGER;
    deleted INTEGER;
BEGIN
    SELECT COUNT(*) INTO alls FROM alumnos;
    DELETE FROM alumnos WHERE promedio>85;
    SELECT COUNT(*) INTO deleted FROM alumnos;

RETURN deleted alls;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION return_prod(INTEGER) RETURNS productos AS $$
DECLARE
    prod productos;
BEGIN
    SELECT * INTO prod FROM productos WHERE id=$1; 
RETURN prod;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TABLE get_date() RETURNS TEXT AS $$
DECLARE
BEGIN



RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE VIEW alumnos_join AS SELECT * FROM alumnos AS a INNER JOIN carreras AS c ON a.idcarrera=c.idcarrera;

-- check constraint
SELECT con.*
       FROM pg_catalog.pg_constraint con
            INNER JOIN pg_catalog.pg_class rel
                       ON rel.oid = con.conrelid
            INNER JOIN pg_catalog.pg_namespace nsp
                       ON nsp.oid = connamespace
       WHERE nsp.nspname = 'public'
             AND rel.relname = 'sobresalientes';

-- find foreign key
select * from information_schema.key_column_usage
where constraint_catalog=current_catalog and table_name='sobresalientes'
and position_in_unique_constraint notnull;

-- find constraints
SELECT * FROM information_schema.table_constraints WHERE table_name='libros'

--triggers 
-- example 1:
CREATE TABLE table_one(id INTEGER, name VARCHAR(45));
CREATE TABLE table_one_resp(id INTEGER, name VARCHAR(45));

INSERT INTO table_one VALUES(1, 'John');

CREATE OR REPLACE FUNCTION func_resp() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO table_one_resp VALUES(OLD.id, OLD.name);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql 

CREATE TRIGGER update_empleados
BEFORE UPDATE ON table_one
FOR EACH ROW
EXECUTE PROCEDURE fun_resp();

UPDATE table_one SET name='John UPDATED' WHERE id=1;

SELECT * FROM table_one;
SELECT * FROM table_one_resp;

-- example 2:
CREATE TABLE table_two(id INTEGER, name VARCHAR(45), password(45));

INSERT INTO table_two VALUES(1, 'John', 1234);

CREATE OR REPLACE FUNCTION func_password() RETURNS TRIGGER AS $$
BEGIN
    IF LENGTH(NEW.password)>8 OR NEW.password IS NULL THEN
        RAISE EXCEPTION 'Password must be at least 8 characters or must not be null';
    INSERT INTO table_one_resp VALUES(OLD.id, OLD.name, OLD.password);
    END IF;

    IF NEW.name IS NULL THEN
        RAISE EXCEPTION 'Name must not be null';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql; 

CREATE TRIGGER trigger_password
BEFORE INSERT OR UPDATE ON table_two
FOR EACH ROW
EXECUTE PROCEDURE func_password();

INSERT INTO table_two VALUES(1, 'Jose', 123);

-- example 3
CREATE TABLE clientes(id INTEGER, name VARCHAR(45), fechaalta DATE);

CREATE OR REPLACE FUNCTION func_validar_fecha() RETURNS TRIGGER AS $$

BEGIN
    IF(EXTRACT(YEAR FROM NEW.fechaalta))>(SELECT EXTRACT(YEAR FROM CURRENT_DATE)) THEN
    RAISE EXCEPTION 'Error in the year';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_clientes
BEFORE INSERT OR UPDATE ON clientes
FOR EACH ROW
EXECUTE PROCEDURE func_validar_fecha();

-- example 4
DROP TABLE IF EXISTS clientes;

CREATE TABLE clientes(
    idcliente INTEGER PRIMARY KEY,
    nombre TEXT,
    direccion TEXT,
    fecha_alta DATE
);

INSERT INTO clientes(idcliente,nombre,direccion,fecha_alta) VALUES (1,'haha','anywhere','2022-08-28');

CREATE TABLE log_clientes(
    idcliente INTEGER PRIMARY KEY,
    nombre TEXT,
    direccion TEXT,
    fecha_alta DATE,
    log_movimiento TEXT,
    log_fecha_movimiento DATE
);

CREATE OR REPLACE FUNCTION tg_func_log_clientes() RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP='INSERT' OR TG_OP='UPDATE') THEN
        INSERT INTO log_clientes (idcliente, nombre, direccion, fecha_alta, log_movimiento, log_fecha_movimiento) VALUES (NEW.idcliente, NEW.nombre, NEW.direccion, NEW.fecha_alta, TG_OP, CURRENT_DATE);
        RETURN NEW;
    END IF;
    IF (TG_OP='DELETE') THEN 
        INSERT INTO log_clientes (idcliente, nombre, direccion, fecha_alta, log_movimiento, log_fecha_movimiento) VALUES (OLD.idcliente, OLD.nombre, OLD.direccion, OLD.fecha_alta, TG_OP, CURRENT_DATE); 
    RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_log_cliente AFTER INSERT OR UPDATE OR DELETE ON clientes
FOR EACH ROW EXECUTE PROCEDURE tg_func_log_clientes;

-- example 5
CREATE TABLE libros(
    id SERIAL PRIMARY KEY,
    titulo VARCHAR(40),
    autor VARCHAR(30),
    codigoeditorial INTEGER,
    precio DECIMAL(5,2),
    cantidad SMALLINT,
);

CREATE TABLE log_libros(titulo VARCHAR(40), autor VARCHAR(30),codigoeditorial INTEGER,precio DECIMAL(5,2),cantidad SMALLINT, log_fecha DATE);
INSERT INTO libros(titulo, autor,codigoeditorial,precio,cantidad)
    VALUES('el aleph','Jorge Luis Borges',1,450,5),
    ('1984', 'George Orwell',2,300,4),
    ('El gato negro', 'Edgar Allan Poe', 1,400,6
);

CREATE OR REPLACE FUNCTION log_func_libros() RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP='INSERT') THEN
        INSERT INTO log_libros(titulo, autor,codigoeditorial,precio,cantidad, log_fecha) VALUES(NEW.titulo, NEW.autor, NEW.codigoeditorial, NEW.precio, NEW.cantidad, CURRENT_DATE);
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

ALTER TABLE libros ADD CONSTRAINT titulo UNIQUE;

CREATE TRIGGER tg_func_log_libros AFTER INSERT OR UPDATE ON libros
FOR EACH ROW EXECUTE PROCEDURE log_func_libros();