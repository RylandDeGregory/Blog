---
title: "Blogging with Hugo and Azure Part 1"
author: "Ryland DeGregory"
authorlink: "/about/"
date: 2020-03-13T06:18:52-04:00
lastmod: 2020-05-06T11:55:52-04:00
draft: false
categories:
- Azure
- Blog
---

I've been wanting to stand-up a personal blog for a while now, but never found a framework and hosting solution that excited me. I tried the age-old WordPress blog, but it felt so dated and bloated that I didn't enjoy using it for simple blogging.

<!--more-->

There was also the issue of hosting. Anywhere that can host WordPress needs to have robust compute infrastructure in the background somewhere (how else would you run all that PHP?), and with compute comes cost. I haven't found a WordPress hosting solution anywhere for less than $5-10 per month.

## Building a better, cheaper blog

### Static websites

As someone who has no web development experience, I recently learned about static site generators like [Hugo](https://goHugo.io/). Static sites are able to provide just the basics for blogging without needing database, server-side scripting, and compute infrastructure.

#### Backups and versioning with git

Because static websites are purely flat files, you can use a version-control system like git to backup and control your blog. You can even have multiple independent blogs in different branches of the same repository, and use pull requests to move features and content between them. This plus full accountability and tracking for all changes using git history.

#### CI/CD pipelines, automated deployment, release artifacting

As a DevOps engineer by trade, I love the idea of repeatable, commutable builds that run, look and feel the same anytime and anywhere. Because static site generators create static HTML files, you can run your blog through your pipeline tool of choice for integration testing, deployment to your hosting platform, promotion between environments, and packaging the whole site an archivable artifact. See [part 2](https://ryland.dev/posts/blogging-with-hugo-part2/) for more information on this.

---

## Why Hugo

Hugo is free, written in Go, and incredibly simple to use. It also consumes Markdown for its content pages, which I'm a huge fan of as I write in Markdown every day at work! In my exploring, I found other static site generators that provide similar functionality to Hugo, but none caught my eye the same way thanks to Hugo's massive library of beautiful community themes. Now that I've decided how to build my site, where to host it?

### Azure Blob Storage

While studying for the [Azure Administrator](https://docs.microsoft.com/en-us/learn/certifications/azure-administrator?wt.mc_id=learningredirect_certs-web-wwl) certification, I came across a feature of Azure Blob Storage called [static websites](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blob-static-website), which allows you to serve static and client-side script files in an Azure Storage Account blob container for just pennies per month.

I'm aware that Amazon S3 and Google Cloud Storage offer similar functionality, but my experience lies with Azure, so that's the route I decided to take.

---

## Azure Setup

Ok, so we've gotten the architecture flushed out, now for the implementation. The first thing you'll need (if you don't already have one), is an [Azure account](https://azure.microsoft.com/en-us/free/). You can sign up for free and get $200 of credit to mess around with any Azure service you want (I used mine to learn how to deploy applications to managed Kubernetes!). This whole blog will cost less than $3 per month for all Azure resources, so enjoy the free money for something else!

### Azure Storage

Storage Accounts are one of the foundational services of Azure. Blob storage, specifically, is just a giant (think petabytes) bucket to dump files into. It's about as simple as it gets. Go to the Azure Marketplace and create one!

I've set up my Storage Account to be hosted in the Azure region closest to me, and with the cheapest options. Don't worry about geo-replication, I've got a solution for that too: Azure CDN.

![Azure Storage Account Creation](images/bloggingwithhugo/storage-account-creation.png "Create Azure Storage Account")

### Azure CDN

Having a website in one region is great, but frequent requests from geographically-distributed locations can really kill the performance and user experience of a website. Additionally, Azure Blob Storage does not support SSL encryption for custom domains, and who wants an insecure blog?

Azure CDN solves both of these problems, again for only pennies per month. Go to the Azure Marketplace and create a CDN profile, being sure to select **Premium Verizon** (which supports custom rules for url rewrites and redirects).

![Azure CDN Profile Creation](images/bloggingwithhugo//cdn-profile.png "Create Azure CDN Profile")

### Connect Storage Account to CDN

Now is when the magic happens, linking the Azure Blob Storage endpoint to the CDN and enabling the static site.
In the Storage Account, under the Settings group, there is a blade called **Static website**. Once this is enabled, a container is created called `$web` which will be the root directory for the site. The endpoint to access the static site is shown, as well as fields to define the index and error documents for the site.

> NOTE: After spending hours troubleshooting an error in the connection between the Storage Account and CDN, I found you need to go to the `$web` container, click on **Change access level** and set it to *Blob (anonymous read access for blobs only)*.

![Change SA Access Level](images/bloggingwithhugo//change-access-level.png "Change container access level")

On the **Azure CDN** blade of the Storage Account, create a CDN endpoint using the new profile. In the **Origin hostname** field, enter the primary endpoint from the Static website blade. Remove the `https://` and the trailing `/`. The value should look like `{storage_account_name}.{zone}.web.core.windows.net`.

### Routing Rules on Azure CDN

This is a more advanced topic, and not necessary for the completion of this blog, so if you're interested, check out:

- [Http to Https redirection](https://docs.microsoft.com/en-us/azure/cdn/cdn-storage-custom-domain-https#http-to-https-redirection)
- [Azure Verizon Premium rules engine features](https://docs.microsoft.com/en-us/azure/cdn/cdn-verizon-premium-rules-engine-reference-features)

These are the rules I have configured:

#### URL Rewrites

![URL Rewrites](images/bloggingwithhugo//url-rewrites.png "URL Re-Writes")

#### Enforce HTTPS

![Enforce Https](images/bloggingwithhugo//enforce-https.png "Force HTTP to HTTPS")

#### Redirect Azureedge requests to custom domain

![Redirect Azureedge](images/bloggingwithhugo//redirect-azureedge.png "Redirect to custom domain")

### Custom domain on Azure CDN

A custom domain is your brand, your image in the eyes of others. If you don't have one, go get one! I have mine registered through Google domains. To add it as a custom domain on my Azure CDN endpoint, I need to create a DNS record with Google that points to my Azure CDN endpoint.
Create a CNAME record that points from the subdomain you want your website visible at to the CDN Endpoint. This blog is hosted at blog.rylanddegregory.com, so the values would be:

- **Name**: blog
- **Type**: CNAME
- **Data**: {cdn_endpoint}.azureedge.net.

Wait about a half hour for DNS to propagate, then go back to the Azure CDN endpoint and add the custom domain. If the check turns green, it means the DNS record has successfully propagated. If not, keep waiting or check with your domain registrar.

After the custom domain is added, [enable HTTPs for the CDN endpoint](https://docs.microsoft.com/en-us/azure/cdn/cdn-custom-ssl?tabs=option-1-default-enable-https-with-a-cdn-managed-certificate#ssl-certificates).

---

## Hugo Setup

Now that all the fun infrastructure part of this process is out of the way (seriously, for me that is the fun part!), it's time to actually build the static website with Hugo!

### Install Hugo

Install Hugo by following their [guide](https://gohugo.io/getting-started/installing/) for your operating system. I am using Windows so I will use the following command to install using Chocolatey.

`choco install Hugo -confirm`

### Create Site

Once installed, create a new site named **blog** using the Hugo executable.

`hugo new site blog`

This creates a new Hugo site in `./blog/` with the following directory structure.

```txt
blog
│   config.toml
├───archetypes/
│       default.md
├───content/
├───data/
├───layouts/
├───static/
└───themes/
```

### Make it pretty

Install a theme for Hugo from the [massive list](https://themes.goHugo.io) on their website! I am using the [LoveIt](https://hugoloveit.com/) theme, so I will navigate to the `themes/` folder and clone the theme's repo to a containing folder named LoveIt.

```Bash
git clone https://github.com/dillonzq/LoveIt.git themes/LoveIt
```

To use this theme, you need to include its custom configuration in your `config.toml` file. Because this is a new site, just remove the default file and replace it with the template file from the theme. Be sure to customize it how you want! View my edited file on this site's [Github repo](https://github.com/RylandDeGregory/blog).

### Post something

This website was made for blogging, right? Make a post!

```Bash
hugo new "posts/myfirstpost.md"
```

When the new file is created, Hugo places a header which contains metadata about the post.
I've added the `categories` taxonomy, but based on your theme of choice, there are [many different taxonomies](https://gohugo.io/content-management/taxonomies/) to organize posts with.

> Note: change the `draft` attribute from true to false if you want the post to be visible.

```YAML
---
title: "Blogging with Hugo and Azure"
date: 2020-03-12T21:18:52-04:00
draft: false
categories:
- Azure
---
```

When the post is finished, or just to see how it looks in real time, Hugo includes a [local server](https://gohugo.io/commands/hugo_server/) for previewing content. Running the following command will launch the static site at `localhost:1313`. Add `-D` to view draft posts.

```Bash
hugo server
hugo server -D #to view draft posts
```

---

## Deploy to Azure Storage

It's finally time. The infrastructure is set up, the content is written, now show this site to the world! Deploying the Hugo site is incredibly simple.

Executing the Hugo binary with no arguments builds the site, and exports it to the `/public` folder in the blog's root directory.

```Bash
cd blog
hugo
```

```Text
                   | EN
+------------------+----+
  Pages            |  4
  Paginator pages  |  0
  Non-page files   |  0
  Static files     |  0
  Processed images |  0
  Aliases          |  0
  Sitemaps         |  1
  Cleaned          |  0

Total in 23 ms
```

> Make sure to include `/public` in the Git repo's `.gitignore` file!

Use the Azure CLI to deploy the content to Azure Blob Storage

```Bash
az login
az account set --subscription ${SUBSCRIPTION_NAME}
az storage blob upload-batch --account-name ${STORAGE_ACCOUNT_NAME} --account-key ${STORAGE_ACCOUNT_KEY} --source public/ --destination $web
```

Go view the site at the custom domain attached to the Azure CDN endpoint!

## Next Steps

Check out [Part 2](https://ryland.dev/posts/blogging-with-hugo-part2/) to set up a CI/CD Pipeline on Azure Pipelines and configure monitoring for the static site.

Happy {cheap} blogging!
