@echo off

:: Verificar si MySQL está instalado
echo Verificando instalación de MySQL...
mysql --version > nul 2>&1
if errorlevel 1 (
    echo MySQL no está instalado o no está en el PATH.
    echo Por favor, instala MySQL y asegúrate de que el ejecutable mysql.exe esté en el PATH.
    echo Puedes descargar MySQL desde: https://dev.mysql.com/downloads/installer/
    exit /b 1
)

echo MySQL está instalado correctamente.

echo.
echo Creando base de datos y usuario...

:: Crear base de datos y usuario
mysql -u root -e "CREATE DATABASE IF NOT EXISTS gestionturnos CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -e "CREATE USER IF NOT EXISTS 'root'@'localhost' IDENTIFIED BY 'rootpassword123';"
mysql -u root -e "GRANT ALL PRIVILEGES ON gestionturnos.* TO 'root'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"

echo.
echo Base de datos configurada correctamente.
echo.
echo Iniciando la aplicación Spring Boot...

:: Iniciar la aplicación
mvn spring-boot:run
