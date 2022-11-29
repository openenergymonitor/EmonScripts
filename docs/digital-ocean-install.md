# Installation on a DigitalOcean droplet

**Note:** For a single user with moderate use, a small VM on a cloud service is likely plenty of performance for an emoncms installation. For applications with a large number of users and feeds the performance of emoncms will depend a lot on how the cloud provider implements storage. Networked disk drives will result in slow performance due to the network latency associated with the way the emoncms feed engines are implemented. VM's on machines with local storage should provide much better performance.

1. Click on 'Create' to create a new cloud server
1. Select Ubuntu, standard $5/month, region e.g London then Create Droplet
1. DigitalOcean email root login details, ssh in using these credentials.
1. Change root password
1. Follow [Initial Server Setup with Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-18-04)

    ```shell
    adduser oem
    usermod -aG sudo oem
    ufw allow OpenSSH
    ufw enable
    ```

    logout of root and login with oem.

1. Disable root login:

    ```shell
    sudo nano /etc/ssh/sshd_config
    PermitRootLogin no
    sudo service ssh restart
    ```

1. Allow created user to run sudo without password.

    ```shell
    sudo visudo
    ```

    Add to end of visudo file:

    ```shell
    oem ALL=(ALL) NOPASSWD:ALL
    ```

    Save and exit.

1. Start the script

    ```shell
    wget https://raw.githubusercontent.com/openenergymonitor/EmonScripts/master/install/init.sh
    chmod +x init.sh
    ./init.sh
    ```

1. Modify config.ini for non emonSD installation.

    Disable emonhub installation

    ```shell
    install_emonhub=false
    ```

    Disable firmware, emonpilcd, emonsd, wifiap installation

    ```shell
    install_firmware=false
    install_emonpilcd=false
    install_emonsd=false
    install_wifiap=false
    Set user as applicable and set emonSD_pi_env=0
    ```

    ```shell
    user=oem
    hostname=emonpi
    emonSD_pi_env=0
    ```

    Comment out config, wifi and setup module:

    ```shell
    #emoncms_modules[config]=stable
    #emoncms_modules[wifi]=stable
    #emoncms_modules[setup]=stable
    ```

1. Run main installation script:

    ```shell
    ./main.sh
    ```

1. Allow access to port 80 in firewall:

    ```shell
    sudo ufw allow 80/tcp
    ```
