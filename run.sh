#!/bin/bash
git pull origin master
typst compile --font-path resume/ resume/main.typ static/resume/Resume.pdf
# zola build --output-dir /var/www/licu.dev/public --force
cp static/resume/Resume.pdf /var/www/licu.dev/public/Resume.pdf
