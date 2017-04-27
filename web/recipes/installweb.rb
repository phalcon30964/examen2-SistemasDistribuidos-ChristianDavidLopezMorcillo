package 'httpd'
package 'php'
package 'php-mysql' #Libreria para conectar php con mysql
package 'mysql' #Este el cliente de mysql

service 'httpd' do
 action [:enable, :start]
end

bash 'open port' do 
 code <<-EOH
 iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 8080 -j ACCEPT
 iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
 service iptables save
EOH
end

template 'var/www/html/index.php' do
 source 'index.php.erb'
 mode 0777
 variables(
 idServer: node[:web][:idServer],
 usuarioweb_web: node[:web][:usuarioweb_web],
 ip_web: node[:web][:ip_web],
 passwordweb_web: node[:web][:passwordweb_web]
 )
end

cookbook_file '/var/www/html/.htaccess' do
   source 'htaccess'
   mode 0777
end
