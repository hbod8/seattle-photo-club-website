---
date: '{{ time.Format "2006-01-02" time.Now }}'
draft: true
title: '{{ replace .File.ContentBaseName "-" " " | title }}'
summary: 'A page'
description: 'A page with information'
tags:
# - foo
menus:
  - main
---