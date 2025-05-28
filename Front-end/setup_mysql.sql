-- Script para configurar el usuario y permisos de MySQL
-- Guarda este archivo como setup_mysql.sql y ejecútalo con: mysql -u root -p < setup_mysql.sql

-- Cambiar el plugin de autenticación para el usuario root local
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'dani';

-- Crear un usuario remoto si es necesario
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'dani';

-- Otorgar todos los privilegios
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON gestionturnos.* TO 'root'@'%';

-- Aplicar los cambios
FLUSH PRIVILEGES;

-- Mostrar los usuarios y sus métodos de autenticación
SELECT user, host, plugin FROM mysql.user;
