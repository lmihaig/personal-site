#!/bin/bash
typst compile --font-path resume/ resume/main.typ static/resume/Resume.pdf
zola build --output-dir /var/www/licu.dev/public --force
sleep infinity