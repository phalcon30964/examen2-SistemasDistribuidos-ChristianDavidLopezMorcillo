bash 'open port' do
   code <<-EOH
   iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 8080 -j ACCEPT
   iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
   service iptables save
   EOH
end

cookbook_file '/etc/yum.repos.d/nginx.repo' do
   source 'nginx.repo'
   mode 0777
end

package 'nginx'

template '/etc/nginx/nginx.conf' do
   source 'cofig_nginx.erb'
   mode 0777
   variables(
      ipweb1: node[:nginx][:ipweb1],
      ipweb2: node[:nginx][:ipweb2],
      puerto_nginx: node[:nginx][:puerto_nginx]
   )
end

service 'nginx' do
   action [:enable, :start]
end
