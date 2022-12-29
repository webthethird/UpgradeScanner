# UpgradeScanner
A Python script to scan Ethereum for smart contract upgrades

Uses a handcrafted dictionary of known upgradeable proxy addresses, with a name, implementation slot and list of implementation addresses for each. 
If a change is detected in the implementation slot, the new address value is added to the list and its source code is downloaded from Etherscan for diffing.

To use the scanner, you will need to:

* Install [Foundry](https://github.com/foundry-rs/foundry)
* Get free API keys from Etherscan and Infura (or another RPC node provider)
* Copy `example.env`, rename it to `.env`, and add your API keys where indicated
  * If you use a different node provider, you will also need to replace the Infura URL

If you find this script useful leave a star, and if you add more proxy addresses to the dictionary or make any improvements to the code, please open a PR.
