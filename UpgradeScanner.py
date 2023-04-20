import subprocess
import os
import json
import sys
from time import sleep
from dotenv import load_dotenv

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
            slot = contracts[network][address]["slot"]
            name = contracts[network][address]["name"]
            # Read implementation address from storage using known slot
            bash_command = f'cast storage --rpc-url={rpc_url} {address} {slot}'
            process = subprocess.Popen(bash_command.split(), stdout=subprocess.PIPE, text=True)
            output, error = process.communicate()
            if error:
                print(f"Error reading from storage for {address}: {name}", file=sys.stderr)
                continue
            if "offset" not in contracts[network][address].keys():
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
    if any_updates:
        f = open("./contracts.json", "w")
        f.write(json.dumps(contracts, indent=2, sort_keys=False))
        f.close()

