README
======

This directory should be used to place project specfic documentation including
but not limited to project notes, generated API/phpdoc documentation, or 
manual files generated or hand written.  Ideally, this directory would remain
in your development environment only and should not be deployed with your
application to it's final production location.


Setting Up Your VHOST
=====================

The following is a sample VHOST you might want to consider for your project.


**1)Use o script abaixo para cliar um virtual host para esse projeto.
**2) edite o arquivo hosts para o ServerName ... tipo <nano /etc/hosts>

<VirtualHost *:80>
   DocumentRoot "/home/alberto/www/saesolid/public"
   ServerName saesolid.local

   # This should be omitted in the production environment
   SetEnv APPLICATION_ENV development
    
   <Directory "/home/alberto/www/saesolid/public">
       Options Indexes MultiViews FollowSymLinks
       AllowOverride All
       Order allow,deny
       Allow from all
   </Directory>
    
</VirtualHost>
