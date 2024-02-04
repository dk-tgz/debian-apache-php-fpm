Dockerized Apache2 (mods http2, fcgi) with PHP-FPM in a single container managed by supervisord.

Exists as example because I could not find any actual image with combined apache with php8.2-fpm.

## Features:
- Debian 12 (Bullseye): Uses Debian 12 as the base image, providing a stable and secure foundation.
- PHP 8.2: Includes the latest PHP 8.2 along with popular extensions and modules for a wide range of functionalities.
- Apache2 Web Server: Configured with Apache2 to serve web content, with mod_pagespeed for performance optimizations.
- Opcache Optimization: PHP Opcache is configured for better performance, reducing the PHP script execution times.
- Supervisor: Uses Supervisor for process control, ensuring the web server and PHP processes are kept alive.


Tags:
#debian #supervisord #php8.2-fpm #apache2 #httpd 
