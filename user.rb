dep 'user-locale' do
  profile = "/home/#{var :login}/.profile"
  met? {
    grep /^LC_ALL/, profile
  }
  meet {
    append_to_file 'LC_ALL=en_US.UTF-8', profile
  }
end

dep 'user-rvm' do
  profile = "/home/#{var :login}/.profile"
  rvm = '[[ -s "/usr/local/lib/rvm" ]] && . "/usr/local/lib/rvm"  # This loads RVM into a shell session.'
  met? {
    grep('/usr/local/lib/rvm', profile)
  }
  meet {
    append_to_file rvm, profile
    sudo "usermod -a -G rvm #{var :login}"
  }
end

dep 'user-ssh' do
  home = "/home/#{var :login}"
  met? {
    check_file "#{home}/.ssh/authorized_keys", :exist?
  }
  meet {
    sudo "mkdir #{home}/.ssh", :as => var(:login)
    sudo "echo \"#{var :ssh_key}\" > #{home}/.ssh/authorized_keys", :as => var(:login)
  }
end
