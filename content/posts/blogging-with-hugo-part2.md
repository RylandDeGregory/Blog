---
title: "Blogging with Hugo and Azure Part 2"
author: "Ryland DeGregory"
authorlink: "/about/"
date: 2020-03-19T18:06:58-04:00
lastmod: 2020-05-07T12:20:00-04:00
draft: false
categories:
- Azure
- Blog
---

When developing software, or creating a website, there are important metrics to consider when evaluating the success of the product. These include consistency and cadence of releases, number of failures per change, and overall availability.

<!--more-->

## CI/CD - What is it, and why does it matter?

Continuous Integration (CI) is the philosophy of automatically implementing new changes into your product. Each time you change something it's built into the existing code base and tested in a consistent, repeatable way to ensure that your changes can be successfully integrated into the product in its current state.
This is contradictory to traditional development where a feature or update is not integrated or tested in full until it's in the QA stage. With the adoption of CI tools and methodologies, its far easier to guarantee your changes will be successful because you can see what will happen as you develop, deploying often and failing often, until you have code that is worthy of promotion to a higher environment.

Continuous Delivery / Continuous Deployment (CD) is the philosophy of repeatable, traceable, scalable deployments that eliminate inconsistency between environments and tightly integrate approvals and testing with the software release process. CD tools can also automate release artifact creation, infrastructure-as-code provisioning, and concurrent multi-environment deployments.

CI/CD not only enables traceability, repeatability, and immutability to your software or website, it also frees you up to work on the things that really matter: adding functionality and creating content.

## Azure DevOps

[Azure DevOps](https://dev.azure.com/) is Microsoft's jack-of-all-trades platform for agile product management, git repo and software package hosting, and CI/CD pipelines. It's free to use with an Azure or GitHub Account, and integrates incredibly well with almost any modern IT tool.

[Git](https://git-scm.com/downloads) is the defacto source code management tool. The beauty of a static website is that it can be completely version controlled. Make sure you have Git installed on your workstation and have added it to your PATH variable. If you're using Visual Studio Code, it will have bothered you to install it during its first launch, so you may already have it installed.

### Organization and Project setup

After your account is set up to use Azure DevOps, create your organization and then project. This is pretty much click until you're done, but if you need more information, you can follow the [Microsoft documentation](https://docs.microsoft.com/en-us/azure/devops/user-guide/sign-up-invite-teammates?view=azure-devops).

### Git Repo setup

#### Initialize Git repository on Azure Repos

If you are going to use Azure Repos to host your git repository, you can import your repository from another git provider or perform the following commands to initialize and push a new repository containing your code to Azure Repos.

```Bash
cd /blog
git init
git add .
git commit -m "Initial commit"
```

Then, follow the instructions on the Azure Repos homepage to **Push an existing repository from the command line**.

![Azure Repos Empty](images/bloggingwithhugo2/repos-empty.png)

#### Import Repository from another Git hosting provider

Click the link on the Azure Repos homepage to **Import a repository**.

#### Use GitHub to host your Git repository

This is the method I will be using. Follow the [GitHub Guide](https://help.GitHub.com/en/GitHub/getting-started-with-GitHub/create-a-repo) to create a Git repository there.

### Azure Pipelines setup

Azure Pipelines are the most appealing part of Azure DevOps to me. They offer incredibly versatile CI (build) and CD (release) pipelines, and are now offering YAML based pipelines which introduce additional functionality and customizability (and traceability because your pipeline becomes a versioned file in your Git repository!).

I'll be showing off YAML pipelines in this post, as this is the clear direction from Microsoft regarding the future of Azure Pipelines. The graphical editors will still be there for now, but you should try to utilize the YAML pipeline functionality whenever possible!

I'd recommend reviewing the Azure Pipelines [YAML Schema](https://docs.microsoft.com/en-us/azure/devops/pipelines/yaml-schema?view=azure-devops&tabs=schema%2Cparameter-schema) before starting to get a general idea of how they're structured.

#### Create your first pipeline

To get started, go to the Pipelines page of Azure DevOps and **create a pipeline**.

![New Pipeline](images/bloggingwithhugo2/new-pipeline.png)

Select where your code lives. I chose **GitHub** because that's where my repository is hosted. If you set up your Git repo on Azure DevOps, select **Azure Repos Git**.

![Connect Pipeline to Repo](images/bloggingwithhugo2/pipelines-connect.png)

If you selected GitHub, you will need to authorize the connection between your Azure DevOps project and your GitHub account. After doing so, you will see a list of your account's repositories.

![GitHub Repos](images/bloggingwithhugo2/my-github-repos.png)

Choose to use a **Starter pipeline**, which will be configured for use with the software stack I've chosen.

![Starter YAML Pipeline](images/bloggingwithhugo2/starter-pipeline.png)

The starter pipeline shows the general file structure of a YAML pipeline, how to supply triggers, and how to select what agent pool you want to execute your pipeline. You can either use one of many [Microsoft hosted agent](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/hosted?view=azure-devops) types, or [install the agent](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/hosted?view=azure-devops) on your own server(s) and use them as members of the pool.

Expanding the **Assistant** pane on the right side of the screen, the wide variety of built-in pipeline tasks is visible. Building images, working with docker, deploying and managing Azure resources, application publishing, and testing tasks are all available.

![Azure Pipelines Tasks](images/bloggingwithhugo2/pipeline-tasks.png "Some of the many pipeline tasks")

If it all seems a bit overwhelming, don't worry! Deploying Hugo to Azure Storage is incredibly simple, and won't even scratch the surface of capabilities that Azure Pipelines have to offer, but being able to leverage them in any capacity will expose you to the wide world of CI/CD, and hopefully spark an interest to go further with them.

#### My pipeline for deploying Hugo to Azure storage

Let's break down each step of the process:

- `trigger` is the way CI is initiated for this pipeline -- how it's launched. I am triggering my CI build any time a push is made to the master branch of my Git repo. This means any time that I push new commits to GitHub, GitHub sends an event to a webhook listener on Azure DevOps that starts the pipeline.

```YAML
trigger:
- master
```

- `pool` is the type of Microsoft hosted agent that will be running the pipeline. If you're using your own agent(s), remove the `vmImage` attribute and specify the name of the pool after `pool:`.

```YAML
pool:
  vmImage: "ubuntu-latest"
```

- `variables` are exactly what they sound like. They can be specified either in the YAML file directly like this or in the **variables** area of the pipeline editor.

```YAML
variables:
  hugo.version: '0.68.0'
```

> Note: All of the tasks I use in this pipeline are single line scripts. Know that you can combine them all into a single multi-line script task, but I found it easier for debugging and auditing if I used a separate task for each command.

- `steps` are the smallest unit of execution for a pipeline. Azure Pipelines follow a "stages -> jobs -> steps -> scripts/tasks" hierarchy, but for a simple pipeline like this, only one stage and one job are needed, meaning they can be omitted from the YAML file.
  - The first step is a **script** task that uses `wget` to download the Hugo executable from GitHub. Note the use of the variable in the URL, so the correct version of Hugo is always downloaded.
  - The second step is a **script** task that installs the debian package downloaded from GitHub.
  - The third step is invoking the Hugo executable. From the root directory of the Git repository (which is cloned each time the pipeline is launched), running the Hugo executable will generate the website's HTML/CSS/JS from the Markdown content files.
    - I have logging and verbose building turned on so I can review them if necessary in the pipeline build logs.
  - The fourth step is the Hugo secret sauce (in my opinion). It provides an out-of-the-box integration to deploy a Hugo static site to Azure Storage. It's called [Hugo Deploy](https://gohugo.io/hosting-and-deployment/hugo-deploy/#azure-storage) and it trivializes the historically-complicated process of deploying a website to a hosting service.

My `azure-pipelines.yml` file is below. You can also find it on [GitHub](https://GitHub.com/RylandDeGregory/blog/blob/master/azure-pipelines.yml)

```YAML
# Pipeline for deploying a Hugo static website to Azure Blob Storage.
# Uses Azure Hosted agents.
# AZURE_STORAGE_ACCOUNT and AZURE_STORAGE_KEY must be defined as pipeline variables.

trigger:
- master

pool:
  vmImage: "ubuntu-latest"

variables:
  hugo.version: '0.68.0'

steps:
- script: 'wget -c https://GitHub.com/gohugoio/hugo/releases/download/v$(hugo.version)/hugo_$(hugo.version)_Linux-64bit.deb'
  displayName: "Download Hugo"

- script: 'sudo dpkg -i hugo_$(hugo.version)_Linux-64bit.deb'
  displayName: "Install Hugo"

- script: 'hugo --log -v'
  displayName: 'Generate Blog'

- script: 'hugo deploy --maxDeletes -1'
  env:
    AZURE_STORAGE_KEY: $(AZURE_STORAGE_KEY)
    AZURE_STORAGE_ACCOUNT: $(AZURE_STORAGE_ACCOUNT)
  displayName: 'Deploy Blog'
```

![Complete Pipeline](images/bloggingwithhugo2/pipelines-complete.png)

#### Hugo Deploy

To configure [Hugo Deploy](https://gohugo.io/hosting-and-deployment/hugo-deploy/#azure-storage), edit the website's configuration file, `config.toml`. Create a [deployment] field, and set the configuration properties to deploy to Azure Storage.
The important part is the `deployment target`, which specifies the container where the website is going to be hosted. Leaving the default of `$web` is correct, as this is what I set up when creating the Storage Account.

```TOML
[deployment]
  [[deployment.targets]]
    name = "azure blob storage"
    URL  = "azblob://$web"

  [[deployment.matchers]]
    pattern = "^.+\\.(png|jpg)$"
    cacheControl = "max-age=31536000, no-transform, public"
    gzip = false

  [[deployment.matchers]]
    pattern = "^.+\\.(html|xml|json)$"
    gzip = true
```

In order to deploy to Azure Storage, a couple environment variables need to be set in the pipeline so the Hugo executable knows where to send the files. They are `AZURE_STORAGE_ACCOUNT` and `AZURE_STORAGE_KEY` (`AZURE_STORAGE_SAS_TOKEN` can also be used in place of `AZURE_STORAGE_KEY` to limit access to only the specific container where the website will be deployed).

{{% admonition type=warning title="Warning" open=true %}}
It is absolutely imperative that the key/token are not disclosed, hard-coded, or shared anywhere on the Internet. They **MUST** remain secret. Please don't be *that* person who commits secrets to their Git repository. :smiley:
{{% /admonition %}}

#### Azure Pipelines secret variables

For the purposes of this simple blog, I'll be storing my secret values in Azure Pipelines variables. Click the **Variables** button to view and edit them.
Note that they live outside your repo, so if they are changed or deleted, or if the pipeline is deleted, they will be lost.

![Pipeline Variables](images/bloggingwithhugo2/pipelines-variables-button.png)

![My Pipeline Secret Variables](images/bloggingwithhugo2/pipelines-my-variables.png)

#### Azure Key Vault - a true secrets store

The correct place to store these values is a true secrets store like [Azure Key Vault](https://azure.microsoft.com/en-us/services/key-vault/), which has a nice [Azure Pipelines Task](https://azuredevopslabs.com/labs/vstsextend/azurekeyvault/), but is a lot of additional overhead to store on URL and one Key. If your site or application is consistently using RSA Keys, secret values, and Certificates, look into Azure Key Vault. It's essentially free and fully hosted, so there's no infrastructure to maintain or monitor.

#### Run the Pipeline

To run the pipeline, you have multiple options. A trigger for master is configured in the YAML syntax, so each time a commit is pushed to the remote copy of the master branch, the pipeline will run. The pipeline can also be triggered manually from the Azure DevOps portal, or set to run on a schedule.

View the triggers for the pipeline by clicking on the ellipses menu next to **Variables**. Ensure that **Continuous integration** is enabled.

![Pipeline Triggers](images/bloggingwithhugo2/pipelines-triggers.png)

![My Pipeline Triggers](images/bloggingwithhugo2/pipelines-my-triggers.png)

Save and run your pipeline! When the pipeline is launched, it opens the **Pipeline run** screen.

![Pipeline Queued](images/bloggingwithhugo2/pipelines-queued.png)

Each **job** can be clicked into to view logs.

![Pipelines job](images/bloggingwithhugo2/pipelines-job.png)

If it completed successfully, you should now see your updated blog!

> Note: It will take hours for all CDN endpoints to purge and update their cached content. Go to the Blob Storage Static Website endpoint URL (rather than the custom domain) to view the updated content almost immediately.

## Final Thoughts

Thanks for reading! I hope you get as much enjoyment out of your new, cheap, beautiful blog as I do from mine. And I sincerely hope that you learned something new and interesting, something that you will find useful for your own career and personal projects!
