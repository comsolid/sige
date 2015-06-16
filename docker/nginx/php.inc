# Simple include for PHP files
index index.php index.html;

location = /favicon.ico {
	log_not_found off;
	access_log off;
}

location = /robots.txt {
	allow all;
	log_not_found off;
	access_log off;
}

location ~ \..*/.*\.php$ {
	return 403;
}

location ~ \.php$ {
	fastcgi_split_path_info ^(.+\.php)(/.+)$;
	fastcgi_pass php:9000;
	fastcgi_index index.php;
	include fastcgi_params;
	fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
	fastcgi_param APPLICATION_ENV development;
	fastcgi_intercept_errors on;
#	fastcgi_pass unix:/var/run/php5-fpm.sock;
}

location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
	expires max;
	log_not_found off;
}
