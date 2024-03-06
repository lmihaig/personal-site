+++
title = "On how this site was built"
description = "Detailed process of how the infrastructure for this site was built"
date = 2024-02-22
[taxonomies]
tags = ["tech"]
[extra]
toc = true
+++

## Intentions

I decided on building this website with a key principle in mind: simplicity. I wanted a platform that was easy to manage and expand upon in the future. My initial requirements focused on:

- **Single configuration file for infrastructure** - I'm already forgetful enough, so I wanted a single configuration file encompassing the entire infrastructure, eliminating the need to navigate through scattered files for minor adjustments.
- **Hands off CI/CD** - Ideally, adding new services would trigger an automated update and deployment process, minimizing manual intervention.
- **Streamlined/Automated cert renewal** - no longer worrying about forgetting to renew certificates

And specifically for the resume I wanted:

- **Separation of information and presentation** - To maintain flexibility and ease of updating, I prioritized a clear distinction between the content of my resume and its visual presentation.

## Hosting

As a broke university student I don't like paying for hosting, or paying for electricity to host on my own. Therefore, I opted for the best completely free service which absolutely is [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/) and their always free tier deal where you get 2x AMD, 4x ARM Ampere A1 and 24GB RAM to allocate to VMs as you see fit. I already had an account made in the UK Region but as it seems I couldn't manage to spawn any instance as there is a huge shortage at the moment, most likely all the people eager to host Minecraft servers.

So, to cut the story short I had to make a script which I ran for a couple of days to spawn a single core AMD instance which I then used to run the same script this time trying to spawn a 4x ARM VM. After a whole two weeks I had no luck and I started looking into alternatives. Turns out if you add in a credit card and upgrade to their _pay as you go_ plan you have priority to these free resources, and, most importantly, they are still free. After a few more problems with them declining all my credit and debit cards from multiple different banks I had a long chain of emails with their support, finally got my account upgraded to pay as you go, and managed to get an ARM instance.

## Static Site Generator

Looked around a bit and I decided to go with [Zola](https://www.getzola.org/) to generate static pages from markdown as it seems to be very well liked by the community and as a bonus it's also written in Rust which resonated with my preferences. For the themes I really liked [Duckqill](https://codeberg.org/daudix/duckquill) and I just changed a few settings around.

After configuring things and making slight changes to how it looks I now can just run `zola build --output-dir /var/www/licu.dev/public --force` to have my site's new version built.

## Resume

My biggest problem with regularly updating my resume is that I always have to shift things around to have it fit on a single page, and when I decide to try a new look I have to make changes in multiple places. Another problem is up until now I was not using any sort of version control. I know I could do all these things with LaTeX but honestly I was never a big fan of it and instead I took this opportunity to use [Typst](https://typst.app/).
I wanted to use a standard for the data layer and [jsonresume](https://jsonresume.org/) seems to be the only somewhat used one. I really tried to use it but unfortunately it does not provide all the sections that I consider important and neither the exact format I saw to make logical sense for me, so I just drew inspiration from it. For extra readability I also chose to keep my data in YAML format.

I included the command to compile the .typ files to PDF (so I can display them on my site as an iframe) to a script alongside the zola build command `typst compile --font-path resume/ resume/main.typ static/resume/Resume.pdf`

## Web server

While I had experience with Nginx, I opted for Caddy for this project due to its ease of use and automated certificate management. Nginx, while powerful, requires separate configuration for features like Let's Encrypt integration, which I find cumbersome. Caddy streamlines this process by handling it automatically, saving me time and effort.
I also had a weird preference where I wanted specific paths of the website to be represented by a personal subdomain such as `blog.licu.dev` instead of `licu.dev/blog`. Turns out this was not that hard to configure. In my Caddyfile, I've defined separate sections for `licu.dev`, `*.licu.dev` (wildcard for all subdomains), and individual subdomains like `blog.licu.dev` and `resume.licu.dev`.
At the moment this is the whole Caddyfile which is incredibly short and easy to read and modify.

```caddy
{
    email licu.mihai21@gmail.com
    acme_dns  cloudflare {env.CLOUDFLARE_API_TOKEN}
}

(default) {
  header X-Clacks-Overhead "GNU Terry Pratchett"
  encode zstd gzip
}


www.licu.dev {
    redir https://licu.dev{uri} permanent
}

*.licu.dev, licu.dev {
    import default

    root * /var/www/licu.dev/public

    handle_path /blog* {
        redir * https://blog.licu.dev{uri} permanent
    }

    handle_path /resume* {
        redir * https://resume.licu.dev{uri} permanent
    }

    file_server
}


blog.licu.dev {
    root * /var/www/licu.dev/public/blog

    file_server
}

resume.licu.dev {
    root * /var/www/licu.dev/public/resume

    file_server
}
```

## Dockerization

While I considered using Docker Swarm or Kubernetes for better orchestration, I opted for a simpler approach using Docker Compose. I created Dockerfiles for the services and hosted them on GitHub Container Registry (GHCR). I then used a Watchtower container to periodically check and apply updates. For services functioning as "jobs" (like building the new site version), I made them sleep indefinitely to prevent Watchtower from attempting to update or start non-running containers.

Here's the GitHub Actions CI/CD workflow I use for the personal-site:

```yml
name: Create and publish a Docker image

on: push

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}
  DOCKER_TARGET_PLATFORM: linux/arm64/v8

jobs:
  build-and-push-image:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Log in to the Container registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Extract metadata (tags, labels) for Docker
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=raw,value=latest,enable={{is_default_branch}}
            type=sha

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          platforms: linux/arm64
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          provenance: false
```

And the docker-compose file that ties everything together:

```yml
version: "3"
services:
  watchtower:
    image: containrrr/watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /root/.docker/config.json:/config.json
    command: --interval 60 --cleanup

  caddy:
    image: iarekylew00t/caddy-cloudflare:latest
    environment:
      CLOUDFLARE_API_TOKEN: ${CLOUDFLARE_API_TOKEN}
    restart: unless-stopped
    ports:
      - 80:80
      - 443:443
    volumes:
      - ./data/caddy/Caddyfile:/etc/caddy/Caddyfile
      # - ./data/caddy/caddy_data:/data
      # - ./data/caddy/caddy_config:/config
      - ./data/personal-site/var/www:/var/www/licu.dev:ro

  mongo:
    image: mongo:latest
    restart: unless-stopped
    volumes:
      - ./data/mongo/db:/data/db

  personal-site:
    image: ghcr.io/lmihaig/personal-site:latest
    volumes:
      - ./data/personal-site/var/www:/var/www/licu.dev
```

All the code for the infrastructure can be found [here](https://github.com/lmihaig/licu.dev) and the code for the blog + resume part of the site is [here](https://github.com/lmihaig/personal-site)
