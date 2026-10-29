# Project binary cache

The substituter is https://randymarsh77.github.io/nix, with `cache.nixos.org` as
upstream. `public-key` is shared by Nix configuration and the CI installation
action. Its private counterpart is the repository secret `NIX_CACHE_SIGNING_KEY`.
The ephemeral `GITHUB_TOKEN` authorizes Release uploads; no Cachix token is needed.

The static-nix-cache actions and Pages generator are pinned to one commit.
Update all pins together after testing a new cache implementation.

Trusted master builds and repository-dispatch builds upload compressed NARs
directly to GitHub Releases, without storing closures in Actions artifacts.
Only dispatch flakes from trusted sources. Release shards start with `nix-cache`
and roll over at 900 assets; uploaded paths already on cache.nixos.org are skipped.
Both publisher workflows share `nix-cache-publisher` concurrency and serialize
matrix uploads. Do not add another writer outside this concurrency group.
PR builds receive read-only permissions and no signing secret.

The Pages job reconstructs the complete metadata index after both architectures
finish, then publishes it once. GitHub Pages must use **GitHub Actions** as its
build source. Before merging, confirm the signing secret is present and the
static-nix-cache implementation commit is available on GitHub. The first master
run seeds the cache; until then clients fall back to cache.nixos.org/building.
Failed uploads leave the previous Pages deployment intact; a later successful
run reconstructs metadata including any completed uploads from the failed run.

Do not delete published Release assets or rotate the signing key in place.
For rotation, create a new release tag prefix and key, update the publisher and
index generator together, and retain both public keys during client migration.
For rollback, restore the previous substituter and key in bootstrap.nix and the
installation action. Restoring Cachix uploads also requires a renewed Cachix token.
The old token is deliberately left in GitHub until the migration is verified.
