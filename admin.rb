dep 'admin-add' do
  requires 'admin-create', 'user-locale', 'user-ssh', 'user-rvm'
end

dep 'admin-create' do
  requires 'core:admin group', 'core:admins can sudo'
  met? {
    grep /^#{var :login}/, '/etc/passwd'
  }
  meet {
    sudo "useradd -m -s /bin/bash -g users -G admin #{var :login}"
    `sudo passwd #{var :login}`
  }
end

dep 'admin-delete' do
  met? {
      not grep /^#{var :login}/, '/etc/passwd'
    }
  meet {
    sudo "deluser #{var :login}"
  }
end

