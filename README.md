# UpgradeScanner
A Python script to scan Ethereum for smart contract upgrades

Uses a handcrafted dictionary of known upgradeable proxy addresses, with a name, implementation slot and list of implementation addresses for each. 
If a change is detected in the implementation slot, the new address value is added to the list and its source code is downloaded from Etherscan for diffing.

If you find this script useful leave a star, and if you add more proxy addresses to the dictionary or make any improvements to the code, please open a PR.
