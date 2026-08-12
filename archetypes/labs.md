---
date: '{{ time.Format "2006-01-02" time.Now }}'
lastmod: '{{ time.Format "2006-01-02" time.Now }}'
draft: false
title: '{{ replace .File.ContentBaseName "-" " " | title }}'
summary: 'A page'
description: 'A page with information'
# params:
  # neighborhood:
  # address:
  # url:
  # testimonials:
    # - date:
        # content:
---