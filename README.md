# Why Puzzle?

After seeing a handful of proposals successfully passed on the Enigma mainnet its become painfully obvious the governance experience needs to be made more accessible. While stakeholders currently have access to the information regarding proposals from current block explorers like the one hosted by cashmaney, stakeholders still lack a comprehensive resource that really empowers them to more actively participate in the governance process.

To address this secretnodes.org is working to launch puzzle, an open source project forked from hubble. Once we’ve deemed our fork as stable, we plan to use this as a foundational layer to conduct governance UI/UX experiments and display metrics regarding Secret Nodes. These experiments are aimed at making the process of voting and assessing network performance as easy as possible.

You can learn more about how we plan to empower stakeholders to stay informed on proposes uses of community funds, vital changes to the enigma network, and better interact with the governance process overall by reading how we plan to approach proposals on the network [here](https://secretnodes.org/#/misc/community-first-approach).

Made with :heart: by [secretnodes.org](https://secretnodes.org). Originally forked from [hubble](https://github.com/figment-networks/hubble).

# Implementations of Puzzle
https://puzzle.secretnodes.org is our canary build of Puzzle.

https://secret.foundation will the the production implimentation of puzzle. This version will have features created in collaboration between secretnodes.org, contriburors to puzzle, and stakeholders in the enigma community.

# Setup

WIP


## Dependencies

- Ruby 2.5+
- Node LTS
- Accessible PostgreSQL database.
- Memcached running on localhost.
- [PostMark](https://postmarkapp.com) account for email notifications.
- [Rollbar](https://rollbar.com) account for exception tracking.
- [libsecp25k1](https://github.com/bitcoin-core/secp256k1) (with `--enable-module-recovery` configure option)


## How to Setup Puzzle

1. Fork this repo!
1. Generate encrypted secrets with `bin/rails secrets:setup`. Use `config/encrypted_secrets_quickstart.yml` to see what values are needed for what environments. Store `config/secrets.yml.enc` somewhere safe as it won't be committed.
1. Setup your instance:
    ```
    export PUZZLE_ADMIN_EMAIL=your@email.com
    export PUZZLE_HOST=ip-or-hostname-of-server
    export PUZZLE_RAILS_ENV=production
    export PUZZLE_KEY=~/.ssh/puzzle-key.pem
    export PUZZLE_DOMAIN=puzzle.your.domain
    export PUZZLE_REMOTE_USER=puzzle
    ./setup/bootstrap.sh
    ```
    This automated process is meant for a Ubuntu 18.04 LTS install. We use AWS for this. Puzzle uses HTTPS everywhere, so watch the output for when it asks you to create a DNS record.
1. Assuming that all goes well, there will be a URL you can visit to claim an admin account and setup a password/2FA.
1. In admin, create a new Cosmos chain with the chain name and gaiad RPC/LCD info. Make sure to click 'enable' at the top.
1. Next ssh into the machine, start `screen` and do the initial sync:
    ```
    cd /puzzle/app/current
    bin/rake sync:cosmos:all events:cosmos:all stats:cosmos:all
    ```
    That will take a good long while depending on how long the chain you're syncing has been going for.
1. Once it's done, you will want to install the crontab entries. You can either run `bin/bundle exec whenever --update-crontab` right now, or just deploy again and they'll get installed automatically.


## How to Deploy

Use the appropriate generated deploy script if you used our setup scripts:

```
bin/deploy-{RAILS_ENV}.sh
```

Or do it manually:

```
RAILS_ENV=staging DEPLOY_USER=puzzle DEPLOY_HOST=ip-or-hostname DEPLOY_KEYS=~/.ssh/puzzle.pem bin/bundle cap staging deploy
```
