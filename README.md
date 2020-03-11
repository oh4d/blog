# Efrat Levitan's Github Pages

This site is developed with Jekyll, a static site generator and hosted by Github pages. 
All contents of the site are registered in [Github public repository](https://github.com/yumaloop/yumaloop.github.io) and you can browse any source code in it.

## Run locally

```bash
docker run -it --rm -v "$PWD":/usr/src/app -p "4000:4000" starefossen/github-pages sh -c "bundle && jekyll serve -d /_site --watch --force_polling -H 0.0.0.0 -P 4000"
```