---
title: "Using PowerShell with Ansible AWX: Part 1"
date: 2020-12-05T19:29:35-05:00
draft: true
author: "Ryland DeGregory"
authorlink: "/about/"
categories:
- PowerShell
- Ansible
- AWX
---

Now that PowerShell [runs on Mac and Linux](https://github.com/PowerShell/PowerShell), it's able to shine in many more use cases, including extending the power of the open-source configuration management & automation platform, [RedHat Ansible AWX](https://github.com/ansible/awx).

<!--more-->

{{% admonition type=warning title="Before reading on" open=true %}}
The process and configuration outlined in this post (and subsequent posts in this series) are based on an extremely niche and likely unsupported use case, and should be taken with a grain of salt. I am simply sharing my experience with this process, as I have been extremely satisfied with the results over the last year.
{{% /admonition %}}

## PowerShell, the open source way

If you haven't checked out PowerShell 7 yet, why?! It's faster, more secure, more dependable, and more powerful than ever and is now compatible with Windows, MacOS, and Linux platforms.

## Ansible AWX, Simple IT Automation

[Ansible](https://github.com/ansible/ansible) is incredible. Built on Python and expressed in YAML [Playbooks](https://docs.ansible.com/ansible/latest/user_guide/playbooks_intro.html), Ansible enables [idempotent](https://en.wikipedia.org/wiki/Idempotence) agentless configuration management over SSH/WinRM. AWX (short for Ansible-Worx), is a platform that enables scheduling, RBAC, logging, and workflow orchestration of Ansible Playbooks.

> This series of posts will not cover any information on how to use Ansible. For that, check out [Jeff Geerling's Ansible 101 series](https://www.jeffgeerling.com/blog/2020/ansible-101-jeff-geerling-youtube-streaming-series).

## Extending Ansible with scripting

AWX is a crazy-powerful tool for what it is, especially for the cost (Free Open Source Software!), but it really only shines within its intended wheelhouse of running Ansible Playbooks. And Ansible, despite its massive library of modules, still falls short when performing complex logic and data processing, areas that really require a proper programming language rather than its domain-specific language expressed in YAML/jinja2.

### Python vs PowerShell

Most people in this position would write custom Python scripts, extending the existing Python base of Ansible. That would serve their purposes excellently, and is the intended way of extending Ansible's functionality. See [Developing Ansible Modules](https://docs.ansible.com/ansible/latest/dev_guide/developing_modules_general.html). However, I am a PowerShell expert, not a Python expert. The vast majority of my infrastructure automation codebase already exists in PowerShell, so why not leverage the language I am comfortable with? Enter PowerShell 7.

### What about a Windows Bridge Host?

Setting up a [Windows Host](https://docs.ansible.com/ansible/latest/user_guide/windows_setup.html) to run PowerShell scripts is something I've explored, and do utilize, for activities such as interacting with System Center and Active Directory. However, utilizing and relying on an additional, outside server is less-than-ideal in my eyes, and so I wanted to leverage all of the tools at my disposal to make the AWX control host as powerful as possible.

## Adding PowerShell 7 to AWX

AWX is released as a [Docker container image](https://hub.docker.com/r/ansible/awx) based on CentOS 8, meaning that it can be customized to fit each user's needs. For this guide, we will be adding PowerShell 7, as well as the dependent libraries to communicate with Windows systems using [PSRemoting](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_remote?view=powershell-7.1).

### Custom AWX dockerfile

The quickest and easiest way of getting up and running is to utilize the dockerfile shown below to create a custom AWX image with PowerShell 7. The `gssntlmssp` package is used to allow PowerShell to remotely-authenticate against Windows hosts using NTLM.

{{% admonition type=tip title="Note on PowerShell package version" open=false %}}
Though the `awx` container image is based on CentOS 8, I've found that the RHEL7 version of PowerShell is required to successfully utilize PSRemoting to connect to Windows hosts. The CentOS 8 version cannot successfully authenticate.
{{% /admonition %}}

{{< gist RylandDeGregory e27d3250798f9f1e0c077abbc2754a39 >}}

## Deploying AWX

There are multiple ways to [install AWX](https://github.com/ansible/awx/blob/devel/INSTALL.md), but I will be utilizing the `docker-compose` method to deploy AWX on a CentOS 8 Azure Virtual Machine.

### Connect to Virtual Machine

> I deployed my VM from the Azure Portal. For a step-by-step guide, see the [Microsoft Documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-portal).

The private key (`.pem` file) is available for download when a VM is deployed using the Azure Portal.

```Shell
ssh -i <private key path> <user>@<virtual machine>
```

{{% admonition type=example title="Example" open=false %}}

```Shell
ssh -i ~/.ssh/awx_powershell.pem azureuser@10.0.0.1
```

{{% /admonition %}}

### Install Docker

> The steps below are based on the official [Docker Documentation](https://docs.docker.com/engine/install/centos/) for installing Docker on CentOS.

1. Add the Docker CE repo to the Virtual Machine's package manager configuration.

    ```Shell
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    ```

1. Install the Docker daemon and CLI.

    ```Shell
    sudo yum install docker-ce docker-ce-cli containerd.io
    ```

1. Start the Docker daemon and add it as a system startup program.

    ```Text
    sudo systemctl enable docker
    sudo systemctl start docker
    ```

1. Install Docker compose

    ```Shell
    sudo pip3 install docker-compose
    ```

### Build custom AWX Docker image

{{% admonition type=warning title="Prerequisite" open=false %}}
You must have [Docker Desktop](https://www.docker.com/products/docker-desktop) installed, be remotely connected to a server that has Docker installed, or utilize a service that can build Docker images (such as Azure Pipelines or Github Actions). I will be using a CentOS 8 Azure Virtual Machine with Docker installed for part 1 of this series.
{{% /admonition %}}

#### Download AWX PowerShell Dockerfile

Download `awx_powershell.dockerfile` to Docker build environment from the Gist linked above.

```Shell
curl 'https://gist.githubusercontent.com/RylandDeGregory/e27d3250798f9f1e0c077abbc2754a39/raw' -o awx_powershell.dockerfile
```

#### Build container image using Docker CLI

Build the Docker image using the `dockerfile` based on the version of AWX you wish to install (15.0.1 is the latest version when this post was created).

```Shell
sudo docker build -f awx_powershell.dockerfile -t <docker hub username>/awx:<awx_version> .
```

{{% admonition type=example title="Example" open=false %}}

```Shell
sudo docker build -f awx_powershell.dockerfile -t rylandcd/awx:15.0.1 .
```

{{% /admonition %}}

### Push custom AWX Docker image to Container Registry

Push the image to a Docker Container Registry such as [Docker Hub](https://docs.docker.com/engine/reference/commandline/push/) or [Azure Container Registry](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-docker-cli). I will be using Docker Hub.

1. Login to Docker Hub.

    ```Shell
    sudo docker login
    ```

1. Push custom Docker image to Docker Hub.

    ```Shell
    sudo docker push <docker hub username>/awx:15.0.
    ```

### Install AWX

{{% admonition type=danger title="Caution: Not Production ready" open=false %}}
The following steps to install AWX are considered least-effort to get a working installation up and running. Please **DO NOT** utilize the following AWX application configuration in a production environment. You must configure much greater control around application secrets and infrastructure hardening.
{{% /admonition %}}

1. Install Ansible in order to run the AWX installer (an Ansible Playbook).

    ```Shell
    sudo pip3 install ansible
    ```

1. Create a directory to store AWX installation files.

    ```Shell
    sudo mkdir /opt/awx && cd /opt/awx
    ```

1. Download and extract the version of AWX you wish to install (15.0.1 is the latest version when this post was created).

    ```Shell
    curl -LJO https://github.com/ansible/awx/archive/15.0.1.zip
    unzip awx-15.0.1.zip && cd awx-15.0.1
    ```

1. Edit the AWX installer `inventory` file.
    1. `vi inventory`
    1. Update the `dockerhub_base` variable to point to the custom container image.

        ```ini
        dockerhub_base=<docker hub username>
        ```

    1. Update the `pgdocker` and `awxcompose` variables to point to the new `/opt/awx` directory.

        ```ini
        postgres_data_dir="/opt/awx/pgdocker"
        docker_compose_dir="/opt/awx/awxcompose"
        ```

    1. Write the file and Quit vi by pressing `esc`, then `:wq!`.

1. Launch the AWX installer

    ```Shell
    sudo /usr/local/bin/ansible-playbook -i inventory install.yml
    ```

The Ansible Playbook `install.yml` will deploy AWX using the custom Docker container images that include PowerShell. Once complete, the output should look similar to the following screenshot. ![AWX installer output](images/powershell-awx/install-yml-output.png)

Once the containers are up and running, the AWX application will begin configuring itself. You can track its progress by executing the following command to view the logs of the `awx_task` container.

```Shell
sudo docker logs -f awx_task
```

Once the AWX bootstrap and database initialization is complete, you should see log entries similar to the following, indicating that that AWX was installed correctly. ![awx_task bootstrap logs](images/powershell-awx/awx-task-logs.png)

In a web browser on your workstation, navigate to the IP address or hostname of the Virtual Machine hosting AWX, and you should be able to log into the application using the default `admin` credentials:

```Text
Username: admin
Password: password
```

![AWX successful install](images/powershell-awx/awx-successful-install.png)
