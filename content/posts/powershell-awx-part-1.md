---
title: "Using PowerShell with Ansible AWX: Part 1"
date: 2020-12-05T19:00:00-05:00
draft: true
author: "Ryland DeGregory"
authorlink: "/about/"
categories:
- PowerShell
- Ansible
---

Now that PowerShell [runs on Mac and Linux](https://github.com/PowerShell/PowerShell), it's able to shine in many more use cases, including leveraging the power of the open source configuration management & automation platform [RedHat Ansible AWX](https://github.com/ansible/awx) to execute PowerShell 7 commands & scripts within Ansible Playbooks, directly on the Ansible control node.

<!--more-->

{{% admonition type=warning title="Before reading on" open=true %}}
The process and configuration outlined in this article (and subsequent articles in this series) is based on an extremely niche use case, and should be taken with a grain of salt. I am sharing my experience with this process because I have been extremely satisfied with the results over the last year.
{{% /admonition %}}

## Ansible AWX, Simple IT Automation

[Ansible](https://github.com/ansible/ansible) is incredible. Built on Python and expressed in YAML [Playbooks](https://docs.ansible.com/ansible/latest/user_guide/playbooks_intro.html), Ansible enables [idempotent](https://en.wikipedia.org/wiki/Idempotence) agentless configuration management over SSH/WinRM. AWX is a automation platform that enables scheduling, RBAC, logging, and workflow orchestration of Ansible Playbooks.

> This series of articles will not cover any information regarding how to use Ansible. For that, check out [Jeff Geerling's Ansible 101 series](https://www.jeffgeerling.com/blog/2020/ansible-101-jeff-geerling-youtube-streaming-series).

## Extending Ansible with scripting

Ansible, despite its massive library of modules, still falls short when performing complex logic, multidimensional loops, and data processing, areas that really require rich language syntax rather than its domain-specific language (DSL) expressed in YAML/jinja2. Additionally, especially for Windows systems, the module library often lacks the necessary functionality to perform all required management operations.

AWX is a crazy-powerful tool for what it is, especially for the price (Free Open Source Software!), but it really only shines within its intended wheelhouse of running Ansible Playbooks. However, the beauty of open source software is that you can customize it to suit your needs, and this allowed me to make AWX the perfect infrastructure automation platform for running scripts to manage both Windows and Linux hosts.

### Python vs PowerShell

Most people in this position would write custom Python scripts, extending the existing Python base of Ansible. That would serve their purposes excellently, and is the intended way of augmenting Ansible's functionality. See [Developing Ansible Modules](https://docs.ansible.com/ansible/latest/dev_guide/developing_modules_general.html). However, my strength lies in PowerShell, not Python (though I am trying to improve!). The vast majority of my infrastructure automation codebase already exists in PowerShell, so why not leverage the language I'm comfortable with? Enter PowerShell 7.

### What about a Windows Bridge Host?

Setting up a [Windows Host](https://docs.ansible.com/ansible/latest/user_guide/windows_setup.html) to run PowerShell scripts is something I've explored, and do utilize, for operations requiring Windows OS frameworks like interacting with System Center and Active Directory. However, utilizing and relying on an additional server is sub-optimal in my eyes, and I wanted to leverage all of the tools at my disposal to make the AWX control host as useful as possible.

## Adding PowerShell 7 to AWX

AWX is released as a [Docker image](https://hub.docker.com/r/ansible/awx), meaning that it can be customized to fit each user's needs. For this guide, we will be adding PowerShell 7, as well as authentication libraries to communicate with Windows systems using [PSRemoting](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_remote?view=powershell-7.1) with NTLM.

The quickest and easiest way of getting up and running is to utilize the Dockerfile below to create a custom AWX image with PowerShell 7. The `gssntlmssp` package is used to allow PowerShell to remotely-authenticate to Windows hosts using NTLM.

{{% admonition type=tip title="Note on PowerShell package version" open=false %}}
Though the `awx` Docker image is based on CentOS 8, I've found that the RHEL7 version of PowerShell is required to successfully utilize PSRemoting to connect to Windows hosts. The CentOS 8 version cannot successfully authenticate.
{{% /admonition %}}

{{< gist RylandDeGregory e27d3250798f9f1e0c077abbc2754a39 >}}

## Deploying AWX on Docker CE

There are multiple ways to [install AWX](https://github.com/ansible/awx/blob/devel/INSTALL.md), but I will be utilizing [docker-compose](https://docs.docker.com/compose/) to deploy AWX on a CentOS 8 Azure Virtual Machine running Docker CE.

### Connect to Virtual Machine

> I deployed my CentOS VM from the Azure Portal. For a step-by-step guide, see the [Microsoft Documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-portal).

The SSH private key (`.pem` file) is available for download when a VM is deployed using the Azure Portal.

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

1. Install the Docker CE engine and CLI.

    ```Shell
    sudo yum install docker-ce docker-ce-cli containerd.io
    ```

1. Start the Docker daemon and add it as a system startup program.

    ```Text
    sudo systemctl enable docker
    sudo systemctl start docker
    ```

1. Install Docker compose using Python pip

    ```Shell
    sudo pip3 install docker-compose
    ```

### Build custom AWX Docker image

{{% admonition type=warning title="Prerequisite" open=false %}}
You must have [Docker Desktop](https://www.docker.com/products/docker-desktop) installed, be remotely connected to a server that has Docker installed, or utilize a service that can build Docker images, such as Azure Pipelines or Github Actions. I will be using a CentOS 8 Azure Virtual Machine with Docker CE installed.
{{% /admonition %}}

#### Download AWX PowerShell Dockerfile

Download `awx_powershell.dockerfile` to your Docker image build environment from the Gist above.

```Shell
curl 'https://gist.githubusercontent.com/RylandDeGregory/e27d3250798f9f1e0c077abbc2754a39/raw' -o awx_powershell.dockerfile
```

#### Build AWX image using Docker CLI

Build the Docker image using `awx_powershell.dockerfile` and tag it with the version of AWX the image is based on (15.0.1 is the latest version at the creation time of this article).

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

1. Login to Docker Hub using the Docker CLI

    ```Shell
    sudo docker login
    ```

1. Push custom AWX image to Docker Hub.

    ```Shell
    sudo docker push <docker hub username>/awx:15.0.
    ```

### Install AWX

{{% admonition type=danger title="Caution: Not Production ready" open=false %}}
The following steps to install AWX are considered least-effort to get a working installation up and running. Please **DO NOT** utilize the following AWX configuration in a production environment. You must configure much greater control around application secrets and credentials, as well as infrastructure redundancy and database availability, before utilizing AWX in any capacity beyond Proof of Concept (PoC).
{{% /admonition %}}

1. Install Ansible using Python pip in order to run the AWX installer, which is an Ansible Playbook.

    ```Shell
    sudo pip3 install ansible
    ```

1. Create a directory to store AWX installation files.

    ```Shell
    sudo mkdir /opt/awx && cd /opt/awx
    ```

1. Download and extract the version of AWX you wish to install.

    ```Shell
    curl -LJO https://github.com/ansible/awx/archive/15.0.1.zip
    unzip awx-15.0.1.zip && cd awx-15.0.1
    ```

1. Edit the AWX installer `inventory` file for a customized install.
    1. `vi inventory` (use whatever text editor you are comfortable with).
    1. Update the `dockerhub_base` variable to the Docker Hub username hosting the custom AWX image.

        ```ini
        dockerhub_base=rylandcd
        ```

    1. Update the `pgdocker` and `awxcompose` variables to use the new `/opt/awx` directory for application files.

        ```ini
        postgres_data_dir="/opt/awx/pgdocker"
        docker_compose_dir="/opt/awx/awxcompose"
        ```

    1. Write the changes to the file and Quit vi by pressing `esc`, then typing `:wq!`.

1. Run the AWX installer using the `ansible-playbook` CLI tool.

    ```Shell
    sudo /usr/local/bin/ansible-playbook -i inventory install.yml
    ```

The Ansible Playbook `install.yml` will deploy AWX using the custom Docker image that includes PowerShell. Once complete, the output should look similar to the following screenshot. ![AWX installer output](images/powershell-awx/install-yml-output.png)

Once the containers are up and running, the AWX application will begin initializing the PostgreSQL database and configuring itself. You can track its progress by executing the following command to view the logs of the `awx_task` container.

```Shell
sudo docker logs -f awx_task
```

Once the AWX bootstrap and database initialization process is complete, you should see log entries similar to those in the following screenshot, indicating that AWX was installed successfully. ![awx_task bootstrap logs](images/powershell-awx/awx-task-logs.png)

In a web browser on your workstation, navigate to the IP address or hostname of the Virtual Machine hosting the AWX containers, and you should be able to log into the application using the default `admin` credentials:

```Text
Username: admin
Password: password
```

![AWX successful install](images/powershell-awx/awx-successful-install.png)

## Running PowerShell 7 scripts on AWX

See [part 2] of this 3 part series to learn how to execute PowerShell within Ansible Playbooks, run full PowerShell scripts from AWX, and see best practices for output and error handling.