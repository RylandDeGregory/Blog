---
title: "PowerShell and MP3 tagging"
author: "Ryland DeGregory"
authorlink: "/about/"
date: 2020-03-12T23:50:52-04:00
lastmod: 2020-05-06T10:00:00-04:00
draft: false
categories:
- PowerShell
---

I ran into an -- admittedly unique -- issue wherein I needed to tag hundreds of MP3 files with the proper Artist, Genre, Album, etc. Often, downloaded MP3 files will not have the tags populated. On Windows, you can edit tags manually using File Explorer, but on my MacBook Pro, I use a program like [Rekordbox](https://rekordbox.com/en/) to set MP3 tags.

<!--more-->
{{% admonition type=tip title="Tip" open=true %}}
If you just want the code, you can find it on [GitHub](https://github.com/RylandDeGregory/PSTagLib).
{{% /admonition %}}

## The problem

Cutting and pasting is fine for one or two songs, but when this is multiplied for a library of almost 1800, that method starts to break down. After doing around 50 by hand I stopped and thought, there has to be an easy way to automate this. I originally found the open-source [TagLib# library](https://github.com/mono/taglib-sharp), but most people have no experience compiling .NET programs from source. Enter [PowerShell](https://github.com/PowerShell/PowerShell).

## The solution

PowerShell is the quintessential automation tool. It's fast, powerful, and extensible enough to work in almost any situation. If you don't know anything about it, you should [start learning](https://github.com/PowerShell/PowerShell/tree/master/docs/learning-powershell) (MacOS and Linux users too). If you are a MacOS user, you will have to install [PowerShell Core](https://github.com/PowerShell/PowerShell#get-powershell).

The real heavy hitter here is TagLib#, which I've included (compiled into a DLL) in the repo, but PowerShell is what enables it to shine for users of any skill.

### Installation

To start, download the tool from my [GitHub](https://github.com/RylandDeGregory/PSTagLib) repo. Then extract the .zip file to a folder.

### Running the tool

When you double-click to run `Set-Mp3Tags.ps1`, you will see a series of prompts asking you to select a directory to process. You can either select a directory by using a GUI file explorer or by providing a file system path. If the script doesn't open, or opens and immediately closes, see the [documentation](https://github.com/RylandDeGregory/PSTagLib/blob/master/README.md#script-wont-execute).

You are then asked if you would like to tag the files for genre. This was something I added for myself, as I like to DJ based on genre. Genre selection is based on the name of the folder which the files are in. So, a track in the "Trance" folder will have "Trance" as its genre tag.

For example, I have my music organized as follows (not all genres shown):

```text
Music
  ├───Bass
  ├───Hard
  ├───House
  ├───Prog
  ├───Techno
  └───Trance
```

### Results

(Hopefully) all of your files are now properly tagged! For the outliers, check the naming convention one more time.

## Considerations

Now, I'm not implying that you follow the same file naming convention that I use, or that you should! You can modify the delimiter to whatever you want. Simply open the script with any plain text editor (Notepad on Windows or TextEdit on MacOS), and change the value of the `$delimiter` variable at the top. For example, if your files were named "Artist_Title(Mix)", you would change the variable from its default value `' - '` to `'_'`.

## Thanks

Thanks to [illearth](https://github.com/illearth) on GitHub for providing the .dll file and a simple [module](https://github.com/illearth/powershell-taglib) for ad-hoc command use of the TagLib# library with PowerShell.
