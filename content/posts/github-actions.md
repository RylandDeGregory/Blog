---
title: "Setting up Github Actions"
author: "Ryland DeGregory"
authorlink: "/about/"
date: 2020-05-06T17:10:04-04:00
draft: false
categories:
- Blog
- GitHub
- Azure
---

Everyone in the software & IT industry knows GitHub, home to "the world's largest community of developers".

<!--more-->

## GitHub Actions -- the new CI/CD on the block

![Azure Repos Empty](images/github-actions/github-actions-slide.png)

GitHub is THE place for hosting your personal Git repository, or to contribute to your favorite open-source project.
For years, you've been able to commit code, manage pull requests, and track bugs using the GitHub platform. Recently they added [GitHub Projects](https://github.com/features/project-management) for basic agile work management. Even more recently, GitHub decided to take on some major industry players by launching their own CI/CD (Build/Release) platform, [GitHub Actions](https://github.com/features/actions).

GitHub Actions directly competes with Jenkins, CircleCI, TravisCI, GitLab CI, etc. This means that in launching this product, GitHub must have felt that they could deliver enough innovation to not only bolster their existing product stack, but to outshine competitors with years of development and thousands of customers. One of these direct competitors is even another Microsoft product, Azure Pipelines.

## GitHub vs Azure DevOps

I've been a huge fan of [Azure Pipelines](https://azure.microsoft.com/en-us/services/devops/pipelines/) for a while now. I've used them extensively to create multi-stage builds and deployments at my employer and in [managing the release lifecycle of this blog](/posts/blogging-with-hugo-02), and I find it to be one of the strongest CI/CD tools in the current market. Azure DevOps also provides best-in-class agile work management, Artifact storage, and integrated Test Plans. GitHub offers none of this, and Azure DevOps offers seamless integration with any GitHub resources. So, why would Microsoft try to directly compete with Azure DevOps when releasing new features to GitHub? Visibility and user base.

GitHub has over 40 million users and 100 million repositories, and those numbers don't lie. People like the GitHub platform, and want to use it wherever they can. This is why nearly every software development tool has a first-party GitHub integration. Despite all the competition, people stick with it. Microsoft saw this as an opportunity, as Azure DevOps (a re-branding of Team Foundation Services) is still used by mostly Windows developers, to get GitHub users off of tools like CircleCI, TravisCI, and Jenkins, onto a Microsoft CI/CD platform of one type or another. They decided that rather than pushing users to Azure DevOps CI/CD, they'd instead bring it to the users natively within GitHub.

Although Microsoft may be trying to eventually supplant Azure Pipelines with GitHub Actions, they have a LONG way to go before a fair comparison can even be made.

## Migrating to GitHub Actions

![Azure Pipelines to GitHub Actions](images/github-actions/pipelines-actions-migration.png)

When I heard that my employer might be considering migrating our enterprise platform from Azure DevOps to GitHub, I naturally wanted to look into GitHub Actions to see if there was any chance of converting our Pipelines. So, I started with the easiest pipeline I know, the Hugo deploy pipeline for this blog.

### Syntax considerations

Unsurprisingly, GitHub Actions workflows are written in YAML (like almost every other modern config tool). They follow a similar structure to Azure Pipelines YAML files, but the way variables get handled is a little different. All pipeline elements, attributes, artifacts, variables, loops, etc. are referenced as [contexts and expressions](https://help.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions) that you have to reference as elements of an object. Contexts include `env` (stores environment variables set in the pipeline), `secrets` (contains the values defined in the secrets area of **Project Settings**), and `job` (contains the status of the currently-executing job). Expressions include conditionals, loops, and [strategies](https://help.github.com/en/actions/reference/workflow-syntax-for-github-actions#jobsjob_idstrategy).

{{% admonition type=tip title="Tip" open=false %}}
You can learn more about the GitHub Actions Workflow Syntax in its [documentation](https://help.github.com/en/actions/reference/workflow-syntax-for-github-actions#about-yaml-syntax-for-workflows).
{{% /admonition %}}

In my previous post, [Blogging with Hugo and Azure Part 2](posts/blogging-with-hugo-02), I created a simple YAML pipeline for building and deploying this blog to Azure Storage. It's shown below.

{{< gist RylandDeGregory b2106fc30785d0d24a078c86a7e3f2e0 >}}

After about an hour of work (and lots of failed builds), I was able to successfully convert my pipeline to GitHub Actions. The most confusing part was trying to find the syntax for variable expansion! The strange, jinja/bash hybrid notation really threw me off, and was in none of the dozen or so combinations I tried before learning about contexts and the syntax to access them. My new pipeline is below.

{{< gist RylandDeGregory 9d23d7d258ca677fb3a916f5e0398347 >}}

### Overall experience

Using GitHub Actions has been -- I'll admit -- a little rough around the edges, even for a pipeline as simple as this. The actions marketplace is ever-growing, and with the kind of support and innovation that GitHub drives I know it will soon be a mature-enough product to compete with heavy-hitters like Azure Pipelines, but for now it's just too fresh and foreign. Getting a cloud build agent has been inconsistent. Sometimes my build starts in 15 seconds, sometimes not for 3 minutes. You can't remove failed builds from the list, creating a cluttered mess while you learn the syntax and environment.

### A bright future

The more I use it though, the more I'm beginning to enjoy the simplicity of managing my repo, PR's, and pipelines all on GitHub. I'm curious to see what the future holds for both GitHub Actions and Azure Pipelines, as I'm sure that Microsoft won't keep both around forever. My bets are with GitHub, as the integration and name recognition is something that not even Microsoft can ignore.

I can't say that Microsoft will one day kill off Azure DevOps. But if they do, I sincerely hope they will integrate the enterprise work-management functionality, test-plans, and seamless cross-service functionality that makes Microsoft products so enjoyable to use together.

What I can say is that I've deleted the Azure DevOps project for this blog, and will be focusing on using it to try out the new functionality of GitHub whenever it becomes available. But, I won't be migrating the complex, multi-stage pipelines that my team rely on just yet...GitHub Actions has some maturing to do before it's ready for primetime.

![Microsoft octocat](images/github-actions/microsoft-octocat.jpg)
