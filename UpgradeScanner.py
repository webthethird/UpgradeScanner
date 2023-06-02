import subprocess
import os
import json
import sys
import time
import requests
from time import sleep
from dotenv import load_dotenv

api_config = {
    "ethereum": {
        "urls": {
            "mainnet": "api.etherscan.io",
            "goerli": "api-goerli.etherscan.io",
            "kovan": "api-kovan.etherscan.io",
            "rinkeby": "api-rinkeby.etherscan.io",
            "ropsten": "api-ropsten.etherscan.io",
        }
    },
    "arbitrum": {
        "urls": {
            "mainnet": "api.arbiscan.io",
            "testnet": "api-testnet.arbiscan.io",
        }
    },
    "avalanche": {
        "urls": {
            "mainnet": "api.snowtrace.io",
            "testnet": "api-testnet.snowtrace.io",
        }
    },
    "bsc": {
        "urls": {
            "mainnet": "api.bscscan.com",
            "testnet": "api-testnet.bscscan.com",
        }
    },
    "celo": {
        "urls": {
            "mainnet": "api.celoscan.io",
        }
    },
    "fantom": {
        "urls": {
            "mainnet": "api.ftmscan.com",
        }
    },
    "optimism": {
        "urls": {
            "mainnet": "api-optimistic.etherscan.io",
        }
    },
    "polygon": {
        "urls": {
            "mainnet": "api.polygonscan.com",
            "mumbai": "api-testnet.polygonscan.com",
        }
    },
}

def get_previous_impl(proxy_address, current_impl, rpc_url, api_key, chain, slot=None, offset=None, getter=None, args='') -> str | None:
    if slot is None and getter is None:
        return None
    time.sleep(0.5)
    headers = {
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0"
    }
    # Get the transaction that created the current implementation
    response = requests.get(f"https://{api_config[chain]['urls']['mainnet']}/api?"
                            "module=contract&"
                            "action=getcontractcreation&"
                            f"contractaddresses={current_impl}&"
                            f"apikey={api_key}", 
                            headers=headers)
    try:
        data = json.loads(response.text)
        tx_hash = data.get("result")[0].get("txHash")
        # print(f"Current implementation at {current_impl} deployed in tx:\n{tx_hash}")
    except (json.decoder.JSONDecodeError, AttributeError):
        print(f"error on contract at {current_impl}")
        return None
    # Get the block containing that transaction
    time.sleep(0.5)
    response = requests.get(f"https://{api_config[chain]['urls']['mainnet']}/api?"
                            "module=proxy&"
                            "action=eth_getTransactionByHash&"
                            f"txhash={tx_hash}&"
                            f"apikey={api_key}", 
                            headers=headers)
    try:
        data = json.loads(response.text)
        block = data.get("result").get("blockNumber").replace("0x","")
        block = int.from_bytes(bytes.fromhex(block), byteorder="big")
        # print(f"Current implementation at {current_impl} deployed in block {block} in tx: {tx_hash}")
    except (json.decoder.JSONDecodeError, AttributeError, ValueError) as err:
        print(f"error on transaction {tx_hash}")
        return None
    # Get the implementation at the time when the current one was created
    time.sleep(0.5)
    if slot is not None:
        bash_command = f'cast storage --block={block} --rpc-url={rpc_url} {proxy_address} {slot}'
    else:
        bash_command = f'cast call --block={block} --rpc-url={rpc_url} {address} {getter} {args}'
    process = subprocess.Popen(bash_command.split(), stdout=subprocess.PIPE, text=True)
    output, error = process.communicate()
    if error:
        print(f"Error reading from storage for {address}: {name}", file=sys.stderr)
        return None
    if offset is None:
        impl = "0x" + str(output).replace("\n", "")[26:]
    else:
        impl = "0x" + str(output).replace("\n", "")[66-2*(offset + 20):66-2*offset]
    if impl == current_impl:
        return None
    return impl


if __name__ == '__main__':
    load_dotenv()
    f = open("./contracts.json", "r")
    contracts = json.loads(f.read())
    f.close()
    any_updates = False
    for network in contracts.keys():
        print(f"Scanning {network} chain...")
        if (
            f"{str(network).upper()}_RPC_URL" not in os.environ
            or f"{str(network).upper()}_API_KEY" not in os.environ
        ):
            print(f"Missing env variable for {network}", file=sys.stderr)
            continue
        rpc_url = os.getenv(f"{str(network).upper()}_RPC_URL")
        api_key = os.getenv(f"{str(network).upper()}_API_KEY")
        for address in contracts[network].keys():
            sleep(1)
            name = contracts[network][address]["name"]
            slot = None
            getter = None
            getter_args = None
            if "slot" in contracts[network][address]:
                slot = contracts[network][address]["slot"]
                # Read implementation address from storage using known slot
                bash_command = f'cast storage --rpc-url={rpc_url} {address} {slot}'
            elif "getter" in contracts[network][address]:
                getter = contracts[network][address]["getter"]
                # Get implementation address by calling known getter function
                bash_command = f'cast call --rpc-url={rpc_url} {address} {getter}'
                if "getter_arg" in contracts[network][address]:
                    getter_args = contracts[network][address]["getter_arg"]
                    bash_command += f' {getter_args}'
            else:
                continue
            process = subprocess.Popen(bash_command.split(), stdout=subprocess.PIPE, text=True)
            output, error = process.communicate()
            if error:
                print(f"Error reading from storage for {address}: {name}", file=sys.stderr)
                continue
            if "offset" not in contracts[network][address].keys():
                offset = None
                impl = "0x" + str(output).replace("\n", "")[26:]
            else:
                offset = contracts[network][address]["offset"]
                impl = "0x" + str(output).replace("\n", "")[66-2*(offset + 20):66-2*offset]
            if "implementations" not in contracts[network][address]:
                contracts[network][address]["implementations"] = []
            if impl not in contracts[network][address]["implementations"]:
                print(f"New implementation found for {name}:\n{impl}")
                contracts[network][address]["implementations"].append(impl)
                any_updates = True
                # Download implementation source code for diffing
                impl_path = f"./implementations/{network}/{name.replace(' ', '').replace(':', '')}/{impl}"
                chain = "mainnet" if network == "ethereum" else network
                bash_command = f'cast etherscan-source -d {impl_path} -c {chain} --etherscan-api-key {api_key} {impl}'
                process = subprocess.Popen(bash_command.split(), stdout=subprocess.PIPE, text=True)
                output, error = process.communicate()
            if len(contracts[network][address]["implementations"]) == 1:
                try:
                    prev_impl = get_previous_impl(
                        address,
                        contracts[network][address]["implementations"][0],
                        rpc_url,
                        api_key,
                        network,
                        slot,
                        offset,
                        getter,
                        getter_args
                    )
                    if prev_impl is not None and prev_impl != "0x0000000000000000000000000000000000000000":
                        print(f"Previous implementation found for {name}:\n{prev_impl}")
                        contracts[network][address]["implementations"].insert(0, prev_impl)
                        any_updates = True
                        # Download implementation source code for diffing
                        impl_path = f"./implementations/{network}/{name.replace(' ', '').replace(':', '')}/{prev_impl}"
                        chain = "mainnet" if network == "ethereum" else network
                        bash_command = f'cast etherscan-source -d {impl_path} -c {chain} --etherscan-api-key {api_key} {prev_impl}'
                        process = subprocess.Popen(bash_command.split(), stdout=subprocess.PIPE, text=True)
                        output, error = process.communicate()
                    else:
                        print(f"Failed to find a previous implementation for {name}")
                except Exception as err:
                    print(f"Failed to find a previous implementation for {name}")
                    continue

    if any_updates:
        f = open("./contracts.json", "w")
        f.write(json.dumps(contracts, indent=2, sort_keys=False))
        f.close()

