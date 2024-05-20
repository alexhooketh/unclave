# unclave
AA mini accounts on L2s controlled by a single account on another L2

**WARNING: it is ugly both by design and by implementation and probably insecure as fuck, don't use it in prod**

## Abstract

you have an AA account on some L2

you wanna use another L2

deploying the same AA account on another L2 is too hard and expensive, especially if you've got p256 keys, social recovery, etc etc

you deploy simple AA accounts with mutable ecdsa keys

in order to change keys you have to call them from your parent account through the L1, so you can afford to lose them as long as you can recover your main AA account

sending a tx through the L1 takes a long time [(1-4 hrs on most zk rollups, 21hr on era, ~7 days on optimistic rollups)](https://l2beat.com/scaling/finality) but you won't really use it other than when you lose the temporary keys

profit! you have very ugly mini accounts on many L2s that are as recoverable as your main AA account, which in combination with external token bridges gives you sorta rollup interoperability

## What

todo

## How

heavily inspired by [xtra protocol](https://github.com/alexhooketh/xtra-protocol), my ethglobal istanbul project. in fact, the only functional difference is that there you had to walk through the L1 for each transaction (making it unusable in practice), whereas here you only need this after every social recovery of your main AA account (not so unusable)

also it has some gas optimisations so the entire system is much cheaper to use

the codebase is clave-centric and zksync-based so you better rewrite it from scratch if you want to make it universal

## How come unclave

i lacked this on my [clave](https://getclave.io)
