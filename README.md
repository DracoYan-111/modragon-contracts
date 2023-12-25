# Modragon-contracts
Modragon contracts repository

## Installation

It is recommended to install [`pnpm`](https://pnpm.io) through the `npm` package manager, which comes bundled with [Node.js](https://nodejs.org/en) when you install it on your system. It is recommended to use a Node.js version `>= 20.0.0`.

Once you have `npm` installed, you can run the following both to install and upgrade `pnpm`:

```console
npm install -g pnpm
```

After having installed `pnpm`, simply run:

```console
pnpm install
```
## Running Deployments

> [!NOTE]
> The deployment script [`deploy.ts`](./scripts/deploy.ts) attempts to automatically verify the contract on the target chain after deployment. If you have not configured an API key, the verification will fail.

**Example Goerli:**

```console
pnpm deploy:goerli
```

> The deployment script [`deploy.ts`](./scripts/deploy.ts) includes the `tenderly` Hardhat Runtime Environment (HRE) extension with the `verify` method. Please consider uncommenting and configuring the Tenderly `project`, `username`, `forkNetwork`, `privateVerification`, and `deploymentsDir` attributes in the [`hardhat.config.ts`](./hardhat.config.ts) file before deploying or remove this call. Also, for this plugin to function you need to create a `config.yaml` file at `$HOME/.tenderly/config.yaml` or `%HOMEPATH%\.tenderly\config.yaml` and add an `access_key` field to it. For further information, see [here](https://www.npmjs.com/package/@tenderly/hardhat-tenderly#installing-tenderly-cli).

## Running `CREATE2` Deployments

```console
pnpm xdeploy
```

This template uses the [xdeploy](https://github.com/pcaversaccio/xdeployer) Hardhat plugin. Check out the documentation for more information on the specifics of the deployments.

## Configuration Variables

Run `npx hardhat vars set PRIVATE_KEY` to set the private key of your wallet. This allows secure access to your wallet to use with both testnet and mainnet funds during Hardhat deployments.

You can also run `npx hardhat vars setup` to see which other [configuration variables](https://hardhat.org/hardhat-runner/docs/guides/configuration-variables) are available.
