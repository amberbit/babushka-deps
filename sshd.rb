dep "sshd-disable_password" do
  config = '/etc/ssh/sshd_config'
  met? {
    grep /^PasswordAuthentication no/, config
  }
  meet {
    change_line "#PasswordAuthentication yes", "PasswordAuthentication no", config
  }
  after {
    sudo "/etc/init.d/ssh restart"
    # remove root's password
    sudo "passwd -l root"
  }
end

